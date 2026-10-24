-- ─────────────────────────────── Prise de service ───────────────────────────────
-- Un joueur doit PRENDRE SON SERVICE (menu F6 → « Prendre son service ») pour accéder à son menu F6 complet et aux points de son métier.
-- « En ligne » (statut d'une entreprise) = au moins un employé en service ; « hors ligne » = personne en service.
JB.Duty = {}   -- [source] = nom du job pour lequel le joueur est en service

function JB.isOnDuty(src)
    local x = ESX.GetPlayerFromId(src)
    if not x then return false end
    if JB.Duty[src] ~= x.job.name then
        if JB.Duty[src] then JB.Duty[src] = nil Player(src).state:set('jbDuty', false, true) end
        return false
    end
    return true
end

local function setDuty(src, on)
    local x = ESX.GetPlayerFromId(src)
    if not x then return false end
    JB.Duty[src] = on and x.job.name or nil
    Player(src).state:set('jbDuty', on and true or false, true)
    return true
end

-- plus de service si le métier change ou si le joueur part
AddEventHandler('esx:setJob', function(src) if JB.Duty[src] then setDuty(src, false) end end)
AddEventHandler('playerDropped', function() JB.Duty[source] = nil end)
AddEventHandler('esx:playerLoaded', function(src) Player(src).state:set('jbDuty', false, true) end)

ESX.RegisterServerCallback('jobbuilder:duty:toggle', function(src, cb, want)
    local x = ESX.GetPlayerFromId(src)
    if not x or not JB.Jobs[x.job.name] then return cb({ ok = false, error = 'Tu n\'as pas de métier.' }) end
    local on = want == true
    setDuty(src, on)
    if JB.log then pcall(JB.log, x.job.name, x, on and 'duty_on' or 'duty_off') end
    cb({ ok = true, duty = on })
end)

-- Statut de toutes les entreprises : en ligne si au moins un employé est en service
function JB.dutyStatus()
    local counts = {}
    for _, id in ipairs(GetPlayers()) do
        id = tonumber(id)
        if JB.isOnDuty(id) then
            local x = ESX.GetPlayerFromId(id)
            counts[x.job.name] = (counts[x.job.name] or 0) + 1
        end
    end
    local list = {}
    for name, job in pairs(JB.Jobs or {}) do
        list[#list + 1] = { name = name, label = job.label or name, type = job.type, count = counts[name] or 0, online = (counts[name] or 0) > 0 }
    end
    table.sort(list, function(a, b) if a.online ~= b.online then return a.online end return tostring(a.label):lower() < tostring(b.label):lower() end)
    return list
end

ESX.RegisterServerCallback('jobbuilder:dutyStatus', function(src, cb) cb(JB.dutyStatus()) end)
exports('GetDutyStatus', function() return JB.dutyStatus() end)
exports('IsOnDuty', function(src) return JB.isOnDuty(tonumber(src) or 0) end)
