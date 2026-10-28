-- ─────────────────────────────── Perquisitions et saisies (police) ───────────────────────────────
-- Un policier inspecte un joueur proche puis saisit ses drogues et son argent sale. Les objets (avec leur pureté) vont dans le casier de preuves, l'argent sale est reversé
-- à la société de police. Tout est vérifié côté serveur : métier de police, distance, délai. Chaque saisie est enregistrée en base.

local lastSeize = {}   -- [policier] = GetGameTimer()
local STASH = 'ib_evidence'

local function S() return Config.Seizure end

CreateThread(function()
    Wait(2000)
    if MySQL and MySQL.query then
        pcall(MySQL.query.await, [[CREATE TABLE IF NOT EXISTS illegalbuilder_seizures (id INT AUTO_INCREMENT PRIMARY KEY, officer VARCHAR(80) NOT NULL, officer_name VARCHAR(100) NULL,
            target VARCHAR(80) NOT NULL, target_name VARCHAR(100) NULL, items TEXT NULL, black_money INT NOT NULL DEFAULT 0, created_at INT NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    end
    if S().Enabled and S().Evidence and GetResourceState('ox_inventory') == 'started' then
        pcall(function() exports.ox_inventory:RegisterStash(STASH, 'Casier de preuves', S().StashSlots or 200, S().StashWeight or 500000, false) end)
    end
end)

-- Objets illégaux : drogues du catalogue (récolte, pochon, graines) + Config.Seizure.Items
function IB.seizureItems()
    local list, seen = {}, {}
    local function add(n) if type(n) == 'string' and n ~= '' and not seen[n] then seen[n] = true list[#list + 1] = n end end
    for _, id in ipairs(Config.DrugOrder or {}) do
        local d = Config.Drugs[id]
        if d then add(d.raw) add(d.pooch) add(d.seed) end
    end
    for _, n in ipairs(S().Items or {}) do add(n) end
    return list
end

-- Ce que porte un joueur d'illégal : { items = { { item, count } }, black = argent sale }
function IB.seizureScan(target)
    local out = { items = {}, black = 0 }
    for _, name in ipairs(IB.seizureItems()) do
        local n = IB.itemCount(target, name)
        if n > 0 then out.items[#out.items + 1] = { item = name, count = n } end
    end
    if S().SeizeBlackMoney ~= false then
        local x = ESX.GetPlayerFromId(target)
        local acc = x and x.getAccount and x.getAccount('black_money')
        out.black = acc and math.floor(tonumber(acc.money) or 0) or 0
    end
    return out
end

-- Vérifications communes : policier, distance, délai → cible (xPlayer) ou nil, erreur
local function check(src, target)
    local C = S()
    if not C.Enabled then return nil, 'Les perquisitions sont désactivées' end
    local officer = ESX.GetPlayerFromId(src)
    if not officer or not IB.isPoliceJob(officer.job.name) then return nil, 'Réservé à la police' end
    target = tonumber(target)
    if not target or target == src then return nil, 'Cible invalide' end
    local t = ESX.GetPlayerFromId(target)
    if not t then return nil, 'Cible introuvable' end
    local a, b = GetPlayerPed(src), GetPlayerPed(target)
    if not a or a == 0 or not b or b == 0 then return nil, 'Cible introuvable' end
    local pa, pb = GetEntityCoords(a), GetEntityCoords(b)
    local dx, dy, dz = pa.x - pb.x, pa.y - pb.y, pa.z - pb.z
    if dx * dx + dy * dy + dz * dz > ((C.Distance or 3.0) + 1.5) ^ 2 then return nil, 'Trop loin du suspect' end
    return t, nil, officer
end

ESX.RegisterServerCallback('illegalbuilder:seize:inspect', function(src, cb, target)
    local t, err = check(src, target)
    if not t then return cb({ ok = false, error = err }) end
    local scan = IB.seizureScan(tonumber(target))
    local items = {}
    for _, it in ipairs(scan.items) do items[#items + 1] = { item = it.item, count = it.count } end
    cb({ ok = true, items = items, black = scan.black, name = IB.playerName(t) })
end)

ESX.RegisterServerCallback('illegalbuilder:seize:take', function(src, cb, target)
    local t, err, officer = check(src, target)
    if not t then return cb({ ok = false, error = err }) end
    local now = GetGameTimer()
    if (lastSeize[src] or -1e9) + (S().Cooldown or 0) * 1000 > now then return cb({ ok = false, error = 'Doucement' }) end
    lastSeize[src] = now
    target = tonumber(target)
    local scan = IB.seizureScan(target)
    if #scan.items == 0 and scan.black <= 0 then return cb({ ok = true, nothing = true }) end
    local taken = {}
    for _, it in ipairs(scan.items) do
        local moved = 0
        if IB.inventory() == 'ox' then
            -- on déplace chaque pile avec ses métadonnées (la pureté suit le produit)
            local slots = exports.ox_inventory:Search(target, 'slots', it.item) or {}
            for _, sl in ipairs(slots) do
                if exports.ox_inventory:RemoveItem(target, it.item, sl.count, nil, sl.slot) then
                    moved = moved + sl.count
                    if S().Evidence ~= false then pcall(function() exports.ox_inventory:AddItem(STASH, it.item, sl.count, sl.metadata) end) end
                end
            end
        elseif IB.removeItem(target, it.item, it.count) then moved = it.count end
        if moved > 0 then taken[#taken + 1] = { item = it.item, count = moved } end
    end
    local black = 0
    if scan.black > 0 and t.removeAccountMoney then
        t.removeAccountMoney('black_money', scan.black, 'Saisie police')
        black = scan.black
        local share = math.floor(black * math.max(0, math.min(100, S().SocietyShare or 100)) / 100)
        if share > 0 and (S().Society or '') ~= '' then IB.society(S().Society, share) end
    end
    pcall(function() MySQL.insert('INSERT INTO illegalbuilder_seizures (officer, officer_name, target, target_name, items, black_money, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
        { officer.identifier, IB.playerName(officer), t.identifier, IB.playerName(t), json.encode(taken), black, os.time() }) end)
    if GetResourceState('pickax_settings') == 'started' then
        pcall(function()
            exports.pickax_settings:Count('seizures', 1, 'Saisies de police')
            exports.pickax_settings:Count('seized_black', black, 'Argent sale saisi ($)')
            exports.pickax_settings:Discord('police', 'Saisie', ('%s a fouillé %s : %d objet(s), %d $ d\'argent sale saisis.'):format(IB.playerName(officer), IB.playerName(t), #taken, black), 3447003)
        end)
    end
    if IB.recordAdd and #taken + black > 0 and (Config.Record or {}).Enabled ~= false and (Config.Record or {}).AutoSeizure ~= false then
        IB.recordAdd(t.identifier, IB.playerName(t), 'Détention de produits illicites', 0, IB.playerName(officer))
    end
    IB.log(nil, officer, 'seizure', ('%s : %d objets, %d $ sale'):format(IB.playerName(t), #taken, black), black)
    TriggerClientEvent('illegalbuilder:client:notify', target, 'La police t\'a fouillé et a saisi ta marchandise illégale.', 'error')
    cb({ ok = true, items = taken, black = black })
end)

-- /preuves : ouvre le casier de preuves (police)
RegisterCommand('preuves', function(src)
    if src == 0 or not S().Enabled or S().Evidence == false then return end
    local x = ESX.GetPlayerFromId(src)
    if not x or not IB.isPoliceJob(x.job.name) then return TriggerClientEvent('illegalbuilder:client:notify', src, 'Réservé à la police.', 'error') end
    pcall(function() exports.ox_inventory:forceOpenInventory(src, 'stash', STASH) end)
end, false)

-- /saisies : dernières saisies (police)
RegisterCommand('saisies', function(src)
    if src == 0 or not S().Enabled then return end
    local x = ESX.GetPlayerFromId(src)
    if not x or not IB.isPoliceJob(x.job.name) then return TriggerClientEvent('illegalbuilder:client:notify', src, 'Réservé à la police.', 'error') end
    local rows = MySQL.query.await('SELECT officer_name, target_name, black_money, created_at FROM illegalbuilder_seizures ORDER BY id DESC LIMIT 6') or {}
    if #rows == 0 then return TriggerClientEvent('illegalbuilder:client:notify', src, 'Aucune saisie enregistrée.', 'info') end
    for _, r in ipairs(rows) do
        TriggerClientEvent('illegalbuilder:client:notify', src, ('%s · %s a fouillé %s · %d $ sale'):format(os.date('%d/%m %H:%M', r.created_at), r.officer_name or '?', r.target_name or '?', r.black_money or 0), 'info')
    end
end, false)

AddEventHandler('playerDropped', function() lastSeize[source] = nil end)
