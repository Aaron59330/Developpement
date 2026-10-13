-- ─────────────────────────────── Portes verrouillables (métier / job2-gang / item clé) ───────────────────────────────
WB.Doors = {}          -- [eid:pi] = true (verrouillée) / false
local tokens = {}      -- [eid:pi] = jeton de reverrouillage automatique

local function stateKey(eid, pi) return ('%d:%d'):format(eid, pi) end

local function stateOf(e, pi)
    local k = stateKey(e.id, pi)
    if WB.Doors[k] == nil then WB.Doors[k] = (e.points[pi] and e.points[pi].locked) ~= false end
    return WB.Doors[k]
end

-- Second métier (job2 / gang) : hook Config.GetJob2 sinon xPlayer.job2
local function job2Of(x)
    if Config.GetJob2 then return Config.GetJob2(x) end
    if x.job2 then return x.job2 end
    if x.getJob2 then return x.getJob2() end
end

function WB.doorAllowed(x, a)
    a = a or {}
    local hasJobs, hasJobs2 = next(a.jobs or {}) ~= nil, next(a.jobs2 or {}) ~= nil
    local jobOk = hasJobs and WB.jobAllowed(x, a.jobs) or false
    local job2Ok = false
    if hasJobs2 then
        local j2 = job2Of(x)
        local need = j2 and a.jobs2[j2.name]
        job2Ok = need ~= nil and (tonumber(j2.grade) or 0) >= (tonumber(need) or 0)
    end
    local ok
    if not (hasJobs or hasJobs2) then ok = true
    elseif a.mode == 'all' then ok = (not hasJobs or jobOk) and (not hasJobs2 or job2Ok)   -- métier ET gang
    else ok = jobOk or job2Ok end                                                           -- métier OU gang
    if not ok then return false, 'Tu n\'as pas les accès pour cette porte' end
    if a.item and a.item ~= '' and WB.itemCount(x.source, a.item) < 1 then return false, 'Il te faut : ' .. a.item end
    return true
end

function WB.syncDoors(src)
    local list = {}
    for _, e in pairs(WB.Entities) do
        if e.type == 'doorlock' and e.enabled then
            for i, p in ipairs(e.points) do if p.kind == 'lock' and p.doors and #p.doors > 0 then list[#list + 1] = { eid = e.id, pi = i, locked = stateOf(e, i) } end end
        end
    end
    TriggerClientEvent('worldbuilder:client:doorStates', src, list)
end

local function setState(e, pi, locked)
    WB.Doors[stateKey(e.id, pi)] = locked
    TriggerClientEvent('worldbuilder:client:doorState', -1, e.id, pi, locked)
end

ESX.RegisterServerCallback('worldbuilder:doorlock:toggle', function(src, cb, eid, pi, want)
    local e = WB.Entities[tonumber(eid) or 0]
    local x = ESX.GetPlayerFromId(src)
    pi = tonumber(pi) or 0
    local p = e and e.points[pi]
    if not e or e.type ~= 'doorlock' or not e.enabled or not x or not p or p.kind ~= 'lock' or not p.coords then return cb({ ok = false, error = 'Introuvable' }) end
    -- à portée du point OU d'une des portes (touche d'ouverture : on peut être loin du marker)
    local close = WB.near(src, p.coords, 6.0)
    for _, d in ipairs(p.doors or {}) do if not close and WB.near(src, d, 2.0) then close = true end end
    if not close then return cb({ ok = false, error = 'Trop loin' }) end
    local ok, err = WB.doorAllowed(x, p.access)
    if Config.Doors and Config.Doors.Debug then
        print(('[worldbuilder:door] %s (job=%s/%s) porte %d:%d access=%s -> %s'):format(GetPlayerName(src), x.job and x.job.name, x.job and x.job.grade, e.id, pi, json.encode(p.access or {}), ok and 'AUTORISÉ' or 'REFUSÉ'))
    end
    if not ok then return cb({ ok = false, error = err }) end
    local locked = not stateOf(e, pi)
    if want ~= nil then locked = want == true end
    setState(e, pi, locked)
    WB.stat(e, 'uses', 1)
    WB.log(e, x, locked and 'lock' or 'unlock', p.label ~= '' and p.label or ('porte ' .. pi))
    local k = stateKey(e.id, pi)
    tokens[k] = (tokens[k] or 0) + 1
    if not locked and (p.autoLock or 0) > 0 then
        local token = tokens[k]
        SetTimeout(p.autoLock * 1000, function()
            if tokens[k] == token and WB.Doors[k] == false and WB.Entities[e.id] then setState(e, pi, true) end
        end)
    end
    cb({ ok = true, locked = locked })
end)

-- Une modification du module remet les portes à leur état par défaut
local prev = WB.onEntityChanged
function WB.onEntityChanged(e, deleted)
    if prev then prev(e, deleted) end
    if e.type == 'doorlock' then
        for k in pairs(WB.Doors) do if k:match('^' .. e.id .. ':') then WB.Doors[k] = nil end end
    end
end
