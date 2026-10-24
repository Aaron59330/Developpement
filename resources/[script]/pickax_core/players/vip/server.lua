-- Système VIP à 3 niveaux (Bronze / Argent / Or)
local Cache = {} -- [identifier] = { level, expiration, last_claim }

local function tier(level) return ConfigVIP.Tiers[level] end
local function clamp(l) l = tonumber(l) or 0 if l < 1 then return 0 end if l > #ConfigVIP.Tiers then return #ConfigVIP.Tiers end return math.floor(l) end
local function notify(src, msg) TriggerClientEvent(Config.Trigger.TriggerNotification, src, msg) end

MySQL.ready(function()
    pcall(function() MySQL.query.await('ALTER TABLE `vips` ADD COLUMN IF NOT EXISTS `last_claim` int(11) NOT NULL DEFAULT 0') end)
end)

local function loadVip(identifier)
    local row = MySQL.single.await('SELECT vip, expiration, last_claim FROM vips WHERE identifier = ? LIMIT 1', { identifier })
    if not row then Cache[identifier] = { level = 0, expiration = 0, last_claim = 0 } return Cache[identifier] end
    local level, exp = clamp(row.vip), tonumber(row.expiration) or 0
    if level == 0 or exp <= os.time() then
        MySQL.update.await('DELETE FROM vips WHERE identifier = ?', { identifier })
        MySQL.update.await('UPDATE users SET vip = 0 WHERE identifier = ?', { identifier })
        Cache[identifier] = { level = 0, expiration = 0, last_claim = 0, expired = true }
    else
        Cache[identifier] = { level = level, expiration = exp, last_claim = tonumber(row.last_claim) or 0 }
    end
    return Cache[identifier]
end

local function apply(src, silent)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    local v = Cache[xPlayer.identifier] or loadVip(xPlayer.identifier)
    xPlayer.vip = v.level
    local t = tier(v.level)
    pcall(function() xPlayer.setMaxWeight((t and t.maxWeight or ConfigVIP.maxWeightDefault) * 1000) -- ox_inventory travaille en grammes end)
    Player(src).state:set('vipLevel', v.level, true)
    TriggerClientEvent('CorePickax:Vip:updateVIP', src, v.level, v.expiration)
    if v.expired then
        v.expired = nil
        notify(src, 'Votre VIP a ~r~expiré~s~.')
    elseif t and not silent then
        local left = math.max(0, v.expiration - os.time())
        notify(src, ('%s%s~s~ actif : fin dans ~g~%d~s~ jour(s) et ~g~%d~s~ h.'):format(t.color, t.name, left // 86400, (left % 86400) // 3600))
    end
end

local function setVip(identifier, level, days)
    level = clamp(level)
    if level == 0 then return false end
    local cur = Cache[identifier] or loadVip(identifier)
    local now = os.time()
    local base = (cur.level == level and cur.expiration > now) and cur.expiration or now -- même niveau : on prolonge
    local exp = base + math.floor(days) * 86400
    if cur.level > 0 then
        MySQL.update.await('UPDATE vips SET vip = ?, expiration = ? WHERE identifier = ?', { level, exp, identifier })
    else
        MySQL.insert.await('INSERT INTO vips (identifier, vip, expiration, last_claim) VALUES (?, ?, ?, 0)', { identifier, level, exp })
    end
    MySQL.update.await('UPDATE users SET vip = ? WHERE identifier = ?', { level, identifier })
    Cache[identifier] = { level = level, expiration = exp, last_claim = cur.last_claim or 0 }
    return true
end

local function removeVip(identifier)
    MySQL.update.await('DELETE FROM vips WHERE identifier = ?', { identifier })
    MySQL.update.await('UPDATE users SET vip = 0 WHERE identifier = ?', { identifier })
    Cache[identifier] = { level = 0, expiration = 0, last_claim = 0 }
end

local function levelOf(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return 0 end
    local v = Cache[xPlayer.identifier]
    if not v then return clamp(xPlayer.vip) end
    if v.level > 0 and v.expiration <= os.time() then return 0 end
    return v.level
end

AddEventHandler('esx:playerLoaded', function(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    loadVip(xPlayer.identifier)
    apply(src)
end)

AddEventHandler('esx:playerDropped', function(src)
    -- le cache est conservé, il est rechargé à la connexion
end)

-- Expiration + coins horaires (côté serveur uniquement)
CreateThread(function()
    local lastCoins = os.time()
    while true do
        Wait(ConfigVIP.CheckInterval * 60000)
        local now = os.time()
        local giveCoins = now - lastCoins >= ConfigVIP.CoinsInterval * 60
        if giveCoins then lastCoins = now end
        for _, id in ipairs(GetPlayers()) do
            local src = tonumber(id)
            local xPlayer = ESX.GetPlayerFromId(src)
            if xPlayer then
                local v = Cache[xPlayer.identifier]
                if v and v.level > 0 and v.expiration <= now then
                    loadVip(xPlayer.identifier)
                    apply(src)
                elseif giveCoins and v and v.level > 0 then
                    local t = tier(v.level)
                    if t and t.coinsPerHour > 0 and BoutiqueFunction and BoutiqueFunction.addPointsToPlayerReward then
                        pcall(BoutiqueFunction.addPointsToPlayerReward, src, t.coinsPerHour)
                        notify(src, ('~g~+%d~s~ coins (%s%s~s~)'):format(t.coinsPerHour, t.color, t.name))
                    end
                end
            end
        end
    end
end)

-- Informations pour le menu F5
ESX.RegisterServerCallback('CorePickax:Vip:info', function(src, cb)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return cb(nil) end
    local v = Cache[xPlayer.identifier] or loadVip(xPlayer.identifier)
    local level = levelOf(src)
    local tiers = {}
    for i, t in ipairs(ConfigVIP.Tiers) do
        tiers[i] = { name = t.name, color = t.color, salaryMult = t.salaryMult, maxWeight = t.maxWeight, coinsPerHour = t.coinsPerHour,
            chestSlots = t.chest.slots, chestWeight = t.chest.weight, daily = t.daily }
    end
    local nextClaim = (v.last_claim or 0) + ConfigVIP.DailyCooldown
    cb({ level = level, expiration = v.expiration, canClaim = level > 0 and os.time() >= nextClaim, nextClaim = nextClaim, tiers = tiers, now = os.time() })
end)

-- Récompense quotidienne
ESX.RegisterServerCallback('CorePickax:Vip:claim', function(src, cb)
    local xPlayer = ESX.GetPlayerFromId(src)
    local level = levelOf(src)
    if not xPlayer or level == 0 then return cb(false, "Vous n'êtes pas VIP.") end
    local v = Cache[xPlayer.identifier]
    if os.time() < (v.last_claim or 0) + ConfigVIP.DailyCooldown then return cb(false, 'Récompense déjà récupérée, revenez plus tard.') end
    local d = tier(level).daily
    for _, it in ipairs(d.items or {}) do
        if xPlayer.canCarryItem and not xPlayer.canCarryItem(it.name, it.count) then return cb(false, "Pas assez de place dans votre inventaire.") end
    end
    v.last_claim = os.time()
    MySQL.update.await('UPDATE vips SET last_claim = ? WHERE identifier = ?', { v.last_claim, xPlayer.identifier })
    if (d.money or 0) > 0 then xPlayer.addAccountMoney('bank', d.money, 'VIP quotidien') end
    for _, it in ipairs(d.items or {}) do xPlayer.addInventoryItem(it.name, it.count) end
    if (d.coins or 0) > 0 and BoutiqueFunction and BoutiqueFunction.addPointsToPlayerReward then pcall(BoutiqueFunction.addPointsToPlayerReward, src, d.coins) end
    cb(true, 'Récompense quotidienne récupérée !')
end)

-- Coffre VIP personnel (ox_inventory)
ESX.RegisterServerCallback('CorePickax:Vip:chest', function(src, cb)
    local xPlayer = ESX.GetPlayerFromId(src)
    local level = levelOf(src)
    if not xPlayer or level == 0 then return cb(false, "Vous n'êtes pas VIP.") end
    local t = tier(level)
    local id = 'vipchest_' .. xPlayer.identifier
    local ok = pcall(function() exports.ox_inventory:RegisterStash(id, 'Coffre ' .. t.name, t.chest.slots, t.chest.weight, xPlayer.identifier) end)
    if not ok then return cb(false, 'Inventaire indisponible.') end
    cb(true, id)
end)

-- Administration ----------------------------------------------------------
local function parseGive(args)
    local target, level, days = tonumber(args[1]), tonumber(args[2]) or 1, tonumber(args[3]) or ConfigVIP.DureeVIP
    return target, clamp(level), days
end

local function give(target, level, days)
    local xT = target and ESX.GetPlayerFromId(target)
    if not xT then return false, "Joueur introuvable (il doit être connecté)." end
    if level == 0 then return false, 'Niveau invalide (1 à ' .. #ConfigVIP.Tiers .. ').' end
    if days <= 0 then return false, 'Durée invalide.' end
    setVip(xT.identifier, level, days)
    apply(target, true)
    local t = tier(level)
    notify(target, ('Vous avez reçu le %s%s~s~ pour ~g~%d~s~ jour(s).'):format(t.color, t.name, math.floor(days)))
    return true, ('%s donné à %s (%d j)'):format(t.name, xT.getName and xT.getName() or target, math.floor(days))
end

local function remove(target)
    local xT = target and ESX.GetPlayerFromId(target)
    if not xT then return false, 'Joueur introuvable.' end
    removeVip(xT.identifier)
    apply(target, true)
    return true, 'VIP retiré.'
end

ESXCustomServerUtils.registerConsoleCommand('addVIP', function(source, args)
    if source ~= 0 then return end
    local ok, msg = give(parseGive(args))
    print(msg)
end)
ESXCustomServerUtils.registerConsoleCommand('removeVIP', function(source, args)
    if source ~= 0 then return end
    local _, msg = remove(tonumber(args[1]))
    print(msg)
end)

ESX.RegisterCommand('givevip', 'admin', function(xPlayer, args)
    local ok, msg = give(parseGive({ args.id, args.niveau, args.jours }))
    xPlayer.showNotification(msg)
end, true, { help = 'Donner un VIP (niveau 1-3)', arguments = {
    { name = 'id', help = 'ID du joueur', type = 'number' },
    { name = 'niveau', help = '1 Bronze, 2 Argent, 3 Or', type = 'number' },
    { name = 'jours', help = 'Durée en jours', type = 'number' } } })

ESX.RegisterCommand('removevip', 'admin', function(xPlayer, args)
    local _, msg = remove(args.id)
    xPlayer.showNotification(msg)
end, true, { help = 'Retirer le VIP', arguments = { { name = 'id', help = 'ID du joueur', type = 'number' } } })

-- Utilisé par la boutique (achat d'un pack VIP / don par un administrateur) : identifiant, en ligne ou non
function VipGrantByIdentifier(identifier, level, days)
    level, days = clamp(level), tonumber(days) or ConfigVIP.DureeVIP
    if level == 0 or days <= 0 or type(identifier) ~= 'string' or identifier == '' then return false end
    setVip(identifier, level, days)
    local xT = ESX.GetPlayerFromIdentifier(identifier)
    if xT then
        apply(xT.source, true)
        local t = tier(level)
        notify(xT.source, ('Vous avez reçu le %s%s~s~ pour ~g~%d~s~ jour(s).'):format(t.color, t.name, math.floor(days)))
    end
    return true
end

function VipRemoveByIdentifier(identifier)
    if type(identifier) ~= 'string' or identifier == '' then return false end
    removeVip(identifier)
    local xT = ESX.GetPlayerFromIdentifier(identifier)
    if xT then apply(xT.source, true) end
    return true
end

-- Exports -----------------------------------------------------------------
function CheckVIP(source)
    local level = levelOf(source)
    local t = tier(level)
    return level, t and t.salaryMult or 1
end
exports('CheckVIP', CheckVIP)
exports('GetVIPLevel', levelOf)
exports('HasVIP', function(source, minLevel) return levelOf(source) >= (minLevel or 1) end)
exports('GiveVIP', function(source, level, days) return give(source, clamp(level), tonumber(days) or ConfigVIP.DureeVIP) end)
exports('RemoveVIP', remove)
