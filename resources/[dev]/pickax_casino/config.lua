Config = {}

-- ═════════════════════════════ CASINO ═════════════════════════════
Config.Name        = 'Diamond Casino'       -- nom affiché dans les interfaces
-- Les postes (caisse, machines, tables) sont placés dans le World Builder : module « Casino ».
-- Les valeurs ci-dessous servent par défaut ; chaque casino du World Builder (onglet « Jetons & limites ») peut les remplacer.
Config.Currency    = 'money'                -- compte utilisé pour acheter / vendre des jetons : 'money' (liquide) ou 'bank'
Config.ChipBuyPrice  = 1.0                  -- prix d'un jeton en $ à l'achat (1 jeton = 1 $)
Config.ChipSellPrice = 0.95                 -- ce que rend la caisse par jeton au rachat (0.95 = la caisse garde 5 %) ; mets 1.0 pour ne rien garder
Config.MinBuy      = 10                     -- achat minimum (jetons)
Config.MaxBuy      = 500000                 -- achat maximum par opération
Config.MaxWallet   = 5000000                -- jetons maximum qu'un joueur peut posséder
Config.InteractDistance = 2.0               -- tolérance de distance vérifiée par le serveur (mètres, +2,5 de marge)
Config.AdminGroups = { _dev = true, superadmin = true, admin = true }   -- qui peut utiliser /casinortp et /casinostats
Config.Webhook     = ''                     -- (facultatif) webhook Discord : gros gains, achats importants
Config.BigWin      = 50000                  -- gain (jetons) à partir duquel un message est envoyé au webhook et en notification


-- ═════════════════════════════ MACHINES À SOUS ═════════════════════════════
-- 3 rouleaux, 3 lignes visibles, 5 lignes de gain (3 horizontales + 2 diagonales). La mise est répartie sur les 5 lignes.
-- Le taux de retour (RTP) est calculé automatiquement : /casinortp l'affiche en console. Il dépend des rouleaux et du tableau des gains.
Config.Slots = {
    Machines = {                                       -- 3 gammes de machines (la gamme se choisit sur chaque poste dans le World Builder)
        bronze = { label = 'Machine Bronze', min = 10,  max = 200,  bets = { 10, 25, 50, 100, 200 } },
        silver = { label = 'Machine Argent', min = 50,  max = 1000, bets = { 50, 100, 250, 500, 1000 } },
        gold   = { label = 'Machine Or',     min = 250, max = 5000, bets = { 250, 500, 1000, 2500, 5000 } },
    },
    CherrySymbol = 'cherry',
    -- gain pour 3 symboles identiques sur une ligne, en multiple de la mise par ligne (= mise ÷ 5)
    Pay3 = { seven = 100, bar = 40, bell = 20, plum = 10, lemon = 6, cherry = 4 },
    CherryTwo = 8,                                     -- 2 cerises en début de ligne
    CherryOne = 0,                                     -- 1 cerise en début de ligne
    -- cases de chaque rouleau (24 cases) : plus un symbole apparaît, plus il sort souvent
    Strips = {
        { 'cherry', 'lemon', 'cherry', 'cherry', 'cherry', 'lemon', 'bell', 'lemon', 'plum', 'plum', 'seven', 'plum', 'bar', 'cherry', 'cherry', 'lemon', 'cherry', 'lemon', 'lemon', 'bell', 'plum', 'bar', 'cherry', 'bell' },
        { 'cherry', 'lemon', 'bell', 'plum', 'bell', 'bar', 'bar', 'lemon', 'cherry', 'cherry', 'plum', 'bell', 'plum', 'cherry', 'lemon', 'lemon', 'plum', 'lemon', 'cherry', 'cherry', 'cherry', 'cherry', 'seven', 'lemon' },
        { 'cherry', 'lemon', 'bar', 'bar', 'lemon', 'seven', 'cherry', 'plum', 'plum', 'lemon', 'bell', 'cherry', 'cherry', 'lemon', 'plum', 'cherry', 'lemon', 'cherry', 'plum', 'bell', 'bell', 'cherry', 'cherry', 'lemon' },
    },
}

-- ═════════════════════════════ BLACKJACK ═════════════════════════════
Config.Blackjack = {
    Tables = {                                         -- gammes de tables
        classic = { label = 'Table Classique', min = 50,  max = 2500,  bets = { 50, 100, 250, 500, 1000, 2500 } },
        vip     = { label = 'Table VIP',       min = 500, max = 25000, bets = { 500, 1000, 2500, 5000, 10000, 25000 } },
    },
    Decks = 6,                                         -- nombre de jeux dans le sabot
    BlackjackPays = 1.5,                               -- le blackjack paie 3 pour 2
    DealerHitsSoft17 = false,                          -- le croupier tire-t-il sur un 17 « souple » ?
}

-- ═════════════════════════════ ROULETTE ═════════════════════════════
Config.Roulette = {
    Tables = {                                        
        classic = { label = 'Roulette Classique', min = 10,  max = 1000,  total = 5000,  chips = { 10, 50, 100, 500, 1000 } },
        vip     = { label = 'Roulette VIP',       min = 100, max = 10000, total = 50000, chips = { 100, 500, 1000, 5000, 10000 } },
    },
}
