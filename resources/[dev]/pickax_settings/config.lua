Settings = {}

-- Chaque réglage : key, group, label, type ('bool' | 'number' | 'select' | 'text' | 'list'), default, hint
--   number : min, max, step    select : options = { { 'valeur', 'Libellé' } }    list : une ligne par élément (max 20)
-- Un réglage ne change RIEN tant qu'il n'est pas modifié depuis le panel web (« Réglages ») : les valeurs d'origine des ressources restent en vigueur.
Settings.Schema = {
    -- ── Serveur ──────────────────────────────────────────────────────────────
    { key = 'maintenance_enabled', group = 'Serveur', section = 'Maintenance', label = 'Mode maintenance', type = 'bool', default = false, hint = 'Refuse les nouveaux joueurs (sauf staff / identifiants autorisés) et prévient ceux en ligne.' },
    { key = 'maintenance_message', group = 'Serveur', section = 'Maintenance', label = 'Message de maintenance', type = 'text', default = 'Le serveur est en maintenance, reviens dans quelques minutes.', hint = 'Affiché aux joueurs refusés.' },
    { key = 'maintenance_allow', group = 'Serveur', section = 'Maintenance', label = 'Identifiants autorisés pendant la maintenance', type = 'list', default = {}, hint = 'Un identifiant par ligne (license:… ou discord:…). Les administrateurs (ACE « command ») entrent toujours.' },
    { key = 'maintenance_kick', group = 'Serveur', section = 'Maintenance', label = 'Expulser les joueurs en ligne à l\'activation', type = 'bool', default = true, hint = 'Après 2 minutes de préavis (le staff n\'est jamais expulsé).' },
    { key = 'announce_enabled', group = 'Serveur', section = 'Annonces automatiques', label = 'Annonces automatiques', type = 'bool', default = false, hint = 'Un message tourne à intervalle régulier (règles, Discord, boutique…).' },
    { key = 'announce_interval', group = 'Serveur', section = 'Annonces automatiques', label = 'Intervalle des annonces (minutes)', type = 'number', default = 15, min = 1, max = 240, step = 1 },
    { key = 'announce_messages', group = 'Serveur', section = 'Annonces automatiques', label = 'Messages des annonces', type = 'list', default = { 'Pense à lire le règlement du serveur.' }, hint = 'Un message par ligne : ils sont envoyés à tour de rôle.' },
    { key = 'restart_enabled', group = 'Serveur', section = 'Redémarrages programmés', label = 'Redémarrages programmés', type = 'bool', default = false, hint = 'Arrête le serveur aux heures indiquées (txAdmin ou ton hébergeur doit le relancer). N\'active pas ceci si txAdmin gère déjà tes redémarrages.' },
    { key = 'restart_times', group = 'Serveur', section = 'Redémarrages programmés', label = 'Heures de redémarrage', type = 'text', default = '05:00', hint = 'Format HH:MM séparées par des virgules, heure du serveur. Ex : 05:00,17:00. Annonces à −30, −10, −5 et −1 minute.' },

    -- ── Interface : notifications ───────────────────────────────────────────
    { key = 'notify_left', group = 'Interface', section = 'Notifications', label = 'Notifications : distance au bord gauche (vw)', type = 'number', default = 1.35, min = 0, max = 80, step = 0.05 },
    { key = 'notify_bottom', group = 'Interface', section = 'Notifications', label = 'Notifications : distance au bas (vh)', type = 'number', default = 22.5, min = 0, max = 90, step = 0.5 },

    -- ── Interface : boussole ────────────────────────────────────────────────
    { key = 'compass_layout', group = 'Interface', section = 'Boussole', label = 'Boussole : format', type = 'select', default = 'compact', options = { { 'compact', 'Compacte (en bas à gauche)' }, { 'top', 'Grande bande en haut' } } },
    { key = 'compass_street', group = 'Interface', section = 'Boussole', label = 'Boussole : afficher le nom de la rue', type = 'bool', default = true },
    { key = 'compass_left', group = 'Interface', section = 'Boussole', label = 'Boussole compacte : position gauche (vw)', type = 'number', default = 19.6, min = 0, max = 90, step = 0.1 },
    { key = 'compass_bottom', group = 'Interface', section = 'Boussole', label = 'Boussole compacte : position bas (vh)', type = 'number', default = 3.4, min = 0, max = 90, step = 0.1 },

    -- ── Interface : HUD ─────────────────────────────────────────────────────
    -- ── Carnet du joueur ────────────────────────────────────────────────────
    { key = 'carnet_enabled', group = 'Carnet', section = 'Récompenses', label = 'Carnet du joueur activé', type = 'bool', default = true, hint = 'Série de connexion, objectifs du jour et de la semaine, défi de la ville (touche F3). Les récompenses sont versées automatiquement.' },
    { key = 'carnet_reward_mult', group = 'Carnet', section = 'Récompenses', label = 'Multiplicateur des récompenses', type = 'number', default = 1.0, min = 0, max = 10, step = 0.1, hint = 'S\'applique à toutes les récompenses du carnet (série, objectifs, défi de la ville), en plus du type d\'économie du serveur.' },
    { key = 'hud_needs', group = 'Interface', section = 'HUD (faim, soif, vie)', label = 'HUD : afficher faim et soif', type = 'bool', default = true },
    { key = 'hud_health', group = 'Interface', section = 'HUD (faim, soif, vie)', label = 'HUD : afficher la barre de vie', type = 'bool', default = true },
    { key = 'hud_armor', group = 'Interface', section = 'HUD (faim, soif, vie)', label = 'HUD : afficher la ligne d\'armure', type = 'bool', default = true },
    { key = 'hud2_server', group = 'Interface', section = 'Cartes en haut à droite', label = 'Cartes en haut à droite : serveur (nom, Discord, joueurs)', type = 'bool', default = true, hint = 'Si tu désactives une carte ici, aucun joueur ne peut la réactiver.' },
    { key = 'hud2_job', group = 'Interface', section = 'Cartes en haut à droite', label = 'Cartes en haut à droite : métier', type = 'bool', default = true },
    { key = 'hud2_money', group = 'Interface', section = 'Cartes en haut à droite', label = 'Cartes en haut à droite : argent', type = 'bool', default = true },

    -- ── Voix ────────────────────────────────────────────────────────────────
    { key = 'voice_whisper', group = 'Voix', section = 'Distances de la voix', label = 'Distance « chuchoter » (m)', type = 'number', default = 3, min = 0.5, max = 50, step = 0.5, hint = 'Appliquée à tous les joueurs, sans redémarrage.' },
    { key = 'voice_normal', group = 'Voix', section = 'Distances de la voix', label = 'Distance « normal » (m)', type = 'number', default = 7, min = 1, max = 80, step = 0.5 },
    { key = 'voice_shout', group = 'Voix', section = 'Distances de la voix', label = 'Distance « crier » (m)', type = 'number', default = 15, min = 2, max = 150, step = 0.5 },

    -- ── Performance ─────────────────────────────────────────────────────────
    { key = 'perf_mode', group = 'Performance', section = 'Mode performance', label = 'Mode performance des interfaces', type = 'select', default = 'auto', options = { { 'auto', 'Automatique (activé seulement si les FPS du joueur sont bas)' }, { 'on', 'Toujours activé (tous les joueurs)' }, { 'off', 'Désactivé' } }, hint = 'Supprime les ombres, lueurs, flous et animations en boucle des interfaces (HUD, menus, builders) : gain de FPS sur les PC faibles. Aucun effet sur les bons PC en mode automatique.' },
    { key = 'perf_threshold', group = 'Performance', section = 'Mode performance', label = 'Seuil « FPS bas » du mode automatique', type = 'number', default = 40, min = 20, max = 60, step = 1, hint = 'Sous ce nombre d\'images par seconde pendant quelques secondes, le mode performance s\'active ; il se désactive quand les FPS remontent nettement.' },

    -- ── Économie ────────────────────────────────────────────────────────────
    { key = 'eco_weekend_income', group = 'Économie', section = 'Gains', label = 'Bonus de gains le week-end (×)', type = 'number', default = 1, min = 1, max = 3, step = 0.05, hint = '1 = aucun bonus. 1.5 = +50 % de gains le samedi et le dimanche (en plus du type d\'économie).' },

    -- ── Monde & PNJ ─────────────────────────────────────────────────────────
    { key = 'npc_enabled', group = 'Monde & PNJ', section = "Population", label = "PNJ et circulation", type = 'bool', default = false, hint = "Désactivé : aucune population ambiante (rues vides, meilleures performances). Activé : piétons et voitures selon les densités ci-dessous." },
    { key = 'npc_density', group = 'Monde & PNJ', section = "Population", label = "Densité des piétons", type = 'number', default = 0.5, min = 0, max = 1, step = 0.05, hint = "0 = aucun, 1 = maximum. Sans effet si « PNJ et circulation » est désactivé." },
    { key = 'traffic_density', group = 'Monde & PNJ', section = "Population", label = "Densité de la circulation", type = 'number', default = 0.5, min = 0, max = 1, step = 0.05, hint = "Voitures en mouvement." },
    { key = 'parked_density', group = 'Monde & PNJ', section = "Population", label = "Densité des véhicules garés", type = 'number', default = 0.5, min = 0, max = 1, step = 0.05, hint = "Voitures stationnées le long des rues." },
    { key = 'npc_police', group = 'Monde & PNJ', section = "Police et recherche", label = "Policiers PNJ (patrouilles, hélicoptères)", type = 'bool', default = false, hint = "Désactivé : aucune police automatique de GTA (la police est jouée par les joueurs)." },
    { key = 'wanted_enabled', group = 'Monde & PNJ', section = "Police et recherche", label = "Niveau de recherche (étoiles)", type = 'bool', default = true, hint = "Désactivé : les joueurs ne sont jamais « recherchés » par la police PNJ." },
    { key = 'npc_boats', group = 'Monde & PNJ', section = "Transports ambiants", label = "Bateaux PNJ", type = 'bool', default = false },
    { key = 'npc_trains', group = 'Monde & PNJ', section = "Transports ambiants", label = "Trains PNJ", type = 'bool', default = false },
    { key = 'npc_garbage', group = 'Monde & PNJ', section = "Transports ambiants", label = "Camions-poubelles PNJ", type = 'bool', default = false },

    -- ── Météo & heure ───────────────────────────────────────────────────────
    { key = 'weather_dynamic', group = 'Météo & heure', section = "Météo", label = "Météo dynamique", type = 'bool', default = false, hint = "Activé : la météo change toute seule avec le temps. Désactivé : la météo choisie ci-dessous reste fixe." },
    { key = 'weather_type', group = 'Météo & heure', section = "Météo", label = "Météo fixe", type = 'select', default = "EXTRASUNNY", options = { { "EXTRASUNNY", "Grand soleil" }, { "CLEAR", "Dégagé" }, { "CLOUDS", "Nuageux" }, { "OVERCAST", "Couvert" }, { "CLEARING", "Éclaircies" }, { "FOGGY", "Brouillard" }, { "SMOG", "Smog" }, { "RAIN", "Pluie" }, { "THUNDER", "Orage" }, { "SNOW", "Neige" }, { "XMAS", "Noël (neige partout)" }, { "HALLOWEEN", "Halloween" } }, hint = "Utilisée quand la météo dynamique est désactivée." },
    { key = 'blackout', group = 'Météo & heure', section = "Météo", label = "Panne de courant (noir total)", type = 'bool', default = false, hint = "Éteint toutes les lumières de la ville." },
    { key = 'time_frozen', group = 'Météo & heure', section = "Heure", label = "Figer l'heure", type = 'bool', default = false, hint = "Activé : il est toujours l'heure choisie ci-dessous. Désactivé : l'heure s'écoule normalement." },
    { key = 'time_hour', group = 'Météo & heure', section = "Heure", label = "Heure figée", type = 'number', default = 12, min = 0, max = 23, step = 1, hint = "Heure du jeu (0 à 23) quand l'heure est figée." },

    -- ── Joueurs & combat ────────────────────────────────────────────────────
    { key = 'friendly_fire', group = 'Joueurs & combat', section = "Combat", label = "Tir ami (dégâts entre joueurs)", type = 'bool', default = true, hint = "Désactivé : les joueurs ne peuvent pas se blesser entre eux avec les armes à feu." },
    { key = 'weapon_damage', group = 'Joueurs & combat', section = "Combat", label = "Dégâts des armes (×)", type = 'number', default = 1.0, min = 0.1, max = 3, step = 0.1, hint = "1 = normal, 0.5 = moitié moins de dégâts, 2 = double." },
    { key = 'melee_damage', group = 'Joueurs & combat', section = "Combat", label = "Dégâts au corps à corps (×)", type = 'number', default = 1.0, min = 0.1, max = 3, step = 0.1, hint = "Poings et armes blanches." },
    { key = 'critical_hits', group = 'Joueurs & combat', section = "Combat", label = "Coups critiques (tir à la tête)", type = 'bool', default = true, hint = "Désactivé : un tir à la tête ne tue pas instantanément." },
    { key = 'drive_by', group = 'Joueurs & combat', section = "Combat", label = "Tirer depuis un véhicule", type = 'bool', default = true, hint = "Désactivé : impossible de tirer en conduisant ou en passager." },
    { key = 'health_regen', group = 'Joueurs & combat', section = "Santé et endurance", label = "Régénération naturelle de la vie (×)", type = 'number', default = 1.0, min = 0, max = 3, step = 0.1, hint = "0 = la vie ne remonte jamais toute seule (il faut se soigner : EMS, kits). 1 = normal." },
    { key = 'stamina_infinite', group = 'Joueurs & combat', section = "Santé et endurance", label = "Endurance infinie", type = 'bool', default = false, hint = "Activé : on ne se fatigue jamais en courant ou nageant." },
    { key = 'idle_cam', group = 'Joueurs & combat', section = "Divers", label = "Caméra d'inactivité (cinématique AFK)", type = 'bool', default = true, hint = "Désactivé : l'écran ne passe jamais en caméra cinématique quand le joueur est inactif." },

    -- ── Nouveaux joueurs ────────────────────────────────────────────────────
    { key = 'start_money', group = 'Nouveaux joueurs', section = "Création du personnage", label = "Argent bonus à l'arrivée (banque)", type = 'number', default = 0, min = 0, max = 1000000, step = 100, hint = "Versé une seule fois quand un personnage est créé, EN PLUS de l'argent de départ d'ESX." },
    { key = 'welcome_message', group = 'Nouveaux joueurs', section = "Accueil", label = "Message de bienvenue", type = 'text', default = "", hint = "Notification affichée à chaque connexion. Laisse vide pour ne rien afficher. {nom} est remplacé par le nom du joueur." },

    -- ── Interface (suite) ───────────────────────────────────────────────────
    { key = 'hud_crosshair', group = 'Interface', section = "Viseur", label = "Afficher le viseur", type = 'bool', default = true, hint = "Désactivé : pas de point de visée (plus de réalisme)." },

    -- ── Discord ─────────────────────────────────────────────────────────────
    { key = 'discord_status', group = 'Discord', section = "Statut Discord", label = "Texte du statut (présence)", type = 'text', default = "", hint = "Affiché sur le profil Discord du joueur. Variables : {nom}, {id}, {joueurs}. Laisse vide pour garder le statut d'origine." },
}
