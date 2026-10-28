-- Laboratoire interactif : règles pures (validation des résultats envoyés par le client, qualité, rendement). Aucun accès jeu : testable seul.
LabExp = {}

local function num(x, d) x = tonumber(x); if x ~= x or x == nil then return d end return x end

-- Durée minimale (ms) d'une étape : jamais moins de MinStepMs ; les étapes chronométrées (seconds) ne peuvent pas être finies plus vite que 80 % de leur durée
function LabExp.minMs(steps, X)
    local total = 0
    for _, st in ipairs(steps or {}) do
        total = total + math.max(X.MinStepMs or 1200, math.floor(num(st.seconds, 0) * 800))
    end
    return total
end

-- Données envoyées à l'interface : uniquement des champs simples
local KEYS = { 'type', 'label', 'title', 'hint', 'color', 'amount', 'seconds', 'turns', 'hold', 'low', 'high', 'coverage', 'bowls', 'hits', 'speed', 'speedLimit' }
function LabExp.publicSteps(steps)
    local out = {}
    for i, st in ipairs(steps or {}) do
        local o = {}
        for _, k in ipairs(KEYS) do if st[k] ~= nil then o[k] = st[k] end end
        out[i] = o
    end
    return out
end

-- Vérifie les résultats (un par étape, tous réussis, scores 0..1). Retourne true, qualité (0..1) ou false, raison
function LabExp.validate(results, nsteps)
    if type(results) ~= 'table' or #results ~= nsteps then return false, 'Résultats incomplets' end
    local sum = 0
    for i = 1, nsteps do
        local r = results[i]
        if type(r) ~= 'table' or r.ok ~= true then return false, 'Étape non terminée' end
        local s = num(r.score, nil)
        if not s then return false, 'Score invalide' end
        sum = sum + math.max(0, math.min(1, s))
    end
    return true, sum / math.max(1, nsteps)
end

-- ─── Niveaux, catalyseur, accidents (règles pures) ───
local function clamp(x, a, b) return math.max(a, math.min(b, x)) end

-- Niveau d'après l'XP : le niveau n+1 demande Base × n² XP
function LabExp.levelFor(xp, LV)
    if not LV or LV.Enabled == false then return 1 end
    local lvl, base, max = 1, num(LV.Base, 100), math.max(1, math.floor(num(LV.Max, 10)))
    xp = math.max(0, num(xp, 0))
    while lvl < max and xp >= base * lvl * lvl do lvl = lvl + 1 end
    return lvl
end

-- XP restante avant le niveau suivant : xpDans, xpRequis (nil au niveau max)
function LabExp.nextLevel(xp, LV)
    local lvl = LabExp.levelFor(xp, LV)
    if lvl >= math.floor(num(LV and LV.Max, 10)) then return nil end
    local need = num(LV.Base, 100) * lvl * lvl
    local prev = lvl > 1 and num(LV.Base, 100) * (lvl - 1) * (lvl - 1) or 0
    return math.max(0, xp - prev), need - prev
end

function LabExp.xpGain(made, failed, quality, LV)
    if not LV or LV.Enabled == false then return 0 end
    return math.max(0, math.floor(num(LV.XpPerBatch, 10) * (made * (0.5 + quality) + failed * 0.3) + 0.5))
end

-- Qualité finale : performance + bonus de niveau + catalyseur (bornée 0..1)
function LabExp.adjustQuality(q, level, boost, LV, CAT)
    local add = 0
    if LV and LV.Enabled ~= false then add = add + math.max(0, level - 1) * num(LV.QualityPerLevel, 0) end
    if boost and CAT and CAT.Enabled ~= false then add = add + num(CAT.Quality, 0) end
    return clamp(q + add, 0, 1)
end

-- Risque d'accident en % (0 si la qualité atteint le seuil)
function LabExp.accidentChance(q, level, boost, A, LV, CAT)
    if not A or A.Enabled == false then return 0 end
    local th = num(A.Threshold, 0.5)
    if q >= th or th <= 0 then return 0 end
    local c = num(A.Chance, 0) * (th - q) / th
    if LV and LV.Enabled ~= false then c = c * math.max(0, 1 - math.max(0, level - 1) * num(LV.AccidentPerLevel, 0)) end
    if boost and CAT and CAT.Enabled ~= false then c = c * num(CAT.AccidentFactor, 1) end
    return clamp(c, 0, 100)
end

-- Type d'accident tiré au sort selon les poids ; rnd(n) renvoie 1..n
function LabExp.pickAccident(A, rnd)
    rnd = rnd or function(n) return math.random(n) end
    local total = 0
    for _, k in ipairs(A.Kinds or {}) do total = total + math.max(0, num(k.weight, 0)) end
    if total <= 0 then return nil end
    local r = rnd(math.floor(total))
    for _, k in ipairs(A.Kinds) do
        r = r - math.max(0, num(k.weight, 0))
        if r <= 0 then return k.kind end
    end
    return A.Kinds[#A.Kinds].kind
end

-- Rendement : made = lots réussis (hors bonus) · failed · bonus. rnd(n) renvoie un entier 1..n (injectable pour les tests)
function LabExp.outcome(quality, batches, recipeFail, X, rnd)
    rnd = rnd or function(n) return math.random(n) end
    local fail = math.min(100, math.max(0, num(recipeFail, 0) + (1 - quality) * num(X.FailFromQuality, 0)))
    local made, failed = 0, 0
    for _ = 1, batches do
        if rnd(100) <= fail then failed = failed + 1 else made = made + 1 end
    end
    local share = math.max(0, math.min(1, num(X.YieldFromQuality, 0)))
    local mult = (1 - share) + share * 2 * quality          -- qualité 50 % → ×1 (neutre) ; 100 % → ×(1+share) ; 0 % → ×(1-share)
    local out = made > 0 and math.max(1, math.floor(made * mult + 0.5)) or 0
    local bonus = 0
    local pb = X.PerfectBonus
    if made > 0 and pb and quality >= num(pb.quality, 2) then bonus = math.max(0, math.floor(num(pb.extra, 0))) end
    return out, failed, bonus
end
