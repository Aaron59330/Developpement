Config = {}

Config.Framework = 'es_extended'
Config.StatusMax = 1000000
Config.StatusUpdateInterval = 500
Config.HideDefaultHud = true

-- Barre de vie sous la minimap. Valeurs en vh (la minimap GTA suit la HAUTEUR de l'écran : l'alignement reste bon en 16:9, 21:9...).
-- Si la barre ne colle pas exactement à ta minimap, ajuste Left / Width (et Bottom pour l'espace sous la carte).
Config.Health = {
    Enabled = true,
    ShowArmor = true,          -- fine ligne d'armure en haut de la barre (visible seulement si le joueur porte un gilet)
    Left = '2.8vh',            -- bord gauche de la barre = bord gauche de la minimap
    Bottom = '0.55vh',         -- distance depuis le bas de l'écran
    Width = '24.8vh',          -- largeur = largeur de la minimap
    Height = 13,               -- épaisseur en px
}
