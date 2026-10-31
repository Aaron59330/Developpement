-- Serveur : lit la boutique enregistrée dans le panel web, l'applique, reconstruit les prix vérifiés à l'achat et prévient les joueurs.
local current

local function read()
    if GetResourceState('pickax_panel') == 'missing' then return nil end
    local raw = LoadResourceFile('pickax_panel', 'cache_boutique.json')
    if not raw or raw == '' then return nil end
    local ok, v = pcall(json.decode, raw)
    return ok and type(v) == 'table' and v or nil
end

local function apply(doc)
    current = doc
    BoutiqueApplyOverride(doc)
    if BoutiqueRebuildPrices then BoutiqueRebuildPrices() end
end

CreateThread(function()
    local doc = read()
    if doc then apply(doc) end
end)

-- appelé par pickax_panel quand la boutique est modifiée dans le panel
AddEventHandler('pickax_boutique:docUpdated', function(doc)
    if type(doc) ~= 'table' then return end
    apply(doc)
    TriggerClientEvent('CorePickax:boutique:cfg', -1, doc)
end)

RegisterNetEvent('CorePickax:boutique:cfgRequest', function()
    if current then TriggerClientEvent('CorePickax:boutique:cfg', source, current) end
end)
