Config = {}

-- ───────────── Musique des écrans de création (identité, apparence) ─────────────
-- Ajoute tes fichiers dans html/music/ (mp3, ogg) et déclare-les ici. Vide = le lecteur est masqué.
-- cover (facultatif) : image dans html/ (ex. 'cover1.jpg') ou lien https.
Config.Music = {
    Enabled = true,
    Volume = 0.35,
    Tracks = {
        -- { title = 'Lofi Producer', artist = 'Chill Vibes', file = 'music/lofi.mp3', cover = '' },
    },
}

-- ───────────── Scène de création : où s'ouvrent les premiers menus + caméra ─────────────
-- Le joueur est placé au Studio pendant TOUTE la création (identité + apparence), puis renvoyé à son point de départ (ou conduit à la destination choisie).
Config.Scene = {
    -- Lieu : vector4(x, y, z, cap). Le cap est la direction dans laquelle regarde le personnage ; la caméra se place en face.
    -- Par défaut : sommet du Mont Chiliad (extérieur, ciel dégagé, aucun passant). Mets ici ton vestiaire / MLO / une rue de ton choix.
    -- nil = ne pas téléporter (le joueur reste là où il est).
    Studio = vector4(501.0, 5604.0, 797.9, 180.0),
    LoadRadius = 80.0,       -- rayon (m) du décor chargé avant d'afficher les menus (augmente-le pour un grand MLO)
    -- Caméra
    Camera = {
        Distance  = 2.4,     -- distance de la caméra au personnage (m)
        Height    = 0.45,    -- hauteur de la cible (corps entier ≈ 0.0 ; visage ≈ 0.65)
        Rise      = 0.35,    -- la caméra est placée plus haut que la cible de cette valeur (m)
        Fov       = 45.0,    -- champ de vision (plus petit = plus « zoomé »)
        Angle     = 0.0,     -- 0 = face au personnage ; 90 = de côté ; 180 = de dos (degrés)
        Side      = 0.0,     -- décalage latéral (m) : positif = vers la droite du personnage
        ZoomMin   = 0.9,     -- distance minimale quand le joueur zoome (molette)
        ZoomMax   = 3.6,     -- distance maximale
        RotateSpeed = 0.55,  -- vitesse de rotation du personnage à la souris
        ZoomSpeed   = 0.0025,
    },
    FadeOut = 300,           -- ms : fondu au noir avant la téléportation
    FadeIn  = 500,           -- ms : fondu depuis le noir à l'affichage
    HideRadar = true,        -- masque la mini-carte pendant la création
}

-- ───────────── Destination : lieux d'arrivée proposés une fois le personnage validé (création uniquement) ─────────────
-- Le joueur choisit l'un de ces lieux. Modifie / ajoute des lieux librement (3 recommandés pour une belle présentation).
-- coords = vector4(x, y, z, cap). icon (facultatif) : 'plane', 'city', 'beach', 'house', 'pin'.
-- image (facultatif) : fichier placé dans pickax_creator/html/places/ (jpg/png, 626×264 conseillé).
-- Un seul lieu = pas de choix : le joueur y arrive directement. Enabled = false : le joueur reste là où la création l'a laissé.
Config.Destinations = {
    Enabled = true,
    Title = 'Destination',
    Hint = 'Choisis où commencer ta vie',
    Spots = {
        { label = 'Aéroport de Los Santos', description = 'Arrive comme tout nouveau venu en ville.',  icon = 'plane', image = 'airport.jpg', coords = vector4(-1037.00, -2737.00, 20.17, 330.00) },
        { label = 'Legion Square',          description = 'Au cœur de la ville, près de tout.',        icon = 'city',  image = 'legion.jpg', coords = vector4(195.17, -933.77, 30.69, 144.00) },
        { label = 'Plage de Vespucci',      description = 'Un début de vie au bord de l\'océan.',      icon = 'beach', image = 'vespucci.jpg', coords = vector4(-1392.00, -1430.00, 4.00, 25.00) },
    },
}

-- ───────────── Carte du « Point d'apparition » ─────────────
-- html/map.jpg : vraie carte satellite de San Andreas (fournie). Les repères sont placés d'après ces bornes du monde (calées sur l'image) ; remplace map.jpg par ta propre carte en gardant le même cadrage, ou ajuste les bornes.
Config.Map = { Image = 'map.jpg', MinX = -5989.0, MaxX = 7393.0, MinY = -4911.0, MaxY = 8471.0 }

-- ───────────── Message de bienvenue (après l'arrivée) ─────────────
-- Highlight : mot mis en couleur dans le titre. Duration en ms (0 = reste jusqu'au clic).
Config.Welcome = {
    Enabled = true,
    Title = 'Bienvenue sur le',
    Highlight = 'serveur',
    Text = 'Afin de vous garantir une expérience optimale, nous vous invitons à lire le règlement et à profiter de votre aventure.',
    Duration = 9000,
}

-- Nom affiché dans les écrans (vide = nom du serveur du thème)
Config.ServerName = ''
