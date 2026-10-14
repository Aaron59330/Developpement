local MenuNameBLC = {
	['skin_menu'] = 'Modification personnage',
	['use_rotate_view'] = 'Utilisez ~INPUT_VEH_FLY_ROLL_LEFT_ONLY~ et ~INPUT_VEH_FLY_ROLL_RIGHT_ONLY~ pour tourner la vue.',
	['skin'] = 'Changer de skin',
	['saveskin'] = 'Sauvegarder skin dans un fichier',
	['confirm_escape'] = 'Voulez vous quitter la modification de personnage? Les changements ne seront pas sauvegardés.',
	['no'] = 'Non',
	['yes'] = 'Oui',
	['sex'] = 'Sexe',
	['face'] = 'Visage',
	['skin'] = 'Peau',
	['wrinkles'] = 'Rides',
	['wrinkle_thickness'] = 'Épaisseur rides',
	['beard_type'] = 'Type barbe',
	['beard_size'] = 'Taille barbe',
	['beard_color_1'] = 'Couleur barbe 1',
	['beard_color_2'] = 'Couleur barbe 2',
	['hair_1'] = 'Cheveux 1',
	['hair_2'] = 'Cheveux 2',
	['hair_color_1'] = 'Couleur cheveux 1',
	['hair_color_2'] = 'Couleur cheveux 2',
	['eye_color'] = 'Lentilles colorées',
	['eyebrow_type'] = 'Type sourcils',
	['eyebrow_size'] = 'Taille sourcils',
	['eyebrow_color_1'] = 'Couleur sourcils 1',
	['eyebrow_color_2'] = 'Couleur sourcils 2',
	['makeup_type'] = 'Type maquillage',
	['makeup_thickness'] = 'Épaisseur maquillage',
	['makeup_color_1'] = 'Couleur maquillage 1',
	['makeup_color_2'] = 'Couleur maquillage 2',
	['lipstick_type'] = 'Type lipstick',
	['lipstick_thickness'] = 'Épaisseur lipstick',
	['lipstick_color_1'] = 'Couleur lipstick 1',
	['lipstick_color_2'] = 'Couleur lipstick 2',
	['ear_accessories'] = 'Accessoire oreilles',
	['ear_accessories_color'] = 'Couleur accessoire',
	['tshirt_1'] = 'T-Shirt 1',
	['tshirt_2'] = 'T-Shirt 2',
	['torso_1'] = 'Torse 1',
	['torso_2'] = 'Torse 2',
	['decals_1'] = 'Calques 1',
	['decals_2'] = 'Calques 2',
	['arms'] = 'Bras',
	['arms_2'] = 'Bras 2',
	['pants_1'] = 'Jambes 1',
	['pants_2'] = 'Jambes 2',
	['shoes_1'] = 'Chaussures 1',
	['shoes_2'] = 'Chaussures 2',
	['mask_1'] = 'Masque 1',
	['mask_2'] = 'Masque 2',
	['bproof_1'] = 'Gilet pare-balle 1',
	['bproof_2'] = 'Gilet pare-balle 2',
	['chain_1'] = 'Chaine 1',
	['chain_2'] = 'Chaine 2',
	['helmet_1'] = 'Casque 1',
	['helmet_2'] = 'Casque 2',
	['watches_1'] = 'Montre 1',
	['watches_2'] = 'Montre 2',
	['bracelets_1'] = 'Bracelet 1',
	['bracelets_2'] = 'Bracelet 2',
	['glasses_1'] = 'Lunettes 1',
	['glasses_2'] = 'Lunettes 2',
	['bag'] = 'Sac',
	['bag_color'] = 'Couleur sac',
	['blemishes'] = 'Boutons',
	['blemishes_size']= 'Opacité des boutons',
	['ageing'] = 'Vieillissement',
	['ageing_1'] = 'Opacité du vieillissement',
	['blush'] = 'Rougeur',
	['blush_1'] = 'Opacité rougeur',
	['blush_color'] = 'Couleur rougeur',
	['complexion'] = 'Teint',
	['complexion_1'] = 'Opacité teint',
	['sun'] = 'Dommages UV',
	['sun_1'] = 'Opacité dommages UV',
	['freckles'] = 'Taches de rousseur',
	['freckles_1'] = 'Opacité rousseur',
	['chest_hair'] = 'Pillositée torse',
	['chest_hair_1'] = 'Opacité pillositée',
	['chest_color'] = 'Couleur pillositée',
	['bodyb_size'] = 'Imperfections',
	['bodyb'] = 'Opacité des imperfections',
	['mom'] = "Mère",			
	['dad'] = "Père",			
	['resemblance'] = "Ressemblance",	
	['skin_tone'] = "Couleur de peau",		
	['nose_1'] = "Nez 1",			
	['nose_2'] = "Nez 2",		
	['nose_3'] = "Nez 3",		
	['nose_4'] = "Nez 4",		
	['nose_5'] = "Nez 5",		
	['nose_6'] = "Nez 6",		
	['cheeks_1'] = "Joues",		
	['cheeks_2'] = "Joues 2",
	['cheeks_3'] = "Joues 3",
	['lip_fullness'] = "Plénitude des lèvres",	
	['jaw_bone_width'] = "Largeur de l'os de la mâchoire",	
	['jaw_bone_length'] = "Longueur de l'os de la mâchoire",
	['chin_height'] = "Hauteur du menton",	
	['chin_length'] = "Longueur du menton",	
	['chin_width'] = "Largeur menton",		
	['chin_hole'] = "Mentonnière",		
	['neck_thickness'] = "Épaisseur du cou",	
}

local open = false
local indexface2 = {}
local comp = {}
local isCameraActive = false
local FirstSpawn, zoomOffset, camOffset, heading = true, 0.0, 0.0, 90.0

function RefreshData()
    TriggerEvent("skinchanger:getData", function(comp_, max)
        open = true
        comp = comp_
        for k,v in pairs(comp) do
            if v.value ~= 0 then
                indexface2[v.name] = v.value + 1
            else
                indexface2[v.name] = 1
            end
            for i,value in pairs(max) do
                if i == v.name then
                    comp[k].max = value
                    comp[k].table = {}
                    for i = 0, value do
                        table.insert(comp[k].table, i)
                    end
                    break
                end
            end
        end
    end)
end

-- Éléments « vêtements / accessoires » : retirés du menu de création (le joueur ne règle que son apparence ;
-- la tenue se choisit ensuite parmi les styles de ConfigCreationOutfits)
CreationClothes = {
	tshirt_1 = true, tshirt_2 = true, torso_1 = true, torso_2 = true, decals_1 = true, decals_2 = true, arms = true, arms_2 = true,
	pants_1 = true, pants_2 = true, shoes_1 = true, shoes_2 = true, mask_1 = true, mask_2 = true, bproof_1 = true, bproof_2 = true,
	chain_1 = true, chain_2 = true, helmet_1 = true, helmet_2 = true, glasses_1 = true, glasses_2 = true, watches_1 = true, watches_2 = true,
	bracelets_1 = true, bracelets_2 = true, bags_1 = true, bags_2 = true, ears_1 = true, ears_2 = true,
}

InRegisterMenu = false
local sexLocked = false      -- vrai pendant la création : le sexe choisi sur la carte d'identité ne peut plus être changé
local skinFinished = false   -- vrai dès que le personnage est validé : tous les menus de création (imbriqués) se terminent d'un coup
function SkinChanger()
    local face = RageUI.CreateMenu("Menu création", "Faite votre personnage")
    RageUI.Visible(face, not RageUI.Visible(face))
	FreezeEntityPosition(GetPlayerPed(-1), true)
	InRegisterMenu = true
	skinFinished = false
    while face and not skinFinished do
        Citizen.Wait(0)
        RageUI.IsVisible(face, true, true, true, function()
            for k,v in pairs(comp) do
				zoomOffset = comp[1].zoomOffset
				camOffset = comp[1].camOffset
                if v.table[1] ~= nil and not CreationClothes[v.name] and not (sexLocked and v.name == 'sex') then
					RageUI.List(v.label, v.table, indexface2[v.name], nil, {}, true, function(Hovered, Active, Selected, Index)
						indexface2[v.name] = Index;
						TriggerEvent("skinchanger:change", v.name, Index - 1)
						if v.componentId ~= nil then
							SetPedComponentVariation(GetPlayerPed(-1), v.componentId, Index - 1, 0, 2)
						end

						if Active then
							zoomOffset = comp[k].zoomOffset
                            camOffset = comp[k].camOffset
						end

						if Selected and not skinFinished then
							openValidate()
						end
					end)
                end
            end
        end, function()
		end)
        if not RageUI.Visible(face) then
			FreezeEntityPosition(GetPlayerPed(-1), false)
			InRegisterMenu = false
			if not skinFinished then
				-- Menu fermé sans « Valider » : on enregistre quand même l'apparence en cours (rien n'est perdu à la reconnexion)
				TriggerEvent('skinchanger:getSkin', function(skin) TriggerServerEvent('esx_skin:save', skin) end)
			end
            face = RMenu:DeleteType('face', true)
        end
    end
	-- Personnage validé : on ferme proprement le menu de création (un seul appui sur « Valider » suffit)
	if skinFinished then
		RageUI.CloseAll()
		FreezeEntityPosition(GetPlayerPed(-1), false)
		InRegisterMenu = false
	end
end

function openValidate()
    local face = RageUI.CreateMenu("Menu création", "Faite votre personnage")
    RageUI.Visible(face, not RageUI.Visible(face))
    while face and not skinFinished do
        Citizen.Wait(0)
        RageUI.IsVisible(face, true, true, true, function()
			RageUI.ButtonWithStyle('Continuer de modifier mon apparence', nil, {RightLabel = "→→→"}, true, function(_,_,s)
				if s then
					RefreshData()
					SkinChanger()
				end
			end)
			RageUI.ButtonWithStyle('~g~Valider mon apparence', nil, {RightLabel = "→→→"}, true, function(_,_,s)
				if s and not skinFinished then
					skinFinished = true
					RageUI.CloseAll()
					-- Étape suivante : choix de la tenue, puis fin de la création
					Citizen.CreateThread(CreationOutfitFlow)
				end
			end)
        end, function()
    end)
        if not RageUI.Visible(face) then
			FreezeEntityPosition(GetPlayerPed(-1), false)
            face = RMenu:DeleteType('face', true)
        end
    end
end

-- Fin de la création : enregistre le skin, donne les vêtements en items (inventaire), prévient esx_identity (menu Destination)
function CreationFinish()
	TriggerEvent('skinchanger:getSkin', function(skin)
		TriggerServerEvent('esx_skin:save', skin)
		TriggerEvent('skinchanger:loadSkin', skin)
		if CreationChosenStyle and GetResourceState('p_outfits') == 'started' then
			-- Le style choisi est donné comme tenue complète (item Tenue) et déjà portée : le serveur équipe les 14 pièces
			TriggerServerEvent('CorePickax:creation:giveOutfit', CreationChosenStyle)
		else
			-- Convertir la tenue validee en items equipes dans ox_inventory.
			TriggerEvent('p_itemclothes/client/updateClothes', skin)
		end
	end)
	CreationChosenStyle = nil
	FreezeEntityPosition(PlayerPedId(), false)
	InRegisterMenu = false
	ESX.ShowNotification('Bienvenue sur le Serveur ~n~Bon jeu à vous !')
	-- Création terminée : esx_identity peut proposer le menu « Destination »
	TriggerEvent('CorePickax:Creator:finished')
end

-- Choix de la tenue : 3 styles (version homme / femme), aperçu direct sur le personnage, puis validation
function CreationOutfitFlow()
	local cfg = ConfigCreationOutfits
	if not cfg or not cfg.Enabled or not cfg.Styles or #cfg.Styles == 0 or GetResourceState('pickax_ui') ~= 'started' then
		return CreationFinish()
	end
	Citizen.Wait(300)

	-- Caméra face au personnage pendant le choix de la tenue
	local ped = PlayerPedId()
	FreezeEntityPosition(ped, true)
	local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
	local from = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.6, 0.5)
	local target = GetEntityCoords(ped)
	SetCamCoord(cam, from.x, from.y, from.z)
	PointCamAtCoord(cam, target.x, target.y, target.z + 0.1)
	SetCamFov(cam, 45.0)
	RenderScriptCams(true, true, 700, true, false)

	local options = {}
	for i, st in ipairs(cfg.Styles) do options[i] = { label = st.label, description = st.description, icon = st.icon } end

	while true do
		local idx = exports['pickax_ui']:Choose({ title = cfg.Title or 'Ta tenue', hint = cfg.Hint, options = options, cancellable = false, align = 'right' }) or 1
		local style = cfg.Styles[idx] or cfg.Styles[1]
		TriggerEvent('skinchanger:getSkin', function(skin)
			local clothes = (skin.sex == 1) and style.female or style.male
			if clothes then TriggerEvent('skinchanger:loadClothes', skin, clothes) end
		end)
		Citizen.Wait(400)
		local ok = exports['pickax_ui']:Choose({
			title = style.label, hint = 'Cette tenue te plaît ?', cancellable = false, align = 'right',
			options = { { label = 'Valider cette tenue', description = 'Continuer vers la destination.', icon = 'pin' }, { label = 'Choisir une autre tenue', description = 'Revenir au choix des styles.', icon = 'house' } },
		})
		if ok == 1 then CreationChosenStyle = idx break end
	end

	RenderScriptCams(false, true, 700, true, false)
	Citizen.Wait(700)
	DestroyCam(cam, false)
	CreationFinish()
end

-- /tenueinfo : affiche la tenue actuelle au format de config.lua (pour créer / ajuster tes styles)
RegisterCommand('tenueinfo', function()
	local ped = PlayerPedId()
	local keys = { 'tshirt', 'torso', 'decals', 'pants', 'shoes' }
	local map = { tshirt = 8, torso = 11, decals = 10, pants = 4, shoes = 6 }
	local parts = {}
	for _, k in ipairs(keys) do
		local id = map[k]
		parts[#parts + 1] = ('%s_1 = %d, %s_2 = %d'):format(k, GetPedDrawableVariation(ped, id), k, GetPedTextureVariation(ped, id))
	end
	parts[#parts + 1] = ('arms = %d'):format(GetPedDrawableVariation(ped, 3))
	local line = '{ ' .. table.concat(parts, ', ') .. ' }'
	print('^2[tenueinfo]^0 ' .. line)
	TriggerEvent('chat:addMessage', { args = { 'tenueinfo', line } })
	ESX.ShowNotification('Tenue copiable dans la console F8 (~b~/tenueinfo~s~).')
end, false)

if not Config.DisableMenuskin then
	RegisterNetEvent('CorePickax:Creator:openSkinMenu')
	AddEventHandler('CorePickax:Creator:openSkinMenu', function(lockSex)
		sexLocked = lockSex == true
		RefreshData()
		SkinChanger()
	end)
end

AddEventHandler('playerSpawned', function()
	Citizen.CreateThread(function()
		while not PlayerLoaded do
			Citizen.Wait(100)
		end

		if FirstSpawn then
			ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
				if skin == nil then
					TriggerEvent('skinchanger:loadSkin', {sex = 0})
				else
					TriggerEvent('skinchanger:loadSkin', skin)
				end
			end)

			FirstSpawn = false
		end
	end)
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer, isNew, savedSkin)
	PlayerLoaded = true

	-- Filet de sécurité : à la reconnexion, on réapplique le skin enregistré (envoyé par es_extended) même si l'événement
	-- « playerSpawned » n'a pas été déclenché ou est arrivé trop tôt. (Nouveau personnage : le menu de création s'en occupe.)
	if not isNew and type(savedSkin) == 'table' and next(savedSkin) ~= nil and FirstSpawn then
		Citizen.CreateThread(function()
			Citizen.Wait(2500)
			if FirstSpawn then
				TriggerEvent('skinchanger:loadSkin', savedSkin)
				FirstSpawn = false
			end
		end)
	end
end)

AddEventHandler('esx_skin:getLastSkin', function(cb)
	cb(LastSkin)
end)

AddEventHandler('esx_skin:setLastSkin', function(skin)
	LastSkin = skin
end)
local Components = {
	{label =MenuNameBLC['sex'],						name = 'sex',				value = 0,		min = 0,	zoomOffset = 0.6,		camOffset = 0.65},
	{label =MenuNameBLC['face'],					name = 'face',				value = 0,		min = 0,	zoomOffset = 0.6,		camOffset = 0.65},
	{label =MenuNameBLC['skin'],					name = 'skin',				value = 0,		min = 0,	zoomOffset = 0.6,		camOffset = 0.65},
	{label =MenuNameBLC['hair_1'],					name = 'hair_1',			value = 0,		min = 0,	zoomOffset = 0.6,		camOffset = 0.65},
	{label =MenuNameBLC['hair_2'],					name = 'hair_2',			value = 0,		min = 0,	zoomOffset = 0.6,		camOffset = 0.65,	textureof = 'hair_1'},
	{label =MenuNameBLC['hair_color_1'],			name = 'hair_color_1',		value = 0,		min = 0,	zoomOffset = 0.6,		camOffset = 0.65},
	{label =MenuNameBLC['hair_color_2'],			name = 'hair_color_2',		value = 0,		min = 0,	zoomOffset = 0.6,		camOffset = 0.65},
	{label =MenuNameBLC['tshirt_1'],				name = 'tshirt_1',			value = 0,		min = 0,	zoomOffset = 0.75,		camOffset = 0.15},
	{label =MenuNameBLC['tshirt_2'],				name = 'tshirt_2',			value = 0,		min = 0,	zoomOffset = 0.75,		camOffset = 0.15,	textureof = 'tshirt_1'},
	{label =MenuNameBLC['torso_1'],					name = 'torso_1',			value = 0,		min = 0,	zoomOffset = 0.75,		camOffset = 0.15},
	{label =MenuNameBLC['torso_2'],					name = 'torso_2',			value = 0,		min = 0,	zoomOffset = 0.75,		camOffset = 0.15,	textureof = 'torso_1'},
	{label =MenuNameBLC['decals_1'],				name = 'decals_1',			value = 0,		min = 0,	zoomOffset = 0.75,		camOffset = 0.15},
	{label =MenuNameBLC['decals_2'],				name = 'decals_2',			value = 0,		min = 0,	zoomOffset = 0.75,		camOffset = 0.15,	textureof = 'decals_1'},
	{label =MenuNameBLC['arms'],					name = 'arms',				value = 0,		min = 0,	zoomOffset = 0.75,		camOffset = 0.15},
	{label =MenuNameBLC['arms_2'],					name = 'arms_2',			value = 0,		min = 0,	zoomOffset = 0.75,		camOffset = 0.15},
	{label =MenuNameBLC['pants_1'],					name = 'pants_1',			value = 0,		min = 0,	zoomOffset = 0.8,		camOffset = -0.5},
	{label =MenuNameBLC['pants_2'],					name = 'pants_2',			value = 0,		min = 0,	zoomOffset = 0.8,		camOffset = -0.5,	textureof = 'pants_1'},
	{label =MenuNameBLC['shoes_1'],					name = 'shoes_1',			value = 0,		min = 0,	zoomOffset = 0.8,		camOffset = -0.8},
	{label =MenuNameBLC['shoes_2'],					name = 'shoes_2',			value = 0,		min = 0,	zoomOffset = 0.8,		camOffset = -0.8,	textureof = 'shoes_1'},
	{label =MenuNameBLC['mask_1'],					name = 'mask_1',			value = 0,		min = 0,	zoomOffset = 0.6,		camOffset = 0.65},
	{label =MenuNameBLC['mask_2'],					name = 'mask_2',			value = 0,		min = 0,	zoomOffset = 0.6,		camOffset = 0.65,	textureof = 'mask_1'},
	{label =MenuNameBLC['bproof_1'],				name = 'bproof_1',			value = 0,		min = 0,	zoomOffset = 0.75,		camOffset = 0.15},
	{label =MenuNameBLC['bproof_2'],				name = 'bproof_2',			value = 0,		min = 0,	zoomOffset = 0.75,		camOffset = 0.15,	textureof = 'bproof_1'},
	{label =MenuNameBLC['chain_1'],					name = 'chain_1',			value = 0,		min = 0,	zoomOffset = 0.6,		camOffset = 0.65},
	{label =MenuNameBLC['chain_2'],					name = 'chain_2',			value = 0,		min = 0,	zoomOffset = 0.6,		camOffset = 0.65,	textureof = 'chain_1'},
	{label =MenuNameBLC['helmet_1'],				name = 'helmet_1',			value = -1,		min = -1,	zoomOffset = 0.6,		camOffset = 0.65,	componentId	= 0},
	{label =MenuNameBLC['helmet_2'],				name = 'helmet_2',			value = 0,		min = 0,	zoomOffset = 0.6,		camOffset = 0.65,	textureof = 'helmet_1'},
	{label =MenuNameBLC['glasses_1'],				name = 'glasses_1',			value = 0,		min = 0,	zoomOffset = 0.6,		camOffset = 0.65},
	{label =MenuNameBLC['glasses_2'],				name = 'glasses_2',			value = 0,		min = 0,	zoomOffset = 0.6,		camOffset = 0.65,	textureof = 'glasses_1'},
	{label =MenuNameBLC['watches_1'],				name = 'watches_1',			value = -1,		min = -1,	zoomOffset = 0.75,		camOffset = 0.15},
	{label =MenuNameBLC['watches_2'],				name = 'watches_2',			value = 0,		min = 0,	zoomOffset = 0.75,		camOffset = 0.15,	textureof = 'watches_1'},
	{label =MenuNameBLC['bracelets_1'],				name = 'bracelets_1',		value = -1,		min = -1,	zoomOffset = 0.75,		camOffset = 0.15},
	{label =MenuNameBLC['bracelets_2'],				name = 'bracelets_2',		value = 0,		min = 0,	zoomOffset = 0.75,		camOffset = 0.15,	textureof = 'bracelets_1'},
	{label =MenuNameBLC['bag'],						name = 'bags_1',			value = 0,		min = 0,	zoomOffset = 0.75,		camOffset = 0.15},
	{label =MenuNameBLC['bag_color'],				name = 'bags_2',			value = 0,		min = 0,	zoomOffset = 0.75,		camOffset = 0.15,	textureof = 'bags_1'},
	{label =MenuNameBLC['eye_color'],				name = 'eye_color',			value = 0,		min = 0,	zoomOffset = 0.4,		camOffset = 0.65},
	{label =MenuNameBLC['eyebrow_size'],			name = 'eyebrows_2',		value = 0,		min = 0,	zoomOffset = 0.4,		camOffset = 0.65},
	{label =MenuNameBLC['eyebrow_type'],			name = 'eyebrows_1',		value = 0,		min = 0,	zoomOffset = 0.4,		camOffset = 0.65},
	{label =MenuNameBLC['eyebrow_color_1'],			name = 'eyebrows_3',		value = 0,		min = 0,	zoomOffset = 0.4,		camOffset = 0.65},
	{label =MenuNameBLC['eyebrow_color_2'],			name = 'eyebrows_4',		value = 0,		min = 0,	zoomOffset = 0.4,		camOffset = 0.65},
	{label =MenuNameBLC['makeup_type'],				name = 'makeup_1',			value = 0,		min = 0,	zoomOffset = 0.4,		camOffset = 0.65},
	{label =MenuNameBLC['makeup_thickness'],		name = 'makeup_2',			value = 0,		min = 0,	zoomOffset = 0.4,		camOffset = 0.65},
	{label =MenuNameBLC['makeup_color_1'],			name = 'makeup_3',			value = 0,		min = 0,	zoomOffset = 0.4,		camOffset = 0.65},
	{label =MenuNameBLC['makeup_color_2'],			name = 'makeup_4',			value = 0,		min = 0,	zoomOffset = 0.4,		camOffset = 0.65},
	{label =MenuNameBLC['lipstick_type'],			name = 'lipstick_1',		value = 0,		min = 0,	zoomOffset = 0.4,		camOffset = 0.65},
	{label =MenuNameBLC['lipstick_thickness'],		name = 'lipstick_2',		value = 0,		min = 0,	zoomOffset = 0.4,		camOffset = 0.65},
	{label =MenuNameBLC['lipstick_color_1'],		name = 'lipstick_3',		value = 0,		min = 0,	zoomOffset = 0.4,		camOffset = 0.65},
	{label =MenuNameBLC['lipstick_color_2'],		name = 'lipstick_4',		value = 0,		min = 0,	zoomOffset = 0.4,		camOffset = 0.65},
	{label =MenuNameBLC['ear_accessories'],			name = 'ears_1',			value = -1,		min = -1,	zoomOffset = 0.4,		camOffset = 0.65},
	{label =MenuNameBLC['ear_accessories_color'],	name = 'ears_2',			value = 0,		min = 0,	zoomOffset = 0.4,		camOffset = 0.65,	textureof = 'ears_1'},
	{label =MenuNameBLC['chest_hair'],				name = 'chest_1',			value = 0,		min = 0,	zoomOffset = 0.75,		camOffset = 0.15},
	{label =MenuNameBLC['chest_hair_1'],			name = 'chest_2',			value = 0,		min = 0,	zoomOffset = 0.75,		camOffset = 0.15},
	{label =MenuNameBLC['chest_color'],				name = 'chest_3',			value = 0,		min = 0,	zoomOffset = 0.75,		camOffset = 0.15},
	{label =MenuNameBLC['bodyb'],					name = 'bodyb_1',			value = 0,		min = 0,	zoomOffset = 0.75,		camOffset = 0.15},
	{label =MenuNameBLC['bodyb_size'],				name = 'bodyb_2',			value = 0,		min = 0,	zoomOffset = 0.75,		camOffset = 0.15},
	{label =MenuNameBLC['wrinkles'],				name = 'age_1',				value = 0,		min = 0,	zoomOffset = 0.4,		camOffset = 0.65},
	{label =MenuNameBLC['wrinkle_thickness'],		name = 'age_2',				value = 0,		min = 0,	zoomOffset = 0.4,		camOffset = 0.65},
	{label =MenuNameBLC['blemishes'],				name = 'blemishes_1',		value = 0,		min = 0,	zoomOffset = 0.4,		camOffset = 0.65},
	{label =MenuNameBLC['blemishes_size'],			name = 'blemishes_2',		value = 0,		min = 0,	zoomOffset = 0.4,		camOffset = 0.65},
	{label =MenuNameBLC['blush'],					name = 'blush_1',			value = 0,		min = 0,	zoomOffset = 0.4,		camOffset = 0.65},
	{label =MenuNameBLC['blush_1'],					name = 'blush_2',			value = 0,		min = 0,	zoomOffset = 0.4,		camOffset = 0.65},
	{label =MenuNameBLC['blush_color'],				name = 'blush_3',			value = 0,		min = 0,	zoomOffset = 0.4,		camOffset = 0.65},
	{label =MenuNameBLC['complexion'],				name = 'complexion_1',		value = 0,		min = 0,	zoomOffset = 0.4,		camOffset = 0.65},
	{label =MenuNameBLC['complexion_1'],			name = 'complexion_2',		value = 0,		min = 0,	zoomOffset = 0.4,		camOffset = 0.65},
	{label =MenuNameBLC['sun'],						name = 'sun_1',				value = 0,		min = 0,	zoomOffset = 0.4,		camOffset = 0.65},
	{label =MenuNameBLC['sun_1'],					name = 'sun_2',				value = 0,		min = 0,	zoomOffset = 0.4,		camOffset = 0.65},
	{label =MenuNameBLC['freckles'],				name = 'moles_1',			value = 0,		min = 0,	zoomOffset = 0.4,		camOffset = 0.65},
	{label =MenuNameBLC['freckles_1'],				name = 'moles_2',			value = 0,		min = 0,	zoomOffset = 0.4,		camOffset = 0.65},
	{label =MenuNameBLC['beard_type'],				name = 'beard_1',			value = 0,		min = 0,	zoomOffset = 0.4,		camOffset = 0.65},
	{label =MenuNameBLC['beard_size'],				name = 'beard_2',			value = 0,		min = 0,	zoomOffset = 0.4,		camOffset = 0.65},
	{label =MenuNameBLC['beard_color_1'],			name = 'beard_3',			value = 0,		min = 0,	zoomOffset = 0.4,		camOffset = 0.65},
	{label =MenuNameBLC['beard_color_2'],			name = 'beard_4',			value = 0,		min = 0,	zoomOffset = 0.4,		camOffset = 0.65}
}

local LastSex = -1
local LoadSkin = nil
local LoadClothes = nil
local Character = {}

for i = 1, #Components, 1 do
	Character[Components[i].name] = Components[i].value
end

function LoadDefaultModel(malePed, cb)
	local playerPed = PlayerPedId()
	local characterModel

	if malePed then
		characterModel = `mp_m_freemode_01`
	else
		characterModel = `mp_f_freemode_01`
	end

	Citizen.CreateThread(function()
		ESX.Streaming.RequestModel(characterModel, function()
			if IsModelInCdimage(characterModel) and IsModelValid(characterModel) then
				SetPlayerModel(PlayerId(), characterModel)
				SetPedDefaultComponentVariation(playerPed)
			end

			SetModelAsNoLongerNeeded(characterModel)

			if cb then
				cb()
			end

			TriggerEvent('skinchanger:modelLoaded')
		end)
	end)
end

function GetMaxVals()
	local playerPed = PlayerPedId()

	local data = {
		sex = 1,
		face = 45,
		skin = 45,
		age_1 = GetNumHeadOverlayValues(3) - 1,
		age_2 = 10,
		beard_1 = GetNumHeadOverlayValues(1) - 1,
		beard_2 = 10,
		beard_3 = GetNumHairColors() - 1,
		beard_4 = GetNumHairColors() - 1,
		hair_1 = GetNumberOfPedDrawableVariations(playerPed, 2) - 1,
		hair_2 = GetNumberOfPedTextureVariations(playerPed, 2, Character['hair_1']) - 1,
		hair_color_1 = GetNumHairColors() - 1,
		hair_color_2 = GetNumHairColors() - 1,
		eye_color = 31,
		eyebrows_1 = GetNumHeadOverlayValues(2) - 1,
		eyebrows_2 = 10,
		eyebrows_3 = GetNumHairColors() - 1,
		eyebrows_4 = GetNumHairColors() - 1,
		makeup_1 = GetNumHeadOverlayValues(4) - 1,
		makeup_2 = 10,
		makeup_3 = GetNumHairColors() - 1,
		makeup_4 = GetNumHairColors() - 1,
		lipstick_1 = GetNumHeadOverlayValues(8) - 1,
		lipstick_2 = 10,
		lipstick_3 = GetNumHairColors() - 1,
		lipstick_4 = GetNumHairColors() - 1,
		blemishes_1 = GetNumHeadOverlayValues(0) - 1,
		blemishes_2 = 10,
		blush_1 = GetNumHeadOverlayValues(5) - 1,
		blush_2 = 10,
		blush_3 = GetNumHairColors() - 1,
		complexion_1 = GetNumHeadOverlayValues(6) - 1,
		complexion_2 = 10,
		sun_1 = GetNumHeadOverlayValues(7) - 1,
		sun_2 = 10,
		moles_1 = GetNumHeadOverlayValues(9) - 1,
		moles_2 = 10,
		chest_1 = GetNumHeadOverlayValues(10) - 1,
		chest_2 = 10,
		chest_3 = GetNumHairColors() - 1,
		bodyb_1 = GetNumHeadOverlayValues(11) - 1,
		bodyb_2 = 10,
		ears_1 = GetNumberOfPedPropDrawableVariations(playerPed, 1) - 1,
		ears_2 = GetNumberOfPedPropTextureVariations(playerPed, 1, Character['ears_1']) - 1,
		tshirt_1 = GetNumberOfPedDrawableVariations(playerPed, 8) - 1,
		tshirt_2 = GetNumberOfPedTextureVariations(playerPed, 8, Character['tshirt_1']) - 1,
		torso_1 = GetNumberOfPedDrawableVariations(playerPed, 11) - 1,
		torso_2 = GetNumberOfPedTextureVariations(playerPed, 11, Character['torso_1']) - 1,
		decals_1 = GetNumberOfPedDrawableVariations(playerPed, 10) - 1,
		decals_2 = GetNumberOfPedTextureVariations(playerPed, 10, Character['decals_1']) - 1,
		arms = GetNumberOfPedDrawableVariations(playerPed, 3) - 1,
		arms_2 = 10,
		pants_1 = GetNumberOfPedDrawableVariations(playerPed, 4) - 1,
		pants_2 = GetNumberOfPedTextureVariations(playerPed, 4, Character['pants_1']) - 1,
		shoes_1 = GetNumberOfPedDrawableVariations(playerPed, 6) - 1,
		shoes_2 = GetNumberOfPedTextureVariations(playerPed, 6, Character['shoes_1']) - 1,
		mask_1 = GetNumberOfPedDrawableVariations(playerPed, 1) - 1,
		mask_2 = GetNumberOfPedTextureVariations(playerPed, 1, Character['mask_1']) - 1,
		bproof_1 = GetNumberOfPedDrawableVariations(playerPed, 9) - 1,
		bproof_2 = GetNumberOfPedTextureVariations(playerPed, 9, Character['bproof_1']) - 1,
		chain_1 = GetNumberOfPedDrawableVariations(playerPed, 7) - 1,
		chain_2 = GetNumberOfPedTextureVariations(playerPed, 7, Character['chain_1']) - 1,
		bags_1 = GetNumberOfPedDrawableVariations(playerPed, 5) - 1,
		bags_2 = GetNumberOfPedTextureVariations(playerPed, 5, Character['bags_1']) - 1,
		helmet_1 = GetNumberOfPedPropDrawableVariations(playerPed, 0) - 1,
		helmet_2 = GetNumberOfPedPropTextureVariations(playerPed, 0, Character['helmet_1']) - 1,
		glasses_1 = GetNumberOfPedPropDrawableVariations(playerPed, 1) - 1,
		glasses_2 = GetNumberOfPedPropTextureVariations(playerPed, 1, Character['glasses_1'] - 1),
		watches_1 = GetNumberOfPedPropDrawableVariations(playerPed, 6) - 1,
		watches_2 = GetNumberOfPedPropTextureVariations(playerPed, 6, Character['watches_1']) - 1,
		bracelets_1 = GetNumberOfPedPropDrawableVariations(playerPed, 7) - 1,
		bracelets_2 = GetNumberOfPedPropTextureVariations(playerPed, 7, Character['bracelets_1']) - 1
	}

	return data
end

function ApplySkin(skin, clothes)
	local playerPed = PlayerPedId()

	for k, v in pairs(skin) do
		Character[k] = v
	end

	if clothes ~= nil then
		for k, v in pairs(clothes) do
			if
				k ~= 'sex' and
				k ~= 'face' and
				k ~= 'skin' and
				k ~= 'age_1' and
				k ~= 'age_2' and
				k ~= 'eye_color' and
				k ~= 'beard_1' and
				k ~= 'beard_2' and
				k ~= 'beard_3' and
				k ~= 'beard_4' and
				k ~= 'hair_1' and
				k ~= 'hair_2' and
				k ~= 'hair_color_1' and
				k ~= 'hair_color_2' and
				k ~= 'eyebrows_1' and
				k ~= 'eyebrows_2' and
				k ~= 'eyebrows_3' and
				k ~= 'eyebrows_4' and
				k ~= 'makeup_1' and
				k ~= 'makeup_2' and
				k ~= 'makeup_3' and
				k ~= 'makeup_4' and
				k ~= 'lipstick_1' and
				k ~= 'lipstick_2' and
				k ~= 'lipstick_3' and
				k ~= 'lipstick_4' and
				k ~= 'blemishes_1' and
				k ~= 'blemishes_2' and
				k ~= 'blush_1' and
				k ~= 'blush_2' and
				k ~= 'blush_3' and
				k ~= 'complexion_1' and
				k ~= 'complexion_2' and
				k ~= 'sun_1' and
				k ~= 'sun_2' and
				k ~= 'moles_1' and
				k ~= 'moles_2' and
				k ~= 'chest_1' and
				k ~= 'chest_2' and
				k ~= 'chest_3' and
				k ~= 'bodyb_1' and
				k ~= 'bodyb_2'
			then
				Character[k] = v
			end
		end
	end

	SetPedHeadBlendData(playerPed, Character['face'], Character['face'], Character['face'], Character['skin'], Character['skin'], Character['skin'], 1.0, 1.0, 1.0, true)

	SetPedHairColor(playerPed, Character['hair_color_1'], Character['hair_color_2']) -- Hair Color
	SetPedHeadOverlay(playerPed, 3, Character['age_1'], (Character['age_2'] / 10) + 0.0) -- Age + opacity
	SetPedHeadOverlay(playerPed, 1, Character['beard_1'], (Character['beard_2'] / 10) + 0.0) -- Beard + opacity
	SetPedEyeColor(playerPed, Character['eye_color'], 0, 1) -- Eyes color
	SetPedHeadOverlay(playerPed, 2, Character['eyebrows_1'], (Character['eyebrows_2'] / 10) + 0.0) -- Eyebrows + opacity
	SetPedHeadOverlay(playerPed, 4, Character['makeup_1'], (Character['makeup_2'] / 10) + 0.0) -- Makeup + opacity
	SetPedHeadOverlay(playerPed, 8, Character['lipstick_1'], (Character['lipstick_2'] / 10) + 0.0) -- Lipstick + opacity
	SetPedComponentVariation(playerPed, 2, Character['hair_1'], Character['hair_2'], 2) -- Hair
	SetPedHeadOverlayColor(playerPed, 1, 1,	Character['beard_3'], Character['beard_4']) -- Beard Color
	SetPedHeadOverlayColor(playerPed, 2, 1,	Character['eyebrows_3'], Character['eyebrows_4']) -- Eyebrows Color
	SetPedHeadOverlayColor(playerPed, 4, 1,	Character['makeup_3'], Character['makeup_4']) -- Makeup Color
	SetPedHeadOverlayColor(playerPed, 8, 1,	Character['lipstick_3'], Character['lipstick_4']) -- Lipstick Color
	SetPedHeadOverlay(playerPed, 5, Character['blush_1'], (Character['blush_2'] / 10) + 0.0) -- Blush + opacity
	SetPedHeadOverlayColor(playerPed, 5, 2,	Character['blush_3']) -- Blush Color
	SetPedHeadOverlay(playerPed, 6, Character['complexion_1'], (Character['complexion_2'] / 10) + 0.0) -- Complexion + opacity
	SetPedHeadOverlay(playerPed, 7, Character['sun_1'], (Character['sun_2'] / 10) + 0.0) -- Sun Damage + opacity
	SetPedHeadOverlay(playerPed, 9, Character['moles_1'], (Character['moles_2'] / 10) + 0.0) -- Moles/Freckles + opacity
	SetPedHeadOverlay(playerPed, 10, Character['chest_1'], (Character['chest_2'] / 10) + 0.0) -- Chest Hair + opacity
	SetPedHeadOverlayColor(playerPed, 10, 1, Character['chest_3']) -- Torso Color
	SetPedHeadOverlay(playerPed, 11, Character['bodyb_1'], (Character['bodyb_2'] / 10) + 0.0) -- Body Blemishes + opacity

	if Character['ears_1'] == -1 then
		ClearPedProp(playerPed, 2)
	else
		SetPedPropIndex(playerPed, 2, Character['ears_1'], Character['ears_2'], 2) -- Ears Accessories
	end

	SetPedComponentVariation(playerPed, 8, Character['tshirt_1'], Character['tshirt_2'], 2) -- Tshirt
	SetPedComponentVariation(playerPed, 11, Character['torso_1'], Character['torso_2'], 2) -- torso parts
	SetPedComponentVariation(playerPed, 3, Character['arms'], Character['arms_2'], 2) -- Arms
	SetPedComponentVariation(playerPed, 10, Character['decals_1'], Character['decals_2'], 2) -- decals
	SetPedComponentVariation(playerPed, 4, Character['pants_1'], Character['pants_2'], 2) -- pants
	SetPedComponentVariation(playerPed, 6, Character['shoes_1'], Character['shoes_2'], 2) -- shoes
	SetPedComponentVariation(playerPed, 1, Character['mask_1'], Character['mask_2'], 2) -- mask
	SetPedComponentVariation(playerPed, 9, Character['bproof_1'], Character['bproof_2'], 2) -- bulletproof
	SetPedComponentVariation(playerPed, 7, Character['chain_1'], Character['chain_2'], 2) -- chain
	SetPedComponentVariation(playerPed, 5, Character['bags_1'], Character['bags_2'], 2) -- Bag

	if Character['helmet_1'] == -1 then
		ClearPedProp(playerPed, 0)
	else
		SetPedPropIndex(playerPed, 0, Character['helmet_1'], Character['helmet_2'], 2) -- Helmet
	end

	if Character['glasses_1'] == -1 then
		ClearPedProp(playerPed, 1)
	else
		SetPedPropIndex(playerPed, 1, Character['glasses_1'], Character['glasses_2'], 2) -- Glasses
	end

	if Character['watches_1'] == -1 then
		ClearPedProp(playerPed, 6)
	else
		SetPedPropIndex(playerPed, 6, Character['watches_1'], Character['watches_2'], 2) -- Watches
	end

	if Character['bracelets_1'] == -1 then
		ClearPedProp(playerPed,	7)
	else
		SetPedPropIndex(playerPed, 7, Character['bracelets_1'], Character['bracelets_2'], 2) -- Bracelets
	end

	if Character['bproof_1'] == 0 then
		SetPedArmour(playerPed, 0)
	else
		SetPedArmour(playerPed, 100)
	end
end

AddEventHandler('skinchanger:loadDefaultModel', function(loadMale, cb)
	LoadDefaultModel(loadMale, cb)
end)

AddEventHandler('skinchanger:getData', function(cb)
	local components = json.decode(json.encode(Components))

	for k, v in pairs(Character) do
		for i = 1, #components, 1 do
			if k == components[i].name then
				components[i].value = v
			end
		end
	end

	cb(components, GetMaxVals())
end)

AddEventHandler('skinchanger:change', function(key, val)
	Character[key] = val

	if key == 'sex' then
		TriggerEvent('skinchanger:loadSkin', Character)
	else
		ApplySkin(Character)
	end
end)

AddEventHandler('skinchanger:getSkin', function(cb)
	cb(Character)
end)

AddEventHandler('skinchanger:modelLoaded', function()
	ClearPedProp(PlayerPedId(), 0)

	if LoadSkin ~= nil then
		ApplySkin(LoadSkin)
		LoadSkin = nil
	end

	if LoadClothes ~= nil then
		ApplySkin(LoadClothes.playerSkin, LoadClothes.clothesSkin)
		LoadClothes = nil
	end
end)

RegisterNetEvent('skinchanger:loadSkin')
AddEventHandler('skinchanger:loadSkin', function(skin, cb)
	if skin['sex'] ~= LastSex then
		LoadSkin = skin

		if skin['sex'] == 0 then
			TriggerEvent('skinchanger:loadDefaultModel', true, cb)
		else
			TriggerEvent('skinchanger:loadDefaultModel', false, cb)
		end
	else
		ApplySkin(skin)

		if cb then
			cb()
		end
	end

	LastSex = skin['sex']
end)

RegisterNetEvent('skinchanger:loadClothes')
AddEventHandler('skinchanger:loadClothes', function(playerSkin, clothesSkin)
	if playerSkin['sex'] ~= LastSex then
		LoadClothes = {
			playerSkin = playerSkin,
			clothesSkin = clothesSkin
		}

		if playerSkin['sex'] == 0 then
			TriggerEvent('skinchanger:loadDefaultModel', true)
		else
			TriggerEvent('skinchanger:loadDefaultModel', false)
		end
	else
		ApplySkin(playerSkin, clothesSkin)
	end

	LastSex = playerSkin['sex']
end)