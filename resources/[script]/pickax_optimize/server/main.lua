local C = Config
local function esc(n) return '`' .. tostring(n):gsub('[^%w_]', '') .. '`' end
local created, purged, skipped = {}, {}, {}

local function tableExists(t)
    return MySQL.scalar.await('SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = ? LIMIT 1', { t }) ~= nil
end
local function column(t, c)
    return MySQL.single.await('SELECT data_type AS dt, character_maximum_length AS len FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = ? AND column_name = ?', { t, c })
end
local function hasIndex(t, cols)
    local rows = MySQL.query.await('SELECT index_name AS n, seq_in_index AS s, column_name AS c FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = ?', { t }) or {}
    local idx = {}
    for _, r in ipairs(rows) do idx[r.n] = idx[r.n] or {} idx[r.n][r.s] = r.c end
    for _, seq in pairs(idx) do
        local ok = true
        for i, c in ipairs(cols) do if seq[i] ~= c then ok = false break end end
        if ok then return true end
    end
    return false
end

local BAD = { text = true, tinytext = true, mediumtext = true, longtext = true, blob = true, tinyblob = true, mediumblob = true, longblob = true, json = true }

local function ensureIndex(t, cols)
    if not tableExists(t) then return end
    local parts = {}
    for _, c in ipairs(cols) do
        local info = column(t, c)
        if not info then skipped[#skipped + 1] = ('%s.%s (colonne absente)'):format(t, c) return end
        if BAD[info.dt] then skipped[#skipped + 1] = ('%s.%s (type %s non indexable)'):format(t, c, info.dt) return end
        local isStr = info.dt == 'varchar' or info.dt == 'char'
        parts[#parts + 1] = esc(c) .. ((isStr and (info.len or 0) > 191) and '(191)' or '')
    end
    if hasIndex(t, cols) then return end
    local name = ('idx_pk_%s'):format(table.concat(cols, '_')):sub(1, 60)
    local ok, err = pcall(function() MySQL.query.await(('ALTER TABLE %s ADD INDEX %s (%s)'):format(esc(t), esc(name), table.concat(parts, ', '))) end)
    if ok then created[#created + 1] = ('%s(%s)'):format(t, table.concat(cols, ',')) else skipped[#skipped + 1] = ('%s : %s'):format(t, tostring(err):sub(1, 80)) end
end

local function purge(t, days)
    if not tableExists(t) then return end
    for _, c in ipairs(C.PurgeDateColumns) do
        local info = column(t, c)
        if info then
            local dt = info.dt
            local rows
            if dt == 'timestamp' or dt == 'datetime' or dt == 'date' then
                rows = MySQL.update.await(('DELETE FROM %s WHERE %s < (NOW() - INTERVAL ? DAY) LIMIT 20000'):format(esc(t), esc(c)), { days })
            elseif dt == 'int' or dt == 'bigint' then
                local limit = os.time() - days * 86400
                rows = MySQL.update.await(('DELETE FROM %s WHERE %s < ? AND %s > 1000000000 LIMIT 20000'):format(esc(t), esc(c), esc(c)), { limit })
            end
            if rows ~= nil then if rows > 0 then purged[#purged + 1] = ('%s : %d ligne(s) de plus de %d j'):format(t, rows, days) end return end
        end
    end
end

local function run()
    created, purged, skipped = {}, {}, {}
    local t0 = os.clock()
    for _, e in ipairs(C.Indexes) do pcall(ensureIndex, e[1], e[2]) end
    for _, e in ipairs(C.Purge) do pcall(purge, e[1], e[2]) end
    local ms = math.floor((os.clock() - t0) * 1000)
    print(('^2[pickax_optimize]^7 index créés : %d · journaux purgés : %d · ignorés : %d · %d ms'):format(#created, #purged, #skipped, ms))
    for _, l in ipairs(created) do print('  + index ' .. l) end
    for _, l in ipairs(purged) do print('  - purge ' .. l) end
end

CreateThread(function()
    if not C.RunOnStart then return end
    Wait(C.StartDelay)
    pcall(run)
end)

-- ───────── diagnostic : /pickaxdoctor ─────────
local function doctor(reply)
    local lines = {}
    local states, bad = {}, {}
    for i = 0, GetNumResources() - 1 do
        local r = GetResourceByFindIndex(i)
        if r and r:find('^pickax_') or r == 'ox_inventory' or r == 'es_extended' or r == 'oxmysql' or r == 'ox_lib' then
            local st = GetResourceState(r)
            states[st] = (states[st] or 0) + 1
            if st ~= 'started' then bad[#bad + 1] = ('%s (%s)'):format(r, st) end
        end
    end
    lines[#lines + 1] = ('Ressources clés : %s'):format((function() local o = {} for k, v in pairs(states) do o[#o + 1] = ('%d %s'):format(v, k) end return table.concat(o, ' · ') end)())
    if #bad > 0 then lines[#lines + 1] = '^1Non démarrées : ^7' .. table.concat(bad, ', ') end
    local st = exports[GetCurrentResourceName()]:CacheStats()
    lines[#lines + 1] = ('Cache : %d entrées · %d succès · %d échecs'):format(st.entries, st.hits, st.misses)
    lines[#lines + 1] = ('Mémoire Lua (cette ressource) : %.1f Mo · joueurs : %d'):format(collectgarbage('count') / 1024, #GetPlayers())
    lines[#lines + 1] = ('Index créés au dernier passage : %d · journaux purgés : %d · ignorés : %d'):format(#created, #purged, #skipped)
    for _, s in ipairs(skipped) do lines[#lines + 1] = '  ignoré : ' .. s end
    lines[#lines + 1] = 'Pour trouver les ressources lentes : console F8 → resmon 1 (colonne CPU) ; serveur : profiler record 500 puis profiler view.'
    for _, l in ipairs(lines) do reply(l) end
end

RegisterCommand('pickaxdoctor', function(src, args)
    if src ~= 0 then
        local ok = false
        local okE, ESX = pcall(function() return exports['es_extended']:getSharedObject() end)
        if okE and ESX then local x = ESX.GetPlayerFromId(src) ok = x and Config.AdminGroups[x.getGroup()] == true end
        if not ok then return end
    end
    if args[1] == 'run' then pcall(run) end
    doctor(function(l) if src == 0 then print('[pickax_optimize] ' .. l) else TriggerClientEvent('chat:addMessage', src, { args = { 'optimize', l } }) end end)
end, false)
