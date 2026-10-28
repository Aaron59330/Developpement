-- Pureté : facteur de prix et retrait des unités les plus pures d'abord (inventaire ox simulé).
local ROOT = os.getenv('ROOT') or '.'
local checks = 0
local function ok(c, m) checks = checks + 1 assert(c, m) end
local src = io.open(ROOT .. '/resources/[dev]/pickax_illegalbuilder/server/core.lua', 'r'):read('a')
local a = src:find('Pureté du produit', 1, true)
a = src:find('\n', a, true)
local b = src:find('function IB.balance', a, true)
ok(a and b, 'bloc pureté trouvé')
local slots = {
    { slot = 1, count = 3, metadata = { purity = 40 } },
    { slot = 2, count = 2, metadata = { purity = 90 } },
    { slot = 3, count = 5 },                                  -- sans pureté → défaut
}
local removed = {}
exports = setmetatable({}, { __index = function(_, k) return {
    Search = function(_, s, name, n) local out = {} for _, x in ipairs(slots) do out[#out + 1] = { slot = x.slot, count = x.count, metadata = x.metadata } end return out end,
    RemoveItem = function(_, s, name, take, md, slot) removed[#removed + 1] = { slot = slot, take = take } for _, x in ipairs(slots) do if x.slot == slot then x.count = x.count - take end end return true end } end })
Config = { Purity = { Enabled = true, Default = 50, MinFactor = 0.6, MaxFactor = 1.4 } }
IB = { inventory = function() return 'ox' end, itemCount = function() local n = 0 for _, x in ipairs(slots) do n = n + x.count end return n end, removeItem = function() return true end }
load(src:sub(a, b - 1), '@purity', 't', _G)()

ok(math.abs(IB.purityFactor(0) - 0.6) < 1e-9 and math.abs(IB.purityFactor(100) - 1.4) < 1e-9 and math.abs(IB.purityFactor(50) - 1.0) < 1e-9, 'facteurs 0 / 50 / 100 %')
ok(IB.purityFactor(nil) == 1.0, 'pureté inconnue = défaut 50 % → ×1')
Config.Purity.Enabled = false
ok(IB.purityFactor(100) == 1.0, 'désactivée : ×1')
Config.Purity.Enabled = true
local took, f, p = IB.takeUnits(1, 'weed_pooch', 4)
ok(took, 'retrait')
ok(removed[1].slot == 2 and removed[1].take == 2, 'les plus pures d\'abord (90 %)')
ok(removed[2].slot == 3 and removed[2].take == 2, 'puis le produit sans pureté (50 %)')
local expect = (IB.purityFactor(90) * 2 + IB.purityFactor(50) * 2) / 4
ok(math.abs(f - expect) < 1e-9, 'facteur moyen pondéré')
ok(p == 70, 'pureté moyenne 70 % : ' .. tostring(p))
ok(select(1, IB.takeUnits(1, 'weed_pooch', 99)) == false, 'quantité insuffisante refusée')
print(('purity_test : %d vérifications OK'):format(checks))
