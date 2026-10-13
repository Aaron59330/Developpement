local requestedIpl = {
    "h4_islandairstrip",
    "h4_islandairstrip_props",
    "h4_islandx_mansion",
    "h4_islandx_mansion_props",
    "h4_islandx_props",
    "h4_islandxdock",
    "h4_islandxdock_props",
    "h4_islandxdock_props_2",
    "h4_islandxtower",
    "h4_islandx_maindock",
    "h4_islandx_maindock_props",
    "h4_islandx_maindock_props_2",
    "h4_IslandX_Mansion_Vault",
    "h4_islandairstrip_propsb",
    "h4_beach",
    "h4_beach_props",
    "h4_beach_bar_props",
    "h4_islandx_barrack_props",
    "h4_islandx_checkpoint",
    "h4_islandx_checkpoint_props",
    "h4_islandx_Mansion_Office",
    "h4_islandx_Mansion_LockUp_01",
    "h4_islandx_Mansion_LockUp_02",
    "h4_islandx_Mansion_LockUp_03",
    "h4_islandairstrip_hangar_props",
    "h4_IslandX_Mansion_B",
    "h4_islandairstrip_doorsclosed",
    "h4_Underwater_Gate_Closed",
    "h4_mansion_gate_closed",
    "h4_aa_guns",
    "h4_IslandX_Mansion_GuardFence",
    "h4_IslandX_Mansion_Entrance_Fence",
    "h4_IslandX_Mansion_B_Side_Fence",
    "h4_IslandX_Mansion_Lights",
    "h4_islandxcanal_props",
    "h4_beach_props_party",
    "h4_islandX_Terrain_props_06_a",
    "h4_islandX_Terrain_props_06_b",
    "h4_islandX_Terrain_props_06_c",
    "h4_islandX_Terrain_props_05_a",
    "h4_islandX_Terrain_props_05_b",
    "h4_islandX_Terrain_props_05_c",
    "h4_islandX_Terrain_props_05_d",
    "h4_islandX_Terrain_props_05_e",
    "h4_islandX_Terrain_props_05_f",
    "H4_islandx_terrain_01",
    "H4_islandx_terrain_02",
    "H4_islandx_terrain_03",
    "H4_islandx_terrain_04",
    "H4_islandx_terrain_05",
    "H4_islandx_terrain_06",
    "h4_ne_ipl_00",
    "h4_ne_ipl_01",
    "h4_ne_ipl_02",
    "h4_ne_ipl_03",
    "h4_ne_ipl_04",
    "h4_ne_ipl_05",
    "h4_ne_ipl_06",
    "h4_ne_ipl_07",
    "h4_ne_ipl_08",
    "h4_ne_ipl_09",
    "h4_nw_ipl_00",
    "h4_nw_ipl_01",
    "h4_nw_ipl_02",
    "h4_nw_ipl_03",
    "h4_nw_ipl_04",
    "h4_nw_ipl_05",
    "h4_nw_ipl_06",
    "h4_nw_ipl_07",
    "h4_nw_ipl_08",
    "h4_nw_ipl_09",
    "h4_se_ipl_00",
    "h4_se_ipl_01",
    "h4_se_ipl_02",
    "h4_se_ipl_03",
    "h4_se_ipl_04",
    "h4_se_ipl_05",
    "h4_se_ipl_06",
    "h4_se_ipl_07",
    "h4_se_ipl_08",
    "h4_se_ipl_09",
    "h4_sw_ipl_00",
    "h4_sw_ipl_01",
    "h4_sw_ipl_02",
    "h4_sw_ipl_03",
    "h4_sw_ipl_04",
    "h4_sw_ipl_05",
    "h4_sw_ipl_06",
    "h4_sw_ipl_07",
    "h4_sw_ipl_08",
    "h4_sw_ipl_09",
    "h4_islandx_mansion",
    "h4_islandxtower_veg",
    --"h4_islandx_sea_mines",
    "h4_islandx",
    "h4_islandx_barrack_hatch",
    "h4_islandxdock_water_hatch",
    "h4_beach_party"
}

Citizen.CreateThread(function()
    local islandLoaded = false
    local islandCoords = vec3(4840.571, -5174.425, 2.0)
    SetZoneEnabled(GetZoneFromNameId("PROL"), false)
    SetZoneEnabled(GetZoneFromNameId("PRLOG"), false)
    while true do
        local PlayerCoords = GetEntityCoords(PlayerPedId(), false)
        if #(PlayerCoords - islandCoords) < 2000.0 then
            if not islandLoaded then
                islandLoaded = true
                SetIslandHopperEnabled("HeistIsland", true)
                for i = 1, #requestedIpl do
                    RequestIpl(requestedIpl[i])
                end
                LoadGlobalWaterType(1)
                SetScenarioGroupEnabled('Heist_Island_Peds', true)
                SetAiGlobalPathNodesType(1)
                SetAudioFlag("PlayerOnDLCHeist4Island", true)
                SetAmbientZoneListStatePersistent('AZL_DLC_Hei4_Island_Zones', true, true) -- Ambient Sounds For Cayo Perico
                SetAmbientZoneListStatePersistent('AZL_DLC_Hei4_Island_Disabled_Zones', false, true) -- Other Ambient Sounds
                RequestScriptAudioBank("DLC_HEI4/DLCHEI4_GENERIC_01", false, -1)
            end
        else
            if islandLoaded then
                islandLoaded = false
                SetIslandHopperEnabled("HeistIsland", false)
                for i = 1, #requestedIpl do
                    RemoveIpl(requestedIpl[i])
                end
                LoadGlobalWaterType(0)
                SetScenarioGroupEnabled('Heist_Island_Peds', false)
                SetAiGlobalPathNodesType(0)
                SetAudioFlag("PlayerOnDLCHeist4Island", false)
                SetAmbientZoneListStatePersistent('AZL_DLC_Hei4_Island_Zones', false, true) -- Ambient Sounds For Cayo Perico
                SetAmbientZoneListStatePersistent('AZL_DLC_Hei4_Island_Disabled_Zones', true, true) -- Other Ambient Sounds
                ReleaseNamedScriptAudioBank("DLC_HEI4/DLCHEI4_GENERIC_01")
            end
        end
        Wait(1000)
    end
end)

Citizen.CreateThread(function()
    while true do
        SetRadarAsExteriorThisFrame()
        SetRadarAsInteriorThisFrame(`h4_fake_islandx`, vec(4700.0, -5145.0), 0, 0)
        Wait(0)
    end
end)

RegisterCommand('id', function(source, args, raw)
	local serverID = GetPlayerServerId(PlayerId())
	ESX.ShowNotification("Votre ~b~ID~s~ est le " .. serverID .. "~s~")
end)

Citizen.CreateThread(function()
	while true do
		local timer = 500
		if IsPedOnFoot(PlayerPedId()) then 
			SetRadarZoom(900)
		elseif IsPedInAnyVehicle(PlayerPedId(), true) then
			SetRadarZoom(900)
		end
		Citizen.Wait(timer)
	end
end)