-- Perquisitions : réservé à la police, distance, saisie des drogues (avec pureté) et de l'argent sale, société, historique (natives simulées).
local ROOT = os.getenv('ROOT') or '.'
local checks = 0
local function ok(c, m) checks = checks + 1 assert(c, m) end
local timer, cbs, stash, society, inserts, notified = 1000000, {}, {}, {}, 0, {}
function GetGameTimer() return timer end
function CreateThread() end
function Wait() end
function RegisterCommand() end
function TriggerClientEvent() end
function AddEventHandler() end
function GetResourceState() return 'started' end
json = { encode = function() return '[]' end }
MySQL = { insert = function() inserts = inserts + 1 end, query = { await = function() return {} end } }
local peds = { [1] = { ped = 11, pos = { x = 0.0, y = 0.0, z = 0.0 } }, [2] = { ped = 12, pos = { x = 1.0, y = 1.0, z = 0.0 } }, [3] = { ped = 13, pos = { x = 50.0, y = 0.0, z = 0.0 } } }
function GetPlayerPed(s) return peds[s] and peds[s].ped or 0 end
function GetEntityCoords(p) for _, v in pairs(peds) do if v.ped == p then return v.pos end end end
local inv2 = { weed_pooch = { { slot = 4, count = 3, metadata = { purity = 80 } }, { slot = 7, count = 2 } }, coke = { { slot = 9, count = 5 } } }
local removed = {}
exports = setmetatable({}, { __index = function() return { Search = function(_, id, kind, name) return id == 2 and inv2[name] or {} end,
    RemoveItem = function(_, id, name, count, md, slot) removed[#removed + 1] = { name, count, slot } return true end,
    AddItem = function(_, id, name, count, md) stash[#stash + 1] = { id, name, count, md and md.purity } return true end,
    RegisterStash = function() end } end })
local acc = { black_money = 7000 }
local players = {
    [1] = { identifier = 'cop', job = { name = 'police' } },
    [2] = { identifier = 'crook', job = { name = 'unemployed' }, getAccount = function(n) return { money = acc[n] } end, removeAccountMoney = function(n, v) acc[n] = acc[n] - v end },
    [3] = { identifier = 'far', job = { name = 'unemployed' }, getAccount = function() return { money = 0 } end },
}
ESX = { RegisterServerCallback = function(n, f) cbs[n] = f end, GetPlayerFromId = function(s) return players[s] end }
Config = { PoliceJobs = { 'police' }, DrugOrder = { 'weed' }, Drugs = { weed = { raw = 'weed', pooch = 'weed_pooch', seed = 'weed_seed' } },
    Seizure = { Enabled = true, Distance = 3.0, Cooldown = 4, SeizeBlackMoney = true, Society = 'society_police', SocietyShare = 100, Items = { 'coke' }, Evidence = true, StashSlots = 200, StashWeight = 500000 } }
IB = { inventory = function() return 'ox' end, isPoliceJob = function(n) return n == 'police' end, playerName = function(x) return x.identifier end, log = function() end,
    itemCount = function(s, n) local c = 0 for _, sl in ipairs(s == 2 and inv2[n] or {}) do c = c + sl.count end return c end,
    removeItem = function() return true end, society = function(n, v) society[#society + 1] = { n, v } end }
dofile(ROOT .. '/resources/[dev]/pickax_illegalbuilder/server/seizure.lua')
local function call(name, src, ...) local out; cbs[name](src, function(r) out = r end, ...) return out end

local items = IB.seizureItems()
ok(#items == 4 and items[1] == 'weed' and items[2] == 'weed_pooch' and items[3] == 'weed_seed' and items[4] == 'coke', 'objets illégaux : catalogue + liste du serveur')
ok(call('illegalbuilder:seize:inspect', 2, 1).error == 'Réservé à la police', 'un civil ne peut pas fouiller')
ok(call('illegalbuilder:seize:inspect', 1, 1).error == 'Cible invalide', 'on ne se fouille pas soi-même')
ok(call('illegalbuilder:seize:inspect', 1, 3).error == 'Trop loin du suspect', 'distance contrôlée')
local r = call('illegalbuilder:seize:inspect', 1, 2)
ok(r.ok and #r.items == 2 and r.black == 7000, 'inspection : pochons, coke et 7 000 $ sale')
ok(#removed == 0, 'inspecter ne retire rien')
r = call('illegalbuilder:seize:take', 1, 2)
ok(r.ok and r.black == 7000 and #r.items == 2, 'saisie')
ok(#removed == 3 and removed[1][3] == 4 and removed[2][3] == 7, 'chaque pile est retirée (emplacements 4, 7, 9)')
ok(stash[1][1] == 'ib_evidence' and stash[1][4] == 80, 'la pureté suit le produit dans le casier de preuves')
ok(acc.black_money == 0 and society[1][1] == 'society_police' and society[1][2] == 7000, 'argent sale retiré et reversé à la société')
ok(inserts == 1, 'saisie enregistrée en base')
ok(call('illegalbuilder:seize:take', 1, 2).error == 'Doucement', 'délai entre deux saisies')
timer = timer + 5000
inv2 = {}
acc.black_money = 0
ok(call('illegalbuilder:seize:take', 1, 2).nothing == true, 'rien à saisir')
Config.Seizure.Enabled = false
ok(call('illegalbuilder:seize:inspect', 1, 2).error:find('désactivées'), 'fonction désactivée')
print(('seizure_test : %d vérifications OK'):format(checks))
