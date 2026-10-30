-- Lit la configuration du « Parcours d'arrivée » enregistrée depuis le panel web (document « creator », synchronisé par pickax_panel)
-- et la transmet aux joueurs. Sans panel : les valeurs de config.lua s'appliquent.
local function readDoc()
    local raw = GetResourceState('pickax_panel') == 'started' and LoadResourceFile('pickax_panel', 'cache_creator.json') or nil
    if not raw or raw == '' then return nil end
    local ok, v = pcall(json.decode, raw)
    return ok and type(v) == 'table' and v or nil
end
RegisterNetEvent('pickax_creator:cfg', function()
    TriggerClientEvent('pickax_creator:cfg', source, readDoc() or {})
end)
