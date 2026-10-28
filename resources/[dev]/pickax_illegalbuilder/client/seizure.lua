-- ─────────────────────────────── Perquisitions (client) ───────────────────────────────
-- Utilisé par le menu contextuel (pickax_core, clic sur un joueur → Perquisition) : exports StreetAvailable-like pour les policiers.
local function isPolice()
    local job = ESX.PlayerData and ESX.PlayerData.job and ESX.PlayerData.job.name
    for _, j in ipairs(Config.PoliceJobs or {}) do if j == job then return true end end
    return false
end

exports('SeizureAvailable', function() return (Config.Seizure or {}).Enabled ~= false and isPolice() end)

local function targetId(ped)
    if not ped or not DoesEntityExist(ped) or not IsPedAPlayer(ped) then return nil end
    local idx = NetworkGetPlayerIndexFromPed(ped)
    return idx and idx ~= -1 and GetPlayerServerId(idx) or nil
end

local function label(item)
    local ok, items = pcall(function() return exports.ox_inventory:Items() end)
    return ok and items and items[item] and items[item].label or item
end

local function describe(items, black)
    local parts = {}
    for _, it in ipairs(items or {}) do parts[#parts + 1] = ('%d × %s'):format(it.count, label(it.item)) end
    if (black or 0) > 0 then parts[#parts + 1] = ('%d $ d\'argent sale'):format(black) end
    return #parts > 0 and table.concat(parts, ', ') or nil
end

exports('Inspect', function(ped)
    local id = targetId(ped)
    if not id then return end
    ESX.TriggerServerCallback('illegalbuilder:seize:inspect', function(r)
        if not r or not r.ok then return Notify((r and r.error) or 'Impossible', 'error') end
        local d = describe(r.items, r.black)
        Notify(d and ('%s porte : %s'):format(r.name or 'Le suspect', d) or 'Rien d\'illégal sur lui.', d and 'warning' or 'info')
    end, id)
end)

exports('Seize', function(ped)
    local id = targetId(ped)
    if not id then return end
    ESX.TriggerServerCallback('illegalbuilder:seize:take', function(r)
        if not r or not r.ok then return Notify((r and r.error) or 'Impossible', 'error') end
        if r.nothing then return Notify('Rien à saisir.', 'info') end
        Notify(('Saisi : %s'):format(describe(r.items, r.black) or '—'), 'success')
    end, id)
end)
