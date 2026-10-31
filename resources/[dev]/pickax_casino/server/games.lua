-- ═════════════════ Logique pure des jeux du casino (aucune dépendance FiveM : testable hors du jeu) ═════════════════
-- Tout le hasard est tiré ICI, côté serveur ; le client ne reçoit que le résultat.
Games = {}
local rand = function(n) return math.random(1, n) end
function Games.setRandom(f) rand = f end
Games.rand = function(n) return rand(n) end

-- ───────────── Machines à sous : 3 rouleaux × 3 lignes visibles, 5 lignes de gain ─────────────
-- Strips[rouleau] = liste des cases ; le résultat affiche la case tirée et ses deux voisines.
-- Pay3[symbole] = multiplicateur de la MISE PAR LIGNE pour 3 symboles identiques ; la mise totale est répartie sur les 5 lignes.
Games.SLOT_LINES = { { 2, 2, 2 }, { 1, 1, 1 }, { 3, 3, 3 }, { 1, 2, 3 }, { 3, 2, 1 } }
function Games.slotsGrid(strips, stops)
    local grid = {}
    for r = 1, 3 do
        local N = #strips[r]
        grid[r] = {}
        for row = 1, 3 do grid[r][row] = strips[r][((stops[r] - 1 + row - 2) % N) + 1] end
    end
    return grid
end
function Games.slotsEval(cfg, grid)
    local total, wins = 0, {}
    for li, ln in ipairs(Games.SLOT_LINES) do
        local a, b, c = grid[1][ln[1]], grid[2][ln[2]], grid[3][ln[3]]
        local mult = 0
        if a == b and b == c then mult = cfg.Pay3[a] or 0
        elseif a == cfg.CherrySymbol and b == cfg.CherrySymbol then mult = cfg.CherryTwo or 0
        elseif a == cfg.CherrySymbol then mult = cfg.CherryOne or 0 end
        if mult > 0 then total = total + mult wins[#wins + 1] = { line = li, mult = mult, symbols = { a, b, c } } end
    end
    return total / #Games.SLOT_LINES, wins
end
function Games.slotsSpin(cfg, bet)
    local stops = { rand(#cfg.Strips[1]), rand(#cfg.Strips[2]), rand(#cfg.Strips[3]) }
    local grid = Games.slotsGrid(cfg.Strips, stops)
    local mult, wins = Games.slotsEval(cfg, grid)
    return { grid = grid, stops = stops, wins = wins, mult = mult, payout = math.floor(bet * mult + 1e-9) }
end
-- Taux de retour théorique exact (énumération de toutes les combinaisons) : sert à régler les rouleaux
function Games.slotsRTP(cfg)
    local n1, n2, n3 = #cfg.Strips[1], #cfg.Strips[2], #cfg.Strips[3]
    local sum, hits = 0, 0
    for a = 1, n1 do for b = 1, n2 do for c = 1, n3 do
        local m = Games.slotsEval(cfg, Games.slotsGrid(cfg.Strips, { a, b, c }))
        sum = sum + m
        if m > 0 then hits = hits + 1 end
    end end end
    local total = n1 * n2 * n3
    return sum / total, hits / total
end

-- ───────────── Blackjack (sabot de 6 jeux, le croupier tire jusqu'à 17) ─────────────
function Games.newShoe(decks)
    local shoe = {}
    for _ = 1, decks or 6 do
        for suit = 1, 4 do for rank = 1, 13 do shoe[#shoe + 1] = { rank = rank, suit = suit } end end
    end
    for i = #shoe, 2, -1 do local j = rand(i) shoe[i], shoe[j] = shoe[j], shoe[i] end
    return shoe
end
function Games.cardValue(c) if c.rank == 1 then return 11 elseif c.rank >= 10 then return 10 end return c.rank end
function Games.handValue(cards)
    local total, aces = 0, 0
    for _, c in ipairs(cards) do total = total + Games.cardValue(c) if c.rank == 1 then aces = aces + 1 end end
    while total > 21 and aces > 0 do total = total - 10 aces = aces - 1 end
    return total, aces > 0                       -- (total, main « souple » : un as compte encore 11)
end
local function isBlackjack(cards) return #cards == 2 and Games.handValue(cards) == 21 end
local function draw(s) if #s.shoe == 0 then s.shoe = Games.newShoe(s.decks) end return table.remove(s.shoe) end

-- s = état d'une partie ; bet = mise en jetons
function Games.bjNew(bet, opts, shoe)
    opts = opts or {}
    local s = { bet = bet, decks = opts.decks or 6, bjPay = opts.bjPay or 1.5, hitSoft17 = opts.hitSoft17 == true, shoe = shoe or Games.newShoe(opts.decks or 6), player = {}, dealer = {}, doubled = false, over = false }
    s.player[1], s.dealer[1], s.player[2], s.dealer[2] = draw(s), draw(s), draw(s), draw(s)
    if isBlackjack(s.player) or isBlackjack(s.dealer) then Games.bjFinish(s) end
    return s
end
local function dealerPlay(s)
    while true do
        local t, soft = Games.handValue(s.dealer)
        if t < 17 or (t == 17 and soft and s.hitSoft17) then s.dealer[#s.dealer + 1] = draw(s) else break end
    end
end
-- Règle la partie : s.result ('blackjack' | 'win' | 'push' | 'lose' | 'bust') et s.payout (jetons rendus, mise comprise)
function Games.bjFinish(s)
    s.over = true
    local pt = Games.handValue(s.player)
    local stake = s.bet * (s.doubled and 2 or 1)
    if isBlackjack(s.player) and isBlackjack(s.dealer) then s.result, s.payout = 'push', stake
    elseif isBlackjack(s.player) then s.result, s.payout = 'blackjack', stake + math.floor(stake * s.bjPay)
    elseif isBlackjack(s.dealer) then s.result, s.payout = 'lose', 0
    elseif pt > 21 then s.result, s.payout = 'bust', 0
    else
        dealerPlay(s)
        local dt = Games.handValue(s.dealer)
        if dt > 21 or pt > dt then s.result, s.payout = 'win', stake * 2
        elseif pt == dt then s.result, s.payout = 'push', stake
        else s.result, s.payout = 'lose', 0 end
    end
    return s
end
function Games.bjHit(s)
    if s.over then return s end
    s.player[#s.player + 1] = draw(s)
    local t = Games.handValue(s.player)
    if t > 21 then s.over = true s.result, s.payout = 'bust', 0 elseif t == 21 then Games.bjFinish(s) end
    return s
end
function Games.bjStand(s) if not s.over then Games.bjFinish(s) end return s end
function Games.bjDouble(s)               -- une seule carte puis le croupier joue (autorisé sur les 2 premières cartes)
    if s.over or #s.player ~= 2 or s.doubled then return nil end
    s.doubled = true
    s.player[#s.player + 1] = draw(s)
    Games.bjFinish(s)
    return s
end
-- vue envoyée au joueur : la 2e carte du croupier reste cachée tant que la partie n'est pas finie
function Games.bjView(s)
    local d = {}
    for i, c in ipairs(s.dealer) do d[i] = (i == 2 and not s.over) and { hidden = true } or { rank = c.rank, suit = c.suit } end
    local pv = Games.handValue(s.player)
    local dv = s.over and Games.handValue(s.dealer) or Games.cardValue(s.dealer[1])
    return { player = s.player, dealer = d, playerValue = pv, dealerValue = dv, over = s.over, result = s.result, payout = s.payout, bet = s.bet * (s.doubled and 2 or 1), canDouble = (not s.over) and #s.player == 2 and not s.doubled }
end

-- ───────────── Roulette européenne (un seul zéro) ─────────────
Games.RED = {}
for _, n in ipairs({ 1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36 }) do Games.RED[n] = true end
function Games.rouletteColor(n) if n == 0 then return 'green' end return Games.RED[n] and 'red' or 'black' end
-- Une mise = { t = type, n = numéro (pour 'straight'), a = montant } ; renvoie le total misé et une erreur éventuelle
local MULT = { straight = 36, red = 2, black = 2, odd = 2, even = 2, low = 2, high = 2, dozen1 = 3, dozen2 = 3, dozen3 = 3, col1 = 3, col2 = 3, col3 = 3 }
function Games.rouletteCheck(bets, minBet, maxBet, maxTotal)
    if type(bets) ~= 'table' or #bets == 0 then return nil, 'Place au moins une mise' end
    if #bets > 60 then return nil, 'Trop de mises' end
    local total = 0
    for _, b in ipairs(bets) do
        if type(b) ~= 'table' or not MULT[b.t] then return nil, 'Mise invalide' end
        if b.t == 'straight' and not (tonumber(b.n) and b.n >= 0 and b.n <= 36 and b.n == math.floor(b.n)) then return nil, 'Numéro invalide' end
        local a = tonumber(b.a)
        if not a or a ~= math.floor(a) or a < minBet or a > maxBet then return nil, ('Chaque mise doit être entre %d et %d jetons'):format(minBet, maxBet) end
        total = total + a
    end
    if total > maxTotal then return nil, ('Mise totale maximale : %d jetons'):format(maxTotal) end
    return total
end
local function betWins(b, n)
    if b.t == 'straight' then return n == b.n end
    if n == 0 then return false end
    if b.t == 'red' then return Games.RED[n] == true elseif b.t == 'black' then return not Games.RED[n]
    elseif b.t == 'odd' then return n % 2 == 1 elseif b.t == 'even' then return n % 2 == 0
    elseif b.t == 'low' then return n <= 18 elseif b.t == 'high' then return n >= 19
    elseif b.t == 'dozen1' then return n <= 12 elseif b.t == 'dozen2' then return n >= 13 and n <= 24 elseif b.t == 'dozen3' then return n >= 25
    elseif b.t == 'col1' then return n % 3 == 1 elseif b.t == 'col2' then return n % 3 == 2 elseif b.t == 'col3' then return n % 3 == 0 end
    return false
end
function Games.rouletteSpin(bets)
    local n = rand(37) - 1
    local payout, wins = 0, {}
    for i, b in ipairs(bets) do
        if betWins(b, n) then payout = payout + b.a * MULT[b.t] wins[#wins + 1] = i end
    end
    return { number = n, color = Games.rouletteColor(n), payout = payout, wins = wins }
end
