Config = {}

-- ─────────────────────────────── CarPlay : autoradio de véhicule ───────────────────────────────
-- Ouverture : menu contextuel du véhicule → « Ouvrir CarPlay », commande ci-dessous, ou export exports.pickax_core:OpenCarPlay().
Config.Command  = 'carplay'      -- '' = pas de commande
Config.OpenKey  = ''             -- touche proposée dans les réglages FiveM (ex : 'F10') — '' = aucune

-- Qui peut piloter la musique : 'all' = tous les occupants du véhicule, 'driver' = le conducteur seulement
Config.ControlSeats = 'all'

-- ─────────────────────────────── Son ───────────────────────────────
Config.MaxHearDistance = 28.0    -- distance maximale (m) à laquelle on entend la musique depuis l'extérieur
Config.OutsideMuffle   = 0.35    -- part du volume entendue de l'extérieur quand portes fermées et toit fermé (1.0 = pas d'étouffement)
Config.MaxChannels     = 3       -- nombre de véhicules audibles en même temps (les plus proches)
Config.DefaultVolume   = 50      -- volume au premier allumage (0-100)
Config.TrackToast      = true    -- petit bandeau « en cours de lecture » à chaque changement de titre (réglable par joueur)

-- ─────────────────────────────── Liens acceptés ───────────────────────────────
-- YouTube (youtube.com / youtu.be / music.youtube.com / shorts / live) : toujours accepté.
-- Liens directs (.mp3, .ogg, flux radio…) : voir ci-dessous.
Config.AllowDirectLinks = true
Config.AllowedHosts     = {}     -- liste blanche des domaines pour les liens directs (ex : { 'ice1.somafm.com' }) — vide = tous sauf réseau privé
Config.BlockedHosts     = {}     -- domaines interdits
Config.BlockPrivateHosts = true  -- refuse localhost / adresses privées (les clients ne doivent jamais appeler un réseau local)
Config.QueueMax         = 40     -- titres maximum dans la file d'attente
Config.StopWhenEmptyMinutes = 10 -- véhicule vide : la musique s'arrête après X minutes (0 = jamais)

-- Recherche YouTube dans l'appli (optionnelle) : clé « YouTube Data API v3 » à mettre dans server.cfg :
--   set carplay_youtube_key "TA_CLE"        (sans clé : on colle simplement un lien)
Config.YouTubeKeyConvar = 'carplay_youtube_key'

-- Radios / favoris proposés d'office dans l'onglet « Radios » (ajoute les tiens : label + url)
Config.Presets = {
    { label = 'Lofi Girl',        sub = 'Lofi hip hop · 24/7',     url = 'https://www.youtube.com/watch?v=jfKfPfyJRdk', color = '#a855f7' },
    { label = 'Groove Salad',     sub = 'SomaFM · Chill',          url = 'https://ice1.somafm.com/groovesalad-128-mp3',  color = '#22c55e' },
    { label = 'Radio Paradise',   sub = 'Éclectique',              url = 'https://stream.radioparadise.com/mp3-128',      color = '#f59e0b' },
    { label = 'Secret Agent',     sub = 'SomaFM · Lounge',         url = 'https://ice1.somafm.com/secretagent-128-mp3',   color = '#ef4444' },
    { label = 'Drone Zone',       sub = 'SomaFM · Ambient',        url = 'https://ice1.somafm.com/dronezone-128-mp3',     color = '#06b6d4' },
}
