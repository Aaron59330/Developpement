ConfigJail = {
	MaxJail = 15,		-- durée maximale (minutes) pour la commande /jail du staff
	MaxJailPolice = 60,	-- durée maximale (minutes) pour les peines données par la police (pickax_illegalbuilder : /emprisonner)
	LieuJail = vector3(1641.6, 2571.0, 45.5),
	LieuUnJail = vector3(1857.28, 2605.16, 45.67),

	adminRanks = {
		"_dev",
        "superadmin",
        "admin",
        "mod",
    },

	Commande = {
		jail = "jail",
		unjail = "unjail",
		OpenMenu = "gestionjail"
	},

	TenueJail = {
		male = {
			['tshirt_1'] = 15,  ['tshirt_2'] = 0,
			['torso_1']  = 5, 	['torso_2']  = 0,
			['decals_1'] = 0,   ['decals_2'] = 0,
			['arms']     = 5,   ['arms_2']   = 0,   
			['pants_1']  = 9,	['pants_2']  = 4,   
			['shoes_1']  = 8,	['shoes_2']  = 0,  	
			['chain_1']  = 0,	['chain_2']  = 0,
			['helmet_1'] = -1,  ['helmet_2'] = 0,
			['bag_1'] 	 = 0,   ['bag_2'] = 0
		},
		female = {
			['tshirt_1'] = 15,  ['tshirt_2'] = 0,
			['torso_1']  = 14, 	['torso_2']  = 3,
			['decals_1'] = 0,   ['decals_2'] = 0,
			['arms']     = 14,   ['arms_2']   = 0,   
			['pants_1']  = 45,	['pants_2']  = 1,   
			['shoes_1']  = 24,	['shoes_2']  = 0,  	
			['chain_1']  = 0,	['chain_2']  = 0,
			['helmet_1'] = -1,  ['helmet_2'] = 0,
			['bag_1'] 	 = 0,   ['bag_2'] = 0
		}
	},

	Menu = {
		["Title"] = "Jail",
		["Substitle"] = "Que voulez-vous faire ?",
		["Jail"] = "Jail par : %s",
		["Temps"] = "Temps : %s",
		["Raison"] = "Raison : %s"
	},

	Notification = {
		["SetJailAfterConnexion"] = "Vous avez été remis à votre position, en jail.",
		["CantFleePrison"] = "Vous ne pouvez pas sortir de la prison !",

		["Error1"] = "Veuillez mettre un ID.",
		["Error2"] = "Veuillez mettre un temps.",
		["Error3"] = "Veuillez mettre une raison.",
		["Error4"] = "Le joueur n'est pas sur le serveur.",
		["Error5"] = "Vous ne pouvez pas faire ceci à vous même.",
		["Error6"] = "Le joueur est déjà en jail.",
		["Error7"] = "~r~Le temps ne peut être supérieur à 15 minutes.",
		["Error8"] = "Veuillez mettre un temps entre 1 à 15.",
		["Error9"] = "Le joueur n'est pas en jail.",

		["UJail"] = "Vous avez bien jail l'id : %s",
		["Uunjail"] = "Vous avez bien unjail l'id : %s",
		["MessageSendAfterUnjail"] = "La prochaine arrête de faire n'importe quoi",

		["GestionStaffTitle"] = "Gestion staff",
		["GestionStaffSubsTitle"] = "Que voulez-vous faire ?",
		["GestionStaffTitle2"] = "Gestion staff",
		["GestionStaffSubsTitle2"] = "Que voulez-vous faire ?",
		["ButonPlayer"] = "%s (ID : ~b~%s~s~)",
		["DescPlayer"] = "~y~Faites entrée pour plus d'informations~s~",
		["ButonPlayer2"] = "Unjail %s (~b~%s~s~)",
		["DescPlayer2"] = "~y~Raison de son jail : %s~s~",

		--Logs
		["LogsFinishJail"] = "Le joueur : **%s** à fini son jail",
		["LogsJail"] = "Le staff : [**%s**] à jail : **%s** pendant : **%s** minutes avec raison : **%s**",
		["LogsUnjail"] = "Le staff : [**%s**] à unjail : **%s**"
	}
}

--Serveur function
function AddonToSetPedInJail(source)
	--Exemple:--SetPedArmour(GetPlayerPed(source), 0)
end

function AddonToUnJailFunction(source)
	-- Exemple:--SetPedArmour(GetPlayerPed(source), 100)
end