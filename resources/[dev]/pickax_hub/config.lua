Config = {}

Config.Command = 'hub'                -- /hub ouvre le menu (F5 l'ouvre aussi : pickax_core/players/menupersonnel → ConfigMenuF5.UseHub)
Config.Key     = nil                  -- touche propre au hub (nil = aucune, on garde F5 du menu personnel)
Config.Accent  = nil                  -- nil = couleur du serveur (pickax_core/config.lua → AccentColor). Mets '#RRGGBB' pour forcer une autre couleur

Config.DefaultMode = 'new'            -- menu proposé par défaut : 'new' (ce menu) ou 'classic' (ancien menu RageUI). Chaque joueur peut changer dans Préférences
Config.ClassicCommand = 'menuF5'      -- commande de l'ancien menu (pickax_core/players/menupersonnel)

Config.Links = {                      -- onglet « Liens » (https uniquement)
    Discord  = 'https://' .. ((PickaxTheme and PickaxTheme.discord) or 'discord.gg/bluebayrp'),
    Boutique = 'https://bluebayrp.tebex.io/',
}

Config.Limiter = { 50, 80, 120 }      -- vitesses proposées pour le limitateur (km/h)
Config.ShowDirty = true               -- afficher l'argent sale dans le portefeuille

-- Listes des réglages d'apparence (identiques au menu personnel d'origine)
Config.Styles = { { 'noir', 'Noir' }, { 'verre', 'Verre' }, { 'clair', 'Clair' }, { 'neon', 'Néon' }, { 'bleu', 'Couleur du serveur' } }
Config.Sizes  = { { 'sm', 'Petit' }, { 'md', 'Moyen' }, { 'lg', 'Grand' } }
Config.BtnRadius  = { { 0, 'Carré' }, { 6, 'Léger' }, { 12, 'Arrondi' }, { 18, 'Très arrondi' }, { 24, 'Fort arrondi' }, { 999, 'Rond' } }
Config.CardRadius = { { 0, 'Carré' }, { 8, 'Léger' }, { 14, 'Arrondi' }, { 18, 'Standard' }, { 24, 'Très arrondi' }, { 28, 'Fort arrondi' } }
Config.NotifyRadius = { { -1, 'Défaut' }, { 0, 'Carré' }, { 6, 'Léger' }, { 11, 'Arrondi' }, { 18, 'Très arrondi' }, { 26, 'Fort arrondi' } }
Config.HudRadius = { { 0, 'Carré' }, { 6, 'Léger' }, { 12, 'Arrondi' }, { 18, 'Très arrondi' }, { 24, 'Fort arrondi' } }
Config.HudScale  = { { 70, 'Très petit' }, { 85, 'Petit' }, { 100, 'Normal' }, { 115, 'Grand' }, { 130, 'Très grand' } }
Config.Colors = {
    { key = 'accent', label = 'Couleur principale', presets = { { '#00a4ff', 'Serveur' }, { '#ef4444', 'Rouge' }, { '#22c55e', 'Vert' }, { '#a855f7', 'Violet' }, { '#f97316', 'Orange' }, { '#ec4899', 'Rose' }, { '#eab308', 'Jaune' }, { '#f4f4f5', 'Blanc' } } },
    { key = 'bg', label = 'Fond du menu', def = true, presets = { { '#0b0b0c', 'Noir' }, { '#1c1f26', 'Anthracite' }, { '#0a1a3a', 'Bleu nuit' }, { '#1a1030', 'Violet foncé' }, { '#0d1f17', 'Vert foncé' }, { '#2a0f14', 'Bordeaux' }, { '#f7f7f5', 'Blanc' } } },
    { key = 'text', label = 'Texte', def = true, presets = { { '#f4f4f5', 'Blanc' }, { '#c9c9ce', 'Gris clair' }, { '#111114', 'Noir' }, { '#cfe6ff', 'Bleu clair' }, { '#fde68a', 'Doré' } } },
}

-- Statut des entreprises (onglet Informations) : jobs jamais affichés
Config.HideJobs = { 'unemployed', 'unemployed2' }
