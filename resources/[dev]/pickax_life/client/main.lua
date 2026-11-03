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
local function anim(dict, clip, flag) RequestAnimDict(dict) local t = GetGameTimer() + 1500 while not HasAnimDictLoaded(dict) and GetGameTimer() < t do Wait(10) end TaskPlayAnim(PlayerPedId(), dict, clip, 2.0, 2.0, -1, flag or 49, 0, false, false, false) end
local function res(r) if r and r.ok then notify(r.failed and 'error' or 'success', r.msg or 'OK') else notify('error', (r and r.error) or 'Impossible') end end

-- ───────────── Pêche ─────────────
local function fish()
    if busy then return end
    busy = true
    ESX.TriggerServerCallback('pickax_life:fishBegin', function(b)
        if not b or not b.ok then busy = false return notify('error', (b and b.error) or 'Impossible') end
        TaskStartScenarioInPlace(PlayerPedId(), 'WORLD_HUMAN_STAND_FISHING', 0, true)
        Wait(2500 + math.random(0, 2500))
        notify('inform', b.bait and 'Ça mord (appât) !' or 'Ça mord !')
        local score = play('hold', b.cfg)
        ClearPedTasks(PlayerPedId())
        if not score then busy = false return notify('error', 'Tu as lâché la canne.') end
        ESX.TriggerServerCallback('pickax_life:fishEnd', function(r) busy = false res(r) end, score)
    end)
end
if C.UseCommands then RegisterCommand(C.Fishing.Command, function() fish() end, false) end
RegisterNetEvent('pickax_life:useRod', function() fish() end)   -- objet « canne à pêche »

-- ───────────── Chasse : dépeçage ─────────────
local function nearestCarcass()
    local pc = GetEntityCoords(PlayerPedId())
    local handle, ped = FindFirstPed()
    local best, bd = nil, 4.0
    local ok = true
    while ok do
        if DoesEntityExist(ped) and IsEntityDead(ped) and not IsPedAPlayer(ped) and C.Hunting.Animals[GetEntityModel(ped)] then
            local d = #(pc - GetEntityCoords(ped))
            if d < bd and NetworkGetEntityIsNetworked(ped) then best, bd = ped, d end
        end
        ok, ped = FindNextPed(handle)
    end
    EndFindPed(handle)
    return best
end

local function skin(target)
    if busy then return end
    local ped = (target and DoesEntityExist(target)) and target or nearestCarcass()
    if not ped then return notify('error', 'Aucune dépouille à proximité.') end
    busy = true
    ESX.TriggerServerCallback('pickax_life:huntBegin', function(b)
        if not b or not b.ok then busy = false return notify('error', (b and b.error) or 'Impossible') end
        anim('amb@medic@standing@kneel@base', 'base', 1)
        local score = play('timing', b.cfg)
        ClearPedTasks(PlayerPedId())
        if not score then busy = false return notify('error', 'Dépeçage abandonné.') end
        ESX.TriggerServerCallback('pickax_life:huntEnd', function(r) busy = false res(r) end, score)
    end, NetworkGetNetworkIdFromEntity(ped), GetEntityModel(ped))
end
if C.UseCommands then RegisterCommand(C.Hunting.Command, function() skin() end, false) end
RegisterNetEvent('pickax_life:useKnife', function() skin() end)   -- objet « couteau de chasse »

-- Menu contextuel : clic droit sur une dépouille
local CTX_ACTIONS = { { id = 'skin', label = 'Dépecer l\'animal', target = 'ped' } }
exports('ContextCan', function(id, ent) return IsEntityDead(ent) and C.Hunting.Animals[GetEntityModel(ent)] ~= nil and #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(ent)) <= 4.0 end)
exports('ContextDo', function(id, ent) skin(ent) end)
local function registerContext() exports.pickax_core:RegisterContextActions(GetCurrentResourceName(), CTX_ACTIONS) end
CreateThread(function() Wait(2500) registerContext() end)
AddEventHandler('onResourceStart', function(r) if r == 'pickax_core' then SetTimeout(2500, registerContext) end end)

-- ───────────── Points : permis, acheteurs, cuisine ─────────────
local peds = {}
local function pedAt(key, model, c, h)
    if peds[key] then return end
    local m = joaat(model)
    if not IsModelInCdimage(m) then return end
    RequestModel(m) local t = GetGameTimer() + 3000 while not HasModelLoaded(m) and GetGameTimer() < t do Wait(20) end
    if HasModelLoaded(m) then
        local p = CreatePed(4, m, c.x, c.y, c.z - 1.0, h or 0.0, false, true)
        SetEntityInvincible(p, true) SetBlockingOfNonTemporaryEvents(p, true) FreezeEntityPosition(p, true)
        TaskStartScenarioInPlace(p, 'WORLD_HUMAN_CLIPBOARD', 0, true) peds[key] = p
    end
    SetModelAsNoLongerNeeded(m)
end

local function openLicenses()
    ESX.TriggerServerCallback('pickax_life:licList', function(r)
        if not r or not r.ok then return notify('error', (r and r.error) or 'Indisponible') end
        local opts = {}
        for _, l in ipairs(r.list) do
            opts[#opts + 1] = { title = l.label, description = l.owned and 'Déjà obtenu' or (l.price .. ' $'), icon = l.owned and 'check' or 'id-card', disabled = l.owned,
                onSelect = function() ESX.TriggerServerCallback('pickax_life:licBuy', function(b) res(b) end, l.item) end }
        end
        lib.registerContext({ id = 'pk_lic', title = C.Licenses.Office.label, options = opts })
        lib.showContext('pk_lic')
    end)
end

local function openBuyer(idx)
    ESX.TriggerServerCallback('pickax_life:buyerList', function(r)
        if not r or not r.ok then return notify('error', (r and r.error) or 'Indisponible') end
        if #r.list == 0 then return notify('inform', 'Tu n\'as rien à vendre ici.') end
        local opts = {}
        for _, it in ipairs(r.list) do
            opts[#opts + 1] = { title = ('%s ×%d'):format(it.item, it.count), description = ('%d $ l\'unité'):format(it.price), icon = 'sack-dollar',
                onSelect = function() ESX.TriggerServerCallback('pickax_life:buyerSell', function(s) res(s) end, idx, it.item, it.count) end }
        end
        lib.registerContext({ id = 'pk_buyer', title = r.label, options = opts })
        lib.showContext('pk_buyer')
    end, idx)
end

local ANIM = { prep = 'PROP_HUMAN_PARKING_METER', stove = 'PROP_HUMAN_BBQ', grill = 'PROP_HUMAN_BBQ', oven = 'PROP_HUMAN_BBQ', all = 'PROP_HUMAN_BBQ' }

local function cookRun(idx, rid)
    busy = true
    ESX.TriggerServerCallback('pickax_life:cookBegin', function(b)
        if not b or not b.ok then busy = false return notify('error', (b and b.error) or 'Impossible') end
        TaskStartScenarioInPlace(PlayerPedId(), ANIM[b.anim] or 'PROP_HUMAN_BBQ', 0, true)
        local function step(s)
            local score = play(s.game, s.cfg)
            if not score then
                ClearPedTasks(PlayerPedId())
                ESX.TriggerServerCallback('pickax_life:cookCancel', function() end)
                busy = false
                return notify('error', 'Préparation abandonnée : ingrédients conservés.')
            end
            ESX.TriggerServerCallback('pickax_life:cookStep', function(r)
                if not r or not r.ok then ClearPedTasks(PlayerPedId()) busy = false return notify('error', (r and r.error) or 'Impossible') end
                if r.done then ClearPedTasks(PlayerPedId()) busy = false return res(r) end
                notify('inform', ('Étape %d / %d'):format(r.n, r.total))
                step(r)
            end, score)
        end
        notify('inform', ('Étape 1 / %d'):format(b.total))
        step(b)
    end, idx, rid)
end

local openCooking
local function openOrders(idx)
    ESX.TriggerServerCallback('pickax_life:ordersList', function(r)
        if not r or not r.ok then return notify('error', (r and r.error) or 'Indisponible') end
        local opts = {}
        for _, o in ipairs(r.list) do
            local ok = o.have and o.have >= o.min and o.left > 0
            opts[#opts + 1] = { title = ('%s ×%d'):format(o.label, o.left), icon = 'receipt', disabled = not ok,
                description = o.left <= 0 and 'Déjà servie' or (o.have and ('Ton plat : %d %% · paiement ≈ %d $ (min. %d %%)'):format(o.have, o.pay, o.min) or ('Tu n\'as pas ce plat · ≈ %d $ (min. %d %%)'):format(o.pay, o.min)),
                onSelect = function() ESX.TriggerServerCallback('pickax_life:orderDeliver', function(d) res(d) end, idx, o.id) end }
        end
        opts[#opts + 1] = { title = 'Retour', icon = 'arrow-left', onSelect = function() openCooking(idx) end }
        lib.registerContext({ id = 'pk_orders', title = 'Commandes des clients', menu = 'pk_cook', options = opts })
        lib.showContext('pk_orders')
    end, idx)
end

openCooking = function(idx)
    ESX.TriggerServerCallback('pickax_life:cookInfo', function(r)
        if not r or not r.ok then return notify('error', (r and r.error) or 'Indisponible') end
        local opts = {}
        opts[#opts + 1] = { title = ('Cuisinier niveau %d'):format(r.level), icon = 'chef-hat', disabled = true,
            description = r.nextXp and ('%d / %d XP · %s'):format(r.xp, r.nextXp, r.typeLabel or '') or ('%d XP · niveau maximal · %s'):format(r.xp, r.typeLabel or '') }
        for _, rc in ipairs(r.list) do
            local need = {}
            for _, n in ipairs(rc.needs) do need[#need + 1] = ('%s %d/%d'):format(n.label or n.item, math.min(n.have, n.count), n.count) end
            opts[#opts + 1] = { title = rc.label, icon = 'utensils', disabled = rc.locked or not rc.can,
                description = rc.locked and ('Niveau %d requis'):format(rc.level) or table.concat(need, ' · '),
                metadata = { { label = 'Étapes', value = rc.steps }, { label = 'Niveau', value = rc.level } },
                onSelect = function() cookRun(idx, rc.id) end }
        end
        if C.Cooking.Orders and C.Cooking.Orders.Enabled then
            opts[#opts + 1] = { title = 'Commandes des clients', icon = 'receipt', description = 'Livre des plats contre paiement', onSelect = function() openOrders(idx) end }
        end
        lib.registerContext({ id = 'pk_cook', title = r.label, options = opts })
        lib.showContext('pk_cook')
    end, idx)
end

local function openMarket()
    ESX.TriggerServerCallback('pickax_life:marketList', function(r)
        if not r or not r.ok then return notify('error', (r and r.error) or 'Indisponible') end
        local opts = {}
        for _, it in ipairs(r.list) do
            opts[#opts + 1] = { title = it.label or it.item, icon = 'basket-shopping', description = ('%d $ l\'unité · tu en as %d'):format(it.price, it.have),
                onSelect = function()
                    local inp = lib.inputDialog(it.label or it.item, { { type = 'number', label = 'Quantité', default = 1, min = 1, max = 50 } })
                    if inp and inp[1] then ESX.TriggerServerCallback('pickax_life:marketBuy', function(b) res(b) openMarket() end, it.item, inp[1]) end
                end }
        end
        lib.registerContext({ id = 'pk_market', title = r.label, options = opts })
        lib.showContext('pk_market')
    end)
end

CreateThread(function()
    while true do
        local sleep = 1000
        local pc = GetEntityCoords(PlayerPedId())
        if not busy then
            local O = C.Licenses.Office
            local d = O.coords and #(pc - O.coords) or 99999.0
            if d < 45.0 then pedAt('lic', O.ped, O.coords, O.pedHeading) end
            if d < 12.0 then sleep = 0 DrawMarker(1, O.coords.x, O.coords.y, O.coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.9, 0.9, 0.4, 253, 194, 125, 120, false, false, 2, false, nil, nil, false)
                if d < O.Distance then help('Appuie sur ~INPUT_CONTEXT~ : bureau des permis') if IsControlJustPressed(0, 38) then openLicenses() Wait(400) end end end
            for i, b in ipairs(C.Buyers) do
                local db = #(pc - b.coords)
                if db < 45.0 then pedAt('buy' .. i, b.ped, b.coords, b.pedHeading) end
                if db < 12.0 then sleep = 0 DrawMarker(1, b.coords.x, b.coords.y, b.coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.9, 0.9, 0.4, 253, 194, 125, 120, false, false, 2, false, nil, nil, false)
                    if db < b.Distance then help('Appuie sur ~INPUT_CONTEXT~ : vendre') if IsControlJustPressed(0, 38) then openBuyer(i) Wait(400) end end end
            end
            do
                local M = C.Cooking.Market
                local dm = M.coords and #(pc - M.coords) or 99999.0
                if dm < 45.0 then pedAt('market', M.ped, M.coords, M.pedHeading) end
                if dm < 12.0 then sleep = 0 DrawMarker(1, M.coords.x, M.coords.y, M.coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.9, 0.9, 0.4, 253, 194, 125, 120, false, false, 2, false, nil, nil, false)
                    if dm < M.Distance then help('Appuie sur ~INPUT_CONTEXT~ : acheter des ingrédients') if IsControlJustPressed(0, 38) then openMarket() Wait(400) end end end
            end
            for i, s in ipairs(C.Cooking.Stations) do
                local dc = #(pc - s.coords)
                if dc < 10.0 then sleep = 0 DrawMarker(1, s.coords.x, s.coords.y, s.coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.8, 0.8, 0.4, 253, 194, 125, 120, false, false, 2, false, nil, nil, false)
                    if dc < C.Cooking.Distance then help('Appuie sur ~INPUT_CONTEXT~ : cuisiner') if IsControlJustPressed(0, 38) then openCooking(i) Wait(400) end end end
            end
        end
        Wait(sleep)
    end
end)

-- ───────────── Taxi et livraison ─────────────
local run, blip = nil, nil
local stats = { damage = 0.0, hard = 0, lastBody = nil, lastSpeed = 0.0 }

local function setTarget(t)
    if blip and DoesBlipExist(blip) then RemoveBlip(blip) end
    if not t then blip = nil return end
    blip = AddBlipForCoord(t.x, t.y, t.z)
    SetBlipSprite(blip, 1) SetBlipColour(blip, 5) SetBlipRoute(blip, true) SetBlipRouteColour(blip, 5)
    BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName('Course') EndTextCommandSetBlipName(blip)
    run.target = t
end

local function toggleRun()
    ESX.TriggerServerCallback('pickax_life:runToggle', function(r)
        if not r or not r.ok then return notify('error', (r and r.error) or 'Impossible') end
        if r.stopped then run = nil setTarget(nil) return notify('inform', r.msg) end
        run = { kind = r.run.kind }
        setTarget(r.run.target)
        stats = { damage = 0.0, hard = 0, lastBody = nil, lastSpeed = 0.0 }
        notify('success', r.run.kind == 'taxi' and 'Service taxi : rends-toi chez le client (GPS).' or 'Service de livraison : va charger les colis (GPS).')
    end)
end
if C.UseCommands then RegisterCommand(C.Runs.Command, function() toggleRun() end, false) end
exports('ToggleRun', toggleRun)   -- menu F6 du job (taxi / livraison)

CreateThread(function()
    while true do
        local sleep = 1000
        if run and run.target then
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 then
                sleep = 250
                local body = GetVehicleBodyHealth(veh)
                if stats.lastBody and body < stats.lastBody then stats.damage = stats.damage + (stats.lastBody - body) end
                stats.lastBody = body
                local spd = GetEntitySpeed(veh)
                if stats.lastSpeed - spd > 9.0 then stats.hard = stats.hard + 1 end
                stats.lastSpeed = spd
                local d = #(GetEntityCoords(ped) - run.target)
                if d < 60.0 then
                    sleep = 0
                    DrawMarker(1, run.target.x, run.target.y, run.target.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, C.Runs.StopRadius * 2.0, C.Runs.StopRadius * 2.0, 1.0, 253, 194, 125, 90, false, false, 2, false, nil, nil, false)
                    if d < C.Runs.StopRadius and spd < C.Runs.MaxArriveSpeed then
                        help('Arrête-toi ~INPUT_CONTEXT~ : valider l\'étape')
                        if IsControlJustPressed(0, 38) then
                            ESX.TriggerServerCallback('pickax_life:runArrive', function(r)
                                if r and r.ok then
                                    notify('success', r.msg)
                                    stats = { damage = 0.0, hard = 0, lastBody = nil, lastSpeed = 0.0 }
                                    if r.next then setTarget(r.next.target) end
                                else notify('error', (r and r.error) or 'Impossible') end
                            end, { damage = stats.damage, hard = stats.hard })
                            Wait(1200)
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then for _, p in pairs(peds) do DeleteEntity(p) end if blip then RemoveBlip(blip) end end end)
