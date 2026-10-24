-- ─────────────────────────────── Meubles (client) ───────────────────────────────
-- F7 / /meubles dans sa propriété : menu de décoration. Les meubles sont des objets LOCAUX créés chez chaque occupant (positions en base).
local F = Config.Real.Furniture
local objs = {}        -- [id] = { ent, model }
local placing = false

for _, n in ipairs({ 'furn:list', 'furn:remove', 'furn:removeAll' }) do NuiRemote[n] = true end

local function entry(id) for _, c in ipairs(F.Catalog) do if c.id == id then return c end end end

local function loadModel(name)
    local hash = joaat(name)
    if not IsModelInCdimage(hash) then return nil end
    RequestModel(hash)
    local t = GetGameTimer() + 4000
    while not HasModelLoaded(hash) and GetGameTimer() < t do Wait(10) end
    return HasModelLoaded(hash) and hash or nil
end

function FurnClear()
    for id, o in pairs(objs) do if DoesEntityExist(o.ent) then DeleteEntity(o.ent) end objs[id] = nil end
end

-- Synchronise les objets avec la liste du serveur (ajoute / déplace / retire)
function FurnSpawn(list)
    if not JBInside() then return FurnClear() end
    local keep = {}
    for _, f in ipairs(list or {}) do
        keep[f.id] = true
        local e = entry(f.model)
        local o = objs[f.id]
        if e then
            if o and (o.model ~= e.model) then if DoesEntityExist(o.ent) then DeleteEntity(o.ent) end o = nil objs[f.id] = nil end
            if not o then
                local hash = loadModel(e.model)
                if hash then
                    local ent = CreateObjectNoOffset(hash, f.x + 0.0, f.y + 0.0, f.z + 0.0, false, false, false)
                    SetEntityHeading(ent, f.h + 0.0)
                    FreezeEntityPosition(ent, true)
                    SetModelAsNoLongerNeeded(hash)
                    objs[f.id] = { ent = ent, model = e.model }
                end
            else
                SetEntityCoordsNoOffset(o.ent, f.x + 0.0, f.y + 0.0, f.z + 0.0, false, false, false)
                SetEntityHeading(o.ent, f.h + 0.0)
            end
        end
    end
    for id, o in pairs(objs) do
        if not keep[id] then if DoesEntityExist(o.ent) then DeleteEntity(o.ent) end objs[id] = nil end
    end
end

RegisterNetEvent('jobbuilder:client:furniture', function(list) FurnSpawn(list) end)
AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then FurnClear() end end)

-- ─────────────────────────────── Menu ───────────────────────────────
function OpenFurnitureMenu()
    if not JBInside() then return JBNotify('~r~Tu dois être dans ta propriété.') end
    ESX.TriggerServerCallback('jobbuilder:furn:list', function(res)
        if not res or not res.ok then return JBNotify('~r~' .. ((res and res.error) or 'Indisponible')) end
        OpenUI({ action = 'open', kind = 'furniture', data = res })
    end)
end

RegisterCommand('meubles', function() if not IsUIOpen() and not placing then OpenFurnitureMenu() end end, false)
RegisterKeyMapping('meubles', 'Décorer ma propriété (meubles)', 'keyboard', F.Key or 'F7')

-- ─────────────────────────────── Mode placement ───────────────────────────────
local function hint(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, false, -1)
end

local function aimPoint(dist)
    local from = GetGameplayCamCoord()
    local rot = GetGameplayCamRot(2)
    local z, x = math.rad(rot.z), math.rad(rot.x)
    local num = math.abs(math.cos(x))
    local dir = vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
    local to = from + dir * dist
    local handle = StartExpensiveSynchronousShapeTestLosProbe(from.x, from.y, from.z, to.x, to.y, to.z, 1, PlayerPedId(), 4)
    local _, hit, coords = GetShapeTestResult(handle)
    if hit == 1 then return coords end
end

-- Pose (ou déplace si `moveId`) : flèches ←/→ ou molette = tourner, ↑/↓ = hauteur, ENTRÉE = valider, RETOUR = annuler
local function placeFurniture(e, moveId, startAt)
    if placing then return end
    local hash = loadModel(e.model)
    if not hash then JBNotify('~r~Modèle introuvable sur ce serveur : ' .. e.model) return OpenFurnitureMenu() end
    placing = true
    local maxDist = F.PlaceDistance or 8.0
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    local ghost = CreateObject(hash, c.x, c.y, c.z, false, false, false)
    SetEntityAlpha(ghost, 150, false)
    SetEntityCollision(ghost, false, false)
    FreezeEntityPosition(ghost, true)
    local heading, lift, result = (startAt and startAt.h) or GetEntityHeading(ped), 0.0, nil
    while placing do
        Wait(0)
        ped = PlayerPedId()
        for _, k in ipairs({ 24, 25, 257, 37, 140, 141, 142, 172, 173 }) do DisableControlAction(0, k, true) end
        local pc = GetEntityCoords(ped)
        local pos = aimPoint(maxDist)
        if not pos then
            local f = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.0, 0.0)
            pos = vector3(f.x, f.y, pc.z)
        end
        SetEntityCoordsNoOffset(ghost, pos.x, pos.y, pos.z + 0.5, false, false, false)
        PlaceObjectOnGroundProperly(ghost)
        local step = IsControlPressed(0, 21) and 3.0 or 1.2
        if IsControlPressed(0, 174) then heading = heading - step end
        if IsControlPressed(0, 175) then heading = heading + step end
        if IsDisabledControlPressed(0, 172) then lift = math.min(3.0, lift + 0.01) end
        if IsDisabledControlPressed(0, 173) then lift = math.max(-0.5, lift - 0.01) end
        if IsControlJustPressed(0, 15) then heading = heading + 8.0 end
        if IsControlJustPressed(0, 14) then heading = heading - 8.0 end
        local g = GetEntityCoords(ghost)
        SetEntityCoordsNoOffset(ghost, g.x, g.y, g.z + lift, false, false, false)
        SetEntityHeading(ghost, heading % 360.0)
        local gc = GetEntityCoords(ghost)
        local tooFar = #(pc - gc) > maxDist + 1.0
        SetEntityAlpha(ghost, tooFar and 60 or 150, false)
        hint(('%s\n~INPUT_CELLPHONE_LEFT~ ~INPUT_CELLPHONE_RIGHT~ / molette : tourner · ~INPUT_CELLPHONE_UP~ ~INPUT_CELLPHONE_DOWN~ : hauteur (%.2f)\n~INPUT_FRONTEND_ACCEPT~ valider   ~INPUT_FRONTEND_RRIGHT~ annuler'):format(e.label, lift))
        if IsControlJustPressed(0, 201) or IsControlJustPressed(0, 191) then
            if tooFar then JBNotify('~r~Trop loin : rapproche-toi.')
            else result = { x = gc.x, y = gc.y, z = gc.z, h = GetEntityHeading(ghost) } placing = false end
        elseif IsControlJustPressed(0, 177) or IsControlJustPressed(0, 202) or IsEntityDead(ped) then
            placing = false
        end
    end
    DeleteEntity(ghost)
    SetModelAsNoLongerNeeded(hash)
    if not result then return OpenFurnitureMenu() end
    local function done(res)
        if res and res.ok then JBNotify(moveId and 'Meuble déplacé.' or ('Meuble posé (%d / %d)'):format(res.count, res.limit))
        else JBNotify('~r~' .. ((res and res.error) or 'Erreur')) end
        OpenFurnitureMenu()
    end
    if moveId then ESX.TriggerServerCallback('jobbuilder:furn:move', done, moveId, result)
    else ESX.TriggerServerCallback('jobbuilder:furn:place', done, e.id, result) end
end

NuiLocal['furn:place'] = function(args, cb)
    cb({ ok = true })
    CloseUI()
    local e = entry(args[1])
    if e then CreateThread(function() placeFurniture(e) end) end
end

NuiLocal['furn:move'] = function(args, cb)
    cb({ ok = true })
    CloseUI()
    local fid, model = tonumber(args[1]), args[2]
    local e = entry(model)
    local o = objs[fid]
    if e then
        local start = o and DoesEntityExist(o.ent) and { h = GetEntityHeading(o.ent) } or nil
        CreateThread(function() placeFurniture(e, fid, start) end)
    end
end
