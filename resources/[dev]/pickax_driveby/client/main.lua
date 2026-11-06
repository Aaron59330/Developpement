local C = Config
local leaning, leanSeat, usedAnim = false, nil, nil
local lastMsg = 0

local function notify(msg)
    if GetGameTimer() - lastMsg < 3000 then return end
    lastMsg = GetGameTimer()
    TriggerEvent('esx:showNotification', msg)
end

local function inList(list, v) for _, x in ipairs(list or {}) do if x == v then return true end end return false end
local function kmh(veh) return GetEntitySpeed(veh) * 3.6 end

local ESX
CreateThread(function() local ok, e = pcall(function() return exports['es_extended']:getSharedObject() end) if ok then ESX = e end end)
local function exempt()
    if not ESX or #C.Rules.ExemptJobs == 0 then return false end
    local d = ESX.GetPlayerData and ESX.GetPlayerData() or nil
    return d and d.job and inList(C.Rules.ExemptJobs, d.job.name) or false
end

-- l'arme en main est-elle autorisée en véhicule ?
local function weaponAllowed(ped)
    if exempt() then return true end
    local w = GetSelectedPedWeapon(ped)
    if w == `WEAPON_UNARMED` then return true end
    for _, n in ipairs(C.Rules.BlockedNames) do if w == joaat(n) then return false end end
    for _, n in ipairs(C.Rules.AllowedNames) do if w == joaat(n) then return true end end
    return inList(C.Rules.AllowedGroups, GetWeapontypeGroup(w))
end

local function seatOf(veh, ped)
    for s = -1, GetVehicleModelNumberOfSeats(GetEntityModel(veh)) - 2 do if GetPedInVehicleSeat(veh, s) == ped then return s end end
end

local function stopLean(ped)
    if not leaning then return end
    leaning = false
    if usedAnim then StopAnimTask(ped, usedAnim.dict, usedAnim.clip, 2.0) usedAnim = nil end
end

local function startLean(ped, seat)
    local a = C.Lean.Animations[seat] or C.Lean.Animations.default
    leaning, leanSeat, usedAnim = true, seat, nil
    if a and a.dict and a.dict ~= '' then
        RequestAnimDict(a.dict)
        local t = GetGameTimer() + 1500
        while not HasAnimDictLoaded(a.dict) and GetGameTimer() < t do Wait(10) end
        if HasAnimDictLoaded(a.dict) then
            TaskPlayAnim(ped, a.dict, a.clip, 4.0, 4.0, -1, a.flag or 49, 0, false, false, false)
            usedAnim = a
        else
            notify('Animation introuvable : ' .. a.dict .. ' (Config.Lean.Animations)')
        end
    end
    TriggerEvent('pickax_driveby:lean', true, seat)
end

-- ─────────── règles : arme, place, vitesse, classe de véhicule ───────────
CreateThread(function()
    if not C.Enabled then return end
    while true do
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 then
            local seat = seatOf(veh, ped)
            local blocked = false
            if seat == nil or C.Rules.Seats[seat] ~= true then blocked = true
            elseif inList(C.Rules.BlockedClasses, GetVehicleClass(veh)) then blocked = true
            else
                local lim = (seat == -1) and C.Rules.MaxSpeedKmh.driver or C.Rules.MaxSpeedKmh.passenger
                if lim and lim > 0 and kmh(veh) > lim then blocked = true end
            end
            if blocked then
                -- pas de visée / tir depuis ce siège
                DisableControlAction(0, 25, true) DisableControlAction(0, 68, true) DisableControlAction(0, 69, true)
                DisableControlAction(0, 70, true) DisableControlAction(0, 91, true) DisableControlAction(0, 92, true) DisableControlAction(0, 24, true)
                stopLean(ped)
                Wait(0)
            else
                if not weaponAllowed(ped) then
                    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
                    notify(C.Rules.Message)
                end
                Wait(250)
            end
        else
            if leaning then stopLean(ped) end
            Wait(500)
        end
    end
end)

-- ─────────── sortir par la fenêtre ───────────
local function allowedToLean(ped, veh)
    if not C.Lean.Enabled then return false end
    local seat = seatOf(veh, ped)
    if seat == nil or C.Lean.Seats[seat] ~= true then return false, 'Tu ne peux pas te pencher depuis cette place.' end
    if C.Rules.Seats[seat] ~= true or inList(C.Rules.BlockedClasses, GetVehicleClass(veh)) then return false, C.Rules.Message end
    if C.Lean.MaxSpeedKmh and C.Lean.MaxSpeedKmh > 0 and kmh(veh) > C.Lean.MaxSpeedKmh then return false, 'Le véhicule va trop vite pour se pencher.' end
    if GetSelectedPedWeapon(ped) == `WEAPON_UNARMED` or not weaponAllowed(ped) then return false, 'Sors une arme autorisée pour te pencher.' end
    return true, nil, seat
end

RegisterCommand('+pickax_lean', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 or leaning then return end
    local ok, why, seat = allowedToLean(ped, veh)
    if not ok then if why and C.Lean.Notify then notify(why) end return end
    startLean(ped, seat)
end, false)
RegisterCommand('-pickax_lean', function() stopLean(PlayerPedId()) TriggerEvent('pickax_driveby:lean', false) end, false)
RegisterKeyMapping('+pickax_lean', 'Se pencher par la fenêtre (tirer)', 'keyboard', C.Lean.Key or 'B')

-- tant qu'on est penché : annule si la situation change (vitesse, arme rangée, sortie du véhicule)
CreateThread(function()
    while true do
        if leaning then
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            if veh == 0 or not (allowedToLean(ped, veh)) then stopLean(ped) TriggerEvent('pickax_driveby:lean', false)
            elseif usedAnim and not IsEntityPlayingAnim(ped, usedAnim.dict, usedAnim.clip, 3) then
                TaskPlayAnim(ped, usedAnim.dict, usedAnim.clip, 4.0, 4.0, -1, usedAnim.flag or 49, 0, false, false, false)
            end
            Wait(150)
        else Wait(400) end
    end
end)

exports('IsLeaning', function() return leaning end)
AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() then stopLean(PlayerPedId()) end end)
