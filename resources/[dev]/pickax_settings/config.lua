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

    -- ═══ Réglages des builders (gangs, laboratoires, drogues) : appliqués par panelsettings.lua de chaque ressource ═══
    -- ── Gangs ──────────────────────────────────
    { key = 'gb_terr_enabled', group = 'Gangs', section = 'Territoires', label = 'Territoires activés', type = 'bool', default = true, hint = 'Désactivé : plus de capture ni de revenu de zone.' },
    { key = 'gb_capture_seconds', group = 'Gangs', section = 'Territoires', label = 'Durée de capture (secondes)', type = 'number', default = 120, min = 15, max = 3600, step = 5, hint = 'Temps passé dans la zone, seul, pour la capturer.' },
    { key = 'gb_capture_members', group = 'Gangs', section = 'Territoires', label = 'Membres minimum pour capturer', type = 'number', default = 1, min = 1, max = 30, step = 1 },
    { key = 'gb_owner_blocks', group = 'Gangs', section = 'Territoires', label = 'La présence du propriétaire bloque la capture', type = 'bool', default = true },
    { key = 'gb_protection_min', group = 'Gangs', section = 'Territoires', label = 'Protection après une capture (minutes)', type = 'number', default = 30, min = 0, max = 1440, step = 5 },
    { key = 'gb_income_interval', group = 'Gangs', section = 'Territoires', label = 'Intervalle des revenus (minutes)', type = 'number', default = 15, min = 1, max = 240, step = 1 },
    { key = 'gb_income_reward', group = 'Gangs', section = 'Territoires', label = 'Revenu par période ($)', type = 'number', default = 500, min = 0, max = 1000000, step = 50, hint = 'Multiplié par le niveau du territoire.' },
    { key = 'gb_income_account', group = 'Gangs', section = 'Territoires', label = 'Compte crédité par les revenus', type = 'select', default = 'dirty', options = { { 'dirty', 'Argent sale' }, { 'money', 'Argent propre' } } },
    { key = 'gb_min_defenders', group = 'Gangs', section = 'Territoires', label = 'Défenseurs connectés requis pour capturer', type = 'number', default = 1, min = 0, max = 30, step = 1, hint = '0 = pas de condition (raid possible même si le gang est hors ligne).' },
    { key = 'gb_max_per_gang', group = 'Gangs', section = 'Territoires', label = 'Territoires maximum par gang', type = 'number', default = 0, min = 0, max = 50, step = 1, hint = '0 = illimité.' },
    { key = 'gb_alert_owner', group = 'Gangs', section = 'Territoires', label = 'Prévenir le propriétaire quand on attaque sa zone', type = 'bool', default = true },
    { key = 'gb_racket_enabled', group = 'Gangs', section = 'Racket', label = 'Racket activé', type = 'bool', default = true, hint = 'Un gang qui vend de la drogue sur le territoire d\'un autre paie une taxe au propriétaire.' },
    { key = 'gb_racket_rate', group = 'Gangs', section = 'Racket', label = 'Taux du racket (%)', type = 'number', default = 10, min = 0, max = 90, step = 1 },
    { key = 'gb_conf_enabled', group = 'Gangs', section = 'Affrontements', label = 'Affrontements activés', type = 'bool', default = true, hint = 'Une activité illégale sur le territoire d\'un autre gang déclenche un affrontement.' },
    { key = 'gb_conf_duration', group = 'Gangs', section = 'Affrontements', label = 'Durée (secondes)', type = 'number', default = 300, min = 60, max = 3600, step = 30 },
    { key = 'gb_conf_cooldown', group = 'Gangs', section = 'Affrontements', label = 'Délai entre deux affrontements (secondes)', type = 'number', default = 900, min = 60, max = 7200, step = 60 },
    { key = 'gb_conf_capture', group = 'Gangs', section = 'Affrontements', label = 'L\'intrus qui gagne capture le territoire', type = 'bool', default = true },
    { key = 'gb_conf_rep', group = 'Gangs', section = 'Affrontements', label = 'Réputation du gagnant', type = 'number', default = 20, min = 0, max = 1000, step = 1 },
    { key = 'gb_turf_enabled', group = 'Gangs', section = 'Guerre de zone déclarée', label = 'Guerre de zone activée', type = 'bool', default = true, hint = 'Le bureau d\'un gang déclare la guerre au propriétaire d\'un territoire (tablette ou /startturfwar).' },
    { key = 'gb_turf_prep', group = 'Gangs', section = 'Guerre de zone déclarée', label = 'Préparation avant le début (secondes)', type = 'number', default = 120, min = 0, max = 1800, step = 15 },
    { key = 'gb_turf_duration', group = 'Gangs', section = 'Guerre de zone déclarée', label = 'Durée de la dispute (secondes)', type = 'number', default = 600, min = 120, max = 3600, step = 30 },
    { key = 'gb_turf_attackers', group = 'Gangs', section = 'Guerre de zone déclarée', label = 'Attaquants connectés requis', type = 'number', default = 2, min = 1, max = 30, step = 1 },
    { key = 'gb_turf_defenders', group = 'Gangs', section = 'Guerre de zone déclarée', label = 'Défenseurs connectés requis', type = 'number', default = 1, min = 0, max = 30, step = 1 },
    { key = 'gb_turf_cooldown', group = 'Gangs', section = 'Guerre de zone déclarée', label = 'Délai avant de redéclarer sur la même zone (secondes)', type = 'number', default = 1800, min = 60, max = 14400, step = 60 },
    { key = 'gb_turf_minkills', group = 'Gangs', section = 'Guerre de zone déclarée', label = 'Kills d\'avance pour que l\'attaquant l\'emporte', type = 'number', default = 1, min = 1, max = 50, step = 1 },
    { key = 'gb_turf_repwin', group = 'Gangs', section = 'Guerre de zone déclarée', label = 'Réputation du gagnant', type = 'number', default = 30, min = 0, max = 1000, step = 1 },
    { key = 'gb_turf_replose', group = 'Gangs', section = 'Guerre de zone déclarée', label = 'Réputation retirée au perdant', type = 'number', default = 10, min = 0, max = 1000, step = 1 },
    { key = 'gb_turf_protected', group = 'Gangs', section = 'Guerre de zone déclarée', label = 'Autoriser la guerre sur un territoire protégé', type = 'bool', default = false },
    { key = 'gb_trib_enabled', group = 'Gangs', section = 'Zones de tribut', label = 'Zones de tribut activées', type = 'bool', default = true, hint = 'Les gangs se disputent un commerce ; le gang avec le plus de survivants collecte le tribut.' },
    { key = 'gb_trib_auto', group = 'Gangs', section = 'Zones de tribut', label = 'Lancement automatique', type = 'bool', default = true, hint = 'Sinon : /starttribute à la main.' },
    { key = 'gb_trib_interval', group = 'Gangs', section = 'Zones de tribut', label = 'Intervalle entre deux événements (minutes)', type = 'number', default = 60, min = 5, max = 720, step = 5 },
    { key = 'gb_trib_gangs', group = 'Gangs', section = 'Zones de tribut', label = 'Gangs connectés requis pour un lancement automatique', type = 'number', default = 2, min = 1, max = 20, step = 1 },
    { key = 'gb_trib_minper', group = 'Gangs', section = 'Zones de tribut', label = 'Survivants minimum pour pouvoir gagner', type = 'number', default = 1, min = 1, max = 30, step = 1 },
    { key = 'gb_trib_seconds', group = 'Gangs', section = 'Zones de tribut', label = 'Durée de la dispute (secondes)', type = 'number', default = 300, min = 60, max = 1800, step = 30 },
    { key = 'gb_trib_collect', group = 'Gangs', section = 'Zones de tribut', label = 'Temps pour collecter (secondes)', type = 'number', default = 600, min = 60, max = 3600, step = 30 },
    { key = 'gb_trib_reward', group = 'Gangs', section = 'Zones de tribut', label = 'Tribut ($)', type = 'number', default = 3000, min = 0, max = 1000000, step = 100 },
    { key = 'gb_trib_account', group = 'Gangs', section = 'Zones de tribut', label = 'Compte crédité par le tribut', type = 'select', default = 'dirty', options = { { 'dirty', 'Argent sale' }, { 'money', 'Argent propre' } } },
    { key = 'gb_trib_rep', group = 'Gangs', section = 'Zones de tribut', label = 'Réputation du gagnant', type = 'number', default = 15, min = 0, max = 1000, step = 1 },
    { key = 'gb_obj_enabled', group = 'Gangs', section = 'Missions colis', label = 'Missions colis activées', type = 'bool', default = true },
    { key = 'gb_obj_auto', group = 'Gangs', section = 'Missions colis', label = 'Lancement automatique', type = 'bool', default = true },
    { key = 'gb_obj_interval', group = 'Gangs', section = 'Missions colis', label = 'Intervalle entre deux missions (minutes)', type = 'number', default = 45, min = 5, max = 720, step = 5 },
    { key = 'gb_obj_hold', group = 'Gangs', section = 'Missions colis', label = 'Temps à tenir dans la zone (secondes)', type = 'number', default = 180, min = 30, max = 1200, step = 10 },
    { key = 'gb_obj_reward', group = 'Gangs', section = 'Missions colis', label = 'Récompense ($)', type = 'number', default = 5000, min = 0, max = 1000000, step = 100 },
    { key = 'gb_obj_rep', group = 'Gangs', section = 'Missions colis', label = 'Réputation', type = 'number', default = 40, min = 0, max = 1000, step = 1 },
    { key = 'gb_wars_enabled', group = 'Gangs', section = 'Guerres entre gangs (tablette)', label = 'Guerres entre gangs activées', type = 'bool', default = true },
    { key = 'gb_wars_stake', group = 'Gangs', section = 'Guerres entre gangs (tablette)', label = 'Mise maximum ($ sale)', type = 'number', default = 50000, min = 0, max = 10000000, step = 500 },
    { key = 'gb_wars_cooldown', group = 'Gangs', section = 'Guerres entre gangs (tablette)', label = 'Délai avant de se rebattre contre le même gang (minutes)', type = 'number', default = 30, min = 0, max = 1440, step = 5 },
    { key = 'gb_wars_repwin', group = 'Gangs', section = 'Guerres entre gangs (tablette)', label = 'Réputation du gagnant', type = 'number', default = 60, min = 0, max = 1000, step = 1 },
    { key = 'gb_wars_replose', group = 'Gangs', section = 'Guerres entre gangs (tablette)', label = 'Réputation retirée au perdant', type = 'number', default = 15, min = 0, max = 1000, step = 1 },

    -- ── Drogues & labos ──────────────────────────────────
    { key = 'jb_lab_enabled', group = 'Drogues & labos', section = 'Laboratoire interactif', label = 'Fabrication interactive activée', type = 'bool', default = true, hint = 'Désactivé : les tables de traitement reviennent à l\'ancienne barre de progression.' },
    { key = 'jb_lab_yield', group = 'Drogues & labos', section = 'Laboratoire interactif', label = 'Part du rendement qui dépend de la qualité', type = 'number', default = 0.4, min = 0, max = 1, step = 0.05, hint = '0 = la qualité ne change pas le nombre de pochons ; 1 = rendement proportionnel à la qualité.' },
    { key = 'jb_lab_fail', group = 'Drogues & labos', section = 'Laboratoire interactif', label = 'Risque de lot raté à qualité 0 (%)', type = 'number', default = 35, min = 0, max = 100, step = 1, hint = 'Ajouté au risque de la recette ; aucun risque ajouté à qualité 100 %.' },
    { key = 'jb_lab_bonus_q', group = 'Drogues & labos', section = 'Laboratoire interactif', label = 'Seuil de qualité du bonus (0-1)', type = 'number', default = 0.92, min = 0.5, max = 1, step = 0.01 },
    { key = 'jb_lab_bonus_extra', group = 'Drogues & labos', section = 'Laboratoire interactif', label = 'Pochons bonus si qualité parfaite', type = 'number', default = 1, min = 0, max = 10, step = 1 },
    { key = 'jb_lab_minstep', group = 'Drogues & labos', section = 'Laboratoire interactif', label = 'Durée minimale d\'une étape (ms, anti-triche)', type = 'number', default = 1200, min = 300, max = 10000, step = 100 },
    { key = 'jb_lab_3d', group = 'Drogues & labos', section = 'Rendu 3D et caméra du labo', label = 'Objets 3D sur la table', type = 'bool', default = true, hint = 'Désactivé : ancien rendu 2D.' },
    { key = 'jb_lab_light', group = 'Drogues & labos', section = 'Rendu 3D et caméra du labo', label = 'Lueur et éclairage de la table', type = 'bool', default = true },
    { key = 'jb_lab_mat', group = 'Drogues & labos', section = 'Rendu 3D et caméra du labo', label = 'Tapis sombre sous les objets', type = 'bool', default = true },
    { key = 'jb_lab_cam_dist', group = 'Drogues & labos', section = 'Rendu 3D et caméra du labo', label = 'Distance de la caméra (m)', type = 'number', default = 0.85, min = 0.4, max = 2.5, step = 0.05 },
    { key = 'jb_lab_cam_pitch', group = 'Drogues & labos', section = 'Rendu 3D et caméra du labo', label = 'Inclinaison de la caméra (°)', type = 'number', default = -64, min = -90, max = -20, step = 1, hint = '-90 = vue de dessus, -30 = vue rasante.' },
    { key = 'jb_lab_cam_fov', group = 'Drogues & labos', section = 'Rendu 3D et caméra du labo', label = 'Champ de vision de la caméra (°)', type = 'number', default = 45, min = 25, max = 75, step = 1 },
    { key = 'jb_toxic_enabled', group = 'Drogues & labos', section = 'Intoxication des laboratoires', label = 'Intoxication activée', type = 'bool', default = true, hint = 'Sans la tenue dans une zone de laboratoire, le joueur s\'intoxique ; seul l\'antidote guérit.' },
    { key = 'jb_toxic_gain', group = 'Drogues & labos', section = 'Intoxication des laboratoires', label = 'Vitesse d\'intoxication', type = 'number', default = 6, min = 1, max = 50, step = 1 },
    { key = 'jb_toxic_damage', group = 'Drogues & labos', section = 'Intoxication des laboratoires', label = 'Dégâts à partir du seuil (PV par tick)', type = 'number', default = 4, min = 0, max = 50, step = 1 },
    { key = 'jb_toxic_kill', group = 'Drogues & labos', section = 'Intoxication des laboratoires', label = 'Niveau mortel (0-100)', type = 'number', default = 100, min = 50, max = 100, step = 1 },
    { key = 'ib_pedsales', group = 'Drogues & labos', section = 'Vente de drogue aux PNJ', label = 'Vente de drogue aux PNJ (dealers)', type = 'bool', default = true, hint = 'Désactivé : tous les dealers à PNJ disparaissent et plus aucune vente n\'est possible.' },
}
