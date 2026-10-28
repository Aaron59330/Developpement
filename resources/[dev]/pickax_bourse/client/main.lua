-- ─────────────────────────────── Bourse (client) : menus ox_lib ───────────────────────────────
local function money(n) return ('%s $'):format(math.floor(n + 0.5)) end

local function bar(trend)
    if not trend or #trend < 2 then return '' end
    local chars, lo, hi = { '▁', '▂', '▃', '▄', '▅', '▆', '▇', '█' }, math.huge, -math.huge
    for _, v in ipairs(trend) do lo, hi = math.min(lo, v), math.max(hi, v) end
    local out = {}
    for _, v in ipairs(trend) do out[#out + 1] = chars[hi == lo and 4 or (1 + math.floor((v - lo) / (hi - lo) * 7))] end
    return table.concat(out)
end

local function order(side, s, max)
    local input = lib.inputDialog(('%s %s'):format(side == 'buy' and 'Acheter' or 'Vendre', s.id), { { type = 'number', label = 'Nombre d\'actions', min = 1, max = max, default = 1, required = true } })
    if not input then return end
    local r = lib.callback.await('pickax_bourse:order', false, side, s.id, input[1])
    if not r or not r.ok then return lib.notify({ title = 'Bourse', description = (r and r.error) or 'Erreur', type = 'error' }) end
    local d = side == 'buy' and ('%d × %s achetées pour %s'):format(r.qty, s.id, money(r.total)) or ('%d × %s vendues pour %s (%s%s)'):format(r.qty, s.id, money(r.total), r.profit >= 0 and '+' or '', money(r.profit))
    lib.notify({ title = 'Bourse', description = d, type = 'success' })
end

local open
local function stockMenu(m, s)
    lib.registerContext({ id = 'bourse_stock', title = ('%s · %s'):format(s.id, s.label), menu = 'bourse_main', options = {
        { title = money(s.price), description = ('%s%.1f %% · %s'):format(s.change >= 0 and '+' or '', s.change, bar(s.trend)), readOnly = true, icon = 'chart-line' },
        { title = 'Acheter', description = ('Frais %.1f %%'):format(m.fee), icon = 'cart-plus', onSelect = function() order('buy', s, math.max(1, (m.max or 5000) - s.shares)) open() end },
        { title = 'Vendre', description = s.shares > 0 and ('Tu en as %d (prix moyen %s)'):format(s.shares, money(s.avg)) or 'Tu n\'en as pas', disabled = s.shares <= 0, icon = 'hand-holding-dollar', onSelect = function() order('sell', s, s.shares) open() end },
    } })
    lib.showContext('bourse_stock')
end

function open()
    local m = lib.callback.await('pickax_bourse:market', false)
    if not m or not m.ok then return lib.notify({ title = 'Bourse', description = (m and m.error) or 'Indisponible', type = 'error' }) end
    local opts, total = {}, 0
    for _, s in ipairs(m.stocks) do
        total = total + s.shares * s.price
        opts[#opts + 1] = { title = ('%s  %s'):format(s.id, money(s.price)), description = ('%s · %s%.1f %%  %s%s'):format(s.label, s.change >= 0 and '+' or '', s.change, bar(s.trend), s.shares > 0 and ('  ·  %d détenues'):format(s.shares) or ''),
            icon = s.change >= 0 and 'arrow-trend-up' or 'arrow-trend-down', iconColor = s.change >= 0 and '#4ade80' or '#f87171', onSelect = function() stockMenu(m, s) end }
    end
    lib.registerContext({ id = 'bourse_main', title = ('Bourse · portefeuille %s · compte %s'):format(money(total), money(m.cash)), options = opts })
    lib.showContext('bourse_main')
end

RegisterCommand(Config.Command or 'bourse', function() open() end, false)
