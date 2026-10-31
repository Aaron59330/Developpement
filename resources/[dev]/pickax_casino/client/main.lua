local ESX = exports['es_extended']:getSharedObject()
local open, cur = false, nil

-- Les repères au sol, PNJ, blips et la touche d'interaction sont gérés par le World Builder (module « Casino ») ;
-- il appelle exports.pickax_casino:Open({ eid, pi, kind, tier, x, y, z }) quand le joueur utilise un poste.
local function close()
    if not open then return end
    open, cur = false, nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

exports('IsOpen', function() return open end)
exports('Open', function(s)
    if open or type(s) ~= 'table' or IsEntityDead(PlayerPedId()) then return end
    ESX.TriggerServerCallback('pickax_casino:state', function(st)
        if not st or not st.ok then return ESX.ShowNotification('~r~Ce poste est indisponible.') end
        local game = { kind = s.kind, tier = s.tier }
        if s.kind == 'slots' then game.cfg = Config.Slots.Machines[s.tier] game.symbols = Config.Slots.Pay3 game.cherryTwo = Config.Slots.CherryTwo
        elseif s.kind == 'blackjack' then game.cfg = Config.Blackjack.Tables[s.tier]
        elseif s.kind == 'roulette' then game.cfg = Config.Roulette.Tables[s.tier] end
        if s.kind ~= 'cashier' and not game.cfg then return ESX.ShowNotification('~r~Gamme de ce poste inconnue (World Builder → Emplacements).') end
        open, cur = true, s
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'open', state = st, game = game })
    end, s.eid, s.pi)
end)

-- Fermeture automatique si le joueur s'éloigne du poste
CreateThread(function()
    while true do
        Wait(500)
        if open and cur and #(GetEntityCoords(PlayerPedId()) - vector3(cur.x, cur.y, cur.z)) > Config.InteractDistance + 3.0 then close() end
    end
end)

RegisterNUICallback('close', function(_, cb) close() cb('ok') end)
RegisterNUICallback('buy', function(d, cb) if not cur then return cb({ ok = false }) end ESX.TriggerServerCallback('pickax_casino:buy', function(r) cb(r) end, cur.eid, cur.pi, d.chips) end)
RegisterNUICallback('sell', function(d, cb) if not cur then return cb({ ok = false }) end ESX.TriggerServerCallback('pickax_casino:sell', function(r) cb(r) end, cur.eid, cur.pi, d.chips) end)
RegisterNUICallback('slots', function(d, cb) if not cur then return cb({ ok = false }) end ESX.TriggerServerCallback('pickax_casino:slots', function(r) cb(r) end, cur.eid, cur.pi, d.bet) end)
RegisterNUICallback('bjDeal', function(d, cb) if not cur then return cb({ ok = false }) end ESX.TriggerServerCallback('pickax_casino:bj:deal', function(r) cb(r) end, cur.eid, cur.pi, d.bet) end)
RegisterNUICallback('bjAct', function(d, cb) if not cur then return cb({ ok = false }) end ESX.TriggerServerCallback('pickax_casino:bj:act', function(r) cb(r) end, d.act) end)
RegisterNUICallback('roulette', function(d, cb) if not cur then return cb({ ok = false }) end ESX.TriggerServerCallback('pickax_casino:roulette', function(r) cb(r) end, cur.eid, cur.pi, d.bets) end)
