
AddEventHandler('onClientResourceStart', function(resource)
	if resource ~= GetCurrentResourceName() then
		return
	end
	

	-- Some people modify pma-voice and mess up the resource Kvp, which means that if someone
	-- joins another server that has pma-voice, it will error out, this will catch and fix the kvp.
	local success = pcall(function()
		local micClicksKvp = GetResourceKvpString('pma-voice_enableMicClicks')
		if not micClicksKvp then
			SetResourceKvp('pma-voice_enableMicClicks', tostring(true))
		else
			if micClicksKvp ~= 'true' and micClicksKvp ~= 'false' then
				error('Invalid Kvp, throwing error for automatic cleaning')
			end
			micClicks = micClicksKvp
		end
	end)

	if not success then
		logger.warn('Failed to load resource Kvp, likely was inappropriately modified by another server, resetting the Kvp.')
		SetResourceKvp('pma-voice_enableMicClicks', tostring(true))
		micClicks = 'true'
	end
	sendUIMessage({
		uiEnabled = GetConvarInt("voice_enableUi", 1) == 1,
		voiceModes = json.encode(Cfg.voiceModes),
		voiceMode = mode - 1
	})

	-- Reinitialize channels if they're set.
	if LocalPlayer.state.radioChannel ~= 0 then
		setRadioChannel(LocalPlayer.state.radioChannel)
	end

	if LocalPlayer.state.callChannel ~= 0 then
		setCallChannel(LocalPlayer.state.callChannel)
	end

end)


-- Détection fiable : inventaire (signal direct + état du joueur) et menu pause / carte (plusieurs méthodes)
local invFlag = false
AddEventHandler('pickax:inventory', function(open) invFlag = open == true end)

local function inventoryOpen()
    return invFlag or LocalPlayer.state.invOpen == true
end

local function pauseOpen()
    if IsPauseMenuActive() then return true end
    local state = Citizen.InvokeNative(0x272ACD84970869C5, Citizen.ResultAsInteger())   -- état du menu pause (0 = fermé)
    return state ~= nil and state ~= 0
end

-- Interface vocale masquée quand l'inventaire est ouvert
CreateThread(function()
    local hidden = false
    while true do
        Wait(150)
        local open = inventoryOpen() or pauseOpen()
        if open ~= hidden then
            hidden = open
            sendUIMessage({ uiEnabled = (not open) and GetConvarInt("voice_enableUi", 1) == 1 })
        end
    end
end)
