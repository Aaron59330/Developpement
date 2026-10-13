local showedEntity = nil
local _enabledDoors, _doorState = {}, {}
local pulsed = false
local _coordsToShow = nil
local text = ""

-- Configuration vars
TriggerEvent("chat:addSuggestion", "/createdoor", ("Doors builder"), {})

local _doorType, _distToDoor, allowedJobs, allowedJobs2, doorPin, item = "normal", 3, {}, {}, "", ""
CreateThread(function()
    Wait(500)
    ESX.TriggerServerCallback('CorePickax:DoorLock:cb:getDoors', function(doors, state)
        _enabledDoors = doors
        _doorState = state
    end)
end)

local Action = {
    Door = {'Double','Normal','Glissante'}, Liste = 1,
}

function OpenDoorlock()
	local door_main = RageUI.CreateMenu("DoorsBuilder", "Que voulez-vous faire ?")

        RageUI.Visible(door_main, not RageUI.Visible(door_main))
            while door_main do
            Citizen.Wait(0)
            RageUI.IsVisible(door_main, true, true, true, function()

                RageUI.List("Type de porte : ", Action.Door, Action.Liste, nil, {}, true, function(Hovered, Active, Selected, Index)
                    if (Selected) then 
                        if Index == 1 then
                            _doorType = "double"
                            RageUI.CloseAll()
                            ExecuteCommand("createdoor")
                            ESX['ShowNotification']('~g~Double porte')
                        elseif Index == 2 then
                            _doorType = "normal"
                            RageUI.CloseAll()
                            ExecuteCommand("createdoor")
                            ESX['ShowNotification']('~g~Simple porte')
                        elseif Index == 3 then
                            _doorType = "slider"
                            RageUI.CloseAll()
                            ExecuteCommand("createdoor")
                            ESX['ShowNotification']('~g~Porte glissante')
                            end
                        end
                    Action.Liste = Index;              
                end)

                RageUI.ButtonWithStyle("Disctance d'ouverture :", nil, {RightLabel = _distToDoor}, true, function(Hovered, Active, Selected)
                    if Selected then
                        local dist = ESXCustom_Function_ClientSide:KeyboardInput('Distance entre 1 et 15', 10)
                        if dist == nil then
                            ESX['ShowNotification']('Invalid distance')
                        else
                            _distToDoor = dist
                            RageUI.CloseAll()
                            ExecuteCommand("createdoor")
                        end
                    end
                end)

                RageUI.ButtonWithStyle("Job autorisée :", nil, {RightLabel = Job}, true, function(Hovered, Active, Selected)
                    if Selected then 
                        Job = ESXCustom_Function_ClientSide:KeyboardInput("Nom du job", 15)
                        if Job == nil then
                            ESX['ShowNotification']('Invalid job')
                        else
                            table['insert'](allowedJobs, Job)
                            RageUI.CloseAll()
                            ExecuteCommand("createdoor")
                        end
                    end
                end)

                RageUI.ButtonWithStyle("Job2 autorisée :", nil, {RightLabel = Job2}, true, function(Hovered, Active, Selected)
                    if Selected then 
                        Job2 = ESXCustom_Function_ClientSide:KeyboardInput("Nom du job2", 15)
                        if Job2 == nil then
                            ESX['ShowNotification']('Invalid job2')
                        else
                            table['insert'](allowedJobs2, Job2)
                            RageUI.CloseAll()
                            ExecuteCommand("createdoor")
                        end
                    end
                end)

                RageUI.ButtonWithStyle("Code pin :", nil, {RightLabel = pin}, true, function(Hovered, Active, Selected)
                    if Selected then 
                        pin = ESXCustom_Function_ClientSide:KeyboardInput('Code pin ?', 15)
                        if pin == nil then
                            ESX['ShowNotification']('Invalid pin')
                        else
                            doorPin = pin
                            RageUI.CloseAll()
                            ExecuteCommand("createdoor")
                        end
                    end
                end)
                RageUI.ButtonWithStyle("Ajouter item :", nil, {RightLabel = item}, true, function(Hovered, Active, Selected)
                    if Selected then 
                        item = ESXCustom_Function_ClientSide:KeyboardInput('Item?', 15)
                        if item == nil then
                            ESX['ShowNotification']('Invalid item')
                        else
                            item = item
                            RageUI.CloseAll()
                            ExecuteCommand("createdoor")
                        end
                    end
                end)

                RageUI.ButtonWithStyle("~g~Confirmer la création", nil, {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                    if Selected then 
                        addDoor(_doorType, _distToDoor, allowedJobs, allowedJobs2, doorPin, item)
                        RageUI.CloseAll()
                        _doorType = "normal"
                        _distToDoor = 2
                        doorPin = ""
                        allowedJobs = {}
                        allowedJobs2 = {}
                        Job = nil
                        Job2 = nil
                        pin = nil
                    end
                end)

            end, function()
            end)

            if not RageUI.Visible(door_main) then
            door_main = RMenu:DeleteType("door_main", true)
        end
    end
end

RegisterNetEvent("CorePickax:DoorLock:client:setUpDoor", function()
    OpenDoorlock()
end)

RegisterNetEvent("CorePickax:DoorLock:client:deleteDoor", function()
    CreateThread(function()
        while true do
            local _wait = 0
            local _ped = PlayerPedId()
            local _coords = GetEntityCoords(_ped)
            local hit, coords, entity = RayCastGamePlayCamera(5000.0)
            local _found = false

            DrawLine(_coords, coords, 255, 0, 0, 255)
            RageUI.Text({message = "~r~Appuyez sur [E] pour retirer la porte"})
            for k, v in pairs(_enabledDoors) do
                if v['_type'] ~= "double" then
                    local _doorCoords = vector3(v['doorCoords']['x'], v['doorCoords']['y'], v['doorCoords']['z'])
                    DrawGlobalMarker(28, _doorCoords, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.18, 0.18, 0.18, 255, 0, 0, 255, false, true, 2, nil, nil, false)
                else
                    local _doorCoords = vector3(v['_textCoords']['x'], v['_textCoords']['y'], v['_textCoords']['z'])
                    DrawGlobalMarker(28, _doorCoords, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.18, 0.18, 0.18, 255, 0, 0, 255, false, true, 2, nil, nil, false)
                end
            end
            if IsControlJustPressed(1, 38) then
                for k, v in pairs(_enabledDoors) do
                    if v['_type'] ~= "double" then
                        local _doorCoords = vector3(v['doorCoords']['x'], v['doorCoords']['y'], v['doorCoords']['z'])
                        local _distTo = #(coords - _doorCoords)
                        if _distTo < 1 then
                            TriggerServerEvent("CorePickax:DoorLock:server:syncRemove", k)
                            _found = true
                        end
                    else
                        local _doorCoords = vector3(v['_textCoords']['x'], v['_textCoords']['y'], v['_textCoords']['z'])
                        local _distTo = #(coords - _doorCoords)
                        if _distTo < 1 then
                            TriggerServerEvent("CorePickax:DoorLock:server:syncRemove", k)
                            _found = true
                        end
                    end
                end
                if _found then
                    RageUI.Text({message = "<C>~g~La porte a été supprimer"})
                    break
                else
                    RageUI.Text({message = "<C>~r~La porte existe pas"})
                end
            end
            Wait(_wait)
        end
    end)
end)

RegisterNetEvent("CorePickax:DoorLock:client:removeGlobDoor", function(id)
    table['remove'](_enabledDoors, id)
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        SetEntityDrawOutline(showedEntity, false)
    end
end)

addDoor = function(type, dist, jobs, jobs2, pin, item)
    dist = tonumber(dist)
    if not dist then
        dist = 2
    end
    if type ~= "double" then 
        CreateThread(function()
            while true do
                local _wait = 0
                local _ped = PlayerPedId()
                local _coords = GetEntityCoords(_ped)
                local hit, coords, entity = RayCastGamePlayCamera(5000.0)   
                if IsEntityAnObject(entity) then
                    RageUI.Text({message = "Appuyez sur ~b~[~s~E~b~]~s~ pour ajouter cette porte"})
                    DrawLine(_coords, coords, 0, 255, 34, 255)
                    if showedEntity ~= entity then
                        SetEntityDrawOutline(showedEntity, false)
                        showedEntity = entity
                    end
                    if IsControlJustPressed(1, 38) then
                        local _doorCoords = GetEntityCoords(entity)
                        local _doorModel = GetEntityModel(entity)
                        local _heading = GetEntityHeading(entity)
                        local _textCoords = coords
                        TriggerServerEvent("CorePickax:DoorLock:server:addDoor", _doorCoords, _doorModel, _heading, type, _textCoords, dist, jobs, jobs2, pin, item)
                        SetEntityDrawOutline(entity, false)
                        break
                    end
                    SetEntityDrawOutline(entity, true)
                else
                    if showedEntity ~= entity then
                        SetEntityDrawOutline(showedEntity, false)
                        showedEntity = entity
                    end
                end
                Wait(_wait)
            end
        end)
    else
        local _doorsDobule, entities = {}, {}
        CreateThread(function()
            while true do
                local _wait = 0
                local _ped = PlayerPedId()
                local _coords = GetEntityCoords(_ped)
                local hit, coords, entity = RayCastGamePlayCamera(5000.0)   
                if IsEntityAnObject(entity) then
                    for k, v in pairs(entities) do
                        SetEntityDrawOutline(v, true)
                    end
                    if #_doorsDobule ~= 2 then
                        DrawLine(_coords, coords, 0, 255, 34, 255)
                        RageUI.Text({message = "~b~Appuyez sur ~b~[~s~E~b~]~s~ ~b~pour ajouter la porte"})
                    else
                        DrawLine(_coords, coords, 0, 255, 34, 255)
                        RageUI.Text({message = "~r~Appuyez sur ~b~[~s~E~b~]~s~ ~r~pour confirmer"})
                    end
                    showedEntity = entity
                    if IsControlJustPressed(1, 38) then
                        local _doorCoords = GetEntityCoords(entity)
                        local _doorModel = GetEntityModel(entity)
                        local _heading = GetEntityHeading(entity)
                        local _textCoords = coords
                        if #_doorsDobule == 2 then
                            for k, v in pairs(entities) do
                                SetEntityDrawOutline(v, false)
                            end
                            entities = {}
                            TriggerServerEvent("CorePickax:DoorLock:server:addDoubleDoor", _doorsDobule, type, _textCoords, dist, jobs, jobs2, pin)
                            _doorsDobule = {}
                            break
                        else
                            table['insert'](_doorsDobule, {coords = _doorCoords, model = _doorModel, heading = _heading})
                            table['insert'](entities, entity)
                        end
                    end
                end
                Wait(_wait)
            end
        end)
    end
end

RegisterNetEvent("CorePickax:DoorLock:client:refreshDoors", function(tableToIns)
    table['insert'](_enabledDoors, tableToIns)
end)

local _selectedDoorJobs, _selectedDoorJobs2, pin, object = {}, {}, nil, nil

CreateThread(function()
    while true do
        local isNearToDoor = false
        local _wait = 800
        for k, v in pairs(_enabledDoors) do
            local _doorHash = GetHashKey(v["_doorModel"])
            local _ped = PlayerPedId()
            local _coords = GetEntityCoords(_ped)
            
            if v['_type'] == "normal" then
                local _doorCoords = vector3(v['doorCoords']['x'], v['doorCoords']['y'], v['doorCoords']['z'])
                local _distTo = #(_coords - _doorCoords)
                if _distTo < 10 then
                    door = GetClosestObjectOfType(v['doorCoords']['x'], v['doorCoords']['y'], v['doorCoords']['z'], 1.0, v["_doorModel"], false, false, false)
                    if _doorState[k] ~= nil then
                        FreezeEntityPosition(door, false)
                    else
                        FreezeEntityPosition(door, true)
                    end
                end
                if _distTo < v['dist'] then
                    door = GetClosestObjectOfType(v['doorCoords']['x'], v['doorCoords']['y'], v['doorCoords']['z'], 1.0, v["_doorModel"], false, false, false)
                    _coordsToShow = vector3(v['_textCoords']['x'], v['_textCoords']['y'], v['_textCoords']['z'])
                    isNearToDoor = true
                    _selectedDoorJobs = v['jobs']
                    _selectedDoorJobs2 = v['jobs2']
                    if v['usePin'] then
                        pin = v['pin']
                    else
                        pin = nil
                    end
                    if v['useitem'] then
                        object = v['item']
                    else
                        object = nil
                    end
                    if _doorState[k] ~= nil then
                        text = "Appuyez sur ~b~[E]~w~ pour ~r~fermer~w~ la porte"
                        FreezeEntityPosition(door, false)
                        if pulsed then
                            TriggerServerEvent("CorePickax:DoorLock:server:updateDoor", k, nil)
                            animatePlyDoor()
                            pulsed = false
                        end
                    else
                        FreezeEntityPosition(door, true)
                        text = "Appuyez sur ~b~[E]~w~ pour ~g~ouvrir~w~ la porte"
                        if pulsed then
                            TriggerServerEvent("CorePickax:DoorLock:server:updateDoor", k, "locked")
                            animatePlyDoor()
                            pulsed = false
                        end
                        if v['_type'] == "normal" then
                            SetEntityHeading(door, v['_heading'])
                        end
                    end

                    _wait = 120
                end
            elseif v['_type'] == "double" then
                local _doorCoords = vector3(v['_doorsDouble'][1]['coords']['x'], v['_doorsDouble'][1]['coords']['y'], v['_doorsDouble'][1]['coords']['z'])
                local _doorCoords2 = vector3(v['_doorsDouble'][2]['coords']['x'], v['_doorsDouble'][2]['coords']['y'], v['_doorsDouble'][2]['coords']['z'])
                local _distTo = #(_coords - vector3(v['_textCoords']['x'], v['_textCoords']['y'], v['_textCoords']['z']))
                if _distTo < 10 then
                    _coordsToShow = vector3(v['_textCoords']['x'], v['_textCoords']['y'], v['_textCoords']['z'])
                    door1 = GetClosestObjectOfType(_doorCoords, 1.0, v['_doorsDouble'][1]['model'], false, false, false)
                    door2 = GetClosestObjectOfType(_doorCoords2, 1.0, v['_doorsDouble'][2]['model'], false, false, false)
                    if _doorState[k] ~= nil then
                        FreezeEntityPosition(door1, false)
                        FreezeEntityPosition(door2, false)
                    else
                        FreezeEntityPosition(door1, true)
                        FreezeEntityPosition(door2, true)
                        SetEntityHeading(door1, v['_doorsDouble'][1]['heading'])
                        SetEntityHeading(door2, v['_doorsDouble'][2]['heading'])
                    end
                    if _distTo < v['dist'] then
                        if v['usePin'] then
                            pin = v['pin']
                        else
                            pin = nil
                        end
                        if v['useitem'] then
                            object = v['item']
                        else
                            object = nil
                        end
                        _selectedDoorJobs = v['jobs']
                        _selectedDoorJobs2 = v['jobs2']
                        if _doorState[k] ~= nil then
                            isNearToDoor = true
                            text = "Appuyez sur ~b~[E]~w~ pour ~r~fermer~w~ la porte"
                            FreezeEntityPosition(door1, false)
                            FreezeEntityPosition(door2, false)
                            if pulsed then
                                TriggerServerEvent("CorePickax:DoorLock:server:updateDoor", k, nil)
                                animatePlyDoor()
                                pulsed = false
                                pin = nil
                            end
                        else
                            isNearToDoor = true
                            FreezeEntityPosition(door1, true)
                            FreezeEntityPosition(door2, true)
                            text = "Appuyez sur ~b~[E]~w~ pour ~g~ouvrir~w~ la porte"
                            if pulsed then
                                TriggerServerEvent("CorePickax:DoorLock:server:updateDoor", k, "locked")
                                animatePlyDoor()
                                pulsed = false
                                pin = nil
                            end
                            SetEntityHeading(door1, v['_doorsDouble'][1]['heading'])
                            SetEntityHeading(door2, v['_doorsDouble'][2]['heading'])
                        end
                        _wait = 120
                    end
                end
            else 
                local _doorCoords = vector3(v['doorCoords']['x'], v['doorCoords']['y'], v['doorCoords']['z'])
                local _distTo = #(_coords - vector3(v['_textCoords']['x'], v['_textCoords']['y'], v['_textCoords']['z']))
                if _distTo < 10 then
                    door = GetClosestObjectOfType(v['doorCoords']['x'], v['doorCoords']['y'], v['doorCoords']['z'], 1.0, v["_doorModel"], false, false, false)
                    if not IsDoorRegisteredWithSystem(v['_doorModel'].. "door"..k) then
                        AddDoorToSystem(v['_doorModel'].. "door"..k, v['_doorModel'], _doorCoords, false, false, false)
                        print(k.. " - Slider Registered")
                    end
                    if _doorState[k] ~= nil then
                        DoorSystemSetDoorState(v['_doorModel'].. "door"..k, 0, false, false) 
                        DoorSystemSetAutomaticDistance(v['_doorModel'].. "door"..k, 30.0, false, false)
                    else
                        DoorSystemSetAutomaticDistance(v['_doorModel'].. "door"..k, 0.0, false, false)
                        DoorSystemSetDoorState(v['_doorModel'].. "door"..k, 4, false, false)
                    end
                end
                if _distTo < v['dist'] then
                    door = GetClosestObjectOfType(v['doorCoords']['x'], v['doorCoords']['y'], v['doorCoords']['z'], 1.0, v["_doorModel"], false, false, false)
                    _coordsToShow = vector3(v['_textCoords']['x'], v['_textCoords']['y'], v['_textCoords']['z'])
                    isNearToDoor = true
                    _selectedDoorJobs = v['jobs']
                    _selectedDoorJobs2 = v['jobs2']
                    if v['usePin'] then
                        pin = v['pin']
                    else
                        pin = nil
                    end
                    if v['useitem'] then
                        object = v['item']
                    else
                        object = nil
                    end
                    if _doorState[k] ~= nil then
                        text = "Appuyez sur ~b~[E]~w~ pour ~r~fermer~w~ la porte"
                        DoorSystemSetDoorState(v['_doorModel'].. "door"..k, 0, false, false) 
                        DoorSystemSetAutomaticDistance(v['_doorModel'].. "door"..k, 30.0, false, false)
                        if pulsed then
                            TriggerServerEvent("CorePickax:DoorLock:server:updateDoor", k, nil)
                            animatePlyDoor()
                            pulsed = false
                        end
                    else
                        DoorSystemSetDoorState(v['_doorModel'].. "door"..k, 4, false, false)
                        DoorSystemSetAutomaticDistance(v['_doorModel'].. "door"..k, 0.0, false, false)
                        text = "Appuyez sur ~b~[E]~w~ pour ~g~ouvrir~w~ la porte"
                        if pulsed then
                            TriggerServerEvent("CorePickax:DoorLock:server:updateDoor", k, "locked")
                            animatePlyDoor()
                            pulsed = false
                        end
                    end

                    _wait = 120
                end
            end
        end
        if isNearToDoor then
            show = true
        else
            show = false
        end
        Wait(_wait)
    end
end)

animatePlyDoor = function()
	CreateThread(function()
        while not HasAnimDictLoaded("anim@heists@keycard@") do
            RequestAnimDict("anim@heists@keycard@")
            Wait(1)
        end
        TaskPlayAnim(PlayerPedId(), "anim@heists@keycard@", "exit", 8.0, 1.0, -1, 16, 0, 0, 0, 0)
        Wait(200)
        ClearPedTasks(PlayerPedId())
	end)
end

local _nuiDone = false

CreateThread(function()
    while true do
        local _wait = 800
        if show then
            _wait = 3
            DrawTxt(_coordsToShow, text, 0.7, 8)
        end
        Wait(_wait)
    end
end)

DrawTxt = function(coords, text, size, font) -- Lirol chuchatumare
    local coords = vector3(coords.x, coords.y, coords.z)

    local camCoords = GetGameplayCamCoords()
    local distance = #(coords - camCoords)

    if not size then size = 1 end
    if not font then font = 0 end

    local scale = (size / distance) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov

    SetTextScale(0.0 * scale, 0.55 * scale)
    SetTextFont(font)
    SetTextColour(255, 255, 255, 215)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    SetTextCentre(true)

    SetDrawOrigin(coords, 0)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

RegisterNetEvent("CorePickax:DoorLock:client:updateDoorState", function(id, type, h)
    _doorState[id] = type
end)

RegisterCommand("lockdoor", function()
    if show then
        local _allowed = false
        for k, v in pairs(_selectedDoorJobs) do
            if v == ESX['GetPlayerData']()['job']['name'] then
                _allowed = true
            end
        end
        for k, v in pairs(_selectedDoorJobs2) do
            if v == ESX['GetPlayerData']()['job2']['name'] then
                _allowed = true
            end
        end
        if _allowed then
            pulsed = true
            return
        end


        if not allowed then

            if pin then
                PinDoor()
            end

            if object then
                ESX.TriggerServerCallback('CorePickax:DoorLock:cb:hasObj', function(has)
                    if has then
                        pulsed = true
                        object = nil
                    end
                end, object)
            end

        end


    end
end)

function PinDoor()
	local door_pin = RageUI.CreateMenu("Porte", "Code")

        RageUI.Visible(door_pin, not RageUI.Visible(door_pin))
            while door_pin do
            Citizen.Wait(0)
            RageUI.IsVisible(door_pin, true, true, true, function()

                RageUI.Separator("~r~Cette porte est verouiller par un code")

                RageUI.ButtonWithStyle("Entrer le code", nil, {RightLabel = pinIntr}, true, function(Hovered, Active, Selected)
                    if Selected then
                        pinIntr = ESXCustom_Function_ClientSide:KeyboardInput('Code de la porte', 20)
                        if pinIntr == pin then
                            pulsed = true 
                            pin = nil   
                            pinIntr = nil   
                            RageUI.Text({message="~g~Code pin valide"})
                            RageUI.CloseAll()
                        else
                            pin = nil   
                            pinIntr = nil   
                            RageUI.Text({message="~r~Code pin incorrect"})
                            RageUI.CloseAll()     
                        end
                    end
                end)

            end, function()
            end)

            if not RageUI.Visible(door_pin) then
            door_pin = RMenu:DeleteType(door_pin, true)
        end
    end
end

RegisterKeyMapping("lockdoor", "Fermé une porte", 'keyboard', 'e')

RayCastGamePlayCamera = function(distance)
    local cameraRotation = GetGameplayCamRot()
	local cameraCoord = GetGameplayCamCoord()
	local direction = RotationToDirection(cameraRotation)
	local destination =
	{
		x = cameraCoord.x + direction.x * distance,
		y = cameraCoord.y + direction.y * distance,
		z = cameraCoord.z + direction.z * distance
	}
	local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
	return b, c, e
end


replaceColorText = function(text)
    text = text:gsub("~r~", "<span class='red'>") 
    text = text:gsub("~b~", "<span class='blue'>")
    text = text:gsub("~g~", "<span class='green'>")
    text = text:gsub("~y~", "<span class='yellow'>")
    text = text:gsub("~p~", "<span class='purple'>")
    text = text:gsub("~c~", "<span class='grey'>")
    text = text:gsub("~m~", "<span class='darkgrey'>")
    text = text:gsub("~u~", "<span class='black'>")
    text = text:gsub("~o~", "<span class='gold'>")
    text = text:gsub("~s~", "</span>")
    text = text:gsub("~w~", "</span>")
    text = text:gsub("~b~", "<b>")
    text = text:gsub("~n~", "<br>")
    text = "<span>" .. text .. "</span>"
    return text
end

RotationToDirection = function(rotation)
	local adjustedRotation =
	{
		x = (math.pi / 180) * rotation.x,
		y = (math.pi / 180) * rotation.y,
		z = (math.pi / 180) * rotation.z
	}
	local direction =
	{
		x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		z = math.sin(adjustedRotation.x)
	}
	return direction
end