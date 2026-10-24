-- ─────────────────────────────── Plantations : plantes qui poussent (client) ───────────────────────────────
-- Le serveur envoie la liste des plantes (module, point, heure de plantation). Chaque client calcule la croissance avec l'heure du serveur
-- et affiche une plante (petite / moyenne / grande) à l'emplacement de la parcelle, avec son pourcentage.
local plants = {}      -- liste { eid, pi, at }
local clockOffset = 0  -- heure serveur - heure locale (secondes)
local objects = {}     -- ['eid:pi'] = { ent, stage }

local DEFAULT_MODELS = { 'bkr_prop_weed_01_small_01a', 'bkr_prop_weed_med_01a', 'bkr_prop_weed_lrg_01a' }

local function serverNow() return GetCloudTimeAsInt() + clockOffset end

RegisterNetEvent('illegalbuilder:client:plants', function(data)
    data = data or {}
    plants = data.list or {}
    clockOffset = (tonumber(data.now) or GetCloudTimeAsInt()) - GetCloudTimeAsInt()
end)

local function pointOf(eid, pi)
    for _, e in ipairs((State and State.entities) or {}) do
        if e.id == eid then for _, p in ipairs(e.points) do if p.i == pi then return p end end end
    end
end

local function clear(key)
    local o = objects[key]
    if o and DoesEntityExist(o.ent) then DeleteEntity(o.ent) end
    objects[key] = nil
end

local function spawn(key, model, c)
    local hash = joaat(model)
    if not IsModelInCdimage(hash) then return nil end
    RequestModel(hash)
    local t = GetGameTimer() + 3000
    while not HasModelLoaded(hash) and GetGameTimer() < t do Wait(10) end
    if not HasModelLoaded(hash) then return nil end
    local ent = CreateObject(hash, c.x + 0.0, c.y + 0.0, c.z + 0.0, false, false, false)
    SetModelAsNoLongerNeeded(hash)
    if not ent or ent == 0 then return nil end
    PlaceObjectOnGroundProperly(ent)
    FreezeEntityPosition(ent, true)
    SetEntityCollision(ent, false, false)
    return ent
end

local function text3d(x, y, z, text)
    SetDrawOrigin(x, y, z, 0)
    SetTextScale(0.0, 0.32) SetTextFont(4) SetTextCentre(true) SetTextOutline()
    SetTextColour(255, 255, 255, 235)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

CreateThread(function()
    while true do
        local sleep = 1000
        local pos = GetEntityCoords(PlayerPedId())
        local alive = {}
        for _, pl in ipairs(plants) do
            local p = pointOf(pl.eid, pl.pi)
            local def = p and p.plant
            if def and p.coords then
                local key = pl.eid .. ':' .. pl.pi
                alive[key] = true
                local d = #(pos - vector3(p.coords.x, p.coords.y, p.coords.z))
                if d < 60.0 then
                    local pct = math.min(100.0, math.max(0.0, (serverNow() - pl.at) / (math.max(1, def.growMinutes) * 60) * 100.0))
                    local stage = pct >= 100.0 and 3 or (pct >= 50.0 and 2 or 1)
                    local o = objects[key]
                    if not o or o.stage ~= stage or not DoesEntityExist(o.ent) then
                        clear(key)
                        local model = ({ def.small, def.medium, def.large })[stage]
                        if not model or model == '' then model = DEFAULT_MODELS[stage] end
                        local ent = spawn(key, model, p.coords)
                        if ent then objects[key] = { ent = ent, stage = stage } end
                    end
                    if d < 7.0 then
                        sleep = 0
                        local label = pct >= 100.0 and '~g~Prête à récolter' or ('Pousse : ~y~%d %%'):format(math.floor(pct))
                        text3d(p.coords.x, p.coords.y, p.coords.z + 1.1, label)
                    end
                else
                    clear(key)
                end
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
