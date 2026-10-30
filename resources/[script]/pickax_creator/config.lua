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

-- ───────────── Scène de création (caméra face au personnage) ─────────────
-- Position du studio : le joueur y est placé pendant l'apparence. coords = vector4(x, y, z, cap). nil = là où il se trouve déjà.
Config.Scene = {
    -- Lieu de la scène : le joueur y est téléporté pendant TOUTE la création (identité + apparence), puis renvoyé à son point de départ
    -- (ou conduit au point d'apparition choisi). Par défaut : sommet du Mont Chiliad (extérieur, ciel dégagé, aucun passant). Mets ton vestiaire / MLO ici.
    -- nil = ne pas téléporter (le joueur reste là où il est).
    Studio = vector4(501.0, 5604.0, 797.9, 180.0),
    CamDistance = 2.4,      -- distance de la caméra au personnage
    CamHeight = 0.45,       -- hauteur de visée (corps entier ≈ 0.0 ; visage ≈ 0.65)
}

-- ───────────── Carte du « Point d'apparition » ─────────────
-- html/map.png : image de la carte de Los Santos (non fournie). Les repères sont placés d'après ces bornes du monde.
Config.Map = { Image = 'map.png', MinX = -4100.0, MaxX = 4500.0, MinY = -4200.0, MaxY = 8000.0 }

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
