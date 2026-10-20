Config = {}

Config.TypeSpeed   = 28        -- millisecondes par lettre (le texte s'écrit comme si le PNJ parlait)
Config.Camera      = true      -- léger zoom caméra sur le PNJ pendant qu'il parle
Config.Gesture     = true      -- le PNJ se tourne vers le joueur et fait un geste de salutation
Config.MaxDistance = 6.0       -- si le joueur s'éloigne de plus de X mètres, le dialogue est refusé automatiquement
Config.Timeout     = 60        -- secondes sans réponse avant refus automatique (0 = jamais)
Config.HideHuds    = true      -- masque les HUD pendant le dialogue (même événement que le menu pause)
Config.Accept      = 'Accepter'
Config.Refuse      = 'Refuser'
