-- Menu « Véhicule d'urgence » (F6 → Gyrophares & sirènes) : sirène, gyrophares, phares, clignotants, détresse, lumière intérieure et extras (barre lumineuse).
-- Le joueur doit être au volant. Tout se pilote depuis le NUI (NuiLocal 'vehctl:state' / 'vehctl:set').

local local_state = {}   -- [vehicule] = { lights = 0|1|2, indL, indR, interior }

local function driverVehicle()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= ped then return nil end
    return veh
end

local function st(veh)
    local s = local_state[veh]
    if not s then s = { lights = 0, indL = false, indR = false, interior = false } local_state[veh] = s end
    return s
end

local function snapshot()
    local veh = driverVehicle()
    if not veh then return { ok = true, inVehicle = false } end
    local s = st(veh)
    local _, lightsOn, highOn = GetVehicleLightsState(veh)
    local extras = {}
    for i = 1, 14 do
        if DoesExtraExist(veh, i) then extras[#extras + 1] = { id = i, on = IsVehicleExtraTurnedOn(veh, i) } end
    end
    return {
        ok = true, inVehicle = true,
        name = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(veh))),
        plate = GetVehicleNumberPlateText(veh),
        siren = IsVehicleSirenOn(veh) == true,
        muted = s.muted == true,
        lights = s.lights, headlights = lightsOn == 1, high = highOn == 1,
        indL = s.indL, indR = s.indR, hazard = s.indL and s.indR,
        interior = s.interior, extras = extras,
    }
end

local function applyIndicators(veh, s)
    SetVehicleIndicatorLights(veh, 1, s.indL)
    SetVehicleIndicatorLights(veh, 0, s.indR)
end

local handlers = {
    siren = function(veh, s) SetVehicleSiren(veh, not IsVehicleSirenOn(veh)) end,
    mute = function(veh, s) s.muted = not s.muted SetVehicleHasMutedSirens(veh, s.muted) end,
    blip = function(veh) BlipSiren(veh) end,
    horn = function(veh) StartVehicleHorn(veh, 900, `HELDDOWN`, false) end,
    lights = function(veh, s, v) s.lights = tonumber(v) or 0 SetVehicleLights(veh, s.lights) end,
    high = function(veh, s) local _, _, h = GetVehicleLightsState(veh) SetVehicleFullbeam(veh, h ~= 1) if h ~= 1 and s.lights == 0 then s.lights = 2 SetVehicleLights(veh, 2) end end,
    left = function(veh, s) s.indL = not s.indL s.indR = false applyIndicators(veh, s) end,
    right = function(veh, s) s.indR = not s.indR s.indL = false applyIndicators(veh, s) end,
    hazard = function(veh, s) local on = not (s.indL and s.indR) s.indL, s.indR = on, on applyIndicators(veh, s) end,
    interior = function(veh, s) s.interior = not s.interior SetVehicleInteriorlight(veh, s.interior) end,
    extra = function(veh, s, v)
        v = tonumber(v)
        if v and DoesExtraExist(veh, v) then SetVehicleExtra(veh, v, IsVehicleExtraTurnedOn(veh, v)) end   -- 2e paramètre = « désactiver »
    end,
    off = function(veh, s)
        SetVehicleSiren(veh, false) s.muted = false SetVehicleHasMutedSirens(veh, false)
        s.indL, s.indR, s.interior, s.lights = false, false, false, 0
        applyIndicators(veh, s) SetVehicleInteriorlight(veh, false) SetVehicleFullbeam(veh, false) SetVehicleLights(veh, 0)
    end,
}

NuiLocal['vehctl:state'] = function(_, cb) cb(snapshot()) end

NuiLocal['vehctl:set'] = function(args, cb)
    local veh = driverVehicle()
    if not veh then return cb({ ok = false, error = 'Monte au volant d\'un véhicule pour utiliser ce menu' }) end
    local h = handlers[args[1]]
    if not h then return cb({ ok = false, error = 'Commande inconnue' }) end
    h(veh, st(veh), args[2])
    Wait(80)   -- laisse le jeu appliquer l'état avant de le relire
    cb(snapshot())
end

AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() then local_state = {} end end)
