-- ─────────────────────────────── Props du métier (client) ───────────────────────────────
-- Menu F6 → « Props du métier » : liste des props, mode placement (fantôme semi-transparent), retrait.
local placing = false

local function hint(text)
    if GetResourceState('pickax_notify') == 'started' then exports['pickax_notify']:ShowHelpNotification(text) return end
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, false, -1)
end

local function rotationToDirection(rot)
    local z, x = math.rad(rot.z), math.rad(rot.x)
    local num = math.abs(math.cos(x))
    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

-- Point visé par la caméra (max `dist` mètres) ; nil si rien n'est touché
local function aimPoint(dist)
    local from = GetGameplayCamCoord()
    local to = from + rotationToDirection(GetGameplayCamRot(2)) * dist
    local handle = StartExpensiveSynchronousShapeTestLosProbe(from.x, from.y, from.z, to.x, to.y, to.z, 1 + 16 + 256, PlayerPedId(), 4)
    local _, hit, coords = GetShapeTestResult(handle)
    if hit == 1 then return coords end
    return nil
end

function OpenPropsMenu()
    ESX.TriggerServerCallback('jobbuilder:props:list', function(res)
        if not res or not res.ok then return JBNotify('~r~' .. ((res and res.error) or 'Props indisponibles')) end
        OpenUI({ action = 'open', kind = 'props', data = res })
    end)
end

-- Mode placement : fantôme devant le joueur, flèches / molette = tourner, ENTRÉE = poser, RETOUR = annuler
local function placeProp(entry)
    if placing then return end
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then return JBNotify('~r~Descends du véhicule d\'abord.') end
    local hash = joaat(entry.model)
    if not IsModelInCdimage(hash) then return JBNotify('~r~Modèle introuvable sur ce serveur.') end
    RequestModel(hash)
    local t = GetGameTimer() + 4000
    while not HasModelLoaded(hash) and GetGameTimer() < t do Wait(10) end
    if not HasModelLoaded(hash) then return JBNotify('~r~Modèle introuvable.') end
    placing = true
    local maxDist = (Config.Props.PlaceDistance or 10.0)
    local c = GetEntityCoords(ped)
    local ghost = CreateObject(hash, c.x, c.y, c.z, false, false, false)
    SetEntityAlpha(ghost, 150, false)
    SetEntityCollision(ghost, false, false)
    FreezeEntityPosition(ghost, true)
    local heading = GetEntityHeading(ped)
    local result = nil
    while placing do
        Wait(0)
        ped = PlayerPedId()
        DisableControlAction(0, 24, true) DisableControlAction(0, 25, true) DisableControlAction(0, 257, true) DisableControlAction(0, 37, true)
        DisableControlAction(0, 140, true) DisableControlAction(0, 141, true) DisableControlAction(0, 142, true)
        local pos = aimPoint(maxDist)
        local pc = GetEntityCoords(ped)
        if not pos then
            local f = GetOffsetFromEntityInWorldCoords(ped, 0.0, 3.0, 0.0)
            pos = vector3(f.x, f.y, pc.z)
        end
        SetEntityCoordsNoOffset(ghost, pos.x, pos.y, pos.z + 1.0, false, false, false)
        PlaceObjectOnGroundProperly(ghost)
        local step = IsControlPressed(0, 21) and 3.0 or 1.2
        if IsControlPressed(0, 174) then heading = heading - step end
        if IsControlPressed(0, 175) then heading = heading + step end
        if IsControlJustPressed(0, 15) then heading = heading + 8.0 end
        if IsControlJustPressed(0, 14) then heading = heading - 8.0 end
        SetEntityHeading(ghost, heading % 360.0)
        local gc = GetEntityCoords(ghost)
        local tooFar = #(pc - gc) > maxDist + 1.0
        SetEntityAlpha(ghost, tooFar and 60 or 150, false)
        hint(('%s\n~INPUT_CELLPHONE_LEFT~ ~INPUT_CELLPHONE_RIGHT~ / molette : tourner (MAJ = vite)\n~INPUT_FRONTEND_ACCEPT~ poser   ~INPUT_FRONTEND_RRIGHT~ annuler'):format(entry.label))
        if IsControlJustPressed(0, 201) or IsControlJustPressed(0, 191) then
            if tooFar then JBNotify('~r~Trop loin : rapproche-toi.')
            else result = { x = gc.x, y = gc.y, z = gc.z, h = GetEntityHeading(ghost) } placing = false end
        elseif IsControlJustPressed(0, 177) or IsControlJustPressed(0, 202) or IsEntityDead(ped) then
            placing = false
        end
    end
    DeleteEntity(ghost)
    SetModelAsNoLongerNeeded(hash)
    if result then
        ESX.TriggerServerCallback('jobbuilder:props:place', function(res)
            if res and res.ok then JBNotify(('Prop posé (%d / %d)'):format(res.count, res.limit))
            else JBNotify('~r~' .. ((res and res.error) or 'Erreur')) end
            OpenPropsMenu()
        end, entry.id, result)
    else
        OpenPropsMenu()
    end
end

NuiLocal['props:place'] = function(args, cb)
    cb({ ok = true })
    CloseUI()
    local id = args[1]
    for _, c in ipairs(Config.Props.Catalog) do
        if c.id == id then return CreateThread(function() placeProp(c) end) end
    end
end
