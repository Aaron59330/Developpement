local open = false
local headHandle = nil

local function ClearHeadshot()
	if headHandle then
		UnregisterPedheadshot(headHandle)
		headHandle = nil
	end
end

-- Photo (pedheadshot) du propriétaire de la carte, nil s'il n'est pas à portée
local function GetOwnerHead(owner)
	local ped
	if owner == nil or owner == GetPlayerServerId(PlayerId()) then
		ped = PlayerPedId()
	else
		local player = GetPlayerFromServerId(owner)
		if player == -1 then return nil end
		ped = GetPlayerPed(player)
	end

	ClearHeadshot()
	local handle = RegisterPedheadshotTransparent(ped)
	local timeout = GetGameTimer() + 3000

	while not IsPedheadshotReady(handle) or not IsPedheadshotValid(handle) do
		if GetGameTimer() > timeout then
			UnregisterPedheadshot(handle)
			return nil
		end
		Wait(50)
	end

	headHandle = handle
	local txd = GetPedheadshotTxdString(handle)
	return "https://nui-img/" .. txd .. "/" .. txd
end

-- Open ID card
RegisterNetEvent('jsfour-idcard:open', function( data, type )
	open = true
	local head = GetOwnerHead(data.owner)
	SendNUIMessage({
		action = "open",
		array  = data,
		type   = type,
		head   = head
	})
end)

-- Key events

Citizen.CreateThread(function()
	while true do
		if not open then
			Wait(1000)
		else
			ESX.ShowHelpNotification(ConfigJsFourd.Text)
			Wait(0)
		end
		if IsControlJustReleased(0, 322) and open or IsControlJustReleased(0, 177) and open then
			SendNUIMessage({
				action = "close"
			})
			open = false
			ClearHeadshot()
		end
	end
end)
