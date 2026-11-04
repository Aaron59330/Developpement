local ESX = exports['es_extended']:getSharedObject()
local open = false

local function toggle()
    if open then
        open = false SetNuiFocusKeepInput(false) SetNuiFocus(false, false) SendNUIMessage({ a = 'close' })
        return
    end
    ESX.TriggerServerCallback('pickax_xp:info', function(d)
        if not d or not d.ok then return end
        open = true
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(true)   -- la touche F4 continue d'arriver au jeu : elle referme l'écran
        SendNUIMessage({ a = 'open', d = d })
    end)
end
RegisterCommand('pickax_xp_ouvrir', toggle, false)
RegisterKeyMapping('pickax_xp_ouvrir', 'Niveau et récompenses', 'keyboard', Config.Key or 'F4')
exports('Open', toggle)

RegisterNUICallback('close', function(_, cb) open = false SetNuiFocusKeepInput(false) SetNuiFocus(false, false) SendNUIMessage({ a = 'close' }) cb(1) end)

-- Pendant que l'écran est ouvert : pas de caméra, de tir, de déplacement ni de menu pause (Échap ferme l'écran, pas le jeu)
CreateThread(function()
    while true do
        if open then
            for _, c in ipairs({ 1, 2, 14, 15, 16, 17, 24, 25, 30, 31, 32, 33, 34, 35, 36, 37, 44, 140, 141, 142, 199, 200, 257 }) do DisableControlAction(0, c, true) end
            if IsDisabledControlJustPressed(0, 200) or IsDisabledControlJustPressed(0, 199) then toggle() end
            Wait(0)
        else Wait(300) end
    end
end)
AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() and open then SetNuiFocus(false, false) end end)

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
