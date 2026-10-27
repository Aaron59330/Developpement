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
