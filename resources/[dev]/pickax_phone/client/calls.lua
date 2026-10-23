-- Appels vocaux (pma-voice) et réponse rapide hors interface
local channel = 0
local muted = false

local function setChannel(id)
    channel = id
    local ok = pcall(function() exports[Config.Calls.voiceResource]:setCallChannel(id) end)
    if not ok and Config.Debug then print('^3[pickax_phone] ' .. Config.Calls.voiceResource .. ' introuvable : pas de voix pour les appels^7') end
end

RegisterNetEvent('aura:client:callConnect', function(d)
    Phone.inCall = true; Phone.ringing = false
    muted = false
    setChannel(d.channel)
    Phone.UpdateAnim()
end)

RegisterNetEvent('aura:client:callEnd', function()
    Phone.inCall = false; Phone.ringing = false
    setChannel(0)
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
