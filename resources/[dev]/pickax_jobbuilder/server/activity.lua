-- ─────────────────────────────── Métiers actifs (pickax_activejobs) ───────────────────────────────
-- Les jobs de type garbage / towing / carwash / trucker / farmer / firefighter / train se créent ici comme les autres (grades, société, vestiaire, coffre,
-- boss, service). Leur « poste d'activité » (point) ouvre le panneau de la ressource pickax_activejobs, qui gère les missions, l'XP et la paie.
-- Les points d'activité (rôle : zone, fourrière, baie, destination, champ, marché, incendie, station) décrivent le terrain.

local function sortedPoints(jobName)
    local list = {}
    for id, p in pairs(JB.Points) do if p.job_name == jobName then list[#list + 1] = p end end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end

local function xyz(c, label) return { x = c.x + 0.0, y = c.y + 0.0, z = c.z + 0.0, h = (c.h or 0.0) + 0.0, label = label or '' } end

-- Infos d'un job (type, label, grades, grade boss)
exports('GetJobMeta', function(jobName)
    local job = JB.Jobs[tostring(jobName)]
    if not job then return nil end
    return { name = job.name, type = job.type, label = job.label, grades = job.grades, boss_grade = job.boss_grade }
end)

-- Poste d'activité (point) : job, grade minimum, position et sortie du véhicule
exports('GetActivityPoint', function(pointId)
    local p = JB.Points[tonumber(pointId)]
    if not p or p.type ~= 'activity' then return nil end
    local job = JB.Jobs[p.job_name]
    if not job then return nil end
    return { id = p.id, job = p.job_name, type = job.type, min_grade = p.min_grade, label = p.label, coords = xyz(p.coords, p.label), spawn = p.data.spawn and xyz(p.data.spawn, 'Sortie véhicule') or nil }
end)

-- Points d'activité du job : { rôle = { {x,y,z,h,label}, ... } } dans l'ordre de création
exports('GetActivityRoles', function(jobName)
    local out = {}
    for _, p in ipairs(sortedPoints(tostring(jobName))) do
        if p.type == 'actpoint' and p.data.role then
            out[p.data.role] = out[p.data.role] or {}
            table.insert(out[p.data.role], xyz(p.coords, p.label))
        end
    end
    return out
end)
