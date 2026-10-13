ESXCustom = {}
ESXCustom.newThread = Citizen.CreateThread
ESXCustom.newWaitingThread = Citizen.SetTimeout
ESXCustom.BlacklistEventCrypt = {
    ["ptFxEvent"] = true,
    ["fireEvent"] = true,
    ["playerDropped"] = true,
    ["playerSpawned"] = true,
    ["entityRemoved"] = true,
    ["explosionEvent"] = true,
    ["entityCreating"] = true,
    ["entityCreated"] = true,
    ["onResourceStop"] = true,
    ["giveWeaponEvent"] = true,
    ["playerConnecting"] = true,
    ["RemoveWeaponEvent"] = true,
    ["weaponDamageEvent"] = true,
    ['esx:activateMoney'] = true,
    ["clearPedTasksEvent"] = true,
    ["gameEventTriggered"] = true,
    ['esx:setAccountMoney'] = true,
    ["startProjectileEvent"] = true,
    ["onClientResourceStop"] = true,
    ["RemoveAllWeaponsEvent"] = true,
    ["chat:addSuggestion"] = true,
    ["skinchanger:getSkin"] = true,
    ["skinchanger:loadClothes"] = true,
    ["skinchanger:loadSkin"] = true,
    ["esx_skin:getPlayerSkin"] = true,
    ["skinchanger:loadDefaultModel"] = true,
    ["esx:restoreLoadout"] = true,
    ["skinchanger:change"] = true,
}

ESXCustomPrefixes = {
    zones = "^1ZONE",
    err = "^1ERREUR",
    blips = "^1BLIPS",
    npcs = "^1NPCS",
    dev = "^6INFOS",
    sync = "^6SYNC",
    jobs = "^6JOBS",
    succes = "^2SUCCÈS"
}

ESXCustom.hash = function(notHashedModel)
    return GetHashKey(notHashedModel)
end

ESXCustom.prefix = function(title, message)
    return ("[^6ESXCustom^0] (%s^0) %s" .. "^0"):format(title, message)
end

local registredEvents = {}
local function isEventRegistred(eventName)
    for k,v in pairs(registredEvents) do
        if v == eventName then return true end
    end
    return false
end

ESXCustom.netRegisterAndHandle = function(eventName, handler)
    if Config.Debug then
        print(ESXCustomPrefixes.dev..' REGISTER DE l\'EVENT '..eventName)
    end
    local event = "esx_custom:" .. GetHashKey(eventName)
    if not isEventRegistred(event) then
        RegisterNetEvent(event)
        table.insert(registredEvents, event)
    end
    AddEventHandler(event, handler)
end

local registredServerEvents = {}
local function isEventRegistredServer(eventName)
    for k,v in pairs(registredServerEvents) do
        if v == eventName then return true end
    end
    return false
end

ESXCustom.CheckEventRegisterServerSide = function()
    return registredServerEvents
end

ESXCustom.netRegisterServerAndHandle = function(eventName, handler)
    if Config.Debug then
        print(ESXCustomPrefixes.dev..' REGISTER SERVER DE l\'EVENT '..eventName)
    end
    local event = "esx_custom:" .. GetHashKey(eventName)
    if not isEventRegistredServer(event) then
        RegisterServerEvent(event)
        table.insert(registredServerEvents, event)
    end
    AddEventHandler(event, handler)
end

ESXCustom.netRegister = function(eventName)
    local event = "esx_custom:" .. GetHashKey(eventName)
    RegisterNetEvent(event)
end

ESXCustom.netHandle = function(eventName, handler)
    local event = "esx_custom:" .. GetHashKey(eventName)
    AddEventHandler(event, handler)
end

ESXCustom.netHandleBasic = function(eventName, handler)
    AddEventHandler(eventName, handler)
end

ESXCustom.second = function(from)
    return from*1000
end

ESXCustom.toInternal = function(eventName, ...)
    if ESXCustom.BlacklistEventCrypt[eventName] then
        TriggerEvent(eventName, ...)
    else
        TriggerEvent("esx_custom:" .. GetHashKey(eventName), ...)
    end
end

ESXCustom.load = function(message)
    if type(message) == "string" then
        Citizen.InvokeNative(0xABA17D7CE615ADBF, "STRING")
        AddTextComponentSubstringPlayerName(message)
        Citizen.InvokeNative(0xBD12F8228410D9B4, 3)
    else
        Citizen.InvokeNative(0xABA17D7CE615ADBF, "STRING")
        AddTextComponentSubstringPlayerName("")
        Citizen.InvokeNative(0xBD12F8228410D9B4, -1)
    end
end