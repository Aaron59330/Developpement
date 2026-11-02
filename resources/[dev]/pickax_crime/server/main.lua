-- ─────────────────────────────── Illégal : crochetage, piratage, faux papiers, désossage, recel ───────────────────────────────
-- Le client joue les mini-jeux ; le serveur valide matériel, distance, durée minimale, cooldowns, récompenses et alertes.
local ESX = exports['es_extended']:getSharedObject()
local C = Config
local Pending, Last, Cooldown = {}, {}, {}
local Chopped = {}   -- [plate] = { done = { partId = true } }

local function clamp(v, a, b) return math.max(a, math.min(b, v)) end
local function trim(s) return (tostring(s or ''):gsub('^%s+', ''):gsub('%s+$', '')) end
local function near(src, c, d) return #(GetEntityCoords(GetPlayerPed(src)) - c) <= d end
local function have(src, item) return (exports.ox_inventory:GetItemCount(src, item) or 0) end

local function alert(src, title, msg)
    if not C.Alert.Enabled or GetResourceState('pickax_jobbuilder') ~= 'started' then return end
    local c = GetEntityCoords(GetPlayerPed(src))
    pcall(function() exports.pickax_jobbuilder:SendDispatch(C.Alert.Target, title, msg or title, { x = c.x, y = c.y, z = c.z }, 'alert') end)
end

local function chance(p) return math.random(100) <= p end
local function notify(src, kind, txt) TriggerClientEvent('ox_lib:notify', src, { type = kind, description = txt }) end

-- ═══════════════ Crochetage ═══════════════
local function vehicleOf(src, netId, dist)
    local veh = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
    if not veh or veh == 0 or not DoesEntityExist(veh) or GetEntityType(veh) ~= 2 then return nil end
    if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(veh)) > (dist or C.Lockpick.Distance) + 3.0 then return nil end
    return veh
end

ESX.RegisterServerCallback('pickax_crime:lockBegin', function(src, cb, netId, class)
    local L = C.Lockpick
    if not C.Enabled or not ESX.GetPlayerFromId(src) then return cb({ ok = false }) end
    local veh = vehicleOf(src, netId)
    if not veh then return cb({ ok = false, error = 'Aucun véhicule à portée' }) end
    if have(src, L.Item) < 1 then return cb({ ok = false, error = 'Il te faut : ' .. L.Item }) end
    if Cooldown['l' .. src] and os.time() - Cooldown['l' .. src] < L.Cooldown then return cb({ ok = false, error = 'Patiente un peu avant de recommencer' }) end
    local dif = L.ClassDifficulty[tonumber(class) or 1] or 3
    if dif <= 0 then return cb({ ok = false, error = 'Ce véhicule ne peut pas être crocheté' }) end
    if GetVehicleDoorLockStatus(veh) <= 1 then return cb({ ok = false, error = 'Ce véhicule n\'est pas verrouillé' }) end
    Cooldown['l' .. src] = os.time()
    Pending[src] = { kind = 'lock', netId = tonumber(netId), at = GetGameTimer() }
    cb({ ok = true, cfg = { pins = 3 + math.floor(dif / 2), difficulty = dif, seconds = 24 + dif * 3, seed = math.random(1, 2147483000), title = 'Crochetage du véhicule' } })
end)

ESX.RegisterServerCallback('pickax_crime:lockEnd', function(src, cb, score)
    local p = Pending[src]
    Pending[src] = nil
    local L = C.Lockpick
    if not p or p.kind ~= 'lock' then return cb({ ok = false, error = 'Aucune tentative en cours' }) end
    if GetGameTimer() - p.at < 3000 then return cb({ ok = false, error = 'Trop rapide' }) end
    local veh = vehicleOf(src, p.netId)
    if not veh then return cb({ ok = false, error = 'Véhicule hors de portée' }) end
    score = clamp(math.floor(tonumber(score) or 0), 0, 100)
    if score >= L.Min then
        SetVehicleDoorsLocked(veh, 1)
        return cb({ ok = true, msg = 'Serrure crochetée : le véhicule est ouvert.' })
    end
    local broke = chance(L.BreakChance)
    if broke then exports.ox_inventory:RemoveItem(src, L.Item, 1) end
    if chance(L.AlertChance) then alert(src, 'Tentative d\'effraction', 'Une personne tente de forcer un véhicule') end
    cb({ ok = true, failed = true, msg = broke and 'Échec : le crochet s\'est cassé.' or 'Échec : la serrure résiste.' })
end)

-- ═════════════ Piratage de terminaux ═════════════
local function roll(a, b) return math.random(a, math.max(a, b)) end

ESX.RegisterServerCallback('pickax_crime:hackBegin', function(src, cb, idx)
    local H = C.Hack
    local t = H.Terminals[tonumber(idx) or 0]
    if not t or not ESX.GetPlayerFromId(src) or not near(src, t.coords, H.Distance + 3.0) then return cb({ ok = false, error = 'Trop loin' }) end
    if H.Item ~= '' and have(src, H.Item) < 1 then return cb({ ok = false, error = 'Il te faut : ' .. H.Item }) end
    local cd = Cooldown['h' .. idx]
    if cd and os.time() - cd < t.cooldown * 60 then return cb({ ok = false, error = 'Terminal verrouillé : reviens plus tard' }) end
    Pending[src] = { kind = 'hack', idx = tonumber(idx), at = GetGameTimer() }
    local cfg = { seed = math.random(1, 2147483000), title = t.label, seconds = 28 }
    if t.game == 'code' then cfg.length = t.length or 6 else cfg.wires = t.wires or 5 end
    cb({ ok = true, game = t.game, cfg = cfg })
end)

ESX.RegisterServerCallback('pickax_crime:hackEnd', function(src, cb, score)
    local p = Pending[src]
    Pending[src] = nil
    local x = ESX.GetPlayerFromId(src)
    if not p or p.kind ~= 'hack' or not x then return cb({ ok = false, error = 'Aucun piratage en cours' }) end
    if GetGameTimer() - p.at < 5000 then return cb({ ok = false, error = 'Trop rapide' }) end
    local t = C.Hack.Terminals[p.idx]
    score = clamp(math.floor(tonumber(score) or 0), 0, 100)
    Cooldown['h' .. p.idx] = os.time()
    if score < C.Hack.Min then
        alert(src, 'Intrusion informatique', t.alert or t.label)
        return cb({ ok = true, failed = true, msg = 'Accès refusé : une alerte a été déclenchée !' })
    end
    local msgs = {}
    if t.reward.money then local m = roll(t.reward.money[1], t.reward.money[2]) x.addAccountMoney('black_money', m) msgs[#msgs + 1] = ('%d $ (argent sale)'):format(m) end
    for _, it in ipairs(t.reward.items or {}) do local n = roll(it[2], it[3]) if exports.ox_inventory:CanCarryItem(src, it[1], n) then exports.ox_inventory:AddItem(src, it[1], n) msgs[#msgs + 1] = ('%d × %s'):format(n, it[1]) end end
    cb({ ok = true, msg = 'Piratage réussi : ' .. table.concat(msgs, ', ') })
end)

-- ═════════════ Faux papiers ═════════════
ESX.RegisterServerCallback('pickax_crime:forgeBegin', function(src, cb, idx)
    local F = C.Forgery
    local w = F.Workshops[tonumber(idx) or 0]
    if not w or not ESX.GetPlayerFromId(src) or not near(src, w.coords, F.Distance + 3.0) then return cb({ ok = false, error = 'Trop loin' }) end
    for _, n in ipairs(F.Needs) do if have(src, n[1]) < n[2] then return cb({ ok = false, error = ('Il te manque : %s ×%d'):format(n[1], n[2]) }) end end
    if not exports.ox_inventory:CanCarryItem(src, F.Item, 1) then return cb({ ok = false, error = 'Tu ne peux pas porter plus' }) end
    Pending[src] = { kind = 'forge', at = GetGameTimer() }
    cb({ ok = true, cfg = { seed = math.random(1, 2147483000), title = 'Contrefaçon de document', rounds = 3, seconds = F.Seconds } })
end)

ESX.RegisterServerCallback('pickax_crime:forgeEnd', function(src, cb, score, first, last)
    local p = Pending[src]
    Pending[src] = nil
    local F = C.Forgery
    if not p or p.kind ~= 'forge' then return cb({ ok = false, error = 'Aucune fabrication en cours' }) end
    if GetGameTimer() - p.at < 8000 then return cb({ ok = false, error = 'Trop rapide' }) end
    for _, n in ipairs(F.Needs) do if have(src, n[1]) < n[2] then return cb({ ok = false, error = 'Matériel manquant' }) end end
    first, last = trim(first):gsub('[^%w%s%-\']', ''):sub(1, 24), trim(last):gsub('[^%w%s%-\']', ''):sub(1, 24)
    if first == '' or last == '' then return cb({ ok = false, error = 'Nom invalide' }) end
    score = clamp(math.floor(tonumber(score) or 0), 0, 100)
    for _, n in ipairs(F.Needs) do exports.ox_inventory:RemoveItem(src, n[1], n[2]) end
    exports.ox_inventory:AddItem(src, F.Item, 1, { firstname = first, lastname = last, quality = score, label = ('Carte d\'identité — %s %s'):format(first, last), description = 'Document fabriqué.' })
    cb({ ok = true, msg = ('Document fabriqué (qualité %d %%).'):format(score) })
end)

-- ═════════════ Désossage ═════════════
local function owned(plate)
    local r = MySQL.scalar.await('SELECT 1 FROM owned_vehicles WHERE plate = ? LIMIT 1', { plate })
    return r ~= nil
end

local function inZone(src)
    local pc = GetEntityCoords(GetPlayerPed(src))
    for _, z in ipairs(C.Chop.Zones) do if #(pc - z.coords) <= z.radius then return true end end
    return false
end

ESX.RegisterServerCallback('pickax_crime:chopInfo', function(src, cb, netId)
    local K = C.Chop
    if not ESX.GetPlayerFromId(src) then return cb({ ok = false }) end
    if not inZone(src) then return cb({ ok = false, error = 'Il faut être dans la zone de désossage' }) end
    local veh = vehicleOf(src, netId, 8.0)
    if not veh then return cb({ ok = false, error = 'Aucun véhicule à portée' }) end
    local plate = trim(GetVehicleNumberPlateText(veh))
    if not K.AllowOwned and owned(plate) then return cb({ ok = false, error = 'Ce véhicule appartient à un citoyen : impossible' }) end
    local done = (Chopped[plate] or { done = {} }).done
    local parts = {}
    for _, p in ipairs(K.Parts) do parts[#parts + 1] = { id = p.id, label = p.label, done = done[p.id] == true } end
    cb({ ok = true, plate = plate, parts = parts })
end)

ESX.RegisterServerCallback('pickax_crime:chopBegin', function(src, cb, netId, partId)
    local K = C.Chop
    if not ESX.GetPlayerFromId(src) or not inZone(src) then return cb({ ok = false, error = 'Hors de la zone' }) end
    local veh = vehicleOf(src, netId, 8.0)
    local part
    for _, p in ipairs(K.Parts) do if p.id == partId then part = p end end
    if not veh or not part then return cb({ ok = false, error = 'Impossible' }) end
    local plate = trim(GetVehicleNumberPlateText(veh))
    if not K.AllowOwned and owned(plate) then return cb({ ok = false, error = 'Véhicule de citoyen : refusé' }) end
    if K.Tool ~= '' and have(src, K.Tool) < 1 then return cb({ ok = false, error = 'Il te faut : ' .. K.Tool }) end
    local ch = Chopped[plate]
    if ch and ch.done[part.id] then return cb({ ok = false, error = 'Cette pièce est déjà démontée' }) end
    if not exports.ox_inventory:CanCarryItem(src, part.item, 1) then return cb({ ok = false, error = 'Tu ne peux pas porter plus' }) end
    Pending[src] = { kind = 'chop', netId = tonumber(netId), part = part, plate = plate, at = GetGameTimer() }
    cb({ ok = true, cfg = { rounds = part.game.rounds, difficulty = part.game.difficulty, seconds = part.seconds, seed = math.random(1, 2147483000), title = 'Démontage : ' .. part.label } })
end)

ESX.RegisterServerCallback('pickax_crime:chopEnd', function(src, cb, score)
    local p = Pending[src]
    Pending[src] = nil
    local K = C.Chop
    if not p or p.kind ~= 'chop' then return cb({ ok = false, error = 'Aucun démontage en cours' }) end
    if GetGameTimer() - p.at < 4000 then return cb({ ok = false, error = 'Trop rapide' }) end
    local veh = vehicleOf(src, p.netId, 8.0)
    if not veh then return cb({ ok = false, error = 'Véhicule hors de portée' }) end
    score = clamp(math.floor(tonumber(score) or 0), 0, 100)
    if chance(K.AlertChance) then alert(src, 'Activité suspecte', 'Bruit de démontage de véhicule') end
    if score < K.Min then return cb({ ok = true, failed = true, msg = 'Démontage raté : la pièce est abîmée, réessaie.' }) end
    local ch = Chopped[p.plate] or { done = {}, n = 0 }
    Chopped[p.plate] = ch
    if ch.done[p.part.id] then return cb({ ok = false, error = 'Déjà démontée' }) end
    ch.done[p.part.id] = true
    ch.n = ch.n + 1
    exports.ox_inventory:AddItem(src, p.part.item, 1)
    local all = ch.n >= #K.Parts
    if all then DeleteEntity(veh) Chopped[p.plate] = nil end
    cb({ ok = true, msg = ('%s démontée.%s'):format(p.part.label, all and ' Véhicule entièrement désossé : l\'épave est évacuée.' or ''), done = all })
end)

-- Receleur
local function fencePrices()
    local day = tonumber(os.date('%j')) or 1
    local out = {}
    local i = 0
    for item, base in pairs(C.Chop.Fence.Prices) do
        i = i + 1
        local f = ((joaat(item .. ':' .. day) & 0xFFFF) / 0xFFFF * 2 - 1) * C.Chop.Fence.Fluctuation / 100
        out[item] = math.floor(base * (1 + f))
    end
    return out
end

ESX.RegisterServerCallback('pickax_crime:fenceList', function(src, cb)
    local F = C.Chop.Fence
    if not ESX.GetPlayerFromId(src) or not near(src, F.coords, F.Distance + 3.0) then return cb({ ok = false, error = 'Trop loin' }) end
    local pr, list = fencePrices(), {}
    for item, price in pairs(pr) do local n = have(src, item) if n > 0 then list[#list + 1] = { item = item, count = n, price = price } end end
    cb({ ok = true, list = list })
end)

ESX.RegisterServerCallback('pickax_crime:fenceSell', function(src, cb, item, qty)
    local F = C.Chop.Fence
    local x = ESX.GetPlayerFromId(src)
    if not x or not near(src, F.coords, F.Distance + 3.0) then return cb({ ok = false, error = 'Trop loin' }) end
    local pr = fencePrices()
    item = tostring(item or '')
    qty = clamp(math.floor(tonumber(qty) or 0), 1, 99)
    if not pr[item] or have(src, item) < qty then return cb({ ok = false, error = 'Rien à vendre' }) end
    exports.ox_inventory:RemoveItem(src, item, qty)
    local total = pr[item] * qty
    x.addAccountMoney(F.Account, total)
    cb({ ok = true, msg = ('%d × %s vendu(s) : %d $'):format(qty, item, total) })
end)

AddEventHandler('playerDropped', function() Pending[source] = nil end)
