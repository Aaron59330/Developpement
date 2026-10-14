Config = {}

-- ============================================================
--                    PICKAX NOTIFY CONFIG
-- ============================================================
-- Tu peux modifier le design ici sans toucher au HTML/CSS/JS.
-- Pour appliquer les changements : restart pickax_notify
-- ============================================================

-- COULEURS ---------------------------------------------------
Config.MainColor = '#00a4ff'              -- Couleur principale (ligne, titre, icône, compteur)
Config.BackgroundColor = '#070707'        -- Couleur du fond de la notification
Config.BackgroundTransparency = 0.40      -- 0.0 = invisible / 1.0 = opaque

Config.TextColor = '#f7f7fb'              -- Texte principal du message
Config.SmallTextColor = '#b7b6c1'         -- Petit texte / subject
Config.SuccessColor = '#5be39a'           -- ~g~
Config.ErrorColor = '#ff7373'             -- ~r~
Config.WarningColor = '#ffd86a'           -- ~y~
Config.BlueTextColor = '#74b7ff'          -- ~b~

-- FORME / TAILLE ---------------------------------------------
Config.Width = 'clamp(270px, 14.2vw, 315px)' -- Largeur comme avant (accepte aussi 300 ou '300px')
Config.MinHeight = 65                     -- Hauteur minimum
Config.BorderRadius = 0                   -- 0 = carré, 6 = léger, 11 = arrondi, 20+ = très arrondi

-- Padding interne
Config.PaddingTop = 11
Config.PaddingRight = 13
Config.PaddingBottom = 12
Config.PaddingLeft = 16

-- LIGNE PRINCIPALE À GAUCHE ----------------------------------
Config.SideLineWidth = 2                  -- Épaisseur de la ligne principale
Config.SideLineEnabled = true             -- false = désactive la ligne de gauche

-- Petite ligne de progression en bas
Config.ProgressLineEnabled = true
Config.ProgressLineHeight = 2
Config.ProgressLineOpacity = 0.85

-- POSITION ----------------------------------------------------
-- Valeurs CSS acceptées : '1.35vw', '25px', '22.5vh', etc.
Config.PositionLeft = '1.35vw'
Config.PositionBottom = '22.5vh'
Config.NotificationGap = 8                -- Espace entre deux notifications

-- TEXTE -------------------------------------------------------
Config.TitleFontSize = 12.5                -- Taille du titre "Information"
Config.TitleFontWeight = 750
Config.MessageFontSize = 12                -- Taille du texte principal
Config.MessageFontWeight = 600
Config.MessageLineHeight = 1.45
Config.SmallTextFontSize = 10.5            -- Taille du petit texte à droite
Config.SmallTextFontWeight = 600
Config.HeaderGap = 7
Config.HeaderBottomSpacing = 6

-- ICÔNE -------------------------------------------------------
Config.IconEnabled = true
Config.IconBoxSize = 22                    -- Taille du carré autour de l'icône
Config.IconSize = 13                       -- Taille du dessin SVG
Config.IconRadius = 0                      -- Arrondi du carré de l'icône
Config.IconStrokeWidth = 1.9               -- Épaisseur du dessin de l'icône
Config.IconBackgroundOpacity = 0.12
Config.IconBorderOpacity = 0.34

-- COMPTEUR ANTI-SPAM ------------------------------------------
Config.StackWindow = 3000                  -- Temps en ms pour empiler la même notif
Config.CounterEnabled = true
Config.CounterSize = 16                    -- Hauteur minimale du compteur
Config.CounterFontSize = 9
Config.CounterRadius = 0
Config.CounterTop = 6
Config.CounterRight = 6
Config.CounterBackgroundOpacity = 0.92

-- AFFICHAGE ---------------------------------------------------
Config.MaxVisibleNotifications = 4

-- Durée des notifications en millisecondes
Config.NotificationDuration = 4500
Config.AdvancedNotificationDuration = 5500
Config.HelpNotificationDuration = 1200   -- l'aide se rafraîchit tant que le script l'appelle ; elle disparaît 1,2 s après

