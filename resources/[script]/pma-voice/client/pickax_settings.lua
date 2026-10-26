-- Distances de la voix réglables depuis le panel web (Réglages > Voix). N'agit que si un réglage a été modifié (sinon les distances d'origine restent).
AddEventHandler('pickax_settings:changed', function(all, ov)
	if not ov then return end
	local keys = { voice_whisper = 1, voice_normal = 2, voice_shout = 3 }
	local touched = false
	for k, i in pairs(keys) do
		if ov[k] ~= nil and Cfg.voiceModes[i] then Cfg.voiceModes[i][1] = all[k] touched = true end
	end
	if touched and Cfg.voiceModes[mode] and setProximityState then setProximityState(Cfg.voiceModes[mode][1], false) end
end)
