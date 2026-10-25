local open = false

local function norm(k)
    k = tostring(k or ''):gsub('^t_', ''):gsub('^b_', 'Souris '):gsub('^w_', 'Molette '):gsub('^%s+', ''):gsub('%s+$', '')
    if k == '' or k == 'null' or k == 'NULL' or k:lower() == 'unbound' or k == '~' then return '' end
    return k:upper()
end

-- Touche réellement attribuée à une commande enregistrée par RegisterKeyMapping (reflète les choix du joueur dans les paramètres FiveM)
local function keyOf(cmd)
    local ok, v = pcall(GetControlInstructionalButton, 0, GetHashKey(cmd) | 0x80000000, true)
    return ok and norm(v) or ''
end

local function snapshot()
    local list, byKey = {}, {}
    for i, a in ipairs(Config.Actions) do
        local k = keyOf(a.cmd)
        list[i] = { group = a.group, label = a.label, cmd = a.cmd, default = (a.default or ''):upper(), key = k, changed = k ~= '' and (a.default or ''):upper() ~= '' and k ~= (a.default or ''):upper() }
        if k ~= '' then byKey[k] = byKey[k] or {} byKey[k][#byKey[k] + 1] = i end
    end
    local conflicts = {}
    for k, ids in pairs(byKey) do
        if #ids > 1 then
            local names = {}
            for _, id in ipairs(ids) do list[id].conflict = true names[#names + 1] = list[id].label end
            conflicts[#conflicts + 1] = { key = k, names = names }
        end
    end
    table.sort(conflicts, function(a, b) return a.key < b.key end)
    return { actions = list, conflicts = conflicts }
end

exports('GetKey', function(cmd) local k = keyOf(cmd) return k ~= '' and k or nil end)
exports('GetConflicts', function() return snapshot().conflicts end)

local function close()
    if not open then return end
    open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterCommand(Config.Command, function()
    if open then return close() end
    open = true
    SetNuiFocus(true, true)
    local d = snapshot()
    d.action = 'open'
    SendNUIMessage(d)
end, false)

RegisterNUICallback('refresh', function(_, cb) cb(snapshot()) end)
RegisterNUICallback('close', function(_, cb) cb(1) close() end)
AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() and open then SetNuiFocus(false, false) end end)
