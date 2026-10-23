Config = {}

-- ╔═══════════════════════════════════════════════════════════════════════════════════════════════╗
-- ║  AERO SMARTPHONE — COMPATIBILITÉ : fonctionne sur ESX, QBCore, Qbox, ou sans framework (standalone)      ║
-- ║  Tout est en « auto » par défaut : le téléphone détecte ce qui tourne sur ton serveur.        ║
-- ║  Change une valeur seulement si la détection ne te convient pas.                              ║
-- ╚═══════════════════════════════════════════════════════════════════════════════════════════════╝

-- ▼▼▼ PRÉRÉGLÉ ESX (ESX + ox_inventory + pma-voice + pickax_core + Job Builder). Rien à changer. ▼▼▼
-- (les autres valeurs possibles sont indiquées en commentaire, au cas où tu changes de base un jour)
Config.Framework = 'esx'       -- 'auto' | 'esx' | 'qb' | 'qbox' | 'standalone'
Config.Inventory = 'ox'        -- 'auto' | 'ox' (ox_inventory) | 'qb' (qb/ps/lj-inventory) | 'qs' (qs-inventory) | 'esx' (inventaire ESX natif) | 'none'
Config.Voice     = 'pma-voice' -- appels vocaux : 'auto' | 'pma-voice' | 'mumble-voip' | 'saltychat' | 'custom' | 'none'
Config.Notify    = 'esx'       -- notifications en jeu (passent par pickax_notify) : 'ox_lib' | 'esx' | 'qb' | 'qbox' | 'native' | 'custom'
Config.Status    = 'esx_status'-- faim / soif de l'app Santé (esx_status fourni par pickax_core) : 'auto' | 'esx_status' | 'qb' | 'none' | 'custom'
Config.Society   = 'auto'      -- compte société : Job Builder en priorité, sinon esx_addonaccount (pickax_core)
                               --   'auto' | 'jobbuilder' | 'esx_addonaccount' | 'qb-banking' | 'qb-management' | 'renewed' | 'okok' | 'none' | 'custom'

-- Noms des comptes du framework : ESX = bank (banque) / money (espèces)
Config.Accounts = { bank = 'bank', cash = 'money' }

-- Tables SQL utilisées (hors tables aero_*). 'auto' = réglage habituel du framework détecté.
-- Pour une base personnalisée, remplace 'auto' par un tableau, exemple :
--   Config.Database.vehicles = { table = 'owned_vehicles', owner = 'owner', plate = 'plate', props = 'vehicle', model = nil, stored = 'stored', storedValue = 1 }
--   Config.Database.players  = { table = 'users', identifier = 'identifier', money = 'accounts', moneyFormat = 'esx' }   -- argent hors ligne
Config.Database = {
    -- Ta table owned_vehicles : colonne `state` (1 = garage, 0 = sorti, 2 = fourrière), comme pickax_core et le World Builder
    vehicles = { table = 'owned_vehicles', owner = 'owner', plate = 'plate', props = 'vehicle', stored = 'state', storedValue = 1, impoundValue = 2 },
    players  = 'auto',     -- argent des joueurs hors ligne : users.accounts (ESX)
}

-- Groupes / permissions administrateur (commandes /phone_*, modération des réseaux, suppression d'annonces…)
Config.Admin = {
    groups = { '_dev', 'superadmin', 'admin' },         -- groupes ESX de ta base (mêmes que le Builder Hub et l'anticheat)
    ace    = 'aura.admin',                              -- ou permission ACE : add_ace group.admin aura.admin allow
}

-- Fonctions personnalisées (pour les ressources non gérées en standard). Laisse nil si inutile.
-- Elles s'exécutent côté serveur, sauf notify / voiceStart / voiceStop / status qui s'exécutent côté client.
Config.Hooks = {
    societyAdd     = nil,   -- function(jobName, amount, reason) end
    societyBalance = nil,   -- function(jobName) return 0 end
    notify         = nil,   -- function(message) end                      (Config.Notify = 'custom')
    voiceStart     = nil,   -- function(channel, peerServerId) end        (Config.Voice = 'custom')
    voiceStop      = nil,   -- function(channel, peerServerId) end
    status         = nil,   -- function() return { hunger = 0-100, thirst = 0-100 } end   (Config.Status = 'custom')
    hasItem        = nil,   -- function(source, itemName) return count end                (inventaire non géré)
}

-- ╔═══════════════════════════════════════════════════════════════════════════════════════════════╗
-- ║  PERSONNALISATION GÉNÉRALE                                                                    ║
-- ╚═══════════════════════════════════════════════════════════════════════════════════════════════╝

-- Position et taille du téléphone à l'écran
Config.UI = {
    side     = 'right',    -- 'right' | 'left'
    marginX  = 28,         -- distance au bord (px)
    marginY  = 0,          -- distance entre le bas du téléphone et le bas de l'écran (px) : le téléphone reste toujours posé en bas, quelle que soit sa taille. 'auto' = centré verticalement
    offsetY  = -10,        -- (mode auto) décalage vertical : négatif = plus bas, positif = plus haut
    padY     = 56,         -- marge verticale totale réservée autour du téléphone (px) : plus grand = téléphone plus petit
    userMin  = 60,         -- taille minimale choisissable par le joueur (% de la taille automatique)
    userMax  = 125,        -- taille maximale choisissable (% ; limitée par la hauteur de l'écran)
    maxScale = 1.0,        -- taille maximale (1.0 = 100 %)
    minScale = 0.55,       -- taille minimale sur petits écrans
    blur     = true,       -- false : aucun flou d'arrière-plan sur le téléphone (à essayer si des coins sombres carrés dépassent du cadre dans le jeu)
    showBootLogo = true,   -- animation de démarrage à la première ouverture
}

-- Réglages donnés à chaque nouveau téléphone (le joueur peut ensuite les changer dans Réglages)
Config.Defaults = {
    wallpaper = 'aurora', lockWallpaper = 'aurora', theme = 'dark', accent = '',  -- '' = suit la couleur du serveur (pickax_core → AccentColor) ; le joueur peut en choisir une autre ringtone = 'Marimba', texttone = 'Cristal',
    volume = 70, brightness = 100, textSize = 100, phoneScale = 100, hour24 = false, autoLock = 30, wifi = true, previews = true, readReceipts = true,
    dnd = false, vibrate = true,
}

-- Quand le joueur ne peut PAS sortir son téléphone
Config.Restrictions = {
    dead     = true,       -- mort / à terre
    cuffed   = true,       -- menotté
    ragdoll  = true,       -- au sol / assommé
    inVehicleDriver = false, -- true : interdit au conducteur d'un véhicule en mouvement
}

-- Limites et verrous divers
Config.Limits = {
    contacts       = 500,
    callLogDays    = 0,    -- purge de l'historique d'appels (0 = jamais)
    messageImages  = true, -- autoriser les images dans les messages
    messageLocation = true,
    groups         = true, -- autoriser les groupes de messages
    hideNumber     = true,
}

-- Règles d'accès à une application : ajoute dans Config.Apps  jobs = { 'police' }  (seuls ces métiers la voient)
-- ou  item = 'usb_key'  (il faut cet objet), ou  grade = 2  (grade minimum, avec jobs).

-- ═══════════════════════════ GÉNÉRAL ═══════════════════════════
Config.Brand        = 'Aero'            -- nom affiché (écran de démarrage, À propos…)
Config.Carrier      = (PickaxTheme and PickaxTheme.short) or 'Aero'   -- « opérateur » affiché dans Réglages → Général (nom court du serveur : pickax_core/config.lua)
Config.Model        = 'Aero Phone Pro'     -- modèle affiché dans Réglages → Général → Informations
Config.Command      = 'phone'           -- commande pour ouvrir/fermer le téléphone
Config.Key          = 'F1'              -- touche par défaut (modifiable par le joueur dans les paramètres FiveM)
Config.RequireItem  = true              -- true : il faut l'objet ci-dessous dans l'inventaire
Config.Item         = 'phone'           -- nom de l'objet téléphone (à créer dans ton inventaire si besoin)
Config.UseItem      = true              -- true : utiliser l'objet ouvre aussi le téléphone
Config.Debug        = false

-- ═══════════════════════════ NUMÉROS ═══════════════════════════
Config.Number = {
    format   = 'us',                                       -- 'us' : (310) 555-0142 · 'fr' : 06 12 34 56 78
    prefixes = { '213', '310', '323', '424', '747', '818' },   -- format 'us' : indicatifs de Los Angeles ; format 'fr' : début des numéros (ex. '06', '07')
    exchange = '555',                                      -- format 'us' : 3 chiffres suivants (555 = numéros fictifs réservés au cinéma)
    length   = 10,                                         -- longueur totale (chiffres)
    group    = 2,                                          -- format 'fr' : affichage par groupes de N chiffres
}

-- Réglages régionaux (mode Amérique par défaut)
Config.Region = {
    locale      = 'en-US',      -- séparateurs d'argent : 12,345 $
    temperature = 'F',          -- 'F' (°F, vent en mph) ou 'C' (°C, vent en km/h)
    dateOrder   = 'mdy',        -- 'mdy' (10/22/26) ou 'dmy' (22/10/26)
}
Config.MailDomain = 'aero.mail'      -- adresse mail : prenom.nom@aero.mail

-- ═══════════════════════════ APPELS ═══════════════════════════
Config.Calls = {
    ringTimeout   = 30,                 -- secondes avant « appel manqué »
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
    verifiedJobs  = { lspd = true, ambulance = true, pillboxhopital = true, banque = true, police = true, ems = true },   -- badge vérifié automatique (jobs de ta base)
    adminGroups   = { '_dev', 'superadmin', 'admin' },                -- peuvent supprimer / vérifier
}

-- ═══════════════════════════ BANQUE & CRYPTO ═══════════════════════════
Config.Bank = {
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
        { id = 'AER', name = 'Aero Coin', price = 12,   color = '#00a4ff' },
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

-- ═══════════════════════════ LIGNES DES MÉTIERS (app Services) ═══════════════════════════
-- D'où viennent les métiers joignables par les joueurs ?
--   'auto'       : le Job Builder s'il tourne (pickax_jobbuilder), sinon les métiers du framework (ESX / QBCore / Qbox)
--   'jobbuilder' : uniquement les jobs du Job Builder (réglage dans le builder → carte « Téléphone des joueurs »)
--   'framework'  : tous les métiers du framework (ESX jobs / QBCore jobs), réglés ci-dessous
--   'config'     : seulement la liste fixe Config.Services plus bas
Config.JobLines = {
    enabled       = true,
    source        = 'auto',
    voice         = true,      -- appels vocaux vers les métiers (le premier employé qui décroche)
    keepStatic    = false,     -- true : garde aussi Config.Services en plus des métiers détectés
    ringTimeout   = 30,        -- secondes de sonnerie chez les employés
    dutyOnly      = true,      -- framework : seuls les employés « en service » reçoivent les appels (si le framework gère le service)
    -- Source 'framework' : filtre et réglages par métier
    only          = {},        -- liste blanche ( { 'police', 'ambulance' } ). Vide = tous les métiers sauf « ignore »
    ignore        = { 'unemployed', 'unemployed2' },   -- chômeur / aucun métier de ta base
    -- Réglages par métier : label, number (court), icon, color, mode ('both' | 'voice' | 'alert'), anon, minGrade, hint
    jobs = {
        lspd      = { number = '911', icon = 'shield', color = '#2563eb', anon = true, hint = 'Que se passe-t-il ?', type = 'police' },
        ambulance = { number = '912', icon = 'heart', color = '#ef4444', type = 'ems' },
        pillboxhopital = { number = '', icon = 'heart', color = '#f43f5e', type = 'ems' },
        bennys    = { icon = 'wrench', color = '#f59e0b', type = 'mecano' },
        LsCustoms = { icon = 'wrench', color = '#f97316', type = 'mecano' },
        pdm       = { icon = 'car', color = '#22c55e', type = 'dealer' },
        banque    = { icon = 'bank', color = '#16a34a', type = 'bank' },
        police    = { number = '911', icon = 'shield', color = '#2563eb', anon = true, hint = 'Que se passe-t-il ?' },
        sheriff   = { number = '', icon = 'shield', color = '#92400e', anon = true },
        ambulance = { number = '912', icon = 'heart', color = '#ef4444' },
        ems       = { number = '912', icon = 'heart', color = '#ef4444' },
        mechanic  = { icon = 'wrench', color = '#f59e0b' },
        mecano    = { icon = 'wrench', color = '#f59e0b' },
        taxi      = { icon = 'car', color = '#eab308', type = 'taxi' },
        realestate = { icon = 'home', color = '#14b8a6' },
    },
    default = { icon = 'briefcase', color = '#8b5cf6', mode = 'both', anon = false, minGrade = 0 },   -- métiers non listés ci-dessus
}

-- ═══════════════════════════ SERVICES (URGENCES, JOBS) ═══════════════════════════
-- Liste fixe, utilisée si Config.JobLines.source = 'config' (ou keepStatic = true)
-- number : numéro composable au clavier ; jobs : métiers qui reçoivent l'alerte (en service)
Config.Services = {
    { id = 'police',   label = 'Police',        number = '911',  icon = 'shield', color = '#2563eb', jobs = { 'lspd', 'police', 'sheriff' },    anon = true },
    { id = 'ems',      label = 'Ambulance',     number = '912',  icon = 'heart',  color = '#ef4444', jobs = { 'ambulance', 'pillboxhopital', 'ems' }, anon = false },
    { id = 'fire',     label = 'Pompiers',      number = '913',  icon = 'flame',  color = '#f97316', jobs = { 'fire', 'ambulance', 'pillboxhopital' }, anon = false },
    { id = 'mecano',   label = 'Dépanneur',     number = '',    icon = 'wrench', color = '#f59e0b', jobs = { 'bennys', 'LsCustoms', 'mechanic', 'mecano' }, anon = false },
    { id = 'taxi',     label = 'Taxi',          number = '',    icon = 'car',    color = '#eab308', jobs = { 'taxi' },                        anon = false },
    { id = 'realestate', label = 'Agence immobilière', number = '', icon = 'home', color = '#14b8a6', jobs = { 'realestate' },              anon = false },
}
Config.Dispatch = {
    blipSeconds = 120,
    cooldown    = 20,                   -- secondes entre deux alertes d'un même joueur
    sprite = 280, color = 1,
}

-- ═══════════════════════════ DARKCHAT (salons anonymes) ═══════════════════════════
Config.Darkchat = {
    enabled      = true,
    item         = '',                   -- objet requis pour ouvrir l'app (ex. 'usb_key', ox_inventory). Vide = aucun objet requis
    maxRoomsOwn  = 3,                    -- salons créés par joueur
    ttlOptions   = { 0, 1, 6, 24, 168 }, -- durées de vie des messages proposées (heures, 0 = illimité)
    messageMax   = 500,
    aliasCooldown = 600,                 -- secondes entre deux changements de pseudo
    idleRoomDays = 7,                    -- un salon sans message depuis N jours est supprimé
    publicRooms  = {                     -- salons publics créés au démarrage
        { id = 'marche-noir', name = 'Marché noir', ttl = 24 },
        { id = 'general',     name = 'Général',     ttl = 24 },
        { id = 'rumeurs',     name = 'Rumeurs',     ttl = 6 },
    },
}

-- ═══════════════════════════ ENTREPRISE (facturation, équipe, société) ═══════════════════════════
Config.Business = {
    enabled       = true,
    source        = 'auto',              -- 'auto' (Job Builder sinon framework) | 'jobbuilder' | 'framework'
    allowFire     = true,                -- la direction peut licencier / promouvoir / recruter
    billDistance  = 6.0,                 -- distance max au client pour facturer
    maxBill       = 250000,
    billGrade     = 0,                   -- grade minimum pour facturer
    hireDistance  = 6.0,
}

-- ═══════════════════════════ TAXI ═══════════════════════════
Config.Taxi = { enabled = true, base = 15, ratePerKm = 45 }   -- estimation affichée au client ($)

-- ═══════════════════════════ ACTUALITÉS ═══════════════════════════
Config.News = {
    jobs = { 'weazel', 'journalist', 'journaliste', 'news' },   -- noms de métiers autorisés à publier
    adminCanPost = true,
    breakingToAll = true,                                      -- une info « urgente » notifie tous les joueurs
}

-- ═══════════════════════════ LOTO ═══════════════════════════
Config.Loto = {
    enabled = true, price = 50, drawEveryMinutes = 30, pick = 5, max = 30,
    jackpotSeed = 5000, sharePool = 0.7,          -- 70 % des mises alimentent la cagnotte
    payouts = { [3] = 15, [4] = 250 },            -- multiples de la mise pour 3 et 4 bons numéros ; 5 = cagnotte partagée
}

-- ═══════════════════════════ AIRSHARE ═══════════════════════════
Config.AirShare = { distance = 8.0, timeout = 25 }

-- ═══════════════════════════ LOCALISER ═══════════════════════════
Config.FindMy = { refresh = 5 }         -- secondes entre deux mises à jour de position partagée

-- ═══════════════════════════ MUSIQUE ═══════════════════════════
-- Flux audio directs (mp3/aac/ogg). Les joueurs peuvent aussi ajouter leurs propres URL.
Config.Radios = {
    { name = 'Aero FM',      url = 'https://icecast.radiofrance.fr/fip-midfi.mp3',  color = '#ef4444' },
    { name = 'Lofi Beats',   url = 'https://streams.ilovemusic.de/iloveradio17.mp3', color = '#8b5cf6' },
    { name = 'Hits',         url = 'https://streams.ilovemusic.de/iloveradio1.mp3',  color = '#f97316' },
    { name = 'Chill',        url = 'https://streams.ilovemusic.de/iloveradio10.mp3', color = '#14b8a6' },
}

-- ═══════════════════════════ APPLICATIONS ═══════════════════════════
-- default = installée d'office ; store = visible dans l'App Store ; system = ne peut pas être désinstallée
-- Pour retirer une app du téléphone : mets enabled = false.
-- Options par app (facultatives) : name = 'Nom affiché', grad = { '#couleur1', '#couleur2' }, icon = 'nom-icône',
--   jobs = { 'police' } (réservée à ces métiers), grade = 2 (grade minimum), item = 'nom_objet' (objet requis).
-- L'ordre de cette liste = l'ordre des icônes sur l'écran d'accueil.
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
    { id = 'business',  enabled = true, default = true },                  -- entreprise : facturation, employés, société (jobs du Job Builder)
    { id = 'keys',      enabled = true, default = true },                  -- clés : verrouiller / démarrer / klaxonner ses véhicules
    { id = 'reminders', enabled = true, default = true },
    { id = 'compass',   enabled = true, default = true },
    { id = 'health',    enabled = true, default = true },
    { id = 'darkchat',  enabled = true, default = false, store = true },   -- salons anonymes (voir Config.Darkchat)
    { id = 'games',     enabled = true, default = false, store = true },
    { id = 'taxi',      enabled = true, default = true },                  -- commander une course (jobs de type taxi du Job Builder)
    { id = 'news',      enabled = true, default = true },                  -- actualités du serveur (journalistes / admins)
    { id = 'loto',      enabled = true, default = false, store = true },   -- loto avec tirage régulier
    { id = 'converter', enabled = true, default = true },
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

-- ═══════════════════════════ FIN ═══════════════════════════
