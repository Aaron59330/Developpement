local ESX = exports['es_extended']:getSharedObject()
local open = false

local function toggle()
    if open then
        open = false SetNuiFocus(false, false) SendNUIMessage({ a = 'close' })
        return
    end
    ESX.TriggerServerCallback('pickax_xp:info', function(d)
        if not d or not d.ok then return end
        open = true
        SetNuiFocus(true, true)
        SendNUIMessage({ a = 'open', d = d })
    end)
end
RegisterCommand('pickax_xp_ouvrir', toggle, false)
RegisterKeyMapping('pickax_xp_ouvrir', 'Niveau et récompenses', 'keyboard', Config.Key or 'F4')
exports('Open', toggle)

RegisterNUICallback('close', function(_, cb) open = false SetNuiFocus(false, false) cb(1) end)

-- Gain d'XP : une seule notification regroupée
RegisterNetEvent('pickax_xp:gain', function(xp, parts, total, level, floor, nextXp)
    local txt = ('+%d XP · %s'):format(xp, table.concat(parts, ', '))
    TriggerEvent('pickax_notify:notify', { type = 'inform', title = ('Niveau %d'):format(level), description = txt })
end)

RegisterNetEvent('pickax_xp:levelup', function(level, rewards)
    local r = (#rewards > 0) and ('Récompense : ' .. table.concat(rewards, ' · ')) or 'Continue comme ça !'
    TriggerEvent('pickax_notify:notify', { type = 'success', title = ('NIVEAU %d ATTEINT'):format(level), description = r })
    PlaySoundFrontend(-1, 'RANK_UP', 'HUD_AWARDS', true)
end)
