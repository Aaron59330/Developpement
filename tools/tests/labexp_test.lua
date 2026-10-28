dofile((os.getenv('ROOT') or '.') .. '/resources/[dev]/pickax_jobbuilder/server/labexp.lua')
local X = { MinStepMs = 1200, YieldFromQuality = 0.4, FailFromQuality = 35, PerfectBonus = { quality = 0.92, extra = 1 } }
local n = 0
local function function_ok(c, m) assert(c, m) n = n + 1 print("  ✓", m) end
local steps = { { type = 'add', seconds = 5 }, { type = 'stir', turns = 6 }, { type = 'timing' } }
function_ok(LabExp.minMs(steps, X) == 4000 + 1200 + 1200, 'durée minimale : 80 % de la durée des étapes chronométrées, 1,2 s minimum pour les autres')
local res = function(...) local t = {} for _, s in ipairs({ ... }) do t[#t + 1] = { ok = true, score = s, ms = 5000 } end return t end
local ok, q = LabExp.validate(res(1, 0.5, 0.75), 3)
function_ok(ok and math.abs(q - 0.75) < 1e-9, 'qualité = moyenne des scores')
function_ok(not LabExp.validate(res(1, 1), 3), 'refusé : il manque une étape')
function_ok(not LabExp.validate({ { ok = true, score = 1 }, { ok = false, score = 1 }, { ok = true, score = 1 } }, 3), 'refusé : étape non réussie')
function_ok(not LabExp.validate({ { ok = true, score = 'x' }, { ok = true, score = 1 }, { ok = true, score = 1 } }, 3), 'refusé : score invalide')
function_ok(not LabExp.validate('triche', 3), 'refusé : résultats absents')
local _, q2 = LabExp.validate(res(9, -4, 1), 3); function_ok(math.abs(q2 - (1 + 0 + 1) / 3) < 1e-9, 'scores bornés entre 0 et 1 (pas de triche par valeurs extrêmes)')
local never = function() return 100 end
local made, failed, bonus = LabExp.outcome(1.0, 3, 0, X, never)
function_ok(made == 4 and failed == 0 and bonus == 1, 'qualité 100 % : rendement ×1,4 (3 → 4) et pochon bonus')
made, failed, bonus = LabExp.outcome(0.5, 3, 0, X, never)
function_ok(made == 3 and bonus == 0, 'qualité 50 % : rendement normal, pas de bonus')
made, failed, bonus = LabExp.outcome(0.0, 3, 0, X, never)
function_ok(made == 2 and bonus == 0, 'qualité 0 % : rendement ×0,6 (3 → 2)')
local always = function() return 1 end
made, failed = LabExp.outcome(0.9, 3, 0, X, always); function_ok(made == 0 and failed == 3, 'tirage sous le seuil : tous les lots ratés')
made, failed = LabExp.outcome(1.0, 4, 10, X, function(n) return 11 end); function_ok(made == 6 and failed == 0, 'qualité 100 % : le risque d’échec de la recette reste inchangé (10 %), 11 > 10 réussi')
-- statistique : qualité basse → plus d'échecs
math.randomseed(7)
local function fails(qq) local f = 0 for _ = 1, 4000 do local _, x = LabExp.outcome(qq, 1, 5, X) f = f + x end return f / 4000 end
local lo, hi = fails(0.1), fails(1.0)
function_ok(lo > hi + 0.2, ('qualité basse = plus de lots ratés (%.0f %% contre %.0f %%)'):format(lo * 100, hi * 100))
local pub = LabExp.publicSteps({ { type = 'add', label = 'x', secret = 'ne pas envoyer', amount = 3 } })
function_ok(pub[1].amount == 3 and pub[1].secret == nil, 'seuls les champs d’interface sont envoyés au client')
-- niveaux / catalyseur / accidents
local LV = { Enabled = true, XpPerBatch = 10, Base = 100, Max = 5, QualityPerLevel = 0.015, AccidentPerLevel = 0.06 }
local CAT = { Enabled = true, Quality = 0.12, AccidentFactor = 0.5 }
local A = { Enabled = true, Threshold = 0.5, Chance = 60, Kinds = { { kind = 'leak', weight = 60 }, { kind = 'fire', weight = 30 }, { kind = 'explosion', weight = 10 } } }
function_ok(LabExp.levelFor(0, LV) == 1 and LabExp.levelFor(99, LV) == 1 and LabExp.levelFor(100, LV) == 2 and LabExp.levelFor(400, LV) == 3 and LabExp.levelFor(900, LV) == 4, 'niveaux : 100 / 400 / 900 XP')
function_ok(LabExp.levelFor(10 ^ 9, LV) == 5, 'niveau maximum respecté')
function_ok(LabExp.levelFor(10 ^ 9, { Enabled = false }) == 1, 'niveaux désactivés = niveau 1')
local got, need = LabExp.nextLevel(250, LV)
function_ok(got == 150 and need == 300, ('progression vers le niveau suivant : %s / %s'):format(tostring(got), tostring(need)))
function_ok(LabExp.nextLevel(10 ^ 9, LV) == nil, 'pas de niveau suivant au maximum')
function_ok(LabExp.xpGain(2, 1, 1.0, LV) == math.floor(10 * (2 * 1.5 + 0.3) + 0.5), 'XP : lots réussis + lots ratés')
function_ok(LabExp.xpGain(1, 0, 1, { Enabled = false }) == 0, 'XP désactivée')
function_ok(math.abs(LabExp.adjustQuality(0.5, 3, false, LV, CAT) - 0.53) < 1e-9, 'bonus de niveau : +1,5 % par niveau au-dessus du 1')
function_ok(math.abs(LabExp.adjustQuality(0.5, 1, true, LV, CAT) - 0.62) < 1e-9, 'catalyseur : +12 %')
function_ok(LabExp.adjustQuality(0.95, 5, true, LV, CAT) == 1, 'qualité bornée à 100 %')
function_ok(LabExp.accidentChance(0.5, 1, false, A, LV, CAT) == 0, 'aucun accident au seuil de qualité')
function_ok(math.abs(LabExp.accidentChance(0, 1, false, A, LV, CAT) - 60) < 1e-9, 'qualité 0 : risque maximum')
function_ok(math.abs(LabExp.accidentChance(0.25, 1, false, A, LV, CAT) - 30) < 1e-9, 'risque proportionnel à la qualité')
function_ok(math.abs(LabExp.accidentChance(0, 1, true, A, LV, CAT) - 30) < 1e-9, 'catalyseur : risque ÷ 2')
function_ok(math.abs(LabExp.accidentChance(0, 6, false, A, { Enabled = true, AccidentPerLevel = 0.06 }, CAT) - 42) < 1e-9, 'niveau 6 : -30 % de risque')
function_ok(LabExp.accidentChance(0, 1, false, { Enabled = false }, LV, CAT) == 0, 'accidents désactivés')
local counts = { leak = 0, fire = 0, explosion = 0 }
math.randomseed(3)
for _ = 1, 6000 do counts[LabExp.pickAccident(A)] = counts[LabExp.pickAccident(A)] + 0 end
for _ = 1, 6000 do local k = LabExp.pickAccident(A) counts[k] = counts[k] + 1 end
function_ok(counts.leak > counts.fire and counts.fire > counts.explosion, ('tirage pondéré : fuite %d > incendie %d > explosion %d'):format(counts.leak, counts.fire, counts.explosion))
function_ok(LabExp.pickAccident({ Kinds = {} }) == nil, 'aucun type configuré : pas d\'accident')
print('\n' .. n .. ' vérifications OK')
