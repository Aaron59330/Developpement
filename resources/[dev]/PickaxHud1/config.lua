Config = {}

Config.Framework = 'es_extended'
Config.StatusMax = 1000000
Config.StatusUpdateInterval = 500
Config.HideDefaultHud = true

-- Barre de vie sous la minimap (positions en CSS : vw / vh / px — à ajuster si la barre ne colle pas exactement à ta minimap)
Config.Health = {
    Enabled = true,
    ShowArmor = true,          -- fine barre d'armure au-dessus de la vie (visible seulement si le joueur porte un gilet)
    Left = '1.6vw',            -- distance depuis le bord gauche de l'écran
    Bottom = '0.9vh',          -- distance depuis le bas de l'écran
    Width = '11.8vw',          -- largeur (celle de la minimap)
    Height = 15,               -- épaisseur en px
}
