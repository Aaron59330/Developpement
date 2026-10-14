local isShowing = false
local prevData = {speed = nil, fuel = nil, engine = nil, headlight = nil}

local function toggleNuiFrame(shouldShow)
    SendReactMessage('setVisible', shouldShow)
end

CreateThread(function()
    while true do
        local wait = 1000 

        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        local isDriver = (vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped)

        if isDriver then
            if not isShowing then
                toggleNuiFrame(true)
                isShowing = true
            end

            local speed = math.floor(GetEntitySpeed(vehicle) * 3.6)
            local fuel = math.floor(GetVehicleFuelLevel(vehicle)) 
            local engine = GetIsVehicleEngineRunning(vehicle)
            local headlight = GetVehicleDashboardLights(vehicle) ~= 0

            if prevData.speed ~= speed then
                SendReactMessage('setSpeed', speed)
                prevData.speed = speed
            end

            if prevData.fuel ~= fuel then
                SendReactMessage('setFuel', fuel)
                prevData.fuel = fuel
            end

            if prevData.engine ~= engine or prevData.headlight ~= headlight then
                SendReactMessage('setIcons', { engine = engine, headlight = headlight })
                prevData.engine = engine
                prevData.headlight = headlight
            end

            wait = 300
        else
            if isShowing then
                toggleNuiFrame(false)
                isShowing = false
                prevData = {speed = nil, fuel = nil, engine = nil, headlight = nil}
            end
            wait = 1500 
        end

        Wait(wait)
    end
end)




-- Masque le compteur quand l'inventaire est ouvert, le réaffiche à la fermeture (si on conduit toujours)
CreateThread(function()
    local hiddenByInv = false
    while true do
        Wait(150)
        local open = LocalPlayer.state.invOpen == true
        if open and not hiddenByInv then
            hiddenByInv = true
            toggleNuiFrame(false)
        elseif not open and hiddenByInv then
            hiddenByInv = false
            if isShowing then toggleNuiFrame(true) end
        end
    end
end)
