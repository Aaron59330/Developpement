-- Catalogue des réglages que le panel sait lire / modifier dans TES fichiers existants.
-- Rien à changer dans tes scripts : chaque réglage pointe vers la ligne déjà présente dans ton config.lua / style.css / index.html...
-- Pour ajouter un réglage : copier une ligne F{...} (id unique, type, fichier, repère `anchor` + nom `key` de la valeur).
-- Types : bool, number, color (#rrggbb), rgba ({r,g,b,a}), text, css (valeur CSS), url, items (liste de lignes).

PanelSchema = {}

local function group(def)
    def.fields = {}
    PanelSchema[#PanelSchema + 1] = def
    return function(f)
        f.group = def.id
        f.resource = f.resource or def.resource
        f.loc = { anchor = f.anchor, key = f.key, sep = f.sep, to = f.to, open = f.open, close = f.close }
        f.anchor, f.key, f.sep, f.to, f.open, f.close = nil, nil, nil, nil, nil, nil
        def.fields[#def.fields + 1] = f
    end
end

-- ───────────────────────────── Écran de chargement ─────────────────────────────
do
    local F = group { id = 'loading', label = 'Écran de chargement', icon = 'loading', resource = 'PickaxLoading',
        desc = 'Page affichée pendant la connexion. Appliqué à la prochaine connexion après redémarrage de PickaxLoading.' }
    F { id = 'loading.accent', label = 'Couleur principale', type = 'color', file = 'style.css',
        anchor = ':root', key = '--accent', to = ';', hint = 'Barre de progression, boutons, pourcentage.',
        also = { { file = 'style.css', anchor = ':root', key = '--accent-rgb', to = ';', xform = 'rgbcsv' } } }
    F { id = 'loading.volume', label = 'Volume de la musique (%)', type = 'number', min = 0, max = 100, int = true, file = 'index.html',
        anchor = 'id="volume"', key = 'value', sep = '^%s*=%s*', hint = 'Volume au lancement de la page.',
        also = { { file = 'index.html', anchor = 'const myAudio', key = 'myAudio.volume', type = 'number', xform = 'div100' } } }
    F { id = 'loading.discord', label = 'Lien du bouton Discord', type = 'url', file = 'ui.js', anchor = 'var LINKS', key = 'discord' }
    F { id = 'loading.boutique', label = 'Lien du bouton Boutique', type = 'url', file = 'ui.js', anchor = 'var LINKS', key = 'boutique' }
    F { id = 'loading.reglement', label = 'Lien du bouton Règlement', type = 'url', file = 'ui.js', anchor = 'var LINKS', key = 'reglement',
        hint = 'Laisser vide pour que le bouton ne fasse rien.' }
    F { id = 'loading.ticker', label = 'Messages défilants (bas de page)', type = 'items', file = 'index.html',
        anchor = '<div class="ticker">', open = '<div class="ticker__item">', close = '</div>' }
end

-- ───────────────────────────── Menus RageUI ─────────────────────────────
do
    local F = group { id = 'rageui', label = 'Menus RageUI & bannière', icon = 'menu', resource = 'CorePickax',
        desc = 'Couleurs de tous les menus RageUI et bannière du menu F5. Redémarrer CorePickax pour appliquer.' }
    local function color(id, key, label, hint)
        F { id = 'rageui.' .. id, label = label, hint = hint, type = 'rgba', file = 'config.lua', anchor = 'RageUIStyle = {', key = key }
    end
    F { id = 'rageui.bannerOn', label = 'Bannière personnalisée activée', type = 'bool', file = 'utils/gifMenu/config.lua',
        anchor = 'ConfigMenuGIF = {', key = 'Active', hint = 'Remplace l\'image de bannière des menus.' }
    F { id = 'rageui.bannerLink', label = 'Image de la bannière (lien)', type = 'url', max = 400, file = 'utils/gifMenu/config.lua',
        anchor = 'AllTexture', key = 'link', hint = 'Image 512×128 (png / gif) hébergée en ligne.' }
    F { id = 'rageui.hideTitle', label = 'Masquer le titre sur la bannière', type = 'bool', file = 'config.lua',
        anchor = 'Config = {', key = 'DisableTitle', hint = 'À activer quand la bannière contient déjà le nom.' }
    F { id = 'rageui.glare', label = 'Reflet GTA au-dessus de la bannière', type = 'bool', file = 'config.lua', anchor = 'RageUIStyle = {', key = 'BannerGlare' }
    F { id = 'rageui.keepCodes', label = 'Garder les couleurs ~r~ ~b~ des scripts', type = 'bool', file = 'config.lua', anchor = 'RageUIStyle = {', key = 'KeepTextCodes' }
    color('background', 'Background', 'Fond du menu')
    color('shadow', 'Shadow', 'Ombre')
    color('button', 'Button', 'Bouton sélectionné')
    color('text', 'Text', 'Texte des boutons')
    color('selectedText', 'SelectedText', 'Texte sélectionné')
    color('disabledText', 'DisabledText', 'Texte désactivé')
    color('subtitle', 'Subtitle', 'Sous-titre')
    color('counterBg', 'CounterBackground', 'Fond du compteur')
    color('counterText', 'CounterText', 'Texte du compteur')
    color('separator', 'Separator', 'Lignes et accents')
    color('separatorText', 'SeparatorText', 'Titres des catégories')
    color('descBg', 'DescriptionBackground', 'Fond de la description')
    color('descText', 'DescriptionText', 'Texte de la description')
    color('infoBg', 'InfoBackground', 'Fond du panneau de droite')
    color('infoTitle', 'InfoTitle', 'Titre du panneau de droite')
    color('infoLabel', 'InfoLabel', 'Libellés du panneau de droite')
    color('infoValue', 'InfoValue', 'Valeurs du panneau de droite')
end

-- ───────────────────────────── Markers ─────────────────────────────
do
    local F = group { id = 'markers', label = 'Markers', icon = 'marker', resource = 'CorePickax',
        desc = 'Style commun de tous les markers au sol (Config.GlobalMarker). Redémarrer CorePickax pour appliquer.' }
    F { id = 'markers.enabled', label = 'Markers activés', type = 'bool', file = 'config.lua', anchor = 'Config.GlobalMarker = {', key = 'Enabled' }
    F { id = 'markers.type', label = 'Type de marker', type = 'number', min = 0, max = 43, int = true, file = 'config.lua',
        anchor = 'Config.GlobalMarker = {', key = 'Type', hint = '23 = cercle plat au sol.' }
    F { id = 'markers.color', label = 'Couleur', type = 'rgba', named = true, file = 'config.lua', anchor = 'Config.GlobalMarker = {', key = 'Color' }
    F { id = 'markers.bob', label = 'Marker qui monte et descend', type = 'bool', file = 'config.lua', anchor = 'Config.GlobalMarker = {', key = 'BobUpAndDown' }
    F { id = 'markers.rotate', label = 'Marker qui tourne', type = 'bool', file = 'config.lua', anchor = 'Config.GlobalMarker = {', key = 'Rotate' }
    F { id = 'markers.face', label = 'Marker face à la caméra', type = 'bool', file = 'config.lua', anchor = 'Config.GlobalMarker = {', key = 'FaceCamera' }
end

-- ───────────────────────────── HUD infos joueur (haut droite) ─────────────────────────────
do
    local F = group { id = 'hud2', label = 'HUD infos (haut droite)', icon = 'hud', resource = 'PickaxHud2',
        desc = 'Cartes serveur / métier / argent. Les joueurs gardent leurs propres préférences (menu personnel). Redémarrer PickaxHud2.' }
    F { id = 'hud2.server', label = 'Nom du serveur', type = 'text', max = 24, escape = 'html', file = 'html/index.html', anchor = 'id="servername"', key = '>', sep = false, to = '<' }
    F { id = 'hud2.discord', label = 'Texte du lien Discord', type = 'text', max = 40, escape = 'html', file = 'html/index.html', anchor = 'id="discord"', key = '>', sep = false, to = '<' }
    F { id = 'hud2.main', label = 'Couleur principale', type = 'color', file = 'html/css/css.css', anchor = ':root', key = '--main', to = ';' }
    F { id = 'hud2.bg', label = 'Fond des cartes', type = 'css', file = 'html/css/css.css', anchor = ':root', key = '--bg', to = ';', hint = 'ex : rgba(7, 12, 18, .68)' }
    F { id = 'hud2.text', label = 'Texte', type = 'color', file = 'html/css/css.css', anchor = ':root', key = '--text', to = ';' }
    F { id = 'hud2.muted', label = 'Texte secondaire', type = 'color', file = 'html/css/css.css', anchor = ':root', key = '--muted', to = ';' }
    F { id = 'hud2.ok', label = 'Gain d\'argent (vert)', type = 'color', file = 'html/css/css.css', anchor = ':root', key = '--ok', to = ';' }
    F { id = 'hud2.bad', label = 'Perte d\'argent (rouge)', type = 'color', file = 'html/css/css.css', anchor = ':root', key = '--bad', to = ';' }
    F { id = 'hud2.radius', label = 'Arrondi par défaut (px)', type = 'number', min = 0, max = 30, int = true, file = 'client.lua', anchor = 'local DEFAULTS = {', key = 'radius', hint = '0 = carré. Valeur de départ des joueurs.' }
    F { id = 'hud2.scale', label = 'Taille par défaut (%)', type = 'number', min = 60, max = 150, int = true, file = 'client.lua', anchor = 'local DEFAULTS = {', key = 'scale' }
    F { id = 'hud2.showServer', label = 'Carte serveur affichée par défaut', type = 'bool', file = 'client.lua', anchor = 'local DEFAULTS = {', key = 'server' }
    F { id = 'hud2.showJob', label = 'Carte métier affichée par défaut', type = 'bool', file = 'client.lua', anchor = 'local DEFAULTS = {', key = 'job' }
    F { id = 'hud2.showMoney', label = 'Carte argent affichée par défaut', type = 'bool', file = 'client.lua', anchor = 'local DEFAULTS = {', key = 'money' }
end

-- ───────────────────────────── HUD faim / soif ─────────────────────────────
do
    local F = group { id = 'hud1', label = 'HUD faim / soif', icon = 'status', resource = 'PickaxHud1',
        desc = 'Jauges rondes faim et soif. Redémarrer PickaxHud1 pour appliquer.' }
    F { id = 'hud1.bottom', label = 'Distance du bas (px)', type = 'number', unit = 'px', min = 0, max = 600, int = true, file = 'style.css', anchor = '.hud-container {', key = 'bottom' }
    F { id = 'hud1.left', label = 'Distance de la gauche (px)', type = 'number', unit = 'px', min = 0, max = 1200, int = true, file = 'style.css', anchor = '.hud-container {', key = 'left' }
    F { id = 'hud1.gap', label = 'Espace entre les jauges (px)', type = 'number', unit = 'px', min = 0, max = 40, int = true, file = 'style.css', anchor = '.hud-container {', key = 'gap' }
    F { id = 'hud1.bg', label = 'Fond des jauges', type = 'css', file = 'style.css', anchor = '.hud-element {', key = 'background', to = ';', hint = 'ex : rgba(0, 0, 0, 0.6)' }
    F { id = 'hud1.hideDefault', label = 'Masquer la jauge GTA par défaut', type = 'bool', file = 'config.lua', key = 'Config.HideDefaultHud' }
    F { id = 'hud1.interval', label = 'Rafraîchissement (ms)', type = 'number', min = 100, max = 5000, int = true, file = 'config.lua', key = 'Config.StatusUpdateInterval' }
end

-- ───────────────────────────── Notifications ─────────────────────────────
do
    local F = group { id = 'notify', label = 'Notifications', icon = 'bell', resource = 'pickax_notify',
        desc = 'Notifications, aide « Appuyer sur E » et logos de métier. Redémarrer pickax_notify pour appliquer.' }
    local function c(name, label) F { id = 'notify.' .. name, label = label, type = 'color', file = 'config.lua', key = 'Config.' .. name } end
    local function n(name, label, min, max, extra)
        local f = { id = 'notify.' .. name, label = label, type = 'number', min = min, max = max, file = 'config.lua', key = 'Config.' .. name }
        for k, v in pairs(extra or {}) do f[k] = v end
        F(f)
    end
    local function b(name, label) F { id = 'notify.' .. name, label = label, type = 'bool', file = 'config.lua', key = 'Config.' .. name } end
    c('MainColor', 'Couleur principale'); c('BackgroundColor', 'Couleur du fond')
    n('BackgroundTransparency', 'Opacité du fond (0 à 1)', 0, 1)
    c('TextColor', 'Texte'); c('SmallTextColor', 'Petit texte')
    c('SuccessColor', 'Succès (~g~)'); c('ErrorColor', 'Erreur (~r~)'); c('WarningColor', 'Avertissement (~y~)'); c('BlueTextColor', 'Bleu (~b~)')
    n('BorderRadius', 'Arrondi des notifications (px)', 0, 40, { int = true, hint = '0 = carré, 11 = arrondi.' })
    n('MinHeight', 'Hauteur minimum (px)', 30, 200, { int = true })
    F { id = 'notify.Width', label = 'Largeur', type = 'css', file = 'config.lua', key = 'Config.Width', hint = 'ex : 300px ou clamp(270px, 14.2vw, 315px)' }
    F { id = 'notify.PositionLeft', label = 'Position : distance de la gauche', type = 'css', file = 'config.lua', key = 'Config.PositionLeft', hint = 'ex : 1.35vw ou 25px' }
    F { id = 'notify.PositionBottom', label = 'Position : distance du bas', type = 'css', file = 'config.lua', key = 'Config.PositionBottom', hint = 'ex : 22.5vh ou 120px' }
    n('NotificationGap', 'Espace entre deux notifications (px)', 0, 40, { int = true })
    b('SideLineEnabled', 'Ligne colorée à gauche'); n('SideLineWidth', 'Épaisseur de cette ligne (px)', 1, 10, { int = true })
    b('ProgressLineEnabled', 'Ligne de progression en bas')
    b('IconEnabled', 'Icône / logo du métier'); n('IconBoxSize', 'Taille du carré de l\'icône (px)', 12, 60, { int = true })
    n('IconRadius', 'Arrondi du carré de l\'icône (px)', 0, 30, { int = true })
    b('CounterEnabled', 'Compteur anti-spam (x2, x3...)')
    n('TitleFontSize', 'Taille du titre', 8, 30); n('MessageFontSize', 'Taille du message', 8, 30); n('SmallTextFontSize', 'Taille du petit texte', 7, 24)
    n('MaxVisibleNotifications', 'Notifications visibles en même temps', 1, 10, { int = true })
    n('NotificationDuration', 'Durée d\'une notification (ms)', 1000, 20000, { int = true })
    n('AdvancedNotificationDuration', 'Durée d\'une notification avancée (ms)', 1000, 20000, { int = true })
end

-- ───────────────────────────── File d'attente / connexion ─────────────────────────────
do
    local F = group { id = 'connect', label = 'File d\'attente', icon = 'queue', resource = 'PickaxConnectUI',
        desc = 'Carte d\'attente affichée avant de rejoindre le serveur. Redémarrer PickaxConnectUI pour appliquer.' }
    F { id = 'connect.name', label = 'Titre', type = 'text', max = 80, file = 'config.lua', key = 'Config.ServerName' }
    F { id = 'connect.sec', label = 'Secondes d\'attente estimées par joueur', type = 'number', min = 0, max = 120, int = true, file = 'config.lua', key = 'Config.SecondsPerPlayer' }
    F { id = 'connect.none', label = 'Texte « personne en attente »', type = 'text', max = 80, file = 'config.lua', key = 'Config.NoPlayerText' }
    F { id = 'connect.discord', label = 'Lien Discord', type = 'url', file = 'config.lua', key = 'Config.DiscordURL' }
    F { id = 'connect.shop', label = 'Lien Boutique', type = 'url', file = 'config.lua', key = 'Config.ShopURL' }
end

-- Index par id
PanelFields = {}
for _, g in ipairs(PanelSchema) do
    for _, f in ipairs(g.fields) do PanelFields[f.id] = f end
end
