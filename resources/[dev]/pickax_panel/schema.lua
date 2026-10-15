-- Catalogue des réglages que le panel sait lire / modifier dans TES fichiers existants.
-- Rien à changer dans tes scripts : chaque réglage pointe vers la ligne déjà présente dans ton config.lua / style.css / index.html...
-- Pour ajouter un réglage : copier une ligne F{...} (id unique, type, fichier, repère `anchor` + nom `key` de la valeur).
-- Types : bool, number, color (#rrggbb), rgba ({r,g,b,a}), text, css (valeur CSS), url, select (liste fermée), items (liste de lignes).
-- Groupes `live = true` : appliqués EN DIRECT chez les joueurs (aucune écriture de fichier : marche sur un hébergeur verrouillé).
--   La valeur du fichier sert de valeur par défaut ; les scripts lisent le réglage via exports.pickax_panel:Get('<groupe>').
-- Groupes sans `live` : écrits dans les fichiers (nécessite que le serveur ait le droit d'écriture).

PanelSchema = {}

local function group(def)
    def.fields = {}
    PanelSchema[#PanelSchema + 1] = def
    return function(f)
        f.group = def.id
        f.live = def.live
        f.rkey = f.rkey or f.id:match('^[^.]+%.(.+)$')
        f.resource = f.resource or def.resource
        f.loc = { anchor = f.anchor, key = f.key, sep = f.sep, to = f.to, open = f.open, close = f.close }
        f.anchor, f.key, f.sep, f.to, f.open, f.close = nil, nil, nil, nil, nil, nil
        def.fields[#def.fields + 1] = f
    end
end

-- ───────────────────────────── Général (variables du serveur, appliquées en direct) ─────────────────────────────
do
    local F = group { id = 'general', label = 'Général', icon = 'server', resource = nil,
        desc = 'Nom, description et identité publique du serveur. Appliqué immédiatement dans la liste des serveurs, et réappliqué à chaque démarrage.' }
    local function v(id, label, name, extra)
        local f = { id = 'general.' .. id, label = label, type = 'text', convar = name, info = true, max = 300 }
        for k, x in pairs(extra or {}) do f[k] = x end
        F(f)
    end
    v('name', 'Nom du projet', 'sv_projectName', { section = 'Identité', max = 120, hint = 'Codes couleur ^4 ^7 acceptés.' })
    v('desc', 'Description', 'sv_projectDesc', { max = 250 })
    v('hostname', 'Hostname', 'sv_hostname', { info = false, max = 120, hint = 'Nom affiché dans la liste des serveurs.' })
    v('tags', 'Tags', 'tags', { max = 250, hint = 'Séparés par des virgules.' })
    v('locale', 'Locale', 'locale', { max = 12, hint = 'ex : fr-FR' })
    v('discord', 'Discord', 'discord', { section = 'Liens et bannières', max = 80 })
    v('bannerDetail', 'Bannière (fiche du serveur)', 'banner_detail', { type = 'url', max = 400 })
    v('bannerConnecting', 'Bannière (connexion)', 'banner_connecting', { type = 'url', max = 400 })
end

-- ───────────────────────────── Écran de chargement ─────────────────────────────
do
    local F = group { id = 'loading', label = 'Écran de chargement', icon = 'loading', resource = 'PickaxLoading',
        desc = 'Page affichée pendant la connexion. Nécessite que le serveur puisse modifier ses fichiers (indisponible sur certains hébergeurs).' }
    F { section = 'Apparence', id = 'loading.accent', label = 'Couleur principale', type = 'color', file = 'style.css',
        anchor = ':root', key = '--accent', to = ';', hint = 'Barre de progression, boutons, pourcentage.',
        also = { { file = 'style.css', anchor = ':root', key = '--accent-rgb', to = ';', xform = 'rgbcsv' } } }
    F { section = 'Musique', id = 'loading.volume', label = 'Volume de la musique (%)', type = 'number', min = 0, max = 100, int = true, file = 'index.html',
        anchor = 'id="volume"', key = 'value', sep = '^%s*=%s*', hint = 'Volume au lancement de la page.',
        also = { { file = 'index.html', anchor = 'const myAudio', key = 'myAudio.volume', type = 'number', xform = 'div100' } } }
    F { section = 'Boutons du haut', id = 'loading.discord', label = 'Lien du bouton Discord', type = 'url', file = 'ui.js', anchor = 'var LINKS', key = 'discord' }
    F { id = 'loading.boutique', label = 'Lien du bouton Boutique', type = 'url', file = 'ui.js', anchor = 'var LINKS', key = 'boutique' }
    F { id = 'loading.reglement', label = 'Lien du bouton Règlement', type = 'url', file = 'ui.js', anchor = 'var LINKS', key = 'reglement',
        hint = 'Laisser vide pour que le bouton ne fasse rien.' }
    F { section = 'Texte défilant', id = 'loading.ticker', label = 'Messages défilants (bas de page)', type = 'items', file = 'index.html',
        anchor = '<div class="ticker">', open = '<div class="ticker__item">', close = '</div>' }
end

-- ───────────────────────────── Menus (RageUI en NUI) ─────────────────────────────
do
    local F = group { id = 'rageui', label = 'Menus RageUI', icon = 'menu', resource = 'pickax_ui', live = true,
        desc = 'Apparence par défaut de tous les menus (couleur, style, arrondis, sons). Chaque joueur peut ensuite personnaliser la sienne depuis son menu personnel. Appliqué en direct.' }
    local DEF = { file = 'client.lua', anchor = 'local DEFAULTS = {' }
    local function d(f) for k, v in pairs(DEF) do f[k] = v end F(f) end
    d { section = 'Style', id = 'rageui.style', label = 'Style des menus', type = 'select', key = 'style',
        options = { { 'noir', 'Noir' }, { 'verre', 'Verre' }, { 'clair', 'Clair' }, { 'neon', 'Néon' }, { 'bleu', 'Bleu' } } }
    d { id = 'rageui.size', label = 'Taille', type = 'select', key = 'size', options = { { 'sm', 'Petite' }, { 'md', 'Moyenne' }, { 'lg', 'Grande' } } }
    d { id = 'rageui.banner', label = 'Afficher la bannière', type = 'bool', key = 'banner' }
    d { id = 'rageui.btnRadius', label = 'Arrondi des boutons (px)', type = 'select', key = 'btnRadius', hint = '0 = carré, 999 = pilule.',
        options = { { 0, '0' }, { 6, '6' }, { 12, '12' }, { 18, '18' }, { 24, '24' }, { 999, 'Pilule' } } }
    d { id = 'rageui.cardRadius', label = 'Arrondi des cartes (px)', type = 'select', key = 'cardRadius',
        options = { { 0, '0' }, { 8, '8' }, { 14, '14' }, { 18, '18' }, { 24, '24' }, { 28, '28' } } }
    d { section = 'Couleurs', id = 'rageui.accent', label = 'Couleur principale', type = 'color', key = 'accent' }
    d { id = 'rageui.bg', label = 'Fond des cartes', type = 'color', optional = true, key = 'bg', hint = 'Vide = couleur du style choisi.' }
    d { id = 'rageui.text', label = 'Texte', type = 'color', optional = true, key = 'text', hint = 'Vide = couleur du style choisi.' }
    d { id = 'rageui.selbg', label = 'Fond de la ligne sélectionnée', type = 'color', optional = true, key = 'selbg' }
    d { id = 'rageui.selborder', label = 'Bordure de la ligne sélectionnée', type = 'color', optional = true, key = 'selborder' }
    d { section = 'Sons', id = 'rageui.sound', label = 'Sons des menus', type = 'bool', key = 'sound' }
    d { id = 'rageui.volume', label = 'Volume des sons (%)', type = 'number', min = 10, max = 100, int = true, key = 'volume' }
end

-- ───────────────────────────── Markers ─────────────────────────────
do
    local F = group { id = 'markers', live = true, label = 'Markers', icon = 'marker', resource = 'CorePickax',
        desc = 'Style commun de tous les markers au sol (Config.GlobalMarker). Appliqué en direct.' }
    F { section = 'Style des markers', id = 'markers.enabled', label = 'Markers activés', type = 'bool', file = 'config.lua', anchor = 'Config.GlobalMarker = {', key = 'Enabled' }
    F { id = 'markers.type', label = 'Type de marker', type = 'number', min = 0, max = 43, int = true, file = 'config.lua',
        anchor = 'Config.GlobalMarker = {', key = 'Type', hint = '23 = cercle plat au sol.' }
    F { id = 'markers.color', label = 'Couleur', type = 'rgba', named = true, file = 'config.lua', anchor = 'Config.GlobalMarker = {', key = 'Color' }
    F { id = 'markers.bob', label = 'Marker qui monte et descend', type = 'bool', file = 'config.lua', anchor = 'Config.GlobalMarker = {', key = 'BobUpAndDown' }
    F { id = 'markers.rotate', label = 'Marker qui tourne', type = 'bool', file = 'config.lua', anchor = 'Config.GlobalMarker = {', key = 'Rotate' }
    F { id = 'markers.face', label = 'Marker face à la caméra', type = 'bool', file = 'config.lua', anchor = 'Config.GlobalMarker = {', key = 'FaceCamera' }
end

-- ───────────────────────────── HUD infos joueur (haut droite) ─────────────────────────────
do
    local F = group { id = 'hud2', live = true, label = 'HUD infos (haut droite)', icon = 'hud', resource = 'PickaxHud2',
        desc = 'Cartes serveur / métier / argent. Les joueurs gardent leurs propres préférences (menu personnel). Appliqué en direct.' }
    F { section = 'Textes', id = 'hud2.server', label = 'Nom du serveur', type = 'text', max = 24, escape = 'html', file = 'html/index.html', anchor = 'id="servername"', key = '>', sep = false, to = '<' }
    F { id = 'hud2.discord', label = 'Texte du lien Discord', type = 'text', max = 40, escape = 'html', file = 'html/index.html', anchor = 'id="discord"', key = '>', sep = false, to = '<' }
    F { section = 'Couleurs', id = 'hud2.main', label = 'Couleur principale', type = 'color', file = 'html/css/css.css', anchor = ':root', key = '--main', to = ';' }
    F { id = 'hud2.bg', label = 'Fond des cartes', type = 'css', file = 'html/css/css.css', anchor = ':root', key = '--bg', to = ';', hint = 'ex : rgba(7, 12, 18, .68)' }
    F { id = 'hud2.text', label = 'Texte', type = 'color', file = 'html/css/css.css', anchor = ':root', key = '--text', to = ';' }
    F { id = 'hud2.muted', label = 'Texte secondaire', type = 'color', file = 'html/css/css.css', anchor = ':root', key = '--muted', to = ';' }
    F { id = 'hud2.ok', label = 'Gain d\'argent (vert)', type = 'color', file = 'html/css/css.css', anchor = ':root', key = '--ok', to = ';' }
    F { id = 'hud2.bad', label = 'Perte d\'argent (rouge)', type = 'color', file = 'html/css/css.css', anchor = ':root', key = '--bad', to = ';' }
    F { section = 'Valeurs de départ des joueurs', id = 'hud2.radius', label = 'Arrondi par défaut (px)', type = 'number', min = 0, max = 30, int = true, file = 'client.lua', anchor = 'local DEFAULTS = {', key = 'radius', hint = '0 = carré. Valeur de départ des joueurs.' }
    F { id = 'hud2.scale', label = 'Taille par défaut (%)', type = 'number', min = 60, max = 150, int = true, file = 'client.lua', anchor = 'local DEFAULTS = {', key = 'scale' }
    F { id = 'hud2.showServer', label = 'Carte serveur affichée par défaut', type = 'bool', file = 'client.lua', anchor = 'local DEFAULTS = {', key = 'server' }
    F { id = 'hud2.showJob', label = 'Carte métier affichée par défaut', type = 'bool', file = 'client.lua', anchor = 'local DEFAULTS = {', key = 'job' }
    F { id = 'hud2.showMoney', label = 'Carte argent affichée par défaut', type = 'bool', file = 'client.lua', anchor = 'local DEFAULTS = {', key = 'money' }
end

-- ───────────────────────────── HUD faim / soif ─────────────────────────────
do
    local F = group { id = 'hud1', live = true, label = 'HUD faim / soif', icon = 'status', resource = 'PickaxHud1',
        desc = 'Jauges rondes faim et soif. Appliqué en direct.' }
    F { section = 'Position et fond', id = 'hud1.bottom', label = 'Distance du bas (px)', type = 'number', unit = 'px', min = 0, max = 600, int = true, file = 'style.css', anchor = '.hud-container {', key = 'bottom' }
    F { id = 'hud1.left', label = 'Distance de la gauche (px)', type = 'number', unit = 'px', min = 0, max = 1200, int = true, file = 'style.css', anchor = '.hud-container {', key = 'left' }
    F { id = 'hud1.gap', label = 'Espace entre les jauges (px)', type = 'number', unit = 'px', min = 0, max = 40, int = true, file = 'style.css', anchor = '.hud-container {', key = 'gap' }
    F { id = 'hud1.bg', label = 'Fond des jauges', type = 'css', file = 'style.css', anchor = '.hud-element {', key = 'background', to = ';', hint = 'ex : rgba(0, 0, 0, 0.6)' }
    F { section = 'Comportement', id = 'hud1.hideDefault', label = 'Masquer la jauge GTA par défaut', type = 'bool', file = 'config.lua', key = 'Config.HideDefaultHud' }
    F { id = 'hud1.interval', label = 'Rafraîchissement (ms)', type = 'number', min = 100, max = 5000, int = true, file = 'config.lua', key = 'Config.StatusUpdateInterval' }
end

-- ───────────────────────────── Notifications ─────────────────────────────
do
    local F = group { id = 'notify', live = true, label = 'Notifications', icon = 'bell', resource = 'pickax_notify',
        desc = 'Notifications, aide « Appuyer sur E » et logos de métier. Appliqué en direct.' }
    local nextSection
    local function take() local t = nextSection nextSection = nil return t end
    local function c(name, label) F { section = take(), id = 'notify.' .. name, label = label, type = 'color', file = 'config.lua', key = 'Config.' .. name } end
    local function n(name, label, min, max, extra)
        local f = { section = take(), id = 'notify.' .. name, label = label, type = 'number', min = min, max = max, file = 'config.lua', key = 'Config.' .. name }
        for k, v in pairs(extra or {}) do f[k] = v end
        F(f)
    end
    local function b(name, label) F { section = take(), id = 'notify.' .. name, label = label, type = 'bool', file = 'config.lua', key = 'Config.' .. name } end
    nextSection = 'Couleurs'
    c('MainColor', 'Couleur principale'); c('BackgroundColor', 'Couleur du fond')
    n('BackgroundTransparency', 'Opacité du fond (0 à 1)', 0, 1)
    c('TextColor', 'Texte'); c('SmallTextColor', 'Petit texte')
    c('SuccessColor', 'Succès (~g~)'); c('ErrorColor', 'Erreur (~r~)'); c('WarningColor', 'Avertissement (~y~)'); c('BlueTextColor', 'Bleu (~b~)')
    nextSection = 'Forme et position'
    n('BorderRadius', 'Arrondi des notifications (px)', 0, 40, { int = true, hint = '0 = carré, 11 = arrondi.' })
    n('MinHeight', 'Hauteur minimum (px)', 30, 200, { int = true })
    F { id = 'notify.Width', label = 'Largeur', type = 'css', file = 'config.lua', key = 'Config.Width', hint = 'ex : 300px ou clamp(270px, 14.2vw, 315px)' }
    F { id = 'notify.PositionLeft', label = 'Position : distance de la gauche', type = 'css', file = 'config.lua', key = 'Config.PositionLeft', hint = 'ex : 1.35vw ou 25px' }
    F { id = 'notify.PositionBottom', label = 'Position : distance du bas', type = 'css', file = 'config.lua', key = 'Config.PositionBottom', hint = 'ex : 22.5vh ou 120px' }
    n('NotificationGap', 'Espace entre deux notifications (px)', 0, 40, { int = true })
    nextSection = 'Détails'
    b('SideLineEnabled', 'Ligne colorée à gauche'); n('SideLineWidth', 'Épaisseur de cette ligne (px)', 1, 10, { int = true })
    b('ProgressLineEnabled', 'Ligne de progression en bas')
    b('IconEnabled', 'Icône / logo du métier'); n('IconBoxSize', 'Taille du carré de l\'icône (px)', 12, 60, { int = true })
    n('IconRadius', 'Arrondi du carré de l\'icône (px)', 0, 30, { int = true })
    b('CounterEnabled', 'Compteur anti-spam (x2, x3...)')
    n('TitleFontSize', 'Taille du titre', 8, 30); n('MessageFontSize', 'Taille du message', 8, 30); n('SmallTextFontSize', 'Taille du petit texte', 7, 24)
    nextSection = 'Affichage'
    n('MaxVisibleNotifications', 'Notifications visibles en même temps', 1, 10, { int = true })
    n('NotificationDuration', 'Durée d\'une notification (ms)', 1000, 20000, { int = true })
    n('AdvancedNotificationDuration', 'Durée d\'une notification avancée (ms)', 1000, 20000, { int = true })
end

-- ───────────────────────────── File d'attente / connexion ─────────────────────────────
do
    local F = group { id = 'connect', live = true, label = 'File d\'attente', icon = 'queue', resource = 'PickaxConnectUI',
        desc = 'Carte d\'attente affichée avant de rejoindre le serveur. Appliqué en direct.' }
    F { section = 'Textes et liens', id = 'connect.name', label = 'Titre', type = 'text', max = 80, file = 'config.lua', key = 'Config.ServerName' }
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
