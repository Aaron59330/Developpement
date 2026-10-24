local KEY = 'firefighter'
local run = 0
local fires = {}          -- handles des feux : fires[idx] = { list = {…}, lit = bool, out = bool }
local current = nil
local blip

local function stopFires()
    for _, f in pairs(fires) do
        for _, h in ipairs(f.list or {}) do RemoveScriptFire(h) end
        if f.pos then StopFireInRange(f.pos.x, f.pos.y, f.pos.z, 12.0) end
    end
    fires = {}
    AJ.RemoveBlip(blip) blip = nil
    current = nil
end

local function groundZ(x, y, z)
    local ok, gz = GetGroundZFor_3dCoord(x, y, z + 15.0, false)
    return ok and gz or z
end

-- allume les foyers quand on est assez près pour que la zone soit chargée
local function igniteNear(inc)
    local pos = GetEntityCoords(PlayerPedId())
    for i, f in ipairs(inc.foyers) do
        local fr = fires[i]
        if not f.out and (not fr or not fr.lit) and #(pos - vector3(f.x, f.y, f.z)) < 180.0 then
            local z = groundZ(f.x, f.y, f.z)
            fr = fr or {}
            fr.pos = vector3(f.x, f.y, z)
            fr.list = {}
            for k = 1, 3 do
                fr.list[#fr.list + 1] = StartScriptFire(f.x + math.random(-10, 10) / 10, f.y + math.random(-10, 10) / 10, z, 20, false)
            end
            fr.lit = true
            fires[i] = fr
        end
    end
end

AJ.Mod[KEY] = {
    start = function(d)
        run = run + 1
        local my = run
        local veh = AJ.SpawnVehicle(d.vehicle, d.spawn, d.plate)
        GiveWeaponToPed(PlayerPedId(), joaat(d.weapon), 2000, false, true)
        SetPedInfiniteAmmo(PlayerPedId(), true, joaat(d.weapon))

        local function setIncident(inc)
            stopFires()
            current = inc
            fires = {}
            AJ.RemoveBlip(blip)
            blip = AddBlipForCoord(inc.site.x + 0.0, inc.site.y + 0.0, inc.site.z + 0.0)
            SetBlipSprite(blip, 436) SetBlipColour(blip, 1) SetBlipScale(blip, 1.0) SetBlipRoute(blip, true) SetBlipRouteColour(blip, 1)
            BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName('Incendie — ' .. inc.label) EndTextCommandSetBlipName(blip)
            AJ.Blips[#AJ.Blips + 1] = blip
            PlaySoundFrontend(-1, 'Beep_Red', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true)
            AJ.Notify(('~r~ALERTE INCENDIE~s~ — %s. Rends-toi sur place et éteins tous les foyers !'):format(inc.label))
        end
        if d.incident then setIncident(d.incident) end
        RegisterNetEvent('aj:fire:alert', function(inc) if run == my then setIncident(inc) end end)
        RegisterNetEvent('aj:fire:foyer', function(id, idx)
            if run ~= my or not current or current.id ~= id then return end
            current.foyers[idx].out = true
            local fr = fires[idx]
            if fr then for _, h in ipairs(fr.list or {}) do RemoveScriptFire(h) end if fr.pos then StopFireInRange(fr.pos.x, fr.pos.y, fr.pos.z, 8.0) end fr.out = true end
        end)
        RegisterNetEvent('aj:fire:clear', function(id, reason)
            if run ~= my then return end
            stopFires()
            if reason == 'done' then AJ.Notify('Incendie maîtrisé, bravo l\'équipe !') elseif reason == 'expired' then AJ.Notify('~r~L\'incendie s\'est propagé : mission échouée.') end
            AJ.SetHud({ 'POMPIER', 'Aucun incendie en cours', '→ Reste au camion, une alerte arrivera' })
        end)

        AJ.SetHud({ 'POMPIER', 'Aucun incendie en cours', '→ Reste au camion, une alerte arrivera' })

        CreateThread(function()
            while run == my and AJ.Active == KEY do
                if current then
                    igniteNear(current)
                    local pos = GetEntityCoords(PlayerPedId())
                    local left, total = 0, 0
                    for i, f in ipairs(current.foyers) do
                        total = total + 1
                        local fr = fires[i]
                        if f.out then
                        elseif fr and fr.lit and not fr.out then
                            -- foyer éteint localement quand plus aucune flamme dans le rayon (2 contrôles d'affilée)
                            if GetNumberOfFiresInRange(fr.pos.x, fr.pos.y, fr.pos.z, 4.5) == 0 then
                                fr.zero = (fr.zero or 0) + 1
                                if fr.zero >= 2 then
                                    fr.out = true
                                    f.out = true
                                    TriggerServerEvent('aj:fire:foyerOut', current.id, i)
                                end
                            else fr.zero = 0 end
                            if not f.out then left = left + 1 end
                        else left = left + 1 end
                    end
                    AJ.SetHud({ 'POMPIER', current.label, ('Foyers restants : %d / %d'):format(left, total), veh and DoesEntityExist(veh) and '→ Canon à eau : tir du camion / extincteur' or '→ Extincteur' })
                end
                Wait(1000)
            end
        end)
    end,
    stop = function()
        run = run + 1
        stopFires()
        local ped = PlayerPedId()
        SetPedInfiniteAmmo(ped, false, joaat('WEAPON_FIREEXTINGUISHER'))
        RemoveWeaponFromPed(ped, joaat('WEAPON_FIREEXTINGUISHER'))
    end,
}
