-- Réglages « en direct » envoyés par le panel : diffusés par le serveur (GlobalState.pickaxPanel) et lus par les scripts
-- via  exports.pickax_panel:Get('<groupe>')  (ex : 'notify', 'hud2', 'markers', 'rageui').
-- L'évènement local  pickax_panel:changed  est déclenché à chaque nouvelle valeur.

local cache = {}

local function load(raw)
    local ok, t = pcall(json.decode, raw or '{}')
    cache = (ok and type(t) == 'table') and t or {}
    TriggerEvent('pickax_panel:changed', cache)
end

AddStateBagChangeHandler('pickaxPanel', 'global', function(_, _, value) load(value) end)

CreateThread(function()
    Wait(300)
    load(GlobalState.pickaxPanel)
end)

exports('Get', function(group) return cache[group] or {} end)
