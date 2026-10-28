-- ─────────────────────────────── Réglages du panel web (pickax_settings) ───────────────────────────────
-- Applique les réglages modifiés dans le panel (Réglages du serveur → Drogues & labos) sur la configuration de cette ressource, en direct, sans redémarrage.
-- Rien ne change tant qu'un réglage n'est pas modifié ; remis à sa valeur par défaut, l'ancienne valeur du config.lua est restaurée.
-- Ajouter un réglage : une ligne dans pickax_settings/config.lua (Settings.Schema) + une ligne ci-dessous.
local MAP = {
    { 'ib_pedsales', 'PedSales.Enabled' },
    { 'ib_rep_enabled', 'StreetRep.Enabled' },
    { 'ib_rep_unit', 'StreetRep.PerUnit' },
    { 'ib_rep_accept', 'StreetRep.AcceptPerLevel' },
    { 'ib_rep_price', 'StreetRep.PricePerLevel' },
    { 'ib_zone_enabled', 'StreetZones.Enabled' },
    { 'ib_zone_cell', 'StreetZones.Cell' },
    { 'ib_zone_sat', 'StreetZones.SatPerUnit' },
    { 'ib_zone_satdecay', 'StreetZones.SatDecay' },
    { 'ib_zone_drop', 'StreetZones.MaxPriceDrop' },
    { 'ib_zone_heat', 'StreetZones.HeatPerSale' },
    { 'ib_zone_heatdecay', 'StreetZones.HeatDecay' },
    { 'ib_zone_heatalert', 'StreetZones.HeatAlert' },
    { 'ib_zone_heataccept', 'StreetZones.HeatAccept' },
    { 'ib_purity_enabled', 'Purity.Enabled' },
    { 'ib_purity_default', 'Purity.Default' },
    { 'ib_purity_min', 'Purity.MinFactor' },
    { 'ib_purity_max', 'Purity.MaxFactor' },
    { 'ib_street_enabled', 'StreetSales.Enabled' },
    { 'ib_street_tablet', 'StreetSales.RequireTablet' },
    { 'ib_street_chance', 'StreetSales.AcceptChance' },
    { 'ib_street_qmin', 'StreetSales.QtyMin' },
    { 'ib_street_qmax', 'StreetSales.QtyMax' },
    { 'ib_street_factor', 'StreetSales.PriceFactor' },
    { 'ib_street_cooldown', 'StreetSales.Cooldown' },
    { 'ib_street_hour', 'StreetSales.MaxPerHour' },
    { 'ib_street_alert', 'StreetSales.AlertChance' },
    { 'ib_street_refuse', 'StreetSales.RefuseAlertChance' },
    { 'ib_street_cops', 'StreetSales.CopsRequired' },
}
local ORIG = {}

local function walk(path, create)
    local t = Config
    local keys = {}
    for k in path:gmatch('[^%.]+') do keys[#keys + 1] = tonumber(k) or k end
    for i = 1, #keys - 1 do
        if type(t[keys[i]]) ~= 'table' then if not create then return nil end t[keys[i]] = {} end
        t = t[keys[i]]
    end
    return t, keys[#keys]
end

local function applyAll(all, ov)
    if type(all) ~= 'table' or type(ov) ~= 'table' then return end
    local changed = false
    for _, m in ipairs(MAP) do
        local key, path = m[1], m[2]
        local t, k = walk(path, ov[key] ~= nil)
        if t then
            if ov[key] ~= nil then
                if ORIG[key] == nil then ORIG[key] = { t[k] } end
                if t[k] ~= all[key] then t[k] = all[key] changed = true end
            elseif ORIG[key] ~= nil then
                t[k] = ORIG[key][1]; ORIG[key] = nil; changed = true
            end
        end
    end
    if changed and PanelSettingsChanged then PanelSettingsChanged() end
end

AddEventHandler('pickax_settings:changed', applyAll)

-- si cette ressource démarre après pickax_settings : on récupère les réglages déjà en place
CreateThread(function()
    Wait(1500)
    if GetResourceState('pickax_settings') ~= 'started' then return end
    local ok, all = pcall(function() return exports.pickax_settings:GetAll() end)
    local ok2, ov = pcall(function() return exports.pickax_settings:Overrides() end)
    if ok and ok2 then applyAll(all, ov) end
end)

-- les dealers apparaissent / disparaissent tout de suite chez tous les joueurs
if IsDuplicityVersion() then
    function PanelSettingsChanged() if IB and IB.syncAll then IB.syncAll() end end
end
