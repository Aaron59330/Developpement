ESX = exports["es_extended"]:getSharedObject()
Player = {
    WeaponData = {}
}

function LoadESX()
    while ESX == nil do
		ESX = exports["es_extended"]:getSharedObject()
        Citizen.Wait(0)
    end

	while ESX.GetPlayerData() == nil do
		Citizen.Wait(10)
	end

	while ESX.GetPlayerData().inventory == nil do
		Citizen.Wait(10)
	end

	while ESX.GetPlayerData().job == nil do
        Citizen.Wait(10)
    end

    while ESX.GetPlayerData().job2 == nil do
        Citizen.Wait(10)
    end
    
	ESX.PlayerData = ESX.GetPlayerData()
	Player.WeaponData = ESX.GetWeaponList()

	for i = 1, #Player.WeaponData, 1 do
		if Player.WeaponData[i].name == 'WEAPON_UNARMED' then
			Player.WeaponData[i] = nil
		else
			Player.WeaponData[i].hash = GetHashKey(Player.WeaponData[i].name)
		end
    end

    print(ESXCustomPrefixes.dev..' ESX STARTED')
	
	ESXCustom.load("Initialisation - Lancement.")
    Citizen.Wait(1500)
	ESXCustom.load("Initialisation - Lancement..")
	Citizen.Wait(1500)
	ESXCustom.load("Initialisation - Lancement...")
    Citizen.Wait(2000)
    ESXCustom.load(false)
end

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	ESX.PlayerData.job = job
	TriggerServerEvent("CorePickax:OnSetJob")
end)

RegisterNetEvent('esx:setJob2')
AddEventHandler('esx:setJob2', function(job2)
	ESX.PlayerData.job2 = job2
end)

RegisterNetEvent('esx:setGroup')
AddEventHandler('esx:setGroup', function(group, lastGroup)
	ESX.PlayerData.group = group
end)

RegisterNetEvent('esx:activateMoney')
AddEventHandler('esx:activateMoney', function(money)
    ESX.PlayerData.money = money
end)

RegisterNetEvent('esx:setAccountMoney')
AddEventHandler('esx:setAccountMoney', function(account)
	for i = 1, #ESX.PlayerData.accounts, 1 do
		if ESX.PlayerData.accounts[i].name == account.name then
			ESX.PlayerData.accounts[i] = account
			break
		end
	end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    LoadESX() -- @INIT ESX
	TriggerServerEvent("CorePickax:OnPlayerLoaded", xPlayer)
end)

PlayerLoadedPed = false
AddEventHandler('switchFinished', function()
	PlayerLoadedPed = true
	TriggerServerEvent("switchFinished")
end)

Citizen.CreateThread(function()
    LoadESX()
end)

function DrawMissionText(msg, time)
    ClearPrints()
    SetTextEntry_2("STRING")
    AddTextComponentString(msg)
    DrawSubtitleTimed(time and math.ceil(time) or 0, true)
end