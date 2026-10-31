-- ─────────────────────────────── Casinos ───────────────────────────────
-- Le World Builder place les postes (caisse, machines, tables) et règle les prix des jetons ; les jeux eux-mêmes sont dans pickax_casino.
local DEFAULT_TIERS = { slots = { 'bronze', 'silver', 'gold' }, blackjack = { 'classic', 'vip' }, roulette = { 'classic', 'vip' } }
WB.casinoTiers = DEFAULT_TIERS

local function refreshTiers()
    if GetResourceState('pickax_casino') ~= 'started' then return end
    local ok, t = pcall(function() return exports.pickax_casino:Tiers() end)
    if ok and type(t) == 'table' then WB.casinoTiers = t end
end
AddEventHandler('onResourceStart', function(res) if res == 'pickax_casino' then SetTimeout(500, refreshTiers) end end)
CreateThread(function() Wait(3000) refreshTiers() end)

ESX.RegisterServerCallback('worldbuilder:casino:tiers', function(src, cb) refreshTiers() cb(WB.casinoTiers) end)

-- Appelé par pickax_casino à chaque action : le poste existe-t-il, est-il actif, le joueur y a-t-il accès et est-il à côté ?
-- Retourne { kind, tier, coords, settings } ou nil.
exports('CasinoSpot', function(src, eid, pi, extraDistance)
    local e = WB.Entities[tonumber(eid) or 0]
    local x = ESX.GetPlayerFromId(src)
    if not e or e.type ~= 'casino' or not e.enabled or not x then return nil end
    local p = e.points[tonumber(pi) or 0]
    if not p or not p.coords or p.coords.x == nil or not WB.near(src, p.coords, extraDistance or 3.0) then return nil end
    local ok = WB.hasAccess(x, e.settings.access)
    if not ok then return nil end
    return { kind = p.kind, tier = p.tier, label = p.label ~= '' and p.label or e.label, coords = { x = p.coords.x, y = p.coords.y, z = p.coords.z }, settings = e.settings, entityName = e.label }
end)
