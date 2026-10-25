-- ─────────────────────────────── Restaurant / bar : récolte → cuisine → vente ───────────────────────────────
-- Récolte : un point donne un objet brut (tomates, viande…).  Cuisine : une recette transforme des ingrédients en produit fini.
-- Frigo : un point « Coffre » du job.  Vente : F6 → « Vendre un produit » (carte du job), le client paie directement.
-- Anti-triche : chaque travail est « démarré » (tout est vérifié) puis « terminé » (durée respectée, tout revérifié).

local K = Config.Kitchen
local function fail(msg) return { ok = false, error = msg } end

-- ─────────────────────────────── Inventaire (ox_inventory ou ESX) ───────────────────────────────
function JB.itemCount(src, xPlayer, name)
    if JB.inventory() == 'ox' then return exports.ox_inventory:GetItemCount(src, name) or 0 end
    local it = xPlayer.getInventoryItem(name)
    return it and it.count or 0
end

function JB.canCarry(src, xPlayer, name, count)
    if JB.inventory() == 'ox' then return exports.ox_inventory:CanCarryItem(src, name, count) and true or false end
    return xPlayer.canCarryItem(name, count)
end

function JB.giveItem(src, xPlayer, name, count)
    if JB.inventory() == 'ox' then return exports.ox_inventory:AddItem(src, name, count) and true or false end
    xPlayer.addInventoryItem(name, count)
    return true
end

function JB.takeItem(src, xPlayer, name, count)
    if JB.inventory() == 'ox' then return exports.ox_inventory:RemoveItem(src, name, count) and true or false end
    if (xPlayer.getInventoryItem(name).count or 0) < count then return false end
    xPlayer.removeInventoryItem(name, count)
    return true
end

local function getPoint(src, pointId, ptype)
    local xPlayer = ESX.GetPlayerFromId(src)
    local point = JB.Points[tonumber(pointId)]
    if not xPlayer or not point or point.type ~= ptype then return nil, nil, 'Point introuvable' end
    if JB.distanceTo(src, point.coords) > Config.ServerDistance then return nil, nil, 'Tu es trop loin' end
    if xPlayer.job.name ~= point.job_name then return nil, nil, 'Ce point n\'appartient pas à ton métier' end
    if xPlayer.job.grade < point.min_grade then return nil, nil, 'Ton grade est insuffisant' end
    return point, xPlayer
end

-- ─────────────────────────────── Ouverture des points ───────────────────────────────
function JB.openKitchen(src, xPlayer, point, job, cb)
    local d = point.data
    if point.type == 'harvest' then
        return cb({ ok = true, kind = 'harvest', label = point.label, jobLabel = job.label, item = { name = d.name, label = d.label },
            count = d.count, seconds = d.seconds })
    end
    local list = {}
    for i, r in ipairs(d.recipes) do
        if xPlayer.job.grade >= r.min_grade then
            local inputs, can = {}, true
            for _, inp in ipairs(r.inputs) do
                local have = JB.itemCount(src, xPlayer, inp.name)
                inputs[#inputs + 1] = { label = inp.label, count = inp.count, have = have }
                if have < inp.count then can = false end
            end
            list[#list + 1] = { idx = i, label = r.label, seconds = r.seconds, output = r.output, inputs = inputs, can = can }
        end
    end
    cb({ ok = true, kind = 'kitchen', label = point.label, jobLabel = job.label, recipes = list, maxBatch = K.MaxBatch })
end

-- ─────────────────────────────── Travail : démarrage / fin ───────────────────────────────
local pending = {}   -- [src] = { pointId, kind, idx, qty, ready, expires }

AddEventHandler('playerDropped', function() pending[source] = nil end)

ESX.RegisterServerCallback('jobbuilder:kitchen:begin', function(src, cb, pointId, idx, qty)
    pending[src] = nil
    local point = JB.Points[tonumber(pointId)]
    if not point or (point.type ~= 'harvest' and point.type ~= 'kitchen') then return cb(fail('Point introuvable')) end
    local point2, xPlayer, err = getPoint(src, pointId, point.type)
    if not point2 then return cb(fail(err)) end
    local d = point.data

    if point.type == 'harvest' then
        if not JB.canCarry(src, xPlayer, d.name, d.count) then return cb(fail('Tu ne peux pas porter plus de ' .. d.label)) end
        pending[src] = { pointId = point.id, kind = 'harvest', ready = GetGameTimer() + math.floor(d.seconds * 1000 * K.Grace), expires = GetGameTimer() + d.seconds * 1000 + 60000 }
        return cb({ ok = true, kind = 'harvest', seconds = d.seconds, label = ('Récolte : %d× %s'):format(d.count, d.label) })
    end

    local r = d.recipes[tonumber(idx) or 0]
    qty = math.floor(tonumber(qty) or 1)
    if not r or xPlayer.job.grade < r.min_grade then return cb(fail('Recette indisponible')) end
    if qty < 1 or qty > K.MaxBatch then return cb(fail('Quantité invalide')) end
    for _, inp in ipairs(r.inputs) do
        if JB.itemCount(src, xPlayer, inp.name) < inp.count * qty then
            return cb(fail(('Il te manque des ingrédients : %d× %s'):format(inp.count * qty, inp.label)))
        end
    end
    if not JB.canCarry(src, xPlayer, r.output.name, r.output.count * qty) then return cb(fail('Tu ne peux pas porter autant de ' .. r.output.label)) end
    local total = r.seconds * qty
    pending[src] = { pointId = point.id, kind = 'kitchen', idx = tonumber(idx), qty = qty, ready = GetGameTimer() + math.floor(total * 1000 * K.Grace), expires = GetGameTimer() + total * 1000 + 60000 }
    cb({ ok = true, kind = 'kitchen', seconds = total, label = ('%s ×%d'):format(r.label, qty) })
end)

ESX.RegisterServerCallback('jobbuilder:kitchen:finish', function(src, cb)
    local job = pending[src]
    pending[src] = nil
    if not job or GetGameTimer() > job.expires then return cb(fail('Aucun travail en cours')) end
    if GetGameTimer() < job.ready then return cb(fail('Tu as été trop rapide')) end
    local point, xPlayer, err = getPoint(src, job.pointId, job.kind)
    if not point then return cb(fail(err)) end
    local d = point.data

    if job.kind == 'harvest' then
        if not JB.canCarry(src, xPlayer, d.name, d.count) then return cb(fail('Tu ne peux plus porter ça')) end
        JB.giveItem(src, xPlayer, d.name, d.count)
        JB.log(point.job_name, xPlayer, 'harvest', ('%d× %s'):format(d.count, d.label))
        return cb({ ok = true, msg = ('~g~+%d× %s'):format(d.count, d.label) })
    end

    local r = d.recipes[job.idx]
    if not r or xPlayer.job.grade < r.min_grade then return cb(fail('Recette indisponible')) end
    for _, inp in ipairs(r.inputs) do
        if JB.itemCount(src, xPlayer, inp.name) < inp.count * job.qty then return cb(fail('Il te manque des ingrédients')) end
    end
    local out = r.output.count * job.qty
    if not JB.canCarry(src, xPlayer, r.output.name, out) then return cb(fail('Tu ne peux pas porter autant')) end
    local taken = {}
    for _, inp in ipairs(r.inputs) do
        if JB.takeItem(src, xPlayer, inp.name, inp.count * job.qty) then
            taken[#taken + 1] = inp
        else
            for _, t in ipairs(taken) do JB.giveItem(src, xPlayer, t.name, t.count * job.qty) end    -- rollback
            return cb(fail('Il te manque des ingrédients'))
        end
    end
    JB.giveItem(src, xPlayer, r.output.name, out)
    JB.log(point.job_name, xPlayer, 'cook', ('%d× %s'):format(out, r.output.label))
    cb({ ok = true, msg = ('~g~+%d× %s'):format(out, r.output.label) })
end)

RegisterNetEvent('jobbuilder:kitchen:cancel', function() pending[source] = nil end)

-- ─────────────────────────────── Vente directe au client ───────────────────────────────
ESX.RegisterServerCallback('jobbuilder:serve:menu', function(src, cb)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not JB.jobHasAction(xPlayer, 'serve') then return cb(fail('Action non autorisée')) end
    local job = JB.Jobs[xPlayer.job.name]
    local items = {}
    for i, it in ipairs(job.settings.menu or {}) do
        items[#items + 1] = { idx = i, name = it.name, label = it.label, price = it.price, have = JB.itemCount(src, xPlayer, it.name) }
    end
    cb({ ok = true, jobLabel = job.label, items = items, maxServe = K.MaxServe })
end)

-- (idx, cible, quantité) : la cible est injectée côté client (joueur le plus proche) ; `self` : l'employé se sert lui-même (même facture à payer)
local function serveOffer(src, cb, idx, targetId, qty, self)
    if not JB.rate(src, 'serve:offer', 8, 10) then return cb(fail(JB.RATE_MSG)) end
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not JB.jobHasAction(xPlayer, 'serve') then return cb(fail('Action non autorisée')) end
    local job = JB.Jobs[xPlayer.job.name]
    local it = (job.settings.menu or {})[tonumber(idx) or 0]
    qty = math.floor(tonumber(qty) or 1)
    if not it then return cb(fail('Produit inconnu')) end
    if qty < 1 or qty > K.MaxServe then return cb(fail('Quantité invalide')) end
    local target = self and xPlayer or ESX.GetPlayerFromId(tonumber(targetId))
    if not target or (not self and target.source == src) then return cb(fail('Aucun client à proximité')) end
    if not self and not JB.playersClose(src, target.source) then return cb(fail('Le client est trop loin')) end
    if JB.itemCount(src, xPlayer, it.name) < qty then return cb(fail(('Tu n\'as pas %d× %s sur toi'):format(qty, it.label))) end
    JB.sendInvoice(xPlayer, target, ('%d× %s'):format(qty, it.label), it.price * qty, { name = it.name, label = it.label, count = qty })
    cb({ ok = true })
end

ESX.RegisterServerCallback('jobbuilder:serve:offer', function(src, cb, idx, targetId, qty) serveOffer(src, cb, idx, targetId, qty, false) end)
ESX.RegisterServerCallback('jobbuilder:serve:offerSelf', function(src, cb, idx, qty) serveOffer(src, cb, idx, nil, qty, true) end)

