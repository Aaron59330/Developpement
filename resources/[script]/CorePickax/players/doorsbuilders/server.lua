local _doorCache = {}

isAllowed = function(id)
    if ConfigDoorsBuilder.PermissionAllowed[ESXCustom_Function_ServerSide:getLicense(id)] then
        return true
    end

    return false
end

CreateThread(function()
    local doors = LoadResourceFile(GetCurrentResourceName(), "players/doorsbuilders/doors.json")
    if doors == "" then
        SaveResourceFile(GetCurrentResourceName(), "players/doorsbuilders/doors.json", "[]", -1)
    end
end)

ESX.RegisterServerCallback('CorePickax:DoorLock:cb:getDoors', function(source,cb) 
    local doors = LoadResourceFile(GetCurrentResourceName(), "players/doorsbuilders/doors.json")
    doors = json['decode'](doors)
    cb(doors, _doorCache)
end)

RegisterNetEvent("CorePickax:DoorLock:server:addDoor", function(_doorCoords, _doorModel, _heading, type, _textCoords, dist, jobs, jobs2, pin, item)
    local _src = source
    if isAllowed(_src) then
        local usePin = false
        local useitem = false
        local doors = LoadResourceFile(GetCurrentResourceName(), "players/doorsbuilders/doors.json")
        if pin ~= "" then
            usePin = true
        end
        if item ~= "" then
            useitem = true
        end
        doors = json.decode(doors)
        local tableToIns = {
            doorCoords = _doorCoords,
            _doorModel = _doorModel,
            _heading = _heading,
            _type = type,
            _textCoords = _textCoords,
            dist = dist,
            jobs = jobs,
            jobs2 = jobs2,
            usePin = usePin,
            pin = pin,
            useitem = useitem,
            item = item
        }
        table['insert'](doors, tableToIns)
        SaveResourceFile(GetCurrentResourceName(), "players/doorsbuilders/doors.json", json['encode'](doors, { indent = true }), -1)
        TriggerClientEvent("CorePickax:DoorLock:client:refreshDoors", -1, tableToIns)
    else
        return ESXCustomServerUtils.rejectSuspiciousAction(_src, 'Désynchronisation avec le serveur ou detection de Cheat')
    end
end)

RegisterNetEvent("CorePickax:DoorLock:server:addDoubleDoor", function(_doorsDobule, type, _textCoords, dist, jobs, jobs2, pin)
    local _src = source
    if isAllowed(_src) then
        local doors = LoadResourceFile(GetCurrentResourceName(), "players/doorsbuilders/doors.json")
        doors = json.decode(doors)
        local usePin = false
        if pin ~= "" then
            usePin = true
        end
        local tableToIns = {
            _doorsDouble = _doorsDobule,
            _type = type,
            _textCoords = _textCoords,
            dist = dist,
            jobs = jobs,
            jobs2 = jobs2,
            usePin = usePin,
            pin = pin,
        }
        table['insert'](doors, tableToIns)
        SaveResourceFile(GetCurrentResourceName(), "players/doorsbuilders/doors.json", json['encode'](doors, { indent = true }), -1)
        TriggerClientEvent("CorePickax:DoorLock:client:refreshDoors", -1, tableToIns)
    else
        return ESXCustomServerUtils.rejectSuspiciousAction(_src, 'Désynchronisation avec le serveur ou detection de Cheat')
    end
end)

RegisterNetEvent("CorePickax:DoorLock:server:updateDoor", function(id, type)
    _doorCache[id] = type
    TriggerClientEvent("CorePickax:DoorLock:client:updateDoorState", -1, id, type)
end)

RegisterNetEvent("CorePickax:DoorLock:server:syncRemove", function(id)
    local _src = source
    if isAllowed(_src) then
        local doors = LoadResourceFile(GetCurrentResourceName(), "players/doorsbuilders/doors.json")
        doors = json.decode(doors)
        table['remove'](doors, id)
        SaveResourceFile(GetCurrentResourceName(), "players/doorsbuilders/doors.json", json['encode'](doors, { indent = true }), -1)
        TriggerClientEvent("CorePickax:DoorLock:client:removeGlobDoor", -1, id)
    else
        return ESXCustomServerUtils.rejectSuspiciousAction(_src, 'Désynchronisation avec le serveur ou detection de Cheat')
    end
end)

RegisterCommand("createdoor", function(source, args)  
    if isAllowed(source) then
        VerifyToken(source, function()
            TriggerClientEvent("CorePickax:DoorLock:client:setUpDoor", source)
        end)
    end 
end, false)

RegisterCommand("deletedoor", function(source, args)  
    if isAllowed(source) then
        VerifyToken(source, function()
            TriggerClientEvent("CorePickax:DoorLock:client:deleteDoor", source)
        end)
    end 
end, false)

ESX.RegisterServerCallback('CorePickax:DoorLock:cb:hasObj', function(source,cb, item) 
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local itemPly = xPlayer.getInventoryItem(item)
    if itemPly and itemPly.count > 0 then
        return cb(true)
    else 
        return cb(false)
    end
end)