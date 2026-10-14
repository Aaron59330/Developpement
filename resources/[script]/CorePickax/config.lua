Config = {
	DisableTitle = true,--Si vous utilisez une bannière alors mettez true pour enlever le title des menu en RageUI si nécessaire
	DisableMenuskin = false,--Mettre true si vous utiliser un autre skinMenu

	Trigger = {
        TriggerESX = "esx:getSharedObject",
		TriggerNotification = "esx:showNotification",
		TriggerAdvancedNotification = "esx:showAdvancedNotification",
		TriggerBilling = 'esx_billing:sendBill',
    },

	HandcuffFreezePlayer = false,--Si vous voulez que les menotte freeze les joueurs mettez en true.
	DisableKeysWhenHandcuff = {--à ajouté pour que les joueurs soit brider.
		{group = 2, key = 37},
		{group = 0, key = 24},
		{group = 0, key = 69},
		{group = 0, key = 92},
		{group = 0, key = 140},
		{group = 0, key = 106},
		{group = 0, key = 68},
		{group = 0, key = 69},
		{group = 0, key = 70},
		{group = 0, key = 71},
		{group = 0, key = 72},
		{group = 0, key = 75},
		{group = 0, key = 23},
		{group = 0, key = 21},
		{group = 1, key = 157},
		{group = 1, key = 158},
		{group = 1, key = 159},
		{group = 1, key = 160},
		{group = 1, key = 161},
		{group = 1, key = 162},
		{group = 1, key = 163},
		{group = 1, key = 164},
		{group = 1, key = 165},
	},

	WantToUseME = true,--Si vous ne voulez pas les /me automatique mettez en false.
	HaveJob2SQL = true,--a mettre sur true si vous avez une base possdent le jobs2 & jobs2_grades sql
	Debug = false,
	Snow = false,--Mettre true si vous voulez mettre la neige
	SynchroRealTime = true,--Mettre true si vous voulez lheure de IRL (les commandes /time, /morning, /noon… la suspendent ; /realtime la rétablit)
	RealTimeUtcOffset = 2,--Décalage horaire de l'heure réelle par rapport à UTC (France : 2 en été, 1 en hiver)

    Licensestaff = {--License pour allow la météo et les acces au maintenance
        ["license:0155311d5350cbfe73f6d33c117fd0b8675be1e8"] = true
    },

	MaxSalary = 5000,--évite que les boss abuse sur les salaires

	ArmesPerm = {
		["WEAPON_PISTOL_MK2"] = true,
		["WEAPON_SMG_MK2"] = true,
		["WEAPON_SNSPISTOL_MK2"] = true,
		["WEAPON_ASSAULTRIFLE_MK2"] = true
	},

	HandsupRequired = true,--mettre false si vous voulez que vous n'ayez pas besoin de lever les mains
    AnimationsHandsupList = {
        {dict = "missminuteman_1ig_2", anim = "handsup_base"},
        {dict = "mp_arresting", anim = "idle"},
    },


    RageUI = {
		NewRageUI = true,--Mettre false pour l'ancien menu
		ColorStyle = {
			R = 10,
			G = 39,
			B = 206,
			A = 255
		},

		TitleStyle = 6,
		TitleScale = 1.0,
		ScaleText = 0.29,
		MenuPose = {X = 0, Y = 25},
		ColorMenu = {Default = true, R = 0, G = 0, B = 0, A = 255},--Pour que le RGBA soit changer mettez le default en false
		Width = 0,
		MaxBoutton = 10,

		ColorButon = {
			R = 0,
			G = 168,
			B = 255,
			A = 255
		},

		Line = {
			R = 0,
			G = 168,
			B = 255,
			A = 255
		},
	}
}


-- Style global de tous les markers de cette ressource.
-- Modifier uniquement ces valeurs pour changer tous les DrawMarker.
Config.GlobalMarker = {
    Enabled = true,
    Type = 23,
    Size = { x = 1.0, y = 1.0, z = 0.5 },
    Color = { r = 0, g = 150, b = 255, a = 150 },
    BobUpAndDown = false,
    FaceCamera = false,
    Rotate = false,
    DrawOnEnts = false,

    -- Placement automatique au sol.
    Grounded = true,
    AutoGround = true,

    -- Décalage général après détection du sol. Laisse 0.0 pour coller au GroundZ réel.
    GroundOffset = 0.10,

    -- Compensation visuelle automatique pour les markers plats.
    -- Le type 23 a besoin d'être très légèrement enfoncé pour être visuellement posé au sol.
    AutoVisualGroundOffset = true,
    Type23GroundOffset = -0.10,

    -- Le systeme refuse une surface trop eloignee du Z configure.
    -- Cela evite qu'un marker dans un parking/MLO saute sur un autre etage.
    MaxGroundSnapDistance = 6.0,

    -- Rayon vertical de secours autour du marker.
    GroundRayUp = 1.5,
    GroundRayDown = 6.0,

    -- Sondes progressives : la surface la plus proche du Z original gagne.
    GroundProbeSteps = { 0.35, 0.75, 1.25, 2.0, 3.0, 5.0, 8.0, 15.0, 30.0, 50.0 },

    GroundCachePrecision = 1,
    GroundCacheLimit = 4096
}


-- Style des menus RageUI.
-- Couleurs : {rouge, vert, bleu, opacité}, de 0 à 255.
RageUIStyle = {
    BannerGlare = false, -- Désactive le reflet GTA au-dessus de ta bannière.
    Background = {77, 77, 77, 170},           -- Fond du menu
    Shadow = {20, 25, 34, 85},               -- Ombre
    Button = {55, 151, 255, 255},            -- Bouton sélectionné

    Text = {225, 229, 236, 255},             -- Texte des boutons
    SelectedText = {255, 255, 255, 255},     -- Texte sélectionné
    DisabledText = {145, 151, 162, 255},     -- Texte désactivé
    Subtitle = {195, 202, 214, 255},         -- Sous-titre

    CounterBackground = {35, 42, 55, 220},   -- Fond du compteur
    CounterText = {232, 238, 248, 255},      -- Texte du compteur

    Separator = {55, 151, 255, 255},         -- Lignes et accents
    SeparatorText = {165, 177, 195, 255},    -- Titres des catégories
    SeparatorLine = {165, 177, 195, 55},     -- Traits discrets

    DescriptionBackground = {48, 55, 68, 235},
    DescriptionText = {222, 229, 240, 255},

    InfoBackground = {48, 55, 68, 235},      -- Panneau à droite
    InfoTitle = {255, 255, 255, 255},
    InfoLabel = {174, 193, 221, 255},
    InfoValue = {240, 244, 252, 255},

    Font = 0,
    DescriptionScale = 0.30,
    InfoScale = 0.30,
    InfoTitleScale = 0.36,

    -- true : conserve les couleurs ~r~, ~p~, etc. de tes scripts.
    -- false : applique les couleurs ci-dessus aux descriptions et infos.
    KeepTextCodes = true,
	
}