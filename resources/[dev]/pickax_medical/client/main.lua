local ESX = exports['es_extended']:getSharedObject()
local C = Config
local nuiOpen, cur = false, nil   -- cur = id du patient examiné

local function notify(kind, txt) lib.notify({ type = kind, description = txt }) end
local function nui(m) SendNUIMessage(m) end
local function closeNui() if nuiOpen then nuiOpen = false SetNuiFocus(false, false) nui({ action = 'close' }) end cur = nil end
RegisterNUICallback('close', function(_, cb) closeNui() cb(1) end)

-- ───────────── Blessures : zone touchée → serveur ─────────────
local BONES = {
    [31086] = 'head', [39317] = 'head', [12844] = 'head', [65068] = 'head',
    [24816] = 'torso', [24817] = 'torso', [24818] = 'torso', [11816] = 'torso', [57597] = 'torso', [23553] = 'torso', [10706] = 'torso', [64729] = 'torso', [0] = 'torso',
    [45509] = 'larm', [61163] = 'larm', [18905] = 'larm', [22711] = 'larm',
    [40269] = 'rarm', [28252] = 'rarm', [57005] = 'rarm', [2992] = 'rarm',
    [58271] = 'lleg', [63931] = 'lleg', [14201] = 'lleg', [2108] = 'lleg', [65245] = 'lleg',
    [51826] = 'rleg', [36864] = 'rleg', [52301] = 'rleg', [20781] = 'rleg', [35502] = 'rleg',
}
local lastHealth = nil
CreateThread(function()
    while true do
        Wait(250)
        local ped = PlayerPedId()
        local h = GetEntityHealth(ped)
        if lastHealth and h < lastHealth and h > 0 then
            local ok, bone = GetPedLastDamageBone(ped)
            local zone = (ok and BONES[bone]) or 'torso'
            ClearPedLastDamageBone(ped)
            TriggerServerEvent('pickax_medical:hurt', zone, lastHealth - h)
        end
        lastHealth = h
    end
end)

-- ───────────── Effets d'une blessure (lus dans le statebag du joueur) ─────────────
CreateThread(function()
    local E = C.Bleed
    while true do
        Wait(1000)
        local ped = PlayerPedId()
        local med = LocalPlayer.state.med
        if med and not IsEntityDead(ped) then
            local z, blood = med.zones or {}, med.blood or 100
            -- jambes : boiterie
            local leg = math.max((z.lleg and z.lleg.lvl) or 0, (z.rleg and z.rleg.lvl) or 0)
            if leg >= 3 then SetPedMoveRateOverride(ped, 0.62) elseif leg == 2 then SetPedMoveRateOverride(ped, 0.82) else SetPedMoveRateOverride(ped, 1.0) end
            -- bras : tremblement de visée
            local arm = math.max((z.larm and z.larm.lvl) or 0, (z.rarm and z.rarm.lvl) or 0)
            if arm >= 3 and IsPedArmed(ped, 4) then ShakeGameplayCam('HAND_SHAKE', 0.9) elseif arm == 2 and IsPedArmed(ped, 4) then ShakeGameplayCam('HAND_SHAKE', 0.35) else StopGameplayCamShaking(true) end
            -- tête : vision trouble
            if z.head and z.head.lvl >= 3 then SetTimecycleModifier('drug_drive_blend01') SetTimecycleModifierStrength(0.6)
            elseif blood < E.Weak then SetTimecycleModifier('drug_drive_blend01') SetTimecycleModifierStrength(0.35 + (E.Weak - blood) / E.Weak * 0.4)
            else ClearTimecycleModifier() end
        else
            ClearTimecycleModifier()
            if med == nil then SetPedMoveRateOverride(ped, 1.0) end
        end
    end
end)

RegisterNetEvent('pickax_medical:blackout', function()
    local ped = PlayerPedId()
    if IsPedRagdoll(ped) or IsEntityDead(ped) then return end
    SetPedToRagdoll(ped, 7000, 7000, 0, false, false, false)
    notify('error', 'Tu perds connaissance…')
end)

RegisterNetEvent('pickax_medical:revive', function(hp)   -- repli si le Job Builder ne gère pas la mort
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    NetworkResurrectLocalPlayer(c.x, c.y, c.z, GetEntityHeading(ped), true, false)
    SetEntityHealth(PlayerPedId(), math.floor(200 * (hp or 40) / 100))
    ClearPedTasksImmediately(PlayerPedId())
end)

-- ───────────── Étiquettes de triage visibles des soignants ─────────────
local tags = {}
local TAGCOL = { red = { 235, 64, 52 }, orange = { 240, 150, 40 }, green = { 80, 200, 110 }, black = { 70, 70, 80 } }
RegisterNetEvent('pickax_medical:tag', function(id, tag) tags[id] = tag end)
CreateThread(function()
    while true do
        local sleep = 1000
        if next(tags) then
            for id, tag in pairs(tags) do
                local p = GetPlayerFromServerId(id)
                if p ~= -1 then
                    local ped = GetPlayerPed(p)
                    local c = GetEntityCoords(ped)
                    if #(GetEntityCoords(PlayerPedId()) - c) < 30.0 then
                        sleep = 0
                        local col = TAGCOL[tag] or TAGCOL.green
                        DrawMarker(0, c.x, c.y, c.z + 1.25, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.22, 0.22, 0.22, col[1], col[2], col[3], 220, true, false, 2, false, nil, nil, false)
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- ───────────── Examen d'un patient ─────────────
local function nearestPlayer(maxDist)
    local me, best, bd = PlayerPedId(), nil, maxDist
    local mc = GetEntityCoords(me)
    for _, p in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(p)
        if ped ~= me then
            local d = #(mc - GetEntityCoords(ped))
            if d < bd then best, bd = GetPlayerServerId(p), d end
        end
    end
    return best
end

local function refresh()
    if not cur then return end
    ESX.TriggerServerCallback('pickax_medical:exam', function(r) if r and r.ok then nui({ action = 'exam', data = r }) end end, cur)
end

local function openExam(id)
    if nuiOpen then return end
    ESX.TriggerServerCallback('pickax_medical:exam', function(r)
        if not r or not r.ok then return notify('error', (r and r.error) or 'Indisponible') end
        cur = id
        nuiOpen = true
        SetNuiFocus(true, true)
        nui({ action = 'exam', data = r, first = true })
    end, id)
end
RegisterCommand(C.Command, function(_, args)
    local id = tonumber(args[1]) or nearestPlayer(C.Distance)
    if not id then return notify('error', 'Aucun patient à proximité.') end
    openExam(id)
end, false)
exports('OpenExam', openExam)

-- Joue un mini-jeu : le focus passe à skillgames puis revient au panneau
local function play(game, cfg)
    SetNuiFocus(false, false)
    local score = exports.pickax_skillgames:Play(game, cfg)
    if nuiOpen then SetNuiFocus(true, true) end
    return score
end

local function after(r, cb)
    if r and r.ok then notify(r.failed and 'error' or 'success', r.msg or 'OK') else notify('error', (r and r.error) or 'Impossible') end
    refresh()
    cb(r or { ok = false })
end

RegisterNUICallback('treat', function(d, cb)
    ESX.TriggerServerCallback('pickax_medical:treatBegin', function(b)
        if not b or not b.ok then return after(b, cb) end
        local score = play(b.game, b.cfg)
        if not score then return cb({ ok = false, error = 'Soin interrompu' }) end
        ESX.TriggerServerCallback('pickax_medical:treatEnd', function(r) after(r, cb) end, score)
    end, cur, d.zone, d.kind)
end)

RegisterNUICallback('cpr', function(_, cb)
    ESX.TriggerServerCallback('pickax_medical:cprBegin', function(b)
        if not b or not b.ok then return after(b, cb) end
        RequestAnimDict('mini@cpr@char_a@cpr_str')
        local score = play('cpr', b.cfg)
        if not score then return cb({ ok = false, error = 'Massage interrompu' }) end
        ESX.TriggerServerCallback('pickax_medical:cprEnd', function(r) after(r, cb) end, score)
    end, cur)
end)

RegisterNUICallback('xray', function(_, cb)
    ESX.TriggerServerCallback('pickax_medical:xray', function(b)
        if not b or not b.ok then return after(b, cb) end
        local ok = lib.progressBar({ duration = b.seconds * 1000, label = 'Imagerie en cours…', canCancel = true, disable = { move = true } })
        if nuiOpen then SetNuiFocus(true, true) end
        notify('success', #b.found > 0 and 'Radio : lésions identifiées.' or 'Radio : rien à signaler.')
        refresh() cb(b)
    end, cur)
end)

RegisterNUICallback('bloodTest', function(_, cb)
    ESX.TriggerServerCallback('pickax_medical:bloodTest', function(r)
        if r and r.ok then notify('success', ('Groupe sanguin : %s%s'):format(r.group, r.alcohol and (' — alcoolémie %.2f g/L'):format(r.alcohol) or '')) else notify('error', (r and r.error) or 'Impossible') end
        refresh() cb(r or { ok = false })
    end, cur)
end)

RegisterNUICallback('donate', function(_, cb) ESX.TriggerServerCallback('pickax_medical:donate', function(r) after(r, cb) end, cur) end)
RegisterNUICallback('transfuse', function(_, cb)
    ESX.TriggerServerCallback('pickax_medical:transfuseBegin', function(b)
        if not b or not b.ok then return after(b, cb) end
        local score = play(b.game, b.cfg)
        if not score then return cb({ ok = false, error = 'Interrompue' }) end
        ESX.TriggerServerCallback('pickax_medical:transfuseEnd', function(r) after(r, cb) end, score)
    end, cur)
end)

RegisterNUICallback('triageList', function(_, cb) ESX.TriggerServerCallback('pickax_medical:triageList', function(r) cb(r or { ok = false }) end) end)
RegisterNUICallback('triageTag', function(d, cb)
    ESX.TriggerServerCallback('pickax_medical:triageTag', function(r) cb(r or { ok = false }) end, d.id, d.tag)
end)
RegisterNUICallback('openPatient', function(d, cb) cb(1) cur = tonumber(d.id) refresh() end)

-- /triage : ouvre directement la liste des blessés autour
RegisterCommand('triage', function()
    if nuiOpen then return end
    ESX.TriggerServerCallback('pickax_medical:triageList', function(r)
        if not r or not r.ok then return notify('error', (r and r.error) or 'Réservé aux EMS') end
        nuiOpen = true
        SetNuiFocus(true, true)
        nui({ action = 'triage', data = r })
    end)
end, false)

AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then if nuiOpen then SetNuiFocus(false, false) end SetPedMoveRateOverride(PlayerPedId(), 1.0) ClearTimecycleModifier() end end)
