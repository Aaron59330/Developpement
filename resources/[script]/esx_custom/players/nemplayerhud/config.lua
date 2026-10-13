ConfigNewPlayer = {}

-- =========================
-- TEMPS / PROTECTION
-- =========================
ConfigNewPlayer.RequiredPlayTime = 2 * 60 * 60 -- 2 heures en secondes
ConfigNewPlayer.SaveInterval = 60 -- sauvegarde SQL toutes les X secondes
ConfigNewPlayer.BlockWeapons = true -- true = bloque les armes pendant la période nouveau joueur

-- =========================
-- BADGE AU-DESSUS DU JOUEUR
-- =========================
ConfigNewPlayer.BadgeEnabled = true -- active/désactive complètement le badge
ConfigNewPlayer.BadgeDistance = 1.0 -- distance maximum d'affichage
ConfigNewPlayer.BadgeHeight = 0.38 -- hauteur au-dessus de la tête

-- Fond / logo carré
ConfigNewPlayer.ShowLogo = true -- true = affiche le fond du logo
ConfigNewPlayer.LogoWidth = 0.020
ConfigNewPlayer.LogoHeight = 0.032
ConfigNewPlayer.LogoColor = { r = 70, g = 160, b = 255, a = 220 }

-- Lettre au centre du logo
ConfigNewPlayer.ShowBadgeText = true -- true = affiche le N
ConfigNewPlayer.BadgeText = 'N'
ConfigNewPlayer.BadgeTextScale = 0.30
ConfigNewPlayer.BadgeTextColor = { r = 255, g = 255, b = 255, a = 255 }

-- Texte sous le logo
ConfigNewPlayer.ShowBadgeLabel = true -- true = affiche NOUVEAU
ConfigNewPlayer.BadgeLabel = 'NOUVEAU'
ConfigNewPlayer.BadgeLabelScale = 0.20
ConfigNewPlayer.BadgeLabelColor = { r = 255, g = 255, b = 255, a = 215 }
