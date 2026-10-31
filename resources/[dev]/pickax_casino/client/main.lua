local ESX = exports['es_extended']:getSharedObject()
local spots, open, cur, blip = {}, false, nil, nil

RegisterNetEvent('pickax_casino:spots', function(list)
    spots = list or {}
    if Config.Blip.enabled then
        if blip then RemoveBlip(blip) blip = nil end
        for _, s in ipairs(spots) do
            if s.kind == 'cashier' then
                blip = AddBlipForCoord(s.x, s.y, s.z)
                SetBlipSprite(blip, Config.Blip.sprite) SetBlipColour(blip, Config.Blip.color) SetBlipScale(blip, Config.Blip.scale) SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName('STRING') AddTextComponentString(Config.Blip.label) EndTextCommandSetBlipName(blip)
                break
            end
        end
    end
end)
CreateThread(function() Wait(1500) TriggerServerEvent('pickax_casino:want') end)

RegisterNetEvent('pickax_casino:addHere', function(kind, tier)
    local p = GetEntityCoords(PlayerPedId())
    TriggerServerEvent('pickax_casino:addSpot', kind, tier, p.x, p.y, p.z - 0.95, GetEntityHeading(PlayerPedId()))
end)

local LABEL = { cashier = 'la caisse du casino', slots = 'la machine à sous', blackjack = 'la table de blackjack', roulette = 'la roulette' }
local function close()
    if not open then return end
    open = false cur = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function openSpot(s)
    ESX.TriggerServerCallback('pickax_casino:state', function(st)
        if not st or not st.ok then return end
        local game = { kind = s.kind, tier = s.tier }
        if s.kind == 'slots' then game.cfg = Config.Slots.Machines[s.tier] game.symbols = Config.Slots.Pay3 game.cherryTwo = Config.Slots.CherryTwo
        elseif s.kind == 'blackjack' then game.cfg = Config.Blackjack.Tables[s.tier]
        elseif s.kind == 'roulette' then game.cfg = Config.Roulette.Tables[s.tier] end
        open, cur = true, s
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'open', state = st, game = game })
    end)
end

CreateThread(function()
    while true do
        local wait = 1000
        if not open and #spots > 0 then
            local p = GetEntityCoords(PlayerPedId())
            local best, bd
            for _, s in ipairs(spots) do
                local d = #(p - vector3(s.x, s.y, s.z))
                if d < 25.0 then
                    wait = 0
                    local c = Config.Markers[s.kind] or { 255, 255, 255 }
                    DrawMarker(1, s.x, s.y, s.z, 0, 0, 0, 0, 0, 0, 0.9, 0.9, 0.35, c[1], c[2], c[3], 120, false, false, 2, false, nil, nil, false)
                    if d <= Config.InteractDistance and (not bd or d < bd) then best, bd = s, d end
                end
            end
            if best then
                BeginTextCommandDisplayHelp('STRING')
                AddTextComponentSubstringPlayerName('~INPUT_CONTEXT~ Utiliser ' .. LABEL[best.kind])
                EndTextCommandDisplayHelp(0, false, true, -1)
                if IsControlJustReleased(0, 38) and not IsEntityDead(PlayerPedId()) then openSpot(best) end
            end
        end
        Wait(wait)
    end
end)

-- Fermeture automatique si le joueur s'éloigne du poste
CreateThread(function()
    while true do
        Wait(500)
        if open and cur and #(GetEntityCoords(PlayerPedId()) - vector3(cur.x, cur.y, cur.z)) > Config.InteractDistance + 3.0 then close() end
    end
end)

RegisterNUICallback('close', function(_, cb) close() cb('ok') end)
RegisterNUICallback('state', function(_, cb) ESX.TriggerServerCallback('pickax_casino:state', function(st) cb(st) end) end)
RegisterNUICallback('buy', function(d, cb) ESX.TriggerServerCallback('pickax_casino:buy', function(r) cb(r) end, d.chips) end)
RegisterNUICallback('sell', function(d, cb) ESX.TriggerServerCallback('pickax_casino:sell', function(r) cb(r) end, d.chips) end)
RegisterNUICallback('slots', function(d, cb) if not cur then return cb({ ok = false }) end ESX.TriggerServerCallback('pickax_casino:slots', function(r) cb(r) end, cur.tier, d.bet) end)
RegisterNUICallback('bjDeal', function(d, cb) if not cur then return cb({ ok = false }) end ESX.TriggerServerCallback('pickax_casino:bj:deal', function(r) cb(r) end, cur.tier, d.bet) end)
RegisterNUICallback('bjAct', function(d, cb) ESX.TriggerServerCallback('pickax_casino:bj:act', function(r) cb(r) end, d.act) end)
RegisterNUICallback('roulette', function(d, cb) if not cur then return cb({ ok = false }) end ESX.TriggerServerCallback('pickax_casino:roulette', function(r) cb(r) end, cur.tier, d.bets) end)
