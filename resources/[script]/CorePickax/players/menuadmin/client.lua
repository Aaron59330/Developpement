local staffService = false
local showStaffHud = true -- affiche / masque le HUD staff (Paramètres perso)
local NoClip = false
local ShowName = false
local invisible = false
local invincible = false
local staffRank = nil
local currentAdminGroupLabel = nil
local currentAdminGroupName = nil
local colorVar = nil
local selected = nil
local isSubMenu = {[false] = { RightLabel = "~b~Éxecuter ~s~→→" },[true] = { RightLabel = "~s~→→" }}
local stringText = {[true] = "~g~ON~s~",[false] = "~r~OFF~s~"}
local possiblesQty = {}
local gamerTags = {}
local items = {}
local qty = 1
local NoClipSpeed =  2.0
local NoClipF2 = false
local noclipEntity = nil
local CooldownScreen = false
local ChecktheHeading = false

-- SetJob / SetJob2 admin : listes dynamiques chargées depuis SQL
local adminJobs = {}
local selectedAdminJob = nil
local adminJobs2 = {}
local selectedAdminJob2 = nil

-- Grades administration dynamiques (grades natifs + grades créés par _dev)
local adminGradeList = {}
local pendingCustomGrade = nil
local selectedGradeStyleName = nil
local selectedGradeStyleLabel = nil

RegisterNetEvent("CorePickax:receiveJobs", function(jobs)
    adminJobs = jobs or {}
end)

RegisterNetEvent("CorePickax:receiveJobs2", function(jobs)
    adminJobs2 = jobs or {}
end)

RegisterNetEvent("CorePickax:receiveAdminGrades", function(grades)
    adminGradeList = grades or {}
end)

-- Maintient l'invincibilité même si une autre fonction (ex: noclip) modifie temporairement l'état du ped.
CreateThread(function()
    while true do
        Wait(500)
        if invincible and staffService then
            SetEntityInvincible(PlayerPedId(), true)
            SetPlayerInvincible(PlayerId(), true)
        end
    end
end)

RegisterNetEvent("CorePickax:adminGradesChanged", function()
    TriggerServerEvent("CorePickax:getAdminGrades")
end)

RegisterNetEvent("CorePickax:gradeStyleUpdated", function(group, color)
    if currentAdminGroupName == group then colorVar = color or colorVar end
    for _,g in ipairs(adminGradeList) do if g.name == group then g.color = color end end
end)

-- Permissions dynamiques du menu, configurables par le rôle _dev.
local adminPermissionMatrix = {}
local selectedPermissionRank = 1
local selectedPermissionLabel = "Modérateur"

local function hasAdminPermission(key)
    local rank = tonumber(staffRank)
    if rank == 4 then return true end
    if not rank then return false end

    local rankPermissions = (currentAdminGroupName and adminPermissionMatrix[currentAdminGroupName]) or adminPermissionMatrix[rank] or {}
    local value = rankPermissions[tostring(key)]
    if value ~= nil then return value == true end

    local funcId = tonumber(tostring(key):match("^func_(%d+)$"))
    if funcId then
        for _, allowedId in ipairs(ConfigMenuAdministrationAdmin.ranks[rank].permissions or {}) do
            if tonumber(allowedId) == funcId then return true end
        end
        return false
    end
    if key == "setjob" or key == "setjob2" then return rank >= 2 end
    if key == "section_self" or key == "section_players" or key == "section_reports" or key == "section_vehicle" or key == "take_screen" then return true end
    return false
end

RegisterNetEvent("CorePickax:receivePermissionConfig", function(matrix)
    adminPermissionMatrix = matrix or {}
end)

RegisterNetEvent("CorePickax:permissionUpdated", function(targetKey, key, state)
    local numeric = tonumber(targetKey)
    local matrixKey = numeric or tostring(targetKey)
    adminPermissionMatrix[matrixKey] = adminPermissionMatrix[matrixKey] or {}
    adminPermissionMatrix[matrixKey][tostring(key)] = state == true
end)

-- Mise à jour immédiate du rang staff après /setadmin ou attribution depuis le menu.
RegisterNetEvent("CorePickax:refreshAdminRank", function(group, forcedRank, forcedLabel, forcedColor)
    if ConfigMenuAdmin.CheckByGroup then
        local newRank = tonumber(forcedRank) or ConfigMenuAdmin.GroupList[group]
        staffRank = newRank
        currentAdminGroupName = group
        currentAdminGroupLabel = forcedLabel or group
        colorVar = forcedColor or colorVar or "~r~"

        if group == "user" or not newRank then
            staffRank = nil
            staffService = false
            RageUI.CloseAll()
            ESX.ShowNotification("~r~Vous n'avez plus accès au menu administration.")
            return
        end

        -- Recharge la matrice de permissions. _dev (rang 4) contourne toujours les restrictions.
        TriggerServerEvent("CorePickax:getPermissionConfig")
        ESX.ShowNotification(("~g~Permissions administration actualisées : ~s~%s"):format(group))
    else
        -- En mode liste/licence, on redemande simplement les droits au serveur.
        TriggerServerEvent("CorePickax:canUse")
    end
end)

CreateThread(function()
	TriggerEvent('chat:addSuggestion', '/report', 'Faire un report',{
		{ name = "raison", help = "Raison du report (exemple : freekill au pc)" }
	})
    TriggerEvent('chat:addSuggestion', '/addmoney', 'Ajouté de l\'argent.',{
		{ name = "Account", help = "(exemple : cash ou bank ou dirtycash)" },
		{ name = "ID", help = "(exemple : 1)" },
		{ name = "Montant", help = "(exemple : 2500)" }
	})
end)

-------------------------------------------------------------
local IndexReport = 1
local reportlist = {}
local ESXCustomListButon = {
    ReportMenu = 1,
    PlayerList = 1
}

local showinterior = false
local MenuStaffOpenState = false
Citizen.CreateThread(function()
end)

local playerGroup = {}

RegisterNetEvent('CorePickax:playerGroupReceived', function(playerId, group)
    playerGroup[playerId] = group
end)

local playerInformationReceived = {}
RegisterNetEvent('CorePickax:playerInformationReceived', function(playerId, Informations)
    playerInformationReceived[playerId] = Informations
end)

RegisterKeyMapping(ConfigMenuAdmin.Commande.CommandeName, ConfigMenuAdmin.Commande.Desc, 'keyboard', ConfigMenuAdmin.Commande.Bind)

RegisterCommand(ConfigMenuAdmin.Commande.CommandeName, function()
    if MenuStaffOpenState then
        MenuStaffOpenState = false
        RageUI.CloseAll()
    else
        if not IsPedDeadOrDying(PlayerPedId(), 1) then
            MenuStaffOpenState = true
            MenuStaffOpen()
        end
    end
end)

local function starts(String, Start)
    return string.sub(String, 1, string.len(Start)) == Start
end

local function getInfoReport()
    local info = {}
    ESX.TriggerServerCallback('CorePickax:infoReport', function(info)
        reportlist = info
    end)
end

function MonID()
    return GetPlayerServerId(PlayerId())
end

-------------------------------------------------------------

Citizen.CreateThread(function()
    Wait(5000)
    TriggerServerEvent("CorePickax:canUse")
end)

local function getItems()
    TriggerServerEvent("CorePickax:getItems")
end

local function getCamDirection()
	local heading = GetGameplayCamRelativeHeading() + GetEntityHeading(GetPlayerPed(-1))
	local pitch = GetGameplayCamRelativePitch()
	local coords = vector3(-math.sin(heading * math.pi / 180.0), math.cos(heading * math.pi / 180.0), math.sin(pitch * math.pi / 180.0))
	local len = math.sqrt((coords.x * coords.x) + (coords.y * coords.y) + (coords.z * coords.z))

	if len ~= 0 then
		coords = coords / len
	end

	return coords
end

local function getCurrentStaffOutfit()
    if ConfigMenuAdmin.GradeOutfits and currentAdminGroupName and ConfigMenuAdmin.GradeOutfits[currentAdminGroupName] then
        return ConfigMenuAdmin.GradeOutfits[currentAdminGroupName]
    end
    return ConfigMenuAdministrationAdmin.ranks[staffRank] and ConfigMenuAdministrationAdmin.ranks[staffRank].outfit or nil
end

local function generateStaffOutfit(model)
    local outfit = getCurrentStaffOutfit()
    if not outfit then return end
    if not outfit.peds then
        TriggerEvent("skinchanger:getSkin", function(skin)
            if skin.sex == 0 then
                TriggerEvent("skinchanger:loadClothes", skin, outfit.male or {})
            else
                TriggerEvent("skinchanger:loadClothes", skin, outfit.female or {})
            end
        end)
    else
        local j1 = PlayerId()
        local p1 = GetHashKey(outfit.PedName)
        RequestModel(p1)
        while not HasModelLoaded(p1) do
            Wait(100)
        end
        SetPlayerModel(j1, p1)
        SetModelAsNoLongerNeeded(p1)
    end
end

local function initializeNoclip()
    Citizen.CreateThread(function()
        while NoClip and staffService do
            HideHudComponentThisFrame(19)
            local pCoords = GetEntityCoords(GetPlayerPed(-1), false)
            local camCoords = getCamDirection()
            SetEntityVelocity(GetPlayerPed(-1), 0.01, 0.01, 0.01)
            SetEntityCollision(GetPlayerPed(-1), 0, 1)

            if IsControlPressed(0, 32) then
                pCoords = pCoords + (NoClipSpeed * camCoords)
            end

            if IsControlPressed(0, 269) then
                pCoords = pCoords - (NoClipSpeed * camCoords)
            end

            -- Molette haut : accélérer / molette bas : décélérer.
            -- FiveM: 15/17 = molette haut, 14/16 = molette bas.
            if IsControlJustPressed(0, 15) or IsControlJustPressed(0, 17) then
                NoClipSpeed = math.min(NoClipSpeed + 0.5, 25.0)
            elseif IsControlJustPressed(0, 14) or IsControlJustPressed(0, 16) then
                NoClipSpeed = math.max(NoClipSpeed - 0.5, 0.5)
            end
            SetEntityCoordsNoOffset(GetPlayerPed(-1), pCoords, true, true, true)
            Citizen.Wait(0)
        end
    end)
end

local function initializeInvis()
    Citizen.CreateThread(function()
        while invisible and staffService do
            SetEntityVisible(GetPlayerPed(-1), 0, 0)
            NetworkSetEntityInvisibleToNetwork(GetPlayerPed(-1), 1)
            Citizen.Wait(1)
        end
    end)
end

local function initializeNames()
    Citizen.CreateThread(function()
        local pPed = PlayerPedId()
        while ShowName and staffService do
            local pCoords = GetEntityCoords(GetPlayerPed(-1), false)
            for _, v in pairs(GetActivePlayers()) do
                local otherPed = GetPlayerPed(v)
                if otherPed ~= pPed then
                    if #(pCoords - GetEntityCoords(otherPed, false)) < 250.0 then
                        gamerTags[v] = CreateFakeMpGamerTag(otherPed, ('[%s] %s'):format(GetPlayerServerId(v), GetPlayerName(v)), false, false, '', 0)
                        SetMpGamerTagVisibility(gamerTags[v], 4, 1)
                    else
                        RemoveMpGamerTag(gamerTags[v])
                        gamerTags[v] = nil
                    end
                end
                Citizen.Wait(1)
            end
        end
    end)
end

-- Bandeau du mode administration : barre sombre translucide en haut au milieu (pastilles colorées + séparateurs)
local BAR_TAG_COLORS = {
    ["~r~"] = {224, 62, 62}, ["~g~"] = {92, 214, 120}, ["~b~"] = {88, 170, 240},
    ["~y~"] = {240, 200, 80}, ["~p~"] = {150, 110, 230}, ["~o~"] = {240, 150, 60},
}



-- Résolution (cache) : tout le bandeau est calé sur la grille de pixels pour un rendu net et identique partout
local barRX, barRY = nil, nil
local function BarResolution()
    if not barRX then barRX, barRY = GetActiveScreenResolution() end
    return barRX, barRY
end

-- Rectangle à coins arrondis lissés (pixel de bord à opacité partielle = anti-aliasing simulé)
-- Toutes les valeurs (x, y, w, h, rayon) sont en PIXELS entiers.
local function BarRoundedRect(x, y, w, h, radius, r, g, b, a)
    local RX, RY = BarResolution()
    local function rect(px, py, pw, ph, alpha)
        if pw > 0 and ph > 0 then
            DrawRect((px + pw / 2) / RX, (py + ph / 2) / RY, pw / RX, ph / RY, r, g, b, alpha)
        end
    end

    radius = math.max(0, math.min(radius, math.floor(h / 2), math.floor(w / 2)))
    rect(x, y + radius, w, h - radius * 2, a)

    for i = 0, radius - 1 do
        local dy = radius - (i + 0.5)
        local inset = radius - math.sqrt(radius * radius - dy * dy)
        local full = math.ceil(inset)
        local partial = full - inset
        rect(x + full, y + i, w - full * 2, 1, a)
        rect(x + full, y + h - 1 - i, w - full * 2, 1, a)
        if partial > 0.04 and full >= 1 then
            local alpha = math.floor(a * partial)
            rect(x + full - 1, y + i, 1, 1, alpha)
            rect(x + w - full, y + i, 1, 1, alpha)
            rect(x + full - 1, y + h - 1 - i, 1, 1, alpha)
            rect(x + w - full, y + h - 1 - i, 1, 1, alpha)
        end
    end
end

local function BarBrighten(c, amount)
    return math.min(255, math.floor(c[1] + (255 - c[1]) * amount)),
           math.min(255, math.floor(c[2] + (255 - c[2]) * amount)),
           math.min(255, math.floor(c[3] + (255 - c[3]) * amount))
end

local function BarTextWidthPx(text, scale)
    local RX = BarResolution()
    SetTextFont(4)
    SetTextScale(0.0, scale)
    BeginTextCommandGetWidth("STRING")
    AddTextComponentSubstringPlayerName(text)
    return math.floor(EndTextCommandGetWidth(true) * RX + 0.5)
end

-- (x, y) en pixels : coin haut gauche de la ligne de texte
local function BarDrawTextPx(text, x, y, scale, r, g, b)
    local RX, RY = BarResolution()
    SetTextFont(4)
    SetTextScale(0.0, scale)
    SetTextColour(r, g, b, 255)
    SetTextDropShadow(1, 0, 0, 0, 220)
    SetTextOutline()
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x / RX, y / RY)
end

-- items = { {label = "TEXTE", color = {r,g,b}}, {badge = "15", label = "STAFFS EN LIGNE", color = {r,g,b}}, ... }
-- Style : [pastille colorée + valeur] LIBELLÉ | [pastille] LIBELLÉ | ...
local BAR_TEXT_CENTER = 0.53 -- position verticale du centre des capitales dans la ligne de texte (réglable)
local function DrawTopCenterBar(items)
    local RX, RY = BarResolution()
    local scale = 0.32
    local lineH = math.floor(GetTextScaleHeight(scale, 4) * RY + 0.5)   -- hauteur de la ligne de texte (px)
    local padX, padY, gap, sepGap = 12, 8, 7, 15

    -- Mesure (tout en pixels entiers)
    local total = 0
    for i, item in ipairs(items) do
        item.w = BarTextWidthPx(item.label, scale)
        local width = item.w
        if item.badge then
            item.tw = BarTextWidthPx(item.badge, scale)
            item.bw = item.tw -- plus de carré derrière la valeur : texte coloré seul
            width = width + gap + item.bw
        end
        total = total + width
        if i < #items then total = total + sepGap * 2 + 1 end
    end

    local barH = lineH + padY * 2
    if barH % 2 ~= 0 then barH = barH + 1 end
    local barW = total + padX * 2
    local barX = math.floor(RX / 2 - barW / 2 + 0.5)
    local barY = math.floor(RY * 0.012 + 0.5)
    BarRoundedRect(barX, barY, barW, barH, 6, 38, 38, 40, 150)

    local midY = barY + barH / 2
    local textY = midY - lineH * BAR_TEXT_CENTER     -- même hauteur pour TOUS les textes

    local x = barX + padX
    for i, item in ipairs(items) do
        local c = item.color or {235, 235, 235}
        if item.badge then
            -- valeur colorée (sans fond), puis le libellé
            local tr, tg, tb = BarBrighten(c, 0.25)
            BarDrawTextPx(item.badge, x, textY, scale, tr, tg, tb)
            x = x + item.bw + gap
            BarDrawTextPx(item.label, x, textY, scale, 245, 245, 245)
        else
            BarDrawTextPx(item.label, x, textY, scale, c[1], c[2], c[3])
        end
        x = x + item.w
        if i < #items then
            x = x + sepGap
            local sepH = math.floor(lineH * 0.62 + 0.5)
            if (barH - sepH) % 2 ~= 0 then sepH = sepH + 1 end
            local ar, ag, ab = 240, 240, 240
            DrawRect((x + 0.5) / RX, midY / RY, 1 / RX, sepH / RY, ar, ag, ab, 225)
            x = x + 1 + sepGap
        end
    end
end

local function BarStateColor(state)
    if state then return {92, 214, 120} end
    return {224, 62, 62}
end

-- Statistiques affichées dans le bandeau (envoyées par le serveur)
local barStats = {reports = 0, online = 0, service = 0}
RegisterNetEvent("menuadmin:barStats", function(reports, online, service)
    barStats.reports, barStats.online, barStats.service = reports or 0, online or 0, service or 0
end)

local function initializeText()
    Citizen.CreateThread(function()
        while staffService do 
            Citizen.Wait(1)
            if showStaffHud then
                DrawTopCenterBar({
                    {label = "MODE ADMINISTRATION ACTIF", color = BAR_TAG_COLORS[colorVar] or {235, 235, 235}},
                    {label = "NOCLIP", badge = NoClip and "ON" or "OFF", color = BarStateColor(NoClip)},
                    {label = "INVISIBLE", badge = invisible and "ON" or "OFF", color = BarStateColor(invisible)},
                    {label = "NOMS", badge = ShowName and "ON" or "OFF", color = BarStateColor(ShowName)},
                    {label = "REPORTS", badge = tostring(barStats.reports), color = {232, 72, 88}},
                    {label = "STAFFS EN LIGNE", badge = tostring(barStats.online), color = {60, 140, 255}},
                    {label = "STAFFS EN SERVICE", badge = tostring(barStats.service), color = {60, 140, 255}},
                })
            end
        end
    end)
end

local function initializeThread(rank,license,forcedRank,forcedLabel,forcedColor)
    local mugshot, mugshotStr = ESX.Game.GetPedMugshot(GetPlayerPed(PlayerId()))
	ESX.ShowAdvancedNotification("Administration", ConfigMenuAdmin.Notification["StatsStaff"], ConfigMenuAdmin.Notification["ModeStaffNotif"], mugshotStr, 1)

    if ConfigMenuAdmin.CheckByGroup then
        staffRank = tonumber(forcedRank) or ConfigMenuAdmin.GroupList[rank]
        currentAdminGroupName = rank
        currentAdminGroupLabel = forcedLabel or rank
    else
        staffRank = rank
    end
    colorVar = forcedColor or "~r~"

    for i = 1,100 do 
        table.insert(possiblesQty, tostring(i))
    end

    getItems()
end

ItemIndex = {}
function MenuStaffOpen3()
    local MenuAdminPed = RageUI.CreateMenu("Give Armes", "Interagir avec ce joueur")
    MenuAdminPed.Closed = function()end

    RageUI.Visible(MenuAdminPed, not RageUI.Visible(MenuAdminPed))

    while MenuAdminPed do
        Wait(0)
        RageUI.IsVisible(MenuAdminPed, true, true, true, function()
            menu = true

            for k, v in pairs(ConfigMenuAdmin.MenuConfigMenuAdministration.PedMenu) do
                RageUI.List(v.Title, v, ItemIndex[v] or 1, nil, {}, true, function(Hovered, Active, Selected, Index)
                    if (Selected) then
                        v[Index].OnClick()
                    end
                    ItemIndex[v] = Index;
                end)
            end

            RageUI.Line()

            RageUI.ButtonWithStyle("~g~Revenir à la Normal", "", {RightLabel = ""}, true, function(Hovered, Active, Selected)
                if (Selected) then
                    ESX.TriggerServerCallback("esx_skin:getPlayerSkin", function(skin, jobSkin)
                    local isMale = skin.sex == 0

                        TriggerEvent("skinchanger:loadDefaultModel", isMale, function()
                            ESX.TriggerServerCallback("esx_skin:getPlayerSkin", function(skin)
                                TriggerEvent("skinchanger:loadSkin", skin)
                                TriggerEvent("esx:restoreLoadout")
                            end)
                        end)
                    end)

                    Wait(200)
                    generateStaffOutfit(GetEntityModel(PlayerPedId()))
                end
            end)
        end, function()
        end, 1)

        if not RageUI.Visible(MenuAdminPed) then
            MenuAdminPed = RMenu:DeleteType("MenuAdminPed")
        end
    end
end

function MenuStaffOpen4(id)
    local MenuAdminWeapon = RageUI.CreateMenu("Give Armes", "Interagir avec ce joueur")
    MenuAdminWeapon.Closed = function()end

    RageUI.Visible(MenuAdminWeapon, not RageUI.Visible(MenuAdminWeapon))

    while MenuAdminWeapon do
        Wait(0)

        RageUI.IsVisible(MenuAdminWeapon, true, true, true, function()
            menu = true
            RageUI.Separator("↓ ~b~Catégorie~s~ ↓")
            for k, v in pairs(ConfigMenuAdmin.MenuConfigMenuAdministration.WeaponMenu) do
                RageUI.List(v.Title, v, ItemIndex[v]  or 1, nil, {}, true, function(Hovered, Active, Selected, Index)
                    if (Selected) then
                        v[Index].OnClick()
                    end
                    ItemIndex[v] = Index;
                end)
            end

            RageUI.Separator("↓ ~b~Autres~s~ ↓")
            RageUI.ButtonWithStyle("~r~Supprimer toutes les armes", "~r~Action irréversible~s~", {}, true, function(Hovered, Active, Selected)
                if (Selected) then
                    TriggerServerEvent("CorePickax:RemoveAllWeapon", id, PlayerId())
                end
            end)
        end, function()    
        end, 1)

        if not RageUI.Visible(MenuAdminWeapon) then
            MenuAdminWeapon = RMenu:DeleteType("MenuAdminWeapon")
        end
    end
end

function MenuStaffOpen5()
    local textxte = nil
    local MenuAdminCitoyensRemb = RageUI.CreateMenu("Interactions citoyens", "Interagir avec ce joueur")
    MenuAdminCitoyensRemb.Closed = function()end

    RageUI.Visible(MenuAdminCitoyensRemb, not RageUI.Visible(MenuAdminCitoyensRemb))

    while MenuAdminCitoyensRemb do
        Wait(0)
        
        RageUI.IsVisible(MenuAdminCitoyensRemb,true,true,true,function()
            RageUI.Separator("↓ ~b~Paramètrage ~s~↓")

            RageUI.List("Quantité: ~s~", possiblesQty, qty, nil, {}, true, function(Hovered, Active, Selected, Index)
                qty = Index
            end)
            RageUI.ButtonWithStyle("Effectuer une recherche", nil, {RightLabel = "→→→"}, true, function(_,_,s)
                if s then
                    local amount = ConfigMenuAdministrationAdmin.utils.keyboard("Nom de l'item", "Nom de l'item", 20)
                    textxte = amount
                end
            end)
            RageUI.Separator("↓ ~o~Liste d'items ~s~↓")
            for k,v in pairs(items) do
                if textxte == nil then
                    RageUI.ButtonWithStyle((ConfigMenuAdmin.Notification["AffichageItem"]):format(v.label, v.name), "Appuyez pour give cette item", { RightLabel = "~b~Give ~s~→→" }, true, function(_,a,s)
                        if s then
                            TriggerServerEvent("CorePickax:ActionAdmin", "ActionPlayer", "RembourseItem", selected.s, v.name, qty)
                            ESX.ShowNotification((ConfigMenuAdmin.Notification["GiveItem"]):format(qty, v.label, GetPlayerName(GetPlayerFromServerId(selected.s))))
                        end
                    end)
                else
                    if starts(v.label:lower(), textxte:lower()) or starts(v.name:lower(), textxte:lower()) then
                        RageUI.ButtonWithStyle((ConfigMenuAdmin.Notification["AffichageItem"]):format(v.label, v.name), "Appuyez pour give cette cet item", { RightLabel = "~b~Give ~s~→→" }, true, function(_,a,s)
                            if s then
                                TriggerServerEvent("CorePickax:ActionAdmin", "ActionPlayer", "RembourseItem", selected.s, v.name, qty)
                                ESX.ShowNotification((ConfigMenuAdmin.Notification["GiveItem"]):format(qty, v.label, GetPlayerName(GetPlayerFromServerId(selected.s))))
                            end
                        end)
                    end
                end
            end
        end, function()    
        end, 1)

        if not RageUI.Visible(MenuAdminCitoyensRemb) then
            MenuAdminCitoyensRemb = RMenu:DeleteType("MenuAdminCitoyensRemb")
        end
    end
end

function MenuStaffOpen()
    local textxte2 = nil
    if staffRank == nil then return end
    if playerGroup[MonID()] == nil then
        TriggerServerEvent("CorePickax:getPlayerGroup", PlayerId())
    end

    local actualRankPermissions = {}

    for perm,_ in pairs(ConfigMenuAdministrationAdmin.functions) do
        actualRankPermissions[perm] = false
    end

    for _,perm in pairs(ConfigMenuAdministrationAdmin.ranks[staffRank].permissions) do 
        actualRankPermissions[perm] = true
    end

    TriggerServerEvent("CorePickax:getPermissionConfig")
    for i = 1, #ConfigMenuAdministrationAdmin.functions do
        if tonumber(staffRank) == 4 then
            actualRankPermissions[i] = true
        elseif adminPermissionMatrix[tonumber(staffRank)] and adminPermissionMatrix[tonumber(staffRank)]["func_"..i] ~= nil then
            actualRankPermissions[i] = adminPermissionMatrix[tonumber(staffRank)]["func_"..i] == true
        end
    end

    local MenuAdminPrincipal = RageUI.CreateMenu("Menu d'administration","Rang: "..(currentAdminGroupLabel or ConfigMenuAdministrationAdmin.ranks[staffRank].label))
    MenuAdminPrincipal.Closed = function()
        MenuStaffOpenState = false
    end

    local MenuAdminSelf = RageUI.CreateSubMenu(MenuAdminPrincipal, "Interactions personnelle", "Interactions avec votre joueur")
    MenuAdminSelf.Closed = function()end

    local MenuAdminCitoyens = RageUI.CreateSubMenu(MenuAdminPrincipal, "Interactions citoyens", "Interactions avec un citoyen")
    MenuAdminCitoyens.Closed = function()
        if textxte2 ~= nil then
            textxte2 = nil
        end
    end

    local MenuAdminVehicule = RageUI.CreateSubMenu(MenuAdminPrincipal, "Interactions véhicules", "Interactions avec un véhicule proche")
    MenuAdminVehicule.Closed = function()end

    local MenuAdminCitoyens2 = RageUI.CreateSubMenu(MenuAdminCitoyens, "Interactions citoyens", "Interagir avec ce joueur")
    MenuAdminCitoyens2.Closed = function()end

    local MenuAdminSetJob = RageUI.CreateSubMenu(MenuAdminCitoyens2, "Mettre un métier", "Choisir un métier")
    MenuAdminSetJob.Closed = function()
        selectedAdminJob = nil
    end

    local MenuAdminSetJobGrades = RageUI.CreateSubMenu(MenuAdminSetJob, "Mettre un métier", "Choisir un grade")
    MenuAdminSetJobGrades.Closed = function()end

    local MenuAdminSetJob2 = RageUI.CreateSubMenu(MenuAdminCitoyens2, "Mettre un gang/orga", "Choisir un gang ou une organisation")
    MenuAdminSetJob2.Closed = function()
        selectedAdminJob2 = nil
    end

    local MenuAdminSetJob2Grades = RageUI.CreateSubMenu(MenuAdminSetJob2, "Mettre un gang/orga", "Choisir un grade")
    MenuAdminSetJob2Grades.Closed = function()end

    local MenuAdminSetAdminGrade = RageUI.CreateSubMenu(MenuAdminCitoyens2, "Grade administration", "Attribuer un grade staff")
    MenuAdminSetAdminGrade.Closed = function()end

    local ReportInfoMain = RageUI.CreateSubMenu(MenuAdminPrincipal, "Interactions report", "Que voulez-vous faire ?")
    local ReportInfo =  RageUI.CreateSubMenu(ReportInfoMain, "Interactions report", "Que voulez-vous faire ?")
    
    local MenuAdminPerso = RageUI.CreateSubMenu(MenuAdminSelf, "Interactions personnelle", "Paramètres perso")
    MenuAdminPerso.Closed = function()end

    local menuDev = RageUI.CreateSubMenu(MenuAdminSelf, "Menu développeur", "Que voulez-vous faire ?")
    menuDev.Closed = function()
        if showinterior then
            showinterior = false
        end
    end

    local Menu_interieur = RageUI.CreateSubMenu(menuDev, "Menu Intérieur", "Que voulez vous faire ?")
    local Menu_animation = RageUI.CreateSubMenu(menuDev, "Menu Animation", "Que voulez vous faire ?")
    local Menu_Builder = RageUI.CreateSubMenu(menuDev, "Menu Builder", "Que voulez vous faire ?")
    local Menu_cutscene = RageUI.CreateSubMenu(menuDev, "Menu Cutscene", "Que voulez vous faire ?")

    -- Gestion complète des accès staff (_dev uniquement)
    local MenuPermissionRanks = RageUI.CreateSubMenu(menuDev, "Permissions staff", "Choisir le grade à configurer")
    local MenuPermissionEdit = RageUI.CreateSubMenu(MenuPermissionRanks, "Permissions staff", "Activer / désactiver avec les checkbox")

    -- Gestion des grades admin personnalisés (_dev uniquement)
    local MenuAdminGradeManagement = RageUI.CreateSubMenu(menuDev, "Grades administration", "Créer ou supprimer des grades")
    local MenuAdminGradeCreate = RageUI.CreateSubMenu(MenuAdminGradeManagement, "Créer un grade", "Choisir le niveau de droits hérité")
    local MenuAdminGradeDelete = RageUI.CreateSubMenu(MenuAdminGradeManagement, "Supprimer un grade", "Supprimer un grade admin")
    local MenuAdminGradeColorList = RageUI.CreateSubMenu(MenuAdminGradeManagement, "Couleurs des grades", "Choisir un grade")
    local MenuAdminGradeColorEdit = RageUI.CreateSubMenu(MenuAdminGradeColorList, "Couleur du grade", "Choisir une couleur")

    RageUI.Visible(MenuAdminPrincipal, not RageUI.Visible(MenuAdminPrincipal))

    while MenuAdminPrincipal do
        Wait(0)
        RageUI.IsVisible(MenuAdminPrincipal,true,true,true,function()
            RageUI.Checkbox("Mode administration", nil, staffService, { Style = RageUI.CheckboxStyle.Tick }, function(Hovered, Selected, Active, Checked)
                staffService = Checked;
            end, function()
                staffService = true
                TriggerEvent("CorePickax:Staff:OnEnable")
                ESX.ShowAdvancedNotification("Administration", ConfigMenuAdmin.Notification["StatsStaff"], ConfigMenuAdmin.Notification["ModeStaffNotif1"])
                initializeText()
                generateStaffOutfit(GetEntityModel(PlayerPedId()))
                TriggerServerEvent('takeInfo', true)
            end, function()
                staffService = false
                NoClip = false
                ShowName = false
                invisible = false
                invincible = false
                SetEntityInvincible(PlayerPedId(), false)
                SetPlayerInvincible(PlayerId(), false)
                TriggerEvent("CorePickax:Staff:OnDisable")
                FreezeEntityPosition(GetPlayerPed(-1), false)
                SetEntityCollision(GetPlayerPed(-1), 1, 1)
                SetEntityVisible(GetPlayerPed(-1), 1, 0)
                NetworkSetEntityInvisibleToNetwork(GetPlayerPed(-1), 0)
                for _,v in pairs(GetActivePlayers()) do
                    RemoveMpGamerTag(gamerTags[v])
                end
                ESX.ShowAdvancedNotification("Administration", ConfigMenuAdmin.Notification["StatsStaff"], ConfigMenuAdmin.Notification["ModeStaffNotif2"])
                if not ConfigMenuAdministrationAdmin.ranks[staffRank].outfit.peds then
                    ESX.TriggerServerCallback("esx_skin:getPlayerSkin", function(skin)
                        TriggerEvent("skinchanger:loadSkin", skin)
                        ClearPedProp(playerPed, 0)
                    end)
                else
                    ESX.TriggerServerCallback("esx_skin:getPlayerSkin", function(skin, jobSkin)
                        local isMale = skin.sex == 0
                        TriggerEvent("skinchanger:loadDefaultModel", isMale, function()
                            ESX.TriggerServerCallback("esx_skin:getPlayerSkin", function(skin)
                                TriggerEvent("skinchanger:loadSkin", skin)
                                TriggerEvent("esx:restoreLoadout")
                            end)
                        end)
                    end)
                end

                if NoClipF2 then
                    DisableNoclip(noclipEntity)
                    NoClipF2 = false
                end
                TriggerServerEvent('takeInfo', false)
            end)

            if staffService then
                RageUI.Separator(colorVar.."/!\\ Mode administration actif /!\\")
                RageUI.ButtonWithStyle("Interactions personnelle", "Intéragir avec votre personnage", { RightLabel = "→→" }, hasAdminPermission("section_self"), function()
                end, MenuAdminSelf)
                RageUI.ButtonWithStyle("Interactions joueurs", "Intéragir avec les joueurs du serveur", { RightLabel = "→→" }, hasAdminPermission("section_players"), function()
                end, MenuAdminCitoyens)
                RageUI.ButtonWithStyle("Interactions report", "Intéragir avec les report du serveur", { RightLabel = "→→" }, hasAdminPermission("section_reports"), function(_,a,Selected)
                    if Selected then
                        getInfoReport()
                    end
                end, ReportInfoMain)
                RageUI.ButtonWithStyle("Interactions véhicules", "Intéragir avec les véhicules du serveur", { RightLabel = "→→" }, hasAdminPermission("section_vehicle"), function()
                end, MenuAdminVehicule)

            end
        end, function()    
        end, 1)

        RageUI.IsVisible(MenuAdminCitoyens, true,true,true,function()
            menu = true
            RageUI.List("Trier par :", {"Tous les joueurs", "Staffs", "Joueur", "Zone"}, ESXCustomListButon.PlayerList, nil, {}, true, function(Hovered, Active, Selected, Index)
                ESXCustomListButon.PlayerList = Index;
            end)

            RageUI.ButtonWithStyle("Effectuer une recherche", "~b~Faites une recherche par un nom où un ID~s~", {RightLabel = "→→→"}, true, function(_,_,s)
                if s then
                    local amount = ConfigMenuAdministrationAdmin.utils.keyboard("Nom du joueur où ID", "Nom du joueur où ID", 20)
                    textxte2 = amount
                end
            end)

            RageUI.Line()
            
            if localPlayers ~= nil then
                if ESXCustomListButon.PlayerList == 1 then
                    for k, v in pairs(localPlayers) do
                        if textxte2 == nil then
                            if v.group ~= "user" then
                                RageUI.ButtonWithStyle("["..v.id.."] "..v.name.." ~s~[~s~"..ConfigMenuAdministrationAdmin.ranks[ConfigMenuAdmin.GroupList[v.group]].label.."~s~]~s~", "Intéragir avec ce joueur", { RightLabel = "~b~Intéragir ~s~→→" }, true, function(_,a,s)
                                    if s then
                                        selected = {s = v.id, name = v.name, id = v.id, group = ConfigMenuAdministrationAdmin.ranks[ConfigMenuAdmin.GroupList[v.group]].label}
                                        if playerInformationReceived[v.id] == nil then
                                            TriggerServerEvent("CorePickax:playerInformationReceived", v.id)
                                        end
                                    end
                                end, MenuAdminCitoyens2)
                            else
                                RageUI.ButtonWithStyle("["..v.id.."] "..v.name.." ~s~[~s~"..ConfigMenuAdmin.LabelGroupUser.."~s~]~s~", "Intéragir avec ce joueur", { RightLabel = "~b~Intéragir ~s~→→" }, true, function(_,a,s)
                                    if s then
                                        selected = {s = v.id, name = v.name, id = v.id, group = ConfigMenuAdmin.LabelGroupUser}
                                        if playerInformationReceived[v.id] == nil then
                                            TriggerServerEvent("CorePickax:playerInformationReceived", v.id)
                                        end
                                    end
                                end, MenuAdminCitoyens2)
                            end
                        else
                            if v.group ~= "user" then
                                if starts(v.name:lower(), textxte2:lower()) or starts(v.id, textxte2:lower()) then
                                    RageUI.ButtonWithStyle("["..v.id.."] "..v.name.." ~s~[~s~"..ConfigMenuAdministrationAdmin.ranks[ConfigMenuAdmin.GroupList[v.group]].label.."~s~]~s~", "Intéragir avec ce joueur", { RightLabel = "~b~Intéragir ~s~→→" }, true, function(_,a,s)
                                        if s then
                                            selected = {s = v.id, name = v.name, id = v.id, group = ConfigMenuAdministrationAdmin.ranks[ConfigMenuAdmin.GroupList[v.group]].label}
                                            if playerInformationReceived[v.id] == nil then
                                                TriggerServerEvent("CorePickax:playerInformationReceived", v.id)
                                            end
                                        end
                                    end, MenuAdminCitoyens2)
                                end
                            else
                                if starts(v.name:lower(), textxte2:lower()) or starts(v.id, textxte2:lower()) then
                                    RageUI.ButtonWithStyle("["..v.id.."] "..v.name.." ~s~[~s~"..ConfigMenuAdmin.LabelGroupUser.."~s~]~s~", "Intéragir avec ce joueur", { RightLabel = "~b~Intéragir ~s~→→" }, true, function(_,a,s)
                                        if s then
                                            selected = {s = v.id, name = v.name, id = v.id, group = ConfigMenuAdmin.LabelGroupUser}
                                            if playerInformationReceived[v.id] == nil then
                                                TriggerServerEvent("CorePickax:playerInformationReceived", v.id)
                                            end
                                        end
                                    end, MenuAdminCitoyens2)
                                end
                            end
                        end
                    end
                elseif ESXCustomListButon.PlayerList == 2 then
                    for k,v in pairs(localPlayers) do
                        if textxte2 == nil then
                            if v.group ~= "user" then
                                RageUI.ButtonWithStyle("["..v.id.."] "..v.name.." ~s~[~s~"..ConfigMenuAdministrationAdmin.ranks[ConfigMenuAdmin.GroupList[v.group]].label.."~s~]~s~", "Intéragir avec ce joueur", { RightLabel = "~b~Intéragir ~s~→→" }, true, function(_,a,s)
                                    if s then
                                        selected = {s = v.id, name = v.name, id = v.id, group = ConfigMenuAdministrationAdmin.ranks[ConfigMenuAdmin.GroupList[v.group]].label}
                                        if playerInformationReceived[v.id] == nil then
                                            TriggerServerEvent("CorePickax:playerInformationReceived", v.id)
                                        end
                                    end
                                end, MenuAdminCitoyens2)
                            end
                        else
                            if v.group ~= "user" then
                                if starts(v.name:lower(), textxte2:lower()) or starts(v.id, textxte2:lower()) then
                                    RageUI.ButtonWithStyle("["..v.id.."] "..v.name.." ~s~[~s~"..ConfigMenuAdministrationAdmin.ranks[ConfigMenuAdmin.GroupList[v.group]].label.."~s~]~s~", "Intéragir avec ce joueur", { RightLabel = "~b~Intéragir ~s~→→" }, true, function(_,a,s)
                                        if s then
                                            selected = {s = v.id, name = v.name, id = v.id, group = ConfigMenuAdministrationAdmin.ranks[ConfigMenuAdmin.GroupList[v.group]].label}
                                            if playerInformationReceived[v.id] == nil then
                                                TriggerServerEvent("CorePickax:playerInformationReceived", v.id)
                                            end
                                        end
                                    end, MenuAdminCitoyens2)
                                end
                            end
                        end
                    end
                elseif ESXCustomListButon.PlayerList == 3 then
                    for k,v in pairs(localPlayers) do 
                        if textxte2 == nil then
                            if ConfigMenuAdmin.GroupList[v.group] == nil then
                                if v.group == "user" then
                                    RageUI.ButtonWithStyle("["..v.id.."] "..v.name.." ~s~[~s~"..ConfigMenuAdmin.LabelGroupUser.."~s~]~s~", "Intéragir avec ce joueur", { RightLabel = "~b~Intéragir ~s~→→" }, true, function(_,a,s)
                                        if s then
                                            selected = {s = v.id, name = v.name, id = v.id, group = ConfigMenuAdmin.LabelGroupUser}
                                            if playerInformationReceived[v.id] == nil then
                                                TriggerServerEvent("CorePickax:playerInformationReceived", v.id)
                                            end
                                        end
                                    end, MenuAdminCitoyens2)
                                end
                            else
                                if ConfigMenuAdministrationAdmin.ranks[ConfigMenuAdmin.GroupList[v.group]].label == nil or v.group == "user" then
                                    RageUI.ButtonWithStyle("["..v.id.."] "..v.name.." ~s~[~s~"..ConfigMenuAdministrationAdmin.ranks[ConfigMenuAdmin.GroupList[v.group]].label.."~s~]~s~", "Intéragir avec ce joueur", { RightLabel = "~b~Intéragir ~s~→→" }, true, function(_,a,s)
                                        if s then
                                            selected = {s = v.id, name = v.name, id = v.id, group = ConfigMenuAdministrationAdmin.ranks[ConfigMenuAdmin.GroupList[v.group]].label}
                                            if playerInformationReceived[v.id] == nil then
                                                TriggerServerEvent("CorePickax:playerInformationReceived", v.id)
                                            end
                                        end
                                    end, MenuAdminCitoyens2)
                                end
                            end
                        else
                            if ConfigMenuAdmin.GroupList[v.group] == nil then
                                if v.group == "user" then
                                    if starts(v.name:lower(), textxte2:lower()) or starts(v.id, textxte2:lower()) then
                                        RageUI.ButtonWithStyle("["..v.id.."] "..v.name.." ~s~[~s~"..ConfigMenuAdmin.LabelGroupUser.."~s~]~s~", "Intéragir avec ce joueur", { RightLabel = "~b~Intéragir ~s~→→" }, true, function(_,a,s)
                                            if s then
                                                selected = {s = v.id, name = v.name, id = v.id, group = ConfigMenuAdmin.LabelGroupUser}
                                                if playerInformationReceived[v.id] == nil then
                                                    TriggerServerEvent("CorePickax:playerInformationReceived", v.id)
                                                end
                                            end
                                        end, MenuAdminCitoyens2)
                                    end
                                end
                            else
                                if ConfigMenuAdministrationAdmin.ranks[ConfigMenuAdmin.GroupList[v.group]].label == nil or v.group == "user" then
                                    if starts(v.name:lower(), textxte2:lower()) or starts(v.id, textxte2:lower()) then
                                        RageUI.ButtonWithStyle("["..v.id.."] "..v.name.." ~s~[~s~"..ConfigMenuAdministrationAdmin.ranks[ConfigMenuAdmin.GroupList[v.group]].label.."~s~]~s~", "Intéragir avec ce joueur", { RightLabel = "~b~Intéragir ~s~→→" }, true, function(_,a,s)
                                            if s then
                                                selected = {s = v.id, name = v.name, id = v.id, group = ConfigMenuAdministrationAdmin.ranks[ConfigMenuAdmin.GroupList[v.group]].label}
                                                if playerInformationReceived[v.id] == nil then
                                                    TriggerServerEvent("CorePickax:playerInformationReceived", v.id)
                                                end
                                            end
                                        end, MenuAdminCitoyens2)
                                    end
                                end
                            end
                        end
                    end
                elseif ESXCustomListButon.PlayerList == 4 then
                    for k,v in pairs(GetActivePlayers()) do
                        if textxte2 == nil then
                            if ConfigMenuAdministrationAdmin.ranks[ConfigMenuAdmin.GroupList[localPlayers[GetPlayerServerId(v)].group]] ~= nil then
                                RageUI.ButtonWithStyle("["..GetPlayerServerId(v).."] "..GetPlayerName(v).." ~s~[~s~"..ConfigMenuAdministrationAdmin.ranks[ConfigMenuAdmin.GroupList[localPlayers[GetPlayerServerId(v)].group]].label.."~s~]~s~", "Intéragir avec ce joueur", { RightLabel = "~b~Intéragir ~s~→→" }, true, function(_,a,s)
                                    if s then
                                        selected = {s = GetPlayerServerId(v), name = GetPlayerName(v), id = GetPlayerServerId(v), group = ConfigMenuAdministrationAdmin.ranks[ConfigMenuAdmin.GroupList[localPlayers[GetPlayerServerId(v)].group]].label}
                                        if playerInformationReceived[GetPlayerServerId(v)] == nil then
                                            TriggerServerEvent("CorePickax:playerInformationReceived", GetPlayerServerId(v))
                                        end
                                    end
                                end, MenuAdminCitoyens2)
                            else
                                RageUI.ButtonWithStyle("["..GetPlayerServerId(v).."] "..GetPlayerName(v).." ~s~[~s~"..ConfigMenuAdmin.LabelGroupUser.."~s~]~s~", "Intéragir avec ce joueur", { RightLabel = "~b~Intéragir ~s~→→" }, true, function(_,a,s)
                                    if s then
                                        selected = {s = GetPlayerServerId(v), name = GetPlayerName(v), id = GetPlayerServerId(v), group = ConfigMenuAdmin.LabelGroupUser}
                                        if playerInformationReceived[GetPlayerServerId(v)] == nil then
                                            TriggerServerEvent("CorePickax:playerInformationReceived", GetPlayerServerId(v))
                                        end
                                    end
                                end, MenuAdminCitoyens2)
                            end
                        else
                            if starts(GetPlayerName(v):lower(), textxte2:lower()) or starts(GetPlayerServerId(v), textxte2:lower()) then
                                if ConfigMenuAdministrationAdmin.ranks[ConfigMenuAdmin.GroupList[localPlayers[GetPlayerServerId(v)].group]] ~= nil then
                                    RageUI.ButtonWithStyle("["..GetPlayerServerId(v).."] "..GetPlayerName(v).." ~s~[~s~"..ConfigMenuAdministrationAdmin.ranks[ConfigMenuAdmin.GroupList[localPlayers[GetPlayerServerId(v)].group]].label.."~s~]~s~", "Intéragir avec ce joueur", { RightLabel = "~b~Intéragir ~s~→→" }, true, function(_,a,s)
                                        if s then
                                            selected = {s = GetPlayerServerId(v), name = GetPlayerName(v), id = GetPlayerServerId(v), group = ConfigMenuAdministrationAdmin.ranks[ConfigMenuAdmin.GroupList[localPlayers[GetPlayerServerId(v)].group]].label}
                                            if playerInformationReceived[GetPlayerServerId(v)] == nil then
                                                TriggerServerEvent("CorePickax:playerInformationReceived", GetPlayerServerId(v))
                                            end
                                        end
                                    end, MenuAdminCitoyens2)
                                else
                                    RageUI.ButtonWithStyle("["..GetPlayerServerId(v).."] "..GetPlayerName(v).." ~s~[~s~"..ConfigMenuAdmin.LabelGroupUser.."~s~]~s~", "Intéragir avec ce joueur", { RightLabel = "~b~Intéragir ~s~→→" }, true, function(_,a,s)
                                        if s then
                                            selected = {s = GetPlayerServerId(v), name = GetPlayerName(v), id = GetPlayerServerId(v), group = ConfigMenuAdmin.LabelGroupUser}
                                            if playerInformationReceived[GetPlayerServerId(v)] == nil then
                                                TriggerServerEvent("CorePickax:playerInformationReceived", GetPlayerServerId(v))
                                            end
                                        end
                                    end, MenuAdminCitoyens2)
                                end
                            end
                        end
                    end
                end
            else
                RageUI.Separator("")
                RageUI.Separator("~r~Aucune personne trouver.~s~")
                RageUI.Separator("")
            end
        end, function()    
        end, 1)

        RageUI.IsVisible(MenuAdminCitoyens2,true,true,true,function()
            menu = true 
            if ConfigMenuAdmin.MenuInformation then
                RageUI.Separator("↓ ~m~Informations ~s~↓")
                RageUI.ButtonWithStyle("ID", nil, {RightLabel = selected.s}, true, function(_,a,s)
                end)
                RageUI.ButtonWithStyle("Nom", nil, {RightLabel = selected.name}, true, function(_,a,s)
                end)
                RageUI.ButtonWithStyle("Permission", nil, {RightLabel = selected.group or "user"}, true, function(_,a,s)
                end)
                RageUI.ButtonWithStyle("Discord", nil, {RightLabel = playerInformationReceived[selected.s] or "~r~Introuvable.~s~"}, true, function(_,a,s)
                    if s then SendNUIMessage({tool = playerInformationReceived[selected.s]}) end
                end)
                RageUI.ButtonWithStyle("Prendre un screen", nil, {RightLabel = "~b~Éxecuter ~s~→→"}, CooldownScreen == false and hasAdminPermission("take_screen"), function(_,a,s)
                    if s then
                        TriggerEvent("CorePickax:StartCooldownScreen")
                        TriggerServerEvent("CorePickax:TakeScreen", selected.s)
                    end
                end)
            end

            if tonumber(staffRank) == 4 then
                RageUI.Separator("↓ ~p~Administration ~s~↓")
                RageUI.ButtonWithStyle("Attribuer un grade admin", "Réservé au rôle _dev. Permet aussi de remettre le joueur en user.", { RightLabel = "~p~Gérer ~s~→→" }, true, function(_,_,pressed)
                    if pressed then
                        TriggerServerEvent("CorePickax:getAdminGrades")
                    end
                end, MenuAdminSetAdminGrade)
            end

            RageUI.Separator("↓ ~b~Métier ~s~↓")
            RageUI.ButtonWithStyle("Mettre un métier", "Choisir un métier et un grade chargés depuis la base SQL", { RightLabel = "~s~→→" }, hasAdminPermission("setjob"), function(_, _, s)
                if s then
                    adminJobs = {}
                    selectedAdminJob = nil
                    TriggerServerEvent("CorePickax:getJobs")
                end
            end, MenuAdminSetJob)

            RageUI.ButtonWithStyle("Mettre un gang/orga", "Choisir un gang/orga et un grade chargés depuis la base SQL", { RightLabel = "~s~→→" }, hasAdminPermission("setjob2"), function(_, _, s)
                if s then
                    adminJobs2 = {}
                    selectedAdminJob2 = nil
                    TriggerServerEvent("CorePickax:getJobs2")
                end
            end, MenuAdminSetJob2)

            for i = 1,#ConfigMenuAdministrationAdmin.functions do
                if ConfigMenuAdministrationAdmin.functions[i].cat == "player" then
                    if ConfigMenuAdministrationAdmin.functions[i].sep ~= nil then RageUI.Separator(ConfigMenuAdministrationAdmin.functions[i].sep) end
                    RageUI.ButtonWithStyle(ConfigMenuAdministrationAdmin.functions[i].label, "Appuyez pour faire cette action", isSubMenu[ConfigMenuAdministrationAdmin.functions[i].toSub], hasAdminPermission("func_"..i), function(_,a,s)
                        if s then
                            ConfigMenuAdministrationAdmin.functions[i].press(selected)
                        end
                    end)
                end
            end
        end, function()    
        end, 1)

        RageUI.IsVisible(MenuAdminSetAdminGrade, true, true, true, function()
            menu = true

            if tonumber(staffRank) ~= 4 then
                RageUI.Separator("~r~Accès réservé au rôle _dev~s~")
            else
                RageUI.Separator("Joueur : ~b~"..tostring(selected.name or selected.s).."~s~ ["..tostring(selected.s).."]")
                if #adminGradeList == 0 then
                    RageUI.Separator("~o~Chargement des grades...~s~")
                    TriggerServerEvent("CorePickax:getAdminGrades")
                end

                for _, adminGrade in ipairs(adminGradeList) do
                    local color = adminGrade.color or "~s~"
                    RageUI.ButtonWithStyle(color..adminGrade.label.."~s~", "Grade ESX : "..adminGrade.name..(adminGrade.custom and " | ~p~Personnalisé~s~" or ""), {RightLabel = "→→"}, true, function(_, _, pressed)
                        if pressed then
                            TriggerServerEvent("CorePickax:setAdminGrade", selected.s, adminGrade.name)
                        end
                    end)
                end
            end
        end, function() end, 1)

        RageUI.IsVisible(MenuAdminSetJob, true, true, true, function()
            menu = true

            if #adminJobs == 0 then
                RageUI.Separator("~o~Chargement des métiers...~s~")
            else
                for _, job in ipairs(adminJobs) do
                    local gradeCount = job.grades and #job.grades or 0
                    RageUI.ButtonWithStyle(job.label or job.name, "Nom SQL : "..job.name, { RightLabel = "~b~"..gradeCount.." grade(s) ~s~→→" }, gradeCount > 0, function(_, _, s)
                        if s then
                            selectedAdminJob = job
                        end
                    end, MenuAdminSetJobGrades)
                end
            end
        end, function()
        end, 1)

        RageUI.IsVisible(MenuAdminSetJobGrades, true, true, true, function()
            menu = true

            if selectedAdminJob == nil then
                RageUI.Separator("~r~Aucun métier sélectionné.~s~")
            else
                RageUI.Separator("Métier : ~b~"..(selectedAdminJob.label or selectedAdminJob.name).."~s~")

                for _, grade in ipairs(selectedAdminJob.grades or {}) do
                    local gradeLabel = grade.label or grade.name or ("Grade "..tostring(grade.grade))
                    RageUI.ButtonWithStyle(gradeLabel, "Grade SQL : "..tostring(grade.grade), { RightLabel = "~b~"..tostring(grade.grade).."~s~" }, true, function(_, _, s)
                        if s then
                            TriggerServerEvent("CorePickax:setJob", selected.s, selectedAdminJob.name, tonumber(grade.grade))
                        end
                    end)
                end
            end
        end, function()
        end, 1)


        RageUI.IsVisible(MenuAdminSetJob2, true, true, true, function()
            menu = true

            if #adminJobs2 == 0 then
                RageUI.Separator("~o~Chargement des métiers secondaires...~s~")
            else
                for _, job in ipairs(adminJobs2) do
                    local gradeCount = job.grades and #job.grades or 0
                    RageUI.ButtonWithStyle(job.label or job.name, "Nom SQL : "..job.name, { RightLabel = "~b~"..gradeCount.." grade(s) ~s~→→" }, gradeCount > 0, function(_, _, s)
                        if s then
                            selectedAdminJob2 = job
                        end
                    end, MenuAdminSetJob2Grades)
                end
            end
        end, function()
        end, 1)

        RageUI.IsVisible(MenuAdminSetJob2Grades, true, true, true, function()
            menu = true

            if selectedAdminJob2 == nil then
                RageUI.Separator("~r~Aucun métier secondaire sélectionné.~s~")
            else
                RageUI.Separator("Métier secondaire : ~b~"..(selectedAdminJob2.label or selectedAdminJob2.name).."~s~")

                for _, grade in ipairs(selectedAdminJob2.grades or {}) do
                    local gradeLabel = grade.label or grade.name or ("Grade "..tostring(grade.grade))
                    RageUI.ButtonWithStyle(gradeLabel, "Grade SQL : "..tostring(grade.grade), { RightLabel = "~b~"..tostring(grade.grade).."~s~" }, true, function(_, _, s)
                        if s then
                            TriggerServerEvent("CorePickax:setJob2", selected.s, selectedAdminJob2.name, tonumber(grade.grade))
                        end
                    end)
                end
            end
        end, function()
        end, 1)

        RageUI.IsVisible(MenuAdminSelf,true,true,true,function()
            menu = true
            for i = 1,#ConfigMenuAdministrationAdmin.functions do
                if ConfigMenuAdministrationAdmin.functions[i].cat == "self" then
                    if ConfigMenuAdministrationAdmin.functions[i].sep ~= nil then RageUI.Separator(ConfigMenuAdministrationAdmin.functions[i].sep) end
                    if ConfigMenuAdministrationAdmin.functions[i].MenuParamettre then
                        RageUI.ButtonWithStyle(ConfigMenuAdministrationAdmin.functions[i].label, "Appuyez pour faire cette action", isSubMenu[ConfigMenuAdministrationAdmin.functions[i].toSub], hasAdminPermission("func_"..i), function(_,a,s)
                            if s then
                                ConfigMenuAdministrationAdmin.functions[i].press()
                            end
                        end, MenuAdminPerso)
                    else
                        RageUI.ButtonWithStyle(ConfigMenuAdministrationAdmin.functions[i].label, "Appuyez pour faire cette action", isSubMenu[ConfigMenuAdministrationAdmin.functions[i].toSub], hasAdminPermission("func_"..i), function(_,a,s)
                            if s then
                                ConfigMenuAdministrationAdmin.functions[i].press()
                            end
                        end)
                    end
                end
            end
            RageUI.Line()

            if ConfigMenuAdministrationAdmin.ranks[staffRank].Developpeur ~= nil then
                RageUI.ButtonWithStyle("Menu développeur", "Appuyez pour faire cette action", {RightLabel = "→→→"}, ConfigMenuAdministrationAdmin.ranks[staffRank].Developpeur == true, function(_,a,s)
                end, menuDev)
            else
                RageUI.ButtonWithStyle("Menu développeur", "Appuyez pour faire cette action", {RightLabel = "→→→"}, false, function(_,a,s)
                end)
            end
        end, function()    
        end, 1)

        RageUI.IsVisible(menuDev, true, true, true,function()
            menu = true

            if tonumber(staffRank) == 4 then
                RageUI.ButtonWithStyle("Gérer les permissions staff", "Choisir précisément ce que Modérateur / Admin / Superadmin peuvent utiliser", {RightLabel = "~p~Configurer ~s~→→"}, true, function(_,_,s)
                    if s then
                        TriggerServerEvent("CorePickax:getPermissionConfig")
                    end
                end, MenuPermissionRanks)
                RageUI.ButtonWithStyle("Gérer les grades admin", "Créer ou supprimer des grades personnalisés", {RightLabel = "~p~Configurer ~s~→→"}, true, function(_,_,pressed)
                    if pressed then TriggerServerEvent("CorePickax:getAdminGrades") end
                end, MenuAdminGradeManagement)
                RageUI.Line()
            end

            RageUI.ButtonWithStyle("Afficher info interieur", false, {RightLabel = "→→→"}, true, function(_,a,s)
                if s then
                    Showinterior()
                end
            end)
            RageUI.Line()
            RageUI.List("Coordonnées", ConfigMenuAdmin.CoordsList, ConfigMenuAdmin.CoordsList.Index , nil, {}, true, function(Hovered, Active, Selected, Index)
                ConfigMenuAdmin.CoordsList.Index = Index

                if Selected then
                    if Index == 1 then
                        SendNUIMessage({
                            tool = ""..GetEntityCoords(PlayerPedId())
                        })
                    elseif Index == 2 then
                        SendNUIMessage({
                            tool = ""..GetEntityCoords(PlayerPedId()).x..", "..GetEntityCoords(PlayerPedId()).y..", "..GetEntityCoords(PlayerPedId()).z
                        })
                    elseif Index == 3 then
                        SendNUIMessage({
                            tool = ""..GetEntityCoords(PlayerPedId()).x..", "..GetEntityCoords(PlayerPedId()).y..", "..GetEntityCoords(PlayerPedId()).z..", "..GetEntityHeading(PlayerPedId())
                        })
                    elseif Index == 4 then
                        SendNUIMessage({
                            tool = "{x = "..GetEntityCoords(PlayerPedId()).x..", y = "..GetEntityCoords(PlayerPedId()).y..", z = "..GetEntityCoords(PlayerPedId()).z.."}"
                        })
                    elseif Index == 5 then
                        SendNUIMessage({
                            tool = "{x = "..GetEntityCoords(PlayerPedId()).x..", y = "..GetEntityCoords(PlayerPedId()).y..", z = "..GetEntityCoords(PlayerPedId()).z..", a = "..GetEntityHeading(PlayerPedId()).."}"
                        })
                    end
                end
            end)
            RageUI.ButtonWithStyle("Heading", false, {RightLabel = "→→→"}, true, function(_,_,s)
                if s then
                    SendNUIMessage({
                        tool = GetEntityHeading(PlayerPedId())
                    })
                end
            end)
            RageUI.Line()
            RageUI.ButtonWithStyle("List des interieurs", nil, {RightLabel = "→→→"}, true, function(_,a,s)
            end, Menu_interieur)
            RageUI.ButtonWithStyle("List des cutscenes", nil, {RightLabel = "→→→"}, true, function(_,a,s)
            end, Menu_cutscene)
            RageUI.ButtonWithStyle("List des animations", nil, {RightLabel = "→→→"}, true, function(_,a,s)
            end, Menu_animation)
            RageUI.ButtonWithStyle("List des builder", nil, {RightLabel = "→→→"}, true, function(_,a,s)
            end, Menu_Builder)
        end, function()
        end, 1)

        RageUI.IsVisible(Menu_Builder,true,true,true, function()
            RageUI.ButtonWithStyle("MecanoBuilder", "Si un menu ne s'ouvre pas, n'oublier pas que vous devez vous WL dans le config du script.", {RightLabel = "→→"}, true, function(_,a,s)
                if s then
                    ExecuteCommand(ConfigMecanoBuilder.Commande.CommandeCreate)
                end
            end)
            RageUI.ButtonWithStyle("BarBuilder", "Si un menu ne s'ouvre pas, n'oublier pas que vous devez vous WL dans le config du script.", {RightLabel = "→→"}, true, function(_,a,s)
                if s then
                    ExecuteCommand(ConfigBarBuilder.Commande.CommandOpenBar)
                end
            end)
            RageUI.ButtonWithStyle("DoorBuilders", "Si un menu ne s'ouvre pas, n'oublier pas que vous devez vous WL dans le config du script.", {RightLabel = "→→"}, true, function(_,a,s)
                if s then
                    ExecuteCommand("createdoor")
                end
            end)
            RageUI.ButtonWithStyle("DrugsBuilder", "Si un menu ne s'ouvre pas, n'oublier pas que vous devez vous WL dans le config du script.", {RightLabel = "→→"}, true, function(_,a,s)
                if s then
                    ExecuteCommand("drugsbuilder")
                end
            end)
            RageUI.ButtonWithStyle("GangsBuilder", "Si un menu ne s'ouvre pas, n'oublier pas que vous devez vous WL dans le config du script.", {RightLabel = "→→"}, true, function(_,a,s)
                if s then
                    ExecuteCommand(ConfigGangsBuilder.Commande.gangsbuilder)
                end
            end)
            RageUI.ButtonWithStyle("GarageBuilder", "Si un menu ne s'ouvre pas, n'oublier pas que vous devez vous WL dans le config du script.", {RightLabel = "→→"}, true, function(_,a,s)
                if s then
                    ExecuteCommand(ConfigGarage.CommandName)
                end
            end)
            RageUI.ButtonWithStyle("FourrièreBuilder", "Si un menu ne s'ouvre pas, n'oublier pas que vous devez vous WL dans le config du script.", {RightLabel = "→→"}, true, function(_,a,s)
                if s then
                    ExecuteCommand(ConfigFourriere.CommandName)
                end
            end)
            RageUI.Line()
            RageUI.ButtonWithStyle("Gestion MecanoBuilder", "Si un menu ne s'ouvre pas, n'oublier pas que vous devez vous WL dans le config du script.", {RightLabel = "→→"}, true, function(_,a,s)
                if s then
                    ExecuteCommand(ConfigMecanoBuilder.Commande.CommandeGestion)
                end
            end)
            RageUI.ButtonWithStyle("Gestion GangsBuilder", "Si un menu ne s'ouvre pas, n'oublier pas que vous devez vous WL dans le config du script.", {RightLabel = "→→"}, true, function(_,a,s)
                if s then
                    ExecuteCommand(ConfigGangsBuilder.Commande.gestiongangs)
                end
            end)
        end)

        RageUI.IsVisible(Menu_cutscene,true,true,true, function()
            for k,v in pairs(ConfigMenuAdminDev.Cutscenelist) do 
                RageUI.ButtonWithStyle(v, nil, {RightLabel = "→→"}, true, function(_,a,s)
                    if s then
                        PlayCutscene(v)
                    end
                end)
            end
        end)
        RageUI.IsVisible(Menu_animation,true,true,true, function()
            for k,v in pairs(ConfigMenuAdminDev.Animationlist) do 
                RageUI.ButtonWithStyle(v[2], v[1], {RightLabel = "→→"}, true, function(_,a,s)
                    if s then
                        TaskAnimESXCustom(PlayerPedId(), v[1], v[2])
                    end
                end)
            end
        end)
        RageUI.IsVisible(Menu_interieur,true,true,true, function()
            for k,v in pairs(ConfigMenuAdminDev.InteriorsList) do 
                RageUI.ButtonWithStyle(v.Name, nil, {RightLabel = "→→"}, true, function(_,a,s)
                    if s then
                        ESX.Game.Teleport(PlayerPedId(), v.value)
                    end
                end)
            end
        end)

        RageUI.IsVisible(MenuAdminGradeManagement, true, true, true, function()
            menu = true
            if tonumber(staffRank) ~= 4 then
                RageUI.Separator("~r~Accès réservé au rôle _dev~s~")
                return
            end

            RageUI.ButtonWithStyle("Créer un nouveau grade", "Saisir le nom interne et le label, puis choisir son niveau de droits", {RightLabel = "~g~Créer ~s~→→"}, true, function(_,_,pressed)
                if pressed then
                    local name = ConfigMenuAdministrationAdmin.utils.keyboard("Nom interne", "Ex: helper", 24)
                    if name and name ~= "" then
                        local label = ConfigMenuAdministrationAdmin.utils.keyboard("Nom affiché", "Ex: Helper", 32)
                        if label and label ~= "" then
                            pendingCustomGrade = {name = string.lower(name), label = label}
                        end
                    end
                end
            end, MenuAdminGradeCreate)

            RageUI.ButtonWithStyle("Couleur des grades", "Attribuer ou modifier la couleur de chaque grade", {RightLabel = "~p~Configurer ~s~→→"}, true, function(_,_,pressed)
                if pressed then TriggerServerEvent("CorePickax:getAdminGrades") end
            end, MenuAdminGradeColorList)

            RageUI.ButtonWithStyle("Supprimer un grade", "Supprime n’importe quel grade admin sauf _dev", {RightLabel = "~r~Supprimer ~s~→→"}, true, function(_,_,pressed)
                if pressed then TriggerServerEvent("CorePickax:getAdminGrades") end
            end, MenuAdminGradeDelete)
        end, function() end, 1)

        RageUI.IsVisible(MenuAdminGradeCreate, true, true, true, function()
            menu = true
            if tonumber(staffRank) ~= 4 then return end
            if not pendingCustomGrade then
                RageUI.Separator("~o~Reviens en arrière et saisis le nouveau grade.~s~")
                return
            end
            RageUI.Separator("Nom : ~b~"..pendingCustomGrade.name.."~s~")
            RageUI.Separator("Label : ~b~"..pendingCustomGrade.label.."~s~")
            RageUI.Separator("↓ ~p~Niveau de droits hérité ~s~↓")
            local bases = {
                {rank=1,label="Modérateur"},
                {rank=2,label="Admin"},
                {rank=3,label="Superadmin"}
            }
            for _,base in ipairs(bases) do
                RageUI.ButtonWithStyle(base.label, "Le nouveau grade utilisera les permissions de ce niveau", {RightLabel="~g~Créer ~s~→→"}, true, function(_,_,pressed)
                    if pressed then
                        TriggerServerEvent("CorePickax:createAdminGrade", pendingCustomGrade.name, pendingCustomGrade.label, base.rank)
                        pendingCustomGrade = nil
                        RageUI.GoBack()
                    end
                end)
            end
        end, function() end, 1)

        RageUI.IsVisible(MenuAdminGradeColorList, true, true, true, function()
            menu = true
            if tonumber(staffRank) ~= 4 then return end
            for _,grade in ipairs(adminGradeList) do
                if grade.name ~= "user" then
                    RageUI.ButtonWithStyle((grade.color or "~s~")..grade.label.."~s~", "Nom interne : "..grade.name, {RightLabel="→→"}, true, function(_,_,pressed)
                        if pressed then
                            selectedGradeStyleName = grade.name
                            selectedGradeStyleLabel = grade.label
                        end
                    end, MenuAdminGradeColorEdit)
                end
            end
        end, function() end, 1)

        RageUI.IsVisible(MenuAdminGradeColorEdit, true, true, true, function()
            menu = true
            if tonumber(staffRank) ~= 4 or not selectedGradeStyleName then return end
            RageUI.Separator("Grade : ~b~"..(selectedGradeStyleLabel or selectedGradeStyleName).."~s~")
            local colors = {
                {label="Blanc",code="~s~"},{label="Rouge",code="~r~"},{label="Vert",code="~g~"},
                {label="Bleu",code="~b~"},{label="Jaune",code="~y~"},{label="Violet",code="~p~"},
                {label="Orange",code="~o~"},{label="Gris",code="~c~"},{label="Rose",code="~m~"}
            }
            for _,col in ipairs(colors) do
                RageUI.ButtonWithStyle(col.code..col.label.."~s~", "Appliquer cette couleur au grade", {RightLabel=col.code.."●~s~"}, true, function(_,_,pressed)
                    if pressed then TriggerServerEvent("CorePickax:setAdminGradeColor", selectedGradeStyleName, col.code) end
                end)
            end
        end, function() end, 1)

        RageUI.IsVisible(MenuAdminGradeDelete, true, true, true, function()
            menu = true
            if tonumber(staffRank) ~= 4 then return end
            local found = false
            for _,grade in ipairs(adminGradeList) do
                if grade.name ~= "_dev" and grade.name ~= "user" then
                    found = true
                    local kind = grade.custom and "Grade personnalisé" or "Grade natif"
                    RageUI.ButtonWithStyle("~r~"..grade.label.."~s~", kind.." | Nom interne : "..grade.name.." | Tous les joueurs ayant ce grade repasseront user", {RightLabel="~r~Supprimer"}, true, function(_,_,pressed)
                        if pressed then
                            local confirm = ConfigMenuAdministrationAdmin.utils.keyboard("Confirmation", "Tape OUI", 3)
                            if confirm and string.upper(confirm) == "OUI" then
                                TriggerServerEvent("CorePickax:deleteAdminGrade", grade.name)
                            end
                        end
                    end)
                end
            end
            RageUI.Separator("~p~_dev est protégé et ne peut pas être supprimé.~s~")
            if not found then RageUI.Separator("~o~Aucun grade supprimable.~s~") end
        end, function() end, 1)

        RageUI.IsVisible(MenuPermissionRanks, true, true, true, function()
            menu = true
            RageUI.Separator("~p~Configuration réservée au rôle _dev~s~")
            RageUI.Separator("~c~Grades natifs et personnalisés~s~")

            for _, grade in ipairs(adminGradeList) do
                if grade.name ~= "user" and grade.name ~= "_dev" then
                    local targetKey = grade.custom and grade.name or grade.rank
                    local desc = grade.custom and ("Grade personnalisé | Hérite du niveau "..tostring(grade.rank)) or "Grade natif"
                    RageUI.ButtonWithStyle(grade.label, desc.." | Configurer tous les accès", {RightLabel = "→→"}, tonumber(staffRank) == 4, function(_,_,selected)
                        if selected then
                            selectedPermissionRank = targetKey
                            selectedPermissionLabel = grade.label
                        end
                    end, MenuPermissionEdit)
                end
            end
        end, function() end, 1)

        RageUI.IsVisible(MenuPermissionEdit, true, true, true, function()
            menu = true
            if tonumber(staffRank) ~= 4 then
                RageUI.Separator("~r~Accès refusé~s~")
                return
            end

            local perms = adminPermissionMatrix[selectedPermissionRank] or {}
            RageUI.Separator("Grade : ~b~"..(selectedPermissionLabel or tostring(selectedPermissionRank)).."~s~")
            RageUI.Separator("↓ ~p~Accès aux sections ~s~↓")

            local specials = {
                {key="section_self", label="Interactions personnelles"},
                {key="section_players", label="Interactions joueurs"},
                {key="section_reports", label="Interactions reports"},
                {key="section_vehicle", label="Interactions véhicules"},
                {key="setjob", label="Mettre un métier"},
                {key="setjob2", label="Mettre un gang/orga"},
                {key="take_screen", label="Prendre un screen"}
            }

            for _, p in ipairs(specials) do
                local checked = perms[p.key] == true
                RageUI.Checkbox(p.label, "Active ou désactive cet accès pour ce grade", checked, {Style = RageUI.CheckboxStyle.Tick}, function(_,_,_,newChecked)
                    checked = newChecked
                end, function()
                    TriggerServerEvent("CorePickax:setPermission", selectedPermissionRank, p.key, true)
                end, function()
                    TriggerServerEvent("CorePickax:setPermission", selectedPermissionRank, p.key, false)
                end)
            end

            RageUI.Separator("↓ ~b~Actions détaillées ~s~↓")
            for i = 1, #ConfigMenuAdministrationAdmin.functions do
                local f = ConfigMenuAdministrationAdmin.functions[i]
                local key = "func_"..i
                local checked = perms[key] == true
                local prefix = f.cat == "player" and "[Joueur] " or (f.cat == "self" and "[Perso] " or "[Véhicule] ")
                RageUI.Checkbox(prefix..f.label, "Permission #"..i, checked, {Style = RageUI.CheckboxStyle.Tick}, function(_,_,_,newChecked)
                    checked = newChecked
                end, function()
                    TriggerServerEvent("CorePickax:setPermission", selectedPermissionRank, key, true)
                end, function()
                    TriggerServerEvent("CorePickax:setPermission", selectedPermissionRank, key, false)
                end)
            end
        end, function() end, 1)

        RageUI.IsVisible(MenuAdminVehicule,true,true,true,function()
            menu = true
            local pos = GetEntityCoords(PlayerPedId())
            local veh, dst = ESX.Game.GetClosestVehicle(pos)
            if dst ~= nil then RageUI.Separator("~s~Distance: ~b~"..math.floor(dst+0.5).."m") end
            for i = 1,#ConfigMenuAdministrationAdmin.functions do
                if ConfigMenuAdministrationAdmin.functions[i].cat == "veh" then
                    if ConfigMenuAdministrationAdmin.functions[i].sep ~= nil then RageUI.Separator(ConfigMenuAdministrationAdmin.functions[i].sep) end
                    RageUI.ButtonWithStyle(ConfigMenuAdministrationAdmin.functions[i].label, "Appuyez pour faire cette action", isSubMenu[ConfigMenuAdministrationAdmin.functions[i].toSub], hasAdminPermission("func_"..i), function(_,a,s)
                        
                        if a then 
                            pos = GetEntityCoords(veh)
                            DrawGlobalMarker(2, pos.x, pos.y, pos.z+1.3, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 255, 255, 255, 170, 0, 1, 2, 0, nil, nil, 0)
                        end
                        if s then
                            local co = GetEntityCoords(PlayerPedId())
                            local veh, dst = ESX.Game.GetClosestVehicle(co)
                            ConfigMenuAdministrationAdmin.functions[i].press(veh)
                        end
                    end)
                end
            end
        end, function()    
        end, 1)

        RageUI.IsVisible(ReportInfoMain, true, true, true, function()
            RageUI.List("Filtre", {"Report(s) en attente", "Report(s) en cours"}, IndexReport, nil, {}, true, function(Hovered, Active, Selected, Index)
                IndexReport = Index
            end)
            if IndexReport == 1 then
                RageUI.Separator("↓ Report(s) en attente ↓")
                for k, v in pairs(reportlist) do
                    if not v.isTake then
                        RageUI.ButtonWithStyle("~r~[en attente]~s~ "..v.nom.." [ID:~g~"..v.id.."~s~]", "~g~Raison :~s~ "..v.args.."\n~g~Crée le : ~s~"..v.CreateAT, {RightLabel = ""}, true, function(_,_,s)
                            if s then
                                TriggerServerEvent("Admin:takingReport", tonumber(v.id))
                                ReportUsed = v
                            end
                        end, ReportInfo)
                    end
                end
            elseif IndexReport == 2 then
                RageUI.Separator("↓ Report(s) en cours ↓")
                for k, v in pairs(reportlist) do
                    if v.isTake then
                        RageUI.ButtonWithStyle("~g~[en cours]~s~ "..v.nom.." [ID:~g~"..v.id.."~s~]", "~g~Raison :~s~ "..v.args.."\n~g~Crée le : ~s~"..v.CreateAT.."\n~r~Pris par : ~s~"..v.StaffName, {RightLabel = ""}, true, function(_,_,s)
                            if s then
                                ReportUsed = v
                            end
                        end, ReportInfo)
                    end
                end
            end
        end, function()
        end, 1)

        RageUI.IsVisible(ReportInfo, true, true, true, function()
            local nom = ReportUsed.nom
            local id = ReportUsed.id
            local raison = ReportUsed.args
            RageUI.Separator("Report de : [~g~ID:"..ReportUsed.id.."~s~] ~g~"..nom)
            if ReportUsed.StaffName ~= nil then
                RageUI.Separator("Pris par : ~g~"..ReportUsed.StaffName)
            else
                RageUI.Separator("Pris par : ~g~Vous")
            end

            RageUI.Separator("↓ ~b~Interaction avec le TP~s~ ↓")
            RageUI.ButtonWithStyle("Se téléporter sur ~r~"..nom, nil, {RightLabel = "→→"}, true, function(_,_,s)
                if s then
                    TriggerServerEvent("CorePickax:ActionAdmin", "TP", "goto", id)
                end
            end)

            RageUI.ButtonWithStyle("Téléporter ~r~"..nom.."~s~ sur moi", nil, {RightLabel = "→→"}, true, function(_,_,s)
                if s then
                    TriggerServerEvent("CorePickax:ActionAdmin", "TP", "bring", id)
                end
            end)

            if ConfigMenuAdmin.MenuConfigMenuAdministration.TPRapideReport ~= nil and #ConfigMenuAdmin.MenuConfigMenuAdministration.TPRapideReport >= 1 then
                RageUI.List("TP ~r~"..nom.."~s~", ConfigMenuAdmin.MenuConfigMenuAdministration.TPRapideReport, ESXCustomListButon.ReportMenu, nil, {}, true, function(Hovered, Active, Selected, Index)
                    if (Selected) then
                        ConfigMenuAdmin.MenuConfigMenuAdministration.TPRapideReport[Index].OnClick(nom, id, Index)
                    end
                    ESXCustomListButon.ReportMenu = Index;
                end)
            end
            RageUI.Separator("↓ ~b~Interaction avec la vie~s~ ↓")
            RageUI.ButtonWithStyle("Revive ~r~"..nom, nil, {RightLabel = "→→"}, true, function(_,_,s)
                if s then
                    TriggerServerEvent("CorePickax:messageReport", id, "~r~Staff~s~\nVous avez été réanimer !")
                    TriggerServerEvent("CorePickax:ActionAdmin", "ActionPlayer", "RevivePlayer", id)
                end
            end)
            RageUI.ButtonWithStyle("Heal ~r~"..nom, nil, {RightLabel = "→→"}, true, function(_,_,s)
                if s then
                    TriggerServerEvent("CorePickax:messageReport", id, "~r~Staff~s~\nVous avez été heal !")
                    TriggerServerEvent("CorePickax:ActionAdmin", "ActionPlayer", "healPlayer", GetPlayerServerId(PlayerId(id)))
                end
            end)

            RageUI.Line()

            RageUI.ButtonWithStyle("Jail", nil, {RightLabel = "→→"}, true, function(_, _, s)
                if s then 
                    local reponse = ConfigMenuAdministrationAdmin.utils.keyboard('~c~Entrez le temps ici :', nil, 30)
                    local reponseReport = GetOnscreenKeyboardResult(reponse)
                    local raison = ConfigMenuAdministrationAdmin.utils.keyboard('~c~Entrez la raison ici :', nil, 30)
                    local reponseRaison = GetOnscreenKeyboardResult(raison)
                    if reponseReport == "" then
                        ESX.ShowNotification(ConfigMenuAdmin.Notification["AdminMessage"])
                    else
                        if reponseRaison == "" then
                            ESX.ShowNotification(ConfigMenuAdmin.Notification["AdminMessage"])
                        else
                            result = tonumber(reponse)
                            if result >= 16 then
                            else
                                if reponseReport then
                                    ExecuteCommand("jail "..id.." "..reponseReport.."")
                                    ESX.ShowNotification(ConfigMenuAdmin.Notification["UJail"]) 
                                end
                            end
                        end
                    end
                end
            end)

            RageUI.ButtonWithStyle("Unjail (~r~Action irréversible~s~).", nil, {RightLabel = "→→"}, true, function(_, _, s)
                if s then
                    ExecuteCommand("unjail "..id.."")
                end
            end)

            RageUI.ButtonWithStyle("Répondre au report", nil, {RightLabel = "→→"}, true, function(_, _, s)
                if s then 
                    local reponse = ConfigMenuAdministrationAdmin.utils.keyboard('~c~Entrez le message ici :', nil, 30)
                    local reponseReport = GetOnscreenKeyboardResult(reponse)
                    if reponseReport == "" then
                        ESX.ShowNotification(ConfigMenuAdmin.Notification["AdminMessage"])
                    else
                        if reponseReport then
                            ESX.ShowNotification((ConfigMenuAdmin.Notification["messagesend"]):format(reponseReport, GetPlayerName(GetPlayerFromServerId(id))))
                            TriggerServerEvent("CorePickax:messageReport", id, "~r~Staff~s~\n"..reponseReport)
                        end
                    end
                end
            end)

            RageUI.ButtonWithStyle("Fermer le report de ~r~"..nom, nil, {RightLabel = "→→"}, true, function(_,_,s)
                if s then
                    TriggerServerEvent("CorePickax:messageReport", id, "~r~Staff~s~\nVotre report à été fermé !")
                    TriggerServerEvent("CorePickax:GestionReport", "Close", nom, raison, id)
                    RageUI.CloseAll()
                end
            end)

        end, function()
        end, 1)

        RageUI.IsVisible(MenuAdminPerso, true,true,true,function()
            menu = true
            if NoClipF2 then
                RageUI.ButtonWithStyle("NoClip", "~r~Veuillez désactiver votre noclip avec la commande pour faire ceci.~s~", {RightLabel = "~r~Désactiver~s~"}, false, function(_,_,s)
                end)
                RageUI.ButtonWithStyle("Invisibilité", "~r~Veuillez désactiver votre noclip avec la commande pour faire ceci.~s~", {RightLabel = "~r~Désactiver~s~"}, false, function(_,_,s)
                end)
            else
                RageUI.Checkbox("NoClip", nil, NoClip, { Style = RageUI.CheckboxStyle.Tick }, function(Hovered, Selected, Active, Checked)
                    NoClip = Checked;
                end, function()
                    FreezeEntityPosition(GetPlayerPed(-1), true)
                    NoClip = true
                    invisible = true
                    initializeNoclip()
                    initializeInvis()
                end, function()
                    FreezeEntityPosition(GetPlayerPed(-1), false)
                    SetEntityCollision(GetPlayerPed(-1), 1, 1)
                    SetEntityVisible(GetPlayerPed(-1), 1, 0)
                    NetworkSetEntityInvisibleToNetwork(GetPlayerPed(-1), 0)
                    invisible = false
                    NoClip = false
                end)

                RageUI.Checkbox("Invisibilité", nil, invisible, { Style = RageUI.CheckboxStyle.Tick }, function(Hovered, Selected, Active, Checked)
                    invisible = Checked;
                end, function()
                    invisible = true
                    initializeInvis()
                end, function()
                    invisible = false
                    SetEntityVisible(GetPlayerPed(-1), 1, 0)
                    NetworkSetEntityInvisibleToNetwork(GetPlayerPed(-1), 0)
                end)
            end

            RageUI.Checkbox("Invincible", "Empêche votre personnage de subir des dégâts pendant le mode administration", invincible, { Style = RageUI.CheckboxStyle.Tick }, function(_,_,_,Checked)
                invincible = Checked
            end, function()
                invincible = true
                SetEntityInvincible(PlayerPedId(), true)
                SetPlayerInvincible(PlayerId(), true)
            end, function()
                invincible = false
                SetEntityInvincible(PlayerPedId(), false)
                SetPlayerInvincible(PlayerId(), false)
            end)

            RageUI.Checkbox("Afficher les noms", nil, ShowName, { Style = RageUI.CheckboxStyle.Tick }, function(Hovered, Selected, Active, Checked)
                ShowName = Checked;
            end, function()
                ShowName = true
                initializeNames()
            end, function()
                ShowName = false
                for _,v in pairs(GetActivePlayers()) do
                    RemoveMpGamerTag(gamerTags[v])
                end
            end)

            RageUI.Checkbox("Afficher le HUD staff", "Active ou désactive le bandeau d'informations en haut de l'écran", showStaffHud, { Style = RageUI.CheckboxStyle.Tick }, function(Hovered, Selected, Active, Checked)
                showStaffHud = Checked
            end, function()
                showStaffHud = true
            end, function()
                showStaffHud = false
            end)
        end, function()    
        end, 1)

        if not RageUI.Visible(MenuAdminPrincipal) and
        not RageUI.Visible(MenuAdminSelf) and
        not RageUI.Visible(MenuAdminCitoyens) and
        not RageUI.Visible(MenuAdminVehicule) and
        not RageUI.Visible(MenuAdminCitoyens2) and
        not RageUI.Visible(MenuAdminSetJob) and
        not RageUI.Visible(MenuAdminSetJobGrades) and
        not RageUI.Visible(MenuAdminSetJob2) and
        not RageUI.Visible(MenuAdminSetJob2Grades) and
        not RageUI.Visible(MenuAdminSetAdminGrade) and
        not RageUI.Visible(ReportInfo) and
        not RageUI.Visible(MenuAdminPerso) and
        not RageUI.Visible(ReportInfoMain) and
        not RageUI.Visible(menuDev) and
        not RageUI.Visible(MenuPermissionRanks) and
        not RageUI.Visible(MenuPermissionEdit) and
        not RageUI.Visible(MenuAdminGradeManagement) and
        not RageUI.Visible(MenuAdminGradeCreate) and
        not RageUI.Visible(MenuAdminGradeDelete) and
        not RageUI.Visible(MenuAdminGradeColorList) and
        not RageUI.Visible(MenuAdminGradeColorEdit) and
        not RageUI.Visible(Menu_cutscene) and
        not RageUI.Visible(Menu_Builder) and
        not RageUI.Visible(Menu_interieur) and
        not RageUI.Visible(Menu_animation) then
            MenuAdminPrincipal = RMenu:DeleteType("MenuAdminPrincipal")
            MenuAdminSelf = RMenu:DeleteType("MenuAdminSelf")
            MenuAdminCitoyens = RMenu:DeleteType("MenuAdminCitoyens")
            MenuAdminVehicule = RMenu:DeleteType("MenuAdminVehicule")
            MenuAdminCitoyens2 = RMenu:DeleteType("MenuAdminCitoyens2")
            MenuAdminSetJob = RMenu:DeleteType("MenuAdminSetJob")
            MenuAdminSetJobGrades = RMenu:DeleteType("MenuAdminSetJobGrades")
            MenuAdminSetJob2 = RMenu:DeleteType("MenuAdminSetJob2")
            MenuAdminSetJob2Grades = RMenu:DeleteType("MenuAdminSetJob2Grades")
            MenuAdminSetAdminGrade = RMenu:DeleteType("MenuAdminSetAdminGrade")
            ReportInfo = RMenu:DeleteType("ReportInfo")
            MenuAdminPerso = RMenu:DeleteType("MenuAdminPerso")
            menuDev = RMenu:DeleteType("menuDev")
            MenuPermissionRanks = RMenu:DeleteType("MenuPermissionRanks")
            MenuPermissionEdit = RMenu:DeleteType("MenuPermissionEdit")
            MenuAdminGradeManagement = RMenu:DeleteType("MenuAdminGradeManagement")
            MenuAdminGradeCreate = RMenu:DeleteType("MenuAdminGradeCreate")
            MenuAdminGradeDelete = RMenu:DeleteType("MenuAdminGradeDelete")
            MenuAdminGradeColorList = RMenu:DeleteType("MenuAdminGradeColorList")
            MenuAdminGradeColorEdit = RMenu:DeleteType("MenuAdminGradeColorEdit")
            Menu_cutscene = RMenu:DeleteType("Menu_cutscene")
            Menu_interieur = RMenu:DeleteType("Menu_interieur")
            Menu_animation = RMenu:DeleteType("Menu_animation")
            ReportInfoMain = RMenu:DeleteType("ReportInfoMain")
        end
    end
end

RegisterNetEvent("CorePickax:remb", function(id)
    if colorVar == nil then return end
    RageUI.CloseAll()
    Citizen.Wait(100)
    MenuStaffOpen5()
end)

RegisterNetEvent("CorePickax:weapon", function(id)
    if colorVar == nil then return end
    RageUI.CloseAll()
    Citizen.Wait(100)
    MenuStaffOpen4(id)
end)

local isRequest = false

RegisterNetEvent("CorePickax:ridentityj", function(id)
    isRequest = true
    ESX.ShowNotification(ConfigMenuAdmin.Notification["AccptRefuse"])
    TriggerEvent("CorePickax:Accepte?")
end)

RegisterNetEvent("CorePickax:Accepte?", function(id)
    Citizen.CreateThread(function()
        while true do
            local timer = 0
            Citizen.Wait(5)
            timer = timer + 1
            if IsControlJustPressed(1, 246) and isRequest then
                ESX.ShowNotification(ConfigMenuAdmin.Notification["UAccept"])
                ExecuteCommand("chardeladmin")
                isRequest = false
            elseif IsControlJustPressed(1, 182) and isRequest then
                ESX.ShowNotification(ConfigMenuAdmin.Notification["URefuse"])
                isRequest = false
            end
            if timer > 10 then
                isRequest = false
                break
            end
        end
    end)
end)

RegisterNetEvent("CorePickax:getItems", function(table)
    items = table
end)

RegisterNetEvent("CorePickax:canUse", function(ok, rank, license, forcedRank, forcedLabel, forcedColor)
    if ok then
        initializeThread(rank,license,forcedRank,forcedLabel,forcedColor)
    end
end)

RegisterNetEvent("CorePickax:peds", function()
    if colorVar == nil then return end
    RageUI.CloseAll()
    Citizen.Wait(100)
    MenuStaffOpen3()
end)

--------------------------------------------
--GiveClefVehicule
local voituregive = {}

function give_vehi(veh)
    local plyCoords = GetEntityCoords(GetPlayerPed(-1), false)
    
    Citizen.Wait(10)
    ESX.Game.SpawnVehicle(veh, {x = plyCoords.x+2 ,y = plyCoords.y, z = plyCoords.z+2}, 313.4216, function (vehicle)
        local plate = GeneratePlate()
        table.insert(voituregive, vehicle)		
        local vehicleProps = ESX.Game.GetVehicleProperties(voituregive[#voituregive])
        vehicleProps.plate = plate
        SetVehicleNumberPlateText(voituregive[#voituregive] , plate)
		TriggerServerEvent('shop:vehicule', vehicleProps, plate)
	end)
end

--Vehicle Max
function FullVehicleBoost()
	if IsPedInAnyVehicle(PlayerPedId(), false) then
		local vehicle = GetVehiclePedIsIn(PlayerPedId(), true)
		SetVehicleModKit(vehicle, 0)
		SetVehicleMod(vehicle, 14, 0, true)
		SetVehicleNumberPlateTextIndex(vehicle, 5)
		ToggleVehicleMod(vehicle, 18, true)
		SetVehicleColours(vehicle, 0, 0)
		SetVehicleCustomPrimaryColour(vehicle, 0, 0, 0)
		SetVehicleModColor_2(vehicle, 5, 0)
		SetVehicleExtraColours(vehicle, 111, 111)
		SetVehicleWindowTint(vehicle, 2)
		ToggleVehicleMod(vehicle, 22, true)
		SetVehicleMod(vehicle, 23, 11, false)
		SetVehicleMod(vehicle, 24, 11, false)
		SetVehicleWheelType(vehicle, 12) 
		SetVehicleWindowTint(vehicle, 3)
		ToggleVehicleMod(vehicle, 20, true)
		SetVehicleTyreSmokeColor(vehicle, 0, 0, 0)
		LowerConvertibleRoof(vehicle, true)
		SetVehicleIsStolen(vehicle, false)
		SetVehicleIsWanted(vehicle, false)
		SetVehicleHasBeenOwnedByPlayer(vehicle, true)
		SetVehicleNeedsToBeHotwired(vehicle, false)
		SetCanResprayVehicle(vehicle, true)
		SetPlayersLastVehicle(vehicle)
		SetVehicleFixed(vehicle)
		SetVehicleDeformationFixed(vehicle)
		SetVehicleTyresCanBurst(vehicle, false)
		SetVehicleWheelsCanBreak(vehicle, false)
		SetVehicleCanBeTargetted(vehicle, false)
		SetVehicleExplodesOnHighExplosionDamage(vehicle, false)--ICI A PRENDRE POUR LE AC
		SetVehicleHasStrongAxles(vehicle, true)
		SetVehicleDirtLevel(vehicle, 0)
		SetVehicleCanBeVisiblyDamaged(vehicle, false)
		IsVehicleDriveable(vehicle, true)
		SetVehicleEngineOn(vehicle, true, true)
		SetVehicleStrong(vehicle, true)
		RollDownWindow(vehicle, 0)
		RollDownWindow(vehicle, 1)
		SetVehicleNeonLightEnabled(vehicle, 0, true)
		SetVehicleNeonLightEnabled(vehicle, 1, true)
		SetVehicleNeonLightEnabled(vehicle, 2, true)
		SetVehicleNeonLightEnabled(vehicle, 3, true)
		SetVehicleNeonLightsColour(vehicle, 0, 0, 255)
		SetPedCanBeDraggedOut(PlayerPedId(), false)
		SetPedStayInVehicleWhenJacked(PlayerPedId(), true)
		SetPedRagdollOnCollision(PlayerPedId(), false)
		ResetPedVisibleDamage(PlayerPedId())
		ClearPedDecorations(PlayerPedId())
		SetIgnoreLowPriorityShockingEvents(PlayerPedId(), true)
		for i = 0,14 do
			SetVehicleExtra(veh, i, 0)
		end
		SetVehicleModKit(veh, 0)
		for i = 0,49 do
			local custom = GetNumVehicleMods(veh, i)
			for j = 1,custom do
				SetVehicleMod(veh, i, math.random(1,j), 1)
			end
		end
	end
end

RegisterCommand("spect", function(source, args, rawCommand)  
    if playerGroup[MonID()] ~= nil and playerGroup[MonID()] ~= "user" then
        idnum = tonumber(args[1])
        local playerId = GetPlayerFromServerId(idnum)
        SpectatePlayer(GetPlayerPed(playerId), playerId, GetPlayerName(playerId))
    else
        ESX.ShowNotification(ConfigMenuAdmin.Notification["NotAcces"])
    end
end)

RegisterCommand("repair", function(source, args, rawCommand)  
    if playerGroup[MonID()] ~= nil and playerGroup[MonID()] ~= "user" then
        local plyPed = GetPlayerPed(-1)
	    local plyVeh = GetVehiclePedIsIn(plyPed, false)
	    SetVehicleFixed(plyVeh)
	    SetVehicleDirtLevel(plyVeh, 0.0)
    else
        ESX.ShowNotification(ConfigMenuAdmin.Notification["NotAcces"])
    end
end)

function SpectatePlayer(targetPed,target,name)
    local playerPed = PlayerPedId() -- yourself
    enable = true
    if targetPed == playerPed then enable = false end

    if(enable)then

        local targetx,targety,targetz = table.unpack(GetEntityCoords(targetPed, false))

        RequestCollisionAtCoord(targetx,targety,targetz)
        NetworkSetInSpectatorMode(true, targetPed)
        DrawPlayerInfo(target)
        ESX.ShowNotification(ConfigMenuAdmin.Notification["SpectEnCours"])
    else

        local targetx,targety,targetz = table.unpack(GetEntityCoords(targetPed, false))

        RequestCollisionAtCoord(targetx,targety,targetz)
        NetworkSetInSpectatorMode(false, targetPed)
        StopDrawPlayerInfo()
        ESX.ShowNotification(ConfigMenuAdmin.Notification["SpectStop"])
    end
end

Citizen.CreateThread( function()
    while true do
        local timer = 200
        if drawInfo then
            timer = 0
        end
        Citizen.Wait(timer)
        if drawInfo then
            local text = {}
            -- cheat checks
            local targetPed = GetPlayerPed(drawTarget)
            
            table.insert(text,"E pour stop spectate")
            
            for i,theText in pairs(text) do
                SetTextFont(0)
                SetTextProportional(1)
                SetTextScale(0.0, 0.30)
                SetTextDropshadow(0, 0, 0, 0, 255)
                SetTextEdge(1, 0, 0, 0, 255)
                SetTextDropShadow()
                SetTextOutline()
                SetTextEntry("STRING")
                AddTextComponentString(theText)
                EndTextCommandDisplayText(0.3, 0.7+(i/30))
            end
            
            if IsControlJustPressed(0,103) then
                local targetPed = PlayerPedId()
                local targetx,targety,targetz = table.unpack(GetEntityCoords(targetPed, false))
    
                RequestCollisionAtCoord(targetx,targety,targetz)
                NetworkSetInSpectatorMode(false, targetPed)
    
                StopDrawPlayerInfo()
                
            end
            
        end
    end
end)

function DrawPlayerInfo(target)
    drawTarget = target
    drawInfo = true
end

function StopDrawPlayerInfo()
    drawInfo = false
    drawTarget = 0
end

RegisterNetEvent('CorePickax:kill', function()
	SetEntityHealth(GetPlayerPed(-1), 0)
end)

RegisterNetEvent("ESXCustomAdmin:killPlayer", function()
  SetEntityHealth(PlayerPedId(), 0)
end)

RegisterNetEvent("ESXCustomAdmin:freezePlayer", function(input)
    local player = PlayerId()
	local ped = PlayerPedId()
    if input == 'freeze' then
        SetEntityCollision(ped, false)
        FreezeEntityPosition(ped, true)
        SetPlayerInvincible(player, true)
    elseif input == 'unfreeze' then
        SetEntityCollision(ped, true)
	    FreezeEntityPosition(ped, false)
        SetPlayerInvincible(player, false)
    end
end)

function SetPed(NamePed)
    local j1 = PlayerId()
    local p1 = GetHashKey(NamePed)
    RequestModel(p1)
    while not HasModelLoaded(p1) do
        Wait(100)
    end
    SetPlayerModel(j1, p1)
    SetModelAsNoLongerNeeded(p1)
    ESX.ShowNotification(ConfigMenuAdmin.Notification["UChangePed"])
end

--Partie report
RegisterNetEvent("CorePickax:Open/CloseReport", function(type, nomdumec, raisondumec, idDuMec)
    if staffService then
        if type == 1 then
            if playerGroup[MonID()] ~= nil and playerGroup[MonID()] ~= "user" then
                ESX.ShowNotification((ConfigMenuAdmin.Notification["NewReport"]):format(nomdumec))
            end
        elseif type == 2 then
            if playerGroup[MonID()] ~= nil and playerGroup[MonID()] ~= "user" then
                ESX.ShowNotification((ConfigMenuAdmin.Notification["CloseReport"]):format(nomdumec))
            end
        end
    end
end)

function TPPlayer(nom, id, pose, Index)
    TriggerServerEvent("CorePickax:ActionAdmin", "TP", "tpatcoord", id, pose)
    TriggerServerEvent("CorePickax:messageReport", id, "~r~Staff~s~\nVous avez été TP "..ConfigMenuAdmin.MenuConfigMenuAdministration.TPRapideReport[Index].Name.." !")
end

----NoClip Bind
noclipActive = false
index = 1

RegisterKeyMapping(ConfigMenuAdminNoclip.Commande.CommandeName, ConfigMenuAdminNoclip.Commande.Desc, 'keyboard', ConfigMenuAdminNoclip.Commande.Bind)

RegisterCommand(ConfigMenuAdminNoclip.Commande.CommandeName, function()
    if staffRank == nil then return end
    if staffService == false then
        return ESX.ShowNotification(ConfigMenuAdmin.Notification["MustBeStaffService"])
    end
    if IsPedInAnyVehicle(PlayerPedId(), false) then
        if (GetPedInVehicleSeat(GetVehiclePedIsIn(GetPlayerPed(-1), false), -1) == GetPlayerPed(-1)) then
            noclipActive = not noclipActive
            if GetPedInVehicleSeat(GetVehiclePedIsIn(GetPlayerPed(-1), false), 0) ~= 0 then
                TriggerServerEvent("CorePickax:LoadEventServerSide", GetPlayerServerId(NetworkGetPlayerIndexFromPed(GetPedInVehicleSeat(GetVehiclePedIsIn(GetPlayerPed(-1), false), 0))), noclipActive)
            end
            if GetPedInVehicleSeat(GetVehiclePedIsIn(GetPlayerPed(-1), false), 1) ~= 0 then
                TriggerServerEvent("CorePickax:LoadEventServerSide", GetPlayerServerId(NetworkGetPlayerIndexFromPed(GetPedInVehicleSeat(GetVehiclePedIsIn(GetPlayerPed(-1), false), 1))), noclipActive)
            end
            if GetPedInVehicleSeat(GetVehiclePedIsIn(GetPlayerPed(-1), false), 2) ~= 0 then
                TriggerServerEvent("CorePickax:LoadEventServerSide", GetPlayerServerId(NetworkGetPlayerIndexFromPed(GetPedInVehicleSeat(GetVehiclePedIsIn(GetPlayerPed(-1), false), 2))), noclipActive)
            end

            noclipEntity = GetVehiclePedIsIn(PlayerPedId(), false)
            SetNoClip(noclipEntity, noclipActive)
        end
    else
        noclipActive = not noclipActive

        noclipEntity = PlayerPedId()
        SetNoClip(noclipEntity, noclipActive)
    end
end)

function DisableNoclip(noclipEntity)
    noclipActive = false
    SetEntityVisible(noclipEntity, true)
    ResetEntityAlpha(noclipEntity)
    SetEntityCollision(noclipEntity, not noclipActive, not noclipActive)
    FreezeEntityPosition(noclipEntity, noclipActive)
    SetEntityInvincible(noclipEntity, noclipActive)
    SetNoClip(PlayerPedId(), noclipActive)
end

function SetNoClip(noclipEntity, noclipActive)
    if NoClip == false then
        NoClip = true
    else
        NoClip = false
        found, groundZ = GetGroundZFor_3dCoord(GetEntityCoords(PlayerPedId()).x, GetEntityCoords(PlayerPedId()).y, GetEntityCoords(PlayerPedId()).z, false)

        if found then
            SetPedCoordsKeepVehicle(noclipEntity, GetEntityCoords(PlayerPedId()).x, GetEntityCoords(PlayerPedId()).y, groundZ)
        end
    end

    if NoClipF2 == false then
        NoClipF2 = true
    else
        NoClipF2 = false
    end

    SetEntityCollision(noclipEntity, not noclipActive, not noclipActive)
    FreezeEntityPosition(noclipEntity, noclipActive)
    SetEntityInvincible(noclipEntity, noclipActive)
    if noclipActive then
        SetEntityAlpha(noclipEntity, 60, false)
        SetEntityVisible(noclipEntity, false)
        Citizen.CreateThread(function()
            buttons = setupScaleform("instructional_buttons")
            currentSpeed = ConfigMenuAdminNoclip.Speeds[index].speed
            while true do
                if noclipActive then
                    if IsPedInAnyVehicle(PlayerPedId(), false) then
                        if IsControlJustPressed(1, 75) then
                            DisableNoclip(noclipEntity)
                        end
                    end
        
                    DrawScaleformMovieFullscreen(buttons)
        
                    local yoff = 0.0
                    local zoff = 0.0
        
                    if IsControlJustPressed(1, ConfigMenuAdminNoclip.Controls.changeSpeed) then
                        if index ~= 8 then
                            index = index+1
                            currentSpeed = ConfigMenuAdminNoclip.Speeds[index].speed
                        else
                            currentSpeed = ConfigMenuAdminNoclip.Speeds[1].speed
                            index = 1
                        end
                        setupScaleform("instructional_buttons")
                    end

                    -- Réglage de la vitesse à la molette.
                    -- FiveM: 15/17 = molette haut, 14/16 = molette bas.
                    local wheelUp = IsControlJustPressed(0, 15) or IsControlJustPressed(0, 17)
                    local wheelDown = IsControlJustPressed(0, 14) or IsControlJustPressed(0, 16)

                    if wheelUp and index < #ConfigMenuAdminNoclip.Speeds then
                        index = index + 1
                        currentSpeed = ConfigMenuAdminNoclip.Speeds[index].speed
                        buttons = setupScaleform("instructional_buttons")
                    elseif wheelDown and index > 1 then
                        index = index - 1
                        currentSpeed = ConfigMenuAdminNoclip.Speeds[index].speed
                        buttons = setupScaleform("instructional_buttons")
                    end

                    if IsControlJustPressed(1, ConfigMenuAdminNoclip.Controls.noclipheading) then
                        if ChecktheHeading then
                            ChecktheHeading = false
                        else
                            ChecktheHeading = true
                        end
                    end
                        
                    DisableControls()
        
                    if IsDisabledControlPressed(0, ConfigMenuAdminNoclip.Controls.goForward) then
                        yoff = ConfigMenuAdminNoclip.Offsets.y
                    end
                    
                    if IsDisabledControlPressed(0, ConfigMenuAdminNoclip.Controls.goBackward) then
                        yoff = -ConfigMenuAdminNoclip.Offsets.y
                    end
                    
                    if IsDisabledControlPressed(0, ConfigMenuAdminNoclip.Controls.turnLeft) then
                        SetEntityHeading(noclipEntity, GetEntityHeading(noclipEntity)+ConfigMenuAdminNoclip.Offsets.h)
                    end
                    
                    if IsDisabledControlPressed(0, ConfigMenuAdminNoclip.Controls.turnRight) then
                        SetEntityHeading(noclipEntity, GetEntityHeading(noclipEntity)-ConfigMenuAdminNoclip.Offsets.h)
                    end
                    
                    if IsDisabledControlPressed(0, ConfigMenuAdminNoclip.Controls.goUp) then
                        zoff = ConfigMenuAdminNoclip.Offsets.z
                    end
                    
                    if IsDisabledControlPressed(0, ConfigMenuAdminNoclip.Controls.goDown) then
                        zoff = -ConfigMenuAdminNoclip.Offsets.z
                    end
                    
                    local newPos = GetOffsetFromEntityInWorldCoords(noclipEntity, 0.0, yoff * (currentSpeed + 0.3), zoff * (currentSpeed + 0.3))
                    local heading = GetEntityHeading(noclipEntity)
                    SetEntityVelocity(noclipEntity, 0.0, 0.0, 0.0)
                    SetEntityRotation(noclipEntity, 0.0, 0.0, 0.0, 0, false)
                    if ChecktheHeading then
                        SetEntityHeading(noclipEntity, GetGameplayCamRelativeHeading())
                    else
                        SetEntityHeading(noclipEntity, heading)
                    end
                    SetEntityCoordsNoOffset(noclipEntity, newPos.x, newPos.y, newPos.z, noclipActive, noclipActive, noclipActive)
                    SetEntityLocallyVisible(noclipEntity)
                end

                if not NoClip then
                    break
                end
                Citizen.Wait(1)
            end
        end)
    else
        SetEntityVisible(noclipEntity, true)
        ResetEntityAlpha(noclipEntity)
        noclipEntity = nil
    end
    SetVehicleRadioEnabled(noclipEntity, not noclipActive)
end

local stateF = false
RegisterNetEvent("CorePickax:LoadEventClientSide", function(toBreak)
    if stateF == false then
        stateF = true
        Citizen.CreateThread(function()
            while true do
                Citizen.Wait(1)
                if IsPedInAnyVehicle(PlayerPedId(), false) then
                    if IsControlJustPressed(1, 75) then
                        SetEntityVisible(PlayerPedId(), true)
                        ResetEntityAlpha(PlayerPedId())
                        SetEntityCollision(PlayerPedId(), true, true)
                        FreezeEntityPosition(PlayerPedId(), false)
                        SetEntityInvincible(PlayerPedId(), false)
                        stateF = false
                    end
                end

                if not toBreak then
                    stateF = false
                    break
                end
            end
        end)
    end
end)

--function noclip
function ButtonMessage(text)
    BeginTextCommandScaleformString("STRING")
    AddTextComponentScaleform(text)
    EndTextCommandScaleformString()
end

function Button(ControlButton)
    N_0xe83a3e3557a56640(ControlButton)
end

function setupScaleform(scaleform)
    local scaleform = RequestScaleformMovie(scaleform)

    while not HasScaleformMovieLoaded(scaleform) do
        Citizen.Wait(1)
    end

    PushScaleformMovieFunction(scaleform, "CLEAR_ALL")
    PopScaleformMovieFunctionVoid()
    
    PushScaleformMovieFunction(scaleform, "SET_CLEAR_SPACE")
    PushScaleformMovieFunctionParameterInt(200)
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(6)
    Button(GetControlInstructionalButton(2, ConfigMenuAdminNoclip.Commande.openKey, true))
    ButtonMessage(ConfigMenuAdminNoclip.Texte["DisableNoclip"])
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(5)
    Button(GetControlInstructionalButton(2, ConfigMenuAdminNoclip.Commande.noclipheading, true))
    ButtonMessage(ConfigMenuAdminNoclip.Texte["HeadingC"])
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(4)
    Button(GetControlInstructionalButton(2, ConfigMenuAdminNoclip.Controls.goUp, true))
    ButtonMessage(ConfigMenuAdminNoclip.Texte["GoUp"])
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(3)
    Button(GetControlInstructionalButton(2, ConfigMenuAdminNoclip.Controls.goDown, true))
    ButtonMessage(ConfigMenuAdminNoclip.Texte["GoDown"])
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(2)
    Button(GetControlInstructionalButton(1, ConfigMenuAdminNoclip.Controls.turnRight, true))
    Button(GetControlInstructionalButton(1, ConfigMenuAdminNoclip.Controls.turnLeft, true))
    ButtonMessage(ConfigMenuAdminNoclip.Texte["TurnLeft/Right"])
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(1)
    Button(GetControlInstructionalButton(1, ConfigMenuAdminNoclip.Controls.goBackward, true))
    Button(GetControlInstructionalButton(1, ConfigMenuAdminNoclip.Controls.goForward, true))
    ButtonMessage(ConfigMenuAdminNoclip.Texte["Forwards/Backwards"])
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(0)
    Button(GetControlInstructionalButton(2, ConfigMenuAdminNoclip.Controls.changeSpeed, true))
    ButtonMessage((ConfigMenuAdminNoclip.Texte["ChangeSpeed"]):format(ConfigMenuAdminNoclip.Speeds[index].label))
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_BACKGROUND_COLOUR")
    PushScaleformMovieFunctionParameterInt(ConfigMenuAdminNoclip.bgR)
    PushScaleformMovieFunctionParameterInt(ConfigMenuAdminNoclip.bgG)
    PushScaleformMovieFunctionParameterInt(ConfigMenuAdminNoclip.bgB)
    PushScaleformMovieFunctionParameterInt(ConfigMenuAdminNoclip.bgA)
    PopScaleformMovieFunctionVoid()

    return scaleform
end

function DisableControls()
    DisableControlAction(0, 30, true)
    DisableControlAction(0, 31, true)
    DisableControlAction(0, 32, true)
    DisableControlAction(0, 33, true)
    DisableControlAction(0, 34, true)
    DisableControlAction(0, 35, true)
    DisableControlAction(0, 266, true)
    DisableControlAction(0, 267, true)
    DisableControlAction(0, 268, true)
    DisableControlAction(0, 269, true)
    DisableControlAction(0, 44, true)
    DisableControlAction(0, 20, true)
    -- DisableControlAction(0, 74, true)
end

--Menu Dev
AnimationLoad = function(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
       Wait(1)
    end
end

TaskAnimESXCustom = function(ped, animDict, animName)
    AnimationLoad(animDict)
    TaskPlayAnim(ped, animDict, animName, 1.0, -1.0, -1, 1, 1, false, false, false)
end

PlayCutscene = function(name)
    StopCutsceneImmediately()
    local landAnim = {1, 2, 4}
    local timings = {
      [1] = 9100,
      [2] = 17500,
      [4] = 25400
    }
    RequestCollisionAtCoord(-27.8442, -83.1899, 57.2537)
    local flag = landAnim[ math.random( #landAnim ) ]
    LoadCutscene(name, 3, 24)
    BeginCutsceneWithPlayerx()
end

LoadCutscene = function(cut, flag1, flag2)
    if (not flag1) then
      RequestCutscene(cut, 8)
    else
      RequestCutsceneEx(cut, flag1, flag2)
    end
    while (not HasThisCutsceneLoaded(cut)) do Wait(0) end
    return
end

BeginCutsceneWithPlayerx = function()
    local plyrId = PlayerPedId()
    local playerClone = ClonePed_2(plyrId, 0.0, false, true, 1)
  
    SetBlockingOfNonTemporaryEvents(playerClone, true)
    SetEntityVisible(playerClone, false, false)
    SetEntityInvincible(playerClone, true)
    SetEntityCollision(playerClone, false, false)
    FreezeEntityPosition(playerClone, true)
    SetPedHelmet(playerClone, false)
    RemovePedHelmet(playerClone, true)
  
    SetCutsceneEntityStreamingFlags('MP_1', 0, 1)
    RegisterEntityForCutscene(plyrId, 'MP_1', 0, GetEntityModel(plyrId), 64)


    SetCutscenePedComponentVariationFromPed("Michael", PlayerPedId(), 0)
    -- Registering can occur at any point past here before starting the cutscene.
    RegisterEntityForCutscene(PlayerPedId(), "Michael", 0, 0, 64)
    repeat Wait(0) until HasCutsceneLoaded()

    Wait(10)
    StartCutscene(0)
    Wait(10)
    ClonePedToTarget(playerClone, plyrId)
    Wait(10)
    DeleteEntity(playerClone)
    Wait(50)
  
    return playerClone
end

drawText = function(string, coords)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextScale(0.36, 0.36)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(5, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextRightJustify(false)
    SetTextWrap(0,0.55)
    SetTextEntry("STRING")
    
    AddTextComponentString(string)
    DrawText(coords.x, coords.y)
end

function Showinterior()
    if showinterior then
        showinterior = false
        ESX.ShowNotification("Affichage les info interieur ~r~désactivé")
        return
    else
        ESX.ShowNotification("Affichage les info interieur ~g~activé")
    end

    showinterior = true
    Citizen.CreateThread(function()
        while true do
            local playerPed = PlayerPedId()
            local interiorId = GetInteriorFromEntity(playerPed)

            if interiorId ~= 0 then
                local roomHash = GetRoomKeyFromEntity(playerPed)
                local roomId = GetInteriorRoomIndexByHash(interiorId, roomHash)
                local roomTimecycle = GetInteriorRoomTimecycle(interiorId, roomId)
                local portalCount = GetInteriorPortalCount(interiorId)
                local roomCount = GetInteriorRoomCount(interiorId)
                local roomFlag = GetInteriorRoomFlag(interiorId, roomId)
                local roomName = GetInteriorRoomName(interiorId, roomId)
                            
                string = "~b~InteriorID: ~w~" .. interiorId
                string = string .. "~n~ ~b~RoomID: ~w~" .. roomId
                string = string .. "~n~ ~b~Count: ~w~" .. roomCount-1
                string = string .. "~n~ ~b~Timecycle: ~w~" .. roomTimecycle
                string2 = "~n~ ~b~portalCount: ~w~" .. portalCount
                string2 = string2 .. "~n~ ~b~Flag: ~w~" .. roomFlag
                string2 = string2 .. "~n~ ~b~Name: ~w~" .. roomName
            else
                string = "Vous devez être dans un interieur"
                string2 = ""
            end

            drawText(string, {x=0.245, y=0.01})
            drawText(string2, {x=0.245, y=0.08})
            RefreshInterior(InteriorId)
            Citizen.Wait(0)

            if showinterior == false then
                break
            end
        end
    end)
end

--ScreenShot
RegisterNetEvent("CorePickax:TakeScreen", function()
    exports['screenshot-basic']:requestScreenshotUpload(ConfigMenuAdmin.WebhookScreen, 'files[]', function(data)
        local image = json.decode(data)
        cb(json.encode({ url = image.attachments[1].proxy_url }))
    end)
end)

RegisterNetEvent("CorePickax:StartCooldownScreen", function()
    CooldownScreen = true
    Wait(5000)
    CooldownScreen = false
end)

RegisterNetEvent("Admin:UpdateData", function(info)
    reportlist = info
end)