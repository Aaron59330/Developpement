local items = {}
local onTimer       = {}
local savedCoords   = {}
local deadPlayers   = {}

local function getLicense(source)
    local license = nil
    for k,v in pairs(GetPlayerIdentifiers(source))do
        if string.sub(v, 1, string.len("license:")) == "license:" then
            license = v
        end
    end
    return license
end

local function canUse(source)
	local license = getLicense(source)
	if license == nil then return end
	return ConfigMenuAdministrationAdmin.staffList[license] ~= nil
end

-- Grades administration personnalisés créés en jeu par le rôle _dev.
local customGradeFile = "custom_admin_grades.json"
local customAdminGrades = {}

-- Couleurs des grades admin, modifiables en jeu par _dev.
local gradeStyleFile = "admin_grade_styles.json"
local adminGradeStyles = {}
local defaultGradeColors = { user="~s~", mod="~o~", admin="~r~", superadmin="~b~", ["_dev"]="~p~" }

local function loadAdminGradeStyles()
    adminGradeStyles = {}
    local raw = LoadResourceFile(GetCurrentResourceName(), gradeStyleFile)
    if raw and raw ~= "" then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == "table" then adminGradeStyles = decoded end
    end
end

local function saveAdminGradeStyles()
    SaveResourceFile(GetCurrentResourceName(), gradeStyleFile, json.encode(adminGradeStyles), -1)
end

local function getGradeColor(group)
    local style = adminGradeStyles[group]
    if type(style) == "table" and type(style.color) == "string" then return style.color end
    local custom = customAdminGrades[group]
    if custom and type(custom.color) == "string" then return custom.color end
    return defaultGradeColors[group] or "~y~"
end

-- Grades natifs supprimés/désactivés depuis le menu _dev.
-- _dev n'est jamais autorisé dans cette liste.
local deletedGradeFile = "deleted_admin_grades.json"
local deletedAdminGrades = {}

local function loadCustomAdminGrades()
    customAdminGrades = {}
    local raw = LoadResourceFile(GetCurrentResourceName(), customGradeFile)
    if raw and raw ~= "" then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == "table" then customAdminGrades = decoded end
    end
end

local function saveCustomAdminGrades()
    SaveResourceFile(GetCurrentResourceName(), customGradeFile, json.encode(customAdminGrades), -1)
end

local function loadDeletedAdminGrades()
    deletedAdminGrades = {}
    local raw = LoadResourceFile(GetCurrentResourceName(), deletedGradeFile)
    if raw and raw ~= "" then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == "table" then deletedAdminGrades = decoded end
    end
    deletedAdminGrades["_dev"] = nil
    deletedAdminGrades["user"] = nil
end

local function saveDeletedAdminGrades()
    deletedAdminGrades["_dev"] = nil
    deletedAdminGrades["user"] = nil
    SaveResourceFile(GetCurrentResourceName(), deletedGradeFile, json.encode(deletedAdminGrades), -1)
end

loadCustomAdminGrades()
loadDeletedAdminGrades()
loadAdminGradeStyles()

local function getRank(source)
	if ConfigMenuAdmin.CheckByGroup then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return end
        local group = xPlayer.getGroup()
        if deletedAdminGrades[group] then return nil end
        if ConfigMenuAdmin.GroupList[group] then return ConfigMenuAdmin.GroupList[group] end
        local custom = customAdminGrades[group]
        if custom then return tonumber(custom.rank) end
        return nil
	else
		local license = getLicense(source)
		if license == nil then return end
		return ConfigMenuAdministrationAdmin.staffList[license], license
	end
end

local function getAdminGroupName(source)
    if not ConfigMenuAdmin.CheckByGroup then return nil end
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.getGroup then return nil end
    return xPlayer.getGroup()
end

-- ============================================================
-- Permissions dynamiques administrées par _dev
-- Sauvegarde locale : admin_permissions.json dans la ressource.
-- ============================================================
local permissionFile = "admin_permissions.json"
local adminPermissionMatrix = {}

local function buildDefaultPermissions()
    local matrix = {}
    for rank = 1, 3 do
        matrix[rank] = {
            section_self = true,
            section_players = true,
            section_reports = true,
            section_vehicle = true,
            setjob = rank >= 2,
            setjob2 = rank >= 2,
            take_screen = true
        }
        local allowed = {}
        for _, id in ipairs(ConfigMenuAdministrationAdmin.ranks[rank].permissions or {}) do allowed[tonumber(id)] = true end
        for i = 1, #ConfigMenuAdministrationAdmin.functions do
            matrix[rank]["func_"..i] = allowed[i] == true
        end
    end
    return matrix
end

local function loadPermissionConfig()
    adminPermissionMatrix = buildDefaultPermissions()
    local raw = LoadResourceFile(GetCurrentResourceName(), permissionFile)
    if raw and raw ~= "" then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == "table" then
            for matrixKey, saved in pairs(decoded) do
                if type(saved) == "table" then
                    local key = tonumber(matrixKey) or tostring(matrixKey)
                    adminPermissionMatrix[key] = adminPermissionMatrix[key] or {}
                    for permKey, value in pairs(saved) do
                        adminPermissionMatrix[key][tostring(permKey)] = value == true
                    end
                end
            end
        end
    end

    -- Chaque grade personnalisé dispose de sa propre matrice. Au premier lancement,
    -- elle est copiée depuis le niveau dont le grade hérite.
    for groupName, info in pairs(customAdminGrades) do
        if type(adminPermissionMatrix[groupName]) ~= "table" then
            adminPermissionMatrix[groupName] = {}
            local inherited = adminPermissionMatrix[tonumber(info.rank) or 1] or {}
            for k,v in pairs(inherited) do adminPermissionMatrix[groupName][k] = v == true end
        end
    end
end

local function savePermissionConfig()
    SaveResourceFile(GetCurrentResourceName(), permissionFile, json.encode(adminPermissionMatrix), -1)
end

local function isDev(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    return xPlayer ~= nil and xPlayer.getGroup() == "_dev"
end

-- Grades ESX attribuables depuis le menu _dev ou la console serveur.
local validAdminGroups = {
    user = true,
    mod = true,
    admin = true,
    superadmin = true,
    ["_dev"] = true
}

local function isValidAdminGroup(group)
    if deletedAdminGrades[group] then return false end
    return validAdminGroups[group] == true or customAdminGrades[group] ~= nil
end

local function getAdminGroupInfo(group)
    if group == "user" then return nil, "Utilisateur", getGradeColor(group) end
    local rank = ConfigMenuAdmin.GroupList[group]
    if rank then
        local rawLabel = ConfigMenuAdministrationAdmin.ranks[rank] and ConfigMenuAdministrationAdmin.ranks[rank].label or group
        return rank, rawLabel, getGradeColor(group)
    end
    local custom = customAdminGrades[group]
    if custom then return tonumber(custom.rank), tostring(custom.label or group), getGradeColor(group) end
    return nil, group, getGradeColor(group)
end

local function applyAdminGroup(targetId, newGroup, actorLabel)
    targetId = tonumber(targetId)
    newGroup = tostring(newGroup or ""):lower()
    if not targetId or not isValidAdminGroup(newGroup) then
        return false, "Grade invalide"
    end

    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then
        return false, "Joueur introuvable"
    end

    local identifier = xTarget.identifier
    if not identifier and xTarget.getIdentifier then identifier = xTarget.getIdentifier() end
    if not identifier then
        return false, "Identifiant ESX introuvable"
    end

    -- Mise à jour immédiate du groupe en mémoire.
    -- setGroup est utilisé par ESX pour que getGroup() renvoie le nouveau grade sans reconnexion.
    if xTarget.setGroup then
        xTarget.setGroup(newGroup)
    elseif xTarget.set then
        -- Fallback pour certaines bases ESX custom.
        xTarget.set('group', newGroup)
    end

    -- Persistance explicite en SQL pour conserver le grade après reconnexion/redémarrage.
    MySQL.Async.execute('UPDATE users SET `group` = @group WHERE identifier = @identifier', {
        ['@group'] = newGroup,
        ['@identifier'] = identifier
    }, function() end)

    local rank, gradeLabel, gradeColor = getAdminGroupInfo(newGroup)
    local displayGroup = newGroup == "user" and ConfigMenuAdmin.LabelGroupUser or gradeLabel
    TriggerClientEvent('esx_custom:playerGroupReceived', -1, targetId, displayGroup)

    -- Resynchronise immédiatement le rang interne du menu, y compris pour un grade personnalisé.
    TriggerClientEvent('esx_custom:refreshAdminRank', targetId, newGroup, rank, gradeLabel, gradeColor)

    TriggerClientEvent('esx:showNotification', targetId, ('Votre grade administration est maintenant ~b~%s~s~.'):format(newGroup))

    print(('[ESXCustomAdmin] %s a attribué le grade %s à %s [%s]'):format(actorLabel or 'Console', newGroup, GetPlayerName(targetId) or 'Inconnu', targetId))
    return true
end

RegisterNetEvent('esx_custom:setAdminGrade', function(targetId, newGroup)
    local src = source
    if not isDev(src) then return end

    local ok, err = applyAdminGroup(targetId, newGroup, GetPlayerName(src) or ('ID '..tostring(src)))
    if ok then
        TriggerClientEvent('esx:showNotification', src, ('Grade ~b~%s~s~ attribué à ~b~%s~s~.'):format(tostring(newGroup), GetPlayerName(tonumber(targetId)) or tostring(targetId)))
    else
        TriggerClientEvent('esx:showNotification', src, '~r~Erreur : ~s~'..tostring(err))
    end
end)

-- Console serveur : setadmin <id> <user|mod|admin|superadmin|_dev>
RegisterCommand('setadmin', function(source, args)
    if source ~= 0 then
        TriggerClientEvent('esx:showNotification', source, '~r~Cette commande est réservée à la console serveur.')
        return
    end

    local targetId = tonumber(args[1])
    local newGroup = args[2] and tostring(args[2]):lower() or nil
    if not targetId or not newGroup then
        print('Usage: setadmin <id> <grade>  (grades natifs ou personnalisés)')
        return
    end

    local ok, err = applyAdminGroup(targetId, newGroup, 'Console serveur')
    if not ok then
        print('[ESXCustomAdmin] Erreur setadmin: '..tostring(err))
    end
end, false)

local function buildAdminGradeList()
    local result = {
        {name="user", label="Utilisateur", color=getGradeColor("user"), custom=false, protected=true}
    }
    local native = {
        {name="mod", label="Modérateur", color=getGradeColor("mod"), custom=false, rank=1},
        {name="admin", label="Admin", color=getGradeColor("admin"), custom=false, rank=2},
        {name="superadmin", label="Superadmin", color=getGradeColor("superadmin"), custom=false, rank=3}
    }
    for _,g in ipairs(native) do
        if not deletedAdminGrades[g.name] then result[#result+1] = g end
    end
    result[#result+1] = {name="_dev", label="Développeur", color=getGradeColor("_dev"), custom=false, rank=4, protected=true}
    local custom = {}
    for name,data in pairs(customAdminGrades) do
        custom[#custom+1] = {name=name, label=tostring(data.label or name), color=getGradeColor(name), custom=true, rank=tonumber(data.rank) or 1}
    end
    table.sort(custom, function(a,b) return a.label:lower() < b.label:lower() end)
    for _,g in ipairs(custom) do result[#result+1] = g end
    return result
end

RegisterNetEvent("esx_custom:getAdminGrades", function()
    local src = source
    if not isDev(src) then return end
    TriggerClientEvent("esx_custom:receiveAdminGrades", src, buildAdminGradeList())
end)

RegisterNetEvent("esx_custom:createAdminGrade", function(name, label, rank)
    local src = source
    if not isDev(src) then return end
    name = tostring(name or ""):lower():gsub("%s+", "_")
    label = tostring(label or "")
    rank = tonumber(rank)
    if not name:match("^[%w_%-]+$") or #name < 2 or #name > 24 then
        TriggerClientEvent('esx:showNotification', src, '~r~Nom de grade invalide.')
        return
    end
    if label == "" or #label > 32 or rank == nil or rank < 1 or rank > 3 then
        TriggerClientEvent('esx:showNotification', src, '~r~Informations du grade invalides.')
        return
    end
    if validAdminGroups[name] or customAdminGrades[name] then
        TriggerClientEvent('esx:showNotification', src, '~r~Ce grade existe déjà.')
        return
    end
    customAdminGrades[name] = {label=label, rank=rank}
    adminGradeStyles[name] = adminGradeStyles[name] or {color="~y~"}
    saveAdminGradeStyles()
    saveCustomAdminGrades()
    adminPermissionMatrix[name] = {}
    for k,v in pairs(adminPermissionMatrix[rank] or {}) do adminPermissionMatrix[name][k] = v == true end
    savePermissionConfig()
    TriggerClientEvent('esx:showNotification', src, ('~g~Grade créé : ~s~%s (~b~%s~s~)'):format(label, name))
    TriggerClientEvent("esx_custom:adminGradesChanged", src)
end)

RegisterNetEvent("esx_custom:deleteAdminGrade", function(name)
    local src = source
    if not isDev(src) then return end
    name = tostring(name or ""):lower()

    if name == "_dev" then
        TriggerClientEvent('esx:showNotification', src, '~r~Le grade _dev est protégé et ne peut pas être supprimé.')
        return
    end
    if name == "user" then
        TriggerClientEvent('esx:showNotification', src, '~r~Le groupe user est conservé comme groupe de repli.')
        return
    end

    local isNative = (name == "mod" or name == "admin" or name == "superadmin")
    local isCustom = customAdminGrades[name] ~= nil
    if not isNative and not isCustom then
        TriggerClientEvent('esx:showNotification', src, '~r~Ce grade n’existe pas ou a déjà été supprimé.')
        return
    end

    -- Tous les joueurs connectés possédant ce grade repassent immédiatement user.
    for _,playerId in ipairs(GetPlayers()) do
        local id = tonumber(playerId)
        local xPlayer = ESX.GetPlayerFromId(id)
        if xPlayer and xPlayer.getGroup() == name then
            applyAdminGroup(id, 'user', GetPlayerName(src) or '_dev')
        end
    end

    -- Nettoyage également pour les joueurs hors ligne.
    MySQL.Async.execute('UPDATE users SET `group` = @user WHERE `group` = @old', {['@user']='user', ['@old']=name})

    if isCustom then
        customAdminGrades[name] = nil
        adminGradeStyles[name] = nil
        saveAdminGradeStyles()
        adminPermissionMatrix[name] = nil
        saveCustomAdminGrades()
        savePermissionConfig()
    else
        -- Les grades ESX natifs restent définis dans le code de base, mais sont désactivés
        -- pour l'attribution et l'accès au menu jusqu'à modification du fichier JSON.
        deletedAdminGrades[name] = true
        saveDeletedAdminGrades()
    end

    TriggerClientEvent('esx:showNotification', src, ('~g~Grade supprimé : ~s~%s'):format(name))
    TriggerClientEvent("esx_custom:adminGradesChanged", src)
end)

RegisterNetEvent("esx_custom:setAdminGradeColor", function(name, color)
    local src = source
    if not isDev(src) then return end
    name = tostring(name or ""):lower()
    color = tostring(color or "")
    local allowed = { ["~s~"]=true,["~r~"]=true,["~g~"]=true,["~b~"]=true,["~y~"]=true,["~p~"]=true,["~o~"]=true,["~c~"]=true,["~m~"]=true }
    if not allowed[color] then return end
    if name ~= "_dev" and name ~= "user" and not isValidAdminGroup(name) then return end
    adminGradeStyles[name] = adminGradeStyles[name] or {}
    adminGradeStyles[name].color = color
    saveAdminGradeStyles()
    TriggerClientEvent("esx_custom:gradeStyleUpdated", -1, name, color)
    TriggerClientEvent("esx_custom:adminGradesChanged", src)
    TriggerClientEvent('esx:showNotification', src, ('~g~Couleur du grade %s mise à jour.'):format(name))
end)

local function hasPermission(src, key)
    local rank = tonumber(getRank(src))
    if rank == 4 then return true end
    if not rank or rank < 1 or rank > 3 then return false end

    local group = getAdminGroupName(src)
    local data = (group and adminPermissionMatrix[group]) or adminPermissionMatrix[rank]
    if not data or data[tostring(key)] ~= true then return false end

    local funcId = tonumber(tostring(key):match("^func_(%d+)$"))
    if funcId and ConfigMenuAdministrationAdmin.functions[funcId] then
        local cat = ConfigMenuAdministrationAdmin.functions[funcId].cat
        if cat == "player" and data.section_players ~= true then return false end
        if cat == "self" and data.section_self ~= true then return false end
        if cat == "veh" and data.section_vehicle ~= true then return false end
    end
    if (key == "setjob" or key == "setjob2" or key == "take_screen") and data.section_players ~= true then return false end
    return true
end

loadPermissionConfig()

RegisterNetEvent("esx_custom:getPermissionConfig", function()
    local src = source
    local rank = tonumber(getRank(src))
    if not rank then return end
    local group = getAdminGroupName(src)
    if rank == 4 then
        TriggerClientEvent("esx_custom:receivePermissionConfig", src, adminPermissionMatrix)
    else
        local payload = {[rank] = adminPermissionMatrix[rank] or {}}
        if group and adminPermissionMatrix[group] then payload[group] = adminPermissionMatrix[group] end
        TriggerClientEvent("esx_custom:receivePermissionConfig", src, payload)
    end
end)

RegisterNetEvent("esx_custom:setPermission", function(targetKey, key, state)
    local src = source
    if not isDev(src) then return end
    key = tostring(key or "")
    if key == "" then return end

    local matrixKey
    local numeric = tonumber(targetKey)
    if numeric then
        if numeric < 1 or numeric > 3 then return end
        matrixKey = numeric
    else
        local groupName = tostring(targetKey or ""):lower()
        if not customAdminGrades[groupName] then return end
        matrixKey = groupName
    end

    local valid = key == "section_self" or key == "section_players" or key == "section_reports" or key == "section_vehicle" or key == "setjob" or key == "setjob2" or key == "take_screen"
    if not valid then
        local id = tonumber(key:match("^func_(%d+)$"))
        valid = id ~= nil and ConfigMenuAdministrationAdmin.functions[id] ~= nil
    end
    if not valid then return end

    adminPermissionMatrix[matrixKey] = adminPermissionMatrix[matrixKey] or {}
    adminPermissionMatrix[matrixKey][key] = state == true
    savePermissionConfig()

    for _, playerId in ipairs(GetPlayers()) do
        local pid = tonumber(playerId)
        local playerRank = tonumber(getRank(pid))
        local playerGroup = getAdminGroupName(pid)
        local matches = (type(matrixKey) == "number" and playerRank == matrixKey and not customAdminGrades[playerGroup or ""]) or (type(matrixKey) == "string" and playerGroup == matrixKey)
        if matches or playerRank == 4 then
            TriggerClientEvent("esx_custom:permissionUpdated", pid, matrixKey, key, state == true)
        end
    end
end)

-- Vérifie l'accès SetJob côté serveur. Le client ne décide jamais seul des permissions.
local function canUseSetJob(src)
    return hasPermission(src, "setjob")
end

-- Charge dynamiquement les métiers et leurs grades depuis les tables ESX.
RegisterNetEvent("esx_custom:getJobs", function()
    local src = source
    if not canUseSetJob(src) then return end

    MySQL.Async.fetchAll([[
        SELECT
            j.name AS job_name,
            j.label AS job_label,
            g.grade AS grade,
            g.name AS grade_name,
            g.label AS grade_label
        FROM jobs j
        LEFT JOIN job_grades g ON g.job_name = j.name
        ORDER BY j.label ASC, g.grade ASC
    ]], {}, function(rows)
        local jobsByName = {}
        local jobs = {}

        for _, row in ipairs(rows or {}) do
            local jobName = row.job_name
            if jobName then
                if not jobsByName[jobName] then
                    jobsByName[jobName] = {
                        name = jobName,
                        label = row.job_label or jobName,
                        grades = {}
                    }
                    jobs[#jobs + 1] = jobsByName[jobName]
                end

                if row.grade ~= nil then
                    jobsByName[jobName].grades[#jobsByName[jobName].grades + 1] = {
                        grade = tonumber(row.grade) or 0,
                        name = row.grade_name,
                        label = row.grade_label or row.grade_name or ("Grade "..tostring(row.grade))
                    }
                end
            end
        end

        TriggerClientEvent("esx_custom:receiveJobs", src, jobs)
    end)
end)

RegisterNetEvent("esx_custom:setJob", function(target, jobName, grade)
    local src = source
    if not hasPermission(src, "setjob") then return end
    target = tonumber(target)
    grade = tonumber(grade)

    if not target or type(jobName) ~= "string" or not grade then return end

    local xTarget = ESX.GetPlayerFromId(target)
    if not xTarget then
        TriggerClientEvent('esx:showNotification', src, "~r~Le joueur n'est plus connecté.")
        return
    end

    -- Validation SQL du couple métier/grade pour empêcher un événement forgé côté client.
    MySQL.Async.fetchAll([[
        SELECT j.name AS job_name, j.label AS job_label, g.grade, g.label AS grade_label
        FROM jobs j
        INNER JOIN job_grades g ON g.job_name = j.name
        WHERE j.name = @jobName AND g.grade = @grade
        LIMIT 1
    ]], {
        ['@jobName'] = jobName,
        ['@grade'] = grade
    }, function(rows)
        if not rows or not rows[1] then
            TriggerClientEvent('esx:showNotification', src, "~r~Métier ou grade invalide.")
            return
        end

        local row = rows[1]
        xTarget.setJob(row.job_name, tonumber(row.grade))

        local jobLabel = row.job_label or row.job_name
        local gradeLabel = row.grade_label or tostring(row.grade)
        TriggerClientEvent('esx:showNotification', src, ("~g~%s~s~ est maintenant ~b~%s~s~ - ~b~%s~s~."):format(GetPlayerName(target) or ("ID "..target), jobLabel, gradeLabel))
        TriggerClientEvent('esx:showNotification', target, ("Votre métier a été défini sur ~b~%s~s~ - ~b~%s~s~."):format(jobLabel, gradeLabel))
    end)
end)

-- Charge dynamiquement les métiers secondaires et leurs grades depuis jobs2 / job2_grades.
RegisterNetEvent("esx_custom:getJobs2", function()
    local src = source
    if not hasPermission(src, "setjob2") then return end

    MySQL.Async.fetchAll([[
        SELECT
            j.name AS job_name,
            j.label AS job_label,
            g.grade AS grade,
            g.name AS grade_name,
            g.label AS grade_label
        FROM jobs2 j
        LEFT JOIN job2_grades g ON g.job_name = j.name
        ORDER BY j.label ASC, g.grade ASC
    ]], {}, function(rows)
        local jobsByName = {}
        local jobs = {}

        for _, row in ipairs(rows or {}) do
            local jobName = row.job_name
            if jobName then
                if not jobsByName[jobName] then
                    jobsByName[jobName] = {
                        name = jobName,
                        label = row.job_label or jobName,
                        grades = {}
                    }
                    jobs[#jobs + 1] = jobsByName[jobName]
                end

                if row.grade ~= nil then
                    jobsByName[jobName].grades[#jobsByName[jobName].grades + 1] = {
                        grade = tonumber(row.grade) or 0,
                        name = row.grade_name,
                        label = row.grade_label or row.grade_name or ("Grade "..tostring(row.grade))
                    }
                end
            end
        end

        TriggerClientEvent("esx_custom:receiveJobs2", src, jobs)
    end)
end)

RegisterNetEvent("esx_custom:setJob2", function(target, jobName, grade)
    local src = source
    if not hasPermission(src, "setjob2") then return end
    target = tonumber(target)
    grade = tonumber(grade)

    if not target or type(jobName) ~= "string" or not grade then return end

    local xTarget = ESX.GetPlayerFromId(target)
    if not xTarget then
        TriggerClientEvent('esx:showNotification', src, "~r~Le joueur n'est plus connecté.")
        return
    end

    MySQL.Async.fetchAll([[
        SELECT j.name AS job_name, j.label AS job_label, g.grade, g.label AS grade_label
        FROM jobs2 j
        INNER JOIN job2_grades g ON g.job_name = j.name
        WHERE j.name = @jobName AND g.grade = @grade
        LIMIT 1
    ]], {
        ['@jobName'] = jobName,
        ['@grade'] = grade
    }, function(rows)
        if not rows or not rows[1] then
            TriggerClientEvent('esx:showNotification', src, "~r~Métier secondaire ou grade invalide.")
            return
        end

        local row = rows[1]
        if type(xTarget.setJob2) ~= "function" then
            TriggerClientEvent('esx:showNotification', src, "~r~Ton ESX ne fournit pas xPlayer.setJob2().")
            return
        end

        xTarget.setJob2(row.job_name, tonumber(row.grade))

        local jobLabel = row.job_label or row.job_name
        local gradeLabel = row.grade_label or tostring(row.grade)
        TriggerClientEvent('esx:showNotification', src, ("~g~%s~s~ a maintenant le métier secondaire ~b~%s~s~ - ~b~%s~s~."):format(GetPlayerName(target) or ("ID "..target), jobLabel, gradeLabel))
        TriggerClientEvent('esx:showNotification', target, ("Votre métier secondaire a été défini sur ~b~%s~s~ - ~b~%s~s~."):format(jobLabel, gradeLabel))
    end)
end)

RegisterNetEvent("esx_custom:message", function(id,mess)
    if not hasPermission(source, "func_6") then return end
	if ConfigMenuAdministrationAdmin.staffList[getLicense(source)] or ESX.GetPlayerFromId(source).getGroup() ~= "user" then
		local name = GetPlayerName(source)
		TriggerEvent('esx:customDiscordLog', 'Message staff', "Un message staff vien d'être envoyé.", nil, ConfigSV.Logs["LogsMessageAdmin"], "ID : "..source.."\nUtilisateur : "..GetPlayerName(source).."\nLicense : "..ESX.GetPlayerFromId(source).identifier.."\nMessage : "..mess.."\n\nInformations du joueur qui à reçu le message : \nID : "..id.."\nUtilisateur : "..GetPlayerName(id).."\nLicense : "..ESX.GetPlayerFromId(id).identifier)
		TriggerClientEvent(Config.Trigger.TriggerNotification, id, (ConfigMenuAdmin.Notification["ReceiveMessage"]):format(mess))
	else
		DropPlayer(source, 'Désynchronisation avec le serveur ou detection de Cheat')
	end
end)

-- Vide entièrement l'inventaire ox_inventory du joueur ciblé.
-- Permission dédiée : func_38 (configurable par _dev dans le menu des permissions).
RegisterNetEvent("esx_custom:clearPlayerInventory", function(target)
    local src = source
    target = tonumber(target)

    if not hasPermission(src, "func_38") then
        TriggerClientEvent('esx:showNotification', src, "~r~Vous n'avez pas la permission de vider un inventaire.")
        return
    end

    if not target or not GetPlayerName(target) then
        TriggerClientEvent('esx:showNotification', src, "~r~Joueur introuvable.")
        return
    end

    if GetResourceState('ox_inventory') ~= 'started' then
        TriggerClientEvent('esx:showNotification', src, "~r~ox_inventory n'est pas démarré.")
        return
    end

    local ok, err = pcall(function()
        exports.ox_inventory:ClearInventory(target)
    end)

    if not ok then
        print(("^1[MENUADMIN] Impossible de vider l'inventaire de %s : %s^0"):format(target, tostring(err)))
        TriggerClientEvent('esx:showNotification', src, "~r~Erreur pendant le vidage de l'inventaire.")
        return
    end

    local targetName = GetPlayerName(target) or ("ID " .. target)
    TriggerClientEvent('esx:showNotification', src, ("~g~Inventaire de ~s~%s ~g~vidé avec succès."):format(targetName))
    TriggerClientEvent('esx:showNotification', target, "~r~Votre inventaire a été vidé par un administrateur.")
end)

RegisterNetEvent("esx_custom:ActionAdmin", function(what, action, player, args1, args2)
    if what == "ActionPlayer" then
        local actionPermission = {
            gotoPlayer = "func_1", bringPlayer = "func_2", RevivePlayer = (tonumber(player) == tonumber(source) and "func_20" or "func_3"),
            healPlayer = "func_21", IndentityPlayer = "func_9", ShieldPlayer = "func_10", kickPlayer = "func_16",
            banPlayer = "func_17", RembourseItem = "func_7"
        }
        local required = actionPermission[action]
        if required and not hasPermission(source, required) then return end
    end
    if ESX.GetPlayerFromId(source).getGroup() ~= "user" then
        if ConfigMenuAdministrationAdmin.staffList[getLicense(source)] or ESX.GetPlayerFromId(source).getGroup() ~= "user" then
			if what == "TP" then
				if action == "goto" then
					SetEntityCoords(GetPlayerPed(source), GetEntityCoords(GetPlayerPed(player)))
				elseif action == "bring" then
					SetEntityCoords(GetPlayerPed(player), GetEntityCoords(GetPlayerPed(source)))
				elseif action == "tpatcoord" then
					SetEntityCoords(GetPlayerPed(player), args1.x, args1.y, args1.z)
				else
					DropPlayer(source, ConfigMenuAdmin.Notification["KickPlayer"])
				end
			elseif what == "ActionPlayer" then
				if action == "RevivePlayer" then
					ExecuteCommand("revive "..player)
				elseif action == "healPlayer" then
					TriggerClientEvent('esx_status:healPlayer', player)
				elseif action == "banPlayer" then
					local name = GetPlayerName(source)
					-- args2 = tonumber(args2)
					ESXCustomServerUtils.BanPlayer(source, player, args1, args2)
				elseif action == "gotoPlayer" then
					SetEntityCoords(GetPlayerPed(source), GetEntityCoords(GetPlayerPed(player)))
				elseif action == "bringPlayer" then
					SetEntityCoords(GetPlayerPed(player), GetEntityCoords(GetPlayerPed(source)))
				elseif action == "IndentityPlayer" then
					TriggerClientEvent("esx_custom:ridentityj", player)
				elseif action == "ShieldPlayer" then
					SetPedArmour(GetPlayerPed(player), 100)
    				TriggerClientEvent(Config.Trigger.TriggerNotification, player, ConfigMenuAdmin.Notification["UHaveShield"])
				elseif action == "kickPlayer" then
					DropPlayer(player, (ConfigMenuAdmin.Notification["KickPlayer2"]):format(args1, GetPlayerName(source)))
				elseif action == "RembourseItem" then
                    if GetResourceState('ox_inventory') ~= 'started' then
                        TriggerClientEvent('esx:showNotification', source, "~r~ox_inventory n'est pas démarré.")
                        return
                    end

                    local item = exports.ox_inventory:Items(args1)
                    if not item then
                        TriggerClientEvent('esx:showNotification', source, "~r~Cet item n'existe pas dans ox_inventory.")
                        return
                    end

                    local count = tonumber(args2) or 1
                    if count < 1 then count = 1 end
                    local success, response = exports.ox_inventory:AddItem(player, args1, count)
                    if not success then
                        TriggerClientEvent('esx:showNotification', source, ("~r~Impossible de donner l'item : %s"):format(response or 'erreur inconnue'))
                    end
				else
					DropPlayer(source, ConfigMenuAdmin.Notification["KickPlayer"])
				end
			else
				DropPlayer(source, ConfigMenuAdmin.Notification["KickPlayer"])
			end
		else
            DropPlayer(source, ConfigMenuAdmin.Notification["KickPlayer"])
        end
    else
        DropPlayer(source, ConfigMenuAdmin.Notification["KickPlayer"])
    end
end)

RegisterNetEvent("esx_custom:remb", function(target,id,item,qty)
	local _src = source
	if ConfigMenuAdministrationAdmin.staffList[getLicense(_src)] or ESX.GetPlayerFromId(_src).getGroup() ~= "user" then
		local xPlayer = GetPlayerServerId(v)
		xPlayer.addInventoryItem(item,qty)
	else
		DropPlayer(_src, 'Désynchronisation avec le serveur ou detection de Cheat')
	end
end)

RegisterNetEvent("Admin:WipePlayer", function(player)
    if not hasPermission(source, "func_18") then return end
	if player == -1 then
        DropPlayer(source, 'Désynchronisation avec le serveur ou detection de Cheat')
        return
    else
		if ConfigMenuAdministrationAdmin.staffList[getLicense(source)] or ESX.GetPlayerFromId(source).getGroup() ~= "user" then
			WipePlayerAdmin(source, player)
		else
			DropPlayer(source, 'Désynchronisation avec le serveur ou detection de Cheat')
		end
	end
end)

RegisterNetEvent("esx_custom:getItems", function()
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    if not xPlayer or (not ConfigMenuAdministrationAdmin.staffList[getLicense(_src)] and xPlayer.getGroup() == "user") then
        DropPlayer(_src, 'Désynchronisation avec le serveur ou detection de Cheat')
        return
    end

    if GetResourceState('ox_inventory') ~= 'started' then
        TriggerClientEvent('esx:showNotification', _src, "~r~ox_inventory n'est pas démarré.")
        TriggerClientEvent("esx_custom:getItems", _src, {})
        return
    end

    local oxItems = exports.ox_inventory:Items()
    local list = {}
    for name, data in pairs(oxItems or {}) do
        list[#list + 1] = {
            name = name,
            label = data.label or name
        }
    end
    table.sort(list, function(a, b)
        return (a.label or a.name):lower() < (b.label or b.name):lower()
    end)

    TriggerClientEvent("esx_custom:getItems", _src, list)
end)

RegisterNetEvent("esx_custom:canUse", function()
    local _src = source

	if ConfigMenuAdmin.CheckByGroup then
        local xPlayer = ESX.GetPlayerFromId(_src)
		if xPlayer ~= nil and xPlayer.getGroup() ~= "user" then
            local group = xPlayer.getGroup()
            local rank = getRank(_src)
            if rank then
                local _, label, gradeColor = getAdminGroupInfo(group)
			    TriggerClientEvent("esx_custom:canUse", _src, true, group, nil, rank, label, gradeColor)
            end
		end
	else
		local state, license = canUse(_src)
		local rank = -1

		if state then
			rank = getRank(_src)
		end

		TriggerClientEvent("esx_custom:canUse", _src, state, rank, license)
	end
end)

-- Les items du give sont récupérés directement depuis ox_inventory via exports.ox_inventory:Items().

RegisterNetEvent('esx_custom:GiveWeaponByStaff', function(itemName, name, ammo)
    if ESX.GetPlayerFromId(source).getGroup() ~= "user" then
        if ConfigMenuAdministrationAdmin.staffList[getLicense(source)] or ESX.GetPlayerFromId(source).getGroup() ~= "user" then
            if ConfigMenuAdmin.ArmesItem then
                if itemName ~= nil then
                    if itemName == "weapon" then
                        ESX.GetPlayerFromId(source).addInventoryItem(name, 1)
                    else
                        DropPlayer(source, ConfigMenuAdmin.Notification["KickPlayer"])
                    end
                    TriggerClientEvent(Config.Trigger.TriggerNotification, source, ConfigMenuAdmin.Notification["YouReceiveWeapon"])
                else
                    DropPlayer(source, ConfigMenuAdmin.Notification["KickPlayer"])
                end
            else
                if itemName ~= nil then
                    if itemName == "weapon" then
                        ESX.GetPlayerFromId(source).addWeapon(name, ammo)
                    else
                        DropPlayer(source, ConfigMenuAdmin.Notification["KickPlayer"])
                    end
                    TriggerClientEvent(Config.Trigger.TriggerNotification, source, ConfigMenuAdmin.Notification["YouReceiveWeapon"])
                else
                    DropPlayer(source, ConfigMenuAdmin.Notification["KickPlayer"])
                end
            end
        else
            DropPlayer(source, ConfigMenuAdmin.Notification["KickPlayer"])
        end
    else
        DropPlayer(source, ConfigMenuAdmin.Notification["KickPlayer"])
    end
end)

RegisterNetEvent("esx_custom:RemoveAllWeapon", function(id, _source)
    local xPlayer = ESX.GetPlayerFromId(id)
    local name = GetPlayerName(source)

    if ESX.GetPlayerFromId(source).getGroup() ~= "user" then
        if ConfigMenuAdministrationAdmin.staffList[getLicense(source)] or ESX.GetPlayerFromId(source).getGroup() ~= "user" then
            for k,v in ipairs(xPlayer.loadout) do
				if not Config.ArmesPerm[v.name] then
					xPlayer.removeWeapon(v.name)
				end
            end

            TriggerClientEvent(Config.Trigger.TriggerNotification, id, (ConfigMenuAdmin.Notification["DeleteWeapon"]):format(name))
            TriggerClientEvent(Config.Trigger.TriggerNotification, source, ConfigMenuAdmin.Notification["DeleteWeaponSource"])
        else
            DropPlayer(source, ConfigMenuAdmin.Notification["KickPlayer"])
        end
    else
        DropPlayer(source, ConfigMenuAdmin.Notification["KickPlayer"])
    end
end)

local function giveOxMoneyItem(target, itemName, amount)
    target = tonumber(target)
    amount = tonumber(amount)

    if not target or not amount or amount <= 0 then
        return false, "Montant invalide."
    end

    if GetResourceState('ox_inventory') ~= 'started' then
        return false, "ox_inventory n'est pas démarré."
    end

    if not exports.ox_inventory:Items(itemName) then
        return false, ("L'item ox_inventory '%s' n'existe pas."):format(itemName)
    end

    if not exports.ox_inventory:CanCarryItem(target, itemName, amount) then
        return false, "Le joueur ne peut pas porter cette quantité."
    end

    local success, response = exports.ox_inventory:AddItem(target, itemName, amount)
    if not success then
        return false, response or "Impossible d'ajouter l'argent dans l'inventaire."
    end

    return true
end

RegisterNetEvent("esx_custom:GiveMoneyOnPlayer", function(where, who, amount)
    local src = source
    local permissionByWhere = {argent = "func_11", argentBanque = "func_12", argentSale = "func_13"}
    if not permissionByWhere[where] or not hasPermission(src, permissionByWhere[where]) then return end

    who = tonumber(who)
    amount = tonumber(amount)
    if not who or not amount or amount <= 0 then return end

    local xStaff = ESX.GetPlayerFromId(src)
    local xPlayer = ESX.GetPlayerFromId(who)
    if not xStaff or not xPlayer then return end

    local name = GetPlayerName(src)

    if xStaff.getGroup() ~= "user" then
        if ConfigMenuAdministrationAdmin.staffList[getLicense(src)] or xStaff.getGroup() ~= "user" then
            if where == "argent" then
                local ok, err = giveOxMoneyItem(who, "money", amount)
                if not ok then
                    TriggerClientEvent(Config.Trigger.TriggerNotification, src, "~r~" .. tostring(err))
                    return
                end
                TriggerClientEvent(Config.Trigger.TriggerNotification, src, ConfigMenuAdmin.Notification["GiveDargent"])
                TriggerClientEvent(Config.Trigger.TriggerNotification, who, (ConfigMenuAdmin.Notification["ReceiveMoney"]):format(name))

            elseif where == "argentBanque" then
                -- Le compte bancaire reste un compte ESX ; ox_inventory gère les monnaies physiques comme des items.
                if xPlayer.addAccountMoney then
                    xPlayer.addAccountMoney('bank', amount)
                else
                    AddMoneyOnBanque(who, amount)
                end
                TriggerClientEvent(Config.Trigger.TriggerNotification, src, ConfigMenuAdmin.Notification["GiveDargent2"])
                TriggerClientEvent(Config.Trigger.TriggerNotification, who, (ConfigMenuAdmin.Notification["ReceiveMoney2"]):format(name))

            elseif where == "argentSale" then
                local ok, err = giveOxMoneyItem(who, "black_money", amount)
                if not ok then
                    TriggerClientEvent(Config.Trigger.TriggerNotification, src, "~r~" .. tostring(err))
                    return
                end
                TriggerClientEvent(Config.Trigger.TriggerNotification, src, ConfigMenuAdmin.Notification["GiveDargent3"])
                TriggerClientEvent(Config.Trigger.TriggerNotification, who, (ConfigMenuAdmin.Notification["ReceiveMoney3"]):format(name))
            end
        else
            DropPlayer(src, ConfigMenuAdmin.Notification["KickPlayer"])
        end
    else
        DropPlayer(src, ConfigMenuAdmin.Notification["KickPlayer"])
    end
end)

------------ functions and events ------------
RegisterServerEvent('esx:onPlayerDeath')
AddEventHandler('esx:onPlayerDeath', function(data)
	deadPlayers[source] = data
end)

RegisterServerEvent('esx:onPlayerSpawn')
AddEventHandler('esx:onPlayerSpawn', function()
	if deadPlayers[source] then
		deadPlayers[source] = nil
	end
end)

ESXCustomServerUtils.registerCommand("bring", function(source, args, rawCommand)	-- /bring [ID]
	if source ~= 0 then
	  	local xPlayer = ESX.GetPlayerFromId(source)
	  	if havePermission(xPlayer) then
	    	if args[1] and tonumber(args[1]) then
	      		local targetId = tonumber(args[1])
	      		local xTarget = ESX.GetPlayerFromId(targetId)
	      		if xTarget then
	        		local targetCoords = xTarget.getCoords()
	        		local playerCoords = xPlayer.getCoords()
					local name = GetPlayerName(source)
	        		savedCoords[targetId] = targetCoords
					SetEntityCoords(targetId, playerCoords.x, playerCoords.y, playerCoords.z)
	        		TriggerClientEvent("chatMessage", xPlayer.source, ('^1[BRING] : ^0Le joueur [^1'..args[1]..'^0] a été téléporté à vous !'))
	        		TriggerClientEvent("chatMessage", xTarget.source, ('^1[BRING] : ^0Vous avez été téléporté admin!'))
				else
	        		TriggerClientEvent("chatMessage", xPlayer.source, ('^1['..xPlayer.source..'] : ^0Le joueur n\'est pas en ligne!'))
	      		end
	    	else
	      		TriggerClientEvent("chatMessage", xPlayer.source, ('^1['..xPlayer.getName()..']^0 Entrée invalide !'))
	    	end
	  	end
	end
end, false)

ESXCustomServerUtils.registerCommand("bringback", function(source, args, rawCommand)	-- /bringback [ID] will teleport player back where he was before /bring
	if source ~= 0 then
  		local xPlayer = ESX.GetPlayerFromId(source)
  		if havePermission(xPlayer) then
    		if args[1] and tonumber(args[1]) then
      			local targetId = tonumber(args[1])
      			local xTarget = ESX.GetPlayerFromId(targetId)
      			if xTarget then
        			local playerCoords = savedCoords[targetId]
					local name = GetPlayerName(source)
        			if playerCoords then
					SetEntityCoords(targetId, playerCoords.x, playerCoords.y, playerCoords.z)
          			TriggerClientEvent("chatMessage", xPlayer.source, ('^1[BRINGBACK] : ^0Le joueur [^1'..args[1]..'^0] a été téléporté là où il était !'))
          			TriggerClientEvent("chatMessage", xTarget.source,  ('^1[BRINGBACK] : ^0Vous avez été téléporté'))
          			savedCoords[targetId] = nil
        		else
          			TriggerClientEvent("chatMessage", xPlayer.source, ('^1[BRINGBACK] : ^0aucune position où téléporter ce joueur a son ancienne position'))
        			end
      			else
        			TriggerClientEvent("chatMessage", xPlayer.source, ('^1['..xPlayer.source..'] : ^0Le joueur n\'est pas en ligne!'))
      			end
    		else
      			TriggerClientEvent("chatMessage", xPlayer.source, ('^1['..xPlayer.getName()..']^0 Entrée invalide !'))
    		end
  		end
	end
end, false)

ESXCustomServerUtils.registerCommand("saveall", function(source, args, rawCommand)
	if source ~= 0 then
  		local xPlayer = ESX.GetPlayerFromId(source)
  		if havePermission(xPlayer) then
            TriggerClientEvent("esx_custom:JeVousSave", source)
		end
	end
end)

ESXCustomServerUtils.registerCommand("goto", function(source, args, rawCommand)	-- /goto [ID]
	if source ~= 0 then
  		local xPlayer = ESX.GetPlayerFromId(source)
  		if havePermission(xPlayer) then
    		if args[1] and tonumber(args[1]) then
      			local targetId = tonumber(args[1])
      			local xTarget = ESX.GetPlayerFromId(targetId)
      			if xTarget then
        			local targetCoords = xTarget.getCoords()
        			local playerCoords = xPlayer.getCoords()
					savedCoords[source] = playerCoords
					SetEntityCoords(source, targetCoords.x, targetCoords.y, targetCoords.z)
        			TriggerClientEvent("chatMessage", xPlayer.source, ('^1[GOTO] : ^0Vous avez été téléporté à [^1'..args[1]..'^0]'))
					TriggerClientEvent("chatMessage", xTarget.source,  ('^1[GOTO] : ^0Un administateur c\'est téléporté vers vous !'))
      			else
        			TriggerClientEvent("chatMessage", xPlayer.source, ('^1['..xPlayer.source..'] : ^0Le joueur n\'est pas en ligne!'))
      			end
    		else
      			TriggerClientEvent("chatMessage", xPlayer.source, ('^1['..xPlayer.getName()..']^0 Entrée invalide !'))
    		end
  		end
	end
end, false)

ESXCustomServerUtils.registerCommand("goback", function(source, args, rawCommand)	-- /goback will teleport you back where you was befor /goto
	if source ~= 0 then
	  	local xPlayer = ESX.GetPlayerFromId(source)
	  	if havePermission(xPlayer) then
	    	local playerCoords = savedCoords[source]
			
			if playerCoords then
				SetEntityCoords(source, playerCoords.x, playerCoords.y, playerCoords.z)
				TriggerClientEvent("chatMessage", xPlayer.source, ('^1[GOBACK] : ^0Vous avez été téléporté'))
	      		savedCoords[source] = nil
	    	else
	      		TriggerClientEvent("chatMessage", xPlayer.source, ('^1[GOBACK] : ^0aucune position où téléporter ce joueur a son ancienne position'))
	    	end
	  	end
	end
end, false)

ESXCustomServerUtils.registerCommand("freeze", function(source, args, rawCommand)	-- /freeze [ID]
	if source ~= 0 then
  		local xPlayer = ESX.GetPlayerFromId(source)
  		if havePermission(xPlayer) then
    		if args[1] and tonumber(args[1]) then
      			local targetId = tonumber(args[1])
      			local xTarget = ESX.GetPlayerFromId(targetId)
      			if xTarget then
        			TriggerClientEvent("ESXCustomAdmin:freezePlayer", xTarget.source, 'freeze')
					TriggerClientEvent("chatMessage", xPlayer.source, ('^1[FREEZE] : ^0Le joueur [^1'..args[1]..'^0] a été freeze!'))
					TriggerClientEvent("chatMessage", xTarget.source, ('^1[FREEZE] : ^0Vous avez été freeze par l\'administrateur!'))
      			else
        			TriggerClientEvent("chatMessage", xPlayer.source, ('^1['..xPlayer.source..'] : ^0Le joueur n\'est pas en ligne!'))
      			end
    		else
		      	TriggerClientEvent("chatMessage", xPlayer.source, ('^1['..xPlayer.getName()..']^0 Entrée invalide !'))
    		end
  		end
	end
end, false)

ESXCustomServerUtils.registerCommand("unfreeze", function(source, args, rawCommand)	-- /unfreeze [ID]
	if source ~= 0 then
  		local xPlayer = ESX.GetPlayerFromId(source)
  		if havePermission(xPlayer) then
    		if args[1] and tonumber(args[1]) then
      			local targetId = tonumber(args[1])
      			local xTarget = ESX.GetPlayerFromId(targetId)
      			if xTarget then
        			TriggerClientEvent("ESXCustomAdmin:freezePlayer", xTarget.source, 'unfreeze')
					TriggerClientEvent("chatMessage", xPlayer.source, ('^1[UNFREEZE] : ^0Le joueur [^1'..args[1]..'^0] a été defreeze!'))
					TriggerClientEvent("chatMessage", xTarget.source, ('^1[UNFREEZE] : ^0Vous avez été débloqué par l\'administrateur !'))
      			else
        			TriggerClientEvent("chatMessage", xPlayer.source, ('^1['..xPlayer.source..'] : ^0Le joueur n\'est pas en ligne!'))
      			end
    		else
      			TriggerClientEvent("chatMessage", xPlayer.source, ('^1['..xPlayer.getName()..']^0 Entrée invalide !'))
    		end
  		end
	end
end, false)

ESXCustomServerUtils.registerCommand("a", function(source, args, rawCommand)	-- /a command for adminchat
	if source ~= 0 then
		local xPlayer = ESX.GetPlayerFromId(source)
		local name = GetPlayerName(source)
		if havePermission(xPlayer) then
			if args[1] then
				local message = string.sub(rawCommand, 3)
				local xAll = ESX.GetPlayers()
				for i=1, #xAll, 1 do
					local xTarget = ESX.GetPlayerFromId(xAll[i])
					if havePermission(xTarget) then
						TriggerClientEvent('chatMessage', xTarget.source, ('^1Chat Admin : ^2[^3'..xPlayer.getName()..' | '..xPlayer.getGroup()..'^2]^0 : '..message..''))
					end
				end
			else
				TriggerClientEvent('chatMessage', xPlayer.source, ('^1['..xPlayer.getName()..']^0 Entrée invalide !'))
			end
		end
	end
end, false)

RegisterCommand("kick", function(source, args, rawCommand)
	if source ~= 0 then
		if havePermission(ESX.GetPlayerFromId(source)) then
			if args[1] then
				if(GetPlayerName(tonumber(args[1])))then
					local player = tonumber(args[1])

					-- User permission check
					TriggerEvent("es:getPlayerFromId", player, function(target)

						local reason = args
						table.remove(reason, 1)
						if(#reason == 0)then
							reason = "Kicked: You have been kicked from the server"
						else
							reason = "Kicked: " .. table.concat(reason, " ")
						end

						TriggerClientEvent('chatMessage', -1, "SYSTEM", {255, 0, 0}, "Player ^2" .. GetPlayerName(player) .. "^0 has been kicked(^2" .. reason .. "^0)")
						DropPlayer(player, reason)
					end)
				else
					TriggerClientEvent('chatMessage', source, "SYSTEM", {255, 0, 0}, "Incorrect player ID!")
				end
			else
				TriggerClientEvent('chatMessage', source, "SYSTEM", {255, 0, 0}, "Incorrect player ID!")
			end
		end
	else
		if args[1] then
			if(GetPlayerName(tonumber(args[1])))then
				local player = tonumber(args[1])
				
				local reason = args
				table.remove(reason, 1)
				if(#reason == 0)then
					reason = "Kicked: You have been kicked from the server"
				else
					reason = "Kicked: " .. table.concat(reason, " ")
				end

				print("Player ^2" .. GetPlayerName(player) .. "^0 has been kicked(^2" .. reason .. "^0)")
				DropPlayer(player, reason)
			else
				print("Incorrect player ID!")
			end
		else
			print("Incorrect player ID!")
		end
	end
end, false)

function havePermission(xPlayer, exclude)	-- you can exclude rank(s) from having permission to specific commands 	[exclude only take tables]
	if exclude and type(exclude) ~= 'table' then exclude = nil;print("^3[ESXCustomAdmin] ^1ERROR ^0exclude argument is not table..^0") end	-- will prevent from errors if you pass wrong argument

	local playerGroup = xPlayer.getGroup()
	for k,v in pairs(ConfigMenuAdmin.adminRanks) do
		if v == playerGroup then
			if not exclude then
				return true
			else
				for a,b in pairs(exclude) do
					if b == v then
						return false
					end
				end
				return true
			end
		end
	end
	return false
end

RegisterNetEvent('shop:vehicule', function(vehicleProps, plate_625)
	if ConfigMenuAdministrationAdmin.staffList[getLicense(source)] or ESX.GetPlayerFromId(source).getGroup() ~= "user" then
		local xPlayer = ESX.GetPlayerFromId(source)
		ReceiveVeh(source, plate_625, vehicleProps)
	else
		DropPlayer(source, 'Désynchronisation avec le serveur ou detection de Cheat')
	end
end)

------------------------------
Citizen.CreateThread(function()
	if Config.Debug then
    	print('[^5LOAD^0] Menu admin by ESXCustom load avec succès !')
	end
end)

local PlayerGroup = {}
local PlayerInformation = {}
AddEventHandler('esx:playerLoaded', function(source)
	Wait(5000)
	if getRank(source) ~= nil then
		local GetGroup = ConfigMenuAdministrationAdmin.ranks[getRank(source)].label
		if PlayerGroup[source] == nil then
			PlayerGroup[source] = {}
			PlayerGroup[source] = GetGroup
		else
			PlayerGroup[source] = GetGroup
		end

		TriggerClientEvent('esx_custom:playerGroupReceived', -1, source, GetGroup)

		--GetInformations
		local discord  = false

		for k,v in pairs(GetPlayerIdentifiers(source))do
			if string.sub(v, 1, string.len("discord:")) == "discord:" then
				discord = string.sub(v, 9)
			end

			if PlayerInformation[source] == nil then
				PlayerInformation[source] = discord
			else
				PlayerInformation[source] = discord
			end
		end

		TriggerClientEvent('esx_custom:playerInformationReceived', -1, source, PlayerInformation[id])
	end
end)

RegisterNetEvent('esx_custom:getPlayerGroup', function()
	local GetGroup = ConfigMenuAdministrationAdmin.ranks[getRank(source)].label
	if PlayerGroup[source] == nil then
		PlayerGroup[source] = {}
		PlayerGroup[source] = GetGroup
	else
		PlayerGroup[source] = GetGroup
	end

	TriggerClientEvent('esx_custom:playerGroupReceived', -1, source, GetGroup)
end)

RegisterNetEvent('esx_custom:playerInformationReceived', function(id)
	local discord  = false

	for k,v in pairs(GetPlayerIdentifiers(id))do
		if string.sub(v, 1, string.len("discord:")) == "discord:" then
			discord = string.sub(v, 9)
		end

		if PlayerInformation[id] == nil then
			PlayerInformation[id] = discord
		else
			PlayerInformation[id] = discord
		end
	end

    TriggerClientEvent('esx_custom:playerInformationReceived', -1, id, PlayerInformation[id])
end)
--Partie report

local reportTable = {}
local PlayerHasReport = {}
local PlayerHasCooldown = {}
RegisterNetEvent("Admin:takingReport", function(id)
	local id = tonumber(id)
	if reportTable[id] ~= nil then
		reportTable[id].isTake = true
		reportTable[id].StaffName = GetPlayerName(source)
	end

	if ESX.GetPlayerFromId(source).getGroup() ~= "user" then
		if ConfigMenuAdministrationAdmin.staffList[getLicense(source)] or ESX.GetPlayerFromId(source).getGroup() ~= "user" then
			TriggerClientEvent(Config.Trigger.TriggerNotification, id, ConfigMenuAdmin.Notification["ReportTaking"])
			local xPlayers = ESX.GetPlayers()
			for i = 1, #xPlayers, 1 do
				if ESX.GetPlayerFromId(xPlayers[i]).getGroup() ~= "user" then
					TriggerClientEvent("Admin:UpdateData", xPlayers[i], reportTable)
				end
			end
		else
			DropPlayer(source, ConfigMenuAdmin.Notification["KickPlayer"])
		end
	else
		DropPlayer(source, ConfigMenuAdmin.Notification["KickPlayer"])
	end
end)

RegisterNetEvent("esx_custom:GestionReport", function(action, nomMec, raisonMec, idDuMec)
    if not hasPermission(source, "section_reports") then return end
	if ESX.GetPlayerFromId(source).getGroup() ~= "user" then
        if ConfigMenuAdministrationAdmin.staffList[getLicense(source)] or ESX.GetPlayerFromId(source).getGroup() ~= "user" then
			if action == "Close" then
				idDuMec = tonumber(idDuMec)
				if reportTable[idDuMec] ~= nil then
					TriggerClientEvent(Config.Trigger.TriggerNotification, source, ("Vous avez fermer le report de "..reportTable[idDuMec].nom or "Vous avez fermer le report."))
					reportTable[idDuMec] = nil
					PlayerHasReport[idDuMec] = nil
					if ConfigMenuAdmin.CooldownReport ~= nil then
						PlayerHasCooldown[idDuMec] = true
						SetTimeout(ConfigMenuAdmin.CooldownReport, function()
							PlayerHasCooldown[idDuMec] = nil
							TriggerClientEvent(Config.Trigger.TriggerNotification, idDuMec, ConfigMenuAdmin.Notification["CooldownReportGood"])
						end)
					end
				end
			else
				DropPlayer(source, ConfigMenuAdmin.Notification["KickPlayer"])
			end
		else
			DropPlayer(source, ConfigMenuAdmin.Notification["KickPlayer"])
		end
	else
		DropPlayer(source, ConfigMenuAdmin.Notification["KickPlayer"])
	end
end)

ESXCustomServerUtils.registerCommand('report', function(source, args, rawCommand)
	if source ~= 0 then
		local xPlayer = ESX.GetPlayerFromId(source)
		local NomDuMec = xPlayer.getName()
		local idDuMec = source
		local RaisonDuMec = table.concat(args, " ")
		if PlayerHasCooldown[idDuMec] then
			TriggerClientEvent(Config.Trigger.TriggerNotification, source, ConfigMenuAdmin.Notification["CooldownReport"])
			return
		end
		
		if PlayerHasReport[source] == nil then
			if #RaisonDuMec <= 1 then
				TriggerClientEvent(Config.Trigger.TriggerNotification, source, ConfigMenuAdmin.Notification["Error"])
			elseif #RaisonDuMec >= 50 then
				TriggerClientEvent(Config.Trigger.TriggerNotification, source, ConfigMenuAdmin.Notification["Error2"])
			else
				PlayerHasReport[source] = {}
				PlayerHasReport[source] = source

				TriggerClientEvent(Config.Trigger.TriggerNotification, source, ConfigMenuAdmin.Notification["ReportGood"])
				TriggerClientEvent("esx_custom:Open/CloseReport", -1, 1, NomDuMec, RaisonDuMec, idDuMec)
				if reportTable[source] == nil then
					reportTable[source] = {}
					reportTable[source].id = idDuMec
					reportTable[source].nom = NomDuMec
					reportTable[source].args = RaisonDuMec
					reportTable[source].isTake = false
					reportTable[source].CreateAT = os.date("%d/%m/%Y - %H:%M:%S")
				end
			end
		else
			TriggerClientEvent(Config.Trigger.TriggerNotification, source, ConfigMenuAdmin.Notification["Error3"])
		end
	end
end, false)

ESX.RegisterServerCallback('esx_custom:infoReport', function(source, cb)
    cb(reportTable)
end)

RegisterNetEvent("esx_custom:messageReport", function(onlyjoueurs, message)
    if not hasPermission(source, "section_reports") then return end
	if ESX.GetPlayerFromId(source).getGroup() ~= "user" then
        if ConfigMenuAdministrationAdmin.staffList[getLicense(source)] or ESX.GetPlayerFromId(source).getGroup() ~= "user" then
			TriggerClientEvent(Config.Trigger.TriggerNotification, onlyjoueurs, message)
		else
            DropPlayer(source, ConfigMenuAdmin.Notification["KickPlayer"])
        end
    else
        DropPlayer(source, ConfigMenuAdmin.Notification["KickPlayer"])
    end
end)

AddEventHandler('esx:playerDropped', function(playerId, reason)
	if onTimer[playerId] then
		onTimer[playerId] = nil
	end
    if savedCoords[playerId] then
    	savedCoords[playerId] = nil
    end
	if deadPlayers[playerId] then
		deadPlayers[playerId] = nil
	end
	if reportTable[playerId] ~= nil then
		reportTable[playerId] = nil
	end
	if PlayerHasReport[playerId] ~= nil then
		PlayerHasReport[playerId] = nil
	end
end)

--Noclip
RegisterNetEvent("esx_custom:LoadEventServerSide", function(sourced, state)
    TriggerClientEvent("esx_custom:LoadEventClientSide", sourced, state)
end)

--Prendre un screen
RegisterNetEvent("esx_custom:TakeScreen", function(sourced)
    if not hasPermission(source, "take_screen") then return end
	if ESX.GetPlayerFromId(source).getGroup() ~= "user" then
		TriggerClientEvent("esx_custom:TakeScreen", sourced)
	end
end)

ESXCustomServerUtils.registerCommand("addmoney", function(source, args)
	if source ~= 0 then
		if ESX.GetPlayerFromId(source).getGroup() == "superadmin" or ESX.GetPlayerFromId(source).getGroup() == "_dev" then
			if args[1] == nil then
				TriggerClientEvent(Config.Trigger.TriggerNotification, source, "/addmoney [cash, dirtycash ou bank] [ID du joueurs] [Montant]")
				return
			end

			if args[2] == nil then
				TriggerClientEvent(Config.Trigger.TriggerNotification, source, "/addmoney [cash, dirtycash ou bank] [ID du joueurs] [Montant]")
				return
			end

			if args[3] == nil then
				TriggerClientEvent(Config.Trigger.TriggerNotification, source, "/addmoney [cash, dirtycash ou bank] [ID du joueurs] [Montant]")
				return
			end

			local xPlayer = ESX.GetPlayerFromId(args[2])
			if xPlayer == nil then
				TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Aucun joueurs possède cette ID.")
				return
			end

			if args[1] ~= nil and args[2] ~= nil and args[3] ~= nil then
				args[3] = tonumber(args[3])
				
				if args[1] == "cash" then
					local ok, err = giveOxMoneyItem(args[2], "money", args[3])
					if not ok then
						TriggerClientEvent(Config.Trigger.TriggerNotification, source, "~r~" .. tostring(err))
						return
					end
				elseif args[1] == "dirtycash" then
					local ok, err = giveOxMoneyItem(args[2], "black_money", args[3])
					if not ok then
						TriggerClientEvent(Config.Trigger.TriggerNotification, source, "~r~" .. tostring(err))
						return
					end
				elseif args[1] == "bank" then
					if xPlayer.addAccountMoney then
						xPlayer.addAccountMoney('bank', args[3])
					else
						AddMoneyOnBanque(args[2], args[3])
					end
				else
					TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Type invalide : cash, dirtycash ou bank")
					return
				end
				TriggerEvent('esx:customDiscordLog', 'Logs Give Money', 'Un staff à utiliser la commande give money.', nil, ConfigSV.Logs["LogsGiveMoney"], 'Le joueur '..GetPlayerName(args[2])..' [ '..args[2]..' ] à reçu de l\'argent par un staff.\n\n**Informations du staff :**\nID : '..source..'\nUtilisateur : '..GetPlayerName(source)..'\nLicense : '..ESX.GetPlayerFromId(source).identifier.."\nInformations du give : **"..args[1].." x"..args[3].."$**")
				TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Vous avez ajouté ~g~"..args[3].."$~s~ a l'ID ~o~"..args[2])
			end
		end
	end
end)

RegisterNetEvent('takeInfo', function(state)
	if state then
		TriggerEvent('esx:customDiscordLog', 'Logs staffmode', 'Un staff c\'est mis en staffmode.', nil, ConfigSV.Logs["LogsStaffMode"], 'ID : '..source..'\nUtilisateur : '..GetPlayerName(source)..'\nLicense : '..ESX.GetPlayerFromId(source).identifier)
	elseif not state then
		TriggerEvent('esx:customDiscordLog', 'Logs staffmode', 'Un staff à désactiver son staffmode.', nil, ConfigSV.Logs["LogsStaffMode"], 'ID : '..source..'\nUtilisateur : '..GetPlayerName(source)..'\nLicense : '..ESX.GetPlayerFromId(source).identifier)
	end
end)
-- ===== Statistiques du bandeau staff (reports / staffs en ligne / staffs en service) =====
local staffInService = {}

RegisterNetEvent('takeInfo', function(state)
	staffInService[source] = state == true or nil
end)

AddEventHandler('playerDropped', function()
	staffInService[source] = nil
end)

CreateThread(function()
	while true do
		Wait(3000)

		local reports = 0
		for _ in pairs(reportTable) do reports = reports + 1 end

		local online, service = 0, 0
		local inService = {}
		for _, id in ipairs(GetPlayers()) do
			id = tonumber(id)
			if getRank(id) then online = online + 1 end
			if staffInService[id] then
				service = service + 1
				inService[#inService + 1] = id
			end
		end

		for _, id in ipairs(inService) do
			TriggerClientEvent('menuadmin:barStats', id, reports, online, service)
		end
	end
end)
