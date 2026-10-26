local firstSpawn = true
local customPresence = nil   -- statut Discord réglé depuis le panel web (pickax_settings > Discord) ; nil = statut d'origine
local function onSettings(all, ov)
    if ov and ov.discord_status ~= nil then
        local t = tostring(all.discord_status or '')
        customPresence = t ~= '' and t or nil
    end
end
AddEventHandler('pickax_settings:changed', onSettings)
CreateThread(function()
    Wait(4000)
    if GetResourceState('pickax_settings') ~= 'started' then return end
    local ok, all = pcall(function() return exports.pickax_settings:GetAll() end)
    local ok2, ov = pcall(function() return exports.pickax_settings:Overrides() end)
    if ok and ok2 and type(ov) == 'table' then onSettings(all, ov) end
end)
AddEventHandler('playerSpawned', function()
    if firstSpawn then
        for _, v in pairs(ConfigDiscord.Buttons) do
            SetDiscordRichPresenceAction(v.index, v.name, v.url)
        end
        firstSpawn = false
    end
end)

--Info Discord & Option
Citizen.CreateThread(function()
	players = {}
	for _, player in ipairs(GetActivePlayers()) do
		local ped = GetPlayerPed(player)
		table.insert( players, player )
	end

    local name = GetPlayerName(PlayerId())
    local id = GetPlayerServerId(PlayerId())
   	AddTextEntry('PM_PANE_LEAVE', ConfigDiscord.PauseMenu.Leave)
    AddTextEntry('PM_PANE_QUIT', ConfigDiscord.PauseMenu.Quit)
    AddTextEntry('PM_SCR_MAP', ConfigDiscord.PauseMenu.Map)
    AddTextEntry('PM_SCR_GAM', ConfigDiscord.PauseMenu.Gam)
    AddTextEntry('PM_SCR_INF', ConfigDiscord.PauseMenu.Inf)
    AddTextEntry('PM_SCR_SET', ConfigDiscord.PauseMenu.Conf)
    AddTextEntry('PM_SCR_STA', ConfigDiscord.PauseMenu.Sta)
	AddTextEntry('PM_SCR_GAL', ConfigDiscord.PauseMenu.Galerie)
    AddTextEntry('PM_SCR_RPL', ConfigDiscord.PauseMenu.Rpl)
    AddTextEntry('PM_PANE_CFX', ConfigDiscord.PauseMenu.FiveM)

    SetDiscordAppId(ConfigDiscord.ActiviteJeux.id)
    SetDiscordRichPresenceAsset(ConfigDiscord.ActiviteJeux.image1)
    SetDiscordRichPresenceAssetText(ConfigDiscord.ActiviteJeux.text1)
    SetDiscordRichPresenceAssetSmall(ConfigDiscord.ActiviteJeux.image2)
    SetDiscordRichPresenceAssetSmallText(ConfigDiscord.ActiviteJeux.text2)

    while true do
        local t = GetActivePlayers()
		local id = GetPlayerServerId(PlayerId())
        if customPresence then
            SetRichPresence((customPresence:gsub('{nom}', (name:gsub('%%', '%%%%'))):gsub('{id}', tostring(id)):gsub('{joueurs}', tostring(#t))))
        else
            SetRichPresence((ConfigDiscord.ActiviteJeux.RichPresence):format(GetPlayerName(PlayerId()), id, #t))
        end
		Citizen.InvokeNative(GetHashKey("ADD_TEXT_ENTRY"), 'FE_THDR_GTAO', (ConfigDiscord.PauseMenu.PauseMenu):format(name, id))
        Citizen.Wait(5000)
    end
end)