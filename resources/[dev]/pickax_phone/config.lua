Config = {}

-- ═══════════════════════════ GÉNÉRAL ═══════════════════════════
Config.Brand        = 'Aura'            -- nom affiché (écran de démarrage, À propos…)
Config.Model        = 'Aura 15 Pro'     -- modèle affiché dans Réglages → Général → Informations
Config.Command      = 'phone'           -- commande pour ouvrir/fermer le téléphone
Config.Key          = 'F1'              -- touche par défaut (modifiable par le joueur dans les paramètres FiveM)
Config.RequireItem  = true              -- true : il faut l'objet ci-dessous dans l'inventaire (ox_inventory)
Config.Item         = 'phone'           -- nom de l'objet téléphone
Config.UseItem      = true              -- true : utiliser l'objet ouvre aussi le téléphone
Config.Debug        = false

-- ═══════════════════════════ NUMÉROS ═══════════════════════════
Config.Number = {
    prefixes = { '06', '07' },          -- début des numéros générés
    length   = 10,                      -- longueur totale (chiffres)
    group    = 2,                       -- affichage par groupes de N chiffres (06 12 34 56 78)
}
Config.MailDomain = 'aura.mail'         -- adresse mail : prenom.nom@aura.mail

-- ═══════════════════════════ APPELS ═══════════════════════════
Config.Calls = {
    ringTimeout   = 30,                 -- secondes avant « appel manqué »
    voiceResource = 'pma-voice',        -- résolution vocale (setCallChannel)
    channelBase   = 90000,              -- canal de départ pour les appels (évite les canaux radio)
    allowHidden   = true,               -- numéro masqué (*31# avant le numéro)
    price         = 0,                  -- prix par appel (compte bancaire), 0 = gratuit
}

-- ═══════════════════════════ MESSAGES ═══════════════════════════
Config.Messages = {
    maxLength   = 1000,
    historyDays = 60,                   -- purge automatique des messages plus vieux (0 = jamais)
    maxGroup    = 20,
}

-- ═══════════════════════════ BATTERIE ═══════════════════════════
Config.Battery = {
    enabled     = true,
    drainEvery  = 60,                   -- secondes entre deux pertes de 1 %
    drainScreen = 2,                    -- perte supplémentaire par minute écran allumé (en dixièmes de %)
    chargeInVehicle = true,             -- le téléphone se recharge en véhicule
    chargeEvery = 20,                   -- secondes par +1 % en charge
    powerbankItem = 'powerbank',        -- objet recharge instantanée (optionnel, ox_inventory)
}

-- ═══════════════════════════ PHOTOS / CAMÉRA ═══════════════════════════
-- Nécessite la ressource « screenshot-basic ». Mode d'envoi des photos :
--   'discord'    : webhook Discord (Config.Camera.webhook), l'URL de la pièce jointe est enregistrée
--   'fivemanage' : API FiveManage (Config.Camera.apiKey)
--   'custom'     : URL qui renvoie du JSON {"url": "..."} (Config.Camera.webhook)
Config.Camera = {
    mode     = 'discord',
    webhook  = '',
    apiKey   = '',
    field    = 'files[]',
    encoding = 'jpg',
    quality  = 0.85,
    maxPhotos = 200,
}

-- ═══════════════════════════ RÉSEAUX SOCIAUX ═══════════════════════════
Config.Social = {
    postMaxLength = 280,
    maxImages     = 4,
    storyHours    = 24,                 -- durée d'une story (Snapgram)
    verifiedJobs  = { police = true, ambulance = true, ems = true },   -- badge vérifié automatique
    adminGroups   = { 'admin', 'superadmin', 'mod' },                 -- peuvent supprimer / vérifier
}

-- ═══════════════════════════ BANQUE & CRYPTO ═══════════════════════════
Config.Bank = {
    account       = 'bank',             -- compte ESX utilisé
    maxTransfer   = 5000000,
    transferFee   = 0,                  -- % de frais sur les virements
    historyLimit  = 80,
}
Config.Crypto = {
    enabled   = true,
    tickEvery = 60,                     -- secondes entre deux variations de cours
    volatility = 0.035,                 -- amplitude maximale d'une variation (3,5 %)
    fee       = 0.5,                    -- % de frais à l'achat/vente
    coins = {
        { id = 'BTC', name = 'Bitcoin',  price = 42000, color = '#f7931a' },
        { id = 'ETH', name = 'Ethereum', price = 2400,  color = '#627eea' },
        { id = 'SOL', name = 'Solana',   price = 95,    color = '#14f195' },
        { id = 'DOGE', name = 'Dogecoin', price = 0.12, color = '#c2a633' },
        { id = 'AUR', name = 'Aura Coin', price = 12,   color = '#00a4ff' },
    },
}

-- ═══════════════════════════ ANNONCES (MARCHÉ) ═══════════════════════════
Config.Market = {
    categories = { 'Véhicules', 'Immobilier', 'Mode', 'Électronique', 'Maison', 'Loisirs', 'Emploi', 'Services', 'Autre' },
    maxActive  = 8,                     -- annonces actives par joueur
    maxImages  = 4,
    fee        = 0,                     -- frais de publication
    expireDays = 14,
}

-- ═══════════════════════════ LIGNES DES JOBS (Job Builder) ═══════════════════════════
-- Quand pickax_jobbuilder tourne, TOUS les jobs créés dans le builder deviennent des lignes joignables depuis l'app Services
-- (appel vocal + alerte avec position). Ils se règlent dans le Job Builder → job → carte « Téléphone des joueurs ».
-- Les jobs créés/modifiés apparaissent tout de suite, sans redémarrage.
Config.JobLines = {
    enabled       = true,      -- false : on revient à la liste fixe Config.Services ci-dessous
    voice         = true,      -- autorise les appels vocaux vers les jobs (le premier employé qui décroche)
    keepStatic    = false,     -- true : garde aussi les services fixes de Config.Services en plus des jobs du builder
    ringTimeout   = 30,        -- secondes de sonnerie chez les employés
}

-- ═══════════════════════════ SERVICES (URGENCES, JOBS) ═══════════════════════════
-- Liste de secours, utilisée seulement si pickax_jobbuilder n'est pas démarré (ou Config.JobLines.keepStatic = true)
-- number : numéro composable au clavier ; jobs : métiers qui reçoivent l'alerte (en service)
Config.Services = {
    { id = 'police',   label = 'Police',        number = '17',  icon = 'shield', color = '#2563eb', jobs = { 'police', 'sheriff' },           anon = true },
    { id = 'ems',      label = 'Ambulance',     number = '15',  icon = 'heart',  color = '#ef4444', jobs = { 'ambulance', 'ems' },            anon = false },
    { id = 'fire',     label = 'Pompiers',      number = '18',  icon = 'flame',  color = '#f97316', jobs = { 'fire', 'ambulance' },           anon = false },
    { id = 'mecano',   label = 'Dépanneur',     number = '',    icon = 'wrench', color = '#f59e0b', jobs = { 'mechanic', 'mecano', 'bennys' }, anon = false },
    { id = 'taxi',     label = 'Taxi',          number = '',    icon = 'car',    color = '#eab308', jobs = { 'taxi' },                        anon = false },
    { id = 'realestate', label = 'Agence immobilière', number = '', icon = 'home', color = '#14b8a6', jobs = { 'realestate' },              anon = false },
}
Config.Dispatch = {
    blipSeconds = 120,
    cooldown    = 20,                   -- secondes entre deux alertes d'un même joueur
    sprite = 280, color = 1,
}

-- ═══════════════════════════ AIRSHARE ═══════════════════════════
Config.AirShare = { distance = 8.0, timeout = 25 }

-- ═══════════════════════════ LOCALISER ═══════════════════════════
Config.FindMy = { refresh = 5 }         -- secondes entre deux mises à jour de position partagée

-- ═══════════════════════════ MUSIQUE ═══════════════════════════
-- Flux audio directs (mp3/aac/ogg). Les joueurs peuvent aussi ajouter leurs propres URL.
Config.Radios = {
    { name = 'Aura FM',      url = 'https://icecast.radiofrance.fr/fip-midfi.mp3',  color = '#ef4444' },
    { name = 'Lofi Beats',   url = 'https://streams.ilovemusic.de/iloveradio17.mp3', color = '#8b5cf6' },
    { name = 'Hits',         url = 'https://streams.ilovemusic.de/iloveradio1.mp3',  color = '#f97316' },
    { name = 'Chill',        url = 'https://streams.ilovemusic.de/iloveradio10.mp3', color = '#14b8a6' },
}

-- ═══════════════════════════ APPLICATIONS ═══════════════════════════
-- default = installée d'office ; store = visible dans l'App Store ; system = ne peut pas être désinstallée
-- Pour retirer une app du téléphone : mets enabled = false.
Config.Apps = {
    { id = 'phone',     enabled = true, default = true,  system = true,  dock = true },
    { id = 'messages',  enabled = true, default = true,  system = true,  dock = true },
    { id = 'contacts',  enabled = true, default = true,  system = true },
    { id = 'camera',    enabled = true, default = true,  system = true,  dock = true },
    { id = 'photos',    enabled = true, default = true,  system = true },
    { id = 'settings',  enabled = true, default = true,  system = true },
    { id = 'appstore',  enabled = true, default = true,  system = true },
    { id = 'bank',      enabled = true, default = true },
    { id = 'maps',      enabled = true, default = true,  dock = true },
    { id = 'mail',      enabled = true, default = true },
    { id = 'notes',     enabled = true, default = true },
    { id = 'calendar',  enabled = true, default = true },
    { id = 'clock',     enabled = true, default = true },
    { id = 'calculator',enabled = true, default = true },
    { id = 'weather',   enabled = true, default = true },
    { id = 'services',  enabled = true, default = true },
    { id = 'garage',    enabled = true, default = true },
    { id = 'music',     enabled = true, default = true },
    { id = 'findmy',    enabled = true, default = true },
    { id = 'pulse',     enabled = true, default = false, store = true },
    { id = 'snap',      enabled = true, default = false, store = true },
    { id = 'match',     enabled = true, default = false, store = true },
    { id = 'crypto',    enabled = true, default = false, store = true },
    { id = 'market',    enabled = true, default = false, store = true },
    { id = 'airshare',  enabled = true, default = true },
    { id = 'wallet',    enabled = true, default = true },
}

-- ═══════════════════════════ FONDS D'ÉCRAN ═══════════════════════════
Config.Wallpapers = {
    { id = 'aurora', name = 'Aurore',  css = 'radial-gradient(120% 80% at 20% 0%, #1fd1f9 0%, transparent 55%), radial-gradient(100% 70% at 90% 20%, #b621fe 0%, transparent 55%), linear-gradient(160deg,#0f0c29,#302b63 55%,#24243e)' },
    { id = 'sunset', name = 'Coucher',  css = 'radial-gradient(120% 70% at 50% 100%, #ff9a44 0%, transparent 60%), linear-gradient(180deg,#2b1055,#7597de 70%,#f8b195)' },
    { id = 'ocean',  name = 'Océan',    css = 'radial-gradient(100% 60% at 70% 0%, #4facfe 0%, transparent 60%), linear-gradient(170deg,#001e3c,#0a3d62 60%,#1e90ff)' },
    { id = 'forest', name = 'Forêt',    css = 'radial-gradient(110% 70% at 10% 100%, #38ef7d 0%, transparent 55%), linear-gradient(170deg,#06130d,#0b3d2e 60%,#11998e)' },
    { id = 'rose',   name = 'Rose',     css = 'radial-gradient(100% 70% at 80% 10%, #ff9a9e 0%, transparent 55%), linear-gradient(160deg,#2d1b3d,#6a3093 55%,#a044ff)' },
    { id = 'graphite', name = 'Graphite', css = 'radial-gradient(100% 60% at 50% 0%, #4b5563 0%, transparent 60%), linear-gradient(180deg,#0b0b0f,#1f2937)' },
    { id = 'light',  name = 'Clair',    css = 'radial-gradient(100% 60% at 30% 0%, #e0f2fe 0%, transparent 60%), linear-gradient(180deg,#f8fafc,#cbd5e1)' },
}

-- ═══════════════════════════ SONNERIES (sons du navigateur NUI, générés en WebAudio) ═══════════════════════════
Config.Ringtones = { 'Marimba', 'Cristal', 'Radar', 'Pulse', 'Classique', 'Silence' }

-- ═══════════════════════════ ADMIN ═══════════════════════════
Config.Admin = { groups = { 'admin', 'superadmin' } }   -- commandes /phone_give, /phone_reset, /phone_number
