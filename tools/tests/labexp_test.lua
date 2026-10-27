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
print('\n' .. n .. ' vérifications OK')
