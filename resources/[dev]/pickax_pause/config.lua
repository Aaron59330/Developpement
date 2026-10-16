Config = {}

Config.ServerName = 'Bluebay Roleplay'
Config.Tagline    = 'RP sérieux · Free-Access'

-- Ouverture : ÉCHAP (et P). Le vrai menu pause GTA reste accessible via les boutons « Carte » / « Paramètres ».
Config.OpenKeys   = { 200, 199 }
Config.Cooldown   = 600            -- ms : évite de rouvrir le menu juste après l'avoir fermé avec ÉCHAP
Config.BlurScreen = true

-- Onglets du menu pause GTA (PauseMenuceptionGoDeeper) : adapte-les si besoin
Config.FrontendTabs = { map = 0, settings = 6 }

-- Raccourcis affichés dans le menu (url ouverte dans le navigateur) — laisse vide pour masquer
Config.Links = {
    { label = 'Discord',    icon = 'discord', url = 'https://discord.gg/bluebayrp' },
    { label = 'Règlement',  icon = 'book',    url = '' },
    { label = 'Boutique',   icon = 'cart',    url = '' },
}

-- Boutons du menu (true / false)
Config.Buttons = { resume = true, map = true, settings = true, disconnect = true, quit = true }
