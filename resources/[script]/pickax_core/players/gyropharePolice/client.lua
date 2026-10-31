-- Barre d'aide des sirènes : affichée par pickax_ui (couleur du serveur), plus de bandeau GTA natif
local entries = {}
local LABELS = {}   -- « ESC_ENABLE » → texte affiché (rempli plus bas)

local function refreshKeys()
    if #entries == 0 then pcall(function() exports.pickax_ui:KeysHide('sirenes') end) return end
    local items = {}
    for _, e in ipairs(entries) do
        local ok, key = pcall(function() return exports.pickax_ui:ControlKey(e.control, 2) end)
        items[#items + 1] = { key = ok and key or '?', label = LABELS[e.name] or e.name }
    end
    pcall(function() exports.pickax_ui:KeysShow('sirenes', items) end)
end

function SetInstructionalButton(name, control, enabled)
    local found = false
    for k, entry in next, entries do
        if entry.name == name and entry.control == control then
            found = true
            if not enabled then table.remove(entries, k) refreshKeys() end
            break
        end
    end
    if not found and enabled then
        table.insert(entries, { name = name, control = control })
        refreshKeys()
    end
end

--Script général
local CONTROLS = {
    TOGGLE = {"", 80 --[[INPUT_VEH_CIN_CAM]]},
    ENABLE = {"Activer les sirènes", 80 --[[INPUT_VEH_CIN_CAM]]},
    DISABLE = {"Desactiver les sirènes", 80 --[[INPUT_VEH_CIN_CAM]]},
    LIGHTS = {"Désactiver les lumières d'urgence", 86 --[[INPUT_VEH_HORN]]},
}

Citizen.CreateThread(function()
    AddTextEntry("ESC_ENABLE", CONTROLS['ENABLE'][1])
    AddTextEntry("ESC_DISABLE", CONTROLS['DISABLE'][1])
    AddTextEntry("ESC_LIGHTS", CONTROLS['LIGHTS'][1])
    LABELS.ESC_ENABLE, LABELS.ESC_DISABLE, LABELS.ESC_LIGHTS = CONTROLS['ENABLE'][1], CONTROLS['DISABLE'][1], CONTROLS['LIGHTS'][1]

    DecorRegister("esc_siren_enabled", 2)
    DecorRegisterLock()
    while true do
        local timer = 200
        local veh = GetVehiclePedIsUsing(PlayerPedId())
        if veh ~= 0 then
            timer = 0

            for k, v in pairs(ConfigGyro.AllowListVehicle) do
                if GetEntityModel(veh) == GetHashKey(v) then
                    if IsVehicleSirenOn(veh) then
                        DisableControlAction(0, CONTROLS['TOGGLE'][2], true)
                        SetInstructionalButton("ESC_LIGHTS", CONTROLS['LIGHTS'][2], true)
                        if DecorExistOn(veh, "esc_siren_enabled") and DecorGetBool(veh, "esc_siren_enabled") then
                            SetInstructionalButton("ESC_ENABLE", CONTROLS['ENABLE'][2], false)
                            SetInstructionalButton("ESC_DISABLE", CONTROLS['DISABLE'][2], true)
                            if IsDisabledControlJustPressed(0, CONTROLS['TOGGLE'][2]) then
                                DecorSetBool(veh, "esc_siren_enabled", false)
                                PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
                            end
                        else
                            SetInstructionalButton("ESC_ENABLE", CONTROLS['ENABLE'][2], true)
                            SetInstructionalButton("ESC_DISABLE", CONTROLS['DISABLE'][2], false)
                            if IsDisabledControlJustPressed(0, CONTROLS['TOGGLE'][2]) then
                                DecorSetBool(veh, "esc_siren_enabled", true)
                                PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
                            end
                        end
                    else
                        SetInstructionalButton("ESC_ENABLE", CONTROLS['ENABLE'][2], false)
                        SetInstructionalButton("ESC_DISABLE", CONTROLS['DISABLE'][2], false)
                        SetInstructionalButton("ESC_LIGHTS", CONTROLS['LIGHTS'][2], false)
                    end
                end
            end
        end

        Wait(timer)
    end
end)

Citizen.CreateThread(function()
    while true do
        local timer = 200

        for k, v in pairs(ConfigGyro.AllowListVehicle) do
            if GetEntityModel(GetVehiclePedIsUsing(PlayerPedId()), -1) == GetHashKey(v) then
                if (GetPedInVehicleSeat(GetVehiclePedIsUsing(PlayerPedId()), -1) == GetPlayerPed(PlayerId())) then
                    timer = 0
                    if DecorExistOn(GetVehiclePedIsUsing(PlayerPedId()), "esc_siren_enabled") and DecorGetBool(GetVehiclePedIsUsing(PlayerPedId()), "esc_siren_enabled") then
                        DisableVehicleImpactExplosionActivation(GetVehiclePedIsUsing(PlayerPedId()), false)
                    else
                        DisableVehicleImpactExplosionActivation(GetVehiclePedIsUsing(PlayerPedId()), true)
                    end
                end
            end
            -- if IsPedInAnyPoliceVehicle(GetPlayerPed(PlayerId())) then
                -- if (GetPedInVehicleSeat(GetVehiclePedIsUsing(PlayerPedId()), -1) == GetPlayerPed(PlayerId())) then
                --     timer = 0
                --     if DecorExistOn(GetVehiclePedIsUsing(PlayerPedId()), "esc_siren_enabled") and DecorGetBool(GetVehiclePedIsUsing(PlayerPedId()), "esc_siren_enabled") then
                --         DisableVehicleImpactExplosionActivation(GetVehiclePedIsUsing(PlayerPedId()), false)
                --     else
                --         DisableVehicleImpactExplosionActivation(GetVehiclePedIsUsing(PlayerPedId()), true)
                --     end
                -- end
            -- end
        end

        Wait(timer)
    end
end)