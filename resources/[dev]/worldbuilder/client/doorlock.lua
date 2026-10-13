-- ─────────────────────────────── Portes verrouillables (client) ───────────────────────────────
local States = {}          -- [eid:pi] = true (verrouillée)
local registered = {}      -- [hash] = true

local function doorHash(eid, pi, j) return joaat(('wb_%d_%d_%d'):format(eid, pi, j)) end

local function applyAll()
    local keep = {}
    for _, e in ipairs(State.entities) do
        if e.type == 'doorlock' then
            for _, p in ipairs(e.points) do
                if p.kind == 'lock' and p.doors then
                    local locked = States[('%d:%d'):format(e.id, p.i)]
                    if locked == nil then locked = true end
                    for j, d in ipairs(p.doors) do
                        local h = doorHash(e.id, p.i, j)
                        keep[h] = true
                        if not registered[h] then
                            AddDoorToSystem(h, d.model, d.x + 0.0, d.y + 0.0, d.z + 0.0, false, false, false)
                            registered[h] = true
                        end
                        DoorSystemSetDoorState(h, locked and 1 or 0, false, true)
                    end
                end
            end
        end
    end
    for h in pairs(registered) do
        if not keep[h] then RemoveDoorFromSystem(h) registered[h] = nil end
    end
end

function OnSynced() applyAll() end

RegisterNetEvent('worldbuilder:client:doorStates', function(list)
    States = {}
    for _, r in ipairs(list or {}) do States[('%d:%d'):format(r.eid, r.pi)] = r.locked end
    applyAll()
end)

RegisterNetEvent('worldbuilder:client:doorState', function(eid, pi, locked)
    States[('%d:%d'):format(eid, pi)] = locked
    applyAll()
end)

-- Réapplique l'état périodiquement (les portes peuvent se réinitialiser au streaming)
CreateThread(function()
    while true do
        Wait(10000)
        if next(registered) then applyAll() end
    end
end)

-- Petite animation rapide (non bloquante) à chaque verrouillage / déverrouillage
local function doorAnim()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) or IsEntityDead(ped) then return end
    local dict = 'anim@heists@keycard@'
    RequestAnimDict(dict)
    local t = GetGameTimer()
    while not HasAnimDictLoaded(dict) and GetGameTimer() - t < 1000 do Wait(0) end
    if HasAnimDictLoaded(dict) then
        TaskPlayAnim(ped, dict, 'exit', 8.0, -8.0, 900, 48, 0, false, false, false)
        SetTimeout(1000, function() RemoveAnimDict(dict) end)
    end
end

Handlers.doorlock = function(node)
    if node.kind ~= 'lock' then return end
    ServerCall('worldbuilder:doorlock:toggle', function(res)
        if not res or not res.ok then return Notify((res and res.error) or 'Accès refusé', 'error') end
        PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
        CreateThread(doorAnim)
        Notify(res.locked and 'Porte verrouillée.' or 'Porte déverrouillée.', res.locked and 'info' or 'success')
    end, node.eid, node.pi)
end

-- ─────────────────────────────── Touche : verrouiller / déverrouiller la porte la plus proche ───────────────────────────────
local function nearestDoor()
    local pos = GetEntityCoords(PlayerPedId())
    local maxD = (Config.Doors and Config.Doors.Distance) or 3.0
    local best, bd
    for _, e in ipairs(State.entities) do
        if e.type == 'doorlock' then
            for _, p in ipairs(e.points) do
                if p.kind == 'lock' and (p.useKey ~= false or Config.Doors.Marker == false) then
                    local d = #(pos - vector3(p.coords.x, p.coords.y, p.coords.z))
                    for _, door in ipairs(p.doors or {}) do
                        local dd = #(pos - vector3(door.x, door.y, door.z))
                        if dd < d then d = dd end
                    end
                    if d <= maxD + 0.0 and (not bd or d < bd) then best, bd = { eid = e.id, pi = p.i }, d end
                end
            end
        end
    end
    return best
end

if Config.Doors and Config.Doors.Key then
    RegisterCommand('wbdoor', function()
        if IsUIOpen() or Busy or IsEntityDead(PlayerPedId()) then return end
        local n = nearestDoor()
        if not n then return Notify('Aucune porte à proximité.', 'info') end
        ServerCall('worldbuilder:doorlock:toggle', function(res)
            if not res or not res.ok then return Notify((res and res.error) or 'Accès refusé', 'error') end
            PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
        CreateThread(doorAnim)
            Notify(res.locked and 'Porte verrouillée.' or 'Porte déverrouillée.', res.locked and 'info' or 'success')
        end, n.eid, n.pi)
    end, false)
    RegisterKeyMapping('wbdoor', 'Verrouiller / déverrouiller la porte proche', 'keyboard', Config.Doors.Key)
end

-- ─────────────────────────────── Texte 3D sur la porte visée / la plus proche ───────────────────────────────
local function draw3D(x, y, z, text)
    SetDrawOrigin(x, y, z, 0)
    SetTextFont(4) SetTextScale(0.0, 0.6) SetTextColour(255, 255, 255, 235) SetTextOutline() SetTextCentre(true)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

CreateThread(function()
    local key = Config.Doors and Config.Doors.Key
    if not key then return end
    local maxD = (Config.Doors.Distance or 3.0) + 0.0
    while true do
        local sleep = 1000
        if not IsUIOpen() and not Busy then
            local pos = GetEntityCoords(PlayerPedId())
            local best, bd, bx, by, bz
            for _, e in ipairs(State.entities) do
                if e.type == 'doorlock' then
                    for _, p in ipairs(e.points) do
                        if p.kind == 'lock' and (p.useKey ~= false or Config.Doors.Marker == false) and p.showText ~= false then
                            for _, door in ipairs(p.doors or {}) do
                                local d = #(pos - vector3(door.x, door.y, door.z))
                                if d <= maxD and (not bd or d < bd) then best, bd, bx, by, bz = ('%d:%d'):format(e.id, p.i), d, door.x, door.y, door.z end
                            end
                        end
                    end
                end
            end
            if best then
                sleep = 0
                local locked = States[best]
                if locked == nil then locked = true end
                draw3D(bx, by, bz + 0.6, ('Appuie sur ~g~%s~s~ pour %s'):format(key, locked and 'ouvrir' or 'fermer'))
            elseif next(registered) then sleep = 250 end
        end
        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for h in pairs(registered) do RemoveDoorFromSystem(h) end
end)

-- ─────────────────────────────── Builder : viser une porte ───────────────────────────────
-- Vise la porte avec la caméra : Entrée = sélectionner, Retour arrière = annuler
local picking = false

local function aimedObject()
    local cam = GetGameplayCamCoord()
    local rot = GetGameplayCamRot(2)
    local z, x = math.rad(rot.z), math.rad(rot.x)
    local num = math.abs(math.cos(x))
    local dest = vector3(cam.x - math.sin(z) * num * 12.0, cam.y + math.cos(z) * num * 12.0, cam.z + math.sin(x) * 12.0)
    local h = StartExpensiveSynchronousShapeTestLosProbe(cam.x, cam.y, cam.z, dest.x, dest.y, dest.z, 16, PlayerPedId(), 4)
    local _, hit, endCoords, _, ent = GetShapeTestResult(h)
    if hit == 1 and ent and ent ~= 0 and GetEntityType(ent) == 3 then return ent, endCoords end
    return nil, hit == 1 and endCoords or nil
end

local function drawText(text)
    SetTextFont(4) SetTextScale(0.0, 0.45) SetTextColour(255, 255, 255, 230) SetTextOutline() SetTextCentre(true)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.5, 0.88)
end

NuiLocal.doorpick = function(args, cb)
    if args[1] and not picking then
        picking = true
        SetNuiFocus(false, false)
        CreateThread(function()
            while picking do
                local ent, at = aimedObject()
                if ent then
                    local c = GetEntityCoords(ent)
                    DrawMarker(28, c.x, c.y, c.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25, 0.25, 0.25, 255, 80, 80, 180, false, false, 2, false, nil, nil, false)
                    drawText(('Porte visée (modèle %d) — ENTRÉE : sélectionner — RETOUR : annuler'):format(GetEntityModel(ent)))
                    if IsControlJustReleased(0, 201) then
                        SendNUIMessage({ action = 'doorPicked', door = { model = GetEntityModel(ent), x = c.x, y = c.y, z = c.z, h = GetEntityHeading(ent) } })
                    end
                else
                    drawText('Vise une porte avec la caméra — RETOUR : annuler')
                end
                if IsControlJustReleased(0, 177) then
                    picking = false
                    SetNuiFocus(true, true)
                    SendNUIMessage({ action = 'doorPickEnd' })
                end
                Wait(0)
            end
        end)
    end
    cb({ ok = true })
end

-- Fin du mode visée (après sélection)
NuiLocal.doorpickEnd = function(_, cb)
    if picking then picking = false SetNuiFocus(true, true) end
    cb({ ok = true })
end
