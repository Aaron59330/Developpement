ConfigBoiteAGant = {
	MaxCoffreItem = 25,

	WeaponItem = false,--arme en items

	MenuEtNotification = {
		["PushE"] = "Appuyez sur ~INPUT_PICKUP~ pour ouvrir la boîte à gant.",
		["Deposit"] = "Vous avez deposer x%s %s",
		["Retirer"] = "Vous avez retirer x%s %s",
		
		["ammo"] = "Munition(s) : ~r~x%s~s~",
		["rightlabel"] = "x~y~%s",

		TakeMenu = {
			["Separator"] = "Boîte à gant : %s / %s",
			["Bouton"] = "%s",
			["RightLabel"] = "~g~x%s",
		},

		["Trier"] = "Trier par :",
		["BoiteGantsPleins"] = "~r~Votre coffre est pleins !",
		["ErrorQuantity"] = "~r~Quantité invalide",
		["Error2"] = "Veuillez indiquer des chiffres",
		["Input"] = "Indiquer le montant"
	},

	Menu = {
		TitleMenu = "Menu Boîte à gant",
		SubtitleMenu = "Que voulez-vous faire ? [~y~%s~s~]",

		{
			type = "Line"
		},
		{
			type = "Bouton",
			title = "Déposer des items",
			desc = nil,
			RightLabel = "→→→",
			OnClick = function(plaque)
				OpenMenuDeposerBoiteGant()
			end
		},
		{
			type = "Bouton",
			title = "Prendre des items",
			desc = nil,
			RightLabel = "→→→",
			OnClick = function(plaque)
				OpenMenuPrendreBoiteGant()
			end
		},
		{
			type = "Line"
		},
	},
}