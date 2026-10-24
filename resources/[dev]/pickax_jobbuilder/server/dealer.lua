-- ─────────────────────────────── Concession (jobs de type "dealer") ───────────────────────────────
-- Catalogue par concession, vente au client (offre acceptée à l'écran), achat en libre-service, essais routiers,
-- véhicules d'exposition, commission du vendeur, taxes gouvernementales. Les véhicules vendus sont écrits dans
-- ta table owned_vehicles (colonnes réglables dans Config.Dealer.Cols).

local D = Config.Dealer
local Offers, offerId = {}, 0
local Pending = {}     -- [src] = { [plate] = exp } livraisons en attente de propriétés véhicule
local Testing = {}     -- [src] = exp
math.randomseed(os.time())

local function fail(msg) return { ok = false, error = msg } end
local function now() return os.time() end
local function num(v, min, max, default)
    v = tonumber(v)
    if not v or v ~= v then return default end
    if v < min then v = min end
    if v > max then v = max end
    return v
end
local function str(v, max, default)
    if type(v) ~= 'string' then return default or '' end
    return (v:gsub('%c', '')):sub(1, max)
end

local VTYPES = { car = true, bike = true, boat = true, aircraft = true }

local function dealerJob(name)
    local j = JB.Jobs[name]
    return (j and j.type == 'dealer') and j or nil
end

local function ctx(src, needAdmin)
    local x = ESX.GetPlayerFromId(src)
    if not x then return nil, nil, 'Joueur introuvable' end
    local job = dealerJob(x.job.name)
    if not job then return nil, nil, 'Ton métier n\'est pas une concession' end
    local s = job.settings or {}
    if x.job.grade < (s.dealer_sell_grade or 0) then return nil, nil, 'Ton grade ne permet pas de gérer la concession' end
    if needAdmin and x.job.grade < (s.dealer_admin_grade or job.boss_grade) then return nil, nil, 'Réservé à la direction de la concession' end
    return x, job
end

local function playersClose(a, b)
    return #(GetEntityCoords(GetPlayerPed(a)) - GetEntityCoords(GetPlayerPed(b))) <= Config.TargetDistance + 2.0
end

-- ─────────────────────────────── owned_vehicles (colonnes configurables) ───────────────────────────────
local function ident(v) return type(v) == 'string' and v:match('^[%w_]+$') and v or nil end

local function ownedCount(identifier)
    local t, c = ident(D.Table), ident(D.Cols.owner)
    if not t or not c then return 0 end
    return MySQL.scalar.await(('SELECT COUNT(*) FROM `%s` WHERE `%s` = ?'):format(t, c), { identifier }) or 0
end

local function plateExists(plate)
    local t, c = ident(D.Table), ident(D.Cols.plate)
    if not t or not c then return false end
    return (MySQL.scalar.await(('SELECT COUNT(*) FROM `%s` WHERE `%s` = ?'):format(t, c), { plate }) or 0) > 0
end

local function generatePlate()
    for _ = 1, 30 do
        local l = {}
        for i = 1, 3 do l[i] = string.char(math.random(65, 90)) end
        local plate = table.concat(l) .. ('%05d'):format(math.random(0, 99999))
        if not plateExists(plate) then return plate end
    end
end

local function insertOwned(identifier, plate, vehJson, vtype, state, name)
    local t = ident(D.Table)
    if not t then return false end
    local map = { owner = identifier, plate = plate, vehicle = vehJson, type = vtype, state = state, name = name }
    local cols, vals, qs = {}, {}, {}
    for k, v in pairs(map) do
        local col = ident(D.Cols[k])
        if col then cols[#cols + 1] = '`' .. col .. '`' vals[#vals + 1] = v qs[#qs + 1] = '?' end
    end
    return MySQL.insert.await(('INSERT INTO `%s` (%s) VALUES (%s)'):format(t, table.concat(cols, ', '), table.concat(qs, ', ')), vals) ~= nil
end

-- ─────────────────────────────── Catalogue effectif ───────────────────────────────
-- Par défaut une concession vend TOUS les véhicules de ta table `vehicles` (filtrables par catégories, prix × marge).
-- jobbuilder_dealer_vehicles ne contient que des AJUSTEMENTS par concession (prix, stock, grade, masqué) ou des véhicules personnalisés.
local vehCache = { t = 0, list = nil }
local function tableVehicles()
    if vehCache.list and now() - vehCache.t < 60 then return vehCache.list end
    local ok, rows = pcall(function() return MySQL.query.await('SELECT name, model, price, category FROM vehicles') end)
    vehCache = { t = now(), list = (ok and rows) or {} }
    return vehCache.list
end

function JB.dealerCatalog(job)
    local s = job.settings or {}
    local markup = (tonumber(s.dealer_markup) or 100) / 100
    local allow
    if type(s.dealer_categories) == 'table' and #s.dealer_categories > 0 then
        allow = {}
        for _, c in ipairs(s.dealer_categories) do allow[tostring(c):lower()] = true end
    end
    local byModel = {}
    for _, o in ipairs(MySQL.query.await('SELECT id, model, label, category, vtype, price, stock, min_grade, enabled FROM jobbuilder_dealer_vehicles WHERE job_name = ?', { job.name }) or {}) do
        o.enabled = JB.flag(o.enabled)
        byModel[o.model:lower()] = o
    end
    local list, seen, inTable = {}, {}, {}
    if s.dealer_auto ~= false then
        for _, v in ipairs(tableVehicles()) do
            local cat = v.category or ''
            inTable[tostring(v.model):lower()] = true
            if not allow or allow[cat:lower()] then
                local key = tostring(v.model):lower()
                local o = byModel[key]
                if o then
                    list[#list + 1] = { model = v.model, label = o.label, category = o.category, vtype = o.vtype, price = o.price, stock = o.stock, min_grade = o.min_grade, enabled = o.enabled, src = 'override' }
                else
                    list[#list + 1] = { model = v.model, label = v.name, category = cat, vtype = D.CategoryTypes[cat] or 'car', price = math.floor(v.price * markup), stock = -1, min_grade = 0, enabled = true, src = 'table' }
                end
                seen[key] = true
            end
        end
    end
    for key, o in pairs(byModel) do
        -- un véhicule de la table exclu par le filtre de catégories reste exclu ; seuls les véhicules personnalisés (hors table) s'ajoutent
        if not seen[key] and not inTable[key] then
            list[#list + 1] = { model = o.model, label = o.label, category = o.category, vtype = o.vtype, price = o.price, stock = o.stock, min_grade = o.min_grade, enabled = o.enabled, src = 'custom' }
        end
    end
    table.sort(list, function(a, b)
        if a.category ~= b.category then return a.category < b.category end
        return a.label:lower() < b.label:lower()
    end)
    return list
end

function JB.dealerFind(job, model)
    model = tostring(model or ''):lower()
    for _, v in ipairs(JB.dealerCatalog(job)) do
        if tostring(v.model):lower() == model then return v end
    end
end

local function categoryList()
    local labels = {}
    local okL, rows = pcall(function() return MySQL.query.await('SELECT name, label FROM vehicle_categories') end)
    if okL and rows then for _, r in ipairs(rows) do labels[r.name] = r.label end end
    local seen, out = {}, {}
    for _, v in ipairs(tableVehicles()) do
        local c = v.category or ''
        if c ~= '' and not seen[c] then seen[c] = true out[#out + 1] = { name = c, label = labels[c] or c } end
    end
    table.sort(out, function(a, b) return a.label:lower() < b.label:lower() end)
    return out
end
JB.vehicleCategories = categoryList

-- ─────────────────────────────── Données du panel ───────────────────────────────
local function panelData(x, job)
    local s = job.settings or {}
    local adminG = s.dealer_admin_grade or job.boss_grade
    local admin = x.job.grade >= adminG
    local st = MySQL.single.await("SELECT COUNT(*) AS c, COALESCE(SUM(price),0) AS revenue, COALESCE(SUM(commission),0) AS commission, COALESCE(SUM(tax),0) AS tax FROM jobbuilder_dealer_sales WHERE job_name = ? AND created_at > (NOW() - INTERVAL 30 DAY)", { job.name }) or {}
    local cat = JB.dealerCatalog(job)
    local enabled, adjusted = 0, 0
    for _, v in ipairs(cat) do
        if v.enabled then enabled = enabled + 1 end
        if v.src ~= 'table' then adjusted = adjusted + 1 end
    end
    local sales = MySQL.query.await('SELECT model, label, plate, buyer_name, seller_name, price, commission, tax, UNIX_TIMESTAMP(created_at) AS t FROM jobbuilder_dealer_sales WHERE job_name = ? ORDER BY id DESC LIMIT 40', { job.name }) or {}
    return {
        ok = true, job = job.name, jobLabel = job.label, agent = JB.playerName(x), gradeLabel = x.job.grade_label, admin = admin,
        commission = s.dealer_commission or D.DefaultCommission, selfService = s.dealer_self_service == true, maxGrade = #job.grades - 1, grades = job.grades,
        auto = s.dealer_auto ~= false, markup = tonumber(s.dealer_markup) or 100, restricted = s.dealer_categories or {},
        catalog = cat, categories = categoryList(), sales = sales,
        stats = { vehicles = #cat, enabled = enabled, adjusted = adjusted, sales = st.c or 0, revenue = st.revenue or 0, commission = st.commission or 0, tax = st.tax or 0 },
    }
end

ESX.RegisterServerCallback('jobbuilder:dealer:manage', function(src, cb)
    local x, job, err = ctx(src)
    if not x then return cb(fail(err)) end
    cb(panelData(x, job))
end)

-- payload = { rows = { ajustements... }, reset = { modèles à remettre au prix de la table } }
ESX.RegisterServerCallback('jobbuilder:dealer:saveCatalog', function(src, cb, payload)
    local x, job, err = ctx(src, true)
    if not x then return cb(fail(err)) end
    local rows = type(payload) == 'table' and type(payload.rows) == 'table' and payload.rows or {}
    local resets = type(payload) == 'table' and type(payload.reset) == 'table' and payload.reset or {}
    if #rows > 500 or #resets > 2000 then return cb(fail('Trop de modifications d\'un coup (500 max)')) end

    local existing = {}
    for _, o in ipairs(MySQL.query.await('SELECT id, model FROM jobbuilder_dealer_vehicles WHERE job_name = ?', { job.name }) or {}) do
        local k = o.model:lower()
        existing[k] = existing[k] or {}
        table.insert(existing[k], o.id)
    end
    local q, touched = {}, {}
    for _, v in ipairs(rows) do
        local model = str(v.model, 40):lower()
        if not model:match('^[%w_]+$') then return cb(fail('Modèle de véhicule invalide : « ' .. model .. ' »')) end
        local r = {
            label = str(v.label, 80, model), category = str(v.category, 40), vtype = VTYPES[v.vtype] and v.vtype or 'car',
            price = math.floor(num(v.price, 0, 1000000000, 0)), stock = math.floor(num(v.stock, -1, 9999, -1)),
            min_grade = math.floor(num(v.min_grade, 0, #job.grades - 1, 0)), enabled = v.enabled == false and 0 or 1,
        }
        if r.label == '' then r.label = model end
        local ids = existing[model]
        if ids and #ids > 0 then
            q[#q + 1] = { query = 'UPDATE jobbuilder_dealer_vehicles SET label = ?, category = ?, vtype = ?, price = ?, stock = ?, min_grade = ?, enabled = ? WHERE id = ? AND job_name = ?',
                values = { r.label, r.category, r.vtype, r.price, r.stock, r.min_grade, r.enabled, ids[1], job.name } }
            for i = 2, #ids do q[#q + 1] = { query = 'DELETE FROM jobbuilder_dealer_vehicles WHERE id = ? AND job_name = ?', values = { ids[i], job.name } } end
        else
            q[#q + 1] = { query = 'INSERT INTO jobbuilder_dealer_vehicles (job_name, model, label, category, vtype, price, stock, min_grade, enabled) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
                values = { job.name, model, r.label, r.category, r.vtype, r.price, r.stock, r.min_grade, r.enabled } }
        end
        touched[model] = true
    end
    for _, m in ipairs(resets) do
        m = str(tostring(m), 40):lower()
        if m:match('^[%w_]+$') and not touched[m] then
            q[#q + 1] = { query = 'DELETE FROM jobbuilder_dealer_vehicles WHERE job_name = ? AND LOWER(model) = ?', values = { job.name, m } }
        end
    end
    if #q > 0 and not MySQL.transaction.await(q) then return cb(fail('Erreur SQL : catalogue non enregistré')) end
    JB.log(job.name, x, 'catalog_saved', ('%d ajustement(s), %d remise(s) à zéro'):format(#rows, #resets))
    cb(panelData(x, job))
end)

-- ─────────────────────────────── Showroom (lecture publique) ───────────────────────────────
function JB.openShowroom(src, x, point, job, cb)
    local s = job.settings or {}
    local staff = x.job.name == job.name
    local list = {}
    for _, v in ipairs(JB.dealerCatalog(job)) do
        if v.enabled and v.stock ~= 0 then
            list[#list + 1] = { model = v.model, label = v.label, category = v.category, price = v.price, stock = v.stock, min_grade = v.min_grade }
        end
    end
    local hasTest = false
    for _, p in pairs(JB.Points) do if p.job_name == job.name and p.type == 'testdrive' then hasTest = true end end
    cb({
        ok = true, kind = 'showroom', label = point.label, jobLabel = job.label, vehicles = list, categories = categoryList(),
        canSell = staff and x.job.grade >= (s.dealer_sell_grade or 0), grade = staff and x.job.grade or -1,
        selfService = s.dealer_self_service == true, hasTest = hasTest, focus = point.type == 'display' and point.data.model or nil,
    })
end

local function showroomPoint(src, pointId)
    local p = JB.Points[tonumber(pointId)]
    if not p or (p.type ~= 'showroom' and p.type ~= 'display') then return nil, 'Point introuvable' end
    if JB.distanceTo(src, p.coords) > Config.ServerDistance + 4.0 then return nil, 'Tu es trop loin' end
    return p, dealerJob(p.job_name)
end

-- ─────────────────────────────── Vente ───────────────────────────────
local function completeSale(job, v, buyer, seller)
    local s = job.settings or {}
    if not v.enabled or v.stock == 0 then return false, 'Ce véhicule n\'est plus disponible' end
    if D.MaxVehiclesPerPlayer > 0 and ownedCount(buyer.identifier) >= D.MaxVehiclesPerPlayer then
        return false, ('Tu possèdes déjà %d véhicules (maximum)'):format(D.MaxVehiclesPerPlayer)
    end
    local plate = generatePlate()
    if not plate then return false, 'Impossible de générer une plaque' end

    local spawnPoint
    if D.Delivery == 'spawn' then
        for _, p in pairs(JB.Points) do
            if p.job_name == job.name and p.type == 'showroom' and p.data.spawn then spawnPoint = p.data.spawn break end
        end
    end
    local delivered = spawnPoint ~= nil

    -- On inscrit le véhicule AVANT de débiter : si l'insertion échoue, personne n'est facturé ; si le paiement échoue, on retire la ligne
    local vehJson = json.encode({ model = GetHashKey(v.model), plate = plate })
    if not insertOwned(buyer.identifier, plate, vehJson, v.vtype, delivered and D.StateOut or D.StateStored, v.label) then
        return false, 'Erreur base de données (table owned_vehicles / colonnes ?) : vente annulée'
    end
    if not JB.pay(buyer, v.price) then
        local t, cp, co = ident(D.Table), ident(D.Cols.plate), ident(D.Cols.owner)
        MySQL.update.await(('DELETE FROM `%s` WHERE `%s` = ? AND `%s` = ?'):format(t, cp, co), { plate, buyer.identifier })
        return false, 'Pas assez d\'argent'
    end

    local tax = JB.applyTax and JB.applyTax('dealer', v.price, job.name) or 0
    local net = v.price - tax
    local pct = s.dealer_commission or D.DefaultCommission
    local commission = (seller and seller.job.name == job.name) and math.floor(net * pct / 100) or 0
    if job.society then
        JB.societyAdd(job.name, net - commission)
    elseif seller then
        commission = commission + (net - commission)
    end
    if seller and commission > 0 then
        seller.addAccountMoney('bank', commission)
        JBNotifyClient( seller.source, ('Vente conclue ! Commission : ~g~+%d$'):format(commission))
    end
    if v.stock > 0 then MySQL.update.await('UPDATE jobbuilder_dealer_vehicles SET stock = stock - 1 WHERE job_name = ? AND LOWER(model) = ? AND stock > 0', { job.name, tostring(v.model):lower() }) end

    MySQL.insert('INSERT INTO jobbuilder_dealer_sales (job_name, model, label, plate, buyer, buyer_name, seller_name, price, commission, tax) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        { job.name, v.model, v.label, plate, buyer.identifier, JB.playerName(buyer), seller and JB.playerName(seller) or 'libre-service', v.price, commission, tax })
    JB.log(job.name, seller or buyer, 'vehicle_sold', ('%s (%s) → %s : %d$'):format(v.label, plate, JB.playerName(buyer), v.price))

    if delivered then
        Pending[buyer.source] = Pending[buyer.source] or {}
        Pending[buyer.source][plate] = now() + 240
        TriggerClientEvent('jobbuilder:client:dealerDeliver', buyer.source, { model = v.model, plate = plate, spawn = spawnPoint, label = v.label })
    else
        JBNotifyClient( buyer.source, ('~g~%s~s~ (%s) t\'attend dans ton garage.'):format(v.label, plate))
    end
    return true
end

local function vehRow(model, jobName)
    local job = dealerJob(jobName)
    return job and JB.dealerFind(job, model) or nil
end

-- Offre de vente d'un véhicule à un client (le plus proche) ou à soi-même (`self` : le vendeur est aussi l'acheteur, même confirmation et même paiement)
local function dealerOffer(src, cb, vehId, targetId, self)
    local x, job, err = ctx(src)
    if not x then return cb(fail(err)) end
    local v = vehRow(vehId, job.name)
    if not v or not v.enabled or v.stock == 0 then return cb(fail('Véhicule indisponible')) end
    if x.job.grade < v.min_grade then return cb(fail('Ton grade ne permet pas de vendre ce véhicule')) end
    local t = self and x or ESX.GetPlayerFromId(tonumber(targetId))
    if not t or (not self and t.source == src) then return cb(fail('Aucun client à proximité')) end
    if not self and not playersClose(src, t.source) then return cb(fail('Le client est trop loin')) end
    offerId = offerId + 1
    Offers[offerId] = { from = src, to = t.source, veh = v.model, job = job.name, exp = now() + 90 }
    TriggerClientEvent('jobbuilder:client:dealerOffer', t.source, offerId, { label = v.label, model = v.model, category = v.category, price = v.price, jobLabel = job.label })
    cb({ ok = true })
end

ESX.RegisterServerCallback('jobbuilder:dealer:offer', function(src, cb, vehId, targetId) dealerOffer(src, cb, vehId, targetId, false) end)
ESX.RegisterServerCallback('jobbuilder:dealer:offerSelf', function(src, cb, vehId) dealerOffer(src, cb, vehId, nil, true) end)

RegisterNetEvent('jobbuilder:server:dealerAnswer', function(id, yes)
    local src = source
    local o = Offers[id]
    if not o or o.to ~= src then return end
    Offers[id] = nil
    local seller = ESX.GetPlayerFromId(o.from)
    if o.exp < now() then return end
    if not yes then
        if seller then JBNotifyClient( o.from, '~r~Le client a refusé l\'offre.') end
        return
    end
    local buyer, job = ESX.GetPlayerFromId(src), dealerJob(o.job)
    local v = job and vehRow(o.veh, o.job)
    if not buyer or not v then return end
    local ok, e = completeSale(job, v, buyer, seller)
    if not ok then
        JBNotifyClient( src, '~r~' .. e)
        if seller then JBNotifyClient( o.from, '~r~' .. e) end
    end
end)

ESX.RegisterServerCallback('jobbuilder:dealer:buy', function(src, cb, pointId, vehId)
    local p, job = showroomPoint(src, pointId)
    if not p then return cb(fail(job)) end
    if not job or job.settings.dealer_self_service ~= true then return cb(fail('Cette concession ne propose pas le libre-service : demande à un vendeur')) end
    local buyer = ESX.GetPlayerFromId(src)
    local v = vehRow(vehId, job.name)
    if not buyer or not v then return cb(fail('Véhicule introuvable')) end
    local ok, e = completeSale(job, v, buyer, nil)
    if not ok then return cb(fail(e)) end
    cb({ ok = true })
end)

-- Le client envoie les propriétés réelles du véhicule livré (couleur, mods...) : accepté une seule fois, uniquement pour une livraison en cours
RegisterNetEvent('jobbuilder:server:dealerProps', function(plate, props)
    local src = source
    local pend = Pending[src]
    if not pend or not pend[plate] or pend[plate] < now() or type(props) ~= 'table' then return end
    pend[plate] = nil
    local x = ESX.GetPlayerFromId(src)
    local t, cv, cp, co = ident(D.Table), ident(D.Cols.vehicle), ident(D.Cols.plate), ident(D.Cols.owner)
    if not x or not t or not cv or not cp or not co then return end
    props.plate = plate
    local encoded = json.encode(props)
    if #encoded > 30000 then return end
    MySQL.update(('UPDATE `%s` SET `%s` = ? WHERE `%s` = ? AND `%s` = ?'):format(t, cv, cp, co), { encoded, plate, x.identifier })
end)

-- ─────────────────────────────── Essai routier ───────────────────────────────
ESX.RegisterServerCallback('jobbuilder:dealer:test', function(src, cb, pointId, vehId)
    local p, job = showroomPoint(src, pointId)
    if not p then return cb(fail(job)) end
    if not job then return cb(fail('Concession introuvable')) end
    if (Testing[src] or 0) > now() then return cb(fail('Tu as déjà un essai en cours')) end
    local td
    for _, q in pairs(JB.Points) do if q.job_name == job.name and q.type == 'testdrive' then td = q break end end
    if not td then return cb(fail('Cette concession n\'a pas de point d\'essai routier')) end
    local v = vehRow(vehId, job.name)
    if not v or not v.enabled then return cb(fail('Véhicule indisponible')) end
    local seconds = td.data.seconds or D.TestSeconds
    Testing[src] = now() + seconds + 15
    cb({ ok = true, model = v.model, label = v.label, plate = 'ESSAI' .. math.random(10, 99), spawn = td.data.spawn, seconds = seconds })
end)

RegisterNetEvent('jobbuilder:server:testEnd', function() Testing[source] = nil end)
AddEventHandler('playerDropped', function() Testing[source], Pending[source] = nil, nil end)
