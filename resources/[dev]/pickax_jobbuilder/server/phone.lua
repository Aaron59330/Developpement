-- ─────────────────────────────── Téléphone Aura (pickax_phone) ───────────────────────────────
-- Chaque job créé dans le builder devient une « ligne » joignable depuis l'application Services du téléphone :
-- appel vocal (le premier employé qui décroche) et/ou alerte avec position. Les jobs sont lus en direct :
-- un job créé ou modifié apparaît tout de suite, sans redémarrage.

local TYPE_STYLE = {
    police     = { icon = 'shield',   color = '#2563eb', number = '911' },
    ems        = { icon = 'heart',    color = '#ef4444', number = '912' },
    mecano     = { icon = 'wrench',   color = '#f59e0b' },
    taxi       = { icon = 'car',      color = '#eab308' },
    realestate = { icon = 'home',     color = '#14b8a6' },
    dealer     = { icon = 'car',      color = '#22c55e' },
    government = { icon = 'bank',     color = '#6366f1' },
    bank       = { icon = 'bank',     color = '#16a34a' },
    bar        = { icon = 'utensils', color = '#b45309' },
    custom     = { icon = 'briefcase', color = '#8b5cf6' },
}

local function members(jobName, minGrade)
    local ok, list = pcall(ESX.GetExtendedPlayers, 'job', jobName)
    local out = {}
    if ok and list then
        for _, m in ipairs(list) do
            if (m.job.grade or 0) >= (minGrade or 0) then out[#out + 1] = m.source end
        end
    end
    return out
end

-- Liste des lignes joignables. Les numéros par défaut (17 / 15) vont au premier job de chaque type concerné.
function JB.phoneLines()
    local names = {}
    for name in pairs(JB.Jobs) do names[#names + 1] = name end
    table.sort(names)
    local used, taken = {}, {}
    for _, name in ipairs(names) do
        local n = (JB.Jobs[name].settings or {}).phone_number
        if n and n ~= '' then taken[n] = true end
    end
    local lines = {}
    for _, name in ipairs(names) do
        local job = JB.Jobs[name]
        local s = job.settings or {}
        if s.phone_enabled ~= false then
            local style = TYPE_STYLE[job.type] or TYPE_STYLE.custom
            local number = s.phone_number or ''
            if number == '' and style.number and not used[job.type] and not taken[style.number] then
                number = style.number; used[job.type] = true; taken[number] = true
            end
            local grade = s.phone_grade or 0
            lines[#lines + 1] = {
                job = name, label = (s.phone_label and s.phone_label ~= '') and s.phone_label or job.label, type = job.type,
                icon = style.icon, color = style.color, number = number, mode = s.phone_mode or 'both', anon = s.phone_anon == true,
                hint = s.phone_hint or '', minGrade = grade, online = #members(name, grade),
            }
        end
    end
    return lines
end

exports('GetPhoneLines', function() return JB.phoneLines() end)
exports('GetJobMembers', function(jobName, minGrade) return members(tostring(jobName), tonumber(minGrade) or 0) end)

-- Alerte d'un citoyen vers un job : alimente la tablette (police) ou les urgences (EMS) si le job en a une,
-- puis renvoie les employés à prévenir sur leur téléphone.
exports('PhoneAlert', function(src, jobName, message, anon)
    local job = JB.Jobs[jobName]
    if not job then return { ok = false, error = 'Service introuvable' } end
    local s = job.settings or {}
    if s.phone_enabled == false then return { ok = false, error = 'Ce service n\'est pas joignable' } end
    if s.phone_mode == 'voice' then return { ok = false, error = 'Ce service se joint uniquement par appel' } end
    local list = members(jobName, s.phone_grade or 0)
    if #list == 0 then return { ok = false, error = 'Aucun employé disponible pour le moment' } end
    local x = ESX.GetPlayerFromId(src)
    local c = GetEntityCoords(GetPlayerPed(src))
    local by = (anon and s.phone_anon) and 'Anonyme' or (x and JB.playerName(x) or 'Citoyen')
    local msg = tostring(message or ''):gsub('%c', ' '):sub(1, 240)
    local handled = false
    if JB.tabletHandles and JB.tabletHandles(job) and JB.tabletAddCall then
        JB.tabletAddCall(jobName, { title = 'Appel citoyen', message = msg ~= '' and msg or 'Demande d\'assistance', kind = 'citizen', x = c.x, y = c.y, z = c.z, by = by })
        handled = true
    elseif job.type == 'ems' and s.ems_tablet_enabled ~= false and JB.emsCreate then
        pcall(JB.emsCreate, src, (by .. ' : ' .. msg):sub(1, 60))
        handled = true
    end
    JB.log(jobName, x, 'phone_alert', msg)
    return { ok = true, members = list, handled = handled, name = by, coords = { x = c.x, y = c.y, z = c.z } }
end)

-- Infos d'un job pour l'application « Entreprise » du téléphone
exports('GetJobInfo', function(jobName)
    local job = JB.Jobs[tostring(jobName)]
    if not job then return nil end
    local grades = {}
    for _, g in ipairs(job.grades or {}) do grades[#grades + 1] = { grade = g.grade, label = g.label, salary = g.salary } end
    return { name = job.name, label = job.label, type = job.type, society = job.society and true or false, bossGrade = tonumber(job.boss_grade) or (#grades - 1), grades = grades }
end)
