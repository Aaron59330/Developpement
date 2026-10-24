-- ─────────────────────────────── Drogues (client) ───────────────────────────────
-- Tenue obligatoire -----------------------------------------------------------------
local COMP_NAME = { [1] = 'masque', [3] = 'torse', [4] = 'pantalon', [6] = 'chaussures', [7] = 'accessoire', [8] = 'haut', [9] = 'gilet', [11] = 'veste' }
local PROP_NAME = { [0] = 'chapeau', [1] = 'lunettes' }

local function pedSex()
    local m = GetEntityModel(PlayerPedId())
    if m == joaat('mp_m_freemode_01') then return 'male' end
    if m == joaat('mp_f_freemode_01') then return 'female' end
    return nil
end

-- true si le joueur porte la tenue exigée (def = { male = {...}, female = {...} }) ; sinon false + liste des pièces manquantes
local function outfitOK(def)
    if not def then return true end
    local sex = pedSex()
    if not sex then return false, { 'tenue compatible' } end
    local list = def[sex]
    if not list or #list == 0 then return true end
    local ped, missing = PlayerPedId(), {}
    for _, r in ipairs(list) do
        if r.k == 'p' then
            if GetPedPropIndex(ped, r.id) ~= r.d then missing[#missing + 1] = PROP_NAME[r.id] or ('accessoire ' .. r.id) end
        else
            if GetPedDrawableVariation(ped, r.id) ~= r.d then missing[#missing + 1] = COMP_NAME[r.id] or ('pièce ' .. r.id) end
        end
    end
    return #missing == 0, missing
end

local function checkOutfit(def)
    local ok, missing = outfitOK(def)
    if not ok then Notify('Tenue obligatoire : mets la bonne tenue (' .. table.concat(missing, ', ') .. ').', 'error') end
    return ok
end

-- Capture de la tenue portée (éditeur : bouton « Capturer ma tenue »)
NuiLocal.captureOutfit = function(_, cb)
    local sex = pedSex()
    if not sex then return cb({ ok = false, error = 'Il faut un personnage homme ou femme (mp_m_freemode_01 / mp_f_freemode_01)' }) end
    local ped, list = PlayerPedId(), {}
    for _, id in ipairs({ 1, 3, 4, 6, 7, 8, 9, 11 }) do
        local d = GetPedDrawableVariation(ped, id)
        if d ~= 0 then list[#list + 1] = { k = 'c', id = id, d = d } end
    end
    for _, id in ipairs({ 0, 1 }) do
        local d = GetPedPropIndex(ped, id)
        if d >= 0 then list[#list + 1] = { k = 'p', id = id, d = d } end
    end
    cb({ ok = true, sex = sex, list = list })
end

local function findPoint(eid, pi)
    for _, e in ipairs((State and State.entities) or {}) do
        if e.id == eid then for _, p in ipairs(e.points) do if p.i == pi then return p end end end
    end
end

local function timedAction(node, kind, recipeIdx, batches)
    ESX.TriggerServerCallback('illegalbuilder:drug:begin', function(res)
        if not res or not res.ok then return Notify((res and res.error) or 'Impossible', 'error') end
        CreateThread(function()
            local done = RunAction({ seconds = res.seconds, label = res.label, anim = res.anim })
            if done and node.outfit and not outfitOK(node.outfit) then done = false Notify('Tenue obligatoire retirée : action annulée.', 'error') end
            TriggerServerEvent('illegalbuilder:server:drugFinish', done)
            if not done then Notify('Action interrompue.', 'error') end
        end)
    end, node.eid, node.pi, kind, recipeIdx, batches)
end

local function openInfo(cbName, panel, node)
    ESX.TriggerServerCallback('illegalbuilder:drug:' .. cbName, function(res)
        if not res or not res.ok then return Notify((res and res.error) or 'Indisponible', 'error') end
        res.eid, res.pi = node.eid, node.pi
        OpenPanel(panel, res, { type = 'drug', eid = node.eid, pi = node.pi })
    end, node.eid, node.pi)
end

-- Plantation : parcelle vide → planter ; en pousse → pourcentage ; prête (100 %) → récolter
local function plantFlow(node)
    ESX.TriggerServerCallback('illegalbuilder:drug:plantState', function(r)
        if not r or not r.ok then return Notify((r and r.error) or 'Indisponible', 'error') end
        if r.state == 'empty' then
            if r.have < r.seedCount then return Notify(('Il te faut %d × %s pour planter.'):format(r.seedCount, r.seed), 'error') end
            return timedAction(node, 'plant')
        elseif r.state == 'growing' then
            return Notify(('La plante pousse : %d %% (prête dans %d min %02d s).'):format(r.pct, r.left // 60, r.left % 60), 'info')
        end
        return timedAction(node, 'harvest')
    end, node.eid, node.pi)
end

Handlers.drug = function(node)
    local k = node.kind
    if k == 'harvest' then
        if node.outfit and not checkOutfit(node.outfit) then return end
        if node.plant then return plantFlow(node) end
        return timedAction(node, 'harvest')
    end
    if k == 'process' then
        if node.outfit and not checkOutfit(node.outfit) then return end
        return openInfo('processInfo', 'lab', node)
    end
    if k == 'sell' then return openInfo('sellInfo', 'dealer', node) end
    if k == 'launder' then return openInfo('launderInfo', 'launder', node) end
    if k == 'door' or k == 'exit' then
        ESX.TriggerServerCallback('illegalbuilder:drug:door', function(res)
            if not res or not res.ok then return Notify((res and res.error) or 'Verrouillé', 'error') end
            Teleport(res.to)
        end, node.eid, node.pi, k == 'exit' and 'out' or 'in')
    end
end

-- Fabrication depuis le panneau du laboratoire
NuiLocal['lab:craft'] = function(args, cb)
    local ctx = Ctx
    if not ctx or ctx.type ~= 'drug' then return cb({ ok = false, error = 'Fermé' }) end
    local pt = findPoint(ctx.eid, ctx.pi)
    local node = { eid = ctx.eid, pi = ctx.pi, outfit = pt and pt.outfit }
    if node.outfit and not checkOutfit(node.outfit) then return cb({ ok = false, error = 'Tenue obligatoire' }) end
    ESX.TriggerServerCallback('illegalbuilder:drug:begin', function(res)
        if not res or not res.ok then return cb(res or { ok = false, error = 'Erreur' }) end
        cb({ ok = true })
        CloseUI()
        CreateThread(function()
            local done = RunAction({ seconds = res.seconds, label = res.label, anim = res.anim })
            TriggerServerEvent('illegalbuilder:server:drugFinish', done)
            if not done then Notify('Fabrication interrompue.', 'error') end
        end)
    end, node.eid, node.pi, 'process', args[1], args[2])
end
