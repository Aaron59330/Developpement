ESX = exports['es_extended']:getSharedObject()

local open = false
local token = nil

-- ─── Panneau ──────────────────────────────────────────────────────────────────
local function closeUI()
    if not open then return end
    open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function openUI()
    if open then return closeUI() end
    if IsEntityDead(PlayerPedId()) then return end
    ESX.TriggerServerCallback('pickax_anticheat:isAllowed', function(view, ban)
        if not view then return ESX.ShowNotification('~r~Accès refusé : réservé à l\'équipe.') end
        open = true
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'open', canBan = ban == true })
    end)
end

RegisterCommand(Config.Panel.Command, openUI, false)
if Config.Panel.Alias then RegisterCommand(Config.Panel.Alias, openUI, false) end
if Config.Panel.Key then RegisterKeyMapping(Config.Panel.Command, 'Ouvrir le panel anti-cheat', 'keyboard', Config.Panel.Key) end

local NuiRemote = {
    overview = true, players = true, player = true, warn = true, kick = true, ban = true, banOffline = true, unban = true, bans = true, logs = true,
    markFp = true, exempt = true, settingsGet = true, settingsSave = true, settingsReset = true, setMode = true,
}
local NuiLocal = {
    close = function(_, cb) cb({ ok = true }) closeUI() end,
    bbHub = function(_, cb) cb({ ok = true }) closeUI() SetTimeout(250, function() ExecuteCommand('builders') end) end,
}

RegisterNUICallback('rpc', function(body, cb)
    local name, args = body.name, body.args or {}
    if NuiLocal[name] then return NuiLocal[name](args, cb) end
    if NuiRemote[name] then
        return ESX.TriggerServerCallback('pickax_anticheat:' .. name, function(res)
            cb(res or { ok = false, error = 'Aucune réponse' })
        end, table.unpack(args))
    end
    cb({ ok = false, error = 'Appel inconnu' })
end)

CreateThread(function()
    while true do
        Wait(300)
        if open and IsEntityDead(PlayerPedId()) then closeUI() end
    end
end)

AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() and open then SetNuiFocus(false, false) end end)

-- ─── Battement de cœur ────────────────────────────────────────────────────────
RegisterNetEvent('pickax_anticheat:token', function(t) token = t end)

CreateThread(function()
    while true do
        Wait(15000)
        if token then TriggerServerEvent('pickax_anticheat:hb', token) end
    end
end)

-- ─── Signalements (le serveur décide : exemptions, score, sanction) ───────────
local last, streak = {}, {}
local function report(kind, value)
    local t = GetGameTimer()
    if last[kind] and t - last[kind] < 60000 then return end
    last[kind] = t
    TriggerServerEvent('pickax_anticheat:report', kind, value)
end

local function sustained(kind, cond, need)
    if cond then streak[kind] = (streak[kind] or 0) + 1 else streak[kind] = 0 end
    return streak[kind] >= need
end

CreateThread(function()
    Wait(30000)
    while true do
        Wait(2000)
        local ped = PlayerPedId()
        local pid = PlayerId()
        if DoesEntityExist(ped) and not IsEntityDead(ped) then
            local dmg = GetPlayerWeaponDamageModifier(pid)
            if sustained('dmg', dmg and dmg > 1.01, 3) then report('damageMod', math.floor(dmg * 100) / 100) end
            local mel = GetPlayerMeleeWeaponDamageModifier(pid)
            if sustained('mel', mel and mel > 1.01, 3) then report('meleeMod', math.floor(mel * 100) / 100) end
            if sustained('inv', not IsEntityVisible(ped) and not IsPedInAnyVehicle(ped, false), 5) then report('invisible', 1) end
            if sustained('spec', NetworkIsInSpectatorMode(), 5) then report('spectate', 1) end
        else
            streak.dmg, streak.mel, streak.inv, streak.spec = 0, 0, 0, 0
        end
    end
end)
