local open = false

local function close()
    if not open then return end
    open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterCommand(Config.Command, function()
    if open then return close() end
    if not lib.callback.await('basetools:allowed', false) then return lib.notify({ type = 'error', description = 'Réservé à l\'équipe.' }) end
    open = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
end, false)

local RPC = { audit = 'basetools:audit', backups = 'basetools:backups', backup = 'basetools:backup', restore = 'basetools:restore', info = 'basetools:info', themeGet = 'basetools:themeGet', themeSave = 'basetools:themeSave', ecoGet = 'basetools:ecoGet', ecoEvent = 'basetools:ecoEvent', ecoReset = 'basetools:ecoReset' }

RegisterNUICallback('rpc', function(body, cb)
    local name = body and body.name
    if name == 'close' then close() return cb({ ok = true }) end
    local ev = RPC[name]
    if not ev then return cb({ ok = false, error = 'Commande inconnue' }) end
    cb(lib.callback.await(ev, false, table.unpack(body.args or {})) or { ok = false, error = 'Pas de réponse' })
end)

AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() and open then SetNuiFocus(false, false) end end)
