-- [AERO:LIC] contrôle de licence via pickax_core (qui vérifie lui-même la signature du panel) : ne pas retirer
do
    local res = GetCurrentResourceName()
    -- true / false ; nil = pickax_core n'a pas encore fini sa vérification
    local function lic() local good, v = pcall(function() return exports.pickax_core:Licensed() end) if good then return v end end
    local function die(why) print(('^1[AERO] %s arrêtée : %s^0'):format(res, why)) StopResource(res) end
    if GetResourceState('pickax_core') == 'started' and lic() == false then die('licence invalide (pickax_core)') error('AERO : licence invalide', 0) end
    CreateThread(function()
        local tries = 0
        while true do
            local v = lic()
            if v == true then break end
            tries = tries + 1
            if v == false or tries > 30 then die(v == false and 'licence invalide (pickax_core)' or 'pickax_core absent ou licence non vérifiée') return end
            Wait(2000)
        end
        while true do
            Wait(240000 + math.random(0, 120000))
            local good = false
            for _ = 1, 4 do if lic() == true then good = true break end Wait(10000) end
            if not good then die('licence invalide') return end
        end
    end)
end
-- [/AERO:LIC]

ESX = exports['es_extended']:getSharedObject()

MySQL.ready(function()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS pickax_tutorial (
        identifier VARCHAR(80) NOT NULL PRIMARY KEY,
        done_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        skipped TINYINT(1) NOT NULL DEFAULT 0
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
end)

local function serverInfo()
    local ok, st = pcall(function() return exports['pickax_core']:GetGlobalStyle() end)
    st = ok and type(st) == 'table' and st or {}
    return { server = st.name or GetConvar('sv_projectName', 'le serveur'), discord = st.discord or '' }
end

local function seen(identifier) return MySQL.scalar.await('SELECT 1 FROM pickax_tutorial WHERE identifier = ?', { identifier }) ~= nil end

local function payload()
    local info = serverInfo()
    local steps = {}
    local function fill(s) return (tostring(s or ''):gsub('{server}', info.server):gsub('{discord}', info.discord ~= '' and info.discord or 'notre Discord'):gsub('{command}', Config.Command)) end
    for _, s in ipairs(Config.Steps) do
        local b = {}
        for _, x in ipairs(s.bullets or {}) do b[#b + 1] = fill(x) end
        steps[#steps + 1] = { icon = s.icon, title = fill(s.title), text = fill(s.text), keys = s.keys, bullets = b }
    end
    local r = Config.Reward or {}
    local hasReward = (r.money or 0) > 0 or (r.bank or 0) > 0 or (r.items and #r.items > 0)
    return { steps = steps, skippable = Config.Skippable ~= false, reward = hasReward }
end

-- Le client demande : doit-on afficher le tutoriel automatiquement ?
-- afterCreation = le joueur vient de terminer la création de son personnage (identité + apparence + destination)
local function hasIdentity(identifier)
    local fn = MySQL.scalar.await('SELECT firstname FROM users WHERE identifier = ?', { identifier })
    return fn ~= nil and fn ~= ''
end

lib.callback.register('pickax_tutorial:shouldOpen', function(src, afterCreation)
    if not Config.AutoOpen then return false end
    local x = ESX.GetPlayerFromId(src)
    if not x then return false end
    if seen(x.identifier) then return false end
    -- nouveau personnage : on attend la fin de la création (le signal « terminé » relance la demande avec afterCreation)
    if not afterCreation and not hasIdentity(x.identifier) then return false end
    return true
end)

lib.callback.register('pickax_tutorial:data', function(src) return payload() end)

-- Fin du tutoriel : marque comme vu et verse la récompense UNE seule fois (seulement si le tutoriel est terminé, pas passé)
lib.callback.register('pickax_tutorial:finish', function(src, skipped)
    local x = ESX.GetPlayerFromId(src)
    if not x then return { ok = false } end
    skipped = skipped == true
    local inserted = MySQL.update.await('INSERT IGNORE INTO pickax_tutorial (identifier, skipped) VALUES (?, ?)', { x.identifier, skipped and 1 or 0 }) or 0
    local reward = inserted > 0 and not skipped
    if inserted == 0 and not skipped then   -- avait passé le tutoriel puis l'a terminé : la récompense reste due
        reward = (MySQL.update.await('UPDATE pickax_tutorial SET skipped = 0 WHERE identifier = ? AND skipped = 1', { x.identifier }) or 0) > 0
    end
    local given
    if reward then
        local r = Config.Reward or {}
        if (r.money or 0) > 0 then x.addMoney(r.money) end
        if (r.bank or 0) > 0 then x.addAccountMoney('bank', r.bank) end
        for _, it in ipairs(r.items or {}) do pcall(function() exports.ox_inventory:AddItem(src, it.name, it.count or 1) end) end
        given = { money = r.money or 0, bank = r.bank or 0, items = r.items or {} }
    end
    return { ok = true, reward = given }
end)

RegisterCommand('tutorielreset', function(src, args)   -- console ou admin : /tutorielreset <id> remet le tutoriel à zéro pour un joueur
    if src ~= 0 then local x = ESX.GetPlayerFromId(src) local g = x and x.getGroup() if g ~= 'admin' and g ~= 'superadmin' and g ~= 'owner' then return end end
    local t = ESX.GetPlayerFromId(tonumber(args[1]))
    if t then MySQL.update('DELETE FROM pickax_tutorial WHERE identifier = ?', { t.identifier }) print('[pickax_tutorial] remis à zéro pour ' .. t.identifier) end
end, false)
