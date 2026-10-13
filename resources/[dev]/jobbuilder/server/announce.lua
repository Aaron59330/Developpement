-- ─────────────────────────────── Annonces d'entreprise ───────────────────────────────
-- Un employé (grade suffisant) diffuse une annonce à tous les joueurs (ou dans un rayon) : bandeau à l'écran.
-- Réglages par job (onglet Général → Annonces) : activée, grade, délai, coût (prélevé sur la société), rayon, durée, types autorisés.

local A = Config.Announce
local lastSent = {}     -- [job] = os.time()

local function fail(msg) return { ok = false, error = msg } end
local function str(v, max) return type(v) == 'string' and (v:gsub('%c', ' ')):sub(1, max) or '' end

local function typeById(id)
    for _, t in ipairs(A.Types) do if t.id == id then return t end end
end

local function jobSettings(job)
    local s = job.settings or {}
    return {
        grade = s.announce_grade or job.boss_grade,
        cooldown = s.announce_cooldown or A.Cooldown,
        cost = s.announce_cost or A.Cost,
        radius = s.announce_radius or 0,
        duration = s.announce_duration or A.Duration,
        types = s.announce_types or {},
    }
end

local function allowedTypes(cfg)
    local out = {}
    local only = {}
    for _, id in ipairs(cfg.types) do only[id] = true end
    for _, t in ipairs(A.Types) do
        if next(only) == nil or only[t.id] then out[#out + 1] = { id = t.id, label = t.label, color = t.color } end
    end
    return out
end

local function ctx(src)
    if not A.Enabled then return nil, nil, nil, 'Les annonces d\'entreprise sont désactivées' end
    local x = ESX.GetPlayerFromId(src)
    if not x then return nil, nil, nil, 'Joueur introuvable' end
    local job = JB.Jobs[x.job.name]
    if not job or (job.settings or {}).announce_enabled == false then return nil, nil, nil, 'Ton métier ne peut pas faire d\'annonce' end
    local cfg = jobSettings(job)
    if x.job.grade < cfg.grade then return nil, nil, nil, 'Ton grade ne permet pas de faire une annonce' end
    return x, job, cfg
end

ESX.RegisterServerCallback('jobbuilder:announce:open', function(src, cb)
    local x, job, cfg, err = ctx(src)
    if not x then return cb(fail(err)) end
    local history = MySQL.query.await('SELECT author, kind, title, text, UNIX_TIMESTAMP(created_at) AS t FROM jobbuilder_announces WHERE job_name = ? ORDER BY id DESC LIMIT ?', { job.name, A.History }) or {}
    cb({
        ok = true, jobLabel = job.label, types = allowedTypes(cfg), history = history,
        cost = cfg.cost, cooldown = cfg.cooldown, left = math.max(0, cfg.cooldown - (os.time() - (lastSent[job.name] or 0))),
        radius = cfg.radius, maxTitle = A.MaxTitle, maxText = A.MaxText, society = job.society and JB.societyBalance and JB.societyBalance(job.name) or nil,
    })
end)

ESX.RegisterServerCallback('jobbuilder:announce:send', function(src, cb, kind, title, text)
    local x, job, cfg, err = ctx(src)
    if not x then return cb(fail(err)) end
    local left = cfg.cooldown - (os.time() - (lastSent[job.name] or 0))
    if left > 0 then return cb(fail(('Patiente encore %d s avant la prochaine annonce'):format(left))) end

    local t
    for _, a in ipairs(allowedTypes(cfg)) do if a.id == kind then t = typeById(a.id) end end
    if not t then return cb(fail('Type d\'annonce non autorisé')) end
    title, text = str(title, A.MaxTitle), str(text, A.MaxText)
    if #title < 3 then return cb(fail('Le titre est trop court')) end
    if #text < 5 then return cb(fail('Le message est trop court')) end

    if cfg.cost > 0 and job.society then
        if not JB.societyRemove(job.name, cfg.cost) then return cb(fail(('La société n\'a pas les %d $ nécessaires'):format(cfg.cost))) end
    end
    lastSent[job.name] = os.time()

    local payload = { jobLabel = job.label, kindLabel = t.label, color = t.color, title = title, text = text, author = JB.playerName(x), duration = cfg.duration }
    if cfg.radius > 0 then
        local origin = GetEntityCoords(GetPlayerPed(src))
        for _, id in ipairs(GetPlayers()) do
            id = tonumber(id)
            local ped = GetPlayerPed(id)
            if ped and ped ~= 0 and #(GetEntityCoords(ped) - origin) <= cfg.radius then TriggerClientEvent('jobbuilder:client:jobAnnounce', id, payload) end
        end
    else
        TriggerClientEvent('jobbuilder:client:jobAnnounce', -1, payload)
    end
    MySQL.insert('INSERT INTO jobbuilder_announces (job_name, author, kind, title, text) VALUES (?, ?, ?, ?, ?)', { job.name, JB.playerName(x), t.id, title, text })
    JB.log(job.name, x, 'job_announce', ('[%s] %s'):format(t.label, title))
    cb({ ok = true })
end)
