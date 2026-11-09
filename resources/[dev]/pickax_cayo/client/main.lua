ESX = exports['es_extended']:getSharedObject()
local C = Config

State = nil                  -- vue du groupe (envoyée par le serveur)
local open = false
local blips = {}

local function notify(msg) TriggerEvent('esx:showNotification', msg) end
local function byId(list, id) for _, v in ipairs(list) do if v.id == id then return v end end end
function CayoNotify(m) notify(m) end

-- ───────── texte 3D / barre de progression ─────────
function Draw3D(x, y, z, text)
    local on, sx, sy = GetScreenCoordFromWorldCoord(x, y, z)
    if not on then return end
    SetTextScale(0.34, 0.34) SetTextFont(4) SetTextCentre(true) SetTextOutline()
    SetTextColour(255, 255, 255, 235)
    BeginTextCommandDisplayText('STRING') AddTextComponentSubstringPlayerName(text) EndTextCommandDisplayText(sx, sy)
end
function Hud(x, y, text, scale, r, g, b, mode)
    SetTextScale(scale or 0.36, scale or 0.36) SetTextFont(4) SetTextOutline()
    if mode == 'right' then SetTextRightJustify(true) SetTextWrap(0.0, x) elseif mode == 'center' then SetTextCentre(true) end
    SetTextColour(r or 255, g or 255, b or 255, 235)
    BeginTextCommandDisplayText('STRING') AddTextComponentSubstringPlayerName(text) EndTextCommandDisplayText(x, y)
end
-- maintenir E pendant `seconds` : renvoie true si la durée est atteinte
function HoldE(label, seconds, anim)
    local t0 = GetGameTimer()
    local ped = PlayerPedId()
    if anim then
        RequestAnimDict(anim[1]) local w = 0 while not HasAnimDictLoaded(anim[1]) and w < 50 do Wait(20) w = w + 1 end
        TaskPlayAnim(ped, anim[1], anim[2], 4.0, 4.0, -1, 49, 0, false, false, false)
    end
    local ok = true
    while GetGameTimer() - t0 < seconds * 1000 do
        Wait(0)
        if not IsControlPressed(0, 38) or IsEntityDead(ped) then ok = false break end
        local f = (GetGameTimer() - t0) / (seconds * 1000)
        DrawRect(0.5, 0.86, 0.16, 0.012, 0, 0, 0, 170)
        DrawRect(0.5 - 0.08 + 0.08 * f, 0.86, 0.16 * f, 0.012, 18, 160, 85, 230)
        Hud(0.5, 0.82, label, 0.38, 255, 255, 255, 'center')
    end
    ClearPedTasks(ped)
    return ok
end

-- ───────── tablette ─────────
local function nearPlanning()
    return #(GetEntityCoords(PlayerPedId()) - C.Planning.coords) <= C.Planning.radius + 2.0
end
local function isStaff() local g = ESX.PlayerData and ESX.PlayerData.group return g and C.AdminGroups[g] == true end

local function openTablet()
    if open or IsPauseMenuActive() or IsNuiFocused() then return end
    if InHeist then return notify('~r~Tu es déjà en plein braquage.') end
    if not nearPlanning() and not isStaff() then return notify('~y~Rends-toi au poste de planification pour utiliser la tablette.') end
    ESX.TriggerServerCallback('pickax_cayo:open', function(d)
        if not d then return end
        State = d.state
        open = true
        SetNuiFocus(true, true)
        SendNUIMessage({ a = 'open', cfg = d.cfg, state = d.state })
    end)
end
local function closeTablet()
    if not open then return end
    open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ a = 'close' })
end
RegisterCommand(C.Command, openTablet, false)
RegisterNetEvent('pickax_cayo:sync', function(v)
    State = v
    if open then SendNUIMessage({ a = 'state', state = v }) end
    RefreshPrepBlips()
end)

RegisterNUICallback('close', function(_, cb) cb(1) closeTablet() end)
RegisterNUICallback('set', function(d, cb) cb(1) if d and d.field then TriggerServerEvent('pickax_cayo:set', d.field, d.value) end end)
RegisterNUICallback('invite', function(d, cb) cb(1) if d and d.id then TriggerServerEvent('pickax_cayo:invite', d.id) end end)
RegisterNUICallback('cuts', function(d, cb) cb(1) if d and d.cuts then TriggerServerEvent('pickax_cayo:cuts', d.cuts) end end)
RegisterNUICallback('leave', function(_, cb) cb(1) TriggerServerEvent('pickax_cayo:leave') closeTablet() end)
RegisterNUICallback('nearby', function(_, cb)
    local out, me, mine = {}, PlayerPedId(), PlayerId()
    for _, pid in ipairs(GetActivePlayers()) do
        if pid ~= mine then
            local ped = GetPlayerPed(pid)
            if #(GetEntityCoords(ped) - GetEntityCoords(me)) < 40.0 then out[#out + 1] = { id = GetPlayerServerId(pid), name = GetPlayerName(pid) } end
        end
    end
    cb(out)
end)
RegisterNUICallback('gps', function(d, cb)
    cb(1)
    local pt
    if d and d.kind == 'scope' then local s = byId(C.Scope, d.id) pt = s and s.coords
    elseif d and d.kind == 'equip' then pt = C.PrepPoints[d.id] end
    if pt then SetNewWaypoint(pt.x, pt.y) notify('~g~Itinéraire GPS posé.') end
end)
RegisterNUICallback('launch', function(_, cb)
    ESX.TriggerServerCallback('pickax_cayo:launch', function(ok, err)
        cb({ ok = ok, err = err })
        if ok then closeTablet() elseif err then notify('~r~' .. err) end
    end)
end)

-- invitation
RegisterCommand('cayoaccept', function() TriggerServerEvent('pickax_cayo:accept') end, false)
RegisterKeyMapping('cayoaccept', 'Cayo Perico : accepter l\'invitation', 'keyboard', 'Y')

-- ───────── poste de planification : repère, blip, interaction ─────────
CreateThread(function()
    local b = C.Planning.blip
    if b then
        local blip = AddBlipForCoord(C.Planning.coords.x, C.Planning.coords.y, C.Planning.coords.z)
        SetBlipSprite(blip, b.sprite) SetBlipColour(blip, b.colour) SetBlipScale(blip, b.scale) SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName(C.Planning.label) EndTextCommandDisplayText(blip)
    end
    while true do
        local sleep = 800
        if not InHeist and not open then
            local d = #(GetEntityCoords(PlayerPedId()) - C.Planning.coords)
            if d < 25.0 then
                sleep = 0
                DrawMarker(1, C.Planning.coords.x, C.Planning.coords.y, C.Planning.coords.z - 1.0, 0, 0, 0, 0, 0, 0, 1.4, 1.4, 0.5, 18, 160, 85, 120, false, false, 2, false, nil, nil, false)
                if d <= C.Planning.radius then
                    Draw3D(C.Planning.coords.x, C.Planning.coords.y, C.Planning.coords.z + 0.6, '~g~[E]~s~ Tablette de planification — Cayo Perico')
                    if IsControlJustPressed(0, 38) then openTablet() end
                end
            end
        end
        Wait(sleep)
    end
end)

-- ───────── reconnaissances et matériel : points sur le continent ─────────
function RefreshPrepBlips()
    for _, b in ipairs(blips) do if DoesBlipExist(b) then RemoveBlip(b) end end
    blips = {}
    if not State or State.phase ~= 'plan' then return end
    local function add(coords, label, sprite, col)
        local b = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(b, sprite) SetBlipColour(b, col) SetBlipScale(b, 0.8) SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName(label) EndTextCommandDisplayText(b)
        blips[#blips + 1] = b
    end
    for _, s in ipairs(C.Scope) do if not State.scope[s.id] then add(s.coords, 'Cayo : reconnaissance — ' .. s.label, 143, 5) end end
    for id in pairs(State.plan.equipment or {}) do
        if not State.prep[id] and C.PrepPoints[id] then add(C.PrepPoints[id], 'Cayo : ' .. (byId(C.Equipment, id) or { label = id }).label, 478, 2) end
    end
end

CreateThread(function()
    while true do
        local sleep = 700
        if State and State.phase == 'plan' and not InHeist then
            local me = GetEntityCoords(PlayerPedId())
            local targets = {}
            for _, s in ipairs(C.Scope) do if not State.scope[s.id] then targets[#targets + 1] = { 'scope', s.id, s.coords, 'Reconnaissance : ' .. s.label, { 'amb@world_human_binoculars@male@enter', 'enter' } } end end
            for id in pairs(State.plan.equipment or {}) do
                if not State.prep[id] and C.PrepPoints[id] then targets[#targets + 1] = { 'equip', id, C.PrepPoints[id], 'Récupérer : ' .. (byId(C.Equipment, id) or { label = id }).label } end
            end
            for _, t in ipairs(targets) do
                local d = #(me - t[3])
                if d < 30.0 then
                    sleep = 0
                    DrawMarker(1, t[3].x, t[3].y, t[3].z - 1.0, 0, 0, 0, 0, 0, 0, 1.6, 1.6, 0.6, 255, 190, 40, 110, false, false, 2, false, nil, nil, false)
                    if d < 2.5 then
                        Draw3D(t[3].x, t[3].y, t[3].z + 0.7, '~g~[E]~s~ (maintenir) ' .. t[4])
                        if IsControlPressed(0, 38) then
                            if HoldE(t[4], C.PrepSeconds, t[5]) then TriggerServerEvent('pickax_cayo:prep', t[1], t[2]) notify('~g~Terminé : ' .. t[4]) end
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- ───────── staff ─────────
RegisterNetEvent('pickax_cayo:tp', function(c)
    DoScreenFadeOut(300) Wait(400)
    RequestCollisionAtCoord(c.x, c.y, c.z)
    SetEntityCoords(PlayerPedId(), c.x, c.y, c.z + 1.0, false, false, false, false)
    Wait(1500) DoScreenFadeIn(300)
end)
RegisterNetEvent('pickax_cayo:printPos', function()
    local c, h = GetEntityCoords(PlayerPedId()), GetEntityHeading(PlayerPedId())
    local s = ('vec4(%.1f, %.1f, %.1f, %.1f)'):format(c.x, c.y, c.z, h)
    print('^3[pickax_cayo] ' .. s .. '^0')
    notify('Position : ~b~' .. s)
end)

AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() then if open then SetNuiFocus(false, false) end for _, b in ipairs(blips) do RemoveBlip(b) end end end)
