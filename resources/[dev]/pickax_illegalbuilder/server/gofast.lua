-- ─────────────────────────────── Go Fast : départ, véhicule, livraison ───────────────────────────────
-- Tout est contrôlé côté serveur : stock, policiers requis, délai, véhicule (créé par le serveur), distance de livraison et récompense.
local Runs = {}      -- [src] = { eid, drop (index du point), veh, plate, startAt, deadline }
local Stock = {}     -- [eid] = { n, at } : stock disponible, reconstitué avec le temps

-- Nom de l'item « tablette » exigé par ce module (nil si la tablette n'est pas activée)
function IB.gofastTabletItem(e)
    local t = e.type == 'gofast' and e.settings and e.settings.tablet
    if t and t.enabled then return (t.item and t.item ~= '') and t.item or 'gofast_tablet' end
    return nil
end

local function clamp(v, a, b) return math.max(a, math.min(b, v)) end

local function stockOf(e)
    local s = e.settings
    local st = Stock[e.id]
    local now = os.time()
    if not st then st = { n = s.stock, at = now } Stock[e.id] = st end
    st.n = math.min(st.n, s.stock)
    if st.n < s.stock then
        local gained = math.floor((now - st.at) / (math.max(1, s.regenMinutes) * 60))
        if gained > 0 then st.n = math.min(s.stock, st.n + gained) st.at = st.at + gained * math.max(1, s.regenMinutes) * 60 end
    else
        st.at = now
    end
    return st
end

local function points(e, kind)
    local out = {}
    for i, p in ipairs(e.points) do
        if p.kind == kind and p.coords and p.coords.x ~= nil then out[#out + 1] = { i = i, p = p } end
    end
    return out
end

local function resolve(src, eid, pi)
    local e = IB.Entities[tonumber(eid) or 0]
    local xPlayer = ESX.GetPlayerFromId(src)
    if not e or e.type ~= 'gofast' or not e.enabled or not xPlayer then return nil, 'Introuvable' end
    local p = e.points[tonumber(pi) or 0]
    if not p or p.kind ~= 'gfstart' or not p.coords or not IB.near(src, p.coords, 4.0) then return nil, 'Trop loin' end
    local ok, err = IB.hasAccess(xPlayer, p.access)
    if not ok then return nil, err end
    local tab = IB.gofastTabletItem(e)
    if tab and IB.itemCount(src, tab) < 1 then return nil, 'Il te faut la tablette Go Fast' end
    return e, p, xPlayer
end

local function cooldownLeft(e, xPlayer)
    local win = math.max(0, e.settings.cooldown or 0)
    if win == 0 then return 0 end
    local c = IB.counter(('gf:%s:%d'):format(xPlayer.identifier, e.id), win)
    if c.n > 0 then return math.max(0, win - (os.time() - c.since)) end
    return 0
end

local function endRun(src, reason, deleteVeh)
    local r = Runs[src]
    if not r then return end
    Runs[src] = nil
    if deleteVeh and r.veh and DoesEntityExist(r.veh) then DeleteEntity(r.veh) end
    TriggerClientEvent('illegalbuilder:client:gofastEnd', src, reason or '')
end

-- ═══════════════ Informations du contact (panneau) ═══════════════
ESX.RegisterServerCallback('illegalbuilder:gofast:info', function(src, cb, eid, pi)
    local e, p, xPlayer = resolve(src, eid, pi)
    if not e then return cb({ ok = false, error = p }) end
    local st = stockOf(e)
    local need = math.max(e.settings.copsRequired or 0, 0)
    cb({ ok = true, eid = e.id, pi = tonumber(pi), label = e.label, stock = st.n, stockMax = e.settings.stock, copsRequired = need, cops = IB.copCount(),
        cooldown = cooldownLeft(e, xPlayer), rewardMin = e.settings.rewardMin, rewardMax = e.settings.rewardMax, account = e.settings.account,
        bonus = e.settings.damageBonus and e.settings.bonusMax or 0, timeLimit = e.settings.timeLimit, running = Runs[src] ~= nil,
        ready = #points(e, 'gfspawn') > 0 and #points(e, 'gfdrop') > 0 })
end)

-- ═══════════════ Lancement ═══════════════
ESX.RegisterServerCallback('illegalbuilder:gofast:start', function(src, cb, eid, pi)
    if Runs[src] then return cb({ ok = false, error = 'Tu as déjà un Go Fast en cours' }) end
    local e, p, xPlayer = resolve(src, eid, pi)
    if not e then return cb({ ok = false, error = p }) end
    local s = e.settings
    if IB.copCount() < (s.copsRequired or 0) then return cb({ ok = false, error = 'Impossible pour le moment (pas assez de policiers en service)' }) end
    local left = cooldownLeft(e, xPlayer)
    if left > 0 then return cb({ ok = false, error = ('Reviens dans %d min'):format(math.ceil(left / 60)) }) end
    local st = stockOf(e)
    if st.n < 1 then return cb({ ok = false, error = 'Aucun Go Fast disponible, reviens plus tard' }) end
    local spawns, drops = points(e, 'gfspawn'), points(e, 'gfdrop')
    if #spawns == 0 or #drops == 0 then return cb({ ok = false, error = 'Go Fast mal configuré (sortie ou livraison manquante)' }) end
    if s.model == '' then return cb({ ok = false, error = 'Aucun véhicule configuré' }) end

    local sp = spawns[1].p.coords
    local veh = CreateVehicleServerSetter(joaat(s.model), 'automobile', sp.x, sp.y, sp.z, sp.h or 0.0)
    local t = GetGameTimer()
    while (not veh or veh == 0 or not DoesEntityExist(veh)) and GetGameTimer() - t < 2000 do Wait(50) end
    if not veh or veh == 0 or not DoesEntityExist(veh) then return cb({ ok = false, error = 'Impossible de créer le véhicule (modèle introuvable ?)' }) end
    local plate = (s.plate ~= '' and s.plate or 'GOFAST'):upper():sub(1, 8)
    SetVehicleNumberPlateText(veh, plate)

    local drop = drops[math.random(#drops)]
    st.n = st.n - 1
    IB.counter(('gf:%s:%d'):format(xPlayer.identifier, e.id), math.max(1, s.cooldown or 1)).n = 1
    Runs[src] = { eid = e.id, drop = drop.i, veh = veh, plate = plate, startAt = os.time(), deadline = os.time() + math.max(1, s.timeLimit) * 60 }
    IB.stat(e, 'started')
    IB.log(e, xPlayer, 'gf_start', plate)

    local a = s.alert or {}
    if (a.chance or 0) > 0 and math.random(100) <= a.chance then
        SetTimeout(math.max(0, (a.delay or 0)) * 1000, function()
            local r = Runs[src]
            if not r or r.veh ~= veh or not DoesEntityExist(veh) then return end
            local c = GetEntityCoords(veh)
            IB.alertPolice({ x = c.x, y = c.y, z = c.z }, a.label ~= '' and a.label or 'Go Fast suspecté', ('Un véhicule suspect (plaque %s) circule à grande vitesse'):format(plate))
        end)
    end

    cb({ ok = true, netId = NetworkGetNetworkIdFromEntity(veh), drop = { x = drop.p.coords.x, y = drop.p.coords.y, z = drop.p.coords.z }, radius = s.deliverRadius, plate = plate, minutes = s.timeLimit })
end)

-- ═══════════════ Livraison ═══════════════
RegisterNetEvent('illegalbuilder:server:gofastDeliver', function()
    local src = source
    local r = Runs[src]
    local xPlayer = ESX.GetPlayerFromId(src)
    if not r or not xPlayer then return end
    local e = IB.Entities[r.eid]
    if not e or not e.enabled then return endRun(src, 'Go Fast annulé', true) end
    local dp = e.points[r.drop]
    if not dp or not dp.coords then return endRun(src, 'Go Fast annulé', true) end
    if not r.veh or not DoesEntityExist(r.veh) then return endRun(src, 'Le véhicule du Go Fast a été détruit : mission échouée', false) end
    local radius = e.settings.deliverRadius or 8.0
    local vc = GetEntityCoords(r.veh)
    local dest = vector3(dp.coords.x, dp.coords.y, dp.coords.z)
    if #(vc - dest) > radius + 6.0 or not IB.near(src, dp.coords, radius) then return IB.notify(src, 'Tu es trop loin du point de livraison avec le véhicule.', 'error') end

    local s = e.settings
    local lo, hi = math.floor(s.rewardMin or 0), math.floor(s.rewardMax or 0)
    if hi < lo then hi = lo end
    local pay = math.random(lo, hi)
    local bonus = 0
    if s.damageBonus and (s.bonusMax or 0) > 0 then
        local health = tonumber(GetVehicleEngineHealth(r.veh)) or 1000.0
        bonus = math.floor(s.bonusMax * clamp((health - 250.0) / 750.0, 0.0, 1.0))
    end
    local total = pay + bonus
    DeleteEntity(r.veh)
    Runs[src] = nil
    IB.pay(xPlayer, s.account, total, 'Go Fast')
    IB.stat(e, 'delivered')
    IB.stat(e, 'earned', total)
    IB.log(e, xPlayer, 'gf_deliver', ('%d + bonus %d'):format(pay, bonus), total)
    TriggerClientEvent('illegalbuilder:client:gofastEnd', src, '', total, bonus)
end)

RegisterNetEvent('illegalbuilder:server:gofastAbandon', function()
    endRun(source, 'Go Fast abandonné', true)
end)

AddEventHandler('playerDropped', function() endRun(source, nil, true) end)

-- Délai maximum dépassé ou véhicule détruit
CreateThread(function()
    while true do
        Wait(5000)
        local now = os.time()
        for src, r in pairs(Runs) do
            if now >= r.deadline then
                endRun(src, 'Temps écoulé : le Go Fast est annulé', true)
            elseif not r.veh or not DoesEntityExist(r.veh) then
                endRun(src, 'Le véhicule du Go Fast a disparu : mission échouée', false)
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for src, r in pairs(Runs) do if r.veh and DoesEntityExist(r.veh) then DeleteEntity(r.veh) end end
end)
