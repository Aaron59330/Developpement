CreateThread(function()
	TriggerEvent('chat:addSuggestion', '/'..ConfigJail.Commande.jail, 'Jail un joueur',{
		{ name = "Id du joueur", help = "L'id du joueur" },
		{ name = "Temps", help = "Exemple : 10 = 10 minute"},
		{ name = "Raison", help = "Exemple : Troll + freekill"}
	})
	TriggerEvent('chat:addSuggestion', '/'..ConfigJail.Commande.unjail, 'unjail un joueur',{
		{ name = "Id du joueur", help = "L'id du joueur" }
	})
	TriggerEvent('chat:addSuggestion', '/'..ConfigJail.Commande.OpenMenu, 'Gestion des jails',{
	})
end)

local isInJail, unjail = false, false
local jailTime, fastTimer = 0, 0
local author = nil

--GetTimer
function formatDuration(milliseconds)
	local milliseconds = tonumber(milliseconds)
    local totalSeconds = milliseconds
    local minutes = math.floor(totalSeconds / 60)
    local seconds = math.floor(totalSeconds % 60)
    return string.format("%02d:%02d", minutes, seconds)
end

RegisterNetEvent('CorePickax:unjailPlayer', function()
	unjail = true
	jailTime = 0
	fastTimer = 0
	author = nil
	isInJail = false

	ESX.TriggerServerCallback("esx_skin:getPlayerSkin", function(skin)
		TriggerEvent("skinchanger:loadSkin", skin)
	end)
end)

-- La peine a été réduite côté serveur (travail en prison)
RegisterNetEvent('CorePickax:JailReduce', function(left)
	if isInJail then jailTime = tonumber(left) or jailTime end
end)

RegisterNetEvent("CorePickax:SetJail", function(_jailTime, author, reason)
	jailTime = _jailTime
	local playerPed = PlayerPedId()

	TriggerEvent("skinchanger:getSkin", function(skin)
		if skin.sex == 0 then
			TriggerEvent("skinchanger:loadClothes", skin, ConfigJail.TenueJail.male)
		else
			TriggerEvent("skinchanger:loadClothes", skin, ConfigJail.TenueJail.female)
		end
	end)

	RageUI.CloseAll()

	CreateThread(function()
		local mainmenu = RageUI.CreateMenu(ConfigJail.Menu["Title"], ConfigJail.Menu["Substitle"])

		RageUI.Visible(mainmenu, not RageUI.Visible(mainmenu))
		mainmenu.Closable = false

		while true do
			local Time = formatDuration(jailTime)
			RageUI.IsVisible(mainmenu, true, true, true, function()
				RageUI.Line()
				RageUI.Separator((ConfigJail.Menu["Jail"]):format(author))
				RageUI.Separator((ConfigJail.Menu["Temps"]):format(Time))
				RageUI.Separator((ConfigJail.Menu["Raison"]):format(reason))
				RageUI.Line()
			end)

			if unjail then
				RageUI.Visible(mainmenu, false)
				break
			end

			if not RageUI.Visible(mainmenu) then
				mainmenu = RMenu:DeleteType("mainmenu")
			end

			Wait(0)
		end
	end)

	CreateThread(function()
        while true do

            if jailTime == 0 then
				unjail = true
                break
            end

			jailTime = jailTime - 1

			if unjail then
				jailTime = 0
				break
			end

            Wait(1000)
        end
    end)

	isInJail = true
	unjail = false

	while not unjail do
		playerPed = PlayerPedId()

		if IsPedInAnyVehicle(playerPed, false) then
			ClearPedTasksImmediately(playerPed)
		end

		if unjail then
			break
		end

		Citizen.Wait(1000)
	end
end)

local CacheSystem = {}
RegisterNetEvent("CorePickax:AddClientSideJail", function(LeModeZombieSaDechire)
	CacheSystem = LeModeZombieSaDechire
end)

local jailTimerStaff = nil
local send = false
local Time = nil

RegisterNetEvent("CorePickax:OpenMenuGestionJail", function()
	TriggerServerEvent("CorePickax:SendServerSideJail")
	OpenMenuStaff()
end)

function OpenMenuStaff()
	local mainmenu = RageUI.CreateMenu(ConfigJail.Notification["GestionStaffTitle"], ConfigJail.Notification["GestionStaffSubsTitle"])
	local mainmenu2 = RageUI.CreateSubMenu(mainmenu, ConfigJail.Notification["GestionStaffTitle2"], ConfigJail.Notification["GestionStaffSubsTitle2"])

	RageUI.Visible(mainmenu, not RageUI.Visible(mainmenu))

	mainmenu2.Closed = function()
		send = false
		jailTimerStaff = nil
	end

	TriggerServerEvent("CorePickax:SendServerSideJail")

	while mainmenu do
		RageUI.IsVisible(mainmenu, true, true, true, function()
			for k, v in pairs(CacheSystem) do
				RageUI.ButtonWithStyle((ConfigJail.Notification["ButonPlayer"]):format(v.name, v.id), ConfigJail.Notification["DescPlayer"], {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
					if Selected then
						identifier = v.identifier

						TriggerServerEvent("CorePickax:SendServerSideJail")
					end
				end, mainmenu2)
			end
		end)

		RageUI.IsVisible(mainmenu2, true, true, true, function()
			RageUI.Line()
			RageUI.Separator((ConfigJail.Menu["Jail"]):format(CacheSystem[identifier].name))
			if not send then
				send = true
				jailTimerStaff = CacheSystem[identifier].temps
			end
			RageUI.Separator((ConfigJail.Menu["Temps"]):format(Time))
			RageUI.Separator((ConfigJail.Menu["Raison"]):format(CacheSystem[identifier].reason))
			RageUI.Line()

			RageUI.ButtonWithStyle((ConfigJail.Notification["ButonPlayer2"]):format(CacheSystem[identifier].name, CacheSystem[identifier].id), (ConfigJail.Notification["DescPlayer2"]):format(CacheSystem[identifier].reason), {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
				if Selected then
					ExecuteCommand(ConfigJail.Commande.unjail.." "..CacheSystem[identifier].id)
					RageUI.CloseAll()
				end
			end)
		end)

		if not RageUI.Visible(mainmenu) and not RageUI.Visible(mainmenu2) then
			send = false
			jailTimerStaff = nil
			mainmenu = RMenu:DeleteType("mainmenu")
		end

		Wait(0)
	end
end

CreateThread(function()
	while true do
		if jailTimerStaff ~= nil then
			if jailTimerStaff == 0 then
				jailTimerStaff = nil
				break
			end
		
			jailTimerStaff = jailTimerStaff - 1
			Time = formatDuration(jailTimerStaff)
		end
	
		Wait(1000)
	end
end)