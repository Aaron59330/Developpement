-- Joueurs dont le skin enregistré a été réappliqué cette session (voir SkinMarkReady côté client)
local skinReady = {}
RegisterServerEvent('CorePickax:skin:ready')
AddEventHandler('CorePickax:skin:ready', function() skinReady[source] = true end)
AddEventHandler('playerDropped', function() skinReady[source] = nil end)
-- Redémarrage de la ressource avec des joueurs déjà connectés (leur skin est déjà appliqué) : rien à protéger
AddEventHandler('onResourceStart', function(res)
	if res ~= GetCurrentResourceName() then return end
	for _, id in ipairs(GetPlayers()) do skinReady[tonumber(id)] = true end
end)
-- Filet de sécurité : si le client n'a jamais confirmé (cas imprévu), l'enregistrement est autorisé 40 s après le chargement du joueur
AddEventHandler('esx:playerLoaded', function(playerId)
	SetTimeout(40000, function() if GetPlayerName(playerId) then skinReady[playerId] = true end end)
end)

RegisterServerEvent('esx_skin:save')
AddEventHandler('esx_skin:save', function(skin)
	local xPlayer = ESX.GetPlayerFromId(source)
	if not xPlayer or type(skin) ~= 'table' then return end
	if not skinReady[source] then
		print(('^3[skinchanger] enregistrement du skin refusé pour %s : le skin enregistré n\'a pas encore été réappliqué (protection contre l\'écrasement)^0'):format(xPlayer.identifier))
		return
	end

	MySQL.Async.execute('UPDATE users SET skin = @skin WHERE identifier = @identifier', {
		['@skin'] = json.encode(skin),
		['@identifier'] = xPlayer.identifier
	})
end)

ESX.RegisterServerCallback('esx_skin:getPlayerSkin', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT skin FROM users WHERE identifier = @identifier', {
		['@identifier'] = xPlayer.identifier
	}, function(users)
		local user, skin = users[1]

		local jobSkin = {
			skin_male = xPlayer.job.skin_male,
			skin_female = xPlayer.job.skin_female
		}

		if user.skin then
			skin = json.decode(user.skin)
		end

		cb(skin, jobSkin)
	end)
end)

RegisterCommand('skin', function(source, args, user)
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.getGroup() == "superadmin" or xPlayer.getGroup() == "_dev" then
		if args[1] == nil then
			TriggerClientEvent('CorePickax:Creator:openSkinMenu', source)
		else
			TriggerClientEvent('CorePickax:Creator:openSkinMenu', args[1])
		end
	end
end, false)

-- Création du personnage : le style de tenue choisi est donné comme tenue complète (item « Tenue » de p_outfits) et déjà portée.
-- Le serveur lit lui-même le style dans ConfigCreationOutfits (le client n'envoie que son numéro) ; une seule fois par joueur et par session.
local creationOutfitGiven = {}

RegisterServerEvent('CorePickax:creation:giveOutfit')
AddEventHandler('CorePickax:creation:giveOutfit', function(styleIndex)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	local cfg = ConfigCreationOutfits
	if not xPlayer or not cfg or not cfg.Enabled or GetResourceState('p_outfits') ~= 'started' or GetResourceState('ox_inventory') ~= 'started' then return end
	if creationOutfitGiven[xPlayer.identifier] then return end

	local style = cfg.Styles and cfg.Styles[tonumber(styleIndex) or 0]
	if not style then return end
	local ped = GetPlayerPed(src)
	local male = ped and ped ~= 0 and GetEntityModel(ped) == 1885233650
	local outfit = male and style.male or style.female
	if not outfit then return end

	creationOutfitGiven[xPlayer.identifier] = true
	local ok = exports.p_outfits:giveEquipped(src, outfit, ('Tenue — %s'):format(style.label or 'Départ'))
	if not ok then print(('^3[CorePickax] tenue de départ non équipée pour %s (case Tenue / p_outfits indisponible)^0'):format(xPlayer.identifier)) end
end)
