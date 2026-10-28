-- ─────────────────────────────── Assurance véhicule ───────────────────────────────
-- Un joueur assure un de ses véhicules pour quelques jours ; en cas de mise en fourrière (police, dépanneuse, redémarrage), la fourrière coûte moins cher
-- selon la formule choisie. Propriété, durée et prix sont vérifiés côté serveur. /assurer (dans le véhicule), /assurance (liste).

local V = Config.Vehicles
local T = V.table
local function col(c) return '`' .. tostring(c):gsub('`', '') .. '`' end
local function trim(p) return (tostring(p or ''):gsub('^%s+', ''):gsub('%s+$', '')) end
local function I() return Config.Insurance or {} end

CreateThread(function()
    Wait(2500)
    if MySQL and MySQL.query then
        pcall(MySQL.query.await, [[CREATE TABLE IF NOT EXISTS worldbuilder_insurance (plate VARCHAR(20) PRIMARY KEY, owner VARCHAR(80) NOT NULL, plan VARCHAR(30) NOT NULL,
            coverage INT NOT NULL, until_at INT NOT NULL, INDEX (owner)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    end
end)

-- Part (%) de la fourrière prise en charge pour cette plaque (0 si non assuré ou expiré)
function WB.insuranceCoverage(plate)
    if not I().Enabled then return 0 end
    local row = MySQL.single.await('SELECT coverage, until_at FROM worldbuilder_insurance WHERE plate = ?', { trim(plate) })
    if not row or row.until_at < os.time() then return 0 end
    return math.max(0, math.min(100, math.floor(tonumber(row.coverage) or 0)))
end

-- Montant restant à payer après remboursement
function WB.insuranceApply(fee, coverage)
    return math.max(0, math.floor(fee * (100 - math.max(0, math.min(100, coverage))) / 100 + 0.5))
end

local function planOf(id) for _, p in ipairs(I().Plans or {}) do if p.id == id then return p end end end

local lastCmd = {}
RegisterCommand('assurer', function(src, args)
    if src == 0 or not I().Enabled then return end
    local x = ESX.GetPlayerFromId(src)
    if not x then return end
    if (lastCmd[src] or 0) + 3 > os.time() then return end
    lastCmd[src] = os.time()
    local plans = I().Plans or {}
    local plan = planOf(tostring(args[1] or ''))
    local veh = GetVehiclePedIsIn(GetPlayerPed(src), false)
    if not plan then
        local out = {}
        for _, p in ipairs(plans) do out[#out + 1] = ('%s : %d $ / %d j (%d %% de la fourrière)'):format(p.id, p.price, p.days, p.coverage) end
        return WB.notify(src, 'Dans ton véhicule : /assurer <formule>. ' .. table.concat(out, ' · '), 'info')
    end
    if not veh or veh == 0 then return WB.notify(src, 'Monte dans le véhicule à assurer.', 'error') end
    local plate = trim(GetVehicleNumberPlateText(veh))
    local row = MySQL.single.await(('SELECT %s AS plate FROM %s WHERE %s = ? AND TRIM(%s) = ?'):format(col(V.plate), T, col(V.owner), col(V.plate)), { x.identifier, plate })
    if not row then return WB.notify(src, 'Ce véhicule ne t\'appartient pas.', 'error') end
    local acc = x.getAccount('bank')
    if not acc or acc.money < plan.price then return WB.notify(src, ('Il te faut %d $ en banque.'):format(plan.price), 'error') end
    local mine = MySQL.scalar.await('SELECT COUNT(*) FROM worldbuilder_insurance WHERE owner = ? AND until_at > ? AND plate <> ?', { x.identifier, os.time(), plate }) or 0
    if mine >= (tonumber(I().MaxPerPlayer) or 3) then return WB.notify(src, 'Nombre maximal de véhicules assurés atteint.', 'error') end
    x.removeAccountMoney('bank', plan.price, 'Assurance véhicule')
    if (I().Society or '') ~= '' then WB.society(I().Society, plan.price) end
    local base = os.time()
    local cur = MySQL.single.await('SELECT until_at FROM worldbuilder_insurance WHERE plate = ?', { plate })
    if cur and cur.until_at > base then base = cur.until_at end   -- renouvellement : les jours s'ajoutent
    MySQL.update('REPLACE INTO worldbuilder_insurance (plate, owner, plan, coverage, until_at) VALUES (?, ?, ?, ?, ?)', { plate, x.identifier, plan.id, plan.coverage, base + plan.days * 86400 })
    WB.notify(src, ('%s assuré (%s) jusqu\'au %s.'):format(plate, plan.label or plan.id, os.date('%d/%m %H:%M', base + plan.days * 86400)), 'success')
end, false)

RegisterCommand('assurance', function(src)
    if src == 0 or not I().Enabled then return end
    local x = ESX.GetPlayerFromId(src)
    if not x then return end
    local rows = MySQL.query.await('SELECT plate, plan, coverage, until_at FROM worldbuilder_insurance WHERE owner = ? AND until_at > ? ORDER BY until_at', { x.identifier, os.time() }) or {}
    if #rows == 0 then return WB.notify(src, 'Aucun véhicule assuré. /assurer dans ton véhicule.', 'info') end
    for _, r in ipairs(rows) do WB.notify(src, ('%s · %s · %d %% de la fourrière · jusqu\'au %s'):format(r.plate, r.plan, r.coverage, os.date('%d/%m %H:%M', r.until_at)), 'info') end
end, false)

AddEventHandler('playerDropped', function() lastCmd[source] = nil end)
