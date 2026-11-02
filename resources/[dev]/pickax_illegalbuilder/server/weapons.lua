-- ─────────────────────────────── Atelier d'armes : fabrication + personnalisation ───────────────────────────────
-- Fabrication : recettes du module (settings.recipes), action chronométrée contrôlée par le serveur (ingrédients, distance, durée, chance de raté).
-- Personnalisation : accessoires (items « component » d'ox_inventory) et teintes de l'arme choisie. Tout est vérifié et appliqué par le serveur.
local function ox() return IB.inventory() == 'ox' end

local function item(name)
    local ok, it = pcall(function() return exports.ox_inventory:Items(name) end)
    return ok and it or nil
end

local function resolve(src, eid, pi)
    local e = IB.Entities[tonumber(eid) or 0]
    local xPlayer = ESX.GetPlayerFromId(src)
    if not e or e.type ~= 'weapon' or not e.enabled or not xPlayer then return nil, 'Introuvable' end
    local p = e.points[tonumber(pi) or 0]
    if not p or p.kind ~= 'bench' or not p.coords or not IB.near(src, p.coords, 4.0) then return nil, 'Trop loin' end
    local ok, err = IB.hasAccess(xPlayer, p.access)
    if not ok then return nil, err end
    local need = e.settings.copsRequired or 0
    if need > 0 and IB.copCount() < need then return nil, 'Impossible pour le moment (pas assez de policiers en service)' end
    return e, p, xPlayer
end

local function maybeAlert(e, p)
    local c = e.settings.alertChance or 0
    if c > 0 and math.random(100) <= c then
        IB.alertPolice(p.coords, 'Activité suspecte', ('Fabrication d\'armes suspectée (%s)'):format(p.label ~= '' and p.label or e.label))
    end
end

-- ═══════════════ Informations du panneau ═══════════════
local function recipesInfo(src, e)
    local list = {}
    for i, r in ipairs(e.settings.recipes or {}) do
        local max = 10
        local inputs = {}
        for _, inp in ipairs(r.inputs) do
            local have = IB.itemCount(src, inp.item)
            inputs[#inputs + 1] = { item = inp.item, count = inp.count, have = have }
            max = math.min(max, math.floor(have / math.max(1, inp.count)))
        end
        if r.tool and r.tool.item ~= '' and IB.itemCount(src, r.tool.item) < 1 then max = 0 end
        local it = r.outputs[1] and item(r.outputs[1].item)
        list[#list + 1] = { i = i, label = r.label ~= '' and r.label or 'Recette', time = r.time, failChance = r.failChance or 0, tool = (r.tool and r.tool.item ~= '') and r.tool.item or nil,
            inputs = inputs, outputs = r.outputs, max = max, weapon = it and it.weapon and true or false }
    end
    return list
end

local function customInfo(src, e)
    local c = e.settings.customize
    if not ox() or not c or not c.enabled then return nil end
    local weapons, attach, seen = {}, {}, {}
    for _, slot in pairs(exports.ox_inventory:GetInventoryItems(src) or {}) do
        local def = slot and slot.name and item(slot.name)
        if def and def.weapon then
            local comps = {}
            for _, n in ipairs((slot.metadata and slot.metadata.components) or {}) do
                local cd = item(n)
                comps[#comps + 1] = { name = n, label = cd and cd.label or n }
            end
            weapons[#weapons + 1] = { slot = slot.slot, name = slot.name, label = def.label or slot.name, serial = slot.metadata and slot.metadata.serial, tint = slot.metadata and slot.metadata.tint or 0, components = comps }
        elseif def and def.client and def.client.component then
            local a = seen[slot.name]
            if a then a.count = a.count + slot.count
            else
                a = { name = slot.name, label = def.label or slot.name, count = slot.count, type = def.type, hashes = def.client.component }
                seen[slot.name] = a
                attach[#attach + 1] = a
            end
        end
    end
    table.sort(weapons, function(a, b) return a.slot < b.slot end)
    table.sort(attach, function(a, b) return a.label < b.label end)
    return { attachPrice = c.attachPrice, tintPrice = c.tintPrice, account = c.account, weapons = weapons, attachments = attach }
end

local function fullInfo(src, e, p)
    return { ok = true, label = p.label ~= '' and p.label or e.label, recipes = recipesInfo(src, e), custom = customInfo(src, e) }
end

ESX.RegisterServerCallback('illegalbuilder:weapon:info', function(src, cb, eid, pi)
    local e, p = resolve(src, eid, pi)
    if not e then return cb({ ok = false, error = p }) end
    cb(fullInfo(src, e, p))
end)

-- ═══════════════ Fabrication ═══════════════
ESX.RegisterServerCallback('illegalbuilder:weapon:begin', function(src, cb, eid, pi, recipeIdx, batches)
    local e, p = resolve(src, eid, pi)
    if not e then return cb({ ok = false, error = p }) end
    local r = (e.settings.recipes or {})[tonumber(recipeIdx) or 0]
    if not r then return cb({ ok = false, error = 'Recette inconnue' }) end
    batches = math.max(1, math.min(10, math.floor(tonumber(batches) or 1)))
    if r.tool and r.tool.item ~= '' and IB.itemCount(src, r.tool.item) < 1 then return cb({ ok = false, error = 'Il te faut : ' .. r.tool.item }) end
    for _, inp in ipairs(r.inputs) do
        if IB.itemCount(src, inp.item) < inp.count * batches then return cb({ ok = false, error = ('Il te manque : %s ×%d'):format(inp.item, inp.count * batches) }) end
    end
    for _, out in ipairs(r.outputs) do
        if not IB.canCarry(src, out.item, out.count * batches) then return cb({ ok = false, error = 'Tu ne peux pas porter autant' }) end
    end
    local secs = r.time * batches
    IB.beginAct(src, { kind = 'weapon', eid = e.id, pi = tonumber(pi), recipe = tonumber(recipeIdx), batches = batches }, secs)
    cb({ ok = true, seconds = secs, anim = r.anim, label = r.label ~= '' and r.label or 'Fabrication' })
end)

RegisterNetEvent('illegalbuilder:server:weaponFinish', function(done)
    local src = source
    local a, err = IB.endAct(src, 'weapon')
    local xPlayer = ESX.GetPlayerFromId(src)
    local e = a and IB.Entities[a.eid]
    if not a or not e or not xPlayer then if err then IB.notify(src, err, 'error') end return end
    if done ~= true then return end
    local p = e.points[a.pi]
    if not p or not p.coords or not IB.near(src, p.coords, 6.0) then return end
    local r = (e.settings.recipes or {})[a.recipe]
    if not r then return end
    if r.tool and r.tool.item ~= '' and IB.itemCount(src, r.tool.item) < 1 then return IB.notify(src, 'Il te faut : ' .. r.tool.item, 'error') end
    for _, inp in ipairs(r.inputs) do
        if IB.itemCount(src, inp.item) < inp.count * a.batches then return IB.notify(src, 'Ingrédients manquants', 'error') end
    end
    for _, inp in ipairs(r.inputs) do IB.removeItem(src, inp.item, inp.count * a.batches) end
    if r.tool and r.tool.item ~= '' and r.tool.consume then IB.removeItem(src, r.tool.item, 1) end
    local made, failed = 0, 0
    for _ = 1, a.batches do
        if math.random(100) <= (r.failChance or 0) then failed = failed + 1
        else
            made = made + 1
            for _, out in ipairs(r.outputs) do IB.addItem(src, out.item, out.count) end
        end
    end
    maybeAlert(e, p)
    IB.stat(e, 'crafted', made)
    IB.log(e, xPlayer, 'process', ('%s ×%d (%d raté)'):format(r.label ~= '' and r.label or 'recette', made, failed), made)
    if failed > 0 then IB.notify(src, ('%d fabrication(s) ratée(s) : matériaux perdus.'):format(failed), 'error') end
    if made > 0 then IB.notify(src, ('Fabrication terminée : %d lot(s).'):format(made), 'success') end
end)

-- ═══════════════ Personnalisation ═══════════════
local function weaponSlot(src, slotId)
    local slot = exports.ox_inventory:GetSlot(src, tonumber(slotId) or 0)
    local def = slot and slot.name and item(slot.name)
    if not slot or not def or not def.weapon then return nil end
    return slot, def
end

-- Paiement du prix (0 = gratuit) : refuse si les fonds manquent
local function pay(xPlayer, e, price)
    price = math.floor(tonumber(price) or 0)
    if price <= 0 then return true end
    local acc = e.settings.customize.account
    local have = xPlayer.getAccount(acc)
    if not have or have.money < price then return false end
    xPlayer.removeAccountMoney(acc, price, 'Atelier d\'armes')
    return true
end

local function refund(xPlayer, e, price)
    price = math.floor(tonumber(price) or 0)
    if price > 0 then xPlayer.addAccountMoney(e.settings.customize.account, price, 'Atelier d\'armes (annulation)') end
end

local function custom(src, eid, pi, slotId)
    local e, p, xPlayer = resolve(src, eid, pi)
    if not e then return nil, p end
    local c = e.settings.customize
    if not ox() or not c or not c.enabled then return nil, 'La personnalisation est désactivée ici' end
    local slot, def = weaponSlot(src, slotId)
    if not slot then return nil, 'Arme introuvable' end
    return { e = e, p = p, x = xPlayer, slot = slot, def = def, c = c }
end

local function done(src, ctx, detail)
    TriggerClientEvent('ox_inventory:disarm', src, true)   -- l'arme est rangée : elle se rééquipera avec ses nouveaux accessoires
    IB.stat(ctx.e, 'customized', 1)
    IB.log(ctx.e, ctx.x, 'process', detail, 1)
    return fullInfo(src, ctx.e, ctx.p)
end

local MAX_COMPONENTS = 12

-- Poser un accessoire de l'inventaire (compatibilité vérifiée par le client : natives, puis le serveur contrôle le reste)
ESX.RegisterServerCallback('illegalbuilder:weapon:attach', function(src, cb, eid, pi, slotId, name)
    local ctx, err = custom(src, eid, pi, slotId)
    if not ctx then return cb({ ok = false, error = err }) end
    name = tostring(name or '')
    local def = item(name)
    if not def or not def.client or not def.client.component then return cb({ ok = false, error = 'Accessoire inconnu' }) end
    local md = ctx.slot.metadata or {}
    local comps = md.components or {}
    if #comps >= MAX_COMPONENTS then return cb({ ok = false, error = 'Trop d\'accessoires' }) end
    for _, n in ipairs(comps) do
        local cd = item(n)
        if n == name or (cd and def.type and cd.type == def.type) then return cb({ ok = false, error = 'Un accessoire de ce type est déjà posé' }) end
    end
    if IB.itemCount(src, name) < 1 then return cb({ ok = false, error = 'Tu n\'as pas cet accessoire' }) end
    if not pay(ctx.x, ctx.e, ctx.c.attachPrice) then return cb({ ok = false, error = 'Fonds insuffisants' }) end
    if not IB.removeItem(src, name, 1) then refund(ctx.x, ctx.e, ctx.c.attachPrice) return cb({ ok = false, error = 'Accessoire introuvable' }) end
    comps[#comps + 1] = name
    md.components = comps
    exports.ox_inventory:SetMetadata(src, ctx.slot.slot, md)
    cb(done(src, ctx, ('%s : +%s'):format(ctx.def.label or ctx.slot.name, def.label or name)))
end)

-- Retirer un accessoire (rendu dans l'inventaire)
ESX.RegisterServerCallback('illegalbuilder:weapon:detach', function(src, cb, eid, pi, slotId, index)
    local ctx, err = custom(src, eid, pi, slotId)
    if not ctx then return cb({ ok = false, error = err }) end
    local md = ctx.slot.metadata or {}
    local comps = md.components or {}
    index = math.floor(tonumber(index) or 0)
    local name = comps[index]
    if not name then return cb({ ok = false, error = 'Accessoire introuvable' }) end
    if not IB.canCarry(src, name, 1) then return cb({ ok = false, error = 'Tu ne peux pas porter cet accessoire' }) end
    table.remove(comps, index)
    md.components = comps
    exports.ox_inventory:SetMetadata(src, ctx.slot.slot, md)
    IB.addItem(src, name, 1)
    cb(done(src, ctx, ('%s : -%s'):format(ctx.def.label or ctx.slot.name, name)))
end)

-- Changer la teinte (0 = d'origine ; le nombre de teintes dépend de l'arme : 8 en général, 32 pour les Mk II)
ESX.RegisterServerCallback('illegalbuilder:weapon:tint', function(src, cb, eid, pi, slotId, tint)
    local ctx, err = custom(src, eid, pi, slotId)
    if not ctx then return cb({ ok = false, error = err }) end
    tint = math.floor(tonumber(tint) or -1)
    if tint < 0 or tint > 31 then return cb({ ok = false, error = 'Teinte invalide' }) end
    local md = ctx.slot.metadata or {}
    if (md.tint or 0) == tint then return cb({ ok = false, error = 'Cette teinte est déjà appliquée' }) end
    if not pay(ctx.x, ctx.e, ctx.c.tintPrice) then return cb({ ok = false, error = 'Fonds insuffisants' }) end
    md.tint = tint
    exports.ox_inventory:SetMetadata(src, ctx.slot.slot, md)
    cb(done(src, ctx, ('%s : teinte %d'):format(ctx.def.label or ctx.slot.name, tint)))
end)
