-- Entreprises de joueurs : validation réelle du job créé par le builder, frais, limites, dissolution et remboursement (natives et base simulées).
local ROOT = os.getenv('ROOT') or '.'
local checks = 0
local function ok(c, m) checks = checks + 1 assert(c, m) end
local now = 1700000000
os.time = function() return now end
local cmds, cbs, notes, sqls = {}, {}, {}, {}
function CreateThread() end
function Wait() end
function RegisterCommand(n, f) cmds[n] = f end
function AddEventHandler() end
function RegisterNetEvent() end
function TriggerClientEvent() end
function GetResourceState() return 'missing' end
function IsDuplicityVersion() return true end
function JBNotifyClient(s, m) notes[#notes + 1] = m end
function vector3(x, y, z) return { x = x, y = y, z = z } end
vector2 = function(x, y) return { x = x, y = y } end
local pos = { x = 100.0, y = 200.0, z = 30.0 }
function GetPlayerPed() return 1 end
function GetEntityCoords() return pos end
-- base simulée
local jobsTable, companies, society, deletedJob = {}, {}, 5000, nil
local function emptyList() return {} end
MySQL = { ready = function(f) end,
    query = { await = function(sql, p)
        if sql:find('FROM jobbuilder_companies WHERE owner') then local l = {} for _, c in pairs(companies) do if c.owner == p[1] then l[#l + 1] = { job_name = c.job_name } end end return l end
        if sql:find('FROM jobbuilder_jobs WHERE LOWER%(label%)') then for _, j in pairs(JB.Jobs) do if j.label:lower() == p[1] then return { { label = j.label } } end end return {} end
        if sql:find('FROM jobs WHERE name') then return jobsTable[p[1]] and { { name = p[1] } } or {} end
        return {} end },
    single = { await = function() return nil end },
    scalar = { await = function(sql, p) if sql:find('addon_account_data') then return society end return 0 end },
    insert = { await = function(sql, p) if sql:find('jobbuilder_companies') then companies[p[1]] = { job_name = p[1], owner = p[2] } end return 1 end },
    update = setmetatable({ await = function(sql, p) sqls[#sqls + 1] = sql return 1 end }, { __call = function(_, sql, p) if sql:find('DELETE FROM jobbuilder_companies') then companies[p[1]] = nil end end }),
    transaction = { await = function(q) for _, x in ipairs(q) do if x.query:find('INSERT INTO jobs') then jobsTable[x.values[1]] = true end end return true end } }
-- joueur
json = { encode = function() return '{}' end, decode = function() return {} end }
local bank = 100000
local x = { source = 1, identifier = 'id1', job = { name = 'unemployed', grade = 0 }, getAccount = function() return { money = bank } end, removeAccountMoney = function(_, v) bank = bank - v end, addAccountMoney = function(_, v) bank = bank + v end,
    setJob = function(self, name, grade) self.job = { name = name, grade = grade } end }
x.setJob = function(name, grade) x.job = { name = name, grade = grade } end
ESX = { RegisterServerCallback = function(n, f) cbs[n] = f end, GetPlayerFromId = function() return x end, GetExtendedPlayers = function() return {} end }
JB = { Jobs = {}, Points = {}, isDev = function() return true end, societyAccount = function(n) return 'society_' .. n end, log = function() end,
    loadAll = function() end, refreshESX = function() end, syncAll = function() end, inventory = function() return 'ox' end }
JB.playerName = function() return 'Jean' end
Config = {} PickaxTheme = nil
Config.Real = { Lab = {} } Config.Max = {} Config.Tablet = {}
local okc, err = pcall(dofile, ROOT .. '/resources/[dev]/pickax_jobbuilder/config.lua')
ok(okc, 'config.lua du jobbuilder chargé : ' .. tostring(err))
dofile(ROOT .. '/resources/[dev]/pickax_jobbuilder/server/builder.lua')
dofile(ROOT .. '/resources/[dev]/pickax_jobbuilder/server/company.lua')

-- noms
ok(JB.companyLabel('  Garage   Dupont ') == 'Garage Dupont' and JB.companyLabel('ab') == nil and JB.companyLabel('<script>') == nil and JB.companyLabel(string.rep('x', 40)) == nil, 'nom d\'entreprise : 3 à 30 caractères, sans caractères interdits')
ok(JB.companyJobName('Café Élégant', 1) == 'co_cafeelega_1' and #JB.companyJobName('Un nom beaucoup trop long pour un job', 12345) <= 20 and JB.companyJobName('!!!', 2) == 'co_societe_2', 'identifiant du job : accents retirés, 20 caractères max')
-- création
cmds.entreprise(1, { 'creer', 'inconnu', 'Mon', 'Garage' }) ok(notes[#notes]:find('Usage'), 'modèle inconnu : usage affiché')
now = now + 5
cmds.entreprise(1, { 'creer', 'commerce', 'ab' }) ok(notes[#notes]:find('3 et 30'), 'nom trop court refusé')
now = now + 5
bank = 1000
cmds.entreprise(1, { 'creer', 'commerce', 'Chez', 'Marcel' }) ok(notes[#notes]:find('25000') and bank == 1000, 'fonds insuffisants : rien prélevé')
now = now + 5
bank = 100000
cmds.entreprise(1, { 'creer', 'commerce', 'Chez', 'Marcel' })
local created; for n, c in pairs(companies) do created = n end
ok(created and jobsTable[created] and bank == 75000 and x.job.name == created and x.job.grade == 2, 'entreprise créée avec le vrai validateur du builder : frais payés, fondateur patron')
ok(notes[#notes]:find('est créée'), 'message de succès')
JB.Jobs[created] = { label = 'Chez Marcel', name = created }
now = now + 5
cmds.entreprise(1, { 'creer', 'commerce', 'Autre', 'Nom' }) ok(notes[#notes]:find('nombre maximal'), 'une entreprise par joueur')
-- registre du commerce
Config.Company.MaxPerPlayer = 2 Config.Company.Registry = { { coords = { x = 0.0, y = 0.0, z = 0.0 }, radius = 6.0 } }
now = now + 5
cmds.entreprise(1, { 'creer', 'atelier', 'Atelier', 'Bob' }) ok(notes[#notes]:find('registre'), 'hors du registre du commerce : refusé')
Config.Company.Registry = {} Config.Company.MaxPerPlayer = 1
-- dissolution
now = now + 5
cmds.entreprise(1, { 'dissoudre' }) ok(notes[#notes]:find('confirmer') and companies[created], 'dissolution : confirmation demandée')
now = now + 40
cmds.entreprise(1, { 'confirmer' }) ok(companies[created], 'confirmation expirée : rien ne se passe')
now = now + 5
cmds.entreprise(1, { 'dissoudre' }) now = now + 3
cmds.entreprise(1, { 'dissoudre' }) ok(companies[created], '« dissoudre » seul ne confirme jamais')
now = now + 3
cmds.entreprise(1, { 'confirmer' })
ok(companies[created] == nil and bank == 80000 and notes[#notes]:find('5000'), 'entreprise dissoute : solde de la société (5 000 $) reversé')
print(('company_test : %d vérifications OK'):format(checks))
