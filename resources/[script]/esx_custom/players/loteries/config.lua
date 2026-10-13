ConfigLotery = {
    Marker = {
        Distance = 20.0,
        PushEDistance = 3.0,
        MarkerDebug = 0.0,
        MarkerType = 22,
		Scale = {x = 0.3, y = 0.3, z = 0.3},
		Color = {r = 0, g = 0, b = 255, a = 255},
		BobUpAndDown = true,
		FaceCamera = true,
		Rotate = true,
    },

    Pos = {
        [1] = {x = -558.5, y = -619.05, z = 34.68, a = 200.89}
    },

    Price = 100,-- Prix du ticket
    PriceByTicket = 10000,--montant ajouté pour le gain
    Text = "Merci pour votre achat, bonne chance à vous.",
    Text2 = "Un nouveau ticket à été acheter à la loterie, le gains de la cagnotte s'élève à ~g~%s$~s~",
    ShowHelp = "Appuyez sur ~INPUT_PICKUP~ pour ouvrir la Loterie."
}

--[[
    CREATE TABLE IF NOT EXISTS `lotery` (
    `id` int NOT NULL AUTO_INCREMENT,
    `identifier` varchar(255) DEFAULT NULL,
    `code` varchar(255) DEFAULT NULL,
    `win` int DEFAULT '0',
    `gain` int DEFAULT NULL,
    PRIMARY KEY (`id`)
    );
]]--