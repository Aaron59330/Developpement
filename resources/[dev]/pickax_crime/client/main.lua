local ESX = exports['es_extended']:getSharedObject()
local C = Config
local busy = false
-- ───────────── Rôle du joueur (noms de jobs ESX ou type du Job Builder) ─────────────
local function hasRole(names, types)
    local d = ESX.GetPlayerData()
    local job = d and d.job and d.job.name
    for _, n in ipairs(names or {}) do if job == n then return true end end
    if types and #types > 0 and GetResourceState('pickax_jobbuilder') == 'started' then
        local ok, t = pcall(function() return exports.pickax_jobbuilder:GetJobType() end)
        if ok and t then for _, x in ipairs(types) do if t == x then return true end end end
    end
    return false
end

local function notify(kind, txt) lib.notify({ type = kind, description = txt }) end
local function help(txt) BeginTextCommandDisplayHelp('STRING') AddTextComponentSubstringPlayerName(txt) EndTextCommandDisplayHelp(0, false, true, -1) end
local function play(game, cfg) return exports.pickax_skillgames:Play(game, cfg) end
local function closestVehicle(dist)
    local pc = GetEntityCoords(PlayerPedId())
    local v = GetClosestVehicle(pc.x, pc.y, pc.z, dist, 0, 71)
    if v ~= 0 and NetworkGetEntityIsNetworked(v) then return v end
end
local function anim(dict, clip) RequestAnimDict(dict) local t = GetGameTimer() + 1500 while not HasAnimDictLoaded(dict) and GetGameTimer() < t do Wait(10) end TaskPlayAnim(PlayerPedId(), dict, clip, 2.0, 2.0, -1, 49, 0, false, false, false) end

-- ───────────── Crochetage ─────────────
local function lockpick()
    if busy then return end
    local veh = closestVehicle(C.Lockpick.Distance)
    if not veh then return notify('error', 'Aucun véhicule à portée.') end
    if IsPedInAnyVehicle(PlayerPedId(), false) then return notify('error', 'Descends du véhicule.') end
    busy = true
    ESX.TriggerServerCallback('pickax_crime:lockBegin', function(b)
        if not b or not b.ok then busy = false return notify('error', (b and b.error) or 'Impossible') end
        anim('missheistfbisetup1', 'hassle_intro_loop_f')
        local score = play('pins', b.cfg)
        ClearPedTasks(PlayerPedId())
        if not score then busy = false return notify('error', 'Tentative abandonnée.') end
        ESX.TriggerServerCallback('pickax_crime:lockEnd', function(r)
            busy = false
            if r and r.ok then notify(r.failed and 'error' or 'success', r.msg) else notify('error', (r and r.error) or 'Erreur') end
        end, score)
    end, NetworkGetNetworkIdFromEntity(veh), GetVehicleClass(veh))
end
if C.UseCommands then RegisterCommand(C.Lockpick.Command, function() lockpick() end, false) end
RegisterNetEvent('pickax_crime:useLockpick', function() lockpick() end)   -- objet « crochet » utilisé près d'un véhicule
exports('Lockpick', function(difficulty) return (play('pins', { pins = 4, difficulty = difficulty or 3 }) or 0) >= C.Lockpick.Min end)   -- pour d'autres scripts (portes, coffres) : le résultat n'est PAS validé par le serveur

-- ───────────── Points : terminaux, atelier de faux papiers, receleur ─────────────
local peds = {}
local function pedAt(i, model, c, h)
    if peds[i] then return end
    local m = joaat(model)
    if not IsModelInCdimage(m) then return end
    RequestModel(m) local t = GetGameTimer() + 3000 while not HasModelLoaded(m) and GetGameTimer() < t do Wait(20) end
    if HasModelLoaded(m) then
        local p = CreatePed(4, m, c.x, c.y, c.z - 1.0, h or 0.0, false, true)
        SetEntityInvincible(p, true) SetBlockingOfNonTemporaryEvents(p, true) FreezeEntityPosition(p, true)
        TaskStartScenarioInPlace(p, 'WORLD_HUMAN_SMOKING', 0, true) peds[i] = p
    end
    SetModelAsNoLongerNeeded(m)
end

local function hack(idx)
    busy = true
    ESX.TriggerServerCallback('pickax_crime:hackBegin', function(b)
        if not b or not b.ok then busy = false return notify('error', (b and b.error) or 'Impossible') end
        anim('mp_prison_break', 'hack_loop')
        local score = play(b.game, b.cfg)
        ClearPedTasks(PlayerPedId())
        if not score then busy = false return notify('error', 'Piratage abandonné.') end
        ESX.TriggerServerCallback('pickax_crime:hackEnd', function(r)
            busy = false
            if r and r.ok then notify(r.failed and 'error' or 'success', r.msg) else notify('error', (r and r.error) or 'Erreur') end
        end, score)
    end, idx)
end

local function forge(idx)
    local input = lib.inputDialog('Faux papiers', { { type = 'input', label = 'Prénom', required = true, max = 24 }, { type = 'input', label = 'Nom', required = true, max = 24 } })
    if not input then return end
    busy = true
    ESX.TriggerServerCallback('pickax_crime:forgeBegin', function(b)
        if not b or not b.ok then busy = false return notify('error', (b and b.error) or 'Impossible') end
        anim('mp_common', 'givetake1_a')
        local score = play('align', b.cfg)
        ClearPedTasks(PlayerPedId())
        if not score then busy = false return notify('error', 'Fabrication abandonnée.') end
        ESX.TriggerServerCallback('pickax_crime:forgeEnd', function(r)
            busy = false
            if r and r.ok then notify('success', r.msg) else notify('error', (r and r.error) or 'Erreur') end
        end, score, input[1], input[2])
    end, idx)
end

local function fence()
    ESX.TriggerServerCallback('pickax_crime:fenceList', function(r)
        if not r or not r.ok then return notify('error', (r and r.error) or 'Indisponible') end
        if #r.list == 0 then return notify('inform', 'Tu n\'as aucune pièce à vendre.') end
        local opts = {}
        for _, it in ipairs(r.list) do
            opts[#opts + 1] = { title = ('%s ×%d'):format(it.item, it.count), description = ('%d $ l\'unité (argent sale)'):format(it.price), icon = 'sack-dollar',
                onSelect = function() ESX.TriggerServerCallback('pickax_crime:fenceSell', function(s) notify(s and s.ok and 'success' or 'error', (s and (s.msg or s.error)) or 'Erreur') end, it.item, it.count) end }
        end
        lib.registerContext({ id = 'pk_fence', title = C.Chop.Fence.label, options = opts })
        lib.showContext('pk_fence')
    end)
end

CreateThread(function()
    local F = C.Chop.Fence
    while true do
        local sleep = 1000
        local pc = GetEntityCoords(PlayerPedId())
        if not busy then
            for i, t in ipairs(C.Hack.Terminals) do
                local d = #(pc - t.coords)
                if d < 12.0 then sleep = 0 DrawMarker(1, t.coords.x, t.coords.y, t.coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.9, 0.9, 0.4, 253, 194, 125, 120, false, false, 2, false, nil, nil, false)
                    if d < C.Hack.Distance then help('Appuie sur ~INPUT_CONTEXT~ : pirater le terminal') if IsControlJustPressed(0, 38) then hack(i) end end end
            end
            for i, w in ipairs(C.Forgery.Workshops) do
                local d = #(pc - w.coords)
                if d < 12.0 then sleep = 0 DrawMarker(1, w.coords.x, w.coords.y, w.coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.9, 0.9, 0.4, 253, 194, 125, 120, false, false, 2, false, nil, nil, false)
                    if d < C.Forgery.Distance then help('Appuie sur ~INPUT_CONTEXT~ : fabriquer un faux document') if IsControlJustPressed(0, 38) then forge(i) end end end
            end
            local df = #(pc - F.coords)
            if df < 45.0 then pedAt('fence', F.ped, F.coords, F.pedHeading) end
            if df < 12.0 then sleep = 0 DrawMarker(1, F.coords.x, F.coords.y, F.coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.9, 0.9, 0.4, 253, 194, 125, 120, false, false, 2, false, nil, nil, false)
                if df < F.Distance then help('Appuie sur ~INPUT_CONTEXT~ : vendre des pièces') if IsControlJustPressed(0, 38) then fence() Wait(500) end end end
        end
        Wait(sleep)
    end
end)

-- ───────────── Désossage ─────────────
local function chop()
    if busy then return end
    local veh = closestVehicle(8.0)
    if not veh then return notify('error', 'Aucun véhicule à proximité.') end
    ESX.TriggerServerCallback('pickax_crime:chopInfo', function(r)
        if not r or not r.ok then return notify('error', (r and r.error) or 'Impossible') end
        local opts = {}
        for _, p in ipairs(r.parts) do
            opts[#opts + 1] = { title = p.label, description = p.done and 'Déjà démontée' or 'Démonter', icon = p.done and 'check' or 'wrench', disabled = p.done,
                onSelect = function()
                    busy = true
                    ESX.TriggerServerCallback('pickax_crime:chopBegin', function(b)
                        if not b or not b.ok then busy = false return notify('error', (b and b.error) or 'Impossible') end
                        anim('mini@repair', 'fixing_a_ped')
                        local score = play('timing', b.cfg)
                        ClearPedTasks(PlayerPedId())
                        if not score then busy = false return notify('error', 'Démontage abandonné.') end
                        ESX.TriggerServerCallback('pickax_crime:chopEnd', function(e)
                            busy = false
                            if e and e.ok then notify(e.failed and 'error' or 'success', e.msg) else notify('error', (e and e.error) or 'Erreur') end
                        end, score)
                    end, NetworkGetNetworkIdFromEntity(veh), p.id)
                end }
        end
        lib.registerContext({ id = 'pk_chop', title = 'Désossage — ' .. r.plate, options = opts })
        lib.showContext('pk_chop')
    end, NetworkGetNetworkIdFromEntity(veh))
end
if C.UseCommands then RegisterCommand(C.Chop.Command, function() chop() end, false) end

-- Menu contextuel : clic droit sur un véhicule
local CTX_ACTIONS = {
    { id = 'lockpick', label = 'Crocheter la serrure', target = 'vehicle' },
    { id = 'chop',     label = 'Désosser le véhicule', target = 'vehicle' },
}
local function haveItem(name) local ok, n = pcall(function() return exports.ox_inventory:Search('count', name) end) return ok and (tonumber(n) or 0) > 0 end
local function inChopZone() local pc = GetEntityCoords(PlayerPedId()) for _, z in ipairs(C.Chop.Zones) do if #(pc - z.coords) <= z.radius then return true end end return false end
exports('ContextCan', function(id, ent)
    if IsPedInAnyVehicle(PlayerPedId(), false) then return false end
    if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(ent)) > 6.0 then return false end
    if id == 'lockpick' then return GetVehicleDoorLockStatus(ent) > 1 and haveItem(C.Lockpick.Item) end
    if id == 'chop' then return inChopZone() and (C.Chop.Tool == '' or haveItem(C.Chop.Tool)) end
    return false
end)
exports('ContextDo', function(id, ent) if id == 'lockpick' then lockpick() else chop() end end)
local function registerContext() exports.pickax_core:RegisterContextActions(GetCurrentResourceName(), CTX_ACTIONS) end
CreateThread(function() Wait(2500) registerContext() end)
AddEventHandler('onResourceStart', function(r) if r == 'pickax_core' then SetTimeout(2500, registerContext) end end)

AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then for _, p in pairs(peds) do DeleteEntity(p) end end end)
