local ESX = exports['es_extended']:getSharedObject()
local open = false

local function close()
    if not open then return end
    open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function toggle()
    if open then return close() end
    ESX.TriggerServerCallback('carnet:snapshot', function(d)
        if not d or not d.ok then
            ESX.ShowNotification((d and d.error) or 'Carnet indisponible pour le moment.')
            return
        end
        open = true
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'open', data = d })
    end)
end

RegisterCommand(Config.Command, toggle, false)
RegisterKeyMapping(Config.Command, 'Ouvrir le carnet (objectifs et série)', 'keyboard', Config.Key)

RegisterNUICallback('close', function(_, cb) close() cb('ok') end)
RegisterNUICallback('refresh', function(_, cb)
    ESX.TriggerServerCallback('carnet:snapshot', function(d) cb(d or { ok = false }) end)
end)

-- Distance parcourue : échantillon toutes les 5 s (un saut > MaxJump = téléportation, ignoré), envoyé toutes les 30 s
CreateThread(function()
    Wait(15000)
    local last, acc, sent = nil, 0.0, 0
    while true do
        Wait(5000)
        local c = GetEntityCoords(PlayerPedId())
        if last then
            local d = #(vector2(c.x, c.y) - vector2(last.x, last.y))
            if d <= Config.Distance.MaxJump then acc = acc + d end
        end
        last = c
        sent = sent + 5
        if sent >= 30 then
            sent = 0
            if acc >= 20.0 then TriggerServerEvent('pickax_carnet:dist', acc) end
            acc = 0.0
        end
    end
end)
