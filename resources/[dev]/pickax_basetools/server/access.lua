-- Whitelist et message de bienvenue (Config.Whitelist / Config.Motd, voir config.lua)
AddEventHandler('playerConnecting', function(name, _, deferrals)
    local W = Config.Whitelist
    if not W or not W.Enabled then return end
    local src = source
    deferrals.defer()
    Wait(0)
    local allowed = {}
    for _, id in ipairs(W.Identifiers or {}) do allowed[tostring(id):lower()] = true end
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if allowed[id:lower()] then deferrals.done() return end
    end
    print(('[pickax_basetools] Connexion refusée (hors whitelist) : %s'):format(name))
    deferrals.done(W.Message or "Tu n'es pas sur la whitelist du serveur.")
end)

AddEventHandler('esx:playerLoaded', function(src)
    local M = Config.Motd
    if not M or not M.Enabled or not M.Text or M.Text == '' then return end
    SetTimeout((tonumber(M.Delay) or 8) * 1000, function()
        if GetPlayerName(src) then TriggerClientEvent('esx:showNotification', src, M.Text) end
    end)
end)
