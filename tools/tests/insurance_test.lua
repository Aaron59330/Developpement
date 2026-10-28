-- Assurance véhicule : achat, propriété, durée, renouvellement, réduction de la fourrière (natives et base simulées).
local ROOT = os.getenv('ROOT') or '.'
local checks = 0
local function ok(c, m) checks = checks + 1 assert(c, m) end
local now = 1700000000
os.time = function() return now end
local cmds, notes, society = {}, {}, {}
function CreateThread() end
function Wait() end
function RegisterCommand(n, f) cmds[n] = f end
function AddEventHandler() end
local veh = { [1] = 100, [2] = 0 }
function GetPlayerPed(s) return s end
function GetVehiclePedIsIn(p) return veh[p] or 0 end
function GetVehicleNumberPlateText(v) return ' AB 123 ' end
local owned, ins = { { owner = 'id1', plate = 'AB 123' } }, {}
MySQL = { query = { await = function(sql, p) if sql:find('FROM worldbuilder_insurance WHERE owner') then local l = {} for _, r in pairs(ins) do if r.owner == p[1] and r.until_at > p[2] then l[#l + 1] = r end end return l end return {} end },
    single = { await = function(sql, p)
        if sql:find('FROM owned_vehicles') then for _, r in ipairs(owned) do if r.owner == p[1] and r.plate == p[2] then return { plate = r.plate } end end return nil end
        if sql:find('coverage, until_at') or sql:find('until_at FROM worldbuilder_insurance') then return ins[p[1]] end return nil end },
    scalar = { await = function(sql, p) local n = 0 for k, r in pairs(ins) do if r.owner == p[1] and r.until_at > p[2] and k ~= p[3] then n = n + 1 end end return n end },
    update = function(sql, p) ins[p[1]] = { plate = p[1], owner = p[2], plan = p[3], coverage = p[4], until_at = p[5] } end }
local bank = { id1 = 10000, id2 = 10000 }
local function mk(id, ident) return { source = id, identifier = ident, getAccount = function() return { money = bank[ident] } end, removeAccountMoney = function(_, v) bank[ident] = bank[ident] - v end } end
local players = { [1] = mk(1, 'id1'), [2] = mk(2, 'id2') }
ESX = { GetPlayerFromId = function(s) return players[s] end }
WB = { notify = function(s, m) notes[#notes + 1] = m end, society = function(n, v) society[#society + 1] = { n, v } end }
Config = { Vehicles = { table = 'owned_vehicles', owner = 'owner', plate = 'plate', props = 'vehicle', stored = 'state' }, Insurance = { Enabled = true, MaxPerPlayer = 2, Society = 'society_assur',
    Plans = { { id = 'basic', label = 'Basique', days = 7, price = 2500, coverage = 50 }, { id = 'full', label = 'Tous risques', days = 7, price = 6000, coverage = 100 } } } }
dofile(ROOT .. '/resources/[dev]/pickax_worldbuilder/server/insurance.lua')

ok(WB.insuranceApply(1000, 50) == 500 and WB.insuranceApply(1000, 100) == 0 and WB.insuranceApply(1000, 0) == 1000 and WB.insuranceApply(333, 50) == 167, 'calcul de la fourrière après assurance')
ok(WB.insuranceCoverage('AB 123') == 0, 'non assuré : aucune prise en charge')
cmds.assurer(1, { '' }) ok(notes[#notes]:find('basic'), 'sans formule : liste des formules')
cmds.assurer(1, { 'inconnue' }) ok(notes[#notes]:find('basic'), 'formule inconnue : liste')
cmds.assurer(2, { 'basic' }) ok(notes[#notes]:find('Monte dans le véhicule'), 'il faut être dans un véhicule')
veh[2] = 100
now = now + 10
cmds.assurer(2, { 'basic' }) ok(notes[#notes]:find('ne t\'appartient pas') and bank.id2 == 10000, 'véhicule d\'un autre : refusé, rien prélevé')
bank.id1 = 1000 now = now + 10
cmds.assurer(1, { 'basic' }) ok(notes[#notes]:find('Il te faut 2500') and bank.id1 == 1000, 'fonds insuffisants')
bank.id1 = 10000 now = now + 10
cmds.assurer(1, { 'basic' })
ok(bank.id1 == 7500 and society[#society][2] == 2500 and ins['AB 123'].coverage == 50 and WB.insuranceCoverage('AB 123') == 50, 'assuré : prime prélevée, versée à la société, 50 % pris en charge')
local first = ins['AB 123'].until_at
now = now + 10
cmds.assurer(1, { 'full' })
ok(ins['AB 123'].until_at == first + 7 * 86400 and WB.insuranceCoverage('AB 123') == 100, 'renouvellement : les jours s\'ajoutent, nouvelle formule')
now = now + 20 * 86400
ok(WB.insuranceCoverage('AB 123') == 0, 'assurance expirée : plus de prise en charge')
Config.Insurance.Enabled = false
ok(WB.insuranceCoverage('AB 123') == 0, 'assurance désactivée : aucune prise en charge')
print(('insurance_test : %d vérifications OK'):format(checks))
