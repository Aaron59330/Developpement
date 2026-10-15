ConfigArmesPrem = {
    Text = "Appuyer sur ~INPUT_CONTEXT~ pour intéragir",
    Marker = {
        Position = {
            [1] = {Pose = vector3(4.5029311180115, -1106.4975585938, 28.891997909546)},
        },
        Type = 6,
        Color = {r = 0, g = 128, b = 255},
        Size = {x = 1.0, y = 1.0, z = 1.0},
        Rotation = {x = -90.0, y = 0.0, z = 90.0},
    }
}

--[[--Nouvelle Table Arme perm
    CREATE TABLE IF NOT EXISTS `coffre_armeperm` (
        `id` int NOT NULL AUTO_INCREMENT,
        `armes` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
        `munitions` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL,
        `identifier` varchar(55) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
        `label` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL,
        `name` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL,
        PRIMARY KEY (`id`)
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
]]--