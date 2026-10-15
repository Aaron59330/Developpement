local ESX = exports['es_extended']:getSharedObject()

local function allowed(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer then
        local g = xPlayer.getGroup()
        for _, name in ipairs(Config.AllowedGroups) do
            if g == name then return true end
        end
    end
    return Config.AcePermission and Config.AcePermission ~= '' and IsPlayerAceAllowed(src, Config.AcePermission) or false
end

local function count(tbl)
    if not tbl:match('^[%w_]+$') then return nil end
    local ok, n = pcall(function() return MySQL.scalar.await(('SELECT COUNT(*) FROM `%s`'):format(tbl)) end)
    if ok and n ~= nil then return tonumber(n) end
    return nil
end

local function payload()
    local list = {}
    for _, b in ipairs(Config.Builders) do
        local state = GetResourceState(b.resource)
        local stats = {}
        if state == 'started' then
            for _, s in ipairs(b.stats or {}) do
                local n = count(s[2])
                if n ~= nil then stats[#stats + 1] = { s[1], n } end
            end
        end
        list[#list + 1] = {
            id = b.id, label = b.label, desc = b.desc, icon = b.icon, command = b.command,
            state = state, stats = stats,
        }
    end
    return list
end

RegisterNetEvent('builderhub:request', function()
    local src = source
    if not allowed(src) then
        TriggerClientEvent('esx:showNotification', src, "~r~Accès refusé~s~ : réservé à l'équipe.")
        return
    end
    TriggerClientEvent('builderhub:open', src, payload())
end)

-- Un builder demandé : revérifie les droits puis renvoie la commande à lancer
RegisterNetEvent('builderhub:launch', function(id)
    local src = source
    if not allowed(src) then return end
    for _, b in ipairs(Config.Builders) do
        if b.id == id then
            if GetResourceState(b.resource) == 'started' then
                TriggerClientEvent('builderhub:run', src, b.command)
            else
                TriggerClientEvent('esx:showNotification', src, ('~r~%s est arrêté~s~ : ensure %s'):format(b.label, b.resource))
            end
            return
        end
    end
end)
