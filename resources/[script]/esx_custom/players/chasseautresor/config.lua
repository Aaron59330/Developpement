ConfigChasseAuTresor = {
	CommandeName = "chasseautresor",
	Cooldown = 600000,--Nombre de miliseconde pour refaire un event ! (10 minutes par defaut)

	Blips = {
		Name = "Chasse au trésor",
		Sprite = 587,
		Colour = 66,
		Scale = 1.0
	},

	CoffreTresor = {--Position des coffres lambda
		vector3(499.63, 5607.63, 795.67),
		vector3(1789.34, -1541.54, 112.26),
		vector3(1057.844, 4217.778, 35.05126),
		vector3(-2288.329, 210.894, 167.6019)
	},

	AcePermActive = false,-- Mettre true si vous souhaitez mettre les permissions que par Ace.
	AcePerm = "ChasseAuTresor.Staff",--add_ace group.superadmin ChasseAuTresor.Staff allow a mettre dans le cfg
	GroupAcces = {
		"_dev",
		"superadmin"
	},

	WinJustMoney = false,--Mettre true si vous voulez gagner que de l'argent
	WinMoney = math.random(5000, 8000),--Vous gagnerez entre 5000 et 8000 (si vous ne touchez pas)

	ListItemWin = {
		[1] = {
			Item = "water",
			Label = "Eau",
			Amount = 2
		},
		[2] = {
			Item = "bread",
			Label = "Pain",
			Amount = 5
		}
	},

	distance = 2,
	
	Notification = {
		["EventStart"] = "Une chasse au trésor vien de commencer, regarder votre carte pour voir !",
		["EventStop"] = "La chasse au trésor est terminé\nVous avez échoué !",
		["EventCantStart"] = "Vous ne pouvez pas lancer maintenant une chasse au tresor car vous devez attendre encore : %ss",
		["PressE"] = "Appuyez sur ~INPUT_PICKUP~ pour ouvrir le coffre au trésor",
		["WinMoney"] = "Toutes nos félicitations !\nVous êtes le premier à avoir trouvé le coffre au trésor et il y avait %s$ dedans !",
		["WinItem"] = "Toutes nos félicitations !\nVous avez trouvé un coffre au trésor contenant x%s %s !",
		["MaybeCheat"] = "Désynchronisation avec le serveur ou Detection de Cheat (si vous pensez que c'est une erreur, Merci de vous rendre sur notre discord.gg/votreinvite !)",
		["DontSpam"] = "Merci de ne pas spam l'event",
		["SpamEvent"] = "Vous avez trop spam l'event",

		--Notif discord :
		["NotifDiscord"] = "%s à trouvé le coffre, il à gagner : %s$",
		["NotifDiscord2"] = "%s à trouvé le coffre, il à gagner : x%s %s !",
		["NotifDiscord3"] = "Une chasse au trésor a été démarrer par %s."
	}
}