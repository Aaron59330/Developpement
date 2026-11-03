local active, prom = false, nil
local kitProm = nil

local function Play(game, cfg)
    if active then return nil end
    active = true
    prom = promise.new()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'play', game = game, cfg = cfg or {} })
    local score = Citizen.Await(prom)
    prom = nil
    active = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    return score
end
exports('Play', Play)
exports('IsPlaying', function() return active end)

-- ───────────── Interface commune : menus, formulaires, confirmations, progression ─────────────
local function ask(kind, cfg)
    if active then return nil end
    active = true
    kitProm = promise.new()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'kit', kind = kind, cfg = cfg })
    local r = Citizen.Await(kitProm)
    kitProm = nil
    active = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    return r
end
RegisterNUICallback('kitResult', function(d, cb) if kitProm then kitProm:resolve(d and d.value) end cb(1) end)

-- Menu : options = { { title, description, icon, disabled, metadata = { { label, value } }, onSelect = function() } } ; non bloquant (renvoie tout de suite)
exports('ShowMenu', function(cfg)
    CreateThread(function()
        local opts, safe = {}, {}
        for i, o in ipairs((cfg and cfg.options) or {}) do
            opts[i] = o
            safe[i] = { title = o.title, description = o.description, icon = o.icon, disabled = o.disabled, metadata = o.metadata }
        end
        local idx = ask('menu', { title = cfg and cfg.title, options = safe })
        local o = idx and opts[tonumber(idx)]
        if o and o.onSelect and not o.disabled then o.onSelect() end
    end)
end)
-- Formulaire : fields = { { type = 'input'|'textarea'|'number'|'select', label, required, max, min, default, options = { { value, label } } } } → tableau de valeurs, ou nil
exports('Input', function(cfg) return ask('input', cfg) end)
-- Confirmation : { header, content (**gras**, retours à la ligne), labels = { confirm, cancel }, cancel = true } → 'confirm' | 'cancel' | nil
exports('Confirm', function(cfg)
    local r = ask('confirm', cfg)
    return r
end)
exports('CloseKit', function() if kitProm then kitProm:resolve(nil) end end)

-- Barre de progression (animation, annulation avec X, immobilisation) → true si terminée
exports('Progress', function(cfg)
    cfg = cfg or {}
    local ped = PlayerPedId()
    local dur = cfg.duration or 3000
    local a = cfg.anim
    if a then
        if a.scenario then TaskStartScenarioInPlace(ped, a.scenario, 0, true)
        elseif a.dict then
            RequestAnimDict(a.dict)
            local t = GetGameTimer() + 1500
            while not HasAnimDictLoaded(a.dict) and GetGameTimer() < t do Wait(10) end
            TaskPlayAnim(ped, a.dict, a.clip, 2.0, 2.0, -1, a.flag or 49, 0, false, false, false)
        end
    end
    SendNUIMessage({ action = 'progress', label = cfg.label or '', duration = dur, cancel = cfg.canCancel and true or false })
    local t0, ok = GetGameTimer(), true
    while GetGameTimer() - t0 < dur do
        Wait(0)
        if cfg.disable and cfg.disable.move then for _, k in ipairs({ 30, 31, 21, 22, 23, 36, 44 }) do DisableControlAction(0, k, true) end end
        if cfg.disable and cfg.disable.combat then for _, k in ipairs({ 24, 25, 37, 140, 141, 142, 257, 263, 264 }) do DisableControlAction(0, k, true) end end
        if IsEntityDead(ped) then ok = false break end
        if cfg.canCancel and (IsControlJustPressed(0, 73) or IsControlJustPressed(0, 177)) then ok = false break end
    end
    SendNUIMessage({ action = 'progressEnd' })
    if a then ClearPedTasks(PlayerPedId()) end
    return ok
end)

RegisterNUICallback('done', function(d, cb) if prom then prom:resolve(d and tonumber(d.score)) end cb(1) end)

AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() and active then SetNuiFocus(false, false) end end)

if Config.Debug then RegisterCommand('skillgame', function(_, args)
    local ESX = exports['es_extended']:getSharedObject()
    local g = ESX.GetPlayerData().group
    if not Config.AllowTest[g] then return end
    CreateThread(function() local s = Play(args[1] or 'pins', {}) print('[skillgames] score', s) end)
end, false) end
