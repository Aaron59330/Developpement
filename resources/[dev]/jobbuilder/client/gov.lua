-- ─────────────────────────────── Gouvernement (client) ───────────────────────────────
for _, n in ipairs({ 'gov:manage', 'gov:money', 'gov:setTaxes', 'gov:grant', 'gov:prime', 'gov:announce' }) do NuiRemote[n] = true end

function OpenGovPanel()
    ESX.TriggerServerCallback('jobbuilder:gov:manage', function(res)
        if not res or not res.ok then return JBNotify('~r~' .. ((res and res.error) or 'Erreur')) end
        OpenUI({ action = 'open', kind = 'gov', data = res })
    end)
end

-- Annonce officielle : bandeau en haut de l'écran (sans prendre le focus)
RegisterNetEvent('jobbuilder:client:announce', function(a)
    SendNUIMessage({ action = 'announce', title = a.title, text = a.text, author = a.author })
    PlaySoundFrontend(-1, 'Event_Message_Purple', 'GTAO_FM_Events_Soundset', true)
end)
