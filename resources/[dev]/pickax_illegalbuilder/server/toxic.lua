-- ─────────────────────────────── Intoxication des laboratoires (serveur) ───────────────────────────────
-- Le client signale qu'il est dans un laboratoire sans la tenue ; le serveur vérifie la position, limite la fréquence et gère le niveau,
-- les dégâts, la mort et la guérison (un seul item).
local T = Config.Toxic
local Level = {}      -- [src] = niveau d'intoxication (0-100)
local Last = {}       -- [src] = dernier signalement accepté (GetGameTimer)
local Warned = {}     -- [src] = dernier seuil d'alerte annoncé

local function setLevel(src, v)
    v = math.max(0, math.min(T.KillAt, v))
    Level[src] = v
    if Player(src) then Player(src).state:set('labToxic', math.floor(v), true) end
    TriggerClientEvent('illegalbuilder:client:toxic', src, math.floor(v))
end

local function save(src)
    local x = ESX.GetPlayerFromId(src)
    if not x then return end
    local v = math.floor(Level[src] or 0)
    if v > 0 then
        MySQL.update('INSERT INTO illegalbuilder_toxic (identifier, level) VALUES (?, ?) ON DUPLICATE KEY UPDATE level = VALUES(level)', { x.identifier, v })
    else
        MySQL.update('DELETE FROM illegalbuilder_toxic WHERE identifier = ?', { x.identifier })
    end
end

-- Dans le rayon d'un laboratoire exigeant une tenue ?
local function inLab(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    local c = GetEntityCoords(ped)
    for _, e in pairs(IB.Entities) do
        if e.type == 'drug' and e.enabled then
            for _, p in ipairs(e.points) do
                local o = p.kind == 'process' and p.outfit
                if o and o.enabled and p.coords then
                    local r = (o.radius or 15) + 6.0
                    if #(vector3(c.x, c.y, c.z) - vector3(p.coords.x, p.coords.y, p.coords.z)) <= r then return true end
                end
            end
        end
    end
    return false
end

AddEventHandler('esx:playerLoaded', function(src, xPlayer)
    xPlayer = xPlayer or ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    local row = MySQL.single.await('SELECT level FROM illegalbuilder_toxic WHERE identifier = ?', { xPlayer.identifier })
    setLevel(src, row and tonumber(row.level) or 0)
end)

AddEventHandler('playerDropped', function()
    local src = source
    if Level[src] ~= nil then save(src) end
    Level[src], Last[src], Warned[src] = nil, nil, nil
end)

-- Exposition signalée par le client (sans la tenue dans un laboratoire)
RegisterNetEvent('illegalbuilder:server:labExposure', function()
    local src = source
    if not T.Enabled or not ESX.GetPlayerFromId(src) then return end
    local now = GetGameTimer()
    if Last[src] and now - Last[src] < (T.Tick * 1000) - 800 then return end   -- au plus un signalement par tick
    if not inLab(src) then return end
    Last[src] = now
    setLevel(src, (Level[src] or 0) + T.ExposureGain)
end)

-- Évolution de la maladie, dégâts, mort
CreateThread(function()
    while true do
        Wait(T.Tick * 1000)
        if T.Enabled then
            for src, lvl in pairs(Level) do
                if lvl > 0 and ESX.GetPlayerFromId(src) then
                    local ped = GetPlayerPed(src)
                    local dead = ped and ped ~= 0 and GetEntityHealth(ped) <= 0
                    if dead then
                        setLevel(src, 0) save(src) Warned[src] = nil
                    else
                        -- la maladie progresse toute seule (le niveau d'exposition est ajouté séparément par le signalement du client)
                        local new = lvl + (Last[src] and GetGameTimer() - Last[src] < T.Tick * 1000 + 500 and 0 or T.SickGain)
                        setLevel(src, new)
                        new = Level[src]
                        if new >= T.DamageFrom and ped and ped ~= 0 then SetEntityHealth(ped, math.max(0, GetEntityHealth(ped) - T.DamageHealth)) end
                        for _, w in ipairs(T.WarnAt) do
                            if new >= w and (Warned[src] or 0) < w then
                                Warned[src] = w
                                IB.notify(src, w >= 80 and 'Tu es mourant ! Il te faut un ' .. T.CureItem .. ' tout de suite.' or w >= 50 and 'Tu vomis, ton état empire.' or 'Tu te sens mal… Tu es intoxiqué.', 'error')
                            end
                        end
                        if new >= T.KillAt then
                            if ped and ped ~= 0 then SetEntityHealth(ped, 0) end
                            IB.notify(src, 'L\'intoxication t\'a tué.', 'error')
                            IB.log(nil, ESX.GetPlayerFromId(src), 'toxic_death', 'Intoxication de laboratoire')
                            setLevel(src, 0) save(src) Warned[src] = nil
                        end
                    end
                end
            end
        end
    end
end)

-- Sauvegarde régulière des niveaux
CreateThread(function()
    while true do Wait(60000) for src in pairs(Level) do save(src) end end
end)

-- Mort (réanimation, hôpital…) : la maladie disparaît à la réapparition
RegisterNetEvent('esx:onPlayerDeath', function()
    local src = source
    if (Level[src] or 0) > 0 then setLevel(src, 0) save(src) Warned[src] = nil end
end)

-- L'unique remède
ESX.RegisterUsableItem(T.CureItem, function(src)
    if (Level[src] or 0) <= 0 then return IB.notify(src, 'Tu n\'es pas intoxiqué.', 'info') end
    if not IB.removeItem(src, T.CureItem, 1) then return end
    setLevel(src, 0) save(src) Warned[src] = nil
    TriggerClientEvent('illegalbuilder:client:toxicCured', src)
    IB.notify(src, 'Antidote pris : tu es guéri.', 'success')
    IB.log(nil, ESX.GetPlayerFromId(src), 'toxic_cure', T.CureItem)
end)

exports('GetToxicLevel', function(src) return math.floor(Level[tonumber(src)] or 0) end)
