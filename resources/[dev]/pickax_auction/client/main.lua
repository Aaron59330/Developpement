local open = false

local function close()
    if not open then return end
    open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function nearSpot()
    if #Config.Spots == 0 then return true end
    local p = GetEntityCoords(PlayerPedId())
    for _, s in ipairs(Config.Spots) do if #(p - s.coords) <= (s.radius or 3.0) then return true end end
    return false
end

local function show()
    if open then return close() end
    if IsEntityDead(PlayerPedId()) then return end
    if not nearSpot() then return lib.notify({ type = 'error', description = 'Rends-toi à l\'hôtel des ventes.' }) end
    local d = lib.callback.await('pickax_auction:list', false)
    if not d or not d.ok then return lib.notify({ type = 'error', description = (d and d.error) or 'Indisponible' }) end
    open = true
    SetNuiFocus(true, true)
    d.action = 'open'
    SendNUIMessage(d)
end
RegisterCommand(Config.Command, show, false)

-- marqueurs des lieux (si configurés)
CreateThread(function()
    if #Config.Spots == 0 then return end
    for _, s in ipairs(Config.Spots) do
        local b = AddBlipForCoord(s.coords.x, s.coords.y, s.coords.z)
        SetBlipSprite(b, 500) SetBlipScale(b, 0.8) SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName(s.label or 'Hôtel des ventes') EndTextCommandSetBlipName(b)
    end
    while true do
        local w = 1500
        local p = GetEntityCoords(PlayerPedId())
        for _, s in ipairs(Config.Spots) do
            if #(p - s.coords) < 25.0 then
                w = 0
                DrawMarker(23, s.coords.x, s.coords.y, s.coords.z - 0.95, 0, 0, 0, 0, 0, 0, 1.2, 1.2, 0.6, 253, 194, 125, 150, false, false, 2, false, nil, nil, false)
                if #(p - s.coords) < (s.radius or 3.0) then
                    if GetResourceState('pickax_notify') == 'started' then exports['pickax_notify']:ShowHelpNotification('~INPUT_CONTEXT~ Hôtel des ventes')
                    else BeginTextCommandDisplayHelp('STRING') AddTextComponentSubstringPlayerName('~INPUT_CONTEXT~ Hôtel des ventes') EndTextCommandDisplayHelp(0, false, false, -1) end
                    if IsControlJustPressed(0, 38) then show() end
                end
            end
        end
        Wait(w)
    end
end)

local RPC = { list = 'pickax_auction:list', inventory = 'pickax_auction:inventory', create = 'pickax_auction:create', bid = 'pickax_auction:bid', cancel = 'pickax_auction:cancel', claim = 'pickax_auction:claim' }
RegisterNUICallback('rpc', function(body, cb)
    local n = body and body.name
    if n == 'close' then close() return cb({ ok = true }) end
    local ev = RPC[n]
    if not ev then return cb({ ok = false, error = 'Commande inconnue' }) end
    cb(lib.callback.await(ev, false, table.unpack(body.args or {})) or { ok = false, error = 'Pas de réponse' })
end)
AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() and open then SetNuiFocus(false, false) end end)
