ConfigMenuF5 = {
	Trigger = {
		TriggerUseItem = 'esx:useItem',
		TriggerGiveItem = 'esx:giveInventoryItem',
		TriggerPayBill = 'esx_billing:payBill'
    },

	Commande = {
        CommandeName = "menuF5",
        DescCommande = "Menu F5",
        Bind = "F5"
    },

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
	}
}

function DisplayHideHud(stats)
	if stats then
		--Activer HUD
		TriggerEvent("tempui:toggleUi", true)
	else
		--Desactiver HUD
		TriggerEvent("tempui:toggleUi", false)
	end
end