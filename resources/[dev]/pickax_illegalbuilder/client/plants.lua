-- ─────────────────────────────── Plantations : plantes qui poussent (client) ───────────────────────────────
-- Le serveur envoie la liste des plantes (module, point, heure de plantation). Chaque client calcule la croissance avec l'heure du serveur
-- et affiche une plante (petite / moyenne / grande) à l'emplacement de la parcelle, avec son pourcentage.
local plants = {}      -- ['eid:pi'] = heure de plantation (secondes serveur)
local srvAtSync, timerAtSync = 0, 0   -- heure serveur reçue + minuteur local au moment de la synchro (horloge monotone : la pousse avance en continu)
local objects = {}        -- ['eid:pi'] = { ent, stage, baseZ, z }

-- Modèles par défaut (petite → moyenne → grande) et repli sur les plants de cannabis du jeu de base si un modèle est introuvable
local DEFAULT_MODELS = { 'bkr_prop_weed_01_small_01a', 'bkr_prop_weed_med_01a', 'bkr_prop_weed_lrg_01a' }
local FALLBACK_MODELS = { 'prop_weed_02', 'prop_weed_02', 'prop_weed_01' }
local SINK = 0.45    -- la plante sort de terre : enfoncée de SINK m au début de chaque stade, à fleur de sol à la fin du stade

local function serverNow() return srvAtSync + (GetGameTimer() - timerAtSync) / 1000.0 end

RegisterNetEvent('illegalbuilder:client:plants', function(data)
    data = data or {}
    plants = {}
    for _, r in ipairs(data.list or {}) do plants[r.eid .. ':' .. r.pi] = r.at end
    srvAtSync, timerAtSync = tonumber(data.now) or 0, GetGameTimer()
end)

local function clear(key)
    local o = objects[key]
    if o and DoesEntityExist(o.ent) then DeleteEntity(o.ent) end
    objects[key] = nil
end

local function loadModel(name)
    local hash = joaat(name)
    if not IsModelInCdimage(hash) then return nil end
    RequestModel(hash)
    local t = GetGameTimer() + 3000
    while not HasModelLoaded(hash) and GetGameTimer() < t do Wait(10) end
    return HasModelLoaded(hash) and hash or nil
end

local function spawn(model, fallback, c)
    local hash = loadModel(model) or loadModel(fallback)
    if not hash then return nil end
    local ent = CreateObject(hash, c.x + 0.0, c.y + 0.0, c.z + 0.0, false, false, false)
    SetModelAsNoLongerNeeded(hash)
    if not ent or ent == 0 then return nil end
    PlaceObjectOnGroundProperly(ent)
    FreezeEntityPosition(ent, true)
    SetEntityCollision(ent, false, false)
    return ent
end

local function text3d(x, y, z, text, scale)
    SetDrawOrigin(x, y, z, 0)
    SetTextScale(0.0, scale or 0.32) SetTextFont(4) SetTextCentre(true) SetTextOutline()
    SetTextColour(255, 255, 255, 235)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

local function fmtLeft(sec)
    sec = math.max(0, math.floor(sec))
    if sec >= 3600 then return ('%d h %02d min'):format(sec // 3600, (sec % 3600) // 60) end
    return ('%d min %02d s'):format(sec // 60, sec % 60)
end

-- Toutes les parcelles (points de récolte avec plantation), plantées ou non
local function plots()
    local list = {}
    for _, e in ipairs((State and State.entities) or {}) do
        if e.type == 'drug' then
            for _, p in ipairs(e.points) do
                if p.kind == 'harvest' and p.plant and p.coords then list[#list + 1] = { key = e.id .. ':' .. p.i, p = p, def = p.plant } end
            end
        end
    end
    return list
end

CreateThread(function()
    while true do
        local sleep = 1000
        local pos = GetEntityCoords(PlayerPedId())
        local alive = {}
        for _, plot in ipairs(plots()) do
            local key, p, def = plot.key, plot.p, plot.def
            alive[key] = true
            local d = #(pos - vector3(p.coords.x, p.coords.y, p.coords.z))
            local at = plants[key]
            if at and d < 60.0 then
                local total = math.max(1, def.growMinutes) * 60
                local pct = math.min(100.0, math.max(0.0, (serverNow() - at) / total * 100.0))
                -- stade : petite (0-40 %), moyenne (40-80 %), grande (80-100 %) ; la plante « sort de terre » progressivement dans chaque stade
                local stage, lo, hi = 1, 0.0, 40.0
                if pct >= 80.0 then stage, lo, hi = 3, 80.0, 100.0 elseif pct >= 40.0 then stage, lo, hi = 2, 40.0, 80.0 end
                local within = (pct - lo) / (hi - lo)
                local sink = SINK * (1.0 - math.min(1.0, within))
                local o = objects[key]
                if not o or o.stage ~= stage or not DoesEntityExist(o.ent) then
                    clear(key)
                    local model = ({ def.small, def.medium, def.large })[stage]
                    if not model or model == '' then model = DEFAULT_MODELS[stage] end
                    local ent = spawn(model, FALLBACK_MODELS[stage], p.coords)
                    if ent then
                        local bc = GetEntityCoords(ent)
                        objects[key] = { ent = ent, stage = stage, baseZ = bc.z, z = nil }
                        o = objects[key]
                    end
                end
                if o and (not o.z or math.abs(o.z - sink) > 0.01) then
                    SetEntityCoordsNoOffset(o.ent, p.coords.x + 0.0, p.coords.y + 0.0, o.baseZ - sink, false, false, false)
                    o.z = sink
                end
            else
                clear(key)
            end

            -- petit texte au-dessus de chaque parcelle
            if d < 12.0 then
                sleep = 0
                local title, status
                if not at then
                    title, status = (p.label and p.label ~= '') and p.label or 'Parcelle', '~w~Parcelle vide · plante des graines'
                else
                    local total = math.max(1, def.growMinutes) * 60
                    local left = total - (serverNow() - at)
                    title = (p.label and p.label ~= '') and p.label or 'Plante'
                    if left <= 0 then status = '~g~Prête à récolter'
                    else
                        local pct = math.floor(math.min(99.0, (serverNow() - at) / total * 100.0))
                        status = ('~y~Pousse encore · %d %% · prête dans %s'):format(pct, fmtLeft(left))
                    end
                end
                local z = p.coords.z + 1.25
                text3d(p.coords.x, p.coords.y, z + 0.14, '~s~' .. title, 0.27)
                text3d(p.coords.x, p.coords.y, z, status, 0.32)
            end
        end
        for key in pairs(objects) do if not alive[key] then clear(key) end end
        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for key in pairs(objects) do clear(key) end
end)
