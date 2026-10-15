local started = os.time()

local function info()
    return {
        online = GetNumPlayerIndices(),
        max = GetConvarInt('sv_maxclients', 48),
        uptime = os.time() - started,
    }
end

if GetResourceState('es_extended') ~= 'missing' then
    local ESX = exports['es_extended']:getSharedObject()
    ESX.RegisterServerCallback('pickax_pause:info', function(_, cb) cb(info()) end)
end
