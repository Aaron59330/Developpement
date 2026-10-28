-- Fourrière → enchères : mise en vente par l'État, produit à la société, invendu rendu au propriétaire (natives et base simulées).
local ROOT = os.getenv('ROOT') or '.'
local checks = 0
local function ok(c, m) checks = checks + 1 assert(c, m) end
local now = 1700000000
os.time = function() return now end
local threads, updates, inserts, shared = {}, {}, {}, {}
function CreateThread(f) threads[#threads + 1] = f end
function Wait() coroutine.yield() end
function AddEventHandler() end
function GetResourceState() return 'started' end
function GetGameTimer() return 0 end
lib = { callback = { register = function() end } }
exports = setmetatable({ es_extended = { getSharedObject = function() return { GetPlayerFromIdentifier = function() return nil end } end }, pickax_core = { AddSharedMoney = function(_, n, v) shared[#shared + 1] = { n, v } return true end } }, { __call = function() end })
local handlers = {}
exports = setmetatable({ es_extended = { getSharedObject = function() return { GetPlayerFromIdentifier = function() return nil end } end }, pickax_core = { AddSharedMoney = function(_, n, v) shared[#shared + 1] = { n, v } return true end } }, { __call = function(_, name, f) handlers[name] = f end })
local auctionRow, vehOwner = nil, 'license:orig'
MySQL = { ready = function() end,
    insert = { await = function(sql, p) auctionRow = { id = 7, seller = p[1], seller_name = p[2], kind = p[3], item = p[4], plate = p[5], label = p[6], start_price = p[7], bid = 0, bidder = nil, ends_at = p[8], status = p[10], count = 1 } return 7 end },
    update = { await = function(sql, p)
        updates[#updates + 1] = { sql, p }
        if sql:find('SET `owner` = %?') and p[2] == 'license:orig' and p[4] == 2 then vehOwner = p[1] return 1 end
        if sql:find("SET status = 'closing'") then return 1 end
        if sql:find('SET `owner` = %?') then return 1 end
        if sql:find("SET label = %?") then auctionRow.label = p[1] auctionRow.status = 'active' return 1 end
        return 1 end },
    scalar = { await = function() return 'Sultan' end },
    single = { await = function(sql, p) return auctionRow end },
    query = { await = function(sql) if sql:find("status = 'active' AND ends_at <=") then return { { id = 7 } } end return {} end } }
Config = {} dofile(ROOT .. '/resources/[dev]/pickax_auction/config.lua')
dofile(ROOT .. '/resources/[dev]/pickax_auction/server/main.lua')

-- mise en vente
local id = handlers.ListImpounded('AB123', 'license:orig', 3000, 48)
ok(id == 7 and auctionRow.seller == 'state' and auctionRow.item == 'license:orig' and auctionRow.status == 'active' and auctionRow.start_price == 3000 and vehOwner == 'auction:7', 'véhicule de fourrière mis aux enchères par l\'État (propriétaire en dépôt)')
ok(auctionRow.label == 'Sultan', 'libellé du véhicule récupéré')
ok(handlers.ListImpounded('', 'x', 3000, 48) == false and handlers.ListImpounded('AB', 'x', 0, 48) == false, 'paramètres invalides refusés')
local before = #updates
vehOwner = 'license:orig'
-- véhicule absent de la fourrière : l'enchère est annulée
local oldUpd = MySQL.update.await
MySQL.update.await = function(sql, p) updates[#updates + 1] = { sql, p } if sql:find('DELETE FROM pickax_auctions') then return 1 end return 0 end
ok(handlers.ListImpounded('ZZ999', 'license:orig', 3000, 48) == false, 'véhicule pas en fourrière : refusé, enchère supprimée')
MySQL.update.await = oldUpd
-- fin d'enchère invendue : rendu au propriétaire
auctionRow = { id = 7, seller = 'state', seller_name = 'Fourrière', kind = 'vehicle', item = 'license:orig', plate = 'AB123', label = 'Sultan', bid = 0, bidder = nil, status = 'active', count = 1 }
local co = coroutine.create(threads[#threads])
-- on cherche la boucle de fin d'enchère (la dernière thread créée par main.lua)
local loop
for _, f in ipairs(threads) do loop = f end
co = coroutine.create(loop) coroutine.resume(co) coroutine.resume(co)
local back
for _, u in ipairs(updates) do if u[1]:find('SET `owner` = %?') and u[2][1] == 'license:orig' and u[2][2] == 'auction:7' then back = true end end
ok(back, 'invendu : le véhicule retourne à son ancien propriétaire')
-- invendu en mode casse
updates = {}
Config.State.Unsold = 'scrap'
auctionRow = { id = 7, seller = 'state', kind = 'vehicle', item = 'license:orig', plate = 'AB123', label = 'Sultan', bid = 0, status = 'active', count = 1 }
coroutine.resume(co)
local scrapped
for _, u in ipairs(updates) do if u[1]:find('DELETE FROM `owned_vehicles`') then scrapped = true end end
ok(scrapped, 'invendu en mode « scrap » : véhicule détruit')
-- vendu : le produit va à l'État (taxe déduite)
updates = {}
Config.State.Unsold = 'owner'
auctionRow = { id = 7, seller = 'state', seller_name = 'Fourrière', kind = 'vehicle', item = 'license:orig', plate = 'AB123', label = 'Sultan', bid = 10000, bidder = 'license:buyer', bidder_name = 'Acheteur', status = 'active', count = 1 }
coroutine.resume(co)
ok(shared[#shared] and shared[#shared][1] == 'society_police' and shared[#shared][2] == 9500, 'vendu 10 000 $ : 9 500 $ (taxe 5 %) versés à la société de l\'État')
-- le client ne reçoit jamais l'ancien propriétaire
-- (rowOut est local : on vérifie par le source)
local src = io.open(ROOT .. '/resources/[dev]/pickax_auction/server/main.lua'):read('a')
ok(src:find("item = r.kind == 'item' and r.item or nil", 1, true), 'l\'ancien propriétaire n\'est jamais envoyé aux joueurs')

-- décision de mise en vente côté worldbuilder
Config = { Vehicles = { table = 'owned_vehicles', owner = 'owner', plate = 'plate', stored = 'state' }, ImpoundAuction = { Enabled = true, Days = 14, WarnDays = 2 } }
WB = {} ESX = {} threads = {}
dofile(ROOT .. '/resources/[dev]/pickax_worldbuilder/server/autoauction.lua')
ok(WB.auctionDecision(3) == nil and WB.auctionDecision(12.5) == 'warn' and WB.auctionDecision(14) == 'sell' and WB.auctionDecision(30) == 'sell', 'décision : rien / prévenir 2 jours avant / vendre à 14 jours')
Config.ImpoundAuction.WarnDays = 0
ok(WB.auctionDecision(13) == nil, 'sans préavis : pas d\'avertissement')
print(('autoauction_test : %d vérifications OK'):format(checks))
