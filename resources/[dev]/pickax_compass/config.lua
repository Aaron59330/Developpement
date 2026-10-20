Config = {}

Config.DefaultEnabled = true     -- affichée par défaut (chaque joueur peut la couper : menu personnel → Affichage du HUD → Boussole)
Config.OnFootOnly     = false    -- true = seulement à pied
Config.Layout         = 'compact' -- 'compact' = petite boussole en bas à gauche, à droite des jauges faim / soif ; 'top' = grande bande en haut au centre
Config.Compact = {                -- position de la version compacte (unités CSS : vw / vh / px) — à ajuster si tes jauges faim / soif sont ailleurs
    left   = '19.6vw',
    bottom = '3.4vh',
    width  = 210,                 -- largeur en pixels
}
Config.ShowStreet     = true     -- nom de rue sous la boussole (la version « top » ajoute aussi le quartier)
Config.Refresh        = 33       -- ms entre deux mises à jour du cap (plus petit = plus fluide)
Config.HideWhenMapOpen = true    -- masquée quand la carte du menu pause est ouverte
