-- ─────────────────────────────── Props du gang ───────────────────────────────
-- Les props sont de vrais objets créés par le serveur (visibles par tous, avec collision). Limite par joueur : Config.Props.BaseLimit,
-- augmentée par le niveau VIP (exports.pickax_core:GetVIPLevel). Le serveur vérifie le gang, l'action « props », le modèle, la distance et la limite.
local P = Config.Props
local Props = {}      -- [id] = { id, ent, owner, src, gang, model, label, at }
local nextId = 1
local lastPlace = {}  -- [src] = dernière pose (GetGameTimer)

local function fail(msg) return { ok = false, error = msg } end

local function vipLevel(src)
    local ok, l = pcall(function() return exports.pickax_core:GetVIPLevel(src) end)
    return ok and tonumber(l) or 0
end

-- limite du joueur : la plus haute entre la limite de base et celle de son niveau VIP
local function limitFor(src)
    local l = vipLevel(src)
    local lim = P.BaseLimit
    if l > 0 and P.VipLimits and P.VipLimits[l] then lim = math.max(lim, P.VipLimits[l]) end
    return lim, l
end

local function catalogEntry(id)
    for _, c in ipairs(P.Catalog) do if c.id == id then return c end end
end

local function countOf(identifier)
    local n = 0
    for _, p in pairs(Props) do if p.owner == identifier then n = n + 1 end end
    return n
end

-- Props posés par le même joueur via son métier (pickax_jobbuilder) : la limite est commune (gang + métier)
local function otherCount(identifier)
    local ok, n = pcall(function() return exports.pickax_jobbuilder:CountProps(identifier) end)
    return ok and tonumber(n) or 0
end
local function totalCount(identifier) return countOf(identifier) + otherCount(identifier) end

local function removeProp(id)
    local p = Props[id]
    if not p then return end
    if p.ent and DoesEntityExist(p.ent) then DeleteEntity(p.ent) end
    Props[id] = nil
end

local function removeOf(identifier)
    for id, p in pairs(Props) do if p.owner == identifier then removeProp(id) end end
end

-- Joueur autorisé : dans un gang qui a l'action « props » cochée
local function allowed(src)
    local gang, grade, xPlayer = GB.gangOf(src)
    if not P.Enabled or not gang then return nil end
    for _, a in ipairs(gang.settings.actions or {}) do if a == 'props' then return gang, grade, xPlayer end end
    return nil
end

local function mine(identifier)
    local list = {}
    for _, p in pairs(Props) do
        if p.owner == identifier then list[#list + 1] = { id = p.id, label = p.label } end
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end

ESX.RegisterServerCallback('gangbuilder:props:list', function(src, cb)
    local gang, _, xPlayer = allowed(src)
    if not gang then return cb(fail('Les props ne sont pas disponibles pour ton gang')) end
    local limit, vip = limitFor(src)
    local cat = {}
    for _, c in ipairs(P.Catalog) do cat[#cat + 1] = { id = c.id, label = c.label, cat = c.cat } end
    cb({ ok = true, limit = limit, vip = vip, base = P.BaseLimit, vipLimits = P.VipLimits, count = totalCount(xPlayer.identifier), catalog = cat, mine = mine(xPlayer.identifier),
        gangLabel = gang.label })
end)

ESX.RegisterServerCallback('gangbuilder:props:place', function(src, cb, id, c)
    local gang, _, xPlayer = allowed(src)
    if not gang then return cb(fail('Props non disponibles pour ton gang')) end
    local entry = catalogEntry(tostring(id))
    if not entry then return cb(fail('Prop inconnu')) end
    if type(c) ~= 'table' or not tonumber(c.x) or not tonumber(c.y) or not tonumber(c.z) then return cb(fail('Position invalide')) end
    local now = GetGameTimer()
    if lastPlace[src] and now - lastPlace[src] < (P.Cooldown or 1500) then return cb(fail('Doucement…')) end
    local limit = limitFor(src)
    if totalCount(xPlayer.identifier) >= limit then return cb(fail(('Limite atteinte : %d props maximum'):format(limit))) end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return cb(fail('Erreur')) end
    local pc = GetEntityCoords(ped)
    local x, y, z, h = tonumber(c.x) + 0.0, tonumber(c.y) + 0.0, tonumber(c.z) + 0.0, (tonumber(c.h) or 0.0) + 0.0
    if #(vector3(pc.x, pc.y, pc.z) - vector3(x, y, z)) > (P.PlaceDistance or 10.0) + 4.0 then return cb(fail('Trop loin du joueur')) end

    local ent = CreateObjectNoOffset(joaat(entry.model), x, y, z, true, true, false)
    local t = GetGameTimer()
    while (not ent or ent == 0 or not DoesEntityExist(ent)) and GetGameTimer() - t < 2000 do Wait(50) end
    if not ent or ent == 0 or not DoesEntityExist(ent) then return cb(fail('Impossible de créer le prop (modèle introuvable ?)')) end
    SetEntityHeading(ent, h)
    FreezeEntityPosition(ent, true)
    lastPlace[src] = now
    local pid = nextId nextId = nextId + 1
    Props[pid] = { id = pid, ent = ent, owner = xPlayer.identifier, src = src, gang = gang.name, model = entry.model, label = entry.label, at = os.time() }
    GB.log(gang.name, xPlayer, 'prop_placed', entry.label)
    cb({ ok = true, count = totalCount(xPlayer.identifier), limit = limit })
end)

ESX.RegisterServerCallback('gangbuilder:props:remove', function(src, cb, pid)
    local gang, grade, xPlayer = allowed(src)
    if not gang then return cb(fail('Props non disponibles')) end
    local p = Props[tonumber(pid)]
    if not p then return cb(fail('Prop introuvable')) end
    -- le propriétaire, ou le bureau du gang (grade boss) pour les props de son gang
    if p.owner ~= xPlayer.identifier and not (p.gang == gang.name and grade >= (gang.boss_grade or 99)) then return cb(fail('Ce prop ne t\'appartient pas')) end
    removeProp(p.id)
    cb({ ok = true })
end)

ESX.RegisterServerCallback('gangbuilder:props:removeAll', function(src, cb)
    local gang, _, xPlayer = allowed(src)
    if not gang then return cb(fail('Props non disponibles')) end
    removeOf(xPlayer.identifier)
    cb({ ok = true })
end)

AddEventHandler('playerDropped', function()
    local src = source
    lastPlace[src] = nil
    if P.RemoveOnDisconnect then
        for id, p in pairs(Props) do if p.src == src then removeProp(id) end end
    end
end)

-- Durée de vie
CreateThread(function()
    while true do
        Wait(30000)
        if (P.Lifetime or 0) > 0 then
            local now = os.time()
            for id, p in pairs(Props) do if now - p.at > P.Lifetime * 60 or not DoesEntityExist(p.ent) then removeProp(id) end end
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for id in pairs(Props) do removeProp(id) end
end)

exports('CountProps', function(identifier) return countOf(identifier) end)
exports('GetPropLimit', function(src) return (limitFor(tonumber(src))) end)
