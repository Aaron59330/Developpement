-- ─────────────────────────────── Tablette police & annonces d'entreprise (client) ───────────────────────────────
for _, n in ipairs({ 'tablet:open', 'tablet:live', 'records:search', 'records:get', 'records:save', 'records:delete', 'records:addEntry', 'records:delEntry', 'records:fromNearest',
    'fine:send', 'dispatch:create', 'dispatch:take', 'dispatch:close', 'dispatch:delete', 'pursuit:nearby', 'pursuit:start', 'pursuit:stop',
    'announce:open', 'announce:send' }) do NuiRemote[n] = true end

-- ── Alerte dispatch : notification, son, blip temporaire sur la carte du jeu ──
RegisterNetEvent('jobbuilder:client:dispatchAlert', function(a)
    local tag = ({ panic = '~r~[PANIQUE]~s~', pursuit = '~o~[POURSUITE]~s~', citizen = '~b~[APPEL]~s~', officer = '~b~[DISPATCH]~s~' })[a.kind] or '~b~[DISPATCH]~s~'
    ESX.ShowNotification(('%s ~h~%s~h~\n%s'):format(tag, a.title or '', a.message or ''))
    PlaySoundFrontend(-1, a.kind == 'panic' and 'Beep_Red' or 'Menu_Accept', a.kind == 'panic' and 'DLC_HEIST_HACKING_SNAKE_SOUNDS' or 'Phone_SoundSet_Default', true)
    if a.x and a.y and (a.x ~= 0.0 or a.y ~= 0.0) then
        local blip = AddBlipForCoord(a.x + 0.0, a.y + 0.0, (a.z or 0.0) + 0.0)
        SetBlipSprite(blip, a.kind == 'panic' and 161 or 280)
        SetBlipColour(blip, a.kind == 'panic' and 1 or 3)
        SetBlipScale(blip, 1.0)
        SetBlipAsShortRange(blip, false)
        SetBlipFlashes(blip, true)
        BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName(a.title or 'Appel') EndTextCommandSetBlipName(blip)
        SetTimeout(60000, function() if DoesBlipExist(blip) then RemoveBlip(blip) end end)
    end
end)

-- ── Poursuite : le fugitif apparaît sur la carte du jeu de tous les membres du job ──
local chaseBlip
RegisterNetEvent('jobbuilder:client:pursuit', function(p)
    if not p or not p.active then
        if chaseBlip and DoesBlipExist(chaseBlip) then RemoveBlip(chaseBlip) end
        chaseBlip = nil
        return
    end
    if not chaseBlip or not DoesBlipExist(chaseBlip) then
        chaseBlip = AddBlipForCoord(p.x + 0.0, p.y + 0.0, p.z + 0.0)
        SetBlipSprite(chaseBlip, 225)
        SetBlipColour(chaseBlip, 1)
        SetBlipScale(chaseBlip, 1.1)
        SetBlipFlashes(chaseBlip, true)
        SetBlipAsShortRange(chaseBlip, false)
        BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName('Fugitif : ' .. (p.name or '?')) EndTextCommandSetBlipName(chaseBlip)
    end
    SetBlipCoords(chaseBlip, p.x + 0.0, p.y + 0.0, p.z + 0.0)
end)

-- ── Annonce d'entreprise (bandeau). /annonces pour masquer / réafficher ──
local function announcesHidden() return GetResourceKvpInt('jobbuilder_hide_announces') == 1 end

RegisterNetEvent('jobbuilder:client:jobAnnounce', function(a)
    if announcesHidden() then return end
    SendNUIMessage({ action = 'announce', title = a.title, text = a.text, author = a.author, jobLabel = a.jobLabel, kindLabel = a.kindLabel, color = a.color, duration = a.duration })
    PlaySoundFrontend(-1, 'Event_Message_Purple', 'GTAO_FM_Events_Soundset', true)
end)

RegisterCommand(Config.Announce.ToggleCommand, function()
    local hide = not announcesHidden()
    SetResourceKvpInt('jobbuilder_hide_announces', hide and 1 or 0)
    ESX.ShowNotification(hide and 'Annonces d\'entreprise ~r~masquées~s~.' or 'Annonces d\'entreprise ~g~affichées~s~.')
end, false)

TriggerEvent('chat:addSuggestion', '/' .. Config.Police.CallCommand, 'Appeler les forces de l\'ordre', { { name = 'message', help = 'Décris la situation' } })
TriggerEvent('chat:addSuggestion', '/' .. Config.Police.PanicCommand, 'Appel à l\'aide (policiers)')
TriggerEvent('chat:addSuggestion', '/' .. Config.Announce.ToggleCommand, 'Masquer / afficher les annonces d\'entreprise')
