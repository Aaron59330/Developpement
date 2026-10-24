ESX = exports['es_extended']:getSharedObject()

JB = {
    Jobs   = {},   -- [name] = ligne jobbuilder_jobs + .grades
    Points = {},   -- [id]   = ligne jobbuilder_points
}

-- ─────────────────────────────── Helpers ───────────────────────────────
function JB.decode(str, default)
    if not str or str == '' then return default end
    local ok, res = pcall(json.decode, str)
    if ok and res ~= nil then return res end
    return default
end

-- Les colonnes tinyint(1) reviennent en 1/0 ou en true/false selon la version d'oxmysql : on accepte les deux
function JB.flag(v) return v == 1 or v == true or v == '1' end

function JB.isDev(src)
    if src == 0 then return true end
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer then
        for _, g in ipairs(Config.AllowedGroups) do
            if xPlayer.getGroup() == g then return true end
        end
    end
    if Config.AcePermission and Config.AcePermission ~= '' and IsPlayerAceAllowed(src, Config.AcePermission) then
        return true
    end
    return false
end

function JB.playerName(xPlayer)
    return xPlayer.getName and xPlayer.getName() or GetPlayerName(xPlayer.source)
end

function JB.inventory()
    if Config.Inventory == 'ox' then return 'ox' end
    if Config.Inventory == 'esx' then return 'esx' end
    return GetResourceState('ox_inventory') == 'started' and 'ox' or 'esx'
end

function JB.log(jobName, xPlayer, action, detail)
    MySQL.insert('INSERT INTO jobbuilder_logs (job_name, identifier, player_name, action, detail) VALUES (?, ?, ?, ?, ?)', {
        jobName, xPlayer and xPlayer.identifier or nil, xPlayer and JB.playerName(xPlayer) or 'système', action, detail and tostring(detail):sub(1, 255) or nil,
    })
    if GetResourceState('pickax_dlogs') == 'started' and jobName then
        local j = JB.Jobs and JB.Jobs[jobName]
        pcall(function()
            exports.pickax_dlogs:Send('job', jobName, j and j.label or jobName, action,
                xPlayer and { name = JB.playerName(xPlayer), identifier = xPlayer.identifier } or nil, detail)
        end)
    end
end

function JB.distanceTo(src, coords)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return 9999.0 end
    local p = GetEntityCoords(ped)
    return #(vector3(p.x, p.y, p.z) - vector3(coords.x, coords.y, coords.z))
end

function JB.societyAccount(jobName)
    return Config.SocietyPrefix .. jobName
end

-- ─────────────────────────────── Base de données ───────────────────────────────
local function installTables()
    local sql = LoadResourceFile(GetCurrentResourceName(), 'sql/install.sql')
    if not sql then return end -- tables déjà créées par database.sql
    sql = sql:gsub('%-%-[^\n]*', '')
    for stmt in sql:gmatch('[^;]+') do
        if stmt:match('%S') then MySQL.query.await(stmt) end
    end
end

function JB.registerStash(point)
    if JB.inventory() ~= 'ox' or point.type ~= 'stash' then return end
    local d = point.data or {}
    pcall(function()
        exports.ox_inventory:RegisterStash(('jobbuilder_%d'):format(point.id), point.label ~= '' and point.label or 'Coffre',
            tonumber(d.slots) or 50, (tonumber(d.weight) or 100) * 1000, false, { [point.job_name] = point.min_grade or 0 })
    end)
end

function JB.loadAll()
    JB.Jobs, JB.Points = {}, {}
    local jobs = MySQL.query.await('SELECT * FROM jobbuilder_jobs') or {}
    for _, r in ipairs(jobs) do
        r.blip = JB.decode(r.blip, {})
        r.settings = JB.decode(r.settings, {})
        r.whitelisted = JB.flag(r.whitelisted)
        r.society = JB.flag(r.society)
        r.grades = {}
        JB.Jobs[r.name] = r
    end
    local grades = MySQL.query.await('SELECT job_name, grade, name, label, salary FROM job_grades WHERE job_name IN (SELECT name FROM jobbuilder_jobs) ORDER BY job_name, grade') or {}
    for _, g in ipairs(grades) do
        if JB.Jobs[g.job_name] then table.insert(JB.Jobs[g.job_name].grades, g) end
    end
    local points = MySQL.query.await('SELECT * FROM jobbuilder_points ORDER BY id') or {}
    for _, p in ipairs(points) do
        p.coords = JB.decode(p.coords, { x = 0, y = 0, z = 0, h = 0 })
        p.data = JB.decode(p.data, {})
        if JB.Jobs[p.job_name] then
            JB.Points[p.id] = p
            JB.registerStash(p)
        end
    end
end

-- Garantit que chaque job « société » possède bien ses lignes ESX (addon_account, addon_account_data, addon_inventory, datastore)
-- et répare les jobs enregistrés avec la société désactivée alors que son compte existe (ancien défaut de lecture tinyint).
function JB.ensureSocieties()
    local created, healed = {}, {}
    local existing = {}
    for _, r in ipairs(MySQL.query.await('SELECT name FROM addon_account') or {}) do existing[r.name] = true end
    for name, job in pairs(JB.Jobs) do
        local acc = JB.societyAccount(name)
        if not job.society and existing[acc] then
            job.society = true
            MySQL.update.await('UPDATE jobbuilder_jobs SET society = 1 WHERE name = ?', { name })
            healed[#healed + 1] = name
        end
        if job.society and not existing[acc] then
            MySQL.update.await('INSERT IGNORE INTO addon_account (name, label, shared) VALUES (?, ?, 1)', { acc, job.label })
            MySQL.update.await('INSERT INTO addon_account_data (account_name, money, owner) SELECT ?, 0, NULL FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM addon_account_data WHERE account_name = ? AND owner IS NULL)', { acc, acc })
            MySQL.update.await('INSERT IGNORE INTO addon_inventory (name, label, shared) VALUES (?, ?, 1)', { acc, job.label })
            MySQL.update.await('INSERT IGNORE INTO datastore (name, label, shared) VALUES (?, ?, 1)', { acc, job.label })
            MySQL.update.await("INSERT INTO datastore_data (name, data, owner) SELECT ?, '{}', NULL FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM datastore_data WHERE name = ? AND owner IS NULL)", { acc, acc })
            created[#created + 1] = name
        end
    end
    if #healed > 0 then print(('^2[jobbuilder] société réactivée pour : %s^0'):format(table.concat(healed, ', '))) end
    if #created > 0 then print(('^2[jobbuilder] comptes société créés pour : %s — redémarre esx_society / esx_addonaccount (ou CorePickax) pour qu\'ils les voient^0'):format(table.concat(created, ', '))) end
    return created, healed
end

-- Recharge les jobs dans es_extended (nécessite ESX Legacy récent : ESX.RefreshJobs)
function JB.refreshESX()
    if ESX.RefreshJobs then
        local ok, err = pcall(ESX.RefreshJobs)
        if not ok then print(('^1[jobbuilder] ESX.RefreshJobs a échoué : %s^0'):format(err)) end
        return ok
    end
    print('^3[jobbuilder] Ton es_extended n\'a pas ESX.RefreshJobs : redémarre es_extended pour que les nouveaux jobs soient pris en compte.^0')
    return false
end

-- esx_society / esx_addonaccount (ou un CorePickax qui les regroupe) lisent les jobs et les comptes société au démarrage.
-- Après un changement de job, on redémarre les ressources configurées (Config.RestartResources) ; sinon on indique lesquelles redémarrer.
local restartToken = 0
function JB.compatRefresh()
    local detected = {}
    for _, r in ipairs({ 'pickax_core', 'esx_society', 'esx_addonaccount', 'esx_datastore', 'esx_addoninventory' }) do
        if GetResourceState(r) == 'started' then detected[#detected + 1] = r end
    end
    if #Config.RestartResources == 0 then
        if #detected > 0 then
            print(('^3[jobbuilder] Pour que %s voie ce changement de job / société : redémarre-la (ou ajoute-la dans Paramètres → Général → Ressources à redémarrer).^0'):format(table.concat(detected, ', ')))
        end
        return { restarted = false, detected = detected }
    end
    restartToken = restartToken + 1
    local mine = restartToken
    SetTimeout(3000, function()
        if mine ~= restartToken then return end      -- plusieurs modifications rapprochées : un seul redémarrage
        for _, r in ipairs(Config.RestartResources) do
            if GetResourceState(r) == 'started' then
                print(('^2[jobbuilder] Redémarrage de %s pour prendre en compte les jobs / sociétés.^0'):format(r))
                ExecuteCommand('restart ' .. r)
            end
        end
    end)
    return { restarted = true, resources = Config.RestartResources, detected = detected }
end

-- ─────────────────────────────── Synchronisation clients ───────────────────────────────
function JB.publicBlips()
    local list = {}
    for name, job in pairs(JB.Jobs) do
        local b = job.blip or {}
        if b.enabled and b.coords then
            list[#list + 1] = {
                job = name, label = (b.label and b.label ~= '') and b.label or job.label, sprite = b.sprite, color = b.color, category = job.type,
                scale = b.scale, coords = b.coords, shortRange = b.shortRange ~= false,
            }
        end
    end
    return list
end

-- Style effectif d'un point = style du job complété/écrasé par celui du point (le type de point est géré côté client)
function JB.pointStyle(p)
    local job = JB.Jobs[p.job_name]
    local js = job and job.settings and job.settings.marker
    local ps = p.data and p.data.style
    if not js then return ps end
    if not ps then return js end
    local m = {}
    for k, v in pairs(js) do m[k] = v end
    for k, v in pairs(ps) do m[k] = v end
    return m
end

function JB.pointsForJob(jobName)
    local list = {}
    for id, p in pairs(JB.Points) do
        if p.job_name == jobName then
            if p.type == 'garage' and p.data.store then      -- point de rangement du garage : envoyé comme un point à part (id décalé)
                list[#list + 1] = { id = id + 100000000, type = 'garage_return', label = p.label .. ' (rangement)', coords = p.data.store.coords, min_grade = p.min_grade,
                    kind = p.data.kind or 'car', radius = p.data.store.radius or 5.0, style = JB.pointStyle(p) }
            end
            list[#list + 1] = { id = id, type = p.type, label = p.label, coords = p.coords, min_grade = p.min_grade,
                spawn = p.type == 'garage' and p.data.spawn or nil, kind = (p.type == 'garage' or p.type == 'garage_return') and (p.data.kind or 'car') or nil, radius = p.type == 'garage_return' and (p.data.radius or 5.0) or nil, model = p.type == 'display' and p.data.model or nil, color = p.type == 'display' and p.data.color or nil, style = JB.pointStyle(p) }
        end
    end
    return list
end

-- Les boutiques publiques sont envoyées à tout le monde, le reste uniquement aux membres du job.
function JB.publicShops()
    local list = {}
    for id, p in pairs(JB.Points) do
        if (p.type == 'shop' and p.data and p.data.public) or p.type == 'showroom' or p.type == 'display' then
            list[#list + 1] = { id = id, type = p.type, label = p.label, coords = p.coords, min_grade = 0, public = true, job = p.job_name,
                model = p.type == 'display' and p.data.model or nil, color = p.type == 'display' and p.data.color or nil, style = JB.pointStyle(p) }
        end
    end
    return list
end

-- Actions du menu F6 : celles cochées dans le builder (+ gestion immobilière pour les agences)
function JB.menuActions(job)
    local list = {}
    if job.type == 'realestate' then list[#list + 1] = 'properties' end
    if job.type == 'dealer' then list[#list + 1] = 'dealership' end
    if job.type == 'government' then list[#list + 1] = 'government' end
    if Config.Missions.Enabled and job.settings.missions_enabled ~= false then list[#list + 1] = 'missions' end
    if (job.type == 'police' or job.type == 'ems' or job.settings.vehctl == true) and job.settings.vehctl ~= false then list[#list + 1] = 'vehctl' end
    if job.type == 'police' and job.settings.tablet_enabled ~= false then list[#list + 1] = 'tablet' end
    if job.type == 'ems' and job.settings.ems_receive ~= false then list[#list + 1] = 'emscalls' end
    if job.type == 'ems' and job.settings.ems_tablet_enabled ~= false then list[#list + 1] = 'emstablet' end
    if job.type == 'bank' and job.settings.bank_tablet_enabled ~= false then list[#list + 1] = 'banktablet' end
    if job.settings.smalljob then list[#list + 1] = 'smallquests' end
    if Config.Announce.Enabled and job.settings.announce_enabled ~= false then list[#list + 1] = 'jobannounce' end
    local seen = {}
    for _, a in ipairs(list) do seen[a] = true end
    for _, a in ipairs(job.settings.actions or {}) do
        if not seen[a] and JBActionAllowed(a, job.type) then list[#list + 1] = a seen[a] = true end     -- ignore les actions d'un autre métier (anciens jobs)
    end
    return list
end

function JB.configSnapshot()
    return { general = JBGet('general'), pointTypes = JBGet('pointTypes'), real = JBGet('real'), dealer = JBGet('dealer'), death = JBGet('death'), ui = JBGet('ui') }
end

function JB.syncPlayer(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    TriggerClientEvent('jobbuilder:client:config', src, JB.configSnapshot())
    TriggerClientEvent('jobbuilder:client:sync', src, {
        points = JB.pointsForJob(xPlayer.job.name),
        shops = JB.publicShops(),
        blips = JB.publicBlips(),
        jobConfig = JB.Jobs[xPlayer.job.name] and {
            name = xPlayer.job.name,
            label = JB.Jobs[xPlayer.job.name].label,
            grade = xPlayer.job.grade, gradeLabel = xPlayer.job.grade_label,
            type = JB.Jobs[xPlayer.job.name].type,
            actions = JB.menuActions(JB.Jobs[xPlayer.job.name]),
            boss_grade = JB.Jobs[xPlayer.job.name].boss_grade,
            accent = JB.Jobs[xPlayer.job.name].settings.ui_accent,     -- couleur de l'interface propre au job (sinon : couleur globale)
        } or nil,
    })
end

function JB.syncAll()
    for _, src in ipairs(GetPlayers()) do JB.syncPlayer(tonumber(src)) end
end

AddEventHandler('esx:playerLoaded', function(src) SetTimeout(1500, function() JB.syncPlayer(src) end) end)
AddEventHandler('esx:setJob', function(src) SetTimeout(300, function() JB.syncPlayer(src) end) end)

RegisterNetEvent('jobbuilder:server:requestSync', function()
    JB.syncPlayer(source)
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    installTables()
    JB.loadAll()
    pcall(JB.ensureSocieties)
    JB.ready = true
    SetTimeout(1000, JB.syncAll)
    print(('^2[jobbuilder] %d job(s), %d point(s) chargés.^0'):format(
        (function() local n = 0 for _ in pairs(JB.Jobs) do n = n + 1 end return n end)(),
        (function() local n = 0 for _ in pairs(JB.Points) do n = n + 1 end return n end)()))
end)

-- Si ox_inventory redémarre, ré-enregistrer les coffres
AddEventHandler('onResourceStart', function(res)
    if res ~= 'ox_inventory' then return end
    for _, p in pairs(JB.Points) do JB.registerStash(p) end
end)

-- Diagnostic : réglages d'identité / blips lus dans pickax_core/config.lua (voir pickax_theme)
CreateThread(function()
    Wait(1500)
    if PickaxTheme and PickaxTheme.blipScale then
        print(('^2[jobbuilder] taille des blips globale (pickax_core/config.lua) : %s^0'):format(tostring(PickaxTheme.blipScale)))
    else
        print('^3[jobbuilder] réglage global des blips introuvable (pickax_theme absent ou pickax_core/config.lua illisible) : tailles par défaut du builder^0')
    end
end)
