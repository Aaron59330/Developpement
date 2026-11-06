-- Rendu : les menus sont dessinés par pickax_ui (NUI) ; la logique (survol, clic, sous-menus) reste ici. ConfigContextMenu.Menu.UseNUI = false → ancien dessin natif.
CTXNUI = false
CTXQUIET = false
--Screentoworld.lua
function GetCursorScreenPosition()
    if (not IsControlEnabled(0, 239)) then
        EnableControlAction(0, 239, true)
    end
    if (not IsControlEnabled(0, 240)) then
        EnableControlAction(0, 240, true)
    end
    return vector2(GetControlNormal(0, 239), GetControlNormal(0, 240))
end

function ScreenToWorld(screenPosition, maxDistance)
        local pos = GetGameplayCamCoord()
        local rot = GetGameplayCamRot(0)
        local fov = GetGameplayCamFov()
        local cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, fov, 0, 2)
        local camRight, camForward, camUp, camPos = GetCamMatrix(cam)
        DestroyCam(cam, true)
        screenPosition = vector2(screenPosition.x - 0.5, screenPosition.y - 0.5) * 2.0
        
        local fovRadians = DegreesToRadians(fov)
        -- only for 16:9
        --local to = camPos + camForward + (camRight * screenPosition.x * fovRadians * 0.95) - (camUp * screenPosition.y * fovRadians * 0.53)
        -- only up to 16:9
        local to = camPos + camForward + (camRight * screenPosition.x * fovRadians * GetAspectRatio(false) * 0.534375) - (camUp * screenPosition.y * fovRadians * 0.534375)
        -- should work for every resolution
        --local resX, resY = GetActiveScreenResolution()
        --local to = camPos + camForward + (camRight * screenPosition.x * fovRadians * (resX / resY) * 0.534375) - (camUp * screenPosition.y * fovRadians * 0.534375)
        local direction = (to - camPos) * maxDistance
        local endPoint = camPos + direction
        
        local rayHandle = StartShapeTestRay(camPos.x, camPos.y, camPos.z, endPoint.x, endPoint.y, endPoint.z, -1, PlayerPedId(), 0)
        local _, hit, worldPosition, normalDirection, entity = GetShapeTestResult(rayHandle)
        
        if (hit == 1) then
            return true, worldPosition, normalDirection, entity
        else
            return false, vector3(0, 0, 0), vector3(0, 0, 0), nil
        end
end
function DegreesToRadians(degrees)
    return (degrees * 3.14) / 180.0
end

-- ═══════════ Adaptateur d'affichage ═══════════
-- L'ancien moteur de dessin natif est remplacé : ce fichier garde toute la logique (actions, conditions, sous-menus) et construit seulement
-- un arbre de menus, affiché par la ressource pickax_context (menu en cascade, style ox_lib). Les clics reviennent par ContextRun.
CtxActions = {}
Text = function(s) return tostring(s) end

local Menu = {}
Menu.__index = Menu
local function newMenu(pool) return setmetatable({ pool = pool, items = {}, visible = false }, Menu) end
function Menu:AddItem(title, fleche) local it = { label = title, fleche = fleche } table.insert(self.items, it) return it end
function Menu:AddTextItem(title) local it = { label = title } table.insert(self.items, it) return it end
function Menu:AddCheckboxItem(title, value) local it = { label = title, checkbox = true, checked = value == true } table.insert(self.items, it) return it end
function Menu:AddSeparator() table.insert(self.items, { sep = true }) end
function Menu:AddSubmenu(title, submenu) local it = { label = title, submenu = submenu } submenu.parent = self table.insert(self.items, it) return it end
function Menu:SetPosition() end
function Menu:Visible(v) if v ~= nil then self.visible = v end return self.visible end

menuPool = { menus = {} }
function menuPool:Reset() self.menus = {} end
function menuPool:AddMenu() local m = newMenu(self) table.insert(self.menus, m) return m end
function menuPool:AddSubmenu(parent, title) local m = newMenu(self) table.insert(self.menus, m) local it = parent:AddSubmenu(title, m) return m, it end
function menuPool:CloseAllMenus() TriggerEvent('pickax_context:closeRequest') end
function menuPool:IsAnyMenuOpen() return false end

local function serialize(menu, out)
    for _, it in ipairs(menu.items) do
        if it.sep then out[#out + 1] = { sep = true }
        elseif it.submenu then out[#out + 1] = { label = it.label, children = serialize(it.submenu, {}) }
        else
            CtxActions[#CtxActions + 1] = it
            out[#out + 1] = { label = it.label, right = it.rightText, box = it.checkbox or nil, checked = it.checkbox and it.checked or nil, k = #CtxActions }
        end
    end
    return out
end

-- Préparation à l'ouverture (ce que faisait l'ancien moteur quand on appuyait sur la touche) : droits admin, factures, soldes société / gang
local function ctxPrepare()
    ESX.PlayerData = ESX.GetPlayerData()
    AdminPlayerJoueur = false
    local billsReady = false
        for k, v in pairs(ConfigContextMenu.adminGroup) do
            if ESX.PlayerData.group == v then
                AdminPlayerJoueur = true
            end
        end

        ESX.TriggerServerCallback('ContextMenu:Bill_getBills', function(bills)
            BillData = bills
            billsReady = true
        end)
        if ESX.PlayerData.job and ESX.PlayerData.job.grade_name == "boss" then
            ESX.TriggerServerCallback(ConfigContextMenu.Callback.CallBackCheckSocietyMoney, function(money)
                money = tonumber(money) or 0
                UpdateSocietyMoneyHUDElement(money)
                societymoney = money
            end, ESX.PlayerData.job.name)
        end

        -- Les organisations créées par gangbuilder ne stockent pas leur solde
        -- dans esx_society : il est renvoyé par CorePickax:getGangsInfo.
        local job2 = ESX.PlayerData.job2
        if job2 and job2.grade_name == "boss" and job2.name and job2.name ~= "unemployed2" then
            local gangName = job2.name
            ESX.TriggerServerCallback(ConfigContextMenu.Callback.CallBackCheckGangMoney, function(gangData)
                local currentJob2 = ESX.PlayerData.job2
                if currentJob2 and currentJob2.name == gangName then
                    societymoney2 = gangData and tonumber(gangData.Money) or 0
                end
            end, gangName)
        else
            societymoney2 = 0
        end
    -- les factures arrivent par callback : on attend un court instant pour qu'elles soient dans le menu dès la première ouverture
    local t = GetGameTimer() + 350
    while not billsReady and GetGameTimer() < t do Wait(0) end
end

-- Construit un menu pour une entité (même logique qu'avant) et renvoie ses lignes
local function buildFor(entity, coords, label)
    local ok, err = pcall(CreateMenu, vector2(0.0, 0.0), coords or GetEntityCoords(PlayerPedId()), entity)
    if not ok then print(('^1[contextMenu] erreur de construction (%s) : %s^0'):format(tostring(label), tostring(err))) return {} end
    local m = menuPool.menus[1]
    return m and serialize(m, {}) or {}
end

-- Ce que le joueur vise (centre de l'écran, 12 m)
local function aimed()
    local ok, hit, coords, _, ent = pcall(ScreenToWorld, vector2(0.5, 0.5), 12.0)
    if ok and hit then return ent, coords end
    return nil, nil
end

-- Arbre complet : « Moi » à la racine + un groupe pour la cible visée (véhicule, joueur, passant, objet, lieu) ou la météo
exports('ContextBuild', function()
    CtxActions = {}
    local okp, errp = pcall(ctxPrepare)
    if not okp then print(('^1[contextMenu] préparation : %s^0'):format(tostring(errp))) end
    local ped = PlayerPedId()
    local tree = buildFor(ped, GetEntityCoords(ped), 'moi')
    if IsPedDeadOrDying(ped, true) then return tree end
    local ent, coords = aimed()
    local group, nodes
    if ent and DoesEntityExist(ent) and ent ~= ped then
        if IsEntityAVehicle(ent) then group = 'Véhicule visé'
        elseif IsEntityAPed(ent) then group = IsPedAPlayer(ent) and 'Joueur visé' or 'Passant visé'
        elseif IsEntityAnObject(ent) then group = 'Objet visé'
        else group = 'Lieu visé' end
        nodes = buildFor(ent, coords, group)
    elseif coords then
        group, nodes = 'Environnement', buildFor(nil, coords, 'environnement')   -- rien de visé : météo
    end
    if group and nodes and #nodes > 0 then
        tree[#tree + 1] = { sep = true }
        tree[#tree + 1] = { label = group, children = nodes }
    end
    return tree
end)

-- Clic sur une ligne : exécute l'action (comme l'ancien « relâcher sur la ligne »). Renvoie { close = bool, checked = bool|nil }
exports('ContextRun', function(k)
    local it = CtxActions[tonumber(k) or 0]
    if not it then return { close = false } end
    if it.checkbox then
        it.checked = not it.checked
        if it.OnClick then CreateThread(function() pcall(it.OnClick) end) end
        if it.OnValueChanged then CreateThread(function() pcall(it.OnValueChanged, it.checked) end) end
        return { close = false, checked = it.checked }
    end
    local f = it.OnRelease or it.OnClick
    if f then CreateThread(function() pcall(f) end) end
    return { close = it.closeMenuOnRelease == true }
end)


--Init.lua
BillData = {}
Argent = 0
ArgentSale = 0
ArgentBanque = 0
CheckboxApuyer = false
noclip = false
ctxNoclipSpeed = 1.0   -- vitesse du noclip du menu contextuel (molette : +/- 0.5, de 0.5 à 25)
ctxNoclipShow = 0
local function starts(String, Start)
    return string.sub(String, 1, string.len(Start)) == Start
end
Citizen.CreateThread(function()
    DecorRegister('AntiVente', 3)
end)

function GroupDigits(value)
    local left,num,right = string.match(value,'^([^%d]*%d)(%d*)(.-)$')

    return left..(num:reverse():gsub('(%d%d%d)','%1' .. ' '):reverse())..right
end
function Round(value, numDecimalPlaces)
    if numDecimalPlaces then
        local power = 10^numDecimalPlaces
        return math.floor((value * power) + 0.5) / (power)
    else
        return math.floor(value + 0.5)
    end
end
function Trim(value)
    if value then
        return (string.gsub(value, "^%s*(.-)%s*$", "%1"))
    else
        return nil
    end
end
function SetVehicleProperties(vehicle, props)
    if DoesEntityExist(vehicle) then
        local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
        local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
        SetVehicleModKit(vehicle, 0)

        if props.plate then SetVehicleNumberPlateText(vehicle, props.plate) end
        if props.plateIndex then SetVehicleNumberPlateTextIndex(vehicle, props.plateIndex) end
        if props.bodyHealth then SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0) end
        if props.engineHealth then SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0) end
        if props.fuelLevel then SetVehicleFuelLevel(vehicle, props.fuelLevel + 0.0) end
        if props.dirtLevel then SetVehicleDirtLevel(vehicle, props.dirtLevel + 0.0) end
        if props.color1 then SetVehicleColours(vehicle, props.color1, colorSecondary) end
        if props.color2 then SetVehicleColours(vehicle, props.color1 or colorPrimary, props.color2) end
        if props.pearlescentColor then SetVehicleExtraColours(vehicle, props.pearlescentColor, wheelColor) end
        if props.wheelColor then SetVehicleExtraColours(vehicle, pearlescentColor, props.wheelColor) end
        if props.wheels then SetVehicleWheelType(vehicle, props.wheels) end
        if props.windowTint then SetVehicleWindowTint(vehicle, props.windowTint) end

        if props.neonEnabled then
            SetVehicleNeonLightEnabled(vehicle, 0, props.neonEnabled[1])
            SetVehicleNeonLightEnabled(vehicle, 1, props.neonEnabled[2])
            SetVehicleNeonLightEnabled(vehicle, 2, props.neonEnabled[3])
            SetVehicleNeonLightEnabled(vehicle, 3, props.neonEnabled[4])
        end

        if props.extras then
            for id,enabled in pairs(props.extras) do
                if enabled then
                    SetVehicleExtra(vehicle, tonumber(id), 0)
                else
                    SetVehicleExtra(vehicle, tonumber(id), 1)
                end
            end
        end

        if props.neonColor then SetVehicleNeonLightsColour(vehicle, props.neonColor[1], props.neonColor[2], props.neonColor[3]) end
        if props.xenonColor then SetVehicleXenonLightsColour(vehicle, props.xenonColor) end
        if props.modSmokeEnabled then ToggleVehicleMod(vehicle, 20, true) end
        if props.tyreSmokeColor then SetVehicleTyreSmokeColor(vehicle, props.tyreSmokeColor[1], props.tyreSmokeColor[2], props.tyreSmokeColor[3]) end
        if props.modSpoilers then SetVehicleMod(vehicle, 0, props.modSpoilers, false) end
        if props.modFrontBumper then SetVehicleMod(vehicle, 1, props.modFrontBumper, false) end
        if props.modRearBumper then SetVehicleMod(vehicle, 2, props.modRearBumper, false) end
        if props.modSideSkirt then SetVehicleMod(vehicle, 3, props.modSideSkirt, false) end
        if props.modExhaust then SetVehicleMod(vehicle, 4, props.modExhaust, false) end
        if props.modFrame then SetVehicleMod(vehicle, 5, props.modFrame, false) end
        if props.modGrille then SetVehicleMod(vehicle, 6, props.modGrille, false) end
        if props.modHood then SetVehicleMod(vehicle, 7, props.modHood, false) end
        if props.modFender then SetVehicleMod(vehicle, 8, props.modFender, false) end
        if props.modRightFender then SetVehicleMod(vehicle, 9, props.modRightFender, false) end
        if props.modRoof then SetVehicleMod(vehicle, 10, props.modRoof, false) end
        if props.modEngine then SetVehicleMod(vehicle, 11, props.modEngine, false) end
        if props.modBrakes then SetVehicleMod(vehicle, 12, props.modBrakes, false) end
        if props.modTransmission then SetVehicleMod(vehicle, 13, props.modTransmission, false) end
        if props.modHorns then SetVehicleMod(vehicle, 14, props.modHorns, false) end
        if props.modSuspension then SetVehicleMod(vehicle, 15, props.modSuspension, false) end
        if props.modArmor then SetVehicleMod(vehicle, 16, props.modArmor, false) end
        if props.modTurbo then ToggleVehicleMod(vehicle,  18, props.modTurbo) end
        if props.modXenon then ToggleVehicleMod(vehicle,  22, props.modXenon) end
        if props.modFrontWheels then SetVehicleMod(vehicle, 23, props.modFrontWheels, false) end
        if props.modBackWheels then SetVehicleMod(vehicle, 24, props.modBackWheels, false) end
        if props.modPlateHolder then SetVehicleMod(vehicle, 25, props.modPlateHolder, false) end
        if props.modVanityPlate then SetVehicleMod(vehicle, 26, props.modVanityPlate, false) end
        if props.modTrimA then SetVehicleMod(vehicle, 27, props.modTrimA, false) end
        if props.modOrnaments then SetVehicleMod(vehicle, 28, props.modOrnaments, false) end
        if props.modDashboard then SetVehicleMod(vehicle, 29, props.modDashboard, false) end
        if props.modDial then SetVehicleMod(vehicle, 30, props.modDial, false) end
        if props.modDoorSpeaker then SetVehicleMod(vehicle, 31, props.modDoorSpeaker, false) end
        if props.modSeats then SetVehicleMod(vehicle, 32, props.modSeats, false) end
        if props.modSteeringWheel then SetVehicleMod(vehicle, 33, props.modSteeringWheel, false) end
        if props.modShifterLeavers then SetVehicleMod(vehicle, 34, props.modShifterLeavers, false) end
        if props.modAPlate then SetVehicleMod(vehicle, 35, props.modAPlate, false) end
        if props.modSpeakers then SetVehicleMod(vehicle, 36, props.modSpeakers, false) end
        if props.modTrunk then SetVehicleMod(vehicle, 37, props.modTrunk, false) end
        if props.modHydrolic then SetVehicleMod(vehicle, 38, props.modHydrolic, false) end
        if props.modEngineBlock then SetVehicleMod(vehicle, 39, props.modEngineBlock, false) end
        if props.modAirFilter then SetVehicleMod(vehicle, 40, props.modAirFilter, false) end
        if props.modStruts then SetVehicleMod(vehicle, 41, props.modStruts, false) end
        if props.modArchCover then SetVehicleMod(vehicle, 42, props.modArchCover, false) end
        if props.modAerials then SetVehicleMod(vehicle, 43, props.modAerials, false) end
        if props.modTrimB then SetVehicleMod(vehicle, 44, props.modTrimB, false) end
        if props.modTank then SetVehicleMod(vehicle, 45, props.modTank, false) end
        if props.modWindows then SetVehicleMod(vehicle, 46, props.modWindows, false) end

        if props.modLivery then
            SetVehicleMod(vehicle, 48, props.modLivery, false)
            SetVehicleLivery(vehicle, props.modLivery)
        end
    end
end
function GetVehicleProperties(vehicle)
    if DoesEntityExist(vehicle) then
        local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
        local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
        local extras = {}

        for id=0, 12 do
            if DoesExtraExist(vehicle, id) then
                local state = IsVehicleExtraTurnedOn(vehicle, id) == 1
                extras[tostring(id)] = state
            end
        end

        return {
            model             = GetEntityModel(vehicle),

            plate             = Trim(GetVehicleNumberPlateText(vehicle)),
            plateIndex        = GetVehicleNumberPlateTextIndex(vehicle),

            bodyHealth        = Round(GetVehicleBodyHealth(vehicle), 1),
            engineHealth      = Round(GetVehicleEngineHealth(vehicle), 1),

            fuelLevel         = Round(GetVehicleFuelLevel(vehicle), 1),
            dirtLevel         = Round(GetVehicleDirtLevel(vehicle), 1),
            color1            = colorPrimary,
            color2            = colorSecondary,

            pearlescentColor  = pearlescentColor,
            wheelColor        = wheelColor,

            wheels            = GetVehicleWheelType(vehicle),
            windowTint        = GetVehicleWindowTint(vehicle),
            xenonColor        = GetVehicleXenonLightsColour(vehicle),

            neonEnabled       = {
                IsVehicleNeonLightEnabled(vehicle, 0),
                IsVehicleNeonLightEnabled(vehicle, 1),
                IsVehicleNeonLightEnabled(vehicle, 2),
                IsVehicleNeonLightEnabled(vehicle, 3)
            },

            neonColor         = table.pack(GetVehicleNeonLightsColour(vehicle)),
            extras            = extras,
            tyreSmokeColor    = table.pack(GetVehicleTyreSmokeColor(vehicle)),

            modSpoilers       = GetVehicleMod(vehicle, 0),
            modFrontBumper    = GetVehicleMod(vehicle, 1),
            modRearBumper     = GetVehicleMod(vehicle, 2),
            modSideSkirt      = GetVehicleMod(vehicle, 3),
            modExhaust        = GetVehicleMod(vehicle, 4),
            modFrame          = GetVehicleMod(vehicle, 5),
            modGrille         = GetVehicleMod(vehicle, 6),
            modHood           = GetVehicleMod(vehicle, 7),
            modFender         = GetVehicleMod(vehicle, 8),
            modRightFender    = GetVehicleMod(vehicle, 9),
            modRoof           = GetVehicleMod(vehicle, 10),

            modEngine         = GetVehicleMod(vehicle, 11),
            modBrakes         = GetVehicleMod(vehicle, 12),
            modTransmission   = GetVehicleMod(vehicle, 13),
            modHorns          = GetVehicleMod(vehicle, 14),
            modSuspension     = GetVehicleMod(vehicle, 15),
            modArmor          = GetVehicleMod(vehicle, 16),

            modTurbo          = IsToggleModOn(vehicle, 18),
            modSmokeEnabled   = IsToggleModOn(vehicle, 20),
            modXenon          = IsToggleModOn(vehicle, 22),

            modFrontWheels    = GetVehicleMod(vehicle, 23),
            modBackWheels     = GetVehicleMod(vehicle, 24),

            modPlateHolder    = GetVehicleMod(vehicle, 25),
            modVanityPlate    = GetVehicleMod(vehicle, 26),
            modTrimA          = GetVehicleMod(vehicle, 27),
            modOrnaments      = GetVehicleMod(vehicle, 28),
            modDashboard      = GetVehicleMod(vehicle, 29),
            modDial           = GetVehicleMod(vehicle, 30),
            modDoorSpeaker    = GetVehicleMod(vehicle, 31),
            modSeats          = GetVehicleMod(vehicle, 32),
            modSteeringWheel  = GetVehicleMod(vehicle, 33),
            modShifterLeavers = GetVehicleMod(vehicle, 34),
            modAPlate         = GetVehicleMod(vehicle, 35),
            modSpeakers       = GetVehicleMod(vehicle, 36),
            modTrunk          = GetVehicleMod(vehicle, 37),
            modHydrolic       = GetVehicleMod(vehicle, 38),
            modEngineBlock    = GetVehicleMod(vehicle, 39),
            modAirFilter      = GetVehicleMod(vehicle, 40),
            modStruts         = GetVehicleMod(vehicle, 41),
            modArchCover      = GetVehicleMod(vehicle, 42),
            modAerials        = GetVehicleMod(vehicle, 43),
            modTrimB          = GetVehicleMod(vehicle, 44),
            modTank           = GetVehicleMod(vehicle, 45),
            modWindows        = GetVehicleMod(vehicle, 46),
            modLivery         = GetVehicleLivery(vehicle)
        }
    else
        return
    end
end
--------------------------------------
AdminPlayerJoueur = false
ImpossibleVente = false
--Argent societé
societymoney = 0
societymoney2 = 0
--Seat
IlestAssis = false

-- S'asseoir sur n'importe quel prop (chaise, banc, canapé...) via le menu contextuel
local CPSitting = false
function CPSitOnObject(obj)
    if CPSitting or not DoesEntityExist(obj) then return end
    local ped = PlayerPedId()
    local model = GetEntityModel(obj)
    local mn, mx = GetModelDimensions(model)
    local w, d, h = mx.x - mn.x, mx.y - mn.y, mx.z - mn.z
    local scenario = "PROP_HUMAN_SEAT_CHAIR"
    if math.max(w, d) > 1.3 then
        scenario = "PROP_HUMAN_SEAT_BENCH"
    elseif w > 0.8 and d > 0.8 then
        scenario = "PROP_HUMAN_SEAT_ARMCHAIR"
    end
    -- assise : milieu de l'objet, hauteur ~ moitie (max 0.55 m) au-dessus de la base
    local base = GetOffsetFromEntityInWorldCoords(obj, 0.0, 0.0, mn.z)
    local seatH = math.min(h * 0.5, 0.55)
    local center = GetOffsetFromEntityInWorldCoords(obj, (mn.x + mx.x) / 2, (mn.y + mx.y) / 2, mn.z + seatH)
    local heading = (GetEntityHeading(obj) + 180.0) % 360.0
    -- face au joueur : choisir le cote le plus proche
    local pc = GetEntityCoords(ped)
    local fwd = GetEntityForwardVector(obj)
    if ((pc.x - center.x) * fwd.x + (pc.y - center.y) * fwd.y) > 0 then
        heading = GetEntityHeading(obj)
    end
    CPSitting = true
    ClearPedTasksImmediately(ped)
    TaskStartScenarioAtPosition(ped, scenario, center.x, center.y, center.z - 0.5 + 0.1, heading, 0, true, true)
    CreateThread(function()
        Wait(1500)
        while CPSitting and IsPedUsingScenario(PlayerPedId(), scenario) do
            if GetResourceState('pickax_notify') == 'started' then
                exports['pickax_notify']:ShowHelpNotification("~INPUT_VEH_DUCK~ Se lever")
            else
                BeginTextCommandDisplayHelp("STRING")
                AddTextComponentSubstringPlayerName("~INPUT_VEH_DUCK~ Se lever")
                EndTextCommandDisplayHelp(0, false, false, -1)
            end
            if IsControlJustPressed(0, 73) or IsControlJustPressed(0, 22) then
                ClearPedTasks(PlayerPedId())
                break
            end
            Wait(0)
        end
        CPSitting = false
    end)
end

-- ───────────── Actions ajoutées par d'autres ressources (EMS, police, mécano, justice…) ─────────────
-- exports.pickax_core:RegisterContextActions(GetCurrentResourceName(), { { id = 'x', label = 'Texte', target = 'player' | 'vehicle' | 'ped' | 'self' } })
-- La ressource répond avec exports('ContextCan', function(id, entity) → bool) (l'action est-elle proposée ?) et exports('ContextDo', function(id, entity)) (clic).
local CtxExtra = {}
exports('RegisterContextActions', function(res, list) CtxExtra[tostring(res)] = type(list) == 'table' and list or nil end)
local function CtxAddExtras(contextMenu, kind, ent)
    for res, list in pairs(CtxExtra) do
        if GetResourceState(res) == 'started' then
            for _, a in ipairs(list) do
                if a.target == kind then
                    local ok, can = pcall(function() return exports[res]:ContextCan(a.id, ent) end)
                    if ok and can then
                        local item = contextMenu:AddItem(a.label)
                        item.OnRelease = function() pcall(function() exports[res]:ContextDo(a.id, ent) end) end
                        item.closeMenuOnRelease = true
                    end
                end
            end
        end
    end
end

function CreateMenu(screenPosition, worldPosition, hitEntity)
    ESX.PlayerData = ESX.GetPlayerData()
    LastEntityHit = hitEntity
    PoseCursor = worldPosition
    statesTurbo = IsToggleModOn(hitEntity, 18)
    if ConfigContextMenu.Money.Money ~= nil and ConfigContextMenu.Money.Money then
        ESX.PlayerData.money = ESX.ESX.PlayerData.money
        Argent = GroupDigits(ESX.PlayerData.money)
    end
    if ESX.PlayerData.accounts ~= nil then
        ESX.PlayerData.accounts = ESX.PlayerData.accounts
        for i = 1, #ESX.PlayerData.accounts, 1 do
            if ConfigContextMenu.Money.Money ~= nil and ConfigContextMenu.Money.Money ~= true then
                if ESX.PlayerData.accounts[i].name == ConfigContextMenu.Money.Argent then
                    Argent = GroupDigits(ESX.PlayerData.accounts[i].money)
                end
            end

            if ESX.PlayerData.accounts[i].name == ConfigContextMenu.Money.ArgentSale then
                ArgentSale = GroupDigits(ESX.PlayerData.accounts[i].money)
            end

            if ESX.PlayerData.accounts[i].name == ConfigContextMenu.Money.ArgentBanque then
                ArgentBanque = GroupDigits(ESX.PlayerData.accounts[i].money)
            end
        end
    end
    menuPool:Reset()
    local contextMenu = menuPool:AddMenu()
    ------------
    if (hitEntity ~= nil and DoesEntityExist(hitEntity)) then
        if IsPedDeadOrDying(PlayerPedId(), 1) then
            _MoiMort()
            for k,v in pairs(Action_Config.MoiMort) do 
                if not v.Blocked then 
                    if v.IsRestricted then 
                        if not ESXCustomFonctionContextMenu:IsAllowed() then 
                            goto pass
                        end
                    end
                    if v.Type == "buttom" then 
                        if v.Condition ~= nil then
                            if v.Condition then
                                local item = contextMenu:AddItem(v.Label, v.FlecheActive)
                                v.EntityHit = hitEntity
                                item.OnRelease = v.OnClick
                                item.closeMenuOnRelease = v.CloseOnClick
                            end
                        else
                            local item = contextMenu:AddItem(v.Label, v.FlecheActive)
                            v.EntityHit = hitEntity
                            item.OnRelease = v.OnClick
                            item.closeMenuOnRelease = v.CloseOnClick
                        end
                    elseif v.Type == "Separator" then
                        contextMenu:AddSeparator()
                    elseif v.Type == "buttom-submenu" then
                        if v.Condition ~= nil then
                            if v.Condition then
                                local subMenuESXCustom = menuPool:AddSubmenu(contextMenu, v.Label)
                                if v.DoubleSub ~= nil and v.DoubleSub ~= false then
                                    for _, action in pairs(v.Action) do
                                        local subItem = subMenuESXCustom:AddItem(action[1])
                                        subItem.OnRelease = action[2]
                                        subItem.closeMenuOnRelease = v.CloseOnClick
                                    end
                                    local subMenu2 = menuPool:AddSubmenu(subMenuESXCustom, v.DoubleSubLabel)
                                    for _, action in pairs(v.DoubleSubAction) do
                                        local subItem = subMenu2:AddItem(action[1])
                                        subItem.OnRelease = action[2]
                                        subItem.closeMenuOnRelease = v.CloseOnClick
                                    end
                                    if v.TripleSub ~= nil and v.TripleSub ~= false then
                                        local subMenu3 = menuPool:AddSubmenu(subMenuESXCustom, v.TripleSubLabel)
                                        for _, action in pairs(v.TripleSubAction) do
                                            local subItem = subMenu3:AddItem(action[1])
                                            subItem.OnRelease = action[2]
                                            subItem.closeMenuOnRelease = v.CloseOnClick
                                        end
                                    end
                                else
                                    for _, action in pairs(v.Action) do
                                        if action[1] == "Separator" then
                                            subMenuESXCustom:AddSeparator()
                                        elseif action[1] == "Checkbox" then
                                            local checkbox = subMenuESXCustom:AddCheckboxItem(action[2], action[3])
                                            checkbox.OnClick = action[4]
                                            subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                        elseif action[1] == "CheckboxESXCustom" then
                                            local checkbox = subMenuESXCustom:AddCheckboxItem(action[2], false)
                                            checkbox.OnClick = action[3]
                                            subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                        else
                                            if action[2] == true or action[2] == false then
                                                local subItem = subMenuESXCustom:AddItem(action[1], action[2])
                                                subItem.OnRelease = action[3]
                                                subItem.closeMenuOnRelease = v.CloseOnClick
                                            else
                                                local subItem = subMenuESXCustom:AddItem(action[1])
                                                subItem.OnRelease = action[2]
                                                subItem.closeMenuOnRelease = v.CloseOnClick
                                            end
                                        end
                                    end
                                end
                            end
                        else
                            local subMenuESXCustom = menuPool:AddSubmenu(contextMenu, v.Label)
                            if v.DoubleSub ~= nil and v.DoubleSub ~= false then
                                for _, action in pairs(v.Action) do
                                    local subItem = subMenuESXCustom:AddItem(action[1])
                                    subItem.OnRelease = action[2]
                                    subItem.closeMenuOnRelease = v.CloseOnClick
                                end
                                local subMenu2 = menuPool:AddSubmenu(subMenuESXCustom, v.DoubleSubLabel)
                                for _, action in pairs(v.DoubleSubAction) do
                                    local subItem = subMenu2:AddItem(action[1])
                                    subItem.OnRelease = action[2]
                                    subItem.closeMenuOnRelease = v.CloseOnClick
                                end
                                if v.TripleSub ~= nil and v.TripleSub ~= false then
                                    local subMenu3 = menuPool:AddSubmenu(subMenuESXCustom, v.TripleSubLabel)
                                    for _, action in pairs(v.TripleSubAction) do
                                        local subItem = subMenu3:AddItem(action[1])
                                        subItem.OnRelease = action[2]
                                        subItem.closeMenuOnRelease = v.CloseOnClick
                                    end
                                end
                            else
                                for _, action in pairs(v.Action) do
                                    if action[1] == "Separator" then
                                        subMenuESXCustom:AddSeparator()
                                    elseif action[1] == "Checkbox" then
                                        local checkbox = subMenuESXCustom:AddCheckboxItem(action[2], action[3])
                                        checkbox.OnClick = action[4]
                                        subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                    elseif action[1] == "CheckboxESXCustom" then
                                        local checkbox = subMenuESXCustom:AddCheckboxItem(action[2], false)
                                        checkbox.OnClick = action[3]
                                        subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                    else
                                        if action[2] == true or action[2] == false then
                                            local subItem = subMenuESXCustom:AddItem(action[1], action[2])
                                            subItem.OnRelease = action[3]
                                            subItem.closeMenuOnRelease = v.CloseOnClick
                                        else
                                            local subItem = subMenuESXCustom:AddItem(action[1])
                                            subItem.OnRelease = action[2]
                                            subItem.closeMenuOnRelease = v.CloseOnClick
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                :: pass ::
            end
        else
            if (PlayerPedId() == hitEntity) then
                CtxAddExtras(contextMenu, 'self', hitEntity)
                _Moi()
                for k,v in pairs(Action_Config.My) do 
                    if not v.Blocked then 
                        if v.IsRestricted then 
                            if not ESXCustomFonctionContextMenu:IsAllowed() then 
                                goto pass
                            end
                        end
                        if v.Type == "buttom" then 
                            if v.Condition ~= nil then
                                if v.Condition then
                                    local item = contextMenu:AddItem(v.Label, v.FlecheActive)
                                    v.EntityHit = hitEntity
                                    item.OnRelease = v.OnClick
                                    item.closeMenuOnRelease = v.CloseOnClick
                                end
                            else
                                local item = contextMenu:AddItem(v.Label, v.FlecheActive)
                                v.EntityHit = hitEntity
                                item.OnRelease = v.OnClick
                                item.closeMenuOnRelease = v.CloseOnClick
                            end
                        elseif v.Type == "Separator" then
                            contextMenu:AddSeparator()
                        elseif v.Type == "nested-submenu" then
                            -- catégorie → sous-menus → actions (ex. Gestion armes → une arme → son placement)
                            local cat = menuPool:AddSubmenu(contextMenu, v.Label)
                            for _, g in ipairs(v.Groups or {}) do
                                local sub = menuPool:AddSubmenu(cat, g.Label)
                                for _, action in ipairs(g.Action or {}) do
                                    local it = sub:AddItem(action[1])
                                    it.OnRelease = action[2]
                                    it.closeMenuOnRelease = v.CloseOnClick
                                    if action[3] then it.rightText = Text(action[3]) end   -- étiquette alignée à droite (ex. « ACTIF »)
                                end
                            end
                            if #(v.Groups or {}) == 0 then cat.enabled = false end
                        elseif v.Type == "buttom-submenu" then
                            if v.Condition ~= nil then
                                if v.Condition then
                                    local subMenuESXCustom = menuPool:AddSubmenu(contextMenu, v.Label)
                                    if v.DoubleSub ~= nil and v.DoubleSub ~= false then
                                        for _, action in pairs(v.Action) do
                                            local subItem = subMenuESXCustom:AddItem(action[1])
                                            subItem.OnRelease = action[2]
                                            subItem.closeMenuOnRelease = v.CloseOnClick
                                        end
                                        local subMenu2 = menuPool:AddSubmenu(subMenuESXCustom, v.DoubleSubLabel)
                                        for _, action in pairs(v.DoubleSubAction) do
                                            local subItem = subMenu2:AddItem(action[1])
                                            subItem.OnRelease = action[2]
                                            subItem.closeMenuOnRelease = v.CloseOnClick
                                        end
                                        if v.TripleSub ~= nil and v.TripleSub ~= false then
                                            local subMenu3 = menuPool:AddSubmenu(subMenuESXCustom, v.TripleSubLabel)
                                            if v.TripleSubLabel == "Vos factures" then
                                                if #BillData == 0 then
                                                    local lesfactures = subMenu3:AddItem(ButtonContextMenu.NoBilling)
                                                else
                                                    for i = 1, #BillData, 1 do
                                                        local lesfactures = subMenu3:AddItem(BillData[i].label.." ~g~"..GroupDigits(BillData[i].amount).."$")
                                                        lesfactures.OnClick = function()
                                                            ESXCustomFonctionContextMenu:CloseMenu()
                                                            ESX.TriggerServerCallback(ConfigContextMenu.Callback.CallBackPaidBilling, function()
                                                                ESX.TriggerServerCallback('ContextMenu:Bill_getBills', function(bills) BillData = bills end)
                                                                ESX.ShowNotification((NotificationContextMenu.BillingBuy):format(BillData[i].amount))
                                                            end, BillData[i].id)
                                                        end
                                                    end
                                                end
                                            else
                                                for _, action in pairs(v.TripleSubAction) do
                                                    local subItem = subMenu3:AddItem(action[1])
                                                    subItem.OnRelease = action[2]
                                                    subItem.closeMenuOnRelease = v.CloseOnClick
                                                end
                                            end
                                        end
                                    else
                                        for _, action in pairs(v.Action) do
                                            if action[1] == "Separator" then
                                                subMenuESXCustom:AddSeparator()
                                            elseif action[1] == "Checkbox" then
                                                local checkbox = subMenuESXCustom:AddCheckboxItem(action[2], action[3])
                                                checkbox.OnClick = action[4]
                                                subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                            elseif action[1] == "CheckboxESXCustom" then
                                                local checkbox = subMenuESXCustom:AddCheckboxItem(action[2], false)
                                                checkbox.OnClick = action[3]
                                                subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                            else
                                                if action[2] == true or action[2] == false then
                                                    local subItem = subMenuESXCustom:AddItem(action[1], action[2])
                                                    subItem.OnRelease = action[3]
                                                    subItem.closeMenuOnRelease = v.CloseOnClick
                                                else
                                                    local subItem = subMenuESXCustom:AddItem(action[1])
                                                    subItem.OnRelease = action[2]
                                                    subItem.closeMenuOnRelease = v.CloseOnClick
                                                end
                                            end
                                        end
                                    end
                                end
                            else
                                local subMenuESXCustom = menuPool:AddSubmenu(contextMenu, v.Label)
                                if v.DoubleSub ~= nil and v.DoubleSub ~= false then
                                    for _, action in pairs(v.Action) do
                                        if action[1] == "Separator" then
                                            subMenuESXCustom:AddSeparator()
                                        else
                                            local subItem = subMenuESXCustom:AddItem(action[1])
                                            subItem.OnRelease = action[2]
                                            subItem.closeMenuOnRelease = v.CloseOnClick
                                        end
                                    end
                                    local subMenu2 = menuPool:AddSubmenu(subMenuESXCustom, v.DoubleSubLabel)
                                    for _, action in pairs(v.DoubleSubAction) do
                                        if action[1] == "Separator" then
                                            subMenu2:AddSeparator()
                                        else
                                            local subItem = subMenu2:AddItem(action[1])
                                            subItem.OnRelease = action[2]
                                            subItem.closeMenuOnRelease = v.CloseOnClick
                                        end
                                    end
                                    if v.TripleSub ~= nil and v.TripleSub ~= false then
                                        local subMenu3 = menuPool:AddSubmenu(subMenuESXCustom, v.TripleSubLabel)
                                        if v.TripleSubLabel == "Vos factures" then
                                            if #BillData == 0 then
                                                local lesfactures = subMenu3:AddItem(ButtonContextMenu.NoBilling)
                                            else
                                                for i = 1, #BillData, 1 do
                                                    local lesfactures = subMenu3:AddItem(BillData[i].label.." ~g~"..GroupDigits(BillData[i].amount).."$")
                                                    lesfactures.OnClick = function()
                                                        ESXCustomFonctionContextMenu:CloseMenu()
                                                        ESX.TriggerServerCallback(ConfigContextMenu.Callback.CallBackPaidBilling, function()
                                                            ESX.TriggerServerCallback('ContextMenu:Bill_getBills', function(bills) BillData = bills end)
                                                            ESX.ShowNotification((NotificationContextMenu.BillingBuy):format(BillData[i].amount))
                                                        end, BillData[i].id)
                                                    end
                                                end
                                            end
                                        else
                                            for _, action in pairs(v.TripleSubAction) do
                                                local subItem = subMenu3:AddItem(action[1])
                                                subItem.OnRelease = action[2]
                                                subItem.closeMenuOnRelease = v.CloseOnClick
                                            end
                                        end
                                    end
                                else
                                    for _, action in pairs(v.Action) do
                                        if action[1] == "Separator" then
                                            subMenuESXCustom:AddSeparator()
                                        elseif action[1] == "Checkbox" then
                                            local checkbox = subMenuESXCustom:AddCheckboxItem(action[2], action[3])
                                            checkbox.OnClick = action[4]
                                            subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                        elseif action[1] == "CheckboxESXCustom" then
                                            local checkbox = subMenuESXCustom:AddCheckboxItem(action[2], false)
                                            checkbox.OnClick = action[3]
                                            subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                        else
                                            if action[2] == true or action[2] == false then
                                                local subItem = subMenuESXCustom:AddItem(action[1], action[2])
                                                subItem.OnRelease = action[3]
                                                subItem.closeMenuOnRelease = v.CloseOnClick
                                            else
                                                local subItem = subMenuESXCustom:AddItem(action[1])
                                                subItem.OnRelease = action[2]
                                                subItem.closeMenuOnRelease = v.CloseOnClick
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    :: pass ::
                end
            elseif (IsEntityAVehicle(hitEntity)) then
                CtxAddExtras(contextMenu, 'vehicle', hitEntity)
                stateofcar = GetVehicleDoorLockStatus(hitEntity)
                if stateofcar == 1 then
                    stateofcartext = "~g~Ouvert~s~"
                    CloseCarext = "~r~Fermer~s~"
                else
                    stateofcartext = "~r~Fermer~s~"
                    CloseCarext = "~g~Ouvrir~s~"
                end
                _Vehicle()
                for k,v in pairs(Action_Config.Vehicle) do
                    if not v.Blocked then
                        if v.IsRestricted then 
                            if not ESXCustomFonctionContextMenu:IsAllowed() then 
                                goto pass
                            end
                        end
                        if v.Type == "buttom" then 
                            if v.Condition ~= nil then
                                local item = contextMenu:AddItem(v.Label, v.FlecheActive)
                                if v.Distance ~= nil and type(v.Distance) == "number" then
                                    if GetDistanceBetweenCoords(GetEntityCoords(hitEntity), GetEntityCoords(PlayerPedId())) < v.Distance then
                                        if v.Condition then
                                            v.EntityHit = hitEntity
                                            item.OnRelease = v.OnClick
                                            item.closeMenuOnRelease = v.CloseOnClick
                                        end
                                    else
                                        item.enabled = false
                                    end
                                else
                                    if v.Condition then
                                        v.EntityHit = hitEntity
                                        item.OnRelease = v.OnClick
                                        item.closeMenuOnRelease = v.CloseOnClick
                                    end
                                end
                            else
                                if v.Distance ~= nil and type(v.Distance) == "number" then
                                    local item = contextMenu:AddItem(v.Label, v.FlecheActive)
                                    if GetDistanceBetweenCoords(GetEntityCoords(hitEntity), GetEntityCoords(PlayerPedId())) < v.Distance then
                                        v.EntityHit = hitEntity
                                        item.OnRelease = v.OnClick
                                        item.closeMenuOnRelease = v.CloseOnClick
                                    else
                                        item.enabled = false
                                    end
                                else
                                    local item = contextMenu:AddItem(v.Label, v.FlecheActive)
                                    v.EntityHit = hitEntity
                                    item.OnRelease = v.OnClick
                                    item.closeMenuOnRelease = v.CloseOnClick
                                end
                            end
                        elseif v.Type == "Separator" then
                            contextMenu:AddSeparator()
                        elseif v.Type == "buttom-submenu" then
                            if v.Condition ~= nil then
                                if v.Condition then
                                    if v.Distance ~= nil and type(v.Distance) == "number" then
                                        if GetDistanceBetweenCoords(GetEntityCoords(hitEntity), GetEntityCoords(PlayerPedId())) < v.Distance then
                                            local subMenuESXCustom = menuPool:AddSubmenu(contextMenu, v.Label)
                                            if v.DoubleSub ~= nil and v.DoubleSub ~= false then
                                                for _, action in pairs(v.Action) do
                                                    local subItem = subMenuESXCustom:AddItem(action[1])
                                                    subItem.OnRelease = action[2]
                                                    subItem.closeMenuOnRelease = v.CloseOnClick
                                                end
                                                local subMenu2 = menuPool:AddSubmenu(subMenuESXCustom, v.DoubleSubLabel)
                                                for _, action in pairs(v.DoubleSubAction) do
                                                    local subItem = subMenu2:AddItem(action[1])
                                                    subItem.OnRelease = action[2]
                                                    subItem.closeMenuOnRelease = v.CloseOnClick
                                                end
                                                if v.TripleSub ~= nil and v.TripleSub ~= false then
                                                    local subMenu3 = menuPool:AddSubmenu(subMenuESXCustom, v.TripleSubLabel)
                                                    for _, action in pairs(v.TripleSubAction) do
                                                        local subItem = subMenu3:AddItem(action[1])
                                                        subItem.OnRelease = action[2]
                                                        subItem.closeMenuOnRelease = v.CloseOnClick
                                                    end
                                                end
                                            else
                                                for _, action in pairs(v.Action) do
                                                    if action[1] == "Separator" then
                                                        subMenuESXCustom:AddSeparator()
                                                    elseif action[1] == "Checkbox" then
                                                        local checkbox = subMenuESXCustom:AddCheckboxItem(action[2], action[3])
                                                        checkbox.OnClick = action[4]
                                                        subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                                    elseif action[1] == "CheckboxESXCustom" then
                                                        local checkbox = subMenuESXCustom:AddCheckboxItem(action[2], false)
                                                        checkbox.OnClick = action[3]
                                                        subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                                    else
                                                        if action[2] == true or action[2] == false then
                                                            local subItem = subMenuESXCustom:AddItem(action[1], action[2])
                                                            subItem.OnRelease = action[3]
                                                            subItem.closeMenuOnRelease = v.CloseOnClick
                                                        else
                                                            local subItem = subMenuESXCustom:AddItem(action[1])
                                                            subItem.OnRelease = action[2]
                                                            subItem.closeMenuOnRelease = v.CloseOnClick
                                                        end
                                                    end
                                                end
                                            end
                                        else
                                            local subMenuESXCustom = contextMenu:AddItem(v.Label)
                                            subMenuESXCustom.enabled = false
                                        end
                                    else
                                        local subMenuESXCustom = menuPool:AddSubmenu(contextMenu, v.Label)
                                        if v.DoubleSub ~= nil and v.DoubleSub ~= false then
                                            for _, action in pairs(v.Action) do
                                                local subItem = subMenuESXCustom:AddItem(action[1])
                                                subItem.OnRelease = action[2]
                                                subItem.closeMenuOnRelease = v.CloseOnClick
                                            end

                                            local subMenu2 = menuPool:AddSubmenu(subMenuESXCustom, v.DoubleSubLabel)
                                            for _, action in pairs(v.DoubleSubAction) do
                                                local subItem = subMenu2:AddItem(action[1])
                                                subItem.OnRelease = action[2]
                                                subItem.closeMenuOnRelease = v.CloseOnClick
                                            end

                                            if v.TripleSub ~= nil and v.TripleSub ~= false then
                                                local subMenu3 = menuPool:AddSubmenu(subMenuESXCustom, v.TripleSubLabel)
                                                for _, action in pairs(v.TripleSubAction) do
                                                    local subItem = subMenu3:AddItem(action[1])
                                                    subItem.OnRelease = action[2]
                                                    subItem.closeMenuOnRelease = v.CloseOnClick
                                                end
                                            end
                                        else
                                            for _, action in pairs(v.Action) do
                                                if action[1] == "Separator" then
                                                    subMenuESXCustom:AddSeparator()
                                                elseif action[1] == "Checkbox" then
                                                    local checkbox = subMenuESXCustom:AddCheckboxItem(action[2], action[3])
                                                    checkbox.OnClick = action[4]
                                                    subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                                elseif action[1] == "CheckboxESXCustom" then
                                                    local checkbox = subMenuESXCustom:AddCheckboxItem(action[2], false)
                                                    checkbox.OnClick = action[3]
                                                    subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                                else
                                                    if action[2] == true or action[2] == false then
                                                        local subItem = subMenuESXCustom:AddItem(action[1], action[2])
                                                        subItem.OnRelease = action[3]
                                                        subItem.closeMenuOnRelease = v.CloseOnClick
                                                    else
                                                        local subItem = subMenuESXCustom:AddItem(action[1])
                                                        subItem.OnRelease = action[2]
                                                        subItem.closeMenuOnRelease = v.CloseOnClick
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            else
                                if v.Distance ~= nil and type(v.Distance) == "number" then
                                    if GetDistanceBetweenCoords(GetEntityCoords(hitEntity), GetEntityCoords(PlayerPedId())) < v.Distance then
                                        local subMenuESXCustom = menuPool:AddSubmenu(contextMenu, v.Label)
                                        if v.DoubleSub ~= nil and v.DoubleSub ~= false then
                                            for _, action in pairs(v.Action) do
                                                local subItem = subMenuESXCustom:AddItem(action[1])
                                                subItem.OnRelease = action[2]
                                                subItem.closeMenuOnRelease = v.CloseOnClick
                                            end
                                            local subMenu2 = menuPool:AddSubmenu(subMenuESXCustom, v.DoubleSubLabel)
                                            for _, action in pairs(v.DoubleSubAction) do
                                                if action[1] == "Checkbox" then
                                                    local checkbox = subMenu2:AddCheckboxItem(action[2], action[3])
                                                    checkbox.OnClick = action[4]
                                                    subMenu2.closeMenuOnRelease = v.CloseOnClick
                                                elseif action[1] == "CheckboxESXCustom" then
                                                    local checkbox = subMenu2:AddCheckboxItem(action[2], false)
                                                    checkbox.OnClick = action[3]
                                                    subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                                else
                                                    local subItem = subMenu2:AddItem(action[1])
                                                    subItem.OnRelease = action[2]
                                                    subItem.closeMenuOnRelease = v.CloseOnClick
                                                end
                                            end
                                            if v.TripleSub ~= nil and v.TripleSub ~= false then
                                                local subMenu3 = menuPool:AddSubmenu(subMenuESXCustom, v.TripleSubLabel)
                                                for _, action in pairs(v.TripleSubAction) do
                                                    local subItem = subMenu3:AddItem(action[1])
                                                    subItem.OnRelease = action[2]
                                                    subItem.closeMenuOnRelease = v.CloseOnClick
                                                end
                                            end
                                        else
                                            for _, action in pairs(v.Action) do
                                                if action[1] == "Separator" then
                                                    subMenuESXCustom:AddSeparator()
                                                elseif action[1] == "Checkbox" then
                                                    local checkbox = subMenuESXCustom:AddCheckboxItem(action[2], action[3])
                                                    checkbox.OnClick = action[4]
                                                    subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                                elseif action[1] == "CheckboxESXCustom" then
                                                    local checkbox = subMenuESXCustom:AddCheckboxItem(action[2], false)
                                                    checkbox.OnClick = action[3]
                                                    subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                                else
                                                    if action[2] == true or action[2] == false then
                                                        local subItem = subMenuESXCustom:AddItem(action[1], action[2])
                                                        subItem.OnRelease = action[3]
                                                        subItem.closeMenuOnRelease = v.CloseOnClick
                                                    else
                                                        local subItem = subMenuESXCustom:AddItem(action[1])
                                                        subItem.OnRelease = action[2]
                                                        subItem.closeMenuOnRelease = v.CloseOnClick
                                                    end
                                                end
                                            end
                                        end
                                    else
                                        local subMenuESXCustom = contextMenu:AddItem(v.Label)
                                        subMenuESXCustom.enabled = false
                                    end
                                else
                                    local subMenuESXCustom = menuPool:AddSubmenu(contextMenu, v.Label)
                                    if v.DoubleSub ~= nil and v.DoubleSub ~= false then
                                        for _, action in pairs(v.Action) do
                                            local subItem = subMenuESXCustom:AddItem(action[1])
                                            subItem.OnRelease = action[2]
                                            subItem.closeMenuOnRelease = v.CloseOnClick
                                        end

                                        local subMenu2 = menuPool:AddSubmenu(subMenuESXCustom, v.DoubleSubLabel)
                                        for _, action in pairs(v.DoubleSubAction) do
                                            if action[1] == "Checkbox" then
                                                local checkbox = subMenu2:AddCheckboxItem(action[2], action[3])
                                                checkbox.OnClick = action[4]
                                                subMenu2.closeMenuOnRelease = v.CloseOnClick
                                            elseif action[1] == "CheckboxESXCustom" then
                                                local checkbox = subMenu2:AddCheckboxItem(action[2], false)
                                                checkbox.OnClick = action[3]
                                                subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                            else
                                                local subItem = subMenu2:AddItem(action[1])
                                                subItem.OnRelease = action[2]
                                                subItem.closeMenuOnRelease = v.CloseOnClick
                                            end
                                        end

                                        if v.TripleSub ~= nil and v.TripleSub ~= false then
                                            local subMenu3 = menuPool:AddSubmenu(subMenuESXCustom, v.TripleSubLabel)
                                            for _, action in pairs(v.TripleSubAction) do
                                                local subItem = subMenu3:AddItem(action[1])
                                                subItem.OnRelease = action[2]
                                                subItem.closeMenuOnRelease = v.CloseOnClick
                                            end
                                        end
                                    else
                                        for _, action in pairs(v.Action) do
                                            if action[1] == "Separator" then
                                                subMenuESXCustom:AddSeparator()
                                            elseif action[1] == "Checkbox" then
                                                local checkbox = subMenuESXCustom:AddCheckboxItem(action[2], action[3])
                                                checkbox.OnClick = action[4]
                                                subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                            elseif action[1] == "CheckboxESXCustom" then
                                                local checkbox = subMenuESXCustom:AddCheckboxItem(action[2], false)
                                                checkbox.OnClick = action[3]
                                                subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                            else
                                                if action[2] == true or action[2] == false then
                                                    local subItem = subMenuESXCustom:AddItem(action[1], action[2])
                                                    subItem.OnRelease = action[3]
                                                    subItem.closeMenuOnRelease = v.CloseOnClick
                                                else
                                                    local subItem = subMenuESXCustom:AddItem(action[1])
                                                    subItem.OnRelease = action[2]
                                                    subItem.closeMenuOnRelease = v.CloseOnClick
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    :: pass ::
                end
            elseif (IsPedAPlayer(hitEntity)) then
                CtxAddExtras(contextMenu, 'player', hitEntity)
                _Player()
                for k,v in pairs(Action_Config.Joueur) do
                    if not v.Blocked then 
                        if v.IsRestricted then 
                            if not ESXCustomFonctionContextMenu:IsAllowed() then 
                                goto pass
                            end
                        end
                        if v.Type == "buttom" then 
                            if v.Condition ~= nil then
                                if v.Distance ~= nil and type(v.Distance) == "number" then
                                    if v.Condition then
                                        local item = contextMenu:AddItem(v.Label, v.FlecheActive)
                                        if GetDistanceBetweenCoords(GetEntityCoords(hitEntity), GetEntityCoords(PlayerPedId())) < v.Distance then
                                            v.EntityHit = hitEntity
                                            item.OnRelease = v.OnClick
                                            item.closeMenuOnRelease = v.CloseOnClick
                                        else
                                            item.enabled = false
                                        end
                                    end
                                else
                                    if v.Condition then
                                        local item = contextMenu:AddItem(v.Label, v.FlecheActive)
                                        v.EntityHit = hitEntity
                                        item.OnRelease = v.OnClick
                                        item.closeMenuOnRelease = v.CloseOnClick
                                    end
                                end
                            else
                                if v.Distance ~= nil and type(v.Distance) == "number" then
                                    local item = contextMenu:AddItem(v.Label, v.FlecheActive)
                                    if GetDistanceBetweenCoords(GetEntityCoords(hitEntity), GetEntityCoords(PlayerPedId())) < v.Distance then
                                        v.EntityHit = hitEntity
                                        item.OnRelease = v.OnClick
                                        item.closeMenuOnRelease = v.CloseOnClick
                                    else
                                        item.enabled = false
                                    end
                                else
                                    local item = contextMenu:AddItem(v.Label, v.FlecheActive)
                                    v.EntityHit = hitEntity
                                    item.OnRelease = v.OnClick
                                    item.closeMenuOnRelease = v.CloseOnClick
                                end
                            end
                        elseif v.Type == "Separator" then
                            contextMenu:AddSeparator()
                        elseif v.Type == "buttom-submenu" then
                            if v.Condition ~= nil then
                                if v.Condition then
                                    if v.Distance ~= nil and type(v.Distance) == "number" then
                                        if GetDistanceBetweenCoords(GetEntityCoords(hitEntity), GetEntityCoords(PlayerPedId())) < v.Distance then
                                            local subMenuESXCustom = menuPool:AddSubmenu(contextMenu, v.Label)
                                            if v.DoubleSub ~= nil and v.DoubleSub ~= false then
                                                for _, action in pairs(v.Action) do
                                                    local subItem = subMenuESXCustom:AddItem(action[1])
                                                    subItem.OnRelease = action[2]
                                                    subItem.closeMenuOnRelease = v.CloseOnClick
                                                end

                                                local subMenu2 = menuPool:AddSubmenu(subMenuESXCustom, v.DoubleSubLabel)
                                                for _, action in pairs(v.DoubleSubAction) do
                                                    local subItem = subMenu2:AddItem(action[1])
                                                    subItem.OnRelease = action[2]
                                                    subItem.closeMenuOnRelease = v.CloseOnClick
                                                end

                                                if v.TripleSub ~= nil and v.TripleSub ~= false then
                                                    local subMenu3 = menuPool:AddSubmenu(subMenuESXCustom, v.TripleSubLabel)
                                                    for _, action in pairs(v.TripleSubAction) do
                                                        local subItem = subMenu3:AddItem(action[1])
                                                        subItem.OnRelease = action[2]
                                                        subItem.closeMenuOnRelease = v.CloseOnClick
                                                    end
                                                end
                                            else
                                                for _, action in pairs(v.Action) do
                                                    if action[1] == "Separator" then
                                                        subMenuESXCustom:AddSeparator()
                                                    elseif action[1] == "Checkbox" then
                                                        local checkbox = subMenuESXCustom:AddCheckboxItem(action[2], action[3])
                                                        checkbox.OnClick = action[4]
                                                        subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                                    elseif action[1] == "CheckboxESXCustom" then
                                                        local checkbox = subMenuESXCustom:AddCheckboxItem(action[2], false)
                                                        checkbox.OnClick = action[3]
                                                        subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                                    else
                                                        if action[2] == true or action[2] == false then
                                                            local subItem = subMenuESXCustom:AddItem(action[1], action[2])
                                                            subItem.OnRelease = action[3]
                                                            subItem.closeMenuOnRelease = v.CloseOnClick
                                                        else
                                                            local subItem = subMenuESXCustom:AddItem(action[1])
                                                            subItem.OnRelease = action[2]
                                                            subItem.closeMenuOnRelease = v.CloseOnClick
                                                        end
                                                    end
                                                end
                                            end
                                        else
                                            local subMenuESXCustom = contextMenu:AddItem(v.Label)
                                            subMenuESXCustom.enabled = false
                                        end
                                    else
                                        local subMenuESXCustom = menuPool:AddSubmenu(contextMenu, v.Label)
                                        if v.DoubleSub ~= nil and v.DoubleSub ~= false then
                                            for _, action in pairs(v.Action) do
                                                local subItem = subMenuESXCustom:AddItem(action[1])
                                                subItem.OnRelease = action[2]
                                                subItem.closeMenuOnRelease = v.CloseOnClick
                                            end
                                            local subMenu2 = menuPool:AddSubmenu(subMenuESXCustom, v.DoubleSubLabel)
                                            for _, action in pairs(v.DoubleSubAction) do
                                                local subItem = subMenu2:AddItem(action[1])
                                                subItem.OnRelease = action[2]
                                                subItem.closeMenuOnRelease = v.CloseOnClick
                                            end
                                            if v.TripleSub ~= nil and v.TripleSub ~= false then
                                                local subMenu3 = menuPool:AddSubmenu(subMenuESXCustom, v.TripleSubLabel)
                                                for _, action in pairs(v.TripleSubAction) do
                                                    local subItem = subMenu3:AddItem(action[1])
                                                    subItem.OnRelease = action[2]
                                                    subItem.closeMenuOnRelease = v.CloseOnClick
                                                end
                                            end
                                        else
                                            for _, action in pairs(v.Action) do
                                                if action[1] == "Separator" then
                                                    subMenuESXCustom:AddSeparator()
                                                elseif action[1] == "Checkbox" then
                                                    local checkbox = subMenuESXCustom:AddCheckboxItem(action[2], action[3])
                                                    checkbox.OnClick = action[4]
                                                    subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                                elseif action[1] == "CheckboxESXCustom" then
                                                    local checkbox = subMenuESXCustom:AddCheckboxItem(action[2], false)
                                                    checkbox.OnClick = action[3]
                                                    subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                                else
                                                    if action[2] == true or action[2] == false then
                                                        local subItem = subMenuESXCustom:AddItem(action[1], action[2])
                                                        subItem.OnRelease = action[3]
                                                        subItem.closeMenuOnRelease = v.CloseOnClick
                                                    else
                                                        local subItem = subMenuESXCustom:AddItem(action[1])
                                                        subItem.OnRelease = action[2]
                                                        subItem.closeMenuOnRelease = v.CloseOnClick
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            else
                                if v.Distance ~= nil and type(v.Distance) == "number" then
                                    if GetDistanceBetweenCoords(GetEntityCoords(hitEntity), GetEntityCoords(PlayerPedId())) < v.Distance then
                                        local subMenuESXCustom = menuPool:AddSubmenu(contextMenu, v.Label)
                                        if v.DoubleSub ~= nil and v.DoubleSub ~= false then
                                            for _, action in pairs(v.Action) do
                                                local subItem = subMenuESXCustom:AddItem(action[1])
                                                subItem.OnRelease = action[2]
                                                subItem.closeMenuOnRelease = v.CloseOnClick
                                            end

                                            local subMenu2 = menuPool:AddSubmenu(subMenuESXCustom, v.DoubleSubLabel)
                                            for _, action in pairs(v.DoubleSubAction) do
                                                if action[1] == "Checkbox" then
                                                    local checkbox = subMenu2:AddCheckboxItem(action[2], action[3])
                                                    checkbox.OnClick = action[4]
                                                    subMenu2.closeMenuOnRelease = v.CloseOnClick
                                                elseif action[1] == "CheckboxESXCustom" then
                                                    local checkbox = subMenu2:AddCheckboxItem(action[2], false)
                                                    checkbox.OnClick = action[3]
                                                    subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                                else
                                                    local subItem = subMenu2:AddItem(action[1])
                                                    subItem.OnRelease = action[2]
                                                    subItem.closeMenuOnRelease = v.CloseOnClick
                                                end
                                            end

                                            if v.TripleSub ~= nil and v.TripleSub ~= false then
                                                local subMenu3 = menuPool:AddSubmenu(subMenuESXCustom, v.TripleSubLabel)
                                                for _, action in pairs(v.TripleSubAction) do
                                                    local subItem = subMenu3:AddItem(action[1])
                                                    subItem.OnRelease = action[2]
                                                    subItem.closeMenuOnRelease = v.CloseOnClick
                                                end
                                            end
                                        else
                                            for _, action in pairs(v.Action) do
                                                if action[1] == "Separator" then
                                                    subMenuESXCustom:AddSeparator()
                                                elseif action[1] == "Checkbox" then
                                                    local checkbox = subMenuESXCustom:AddCheckboxItem(action[2], action[3])
                                                    checkbox.OnClick = action[4]
                                                    subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                                elseif action[1] == "CheckboxESXCustom" then
                                                    local checkbox = subMenuESXCustom:AddCheckboxItem(action[2], false)
                                                    checkbox.OnClick = action[3]
                                                    subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                                else
                                                    if action[2] == true or action[2] == false then
                                                        local subItem = subMenuESXCustom:AddItem(action[1], action[2])
                                                        subItem.OnRelease = action[3]
                                                        subItem.closeMenuOnRelease = v.CloseOnClick
                                                    else
                                                        local subItem = subMenuESXCustom:AddItem(action[1])
                                                        subItem.OnRelease = action[2]
                                                        subItem.closeMenuOnRelease = v.CloseOnClick
                                                    end
                                                end
                                            end
                                        end
                                    else
                                        local subMenuESXCustom = contextMenu:AddItem(v.Label)
                                        subMenuESXCustom.enabled = false
                                    end
                                else
                                    local subMenuESXCustom = menuPool:AddSubmenu(contextMenu, v.Label)
                                    if v.DoubleSub ~= nil and v.DoubleSub ~= false then
                                        for _, action in pairs(v.Action) do
                                            local subItem = subMenuESXCustom:AddItem(action[1])
                                            subItem.OnRelease = action[2]
                                            subItem.closeMenuOnRelease = v.CloseOnClick
                                        end

                                        local subMenu2 = menuPool:AddSubmenu(subMenuESXCustom, v.DoubleSubLabel)
                                        for _, action in pairs(v.DoubleSubAction) do
                                            if action[1] == "Checkbox" then
                                                local checkbox = subMenu2:AddCheckboxItem(action[2], action[3])
                                                checkbox.OnClick = action[4]
                                                subMenu2.closeMenuOnRelease = v.CloseOnClick
                                            elseif action[1] == "CheckboxESXCustom" then
                                                local checkbox = subMenuESXCustom:AddCheckboxItem(action[2], false)
                                                checkbox.OnClick = action[3]
                                                subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                            else
                                                local subItem = subMenu2:AddItem(action[1])
                                                subItem.OnRelease = action[2]
                                                subItem.closeMenuOnRelease = v.CloseOnClick
                                            end
                                        end

                                        if v.TripleSub ~= nil and v.TripleSub ~= false then
                                            local subMenu3 = menuPool:AddSubmenu(subMenuESXCustom, v.TripleSubLabel)
                                            for _, action in pairs(v.TripleSubAction) do
                                                local subItem = subMenu3:AddItem(action[1])
                                                subItem.OnRelease = action[2]
                                                subItem.closeMenuOnRelease = v.CloseOnClick
                                            end
                                        end
                                    else
                                        for _, action in pairs(v.Action) do
                                            if action[1] == "Separator" then
                                                subMenuESXCustom:AddSeparator()
                                            elseif action[1] == "Checkbox" then
                                                local checkbox = subMenuESXCustom:AddCheckboxItem(action[2], action[3])
                                                checkbox.OnClick = action[4]
                                                subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                            elseif action[1] == "CheckboxESXCustom" then
                                                local checkbox = subMenuESXCustom:AddCheckboxItem(action[2], false)
                                                checkbox.OnClick = action[3]
                                                subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                            else
                                                if action[2] == true or action[2] == false then
                                                    local subItem = subMenuESXCustom:AddItem(action[1], action[2])
                                                    subItem.OnRelease = action[3]
                                                    subItem.closeMenuOnRelease = v.CloseOnClick
                                                else
                                                    local subItem = subMenuESXCustom:AddItem(action[1])
                                                    subItem.OnRelease = action[2]
                                                    subItem.closeMenuOnRelease = v.CloseOnClick
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    :: pass ::
                end
            elseif not (IsPedAPlayer(hitEntity)) and IsEntityAPed(hitEntity) then
                CtxAddExtras(contextMenu, 'ped', hitEntity)
                _Peds()
                for k,v in pairs(Action_Config.Peds) do
                    if not v.Blocked then 
                        if v.IsRestricted then 
                            if not ESXCustomFonctionContextMenu:IsAllowed() then 
                                goto pass
                            end
                        end
                        if v.Type == "buttom" then 
                            if v.Condition ~= nil then
                                if v.Distance ~= nil and type(v.Distance) == "number" then
                                    local item = contextMenu:AddItem(v.Label, v.FlecheActive)
                                    if GetDistanceBetweenCoords(GetEntityCoords(hitEntity), GetEntityCoords(PlayerPedId())) < v.Distance then
                                        v.EntityHit = hitEntity
                                        item.OnRelease = v.OnClick
                                        item.closeMenuOnRelease = v.CloseOnClick
                                    else
                                        item.enabled = false
                                    end
                                else
                                    if v.Condition then
                                        local item = contextMenu:AddItem(v.Label, v.FlecheActive)
                                        v.EntityHit = hitEntity
                                        item.OnRelease = v.OnClick
                                        item.closeMenuOnRelease = v.CloseOnClick
                                    end
                                end
                            else
                                if v.Distance ~= nil and type(v.Distance) == "number" then
                                    local item = contextMenu:AddItem(v.Label, v.FlecheActive)
                                    if GetDistanceBetweenCoords(GetEntityCoords(hitEntity), GetEntityCoords(PlayerPedId())) < v.Distance then
                                        v.EntityHit = hitEntity
                                        item.OnRelease = v.OnClick
                                        item.closeMenuOnRelease = v.CloseOnClick
                                    else
                                        item.enabled = false
                                    end
                                else
                                    local item = contextMenu:AddItem(v.Label, v.FlecheActive)
                                    v.EntityHit = hitEntity
                                    item.OnRelease = v.OnClick
                                    item.closeMenuOnRelease = v.CloseOnClick
                                end
                            end
                        elseif v.Type == "Separator" then
                            contextMenu:AddSeparator()
                        elseif v.Type == "buttom-submenu" then
                            if v.Condition ~= nil then
                                if v.Condition then
                                    if v.Distance ~= nil and type(v.Distance) == "number" then
                                        if GetDistanceBetweenCoords(GetEntityCoords(hitEntity), GetEntityCoords(PlayerPedId())) < v.Distance then
                                            local subMenuESXCustom = menuPool:AddSubmenu(contextMenu, v.Label)
                                            if v.DoubleSub ~= nil and v.DoubleSub ~= false then
                                                for _, action in pairs(v.Action) do
                                                    local subItem = subMenuESXCustom:AddItem(action[1])
                                                    subItem.OnRelease = action[2]
                                                    subItem.closeMenuOnRelease = v.CloseOnClick
                                                end

                                                local subMenu2 = menuPool:AddSubmenu(subMenuESXCustom, v.DoubleSubLabel)
                                                for _, action in pairs(v.DoubleSubAction) do
                                                    local subItem = subMenu2:AddItem(action[1])
                                                    subItem.OnRelease = action[2]
                                                    subItem.closeMenuOnRelease = v.CloseOnClick
                                                end

                                                if v.TripleSub ~= nil and v.TripleSub ~= false then
                                                    local subMenu3 = menuPool:AddSubmenu(subMenuESXCustom, v.TripleSubLabel)
                                                    for _, action in pairs(v.TripleSubAction) do
                                                        local subItem = subMenu3:AddItem(action[1])
                                                        subItem.OnRelease = action[2]
                                                        subItem.closeMenuOnRelease = v.CloseOnClick
                                                    end
                                                end
                                            else
                                                for _, action in pairs(v.Action) do
                                                    if action[1] == "Separator" then
                                                        subMenuESXCustom:AddSeparator()
                                                    elseif action[1] == "Checkbox" then
                                                        local checkbox = subMenuESXCustom:AddCheckboxItem(action[2], action[3])
                                                        checkbox.OnClick = action[4]
                                                        subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                                    elseif action[1] == "CheckboxESXCustom" then
                                                        local checkbox = subMenuESXCustom:AddCheckboxItem(action[2], false)
                                                        checkbox.OnClick = action[3]
                                                        subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                                    else
                                                        if action[2] == true or action[2] == false then
                                                            local subItem = subMenuESXCustom:AddItem(action[1], action[2])
                                                            subItem.OnRelease = action[3]
                                                            subItem.closeMenuOnRelease = v.CloseOnClick
                                                        else
                                                            local subItem = subMenuESXCustom:AddItem(action[1])
                                                            subItem.OnRelease = action[2]
                                                            subItem.closeMenuOnRelease = v.CloseOnClick
                                                        end
                                                    end
                                                end
                                            end
                                        else
                                            local subMenuESXCustom = contextMenu:AddItem(v.Label)
                                            subMenuESXCustom.enabled = false
                                        end
                                    else
                                        local subMenuESXCustom = menuPool:AddSubmenu(contextMenu, v.Label)
                                        if v.DoubleSub ~= nil and v.DoubleSub ~= false then
                                            for _, action in pairs(v.Action) do
                                                local subItem = subMenuESXCustom:AddItem(action[1])
                                                subItem.OnRelease = action[2]
                                                subItem.closeMenuOnRelease = v.CloseOnClick
                                            end

                                            local subMenu2 = menuPool:AddSubmenu(subMenuESXCustom, v.DoubleSubLabel)
                                            for _, action in pairs(v.DoubleSubAction) do
                                                local subItem = subMenu2:AddItem(action[1])
                                                subItem.OnRelease = action[2]
                                                subItem.closeMenuOnRelease = v.CloseOnClick
                                            end

                                            if v.TripleSub ~= nil and v.TripleSub ~= false then
                                                local subMenu3 = menuPool:AddSubmenu(subMenuESXCustom, v.TripleSubLabel)
                                                for _, action in pairs(v.TripleSubAction) do
                                                    local subItem = subMenu3:AddItem(action[1])
                                                    subItem.OnRelease = action[2]
                                                    subItem.closeMenuOnRelease = v.CloseOnClick
                                                end
                                            end
                                        else
                                            for _, action in pairs(v.Action) do
                                                if action[1] == "Separator" then
                                                    subMenuESXCustom:AddSeparator()
                                                elseif action[1] == "Checkbox" then
                                                    local checkbox = subMenuESXCustom:AddCheckboxItem(action[2], action[3])
                                                    checkbox.OnClick = action[4]
                                                    subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                                elseif action[1] == "CheckboxESXCustom" then
                                                    local checkbox = subMenuESXCustom:AddCheckboxItem(action[2], false)
                                                    checkbox.OnClick = action[3]
                                                    subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                                else
                                                    if action[2] == true or action[2] == false then
                                                        local subItem = subMenuESXCustom:AddItem(action[1], action[2])
                                                        subItem.OnRelease = action[3]
                                                        subItem.closeMenuOnRelease = v.CloseOnClick
                                                    else
                                                        local subItem = subMenuESXCustom:AddItem(action[1])
                                                        subItem.OnRelease = action[2]
                                                        subItem.closeMenuOnRelease = v.CloseOnClick
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            else
                                if v.Distance ~= nil and type(v.Distance) == "number" then
                                    if GetDistanceBetweenCoords(GetEntityCoords(hitEntity), GetEntityCoords(PlayerPedId())) < v.Distance then
                                        local subMenuESXCustom = menuPool:AddSubmenu(contextMenu, v.Label)
                                        if v.DoubleSub ~= nil and v.DoubleSub ~= false then
                                            for _, action in pairs(v.Action) do
                                                local subItem = subMenuESXCustom:AddItem(action[1])
                                                subItem.OnRelease = action[2]
                                                subItem.closeMenuOnRelease = v.CloseOnClick
                                            end

                                            local subMenu2 = menuPool:AddSubmenu(subMenuESXCustom, v.DoubleSubLabel)
                                            for _, action in pairs(v.DoubleSubAction) do
                                                local subItem = subMenu2:AddItem(action[1])
                                                subItem.OnRelease = action[2]
                                                subItem.closeMenuOnRelease = v.CloseOnClick
                                            end

                                            if v.TripleSub ~= nil and v.TripleSub ~= false then
                                                local subMenu3 = menuPool:AddSubmenu(subMenuESXCustom, v.TripleSubLabel)
                                                for _, action in pairs(v.TripleSubAction) do
                                                    local subItem = subMenu3:AddItem(action[1])
                                                    subItem.OnRelease = action[2]
                                                    subItem.closeMenuOnRelease = v.CloseOnClick
                                                end
                                            end
                                        else
                                            for _, action in pairs(v.Action) do
                                                if action[1] == "Separator" then
                                                    subMenuESXCustom:AddSeparator()
                                                elseif action[1] == "Checkbox" then
                                                    local checkbox = subMenuESXCustom:AddCheckboxItem(action[2], action[3])
                                                    checkbox.OnClick = action[4]
                                                    subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                                elseif action[1] == "CheckboxESXCustom" then
                                                    local checkbox = subMenuESXCustom:AddCheckboxItem(action[2], false)
                                                    checkbox.OnClick = action[3]
                                                    subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                                else
                                                    if action[2] == true or action[2] == false then
                                                        local subItem = subMenuESXCustom:AddItem(action[1], action[2])
                                                        subItem.OnRelease = action[3]
                                                        subItem.closeMenuOnRelease = v.CloseOnClick
                                                    else
                                                        local subItem = subMenuESXCustom:AddItem(action[1])
                                                        subItem.OnRelease = action[2]
                                                        subItem.closeMenuOnRelease = v.CloseOnClick
                                                    end
                                                end
                                            end
                                        end
                                    else
                                        local subMenuESXCustom = contextMenu:AddItem(v.Label)
                                        subMenuESXCustom.enabled = false
                                    end
                                else
                                    local subMenuESXCustom = menuPool:AddSubmenu(contextMenu, v.Label)
                                    if v.DoubleSub ~= nil and v.DoubleSub ~= false then
                                        for _, action in pairs(v.Action) do
                                            local subItem = subMenuESXCustom:AddItem(action[1])
                                            subItem.OnRelease = action[2]
                                            subItem.closeMenuOnRelease = v.CloseOnClick
                                        end
                                        local subMenu2 = menuPool:AddSubmenu(subMenuESXCustom, v.DoubleSubLabel)
                                        for _, action in pairs(v.DoubleSubAction) do
                                            local subItem = subMenu2:AddItem(action[1])
                                            subItem.OnRelease = action[2]
                                            subItem.closeMenuOnRelease = v.CloseOnClick
                                        end
                                        if v.TripleSub ~= nil and v.TripleSub ~= false then
                                            local subMenu3 = menuPool:AddSubmenu(subMenuESXCustom, v.TripleSubLabel)
                                            for _, action in pairs(v.TripleSubAction) do
                                                local subItem = subMenu3:AddItem(action[1])
                                                subItem.OnRelease = action[2]
                                                subItem.closeMenuOnRelease = v.CloseOnClick
                                            end
                                        end
                                    else
                                        for _, action in pairs(v.Action) do
                                            if action[1] == "Separator" then
                                                subMenuESXCustom:AddSeparator()
                                            elseif action[1] == "Checkbox" then
                                                local checkbox = subMenuESXCustom:AddCheckboxItem(action[2], action[3])
                                                checkbox.OnClick = action[4]
                                                subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                            elseif action[1] == "CheckboxESXCustom" then
                                                local checkbox = subMenuESXCustom:AddCheckboxItem(action[2], false)
                                                checkbox.OnClick = action[3]
                                                subMenuESXCustom.closeMenuOnRelease = v.CloseOnClick
                                            else
                                                if action[2] == true or action[2] == false then
                                                    local subItem = subMenuESXCustom:AddItem(action[1], action[2])
                                                    subItem.OnRelease = action[3]
                                                    subItem.closeMenuOnRelease = v.CloseOnClick
                                                else
                                                    local subItem = subMenuESXCustom:AddItem(action[1])
                                                    subItem.OnRelease = action[2]
                                                    subItem.closeMenuOnRelease = v.CloseOnClick
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    :: pass ::
                end
            elseif (IsEntityAnObject(hitEntity)) then
                local object = hitEntity
            
                _Object()
                local hasNativeSit = false
                for _, a in pairs(Action_Config.Object) do
                    if a.Label == "S'assoir" and a.Props and a.Props[GetEntityModel(object)] then hasNativeSit = true break end
                end
                if not hasNativeSit and not CPSitting then
                    local sitItem = contextMenu:AddItem("S'asseoir", false)
                    local dist = #(GetEntityCoords(object) - GetEntityCoords(PlayerPedId()))
                    if dist < 3.0 and not IsPedInAnyVehicle(PlayerPedId(), false) then
                        sitItem.OnRelease = function() CPSitOnObject(object) end
                        sitItem.closeMenuOnRelease = true
                    else
                        sitItem.enabled = false
                    end
                end
                for k,v in pairs(Action_Config.Object) do 
                    if not v.Blocked then 
                        if v.IsRestricted then 
                            if not ESXCustomFonctionContextMenu:IsAllowed() then 
                                goto pass
                            end
                        end
                        if v.Type == "buttom" then
                            if v.Props ~= nil then
                                if v.Condition ~= nil then
                                    if v.Condition then
                                        if v.Props[GetEntityModel(object)] then
                                            local item = contextMenu:AddItem(v.Label, v.FlecheActive)
                                            v.EntityHit = hitEntity
                                            if v.Distance ~= nil and type(v.Distance) == "number" then
                                                if GetDistanceBetweenCoords(GetEntityCoords(hitEntity), GetEntityCoords(PlayerPedId())) < v.Distance then
                                                    item.OnRelease = v.OnClick
                                                    item.closeMenuOnRelease = v.CloseOnClick
                                                else
                                                    item.enabled = false
                                                end
                                            else
                                                item.OnRelease = v.OnClick
                                                item.closeMenuOnRelease = v.CloseOnClick
                                            end
                                        -- else
                                        --     local item = contextMenu:AddItem(ButtonContextMenu.NothingHere, v.FlecheActive)
                                        --     item.enabled = false
                                        end
                                    end
                                else
                                    if v.Props[GetEntityModel(object)] then
                                        local item = contextMenu:AddItem(v.Label, v.FlecheActive)
                                        v.EntityHit = hitEntity
                                        if v.Distance ~= nil and type(v.Distance) == "number" then
                                            if GetDistanceBetweenCoords(GetEntityCoords(hitEntity), GetEntityCoords(PlayerPedId())) < v.Distance then
                                                item.OnRelease = v.OnClick
                                                item.closeMenuOnRelease = v.CloseOnClick
                                            else
                                                item.enabled = false
                                            end
                                        else
                                            item.OnRelease = v.OnClick
                                            item.closeMenuOnRelease = v.CloseOnClick
                                        end
                                    -- else
                                    --     local item = contextMenu:AddItem(ButtonContextMenu.NothingHere, v.FlecheActive)
                                    --     item.enabled = false
                                    end
                                end
                            else
                                if v.Condition ~= nil then
                                    if v.Condition then
                                        local item = contextMenu:AddItem(v.Label, v.FlecheActive)
                                        v.EntityHit = hitEntity
                                        if v.Distance ~= nil and type(v.Distance) == "number" then
                                            if GetDistanceBetweenCoords(GetEntityCoords(hitEntity), GetEntityCoords(PlayerPedId())) < v.Distance then
                                                item.OnRelease = v.OnClick
                                                item.closeMenuOnRelease = v.CloseOnClick
                                            else
                                                item.enabled = false
                                            end
                                        else
                                            item.OnRelease = v.OnClick
                                            item.closeMenuOnRelease = v.CloseOnClick
                                        end
                                    end
                                else
                                    local item = contextMenu:AddItem(v.Label, v.FlecheActive)
                                    v.EntityHit = hitEntity
                                    if v.Distance ~= nil and type(v.Distance) == "number" then
                                        if GetDistanceBetweenCoords(GetEntityCoords(hitEntity), GetEntityCoords(PlayerPedId())) < v.Distance then
                                            item.OnRelease = v.OnClick
                                            item.closeMenuOnRelease = v.CloseOnClick
                                        else
                                            item.enabled = false
                                        end
                                    else
                                        item.OnRelease = v.OnClick
                                        item.closeMenuOnRelease = v.CloseOnClick
                                    end
                                end
                            end
                        elseif v.Type == "buttom-submenu" then
                            if v.Props ~= nil then
                                if v.Props[GetEntityModel(object)] then
                                    if v.Distance ~= nil and type(v.Distance) == "number" then
                                        if GetDistanceBetweenCoords(GetEntityCoords(hitEntity), GetEntityCoords(PlayerPedId())) < v.Distance then
                                            local subMenuESXCustom = menuPool:AddSubmenu(contextMenu, v.Label)
                                            if v.DoubleSub ~= nil and v.DoubleSub ~= false then
                                                local subMenu2 = menuPool:AddSubmenu(subMenuESXCustom, v.DoubleSubLabel)
                                                for _, action in pairs(v.DoubleSubAction) do
                                                    local subItem = subMenu2:AddItem(action[1])
                                                    subItem.OnRelease = action[2]
                                                    subItem.closeMenuOnRelease = v.CloseOnClick
                                                end
                                                for _, action in pairs(v.Action) do
                                                    local subItem = subMenuESXCustom:AddItem(action[1])
                                                    subItem.OnRelease = action[2]
                                                    subItem.closeMenuOnRelease = v.CloseOnClick
                                                end
                                            else
                                                for _, action in pairs(v.Action) do
                                                    if action[1] == "Separator" then
                                                        subMenuESXCustom:AddSeparator()
                                                    else
                                                        if action[2] == true or action[2] == false then
                                                            local subItem = subMenuESXCustom:AddItem(action[1], action[2])
                                                            subItem.OnRelease = action[3]
                                                            subItem.closeMenuOnRelease = v.CloseOnClick
                                                        else
                                                            local subItem = subMenuESXCustom:AddItem(action[1])
                                                            subItem.OnRelease = action[2]
                                                            subItem.closeMenuOnRelease = v.CloseOnClick
                                                        end
                                                    end
                                                end
                                            end
                                        else
                                            local subMenuESXCustom = contextMenu:AddItem(v.Label)
                                            subMenuESXCustom.enabled = false
                                        end
                                    else
                                        local subMenuESXCustom = menuPool:AddSubmenu(contextMenu, v.Label)
                                        if v.DoubleSub ~= nil and v.DoubleSub ~= false then
                                            local subMenu2 = menuPool:AddSubmenu(subMenuESXCustom, v.DoubleSubLabel)
                                            for _, action in pairs(v.DoubleSubAction) do
                                                local subItem = subMenu2:AddItem(action[1])
                                                subItem.OnRelease = action[2]
                                                subItem.closeMenuOnRelease = v.CloseOnClick
                                            end
                                            for _, action in pairs(v.Action) do
                                                local subItem = subMenuESXCustom:AddItem(action[1])
                                                subItem.OnRelease = action[2]
                                                subItem.closeMenuOnRelease = v.CloseOnClick
                                            end
                                        else
                                            for _, action in pairs(v.Action) do
                                                if action[1] == "Separator" then
                                                    subMenuESXCustom:AddSeparator()
                                                else
                                                    if action[2] == true or action[2] == false then
                                                        local subItem = subMenuESXCustom:AddItem(action[1], action[2])
                                                        subItem.OnRelease = action[3]
                                                        subItem.closeMenuOnRelease = v.CloseOnClick
                                                    else
                                                        local subItem = subMenuESXCustom:AddItem(action[1])
                                                        subItem.OnRelease = action[2]
                                                        subItem.closeMenuOnRelease = v.CloseOnClick
                                                    end
                                                end
                                            end
                                        end
                                    end
                                -- else
                                --     local subMenuESXCustom = contextMenu:AddItem(ButtonContextMenu.NothingHere, v.FlecheActive)
                                --     subMenuESXCustom.enabled = false
                                end
                            else
                                local subMenuESXCustom = menuPool:AddSubmenu(contextMenu, v.Label)
                                if v.Distance ~= nil and type(v.Distance) == "number" then
                                    if GetDistanceBetweenCoords(GetEntityCoords(hitEntity), GetEntityCoords(PlayerPedId())) < v.Distance then
                                        for _, action in pairs(v.Action) do
                                            local subItem = subMenuESXCustom:AddItem(action[1])
                                            subItem.OnRelease = action[2]
                                            subItem.closeMenuOnRelease = v.CloseOnClick
                                        end
                                    else
                                        subMenuESXCustom.enabled = false
                                    end
                                else
                                    for _, action in pairs(v.Action) do
                                        local subItem = subMenuESXCustom:AddItem(action[1])
                                        subItem.OnRelease = action[2]
                                        subItem.closeMenuOnRelease = v.CloseOnClick
                                    end
                                end
                            end
                        end
                    end
                    :: pass ::
                end
            elseif CheckboxApuyer == true then
                local NoClip = contextMenu:AddCheckboxItem(ButtonContextMenu.NoClipItem, true)
                NoClip.OnClick = function()
                    CheckboxApuyer = false
                    noclip = not noclip
                    if not noclip then
                        FreezeEntityPosition(plyPed, false)
                        SetEntityInvincible(plyPed, false)
                        SetEntityCollision(plyPed, true, true)
                    
                        SetEntityVisible(plyPed, true, false)
                    
                        SetEveryoneIgnorePlayer(PlayerId(), false)
                        SetPoliceIgnorePlayer(PlayerId(), false)
                        ESX.ShowNotification(NotificationContextMenu.NoclipOFF)
                    end
                end
            else
                _AtPose()
                for k,v in pairs(Action_Config.AtPose) do 
                    local plyCoords = GetEntityCoords(GetPlayerPed(-1), false)
                    if v ~= nil then
                        local dist = Vdist(worldPosition.x, worldPosition.y, worldPosition.z, v.Coords.x, v.Coords.y, v.Coords.z)
                        local dist2 = Vdist(plyCoords.x, plyCoords.y, plyCoords.z, v.Coords.x, v.Coords.y, v.Coords.z)
                        
                        if dist < (v.MaxCoords or 3) and dist2 < (v.MaxCoords or 3) then
                            if v.Condition ~= nil then
                                if v.Condition then
                                    local item = contextMenu:AddItem(v.Name or "~r~Non indéfini.~s~", v.FlecheActive)
                                    item.OnRelease = v.OnClick
                                    item.closeMenuOnRelease = v.CloseOnClick
                                end
                            else
                                local item = contextMenu:AddItem(v.Name or "~r~Non indéfini.~s~", v.FlecheActive)
                                item.OnRelease = v.OnClick
                                item.closeMenuOnRelease = v.CloseOnClick
                            end
                        end
                    end
                end
                if CounteurAtPose > 0 then
                    contextMenu:AddSeparator()
                end
                _Other()
                for k,v in pairs(Action_Config.Other) do 
                    if not v.Blocked then 
                        if v.IsRestricted then 
                            if not ESXCustomFonctionContextMenu:IsAllowed() then 
                                goto pass
                            end
                        end
                        if v.Type == "buttom" then 
                            if v.Condition ~= nil then
                                if v.Condition then
                                    local item = contextMenu:AddItem(v.Label, v.FlecheActive)
                                    v.EntityHit = hitEntity
                                    item.OnRelease = v.OnClick
                                    item.closeMenuOnRelease = v.CloseOnClick
                                end
                            else
                                local item = contextMenu:AddItem(v.Label, v.FlecheActive)
                                v.EntityHit = hitEntity
                                item.OnRelease = v.OnClick
                                item.closeMenuOnRelease = v.CloseOnClick
                            end
                        elseif v.Type == "Separator" then
                            contextMenu:AddSeparator()
                        elseif v.Type == "buttom-submenu" then
                            local subMenuESXCustom = menuPool:AddSubmenu(contextMenu, v.Label)
                            if v.DoubleSub ~= nil and v.DoubleSub ~= false then
                                local subMenu2 = menuPool:AddSubmenu(subMenuESXCustom, v.DoubleSubLabel)
                                for _, action in pairs(v.DoubleSubAction) do
                                    local subItem = subMenu2:AddItem(action[1])
                                    subItem.OnRelease = action[2]
                                    subItem.closeMenuOnRelease = v.CloseOnClick
                                end
                                for _, action in pairs(v.Action) do
                                    local subItem = subMenuESXCustom:AddItem(action[1])
                                    subItem.OnRelease = action[2]
                                    subItem.closeMenuOnRelease = v.CloseOnClick
                                end
                            else
                                for _, action in pairs(v.Action) do
                                    if action[1] == "Separator" then
                                        subMenuESXCustom:AddSeparator()
                                    else
                                        if action[2] == true or action[2] == false then
                                            local subItem = subMenuESXCustom:AddItem(action[1], action[2])
                                            subItem.OnRelease = action[3]
                                            subItem.closeMenuOnRelease = v.CloseOnClick
                                        else
                                            local subItem = subMenuESXCustom:AddItem(action[1])
                                            subItem.OnRelease = action[2]
                                            subItem.closeMenuOnRelease = v.CloseOnClick
                                        end
                                    end
                                end
                            end
                        end
                    end
                    :: pass ::
                end
            end
        end
    else
        _Weather()
        for k,v in pairs(Action_Config.Weather) do 
            if not v.Blocked then 
                if v.IsRestricted then 
                    if not ESXCustomFonctionContextMenu:IsAllowed() then 
                        goto pass
                    end
                end
                if v.Type == "buttom" then 
                    if v.Condition ~= nil then
                        if v.Condition then
                            local item = contextMenu:AddItem(v.Label, v.FlecheActive)
                            v.EntityHit = hitEntity
                            item.OnRelease = v.OnClick
                            item.closeMenuOnRelease = v.CloseOnClick
                        end
                    else
                        local item = contextMenu:AddItem(v.Label, v.FlecheActive)
                        v.EntityHit = hitEntity
                        item.OnRelease = v.OnClick
                        item.closeMenuOnRelease = v.CloseOnClick
                    end
                elseif v.Type == "Separator" then
                    contextMenu:AddSeparator()
                elseif v.Type == "buttom-submenu" then
                    local subMenuESXCustom = menuPool:AddSubmenu(contextMenu, v.Label)
                    if v.DoubleSub ~= nil and v.DoubleSub ~= false then
                        local subMenu2 = menuPool:AddSubmenu(subMenuESXCustom, v.DoubleSubLabel)
                        for _, action in pairs(v.DoubleSubAction) do
                            local subItem = subMenu2:AddItem(action[1])
                            subItem.OnRelease = action[2]
                            subItem.closeMenuOnRelease = v.CloseOnClick
                        end
                        for _, action in pairs(v.Action) do
                            local subItem = subMenuESXCustom:AddItem(action[1])
                            subItem.OnRelease = action[2]
                            subItem.closeMenuOnRelease = v.CloseOnClick
                        end
                    else
                        for _, action in pairs(v.Action) do
                            if action[1] == "Separator" then
                                subMenuESXCustom:AddSeparator()
                            else
                                if action[2] == true or action[2] == false then
                                    local subItem = subMenuESXCustom:AddItem(action[1], action[2])
                                    subItem.OnRelease = action[3]
                                    subItem.closeMenuOnRelease = v.CloseOnClick
                                else
                                    local subItem = subMenuESXCustom:AddItem(action[1])
                                    subItem.OnRelease = action[2]
                                    subItem.closeMenuOnRelease = v.CloseOnClick
                                end
                            end
                        end
                    end
                end
            end
            :: pass ::
        end
    end
    contextMenu:SetPosition(screenPosition)
    contextMenu:Visible(true)
end
--Function.lua
function startAnimAction(lib, anim)
    while not HasAnimDictLoaded(lib) do
        Wait(0)
        RequestAnimDict(lib)
    end
    TaskPlayAnim(GetPlayerPed(-1), lib, anim, 8.0, 1.0, -1, 49, 0, false, false, false)
    RemoveAnimDict(lib)
end
function setUniform(value, plyPed)
    ESX.TriggerServerCallback("esx_skin:getPlayerSkin", function(skin)
        TriggerEvent("skinchanger:getSkin", function(skina)
            if value == 'torso' then
                startAnimAction("clothingtie", "try_tie_neutral_a")
                Citizen.Wait(1000)
                ClearPedTasks(plyPed)
                if skin.torso_1 ~= skina.torso_1 then
                    TriggerEvent('skinchanger:loadClothes', skina, {['torso_1'] = skin.torso_1, ['torso_2'] = skin.torso_2, ['tshirt_1'] = skin.tshirt_1, ['tshirt_2'] = skin.tshirt_2, ['arms'] = skin.arms})
                else
                    TriggerEvent('skinchanger:loadClothes', skina, {['torso_1'] = 15, ['torso_2'] = 0, ['tshirt_1'] = 15, ['tshirt_2'] = 0, ['arms'] = 15})
                end
            elseif value == 'pants' then
                startAnimAction("re@construction", "out_of_breath")
                Citizen.Wait(1300)
                ClearPedTasks(plyPed)
                if skin.pants_1 ~= skina.pants_1 then
                    TriggerEvent('skinchanger:loadClothes', skina, {['pants_1'] = skin.pants_1, ['pants_2'] = skin.pants_2})
                else
                    if skin.sex == 0 then
                        TriggerEvent('skinchanger:loadClothes', skina, {['pants_1'] = 14, ['pants_2'] = 1})
                    else
                        TriggerEvent('skinchanger:loadClothes', skina, {['pants_1'] = 15, ['pants_2'] = 0})
                    end
                end
            elseif value == 'leg' then
                startAnimAction("clothingtie", "try_tie_positive_a")
                Citizen.Wait(2100)
                ClearPedTasks(plyPed)
                if skin.chain_1 ~= skina.chain_1 then
                    TriggerEvent('skinchanger:loadClothes', skina, {['chain_1'] = skin.chain_1, ['chain_2'] = skin.chain_2})
                else
                    if skin.sex == 0 then
                        TriggerEvent('skinchanger:loadClothes', skina, {['chain_1'] = 0, ['chain_2'] = 0})
                    else
                        TriggerEvent('skinchanger:loadClothes', skina, {['chain_1'] = 15, ['chain_2'] = 0})
                    end
                end
            elseif value == 'shoes' then
                startAnimAction("random@domestic", "pickup_low")
                Citizen.Wait(1200)
                ClearPedTasks(plyPed)
                if skin.shoes_1 ~= skina.shoes_1 then
                    TriggerEvent('skinchanger:loadClothes', skina, {['shoes_1'] = skin.shoes_1, ['shoes_2'] = skin.shoes_2})
                else
                    if skin.sex == 0 then
                        TriggerEvent('skinchanger:loadClothes', skina, {['shoes_1'] = 57, ['shoes_2'] = 0})
                    else
                        TriggerEvent('skinchanger:loadClothes', skina, {['shoes_1'] = 47, ['shoes_2'] = 0})
                    end
                end
            elseif value == 'bag' then
                startAnimAction("anim@heists@ornate_bank@grab_cash", "intro")
                Citizen.Wait(1000)
                ClearPedTasks(plyPed)
                if skin.bags_1 ~= skina.bags_1 then
                    TriggerEvent('skinchanger:loadClothes', skina, {['bags_1'] = skin.bags_1, ['bags_2'] = skin.bags_2})
                else
                    TriggerEvent('skinchanger:loadClothes', skina, {['bags_1'] = 0, ['bags_2'] = 0})
                end
            elseif value == 'bproof' then
                startAnimAction("clothingtie", "try_tie_neutral_a")
                Citizen.Wait(1000)
                ClearPedTasks(plyPed)
                if skin.bproof_1 ~= skina.bproof_1 then
                    TriggerEvent('skinchanger:loadClothes', skina, {['bproof_1'] = skin.bproof_1, ['bproof_2'] = skin.bproof_2})
                else
                    TriggerEvent('skinchanger:loadClothes', skina, {['bproof_1'] = 0, ['bproof_2'] = 0})
                end
            end
        end)
    end)
end
function AnnimForTake(LePed, Lapose)
    if Lapose < 10.0 then
        startAnimAction("mini@sprunk", "plyr_buy_drink_pt1")
        FreezeEntityPosition(LePed, true)
        Wait(5000)
        FreezeEntityPosition(LePed, false)
        ClearPedTasksImmediately(LePed)
    end
end
function getCamDirection()
    local heading = GetGameplayCamRelativeHeading() + GetEntityPhysicsHeading(plyPed)
    local pitch = GetGameplayCamRelativePitch()
    local coords = vector3(-math.sin(heading * math.pi / 180.0), math.cos(heading * math.pi / 180.0), math.sin(pitch * math.pi / 180.0))
    local len = math.sqrt((coords.x * coords.x) + (coords.y * coords.y) + (coords.z * coords.z))
    if len ~= 0 then
        coords = coords / len
    end
    return coords
end
Citizen.CreateThread(function()
    while true do
        plyPed = PlayerPedId()
        timer = 200
        if noclip then
            timer = 0
            local plyCoords = GetEntityCoords(plyPed, false)
            local camCoords = getCamDirection()
            SetEntityVelocity(plyPed, 0.01, 0.01, 0.01)
            HideHudComponentThisFrame(19)   -- pas de roue des armes avec la molette
            if IsControlPressed(0, 32) then
                plyCoords = plyCoords + (ctxNoclipSpeed * camCoords)
            end
            if IsControlPressed(0, 269) then
                plyCoords = plyCoords - (ctxNoclipSpeed * camCoords)
            end
            -- Molette haut : accélérer / molette bas : ralentir (comme le noclip du menu admin)
            -- FiveM : 15/17 = molette haut, 14/16 = molette bas
            if IsControlJustPressed(0, 15) or IsControlJustPressed(0, 17) then
                ctxNoclipSpeed = math.min(ctxNoclipSpeed + 0.5, 25.0)
                ctxNoclipShow = GetGameTimer() + 1500
            elseif IsControlJustPressed(0, 14) or IsControlJustPressed(0, 16) then
                ctxNoclipSpeed = math.max(ctxNoclipSpeed - 0.5, 0.5)
                ctxNoclipShow = GetGameTimer() + 1500
            end
            if GetGameTimer() < ctxNoclipShow then
                SetTextFont(4) SetTextScale(0.0, 0.5) SetTextColour(255, 255, 255, 235) SetTextOutline() SetTextCentre(true)
                BeginTextCommandDisplayText('STRING')
                AddTextComponentSubstringPlayerName(('Vitesse noclip : ~b~x%.1f'):format(ctxNoclipSpeed))
                EndTextCommandDisplayText(0.5, 0.9)
            end
            SetEntityCoordsNoOffset(plyPed, plyCoords, true, true, true)
        end
        Citizen.Wait(timer)
    end
end)
function SetUnsetAccessory(accessory)
    ESX.TriggerServerCallback(ConfigContextMenu.Callback.CallbackGetAccessories, function(hasAccessory, accessorySkin)
        local _accessory = string.lower(accessory)

        if hasAccessory then
            TriggerEvent('skinchanger:getSkin', function(skin)
                local mAccessory = -1
                local mColor = 0

                if _accessory == 'ears' then
                elseif _accessory == 'glasses' then
                    mAccessory = 0
                    startAnimAction('clothingspecs', 'try_glasses_positive_a')
                    Citizen.Wait(1000)
                    handsup, pointing = false, false
                    ClearPedTasks(plyPed)
                elseif _accessory == 'helmet' then
                    startAnimAction('missfbi4', 'takeoff_mask')
                    Citizen.Wait(1000)
                    handsup, pointing = false, false
                    ClearPedTasks(plyPed)
                elseif _accessory == 'mask' then
                    mAccessory = 0
                    startAnimAction('missfbi4', 'takeoff_mask')
                    Citizen.Wait(850)
                    handsup, pointing = false, false
                    ClearPedTasks(plyPed)
                elseif _accessory == 'Montre' then
                elseif _accessory == 'Bracelet' then
                end

                if skin[_accessory .. '_1'] == mAccessory then
                    mAccessory = accessorySkin[_accessory .. '_1']
                    mColor = accessorySkin[_accessory .. '_2']
                end

                local accessorySkin = {}
                accessorySkin[_accessory .. '_1'] = mAccessory
                accessorySkin[_accessory .. '_2'] = mColor
                TriggerEvent('skinchanger:loadClothes', skin, accessorySkin)
            end)
        else
            if _accessory == 'ears' then
                ESX.ShowNotification(NotificationContextMenu.AccessOreille)
            elseif _accessory == 'glasses' then
                ESX.ShowNotification(NotificationContextMenu.AccessLunette)
            elseif _accessory == 'helmet' then
                ESX.ShowNotification(NotificationContextMenu.AccessChapeau)
            elseif _accessory == 'mask' then
                ESX.ShowNotification(NotificationContextMenu.AccessMask)
            elseif _accessory == 'Montre' then
                ESX.ShowNotification(NotificationContextMenu.AccessMontre)
            elseif _accessory == 'Bracelet' then
                ESX.ShowNotification(NotificationContextMenu.AccessBracelet)
            end
        end
    end, accessory)
end
TableMarker = {}
Citizen.CreateThread(function()
    while true do
        if TableMarker == 0 then
            timer = 5000
        else
            timer = 2500
            for k, v in ipairs(TableMarker) do
                if GetDistanceBetweenCoords(v.coords, GetEntityCoords(PlayerPedId())) < 5.0 then
                    timer = 0
                end
                if GetDistanceBetweenCoords(v.coords, GetEntityCoords(PlayerPedId())) < 5.0 then
                    ESXCustomFonctionContextMenu:Draw3DText(v.coords.x, v.coords.y, v.coords.z, v.text, 4, 0.1, 0.1)
                end
            end
        end
        Citizen.Wait(timer)
    end
end)
ESXCustomFonctionContextMenu = {}
function ESXCustomFonctionContextMenu:IsAllowed()
    if AdminPlayerJoueur then
        return true
    else
        return false
    end
end
function ESXCustomFonctionContextMenu:SpawnObj(obj)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local objectCoords = (coords + getCamDirection() * 1.0)
    local Ent = nil

    ESXCustomFonctionContextMenu:SpawnObject(obj, objectCoords, function(obj)
        SetEntityCoords(obj, objectCoords, 0.0, 0.0, 0.0, 0)
        SetEntityHeading(obj, GetEntityHeading(playerPed))
        PlaceObjectOnGroundProperly(obj)
        Ent = obj
        Wait(1)
    end)
    Wait(1)
    while Ent == nil do Wait(1) end
    SetEntityHeading(Ent, GetEntityHeading(playerPed))
    PlaceObjectOnGroundProperly(Ent)
    local placed = false
    while not placed do
        Citizen.Wait(1)
        local coords, forward = GetEntityCoords(playerPed), GetEntityForwardVector(playerPed)
        local objectCoords = (coords + getCamDirection() * 2.0)
        SetEntityCoords(Ent, objectCoords, 0.0, 0.0, 0.0, 0)
        SetEntityHeading(Ent, GetEntityHeading(playerPed))
        PlaceObjectOnGroundProperly(Ent)
        SetEntityAlpha(Ent, 170, 170)
        SetEntityCollision(Ent, false, false)

        if IsControlJustReleased(1, 38) then
            placed = true
        end
    end

    FreezeEntityPosition(Ent, true)
    SetEntityInvincible(Ent, true)
    ResetEntityAlpha(Ent)
    SetEntityCollision(Ent, true, true)
    local NetId = NetworkGetNetworkIdFromEntity(Ent)
end

function ESXCustomFonctionContextMenu:SpawnObject(model, coords, cb)
    local model = GetEntityModel(model)
    Citizen.CreateThread(function()
        ESXCustomFonctionContextMenu:RequestModels(model)
        Wait(1)
        local obj = CreateObject(model, coords.x, coords.y, coords.z, true, false, true)

        if cb then
            cb(obj)
        end
    end)
end

function ESXCustomFonctionContextMenu:RequestModels(modelHash)
    if not HasModelLoaded(modelHash) and IsModelInCdimage(modelHash) then
        RequestModel(modelHash)

        while not HasModelLoaded(modelHash) do
            Citizen.Wait(1)
        end
    end
end

function ESXCustomFonctionContextMenu:Draw3DText(x,y,z,textInput,fontId,scaleX,scaleY)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    local dist = GetDistanceBetweenCoords(px,py,pz, x,y,z, 1)    
    local scale = (1/dist)*20
    local fov = (1/GetGameplayCamFov())*100
    local scale = scale*fov   
    SetTextScale(scaleX*scale, scaleY*scale)
    SetTextFont(fontId)
    SetTextProportional(1)
    SetTextColour(250, 250, 250, 255)	
    SetTextDropshadow(1, 1, 1, 1, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(textInput)
    SetDrawOrigin(x,y,z+2, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end
function ESXCustomFonctionContextMenu:Command(commandeName)
    ExecuteCommand(commandeName)
end
function ESXCustomFonctionContextMenu:CommandME(message)
    if Config.WantToUseME then
        ESXCustomFonctionContextMenu:Command("me "..message)
    end
end

-- Interactions RP : animation + /me, annulées dès que le joueur bouge
function ESXCustomFonctionContextMenu:RPAnim(dict, anim, duration, meText, flag)
    local ped = PlayerPedId()
    if not IsPedOnFoot(ped) or IsPedDeadOrDying(ped, true) then return ESX.ShowNotification("~r~Action impossible maintenant.") end
    RequestAnimDict(dict)
    local t = GetGameTimer()
    while not HasAnimDictLoaded(dict) and GetGameTimer() - t < 3000 do Wait(10) end
    if not HasAnimDictLoaded(dict) then return end
    if meText then ESXCustomFonctionContextMenu:CommandME(meText) end
    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, duration or 3000, flag or 0, 0.0, false, false, false)
end
function ESXCustomFonctionContextMenu:RPScenario(scenario, meText)
    local ped = PlayerPedId()
    if not IsPedOnFoot(ped) or IsPedDeadOrDying(ped, true) then return ESX.ShowNotification("~r~Action impossible maintenant.") end
    if meText then ESXCustomFonctionContextMenu:CommandME(meText) end
    TaskStartScenarioInPlace(ped, scenario, 0, true)
    ESX.ShowNotification("~b~Bougez pour arrêter.")
    CreateThread(function()
        Wait(1500)
        while IsPedUsingScenario(ped, scenario) or IsPedActiveInScenario(ped) do
            if IsControlPressed(0, 32) or IsControlPressed(0, 33) or IsControlPressed(0, 34) or IsControlPressed(0, 35) or IsPedDeadOrDying(ped, true) then
                ClearPedTasks(ped)
                break
            end
            Wait(150)
        end
    end)
end
-- Face au joueur visé, anime puis /me
function ESXCustomFonctionContextMenu:RPWithPlayer(dict, anim, duration, meText)
    local target = LastEntityHit
    if not target or not DoesEntityExist(target) then return end
    if #(GetEntityCoords(target) - GetEntityCoords(PlayerPedId())) > 3.0 then return ESX.ShowNotification("~r~Le joueur est trop loin.") end
    ESXCustomFonctionContextMenu:MakeEntityFaceEntity(PlayerPedId(), target)
    ESXCustomFonctionContextMenu:RPAnim(dict, anim, duration, meText)
end

--Copie Animation
function ESXCustomFonctionContextMenu:CopieAnimation(target)
    ESX.TriggerServerCallback('ContextMenu:getAnimation', function(data)
        if data ~= nil then
            if data == "wait" then
                ESX.ShowNotification("~r~Action impossible:~s~\nVeuillez patientez.")
            else
                ExecuteCommand("e "..data)
            end
        else
            ESX.ShowNotification("~r~Action impossible:~s~\nLe joueur ne fait pas d'animation.")
        end
    end, GetPlayerServerId(NetworkGetPlayerIndexFromPed(target)))
end

RegisterNetEvent("ContextMenu:getAnimationTarget")
AddEventHandler("ContextMenu:getAnimationTarget", function(src)
    local data = {src = src, animation = PlayerClass.pEmoteEnCours}
    TriggerServerEvent("ContextMenu:getAnimationTarget", data)
end)

function ESXCustomFonctionContextMenu:Weather(weather)
    if weather == "freezeweather" then
        ESXCustomFonctionContextMenu:Command(weather)
    else
        ESXCustomFonctionContextMenu:Command("weather "..weather)
    end
end
function ESXCustomFonctionContextMenu:RevivePed(ped)
    ClearPedTasksImmediately(ped)
    ResurrectPed(ped)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    ClearPedTasksImmediately(ped)
    ClearPedBloodDamage(ped)
end
function ESXCustomFonctionContextMenu:PlayAnim(ped, dict, anim, speed, time, flag)
    while not HasAnimDictLoaded(dict) do
        Wait(0)
        RequestAnimDict(dict)
    end
    TaskPlayAnim(ped, dict, anim, speed, speed, time, flag, 1, false, false, false)
end
function ESXCustomFonctionContextMenu:MakeEntityFaceEntity(entity1, entity2)
    local p1 = GetEntityCoords(entity1, true)
    local p2 = GetEntityCoords(entity2, true)

    local dx = p2.x - p1.x
    local dy = p2.y - p1.y

    local heading = GetHeadingFromVector_2d(dx, dy)
    SetEntityHeading( entity1, heading )
end
function ESXCustomFonctionContextMenu:SpawnCar(Vehicle, Pose)
    if IsModelInCdimage(Vehicle) then
        ESX.ShowNotification(NotificationContextMenu.LoadingCar)
        Wait(500)
        if Vehicle ~= nil then
            RequestModel(Vehicle)
            while not HasModelLoaded(Vehicle) do
                Wait(0)
            end
            local veh = CreateVehicle(Vehicle, Pose, GetEntityHeading(PlayerPedId()), true, true)
            ESX.ShowNotification(NotificationContextMenu.CarSpawn)
        end
    else
        ESX.ShowNotification(NotificationContextMenu.LoadingCar)
        Wait(1000)
        ESX.ShowNotification(NotificationContextMenu.CarNotWork)
    end
end
function ESXCustomFonctionContextMenu:LoadText(Texte)
    table.insert(TableMarker, {coords = PoseCursor, text = Texte})
end
function ESXCustomFonctionContextMenu:Graphisme(graphisme)
    SetTimecycleModifier(graphisme)
end
function ESXCustomFonctionContextMenu:Optimisation()
    DoScreenFadeIn(2000)
    ESX.ShowNotification("Optimisation en cours...", 3)
    DoScreenFadeOut(2000)
    Citizen.Wait(2000)
    DoScreenFadeIn(1500)
    ClearAllBrokenGlass()
    ClearAllHelpMessages()
    LeaderboardsReadClearAll()
    ClearBrief()
    ClearGpsFlags()
    ClearPrints()
    ClearSmallPrints()
    ClearReplayStats()
    LeaderboardsClearCacheData()
    ClearFocus()
    ClearHdArea()
    ClearHelp()
    ClearNotificationsPos()
    ClearPedInPauseMenu()
    ClearFloatingHelp()
    ClearGpsPlayerWaypoint()
    ClearGpsRaceTrack()
    ClearReminderMessage()
    ClearThisPrint()
    Citizen.Wait(2090)
    PlaySoundFrontend(-1, "Hack_Success", "DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS", true)
end
function ESXCustomFonctionContextMenu:NoClip()
    ESXCustomFonctionContextMenu:CloseMenu()
    CheckboxApuyer = true
    noclip = not noclip
    if noclip then
        FreezeEntityPosition(plyPed, true)
        SetEntityInvincible(plyPed, true)
        SetEntityCollision(plyPed, false, false)
        SetEntityVisible(plyPed, false, false)
        SetEveryoneIgnorePlayer(PlayerId(), true)
        SetPoliceIgnorePlayer(PlayerId(), true)
        ESX.ShowNotification(NotificationContextMenu.NoclipON)
    end
end

function ESXCustomFonctionContextMenu:RemoveMask(hitEntity)
    if Config.HandsupRequired ~= nil and Config.HandsupRequired then
        if ESXCustom_Function_ClientSide:GetPlayerHandsup(GetPlayerPed(NetworkGetPlayerIndexFromPed(hitEntity)), Config.AnimationsHandsupList) then
            TriggerServerEvent('ContextMenu:EnleveMask', GetPlayerServerId(NetworkGetPlayerIndexFromPed(hitEntity)))
        else
            ESX.ShowNotification(NotificationContextMenu.NotificationLeverMains)
        end
    else
        TriggerServerEvent('ContextMenu:EnleveMask', GetPlayerServerId(NetworkGetPlayerIndexFromPed(hitEntity)))
    end
end
function ESXCustomFonctionContextMenu:Facture(hitEntity)
    ESXCustomFonctionContextMenu:CloseMenu()
    local raison = ESXCustomFonctionContextMenu:Keyboard(ButtonContextMenu.FactureRaison, 999, "small_text")
    local montant = ESXCustomFonctionContextMenu:Keyboard(ButtonContextMenu.Amount, 15, "small_text")
    if raison ~= nil and montant ~= nil then
        TriggerServerEvent(ConfigContextMenu.Callback.CallBackSendBilling,  GetPlayerServerId(NetworkGetPlayerIndexFromPed(hitEntity)), 'society_'..ESX.PlayerData.job.name, raison, tonumber(montant))
        TriggerServerEvent("ContextMenu:SendMessage", GetPlayerServerId(NetworkGetPlayerIndexFromPed(hitEntity)), ESX.PlayerData.job.label, raison, tonumber(montant))
    end
end

function ESXCustomFonctionContextMenu:Fouille(hitEntity)
    if Config.HandsupRequired ~= nil and Config.HandsupRequired then
        if ESXCustom_Function_ClientSide:GetPlayerHandsup(GetPlayerPed(NetworkGetPlayerIndexFromPed(hitEntity)), Config.AnimationsHandsupList) then
            ESXCustomMenu:getPlayerInvGang(NetworkGetPlayerIndexFromPed(hitEntity), false)
            ESXCustomMenu:OPenGangMenuFouillez()
        else
            ESX.ShowNotification(NotificationContextMenu.NotificationLeverMains)
        end
    else
        ESXCustomMenu:getPlayerInvGang(NetworkGetPlayerIndexFromPed(hitEntity), false)
        ESXCustomMenu:OPenGangMenuFouillez()
    end
end
function ESXCustomFonctionContextMenu:CheckSellDrugs(hitEntity)
    if not DecorExistOn(hitEntity, 'AntiVente') then
        return true
    end
    return false
end
function ESXCustomFonctionContextMenu:Drugs(hitEntity, v)
    ESX.TriggerServerCallback("ContextMenu:CheckIfCops", function(CopsCo)
        if CopsCo then
            ESXCustomFonctionContextMenu:CloseMenu()
            ESX.TriggerServerCallback(v.callback, function(HasItem)
                if HasItem then
                    Chance = math.random(1, 5)
                    if Chance <= 3 then
                        ESXCustomFonctionContextMenu:MakeEntityFaceEntity(PlayerPedId(), hitEntity)
                        ESXCustomFonctionContextMenu:MakeEntityFaceEntity(hitEntity, PlayerPedId())
                        SetPedTalk(hitEntity)
                        PlayAmbientSpeech1(hitEntity, 'GENERIC_HI', 'SPEECH_PARAMS_STANDARD')
                        obj = CreateObject(GetHashKey('prop_weed_bottle'), 0, 0, 0, true)
                        AttachEntityToEntity(obj, PlayerPedId(), GetPedBoneIndex(PlayerPedId(),  57005), 0.13, 0.02, 0.0, -90.0, 0, 0, 1, 1, 0, 1, 0, 1)
                        obj2 = CreateObject(GetHashKey('hei_prop_heist_cash_pile'), 0, 0, 0, true)
                        AttachEntityToEntity(obj2, hitEntity, GetPedBoneIndex(hitEntity,  57005), 0.13, 0.02, 0.0, -90.0, 0, 0, 1, 1, 0, 1, 0, 1)
                        ESXCustomFonctionContextMenu:PlayAnim(PlayerPedId(), 'mp_common', 'givetake1_a', 8.0, -1, 0)
                        ESXCustomFonctionContextMenu:PlayAnim(hitEntity, 'mp_common', 'givetake1_a', 8.0, -1, 0)
                        Wait(1000)
                        AttachEntityToEntity(obj2, PlayerPedId(), GetPedBoneIndex(PlayerPedId(),  57005), 0.13, 0.02, 0.0, -90.0, 0, 0, 1, 1, 0, 1, 0, 1)
                        AttachEntityToEntity(obj, hitEntity, GetPedBoneIndex(hitEntity,  57005), 0.13, 0.02, 0.0, -90.0, 0, 0, 1, 1, 0, 1, 0, 1)
                        Wait(1000)
                        DeleteEntity(obj)
                        DeleteEntity(obj2)
                        PlayAmbientSpeech1(hitEntity, 'GENERIC_THANKS', 'SPEECH_PARAMS_STANDARD')
                        SetPedAsNoLongerNeeded(hitEntity)
                        ESX.ShowNotification(v.vente)
                        TriggerServerEvent("ContextMenu:DrugsMoula", PlayerPedId(), GetDistanceBetweenCoords(GetEntityCoords(hitEntity), GetEntityCoords(PlayerPedId())), v.ItemName, v.Item, v.prix, v.Count)
                        DecorSetInt(hitEntity, 'AntiVente', 0)
                        if ConfigContextMenu.Drugs.AppellePolice then
                            Chance2 = math.random(1, 5)
                            if Chance2 == 2 then
                                TriggerServerEvent("ContextMenu:SendMessageCops", PlayerPedId())
                                local playerCoords = GetEntityCoords(PlayerPedId())
                                TriggerServerEvent('ContextMenu:DrugsInProgress', {
                                    x = Round(playerCoords.x, 1),
                                    y = Round(playerCoords.y, 1),
                                    z = Round(playerCoords.z, 1)
                                })
                            end
                        end
                        Wait(5000)
                        ClearPedTasks(PlayerPedId())
                    else
                        ESXCustomFonctionContextMenu:MakeEntityFaceEntity(PlayerPedId(), hitEntity)
                        ESXCustomFonctionContextMenu:MakeEntityFaceEntity(hitEntity, PlayerPedId())
                        SetPedTalk(hitEntity)
                        PlayAmbientSpeech1(hitEntity, 'GENERIC_HI', 'SPEECH_PARAMS_STANDARD')
                        Wait(1000)
                        ESX.ShowNotification(NotificationContextMenu.MessageRefus)
                    end
                else
                    ESX.ShowNotification(v.error, false, false, nil)
                end
            end)
        else
            ESX.ShowNotification(NotificationContextMenu.MessagePasAsseDeFlic)
        end
    end)
end
function ESXCustomFonctionContextMenu:GiveItemMenu(hitEntity)
    ESXCustomFonctionContextMenu:CloseMenu()
    ESXCustomMenu:getPlayerInvGang(PlayerId(), true)
    ESXCustomMenu:OpenInventoryItems(GetPlayerServerId(NetworkGetPlayerIndexFromPed(hitEntity)), NetworkGetPlayerIndexFromPed(hitEntity))
end
function ESXCustomFonctionContextMenu:Poubelle(object)
    if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), GetEntityCoords(object), true) < 10.0 then
        ESXCustomFonctionContextMenu:CloseMenu()
        Citizen.CreateThread(function()
            TaskStartScenarioInPlace(PlayerPedId(), 'PROP_HUMAN_BUM_BIN', 0, true)
            Wait(10000)
            ClearPedTasksImmediately(PlayerPedId())
            GainPoubelle()
        end)
    end
end
function ESXCustomFonctionContextMenu:GiveItems(Item, Count, NomItem, LastEntityHit)
    TriggerServerEvent("ContextMenu:GiveLitemAujoueurs", PlayerPedId(), Item, Count, NomItem, GetEntityCoords(LastEntityHit))
end

function ESXCustomFonctionContextMenu:KeyboardInput(TextEntry, ExampleText, MaxStringLenght)
    if GetResourceState('pickax_ui') == 'started' then
        blockinput = true
        local result = exports['pickax_ui']:Input({ title = TextEntry, default = ExampleText, max = MaxStringLenght })
        Citizen.Wait(200)
        blockinput = false
        return result
    end
    AddTextEntry('FMMC_KEY_TIP1', TextEntry) 
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", ExampleText, "", "", "", MaxStringLenght)
    blockinput = true
    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do 
        Citizen.Wait(0)
    end
    if UpdateOnscreenKeyboard() ~= 2 then
        local result = GetOnscreenKeyboardResult() 
        Citizen.Wait(500) 
        blockinput = false
        return result 
    else
        Citizen.Wait(500) 
        blockinput = false 
        return nil 
    end
end
function ESXCustomFonctionContextMenu:Keyboard(Name, maxcaractere, textname)
    if textname == nil then textname = "small_text" end
    local amount = ESXCustomFonctionContextMenu:KeyboardInput(Name, "", maxcaractere)
    return amount
end
function ESXCustomFonctionContextMenu:saisiedepot()
    local amount = ESXCustomFonctionContextMenu:Keyboard(ButtonContextMenu.MoneyBankKeyboard, 15, "small_text")
    
    if amount ~= nil then
        amount = tonumber(amount)
    
        if type(amount) == 'number' then
            TriggerServerEvent('ContextMenuBank:deposer', amount)
        else
            ESX.ShowNotification(NotificationContextMenu.MauvaisMontant)
        end
    end
end
function ESXCustomFonctionContextMenu:saisieretrait()
    local amount = ESXCustomFonctionContextMenu:Keyboard(ButtonContextMenu.TakeMoneyKeyboard, 15, "small_text")
    if amount ~= nil then
        amount = tonumber(amount)
    
        if type(amount) == 'number' then
            TriggerServerEvent('ContextMenuBank:retirer', amount)
        else
            ESX.ShowNotification(NotificationContextMenu.MauvaisMontant)
        end
    end
end
function ESXCustomFonctionContextMenu:transferetopersonne()
    local to = ESXCustomFonctionContextMenu:Keyboard(ButtonContextMenu.IdOfPlayer, 5, "small_text")
    local amount = ESXCustomFonctionContextMenu:Keyboard(ButtonContextMenu.AmountToGiveMoney, 30, "small_text")
    TriggerServerEvent('ContextMenuBank:transfer', to, amount)
end
function ESXCustomFonctionContextMenu:CloseMenu()
    menuPool:CloseAllMenus()
end
function ESXCustomFonctionContextMenu:TakeWaterOrCoffee(object, money)
    AnnimForTake(PlayerPedId(), GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), GetEntityCoords(object), true))
    TriggerServerEvent("ContextMenu:removeMoney", PlayerPedId(), money, true, true)
end
function ESXCustomFonctionContextMenu:Machine(object, price, item)
    AnnimForTake(PlayerPedId(), GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), GetEntityCoords(object), true))
    TriggerServerEvent("ContextMenu:removeMoney", PlayerPedId(), price, false, false, item)
end
function ESXCustomFonctionContextMenu:SitChair(LastEntityHit)
    local pos = GetEntityCoords(LastEntityHit)
    TaskStartScenarioAtPosition(PlayerPedId(), "PROP_HUMAN_SEAT_BENCH", pos.x, pos.y, pos.z+0.5, GetEntityHeading(LastEntityHit)+180.0, 0, true, true)
    IlestAssis = true
end

function ESXCustomFonctionContextMenu:LiftChair()
    ClearPedTasksImmediately(PlayerPedId())
    IlestAssis = false
end
function ESXCustomFonctionContextMenu:LoadDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) RequestAnimDict(dict) end
end
function ESXCustomFonctionContextMenu:GetVehicleInfos(vehicleData)
    ESX.TriggerServerCallback('ContextMenu:getVehicleInfos', function(data)
        Citizen.SetTimeout(1000, function()
            vehicleStats = data
        end)
    end, vehicleData.plate)
end
function ESXCustomFonctionContextMenu:InTruck(vehicle)
    local player = ESX.Game.GetClosestPlayer()
    local playerPed = GetPlayerPed(player)
    if DoesEntityExist(playerPed) then
        if not IsEntityAttached(playerPed) or GetDistanceBetweenCoords(GetEntityCoords(playerPed), GetEntityCoords(PlayerPedId()), true) >= 5.0 then
            SetCarBootOpen(vehicle)
            Wait(350)
            AttachEntityToEntity(PlayerPedId(), vehicle, -1, 0.0, -2.2, 0.5, 0.0, 0.0, 0.0, false, false, false, false, 20, true)	
            ESXCustomFonctionContextMenu:LoadDict('timetable@floyd@cryingonbed@base')
            TaskPlayAnim(PlayerPedId(), 'timetable@floyd@cryingonbed@base', 'base', 8.0, -8.0, -1, 1, 0, false, false, false)
            Wait(50)
            inTrunk = true
            Wait(1500)
            SetVehicleDoorShut(vehicle, 5)
        else
            ESX.ShowNotification('Une personne est déjà dans le coffre!')
        end
    end
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(inTrunk and 0 or 500)   -- optimisation : plus de tour à chaque image hors du coffre
            if inTrunk then
                local vehicle = GetEntityAttachedTo(PlayerPedId())
                if DoesEntityExist(vehicle) or not IsPedDeadOrDying(PlayerPedId()) or not IsPedFatallyInjured(PlayerPedId()) then
                    local coords = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, 'boot'))
                    SetEntityCollision(PlayerPedId(), false, false)
                    SetTimecycleModifier("NG_blackout")
                    AddTextComponentSubstringPlayerName("")
                    AddTextEntry('TEST_LABEL', '~a~')
                    BeginTextCommandDisplayText('TEST_LABEL')
                    AddTextComponentSubstringPlayerName('Vous êtes dans un coffre ! ~b~[Y]~s~ Pour Quitter Coffre')
                    EndTextCommandDisplayText(0.125, 0.40)

                    if GetVehicleDoorAngleRatio(vehicle, 5) < 0.9 then
                        SetEntityVisible(PlayerPedId(), false, false)
                    else
                        if not IsEntityPlayingAnim(PlayerPedId(), 'timetable@floyd@cryingonbed@base', 3) then
                            ESXCustomFonctionContextMenu:LoadDict('timetable@floyd@cryingonbed@base')
                            TaskPlayAnim(PlayerPedId(), 'timetable@floyd@cryingonbed@base', 'base', 8.0, -8.0, -1, 1, 0, false, false, false)

                            SetEntityVisible(PlayerPedId(), true, false)
                        end
                    end
                    if IsControlJustReleased(0, 246) and inTrunk then
                        if GetVehicleDoorLockStatus(vehicle) == 2 then
                            ESX.ShowNotification(NotificationContextMenu.VehicleClose)
                        else
                            SetCarBootOpen(vehicle)
                            SetEntityCollision(PlayerPedId(), true, true)
                            Wait(750)
                            inTrunk = false
                            SetTimecycleModifier("default")
                            DetachEntity(PlayerPedId(), true, true)
                            SetEntityVisible(PlayerPedId(), true, false)
                            ClearPedTasks(PlayerPedId())
                            SetEntityCoords(PlayerPedId(), GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, -0.5, -0.75))
                            Wait(250)
                            SetVehicleDoorShut(vehicle, 5)
                        end
                    end
                else
                    SetEntityCollision(PlayerPedId(), true, true)
                    DetachEntity(PlayerPedId(), true, true)
                    SetEntityVisible(PlayerPedId(), true, false)
                    ClearPedTasks(PlayerPedId())
                    SetEntityCoords(PlayerPedId(), GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, -0.5, -0.75))
                end
            end
        end
    end)
end
function ESXCustomFonctionContextMenu:InfoVeh(vehicle)
    vehicleStats = nil
    local vehicleData = GetVehicleProperties(vehicle)
    ESXCustomFonctionContextMenu:GetVehicleInfos(vehicleData)
    local Moteur,Suspension,Freins,Turbo,Armure,Transmission=GetVehicleMod(vehicle,11)+1,GetVehicleMod(vehicle,15)+1,GetVehicleMod(vehicle,12)+1,IsToggleModOn(vehicle,18)and"~g~Oui"or"~r~Non",GetVehicleMod(vehicle, 16)+1,GetVehicleMod(vehicle, 13)+1
    ESX.ShowNotification(NotificationContextMenu.WaitBDD)
    Wait(2000)
    local owner = ""
    if not vehicleStats.owner then
        owner = "Jean Moldu"
    else
        owner = vehicleStats.owner
    end
    ESX.ShowNotification((NotificationContextMenu.InfoVeh):format(Moteur, Freins, Suspension, Turbo, Armure, Transmission, GetVehicleFuelLevel(vehicle), vehicleStats.plate, owner))
end
function ESXCustomFonctionContextMenu:KickAllVeh(LastEntityHit)
    ped1 = GetPedInVehicleSeat(LastEntityHit, -1)
    ped2 = GetPedInVehicleSeat(LastEntityHit, 0)
    ped3 = GetPedInVehicleSeat(LastEntityHit, 1)
    ped4 = GetPedInVehicleSeat(LastEntityHit, 2)
    local LastEntityHit = GetVehiclePedIsIn(ped1, false)
    TaskLeaveVehicle(ped1, LastEntityHit, 64)
    local LastEntityHit = GetVehiclePedIsIn(ped2, false)
    TaskLeaveVehicle(ped2, LastEntityHit, 64)
    local LastEntityHit = GetVehiclePedIsIn(ped3, false)
    TaskLeaveVehicle(ped3, LastEntityHit, 64)
    local LastEntityHit = GetVehiclePedIsIn(ped4, false)
    TaskLeaveVehicle(ped4, LastEntityHit, 64)
end
function ESXCustomFonctionContextMenu:CustomVehicle(vehicle, level, typeMod)
    if typeMod == "moteur" then
        SetVehicleProperties(vehicle, {modEngine = level})
        ESX.ShowNotification((NotificationContextMenu.CustomEngine):format(level+1))
    elseif typeMod == "freins" then
        SetVehicleProperties(vehicle, {modBrakes = level})
        ESX.ShowNotification((NotificationContextMenu.CustomBrake):format(level+1))
    elseif typeMod == "transmissions" then
        SetVehicleProperties(vehicle, {modTransmission = level})
        ESX.ShowNotification((NotificationContextMenu.CustomTransmissions):format(level+1))
    elseif typeMod == "suspension" then
        SetVehicleProperties(vehicle, {modSuspension = level})
        ESX.ShowNotification((NotificationContextMenu.CustomSuspension):format(level+1))
    end
end
function ESXCustomFonctionContextMenu:TurboVeh(vehicle)
    if IsToggleModOn(vehicle, 18) then
        SetVehicleProperties(vehicle, {modTurbo = 0})
        ESX.ShowNotification(NotificationContextMenu.TurboTrue)
    else
        SetVehicleProperties(vehicle, {modTurbo = 1})
        ESX.ShowNotification(NotificationContextMenu.TurboFalse)
    end
end
function ESXCustomFonctionContextMenu:DonnerArgent(LastEntityHit, item, account, amount)
    if GetDistanceBetweenCoords(GetEntityCoords(LastEntityHit), GetEntityCoords(PlayerPedId())) < 10.0 then
        TriggerServerEvent(ConfigContextMenu.Triggers.TriggerGiveInventoryItem, GetPlayerServerId(NetworkGetPlayerIndexFromPed(LastEntityHit)), item, account, amount)
    end
end
function ESXCustomFonctionContextMenu:Player(hitEntity)
    return GetPlayerServerId(NetworkGetPlayerIndexFromPed(hitEntity)) 
end
function ESXCustomFonctionContextMenu:GetPlayer(hitEntity)
    return GetPlayerPed(NetworkGetPlayerIndexFromPed(hitEntity))
end
function ESXCustomFonctionContextMenu:MonID()
    return GetPlayerServerId(PlayerId())
end
function ESXCustomFonctionContextMenu:GetJobs(JobsName)
    if ESX.PlayerData.job.name == JobsName then
        return true
    else
        return false
    end
end
ESXCustomMenu = {}
function ESXCustomMenu:OpenMenuMessage()
    local mainmenu = RageUI.CreateMenu(ButtonContextMenu.ManagementText, ButtonContextMenu.WhatYouWant)
    local gestionmessage = RageUI.CreateSubMenu(mainmenu, ButtonContextMenu.ManagementText, ButtonContextMenu.WhatYouWant)
    RageUI.Visible(mainmenu, not RageUI.Visible(mainmenu))
    while mainmenu do
        Wait(0)
        RageUI.IsVisible(mainmenu, true, true, true, function()
            if #TableMarker ~= 0 then
                for k, v in ipairs(TableMarker) do
                    RageUI.ButtonWithStyle(v.text, nil, {RightLabel = "→→→"}, true, function(_,_,s)
                        coords = v.coords
                        text = v.text
                    end, gestionmessage)
                end
            else
                RageUI.ButtonWithStyle(ButtonContextMenu.NoText, nil, {RightLabel = "→→→"}, false, function(_,_,s)
                end)
            end
        end)
        RageUI.IsVisible(gestionmessage, true, true, true, function()
            RageUI.ButtonWithStyle(ButtonContextMenu.TPOnText, nil, {RightLabel = "→→→"}, true, function(_,_,s)
                if s then
                    SetEntityCoords(PlayerPedId(), coords)
                end
            end)
            RageUI.ButtonWithStyle(ButtonContextMenu.ChangeText, nil, {RightLabel = "→→→"}, true, function(_,_,s)
                if s then
                    local newresult = ESXCustomFonctionContextMenu:Keyboard(ButtonContextMenu.TextWhoWant, 999, "small_text")
                    text = newresult
                    table.remove(TableMarker, k)
                    table.insert(TableMarker, {coords = coords, text = text})
                end
            end)
            RageUI.ButtonWithStyle(ButtonContextMenu.DeleteText, nil, {RightLabel = "→→→"}, true, function(_,_,s)
                if s then
                    table.remove(TableMarker, k)
                end
            end)
        end)
    
        if not RageUI.Visible(mainmenu) and not RageUI.Visible(gestionmessage) then 
            mainmenu = RMenu:DeleteType("mainmenu")
        end
    end
end
function ESXCustomMenu:OpenGiveitems(AuGars)
    local DataItems = {}
    ESX.TriggerServerCallback('ContextMenu:GetItems', function(data)
        DataItems = data
    end)
    
    local mainmenu = RageUI.CreateMenu(ButtonContextMenu.GiveItemNameMenu, ButtonContextMenu.WhatYouWant)
    local textxte = nil
    if AuGars == PlayerPedId() then
        LeJ = nil
    else
        LeJ = AuGars
    end
    RageUI.Visible(mainmenu, not RageUI.Visible(mainmenu))
    while mainmenu do
        Wait(0)
        RageUI.IsVisible(mainmenu, true, true, true, function()
            if LeJ == nil then
                RageUI.Separator(ButtonContextMenu.YouGiveAtYou)
            else
                RageUI.Separator(ButtonContextMenu.YouGiveAtPlayer)
            end
            RageUI.ButtonWithStyle(ButtonContextMenu.Research, nil, {RightLabel = "→→→"}, true, function(_,_,s)
                if s then
                    local amount = ESXCustomFonctionContextMenu:Keyboard(ButtonContextMenu.Amount, 8, "small_text")
                    textxte = amount
                end
            end)
            RageUI.Checkbox(ButtonContextMenu.UsableItem, nil, RechercheConsomable, { Style = RageUI.CheckboxStyle.Tick }, function(Hovered, Selected, Active, Checked)
                RechercheConsomable = Checked;
            end, function()
                RechercheConsomable = true
            end, function()
                RechercheConsomable = false
            end)
            RageUI.Separator(ButtonContextMenu.ListOfItem)
            if textxte ~= nil then
                for k,v in pairs(DataItems) do
                    if starts(v.label:lower(), textxte:lower()) then
                        if RechercheConsomable then
                            -- for k,v in pairs(DataItems) do
                                if v.usable then
                                    RageUI.ButtonWithStyle((ButtonContextMenu.ItemGiveItem):format(v.label, v.name), nil, {RightLabel = "→→→"}, true, function(_,_,s)
                                        if s then
                                            TriggerServerEvent("CorePickax:GiveItemStaffRapide", PlayerPedId(), v.name, v.label, LeJ)
                                        end
                                    end)
                                end
                            -- end
                        else
                            -- for k,v in pairs(DataItems) do
                                RageUI.ButtonWithStyle((ButtonContextMenu.ItemGiveItem):format(v.label, v.name), nil, {RightLabel = "→→→"}, true, function(_,_,s)
                                    if s then
                                        TriggerServerEvent("CorePickax:GiveItemStaffRapide", PlayerPedId(), v.name, v.label, LeJ)
                                    end
                                end)
                            -- end
                        end
                    end
                end
            else
                if RechercheConsomable then
                    for k,v in pairs(DataItems) do
                        if v.usable then
                            RageUI.ButtonWithStyle((ButtonContextMenu.ItemGiveItem):format(v.label, v.name), nil, {RightLabel = "→→→"}, true, function(_,_,s)
                                if s then
                                    TriggerServerEvent("CorePickax:GiveItemStaffRapide", PlayerPedId(), v.name, v.label, LeJ)
                                end
                            end)
                        end
                    end
                else
                    for k,v in pairs(DataItems) do
                        RageUI.ButtonWithStyle((ButtonContextMenu.ItemGiveItem):format(v.label, v.name), nil, {RightLabel = "→→→"}, true, function(_,_,s)
                            if s then
                                TriggerServerEvent("CorePickax:GiveItemStaffRapide", PlayerPedId(), v.name, v.label, LeJ)
                            end
                        end)
                    end
                end
            end
        end)
    
        if not RageUI.Visible(mainmenu) then 
            mainmenu = RMenu:DeleteType("mainmenu")
        end
    end
end
function ESXCustomMenu:getPlayerInvGang(player, fouillepas)
    Items = {}
    Armes = {}
    ArgentSale = {}
    Ammo = {}
    if fouillepas then
        ESX.TriggerServerCallback('ContextMenu:getOtherPlayerData1', function(data)
            RageUI.Separator(ButtonContextMenu.HisWeapon)
            if ConfigContextMenu.ArmesItem then
                RageUI.Separator(ButtonContextMenu.HisAmmo)
                for i = 1, #data.inventory, 1 do
                    if data.inventory[i].count > 0 then
                        local invCount = {}
                    
                        for i = 1, data.inventory[i].count, 1 do
                            table.insert(invCount, i)
                        end
                    
                        if string.find(data.inventory[i].name, "ammo_") then
                            table.insert(Ammo, {
                                label    = data.inventory[i].label,
                                right    = data.inventory[i].count,
                                value    = data.inventory[i].name,
                                itemType = 'item_standard',
                                amount   = data.inventory[i].count
                            })
                        end
                    end
                end
                RageUI.Separator(ButtonContextMenu.HisWeapon)
                for i = 1, #data.inventory, 1 do
                    if data.inventory[i].count > 0 then
                        local invCount = {}
                    
                        for i = 1, data.inventory[i].count, 1 do
                            table.insert(invCount, i)
                        end
                    
                        if string.find(data.inventory[i].name, "weapon_") then
                            table.insert(Armes, {
                                label    = data.inventory[i].label,
                                right    = data.inventory[i].count,
                                value    = data.inventory[i].name,
                                itemType = 'item_standard',
                                amount   = data.inventory[i].count
                            })
                        end
                    end
                end
                RageUI.Separator(ButtonContextMenu.HisItems)
                for i=1, #data.inventory, 1 do
                    if data.inventory[i].count > 0 then
                        if not string.find(data.inventory[i].name, "weapon_") and not string.find(data.inventory[i].name, "ammo_") then
                            table.insert(Items, {
                                label    = data.inventory[i].label,
                                right    = data.inventory[i].count,
                                value    = data.inventory[i].name,
                                itemType = 'item_standard',
                                amount   = data.inventory[i].count
                            })
                        end
                    end
                end
            else
                for i=1, #data.weapons, 1 do
                    table.insert(Armes, {
                        label    = ESX.GetWeaponLabel(data.weapons[i].name),
                        value    = data.weapons[i].name,
                        right    = data.weapons[i].ammo,
                        itemType = 'item_weapon',
                        amount   = data.weapons[i].ammo
                    })
                end
                RageUI.Separator(ButtonContextMenu.HisItems)
                for i=1, #data.inventory, 1 do
                    if data.inventory[i].count > 0 then
                        table.insert(Items, {
                            label    = data.inventory[i].label,
                            right    = data.inventory[i].count,
                            value    = data.inventory[i].name,
                            itemType = 'item_standard',
                            amount   = data.inventory[i].count
                        })
                    end
                end
            end

            for i=1, #data.accounts, 1 do
                table.insert(ArgentSale, {
                    name = data.accounts[i].name,
                    value = data.accounts[i].money,
                    itemType = 'item_account'
                })
            end
        end, GetPlayerServerId(player))
    else
        ESX.TriggerServerCallback('ContextMenu:getOtherPlayerData', function(data)
            if ConfigContextMenu.ArmesItem then
                RageUI.Separator(ButtonContextMenu.HisAmmo)
                for i = 1, #data.inventory, 1 do
                    if data.inventory[i].count > 0 then
                        local invCount = {}
                    
                        for i = 1, data.inventory[i].count, 1 do
                            table.insert(invCount, i)
                        end
                    
                        if string.find(data.inventory[i].name, "ammo_") then
                            table.insert(Ammo, {
                                label    = data.inventory[i].label,
                                right    = data.inventory[i].count,
                                value    = data.inventory[i].name,
                                itemType = 'item_standard',
                                amount   = data.inventory[i].count
                            })
                        end
                    end
                end
                RageUI.Separator(ButtonContextMenu.HisWeapon)
                for i = 1, #data.inventory, 1 do
                    if data.inventory[i].count > 0 then
                        local invCount = {}
                    
                        for i = 1, data.inventory[i].count, 1 do
                            table.insert(invCount, i)
                        end
                    
                        if string.find(data.inventory[i].name, "weapon_") then
                            table.insert(Armes, {
                                label    = data.inventory[i].label,
                                right    = data.inventory[i].count,
                                value    = data.inventory[i].name,
                                itemType = 'item_standard',
                                amount   = data.inventory[i].count
                            })
                        end
                    end
                end
                RageUI.Separator(ButtonContextMenu.HisItems)
                for i=1, #data.inventory, 1 do
                    if data.inventory[i].count > 0 then
                        if not string.find(data.inventory[i].name, "weapon_") and not string.find(data.inventory[i].name, "ammo_") then
                            table.insert(Items, {
                                label    = data.inventory[i].label,
                                right    = data.inventory[i].count,
                                value    = data.inventory[i].name,
                                itemType = 'item_standard',
                                amount   = data.inventory[i].count
                            })
                        end
                    end
                end
            else
                for i=1, #data.weapons, 1 do
                    table.insert(Armes, {
                        label    = ESX.GetWeaponLabel(data.weapons[i].name),
                        value    = data.weapons[i].name,
                        right    = data.weapons[i].ammo,
                        itemType = 'item_weapon',
                        amount   = data.weapons[i].ammo
                    })
                end
                RageUI.Separator(ButtonContextMenu.HisItems)
                for i=1, #data.inventory, 1 do
                    if data.inventory[i].count > 0 then
                        table.insert(Items, {
                            label    = data.inventory[i].label,
                            right    = data.inventory[i].count,
                            value    = data.inventory[i].name,
                            itemType = 'item_standard',
                            amount   = data.inventory[i].count
                        })
                    end
                end
            end

            for i=1, #data.accounts, 1 do
                table.insert(ArgentSale, {
                    name = data.accounts[i].name,
                    value = data.accounts[i].money,
                    itemType = 'item_account'
                })
            end
        end, GetPlayerServerId(player))
    end
end
function ESXCustomMenu:OPenGangMenuFouillez()
    local MenuGangSub = RageUI.CreateMenu(ButtonContextMenu.SearchMenu, ButtonContextMenu.WhatYouWant)
    RageUI.Visible(MenuGangSub, not RageUI.Visible(MenuGangSub))
    while MenuGangSub do
        Citizen.Wait(0)
        RageUI.IsVisible(MenuGangSub, true, true, true, function()
            local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
            RageUI.Separator((ButtonContextMenu.YouSearch):format(GetPlayerName(closestPlayer)))
            if ConfigContextMenu.ArmesItem then
                for k,v  in pairs(ArgentSale) do
                    if v.name == "black_money" then
                        RageUI.ButtonWithStyle(ButtonContextMenu.BlackMoneyDetecte, nil, {RightLabel = (ButtonContextMenu.RightLabelBlackMoney):format(v.value)}, true, function(_, _, s)
                            if s then
                                local combien = ESXCustomFonctionContextMenu:Keyboard(ButtonContextMenu.Amount, 8, "small_text")
                                if tonumber(combien) > v.amount then
                                    ESX.ShowNotification(ButtonContextMenu.InvalidAmount)
                                else
                                    TriggerServerEvent('ContextMenu:confiscatePlayerItem', GetPlayerServerId(closestPlayer), v.itemType, v.value, tonumber(combien))
                                end
                                RageUI.GoBack()
                            end
                        end)
                    end
                end
            
                RageUI.Separator(ButtonContextMenu.HisItems)
                for k,v  in pairs(Items) do
                    if v.amount > 0 then
                        RageUI.ButtonWithStyle(v.label, nil, {RightLabel = (ButtonContextMenu.RightLabel):format(v.right)}, true, function(_, _, s)
                            if s then
                                local combien = ESXCustomFonctionContextMenu:Keyboard(ButtonContextMenu.Amount, 8, "small_text")
                                if tonumber(combien) > v.amount then
                                    ESX.ShowNotification(ButtonContextMenu.InvalidAmount)
                                else
                                    TriggerServerEvent('ContextMenu:confiscatePlayerItem', GetPlayerServerId(closestPlayer), v.itemType, v.value, tonumber(combien))
                                end
                                RageUI.GoBack()
                            end
                        end)
                    end
                end
                RageUI.Separator(ButtonContextMenu.HisAmmo)
                for k,v  in pairs(Ammo) do
                    if v.amount > 0 then
                        RageUI.ButtonWithStyle(v.label, nil, {RightLabel = (ButtonContextMenu.RightLabel):format(v.right)}, true, function(_, _, s)
                            if s then
                                local combien = ESXCustomFonctionContextMenu:Keyboard(ButtonContextMenu.Amount, 8, "small_text")
                                if tonumber(combien) > v.amount then
                                    ESX.ShowNotification(ButtonContextMenu.InvalidAmount)
                                else
                                    TriggerServerEvent('ContextMenu:confiscatePlayerItem', GetPlayerServerId(closestPlayer), v.itemType, v.value, tonumber(combien))
                                end
                                RageUI.GoBack()
                            end
                        end)
                    end
                end
                RageUI.Separator(ButtonContextMenu.HisWeapon)
                for k,v  in pairs(Armes) do
                    if v.amount > 0 then
                        if Config.ArmesPerm[v.value] then
                            RageUI.ButtonWithStyle(v.label, nil, {RightBadge = RageUI.BadgeStyle.Lock}, false, function()end)
                        else
                            RageUI.ButtonWithStyle(v.label, nil, {RightLabel = (ButtonContextMenu.RightLabel):format(v.right)}, true, function(_, _, s)
                                if s then
                                    local combien = ESXCustomFonctionContextMenu:Keyboard(ButtonContextMenu.Amount, 8, "small_text")
                                    if tonumber(combien) > v.amount then
                                        ESX.ShowNotification(ButtonContextMenu.InvalidAmount)
                                    else
                                        TriggerServerEvent('ContextMenu:confiscatePlayerItem', GetPlayerServerId(closestPlayer), v.itemType, v.value, tonumber(combien))
                                    end
                                    RageUI.GoBack()
                                end
                            end)
                        end
                    end
                end
            else
                RageUI.Separator(ButtonContextMenu.HisBlackMoney)
                for k,v  in pairs(ArgentSale) do
                    if v.name == "black_money" then
                        RageUI.ButtonWithStyle(ButtonContextMenu.BlackMoneyDetecte, nil, {RightLabel = (ButtonContextMenu.RightLabelBlackMoney):format(v.value)}, true, function(_, _, s)
                            if s then
                                local combien = ESXCustomFonctionContextMenu:Keyboard(ButtonContextMenu.Amount, 8, "small_text")
                                if tonumber(combien) > v.amount then
                                    ESX.ShowNotification(ButtonContextMenu.InvalidAmount)
                                else
                                    TriggerServerEvent('ContextMenu:confiscatePlayerItem', GetPlayerServerId(closestPlayer), v.itemType, v.value, tonumber(combien))
                                end
                                RageUI.GoBack()
                            end
                        end)
                    end
                end
            
                RageUI.Separator(ButtonContextMenu.HisItems)
            
                for k,v  in pairs(Items) do
                    if v.amount > 0 then
                        RageUI.ButtonWithStyle(v.label, nil, {RightLabel = (ButtonContextMenu.RightLabel):format(v.right)}, true, function(_, _, s)
                            if s then
                                local combien = ESXCustomFonctionContextMenu:Keyboard(ButtonContextMenu.Amount, 8, "small_text")
                                if tonumber(combien) > v.amount then
                                    ESX.ShowNotification(ButtonContextMenu.InvalidAmount)
                                else
                                    TriggerServerEvent('ContextMenu:confiscatePlayerItem', GetPlayerServerId(closestPlayer), v.itemType, v.value, tonumber(combien))
                                end
                                RageUI.GoBack()
                            end
                        end)
                    end
                end
            
                RageUI.Separator(ButtonContextMenu.HisWeapon)
                for k,v  in pairs(Armes) do
                    if v.amount > 0 then
                        if Config.ArmesPerm[v.value] then
                            RageUI.ButtonWithStyle(v.label, nil, {RightBadge = RageUI.BadgeStyle.Lock}, false, function()end)
                        else
                            RageUI.ButtonWithStyle(v.label, nil, {RightLabel = (ButtonContextMenu.RightLabel):format(v.right)}, true, function(_, _, s)
                                if s then
                                    local combien = ESXCustomFonctionContextMenu:Keyboard(ButtonContextMenu.Amount, 8, "small_text")
                                    if tonumber(combien) > v.amount then
                                        ESX.ShowNotification(ButtonContextMenu.InvalidAmount)
                                    else
                                        TriggerServerEvent('ContextMenu:confiscatePlayerItem', GetPlayerServerId(closestPlayer), v.itemType, v.value, tonumber(combien))
                                    end
                                    RageUI.GoBack()
                                end
                            end)
                        end
                    end
                end
            end
        end, function() 
        end)
    end
end
function ESXCustomMenu:OpenInventoryItems(player, hitEntity)
    local MenuGangSub = RageUI.CreateMenu(ButtonContextMenu.YourInventory, ButtonContextMenu.WhatYouWant)
    RageUI.Visible(MenuGangSub, not RageUI.Visible(MenuGangSub))
    while MenuGangSub do
        Citizen.Wait(0)
        RageUI.IsVisible(MenuGangSub, true, true, true, function()
            RageUI.Separator((ButtonContextMenu.YouGiveOn):format(GetPlayerName(hitEntity)))
            if ConfigContextMenu.ArmesItem then
                RageUI.Separator(ButtonContextMenu.HisItems)
                for k,v  in pairs(Items) do
                    if v.amount > 0 then
                        RageUI.ButtonWithStyle(v.label, nil, {RightLabel = (ButtonContextMenu.RightLabel):format(v.right)}, true, function(_, _, s)
                            if s then
                                local amount = ESXCustomFonctionContextMenu:Keyboard(ButtonContextMenu.Amount, 15, "small_text")
                            
                                if amount ~= nil then
                                    amount = tonumber(amount)
                                
                                    if type(amount) == 'number' then
                                        TriggerServerEvent(ConfigContextMenu.Triggers.TriggerGiveInventoryItem, player, 'item_standard', v.value, amount)
                                    else
                                        ESX.ShowNotification(NotificationContextMenu.MauvaisMontant)
                                    end
                                end
                                RageUI.CloseAll()
                            end
                        end)
                    end
                end
                RageUI.Separator(ButtonContextMenu.HisAmmo)
                for k,v  in pairs(Ammo) do
                    if v.amount > 0 then
                        RageUI.ButtonWithStyle(v.label, nil, {RightLabel = (ButtonContextMenu.RightLabel):format(v.right)}, true, function(_, _, s)
                            if s then
                                local amount = ESXCustomFonctionContextMenu:Keyboard(ButtonContextMenu.Amount, 15, "small_text")
                            
                                if amount ~= nil then
                                    amount = tonumber(amount)
                                
                                    if type(amount) == 'number' then
                                        TriggerServerEvent(ConfigContextMenu.Triggers.TriggerGiveInventoryItem, player, 'item_standard', v.value, amount)
                                    else
                                        ESX.ShowNotification(NotificationContextMenu.MauvaisMontant)
                                    end
                                end
                                RageUI.CloseAll()
                            end
                        end)
                    end
                end
                RageUI.Separator(ButtonContextMenu.HisWeapon)
                for k,v  in pairs(Armes) do
                    if v.amount > 0 then
                        if Config.ArmesPerm[v.value] then
                            RageUI.ButtonWithStyle(v.label, nil, {RightBadge = RageUI.BadgeStyle.Lock}, false, function()end)
                        else
                            RageUI.ButtonWithStyle(v.label, nil, {RightLabel = (ButtonContextMenu.RightLabel):format(v.right)}, true, function(_, _, s)
                                if s then
                                    local amount = ESXCustomFonctionContextMenu:Keyboard(ButtonContextMenu.Amount, 15, "small_text")
                                
                                    if amount ~= nil then
                                        amount = tonumber(amount)
                                    
                                        if type(amount) == 'number' then
                                            TriggerServerEvent(ConfigContextMenu.Triggers.TriggerGiveInventoryItem, player, 'item_standard', v.value, amount)
                                        else
                                            ESX.ShowNotification(NotificationContextMenu.MauvaisMontant)
                                        end
                                    end
                                    RageUI.CloseAll()
                                end
                            end)
                        end
                    end
                end
            else
                RageUI.Separator(ButtonContextMenu.HisItems)
                for k,v  in pairs(Items) do
                    if v.amount > 0 then
                        RageUI.ButtonWithStyle(v.label, nil, {RightLabel = (ButtonContextMenu.RightLabel):format(v.right)}, true, function(_, _, s)
                            if s then
                                local amount = ESXCustomFonctionContextMenu:Keyboard(ButtonContextMenu.Amount, 15, "small_text")
                            
                                if amount ~= nil then
                                    amount = tonumber(amount)
                                
                                    if type(amount) == 'number' then
                                        TriggerServerEvent(ConfigContextMenu.Triggers.TriggerGiveInventoryItem, player, 'item_standard', v.value, amount)
                                    else
                                        ESX.ShowNotification(NotificationContextMenu.MauvaisMontant)
                                    end
                                end
                                RageUI.CloseAll()
                            end
                        end)
                    end
                end
                RageUI.Separator(ButtonContextMenu.HisWeapon)
                for k,v  in pairs(Armes) do
                    if v.amount > 0 then
                        if Config.ArmesPerm[v.value] then
                            RageUI.ButtonWithStyle(v.label, nil, {RightBadge = RageUI.BadgeStyle.Lock}, false, function()end)
                        else
                            RageUI.ButtonWithStyle(v.label, nil, {RightLabel = (ButtonContextMenu.RightLabel):format(v.right)}, true, function(_, _, s)
                                if s then
                                    local ammo = GetAmmoInPedWeapon(PlayerPedId(), weaponHash)
                                    TriggerServerEvent(ConfigContextMenu.Triggers.TriggerGiveInventoryItem, player, 'item_weapon', v.value, ammo)
                                    RageUI.GoBack()
                                end
                            end)
                        end
                    end
                end
            end
        end, function() 
        end)
    end
end

if ConfigContextMenu.Drugs.AppellePolice then
    RegisterNetEvent('ContextMenu:DrugsInProgress')
    AddEventHandler('ContextMenu:DrugsInProgress', function(targetCoords)
        local thiefBlip = AddBlipForRadius(targetCoords.x, targetCoords.y, targetCoords.z, 50.0)

        SetBlipHighDetail(thiefBlip, true)
        SetBlipColour(thiefBlip, 1)
        SetBlipAlpha(thiefBlip, 250)
        SetBlipAsShortRange(thiefBlip, true)

        Citizen.CreateThread(function()
            while true do
                Citizen.Wait(ConfigContextMenu.Drugs.BlipsRemoveAfter)

                RemoveBlip(thiefBlip)
                break
            end
        end)
    end)
end

--Maj
local ActualConfigTarget = {}
CounteurAtPoseTable = {}
CounteurAtPose = 0
Citizen.CreateThread(function()
    _AtPose()
    ActualConfigTarget = Action_Config.AtPose

	while true do
		local timer = 250
		local plyCoords = GetEntityCoords(GetPlayerPed(-1), false)

		for k, v in pairs(ActualConfigTarget) do
			local dist = Vdist(plyCoords.x, plyCoords.y, plyCoords.z, v.Coords.x, v.Coords.y, v.Coords.z)
			local height = (v.height or 0.02)

			if dist < (v.MaxCoords or 3) then
				if IsControlPressed(0, 19) then
                    _AtPose()
					timer = 0

                    if not CounteurAtPoseTable[k] then
                        CounteurAtPoseTable[k] = true
                        CounteurAtPose = CounteurAtPose +1
                    end

					DrawGlobalMarker(6, v.Coords, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, height, height, height, 0, 166, 255, 255, false, true, 0, false, false, false, false)
				end

			end
		end

        if IsControlJustReleased(0, 19) then
            CounteurAtPose = 0
            CounteurAtPoseTable = {}
        end
		Wait(timer)
	end
end)
