-- Appels vocaux (pma-voice, mumble-voip, saltychat ou hooks perso) et réponse rapide hors interface
local muted = false

RegisterNetEvent('aura:client:callConnect', function(d)
    Phone.inCall = true; Phone.ringing = false
    muted = false
    Bridge.VoiceStart(d.channel, d.peer)
    Phone.UpdateAnim()
end)

RegisterNetEvent('aura:client:callEnd', function()
    Phone.inCall = false; Phone.ringing = false
    Bridge.VoiceStop()
    if muted then muted = false; NetworkSetVoiceActive(true) end
    Phone.UpdateAnim()
end)

RegisterNetEvent('aura:client:incomingCall', function(d)
    if not d.silent then Phone.ringing = true end
end)

RegisterNUICallback('callMute', function(d, cb)
    muted = d and d.state and true or false
    pcall(function() MumbleSetVolumeOverrideByServerId(-1, -1.0) end)
    NetworkSetVoiceActive(not muted)
    cb(1)
end)

-- réponse / refus sans ouvrir le téléphone
local function answer()
    if not Phone.ringing then return end
    SendNUIMessage({ action = 'quickAnswer' })
end
local function decline()
    if not (Phone.ringing or Phone.inCall) then return end
    SendNUIMessage({ action = 'quickDecline' })
end
RegisterCommand('+aura_answer', answer, false); RegisterCommand('-aura_answer', function() end, false)
RegisterCommand('+aura_decline', decline, false); RegisterCommand('-aura_decline', function() end, false)
RegisterKeyMapping('+aura_answer', 'Téléphone : décrocher', 'keyboard', 'UP')
RegisterKeyMapping('+aura_decline', 'Téléphone : raccrocher / refuser', 'keyboard', 'DOWN')

RegisterNUICallback('callState', function(d, cb)
    Phone.ringing = d and d.ringing and true or false
    cb(1)
end)
