local Action = {
	Cross = false,
	Radar = false,
	Hud = false,
	WindowsList = {"Avant Gauche", "Avant Droite", "Arrière Gauche", "Arrière Droite"},
	WindowsIndex = 1,
	DoorState = {
		FrontLeft = false,
		FrontRight = false,
		BackLeft = false,
		BackRight = false,
		Hood = false,
		Trunk = false
	},
	WindowsState = {
		FrontLeft = false,
		FrontRight = false,
		BackLeft = false,
		BackRight = false,
	},
	DoorIndex = 1,
	DoorList = {"Avant Gauche", "Avant Droite", "Arrière Gauche", "Arrière Droite"},
	LimitateurList = {"50 km/h", "80 km/h", "120 km/h", "Personnaliser", "Désactiver"},
	LimitateurIndex = 1
}

local Prefs = {
	Styles = {
		{ id = 'noir', name = 'Noir' }, { id = 'verre', name = 'Verre' }, { id = 'clair', name = 'Clair' },
		{ id = 'neon', name = 'Néon' }, { id = 'bleu', name = 'Couleur du serveur' },
	},
	Sizes = { { id = 'sm', name = 'Petit' }, { id = 'md', name = 'Moyen' }, { id = 'lg', name = 'Grand' } },
	-- Couleurs : liste de préréglages + "Personnalisé" (Entrée = saisir un code #RRGGBB au clavier)
	Colors = {
		{ key = 'accent', label = 'Couleur principale', desc = 'Barre, détails et accents des menus', noDefault = true, presets = {
			{ (PickaxTheme and PickaxTheme.hex) or '#fdc27d', 'Couleur du serveur' }, { '#ef4444', 'Rouge' }, { '#22c55e', 'Vert' }, { '#a855f7', 'Violet' },
			{ '#f97316', 'Orange' }, { '#ec4899', 'Rose' }, { '#eab308', 'Jaune' }, { '#f4f4f5', 'Blanc' } } },
		{ key = 'bg', label = 'Fond du menu', desc = 'Couleur de fond des menus', presets = {
			{ '#0b0b0c', 'Noir' }, { '#1c1f26', 'Anthracite' }, { '#0a1a3a', 'Bleu nuit' }, { '#1a1030', 'Violet foncé' },
			{ '#0d1f17', 'Vert foncé' }, { '#2a0f14', 'Bordeaux' }, { '#f7f7f5', 'Blanc' } } },
		{ key = 'text', label = 'Texte', desc = 'Couleur du texte des menus', presets = {
			{ '#f4f4f5', 'Blanc' }, { '#c9c9ce', 'Gris clair' }, { '#111114', 'Noir' }, { '#cfe6ff', 'Bleu clair' }, { '#fde68a', 'Doré' } } },
		{ key = 'selbg', label = 'Bouton sélectionné (fond)', desc = 'Fond du bouton survolé', presets = {
			{ '#fdc27d', 'Bleu' }, { '#ffffff', 'Blanc' }, { '#ef4444', 'Rouge' }, { '#22c55e', 'Vert' }, { '#a855f7', 'Violet' }, { '#eab308', 'Jaune' } } },
		{ key = 'selborder', label = 'Bouton sélectionné (bordure)', desc = 'Bordure du bouton survolé', presets = {
			{ '#ffffff', 'Blanc' }, { '#fdc27d', 'Bleu' }, { '#ef4444', 'Rouge' }, { '#22c55e', 'Vert' }, { '#a855f7', 'Violet' }, { '#eab308', 'Jaune' } } },
	},
	BtnRadius = { { 0, 'Carré' }, { 6, 'Léger' }, { 12, 'Arrondi' }, { 18, 'Très arrondi' }, { 24, 'Fort arrondi' }, { 999, 'Rond (pilule)' } },
	CardRadius = { { 0, 'Carré' }, { 8, 'Léger' }, { 14, 'Arrondi' }, { 18, 'Standard' }, { 24, 'Très arrondi' }, { 28, 'Fort arrondi' } },
}

local PrefsCfg = { sound = true, volume = 60, banner = true, style = 'noir', size = 'md', accent = (PickaxTheme and PickaxTheme.hex) or '#fdc27d', bg = '', text = '', selbg = '', selborder = '', btnRadius = 12, cardRadius = 18 }

local function PrefsCall(name, ...)
	if GetResourceState('pickax_ui') ~= 'started' then return nil end
	return exports['pickax_ui'][name](exports['pickax_ui'], ...)
end

local function PrefsRefresh()
	local c = PrefsCall('GetSettings')
	if c then for k, v in pairs(c) do PrefsCfg[k] = v end end
end

local function PrefsSet(key, value)
	if PrefsCall('SetSetting', key, value) then PrefsCfg[key] = value end
end

local function PrefsNames(list, nameIdx)
	local t = {}
	for i = 1, #list do t[i] = list[i][nameIdx or 2] or list[i].name end
	return t
end

local PrefsStyleNames, PrefsSizeNames = {}, {}
for i, v in ipairs(Prefs.Styles) do PrefsStyleNames[i] = v.name end
for i, v in ipairs(Prefs.Sizes) do PrefsSizeNames[i] = v.name end
local PrefsVolumeNames = {}
for i = 1, 10 do PrefsVolumeNames[i] = (i * 10) .. ' %' end
local function PrefsVolumeIndex() return math.max(1, math.min(10, math.floor((tonumber(PrefsCfg.volume) or 60) / 10 + 0.5))) end
local HudRadius = { { 0, 'Carré' }, { 6, 'Léger' }, { 12, 'Arrondi' }, { 18, 'Très arrondi' }, { 24, 'Fort arrondi' } }
local HudRadiusNames = {}
for i, v in ipairs(HudRadius) do HudRadiusNames[i] = v[2] end
local HudScale = { { 70, 'Très petit' }, { 85, 'Petit' }, { 100, 'Normal' }, { 115, 'Grand' }, { 130, 'Très grand' } }
local HudScaleNames = {}
for i, v in ipairs(HudScale) do HudScaleNames[i] = v[2] end
local NotifyRadius = { { -1, 'Par défaut' }, { 0, 'Carré' }, { 6, 'Léger' }, { 11, 'Arrondi' }, { 18, 'Très arrondi' }, { 26, 'Fort arrondi' } }
local NotifyRadiusNames = {}
for i, v in ipairs(NotifyRadius) do NotifyRadiusNames[i] = v[2] end
local function NotifyGetRadius()
	if GetResourceState('pickax_notify') ~= 'started' then return -1 end
	return exports['pickax_notify']:GetRadius() or -1
end
local function NotifySetRadius(v)
	if GetResourceState('pickax_notify') ~= 'started' then return end
	exports['pickax_notify']:SetRadius(v >= 0 and v or nil)
	exports['pickax_notify']:ShowNotification('Aperçu : voici le nouvel arrondi des notifications.', 'success')
end
local HudCfg = { hud = true, server = true, job = true, money = true, radius = 6, scale = 100 }
local function HudCall(name, ...)
	if GetResourceState('pickax_hud2') ~= 'started' then return nil end
	return exports['pickax_hud2'][name](exports['pickax_hud2'], ...)
end
local function HudRefresh()
	local c = HudCall('GetSettings')
	if c then for k, v in pairs(c) do HudCfg[k] = v end end
end
local function HudSet(key, value)
	if HudCall('SetSetting', key, value) then HudCfg[key] = value end
end
local PrefsBtnNames, PrefsCardNames = PrefsNames(Prefs.BtnRadius), PrefsNames(Prefs.CardRadius)

local function PrefsStyleIndex(list, id)
	for i = 1, #list do if list[i].id == id then return i end end
	return 1
end

local function PrefsRadiusIndex(list, v)
	for i = 1, #list do if list[i][1] == v then return i end end
	return 1
end

-- Liste d'une couleur : [Défaut] + préréglages + [Personnalisé]
local function PrefsColorItems(def)
	local t = {}
	if not def.noDefault then t[#t + 1] = 'Défaut' end
	for i = 1, #def.presets do t[#t + 1] = def.presets[i][2] end
	t[#t + 1] = 'Personnalisé (Entrée)'
	return t
end

local function PrefsColorIndex(def, items)
	local cur = PrefsCfg[def.key] or ''
	if cur == '' and not def.noDefault then return 1 end
	local off = def.noDefault and 0 or 1
	for i = 1, #def.presets do
		if def.presets[i][1] == cur then return i + off end
	end
	return #items
end

local function PrefsAskHex(key)
	CreateThread(function()
		local cur = PrefsCfg[key] or ''
		local typed
		if GetResourceState('pickax_ui') == 'started' then
			typed = exports['pickax_ui']:Input({ title = 'Couleur personnalisée', hint = 'Format #RRGGBB', placeholder = '#fdc27d', default = cur ~= '' and cur or '#', max = 7 })
		else
			AddTextEntry('PICKAX_HEX', 'Couleur au format #RRGGBB (ex : #fdc27d)')
			DisplayOnscreenKeyboard(1, 'PICKAX_HEX', '', cur ~= '' and cur or '#', '', '', '', 7)
			while UpdateOnscreenKeyboard() == 0 do
				DisableAllControlActions(0)
				Wait(0)
			end
			if UpdateOnscreenKeyboard() == 1 then typed = GetOnscreenKeyboardResult() end
		end
		if typed then
			local r = (typed or ''):gsub('%s', '')
			if r:match('^%x%x%x%x%x%x$') then r = '#' .. r end
			if r:match('^#%x%x%x%x%x%x$') then
				PrefsSet(key, r:lower())
			else
				ESX.ShowNotification('~r~Couleur invalide~s~ (format #RRGGBB)')
			end
		end
	end)
end

local BillData = {}
local Breakable = false

local disabledLourdKeys = {
	{group = 2, key = 37},
	{group = 0, key = 24},
	{group = 0, key = 69},
	{group = 0, key = 92},
	{group = 0, key = 140},
	{group = 0, key = 106},
	{group = 0, key = 21},
	{group = 0, key = 22},
}


Citizen.CreateThread(function()
	while GetResourceState('ox_inventory') ~= 'started' do
		Wait(250)
	end

	while true do
		local timer = 1000
		local currentWeight = exports.ox_inventory:GetPlayerWeight() or 0
		local maxWeight = exports.ox_inventory:GetPlayerMaxWeight() or 0
		if maxWeight > 0 and maxWeight < 1000 then maxWeight = maxWeight * 1000 end -- valeur en kg -> grammes

		if maxWeight > 0 and currentWeight > maxWeight then
			timer = 0

			if not InAFK then
				RageUI.Text({message = "~r~Vous êtes trop lourd~s~", time_display = 1})
				for i = 1, #disabledLourdKeys, 1 do
					DisableControlAction(disabledLourdKeys[i].group, disabledLourdKeys[i].key, true)
				end
			end
		end

		Wait(timer)
	end
end)


-- Raccourcis clavier réels (lus dans les configs des modules)
local function CfgGet(fn)
	local ok, v = pcall(fn)
	if ok and v ~= nil and v ~= '' then return v end
	return nil
end

local function MenuKeys()
	local list = {
		{ "Menu personnel", CfgGet(function() return ConfigMenuF5.Commande.Bind end) },
		{ "Menu des emotes", CfgGet(function() return ConfigMenuEmote.MenuKeybind end) },
		{ "Annuler une emote", CfgGet(function() return ConfigMenuEmote.CancelEmoteKey end) },
		{ "Mains en l'air", CfgGet(function() return ConfigMenuEmote.HandsupKeybind end) },
		{ "Pointer du doigt", CfgGet(function() return ConfigMenuEmote.PointingKeybind end) },
		{ "S'accroupir", CfgGet(function() return ConfigMenuEmote.CrouchKeybind end) },
		{ "Ramper", CfgGet(function() return ConfigMenuEmote.CrawlKeybind end) },
		{ "S'endormir / se réveiller", CfgGet(function() return ConfigRagdoll.Commande.Bind end) },
		{ "Boutique", CfgGet(function() return ConfigBoutique.Commande.Bind end) },
		{ "Radio", CfgGet(function() return ConfigRadio.Commande.Bind end) },
		{ "Clés du véhicule", CfgGet(function() return ConfigVehicle.Commande.Bind end) },
		{ "Ouvrir / fermer le véhicule", CfgGet(function() return ConfigVehicle.Commande.Bind2 end) },
		{ "Coffre du véhicule", "L" },
		{ "Verrouiller une porte", "E" },
	}
	local out = {}
	for _, k in ipairs(list) do if k[2] then out[#out + 1] = k end end
	return out
end

-- Commandes joueurs (les commandes staff ne sont pas listées)
local function MenuCommands()
	local list = {
		{ "me", "Écrire une action RP au-dessus de la tête" },
		{ "e", "Jouer une emote (ex : /e dance)" },
		{ "emotes", "Voir la liste des emotes" },
		{ "walk", "Changer sa démarche" },
		{ "porter", "Porter la personne la plus proche" },
		{ "otage", "Prendre une personne en otage" },
		{ "id", "Afficher votre ID" },
		{ "register", "Recréer votre personnage" },
		{ "coffre", "Ouvrir le coffre du véhicule proche" },
		{ "hidehud", "Afficher / masquer l'affichage d'argent" },
	}
	local boutique = CfgGet(function() return ConfigBoutique.Commande.CommandeName end)
	if boutique then list[#list + 1] = { boutique, "Ouvrir la boutique" } end
	return list
end

local function OpenMenu()
	ESX.PlayerData = ESX.GetPlayerData()
	local Identity = nil
	ESX.TriggerServerCallback('CorePickax:GetIdentity', function(id) Identity = id end)
    local mainmenu = RageUI.CreateMenu("Menu Personnel", "Actions disponibles :")
	local Informations = RageUI.CreateSubMenu(mainmenu, "Informations", "Votre profil et votre portefeuille :")
	local Docs = RageUI.CreateSubMenu(mainmenu, "Documents officiels", "Carte, permis et port d'armes :")
	local Parametres = RageUI.CreateSubMenu(mainmenu, "Préférences", "Réglages de votre jeu :")
	local PerfMenu = RageUI.CreateSubMenu(Parametres, "Performances (FPS)", "Allégez le rendu du jeu :")
	local KeysMenu = RageUI.CreateSubMenu(mainmenu, "Touches du serveur", "Raccourcis clavier :")
	local CmdsMenu = RageUI.CreateSubMenu(mainmenu, "Commandes du serveur", "Commandes utiles :")
	local StatusMenu = RageUI.CreateSubMenu(mainmenu, "Statut des entreprises", "En ligne = au moins un employé en service :")
	local VipMenu = RageUI.CreateSubMenu(mainmenu, "Espace VIP", "Vos avantages et récompenses :")
	local VipInfo, VipAt, VipLoading = nil, 0, false
	local function RefreshVip(force)
		if VipLoading or (not force and GetGameTimer() - VipAt < 5000) then return end
		VipLoading = true
		ESX.TriggerServerCallback('CorePickax:Vip:info', function(info) VipInfo = info or false VipAt = GetGameTimer() VipLoading = false end)
	end
	local JobStatus, JobStatusAt, JobStatusLoading = nil, 0, false
	local function RefreshJobStatus(force)
		if JobStatusLoading or (not force and GetGameTimer() - JobStatusAt < 4000) then return end
		if GetResourceState('pickax_jobbuilder') ~= 'started' then JobStatus = false return end
		JobStatusLoading = true
		ESX.TriggerServerCallback('jobbuilder:dutyStatus', function(list) JobStatus = list or {} JobStatusAt = GetGameTimer() JobStatusLoading = false end)
	end
	local editorMenu = RageUI.CreateSubMenu(Parametres, "Rockstar editor", "Que voulez-vous faire ?")
	local Facture = RageUI.CreateSubMenu(Informations, "Vos facture", "Que voulez-vous faire ?")
	local MenuVehicle = RageUI.CreateSubMenu(mainmenu, "Vehicule", "Que voulez-vous faire ?")
	local PrefsMenu = RageUI.CreateSubMenu(Parametres, "Apparence des menus", "Apparence de tous les menus :")
	local HudMenu = RageUI.CreateSubMenu(Parametres, "Affichage du HUD", "Choisissez ce qui s'affiche en haut à droite :")
	HudRefresh()
	PrefsRefresh()
	local PrefsColorLists, PrefsColorSel = {}, {}
	local function PrefsSyncSel()
		for i, def in ipairs(Prefs.Colors) do PrefsColorSel[i] = PrefsColorIndex(def, PrefsColorLists[i]) end
	end
	for i, def in ipairs(Prefs.Colors) do PrefsColorLists[i] = PrefsColorItems(def) end
	PrefsSyncSel()

	RageUI.Visible(mainmenu, not RageUI.Visible(mainmenu))

	while mainmenu do
		Wait(0)
		RageUI.IsVisible(mainmenu, true, true, true, function()
			RageUI.Separator("Connecté en tant qu'id [~p~"..GetPlayerServerId(PlayerId()).."~s~]")
			RageUI.ButtonWithStyle("Informations", "Votre profil, votre argent et vos factures", {RightLabel = "→→→"}, true, function() end, Informations)
			RageUI.ButtonWithStyle("Documents officiels", "Carte d'identité, permis de conduire et port d'armes", {RightLabel = "→→→"}, true, function() end, Docs)
			local inVeh = IsPedInAnyVehicle(PlayerPedId(), false)
			RageUI.ButtonWithStyle("Véhicule", inVeh and "Portes, fenêtres et limiteur de vitesse" or "Vous devez être dans un véhicule", {RightLabel = "→→→"}, inVeh, function() end, MenuVehicle)
			RageUI.ButtonWithStyle("Préférences", "Réglages du jeu, apparence des menus et performances", {RightLabel = "→→→"}, true, function() end, Parametres)
			RageUI.ButtonWithStyle("Espace VIP", "Avantages, récompense quotidienne et coffre VIP", {RightLabel = "→→→"}, true, function(_, _, sel) if sel then RefreshVip(true) end end, VipMenu)
			RageUI.ButtonWithStyle("Statut des entreprises", "Voir quelles entreprises ont un employé en service", {RightLabel = "→→→"}, true, function(_, _, s) if s then RefreshJobStatus(true) end end, StatusMenu)
			RageUI.Separator("Serveur")
			RageUI.ButtonWithStyle("Touches du serveur", "La liste des raccourcis clavier", {RightLabel = "→→→"}, true, function() end, KeysMenu)
			RageUI.ButtonWithStyle("Commandes du serveur", "Les commandes utiles pour les joueurs", {RightLabel = "→→→"}, true, function() end, CmdsMenu)
			RageUI.ButtonWithStyle("Serveur Discord", "Ouvre le lien du Discord dans votre navigateur", {RightLabel = "↗"}, true, function(_, _, s)
				if s then PrefsCall('OpenUrl', ConfigMenuF5.Links.Discord) end
			end)
			RageUI.ButtonWithStyle("Boutique du serveur", "Ouvre la boutique dans votre navigateur", {RightLabel = "↗"}, true, function(_, _, s)
				if s then PrefsCall('OpenUrl', ConfigMenuF5.Links.Boutique) end
			end)
		end)
		RageUI.IsVisible(PrefsMenu, true, true, true, function()
			RageUI.Separator("Apparence")
			RageUI.Checkbox("Afficher la bannière", "Affiche ou masque la bannière en haut des menus", PrefsCfg.banner, { Style = RageUI.CheckboxStyle.Tick }, function(Hovered, Selected, Active, Checked)
			end, function()
				PrefsSet('banner', true)
			end, function()
				PrefsSet('banner', false)
			end)
			RageUI.List("Style", PrefsStyleNames, PrefsStyleIndex(Prefs.Styles, PrefsCfg.style), "Change le design de tous les menus", {}, true, function() end, function(Index)
				PrefsSet('style', Prefs.Styles[Index].id)
			end)
			RageUI.List("Taille", PrefsSizeNames, PrefsStyleIndex(Prefs.Sizes, PrefsCfg.size), "Change la taille de tous les menus", {}, true, function() end, function(Index)
				PrefsSet('size', Prefs.Sizes[Index].id)
			end)
			RageUI.Separator("Sons")
			RageUI.Checkbox("Sons des menus", "Active ou désactive les sons de TOUTES les interfaces (menus, boutique, builders, dialogues PNJ, pause…)", PrefsCfg.sound, { Style = RageUI.CheckboxStyle.Tick }, function() end, function()
				PrefsSet('sound', true)
			end, function()
				PrefsSet('sound', false)
			end)
			RageUI.List("Volume des sons", PrefsVolumeNames, PrefsVolumeIndex(), "Volume des sons de toutes les interfaces", {}, true, function() end, function(Index)
				PrefsSet('volume', Index * 10)
				PrefsCall('Sound', 'click')
			end)
			RageUI.Separator("Couleurs")
			for i, def in ipairs(Prefs.Colors) do
				local items = PrefsColorLists[i]
				local off = def.noDefault and 0 or 1
				RageUI.List(def.label, items, PrefsColorSel[i], def.desc .. " - Entrée sur « Personnalisé » pour saisir un code #RRGGBB", {}, true, function(Hovered, Active, Selected, Index)
					PrefsColorSel[i] = Index
					if Selected and Index == #items then PrefsAskHex(def.key) end
				end, function(Index)
					if Index == #items then return end
					if not def.noDefault and Index == 1 then
						PrefsSet(def.key, '')
					else
						PrefsSet(def.key, def.presets[Index - off][1])
					end
				end)
			end
			RageUI.Separator("Forme")
			RageUI.List("Bords des boutons", PrefsBtnNames, PrefsRadiusIndex(Prefs.BtnRadius, PrefsCfg.btnRadius), "Carré, arrondi ou rond", {}, true, function() end, function(Index)
				PrefsSet('btnRadius', Prefs.BtnRadius[Index][1])
			end)
			RageUI.List("Bords des notifications", NotifyRadiusNames, PrefsRadiusIndex(NotifyRadius, NotifyGetRadius()), "Carré, arrondi ou très arrondi (s'applique à toutes vos notifications)", {}, true, function() end, function(Index)
				NotifySetRadius(NotifyRadius[Index][1])
			end)
			RageUI.List("Bords du menu", PrefsCardNames, PrefsRadiusIndex(Prefs.CardRadius, PrefsCfg.cardRadius), "Arrondi du cadre des menus", {}, true, function() end, function(Index)
				PrefsSet('cardRadius', Prefs.CardRadius[Index][1])
			end)
			RageUI.Line()
			RageUI.ButtonWithStyle("Réinitialiser l'apparence", "Revient au style par défaut", {}, true, function(_, _, s)
				if s then
					PrefsCall('ResetSettings')
					PrefsRefresh()
					PrefsSyncSel()
				end
			end)
		end)
		RageUI.IsVisible(Informations, true, true, true, function()
			RageUI.ButtonWithStyle("Mes factures", nil, {RightLabel = "→→→"}, true, function(_, _, s)
				if s then
					ESX.TriggerServerCallback('CorePickax:GetBills', function(bills)
                        BillData = bills
                        ESX.PlayerData = ESX.GetPlayerData()
                    end)
				end
			end, Facture)
			do
				local pd = ESX.GetPlayerData()
				local name = (((Identity and Identity.firstName) or pd.firstName or '') .. ' ' .. ((Identity and Identity.lastName) or pd.lastName or '')):gsub('^%s+', ''):gsub('%s+$', '')
				if name == '' then name = GetPlayerName(PlayerId()) end
				local cash, bank, black = 0, 0, 0
				for _, acc in ipairs(pd.accounts or {}) do
					if acc.name == 'money' then cash = acc.money elseif acc.name == 'bank' then bank = acc.money elseif acc.name == 'black_money' then black = acc.money end
				end
				local job = pd.job and ((pd.job.label or pd.job.name or '-') .. (pd.job.grade_label and (' - ' .. pd.job.grade_label) or '')) or '-'
				local labels = { 'Nom', 'ID', 'Métier', 'Liquide', 'Banque', 'Argent sale' }
				local values = { name, tostring(GetPlayerServerId(PlayerId())), job, '~g~' .. ESX.Math.GroupDigits(cash) .. '$~s~', '~b~' .. ESX.Math.GroupDigits(bank) .. '$~s~', '~r~' .. ESX.Math.GroupDigits(black) .. '$~s~' }
				RageUI.Info('Mon profil', labels, values)
			end
		end)
		RageUI.IsVisible(Docs, true, true, true, function()
			RageUI.Separator("~p~↓ Carte d'identité ↓~s~")
			RageUI.ButtonWithStyle("Montrer sa carte d'identité", nil, {RightLabel = "→→→"}, true, function(_, _, s)
				if s then
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

					if closestDistance ~= -1 and closestDistance <= 3.0 then
						TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(closestPlayer))
					else
                        ESX.ShowNotification('Aucun joueur à proximité')
					end
				end
			end)
			RageUI.ButtonWithStyle("Regarder sa carte d'identité", nil, {RightLabel = "→→→"}, true, function(_, _, s)
				if s then
					TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(PlayerId()))
				end
			end)
			RageUI.Separator("~p~↓ Permis de conduire ↓~s~")
			RageUI.ButtonWithStyle("Montrer son permis de conduire", nil, {RightLabel = "→→→"}, true, function(_, _, s)
				if s then
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

					if closestDistance ~= -1 and closestDistance <= 3.0 then
						TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(closestPlayer), 'driver')
					else
                        ESX.ShowNotification('Aucun joueur à proximité')
					end
				end
			end)
			RageUI.ButtonWithStyle("Regarder son permis de conduire", nil, {RightLabel = "→→→"}, true, function(_, _, s)
				if s then
					TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(PlayerId()), 'driver')
				end
			end)
			RageUI.Separator("~p~↓ Permis de port d'armes ↓~s~")
			RageUI.ButtonWithStyle("Montrer son permis de port d'armes", nil, {RightLabel = "→→→"}, true, function(_, _, s)
				if s then
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

					if closestDistance ~= -1 and closestDistance <= 3.0 then
						TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(closestPlayer), 'weapon')
					else
                        ESX.ShowNotification('Aucun joueur à proximité')
					end
				end
			end)
			RageUI.ButtonWithStyle("Regarder son permis de port d'armes", nil, {RightLabel = "→→→"}, true, function(_, _, s)
				if s then
					TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(PlayerId()), 'weapon')
				end
			end)
		end)
		RageUI.IsVisible(Parametres, true, true, true, function()
			RageUI.ButtonWithStyle("Apparence des menus", "Bannière, style, couleurs et forme de tous les menus", {RightLabel = "→→→"}, true, function() end, PrefsMenu)
			RageUI.ButtonWithStyle("Affichage du HUD", "Activer / désactiver le HUD (serveur, métier, argent) et arrondir les bords", {RightLabel = "→→→"}, true, function() end, HudMenu)
			RageUI.ButtonWithStyle("Performances (FPS)", "Allégez le rendu du jeu pour gagner des FPS", {RightLabel = "→→→"}, true, function() end, PerfMenu)
			RageUI.Separator("Jeu")
			RageUI.Checkbox("Désactiver les coups de crosse", nil, Action.Cross, { Style = RageUI.CheckboxStyle.Tick }, function(Hovered, Selected, Active, Checked)
                Action.Cross = Checked;
            end, function()
				-- Coup de cross
				CreateThread(function()
					while true do
						local timer = 200
						if IsPedArmed(PlayerPedId(), 6) then
							timer = 0
							DisableControlAction(1, 140, true)
							DisableControlAction(1, 141, true)
							DisableControlAction(1, 142, true)
						end
						if Breakable then
							Breakable = false
							break
						end

						Citizen.Wait(timer)
					end
				end)
            end, function()
				Breakable = true
            end)
			RageUI.Checkbox("Désactiver le radar", nil, Action.Radar, { Style = RageUI.CheckboxStyle.Tick }, function(Hovered, Selected, Active, Checked)
                Action.Radar = Checked;
            end, function()
				DisplayRadar(false)
            end, function()
				DisplayRadar(true)
            end)
			RageUI.Checkbox("Désactiver l'hud", nil, Action.Hud, { Style = RageUI.CheckboxStyle.Tick }, function(Hovered, Selected, Active, Checked)
                Action.Hud = Checked;
            end, function()
				DisplayHideHud(true)
            end, function()
				DisplayHideHud(false)
            end)
			RageUI.ButtonWithStyle("Rockstar editor", nil, {RightLabel = "→→→"}, true, function(_, _, s)
			end, editorMenu)
		end)
		RageUI.IsVisible(HudMenu, true, true, true, function()
			RageUI.Checkbox("Afficher le HUD", "Active ou désactive tout le HUD en haut à droite", HudCfg.hud, { Style = RageUI.CheckboxStyle.Tick }, function() end, function()
				HudSet('hud', true)
			end, function()
				HudSet('hud', false)
			end)
			RageUI.Separator("Parties du HUD")
			RageUI.Checkbox("Carte serveur", "Nom du serveur, votre ID et le nombre de joueurs", HudCfg.server, { Style = RageUI.CheckboxStyle.Tick }, function() end, function()
				HudSet('server', true)
			end, function()
				HudSet('server', false)
			end)
			RageUI.Checkbox("Carte métier", "Votre métier, votre grade et votre statut", HudCfg.job, { Style = RageUI.CheckboxStyle.Tick }, function() end, function()
				HudSet('job', true)
			end, function()
				HudSet('job', false)
			end)
			RageUI.Checkbox("Carte argent", "Liquide, argent sale et banque", HudCfg.money, { Style = RageUI.CheckboxStyle.Tick }, function() end, function()
				HudSet('money', true)
			end, function()
				HudSet('money', false)
			end)
			if GetResourceState('pickax_compass') == 'started' then
				local okC, cs = pcall(function() return exports['pickax_compass']:GetSettings() end)
				RageUI.Checkbox("Boussole", "Cap, points cardinaux, rue et quartier en haut de l'écran", okC and cs and cs.enabled, { Style = RageUI.CheckboxStyle.Tick }, function() end, function()
					exports['pickax_compass']:SetEnabled(true)
				end, function()
					exports['pickax_compass']:SetEnabled(false)
				end)
			end
			RageUI.Separator("Forme")
			RageUI.List("Taille du HUD", HudScaleNames, PrefsRadiusIndex(HudScale, HudCfg.scale), "Agrandit ou réduit tout le HUD", {}, true, function() end, function(Index)
				HudSet('scale', HudScale[Index][1])
			end)
			RageUI.List("Bords du HUD", HudRadiusNames, PrefsRadiusIndex(HudRadius, HudCfg.radius), "Carré, arrondi ou très arrondi", {}, true, function() end, function(Index)
				HudSet('radius', HudRadius[Index][1])
			end)
			RageUI.Line()
			RageUI.ButtonWithStyle("Réinitialiser le HUD", "Affiche tout et remet les bords par défaut", {}, true, function(_, _, s)
				if s then
					HudCall('ResetSettings')
					HudRefresh()
				end
			end)
		end)
		RageUI.IsVisible(PerfMenu, true, true, true, function()
			if PickaxPerf then
				local perf = PickaxPerf.Get()
				local names = {}
				for i, p in ipairs(PickaxPerf.Presets) do names[i] = p.name end
				local idx = PickaxPerf.PresetIndex()
				RageUI.List("Mode", names, idx, PickaxPerf.Presets[idx].desc, {}, true, function() end, function(Index)
					PickaxPerf.SetPreset(PickaxPerf.Presets[Index].id)
				end)
				RageUI.Checkbox("Afficher le compteur de FPS", "Affiche vos FPS en haut à droite de l'écran", perf.fps, { Style = RageUI.CheckboxStyle.Tick }, function() end, function()
					PickaxPerf.SetFps(true)
				end, function()
					PickaxPerf.SetFps(false)
				end)
			else
				RageUI.Separator("~r~Module de performances indisponible")
			end
		end)
		RageUI.IsVisible(VipMenu, true, true, true, function()
			RefreshVip(false)
			if VipInfo == nil then
				RageUI.ButtonWithStyle("~c~Chargement…", nil, {}, false, function() end)
			elseif VipInfo == false then
				RageUI.ButtonWithStyle("~r~Indisponible", nil, {}, false, function() end)
			else
				local function fmt(n) return tostring(n):reverse():gsub("(%d%d%d)", "%1 "):reverse():gsub("^ ", "") end
				local cur = VipInfo.tiers[VipInfo.level]
				if cur then
					local left = math.max(0, VipInfo.expiration - VipInfo.now)
					RageUI.Separator(cur.color .. cur.name .. "~s~ — " .. math.floor(left / 86400) .. " j " .. math.floor((left % 86400) / 3600) .. " h restants")
					RageUI.ButtonWithStyle("Récompense quotidienne", VipInfo.canClaim and "Récupérer votre récompense du jour" or "Déjà récupérée, revenez plus tard", {RightLabel = VipInfo.canClaim and "~g~Disponible~s~" or "~c~Indisponible~s~"}, VipInfo.canClaim, function(_, _, sel)
						if sel then
							ESX.TriggerServerCallback('CorePickax:Vip:claim', function(ok, msg) ESX.ShowNotification(msg or "") RefreshVip(true) end)
						end
					end)
					RageUI.ButtonWithStyle("Coffre VIP", cur.chestSlots .. " emplacements — " .. math.floor(cur.chestWeight / 1000) .. " kg", {RightLabel = "~b~Ouvrir~s~"}, true, function(_, _, sel)
						if sel then
							ESX.TriggerServerCallback('CorePickax:Vip:chest', function(ok, id)
								if ok then RageUI.CloseAll() exports.ox_inventory:openInventory('stash', id) else ESX.ShowNotification(id or "") end
							end)
						end
					end)
				else
					RageUI.Separator("~c~Vous n'êtes pas VIP")
				end
				for i, t in ipairs(VipInfo.tiers) do
					RageUI.Separator(t.color .. t.name .. (i == VipInfo.level and "~s~  ← votre niveau" or ""))
					RageUI.ButtonWithStyle("Salaire", nil, {RightLabel = "x" .. t.salaryMult}, true, function() end)
					RageUI.ButtonWithStyle("Poids d'inventaire", nil, {RightLabel = t.maxWeight .. " kg"}, true, function() end)
					RageUI.ButtonWithStyle("Coins boutique", nil, {RightLabel = "+" .. t.coinsPerHour .. " / heure"}, true, function() end)
					RageUI.ButtonWithStyle("Coffre VIP", nil, {RightLabel = t.chestSlots .. " empl. / " .. math.floor(t.chestWeight / 1000) .. " kg"}, true, function() end)
					RageUI.ButtonWithStyle("Récompense quotidienne", nil, {RightLabel = "$" .. fmt(t.daily.money) .. ((t.daily.coins or 0) > 0 and (" + " .. t.daily.coins .. " coins") or "")}, true, function() end)
				end
			end
		end)
		RageUI.IsVisible(StatusMenu, true, true, true, function()
			RefreshJobStatus(false)
			if JobStatus == false then
				RageUI.ButtonWithStyle("~r~Indisponible", "Le système d'entreprises n'est pas démarré", {}, false, function() end)
			elseif JobStatus == nil then
				RageUI.ButtonWithStyle("~c~Chargement…", nil, {}, false, function() end)
			elseif #JobStatus == 0 then
				RageUI.ButtonWithStyle("~c~Aucune entreprise", "Aucune entreprise n'a été créée", {}, false, function() end)
			else
				for _, j in ipairs(JobStatus) do
					RageUI.ButtonWithStyle(j.label, j.online and (j.count .. " employé(s) en service") or "Personne n'a pris son service", {RightLabel = j.online and ("~g~● En ligne (" .. j.count .. ")~s~") or "~r~● Hors ligne~s~"}, true, function() end)
				end
			end
		end)
		RageUI.IsVisible(KeysMenu, true, true, true, function()
			for _, k in ipairs(MenuKeys()) do
				RageUI.ButtonWithStyle(k[1], nil, {RightLabel = "~b~[" .. string.upper(tostring(k[2])) .. "]~s~"}, true, function() end)
			end
		end)
		RageUI.IsVisible(CmdsMenu, true, true, true, function()
			for _, c in ipairs(MenuCommands()) do
				RageUI.ButtonWithStyle(c[2], nil, {RightLabel = "~b~/" .. c[1] .. "~s~"}, true, function() end)
			end
		end)
		RageUI.IsVisible(editorMenu, true, true, true, function()
			RageUI.ButtonWithStyle("Lancer Record", nil, {RightLabel = "→→→"}, true, function(_, _, s)
				if s then
					if IsRecording() then
						ESX.ShowNotification("Vous êtes déjà en train d'enregistrer un clip, vous devez d'abord arrêter l'enregistrement avant de pouvoir recommencer à enregistrer.")
					else
						StartRecording(1)
					end
				end
			end)
			RageUI.ButtonWithStyle("Stoper Record", nil, {RightLabel = "→→→"}, true, function(_, _, s)
				if s then
					if not IsRecording() then
						ESX.ShowNotification("Vous n'êtes pas en train d'enregistrer un clip, vous devez d'abord démarrer l'enregistrement avant de pouvoir arrêter et enregistrer un clip.")
					else
						StopRecordingAndSaveClip()
					end
				end
			end)
		end)
		RageUI.IsVisible(Facture, true, true, true, function()
            if #BillData == 0 then
                RageUI.Separator('')
                RageUI.Separator('~r~Aucune facture')
                RageUI.Separator('')
            end
            for i = 1, #BillData, 1 do
                RageUI.ButtonWithStyle(BillData[i].label, nil, {RightLabel = '~g~$' .. ESX.Math.GroupDigits(BillData[i].amount)}, true, function(Hovered, Active, Selected)
                    if Selected then
                        ESX.TriggerServerCallback(ConfigMenuF5.Trigger.TriggerPayBill, function()
                            ESX.TriggerServerCallback('CorePickax:GetBills', function(bills) BillData = bills end)
                        end, BillData[i].id)
                    end
                end)
            end
		end)
		RageUI.IsVisible(MenuVehicle, true, true, true, function()
			RageUI.Separator("~r~Information~s~")
			RageUI.ButtonWithStyle("Nom du véhicule", nil, {RightLabel = "~p~"..GetDisplayNameFromVehicleModel(GetEntityModel(GetVehiclePedIsIn(PlayerPedId(), false)))}, true, function(_,_,s)
			end)
			RageUI.ButtonWithStyle("Plaque du véhicule", nil, {RightLabel = "~p~"..GetVehicleNumberPlateText(GetVehiclePedIsIn(PlayerPedId(), false))}, true, function(_,_,s)
			end)
			RageUI.ButtonWithStyle("État du moteur", nil, {RightLabel = "~p~"..math.floor(GetVehicleEngineHealth(GetVehiclePedIsIn(PlayerPedId(), false))/10) .."%"}, true, function(_,_,s)
			end)
			RageUI.Separator("~b~Multimédia~s~")
			RageUI.ButtonWithStyle("Ouvrir CarPlay", "Autoradio : musique YouTube, radios, volume…", {RightLabel = "→→→"}, true, function(_,_,s)
				if s then
					RageUI.CloseAll()
					CreateThread(function()
						Wait(300)
						TriggerEvent('carplay:client:open')
					end)
				end
			end)
			if (GetPedInVehicleSeat(GetVehiclePedIsIn(GetPlayerPed(-1), false), -1) == GetPlayerPed(-1)) then
				RageUI.Separator("~r~Actions~s~")
				RageUI.ButtonWithStyle("Allumer/Eteindre le moteur", nil, {RightLabel = "→→→"}, true, function(_,_,s)
					if s then
						local plyVeh = GetVehiclePedIsIn(PlayerPedId(), false)
						
						if GetIsVehicleEngineRunning(plyVeh) then
							SetVehicleEngineOn(plyVeh, false, false, true)
							SetVehicleUndriveable(plyVeh, true)
						elseif not GetIsVehicleEngineRunning(plyVeh) then
							SetVehicleEngineOn(plyVeh, true, false, true)
							SetVehicleUndriveable(plyVeh, false)
						end
					end
				end)
				RageUI.ButtonWithStyle("Ouvrir/Fermer le capot", nil, {RightLabel = "→→→"}, true, function(_,_,s)
					if s then
						local plyVeh = GetVehiclePedIsIn(PlayerPedId(), false)
						
						if GetVehicleDoorAngleRatio(plyVeh, 4) == 0 then
							SetVehicleDoorOpen(plyVeh, 4, false, false)
						else
							SetVehicleDoorShut(plyVeh, 4, false)
						end
					end
				end)
				RageUI.ButtonWithStyle("Ouvrir/Fermer le coffre", nil, {RightLabel = "→→→"}, true, function(_,_,s)
					if s then
						local plyVeh = GetVehiclePedIsIn(PlayerPedId(), false)
						
						if GetVehicleDoorAngleRatio(plyVeh, 5) == 0 then
							SetVehicleDoorOpen(plyVeh, 5, false, false)
						else
							SetVehicleDoorShut(plyVeh, 5, false)
						end
					end
				end)
				RageUI.ButtonWithStyle("Fermer toutes les portes", nil, {RightLabel = "→→→"}, true, function(_,_,s)
					if s then
						local plyVeh = GetVehiclePedIsIn(PlayerPedId(), false)

						SetVehicleDoorShut(plyVeh, 0, false)
						SetVehicleDoorShut(plyVeh, 1, false)
						SetVehicleDoorShut(plyVeh, 2, false)
						SetVehicleDoorShut(plyVeh, 3, false)
						SetVehicleDoorShut(plyVeh, 4, false)
						SetVehicleDoorShut(plyVeh, 5, false)
					end
				end)
				RageUI.List('Ouvrir/Fermer Fenêtre', Action.WindowsList, Action.WindowsIndex, nil, {}, true, function(Hovered, Active, Selected, Index)
					Action.WindowsIndex = Index

					if (Selected) then
						local plyVeh = GetVehiclePedIsIn(PlayerPedId(), false)

						if Index == 1 then
							if not Action.WindowsState.FrontLeft then
								Action.WindowsState.FrontLeft = true
								RollDownWindow(plyVeh, 0)
							elseif Action.WindowsState.FrontLeft then
								Action.WindowsState.FrontLeft = false
								RollUpWindow(plyVeh, 0)
							end
						elseif Index == 2 then
							if not Action.WindowsState.FrontRight then
								Action.WindowsState.FrontRight = true
								RollDownWindow(plyVeh, 1)
							elseif Action.WindowsState.FrontRight then
								Action.WindowsState.FrontRight = false
								RollUpWindow(plyVeh, 1)
							end
						elseif Index == 3 then
							if not Action.WindowsState.BackLeft then
								Action.WindowsState.BackLeft = true
								RollDownWindow(plyVeh, 2)
							elseif Action.WindowsState.BackLeft then
								Action.WindowsState.BackLeft = false
								RollUpWindow(plyVeh, 2)
							end
						elseif Index == 4 then
							if not Action.WindowsState.BackRight then
								Action.WindowsState.BackRight = true
								RollDownWindow(plyVeh, 3)
							elseif Action.WindowsState.BackRight then
								Action.WindowsState.BackRight = false
								RollUpWindow(plyVeh, 3)
							end
						end
					end
				end)

				RageUI.List('Ouvrir/Fermer Porte', Action.DoorList, Action.DoorIndex, nil,{}, true, function(Hovered, Active, Selected, Index)
					Action.DoorIndex = Index

					if (Selected) then
						local plyVeh = GetVehiclePedIsIn(PlayerPedId(), false)

						if Index == 1 then
							if not Action.DoorState.FrontLeft then
								Action.DoorState.FrontLeft = true
								SetVehicleDoorOpen(plyVeh, 0, false, false)
							elseif Action.DoorState.FrontLeft then
								Action.DoorState.FrontLeft = false
								SetVehicleDoorShut(plyVeh, 0, false, false)
							end
						elseif Index == 2 then
							if not Action.DoorState.FrontRight then
								Action.DoorState.FrontRight = true
								SetVehicleDoorOpen(plyVeh, 1, false, false)
							elseif Action.DoorState.FrontRight then
								Action.DoorState.FrontRight = false
								SetVehicleDoorShut(plyVeh, 1, false, false)
							end
						elseif Index == 3 then
							if not Action.DoorState.BackLeft then
								Action.DoorState.BackLeft = true
								SetVehicleDoorOpen(plyVeh, 2, false, false)
							elseif Action.DoorState.BackLeft then
								Action.DoorState.BackLeft = false
								SetVehicleDoorShut(plyVeh, 2, false, false)
							end
						elseif Index == 4 then
							if not Action.DoorState.BackRight then
								Action.DoorState.BackRight = true
								SetVehicleDoorOpen(plyVeh, 3, false, false)
							elseif Action.DoorState.BackRight then
								Action.DoorState.BackRight = false
								SetVehicleDoorShut(plyVeh, 3, false, false)
							end
						end
					end
				end)

				RageUI.List('Limitateur', Action.LimitateurList, Action.LimitateurIndex, nil,{}, true, function(Hovered, Active, Selected, Index)
					Action.LimitateurIndex = Index

					if (Selected) then
						local plyVeh = GetVehiclePedIsIn(PlayerPedId(), false)

						if Index == 1 then
							ESX.ShowNotification('Le ~b~limitateur~s~ est ~g~activée ~s~à ~o~50 Km/h.')
							SetVehicleMaxSpeed(plyVeh, 49/3.6)
						elseif Index == 2 then
							ESX.ShowNotification('Le ~b~limitateur~s~ est ~g~activée ~s~à ~o~80 Km/h.')
							SetVehicleMaxSpeed(plyVeh, 79/3.6)
						elseif Index == 3 then
							ESX.ShowNotification('Le ~b~limitateur~s~ est ~g~activée ~s~à ~o~120 Km/h.')
							SetVehicleMaxSpeed(plyVeh, 119/3.6)
						elseif Index == 4 then
							local AAA = ESXCustom_Function_ClientSide:KeyboardInput("Limitateur personnaliser", 3)

							if AAA ~= nil then
								ESX.ShowNotification("Le ~b~limitateur~s~ est ~g~activée ~s~à ~o~"..tonumber(AAA).." Km/h.")
								SetVehicleMaxSpeed(plyVeh, tonumber(AAA-1)/3.6)
							end
						elseif Index == 5 then
							ESX.ShowNotification('Le ~b~limitateur~s~ est ~r~desactivée')
							SetVehicleMaxSpeed(plyVeh, 1000/3.6)
						end
					end
				end)
			end
		end)

		if not RageUI.Visible(mainmenu) and not RageUI.Visible(Informations) and not RageUI.Visible(Parametres) and not RageUI.Visible(PrefsMenu) and not RageUI.Visible(HudMenu) and not RageUI.Visible(Docs) and not RageUI.Visible(PerfMenu) and not RageUI.Visible(KeysMenu) and not RageUI.Visible(CmdsMenu) and not RageUI.Visible(StatusMenu) and not RageUI.Visible(VipMenu) and not RageUI.Visible(editorMenu) and not RageUI.Visible(Facture) and not RageUI.Visible(MenuVehicle) then
			mainmenu = RMenu:DeleteType("mainmenu")
		end
	end
end

--Register
RegisterKeyMapping(ConfigMenuF5.Commande.CommandeName, ConfigMenuF5.Commande.DescCommande, 'keyboard', ConfigMenuF5.Commande.Bind)

RegisterCommand(ConfigMenuF5.Commande.CommandeName, function()
	OpenMenu()
end)