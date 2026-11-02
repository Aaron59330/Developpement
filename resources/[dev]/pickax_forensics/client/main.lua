local ESX = exports['es_extended']:getSharedObject()
local Ev = {}          -- [id] = { id, x, y, z } : douilles visibles (police uniquement)
local isPolice = false

local policeJobs = {}
for _, j in ipairs(Config.PoliceJobs) do policeJobs[j] = true end

local function refreshJob()
    local d = ESX.GetPlayerData()
    local was = isPolice
    isPolice = d and d.job and policeJobs[d.job.name] == true or false
    if isPolice ~= was or isPolice then TriggerServerEvent('pickax_forensics:requestSync') end
    if not isPolice then Ev = {} end
end

RegisterNetEvent('esx:playerLoaded', function() Wait(1500) refreshJob() end)
RegisterNetEvent('esx:setJob', function() Wait(300) refreshJob() end)
CreateThread(function() Wait(3000) refreshJob() end)

RegisterNetEvent('pickax_forensics:sync', function(list)
    Ev = {}
    for _, e in ipairs(list or {}) do Ev[e.id] = e end
end)
RegisterNetEvent('pickax_forensics:add', function(e) Ev[e.id] = e end)
RegisterNetEvent('pickax_forensics:remove', function(id) Ev[id] = nil end)

-- ───────────── Tir : le client signale seulement qu'il tire (le serveur décide de tout) ─────────────
CreateThread(function()
    local last = 0
    while true do
        Wait(0)
        local ped = PlayerPedId()
        if IsPedShooting(ped) then
            local now = GetGameTimer()
            if now - last > Config.Casings.MinInterval then
                last = now
                TriggerServerEvent('pickax_forensics:shot')
            end
        else
            Wait(60)
        end
    end
end)

-- ───────────── Aide à l'écran ─────────────
local function help(txt)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(txt)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local COL = { 253, 194, 125 }

-- ───────────── Douilles : repères et ramassage (police) ─────────────
local busy = false
CreateThread(function()
    while true do
        local sleep = 800
        if isPolice and not busy then
            local pc = GetEntityCoords(PlayerPedId())
            local nearest, nd
            for id, e in pairs(Ev) do
                local d = #(pc - vector3(e.x, e.y, e.z))
                if d < Config.Casings.DrawDistance then
                    sleep = 0
                    DrawMarker(0, e.x, e.y, e.z + 0.35, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.12, 0.12, 0.12, COL[1], COL[2], COL[3], 190, true, false, 2, false, nil, nil, false)
                    if not nd or d < nd then nearest, nd = e, d end
                end
            end
            if nearest and nd <= Config.Casings.PickupDistance and not IsPedInAnyVehicle(PlayerPedId(), false) then
                help('Appuie sur ~INPUT_CONTEXT~ pour ramasser la douille')
                if IsControlJustPressed(0, 38) then
                    busy = true
                    local ok = lib.progressBar({ duration = Config.Casings.PickupSeconds * 1000, label = 'Ramassage de la douille…', canCancel = true,
                        disable = { move = true, combat = true }, anim = { dict = 'pickup_object', clip = 'pickup_low' } })
                    if ok then
                        ESX.TriggerServerCallback('pickax_forensics:collect', function(r)
                            if r and r.ok then lib.notify({ type = 'success', description = ('Douille #%d placée sous scellé.'):format(r.id) })
                            else lib.notify({ type = 'error', description = (r and r.error) or 'Impossible' }) end
                        end, nearest.id)
                        Wait(600)
                    end
                    busy = false
                end
            end
        end
        Wait(sleep)
    end
end)

-- ───────────── Rapport d'analyse ─────────────
local function street(x, y)
    local s = GetStreetNameFromHashKey((GetStreetNameAtCoord(x + 0.0, y + 0.0, 0.0)))
    return s ~= '' and s or 'lieu inconnu'
end

local function showReport(r)
    local lines = {
        ('**Douille #%d**'):format(r.id), '',
        ('- Arme : **%s**'):format(r.weapon:gsub('WEAPON_', ''):lower()),
        ('- Calibre : **%s**'):format(r.caliber),
        ('- Signature balistique : **%s**'):format(r.signature),
        ('- Tir enregistré : %s'):format(r.shotAt),
        r.serial and ('- N° de série : **%s**'):format(r.serial) or '- N° de série : **absent ou limé** (arme non traçable)',
        r.owner and ('- Propriétaire enregistré : **%s**'):format(r.owner) or '- Propriétaire : **arme non enregistrée**',
        '',
    }
    if #r.matches > 0 then
        lines[#lines + 1] = ('**Correspondance balistique : %d autre(s) douille(s) tirée(s) par la même arme**'):format(#r.matches)
        for _, m in ipairs(r.matches) do lines[#lines + 1] = ('- Douille #%d — %s — %s'):format(m.id, m.at, street(m.x, m.y)) end
    else
        lines[#lines + 1] = 'Aucune correspondance dans le fichier pour le moment.'
    end
    lib.alertDialog({ header = 'Rapport de balistique', content = table.concat(lines, '\n'), centered = true, size = 'md' })
end

local function openLab()
    ESX.TriggerServerCallback('pickax_forensics:labInfo', function(r)
        if not r or not r.ok then return lib.notify({ type = 'error', description = (r and r.error) or 'Indisponible' }) end
        if #r.items == 0 then return lib.notify({ type = 'inform', description = 'Tu n\'as aucun scellé à analyser.' }) end
        local opts = {}
        for _, it in ipairs(r.items) do
            opts[#opts + 1] = {
                title = it.label, description = it.analysed and ('Déjà analysée — ' .. (it.signature or '')) or 'Lancer l\'analyse balistique',
                icon = it.analysed and 'file-circle-check' or 'microscope',
                onSelect = function()
                    local ok = lib.progressBar({ duration = r.seconds * 1000, label = 'Analyse balistique…', canCancel = true, disable = { move = true, combat = true },
                        anim = { scenario = 'PROP_HUMAN_PARKING_METER' } })
                    if not ok then return end
                    ESX.TriggerServerCallback('pickax_forensics:analyse', function(res)
                        if res and res.ok then showReport(res.report)
                        else lib.notify({ type = 'error', description = (res and res.error) or 'Analyse impossible' }) end
                    end, it.slot)
                end,
            }
        end
        lib.registerContext({ id = 'pickax_forensics_lab', title = 'Laboratoire — scellés', options = opts })
        lib.showContext('pickax_forensics_lab')
    end)
end

-- Laboratoires : repère au sol + blip
local blips = {}
CreateThread(function()
    for _, l in ipairs(Config.Labs) do
        if l.blip then
            local b = AddBlipForCoord(l.coords.x, l.coords.y, l.coords.z)
            SetBlipSprite(b, 403) SetBlipColour(b, 3) SetBlipScale(b, 0.6) SetBlipAsShortRange(b, true)
            BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName(l.label) EndTextCommandSetBlipName(b)
            blips[#blips + 1] = b
        end
    end
end)
AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then for _, b in ipairs(blips) do RemoveBlip(b) end end end)

CreateThread(function()
    while true do
        local sleep = 1000
        if isPolice and not busy then
            local pc = GetEntityCoords(PlayerPedId())
            for _, l in ipairs(Config.Labs) do
                local d = #(pc - l.coords)
                if d < Config.Analysis.DrawDistance then
                    sleep = 0
                    DrawMarker(1, l.coords.x, l.coords.y, l.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 0.5, COL[1], COL[2], COL[3], 150, false, false, 2, false, nil, nil, false)
                    if d <= Config.Analysis.InteractDistance then
                        help('Appuie sur ~INPUT_CONTEXT~ : analyser les scellés')
                        if IsControlJustPressed(0, 38) then openLab() Wait(500) end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- ───────────── /balistique [n° de série | BAL-xxxxxx] ─────────────
RegisterCommand(Config.Analysis.Command, function(_, args)
    if not isPolice then return lib.notify({ type = 'error', description = 'Réservé à la police.' }) end
    ESX.TriggerServerCallback('pickax_forensics:lookup', function(r)
        if not r or not r.ok then return lib.notify({ type = 'error', description = (r and r.error) or 'Indisponible' }) end
        if #r.rows == 0 then return lib.notify({ type = 'inform', description = 'Aucune douille analysée ne correspond.' }) end
        local lines = { r.q ~= '' and ('**Recherche : %s**'):format(r.q) or '**Dernières analyses**', '' }
        for _, x in ipairs(r.rows) do
            lines[#lines + 1] = ('- #%d — %s — %s — **%s** — %s — %s — %s'):format(x.id, x.weapon:gsub('WEAPON_', ''):lower(), x.caliber, x.signature,
                x.serial or 'sans n° de série', x.owner or 'non enregistrée', street(x.x, x.y))
        end
        lib.alertDialog({ header = 'Fichier balistique', content = table.concat(lines, '\n'), centered = true, size = 'lg' })
    end, args[1] or '')
end, false)
