Settings = {}

-- Chaque réglage : key, group, label, type ('bool' | 'number' | 'select' | 'text' | 'list'), default, hint
--   number : min, max, step    select : options = { { 'valeur', 'Libellé' } }    list : une ligne par élément (max 20)
-- Un réglage ne change RIEN tant qu'il n'est pas modifié depuis le panel web (« Réglages ») : les valeurs d'origine des ressources restent en vigueur.
Settings.Schema = {
    -- ── Serveur ──────────────────────────────────────────────────────────────
    { key = 'maintenance_enabled', group = 'Serveur', label = 'Mode maintenance', type = 'bool', default = false, hint = 'Refuse les nouveaux joueurs (sauf staff / identifiants autorisés) et prévient ceux en ligne.' },
    { key = 'maintenance_message', group = 'Serveur', label = 'Message de maintenance', type = 'text', default = 'Le serveur est en maintenance, reviens dans quelques minutes.', hint = 'Affiché aux joueurs refusés.' },
    { key = 'maintenance_allow', group = 'Serveur', label = 'Identifiants autorisés pendant la maintenance', type = 'list', default = {}, hint = 'Un identifiant par ligne (license:… ou discord:…). Les administrateurs (ACE « command ») entrent toujours.' },
    { key = 'maintenance_kick', group = 'Serveur', label = 'Expulser les joueurs en ligne à l\'activation', type = 'bool', default = true, hint = 'Après 2 minutes de préavis (le staff n\'est jamais expulsé).' },
    { key = 'announce_enabled', group = 'Serveur', label = 'Annonces automatiques', type = 'bool', default = false, hint = 'Un message tourne à intervalle régulier (règles, Discord, boutique…).' },
    { key = 'announce_interval', group = 'Serveur', label = 'Intervalle des annonces (minutes)', type = 'number', default = 15, min = 1, max = 240, step = 1 },
    { key = 'announce_messages', group = 'Serveur', label = 'Messages des annonces', type = 'list', default = { 'Pense à lire le règlement du serveur.' }, hint = 'Un message par ligne : ils sont envoyés à tour de rôle.' },
    { key = 'restart_enabled', group = 'Serveur', label = 'Redémarrages programmés', type = 'bool', default = false, hint = 'Arrête le serveur aux heures indiquées (txAdmin ou ton hébergeur doit le relancer). N\'active pas ceci si txAdmin gère déjà tes redémarrages.' },
    { key = 'restart_times', group = 'Serveur', label = 'Heures de redémarrage', type = 'text', default = '05:00', hint = 'Format HH:MM séparées par des virgules, heure du serveur. Ex : 05:00,17:00. Annonces à −30, −10, −5 et −1 minute.' },

    -- ── Interface : notifications ───────────────────────────────────────────
    { key = 'notify_left', group = 'Interface', label = 'Notifications : distance au bord gauche (vw)', type = 'number', default = 1.35, min = 0, max = 80, step = 0.05 },
    { key = 'notify_bottom', group = 'Interface', label = 'Notifications : distance au bas (vh)', type = 'number', default = 22.5, min = 0, max = 90, step = 0.5 },

    -- ── Interface : boussole ────────────────────────────────────────────────
    { key = 'compass_layout', group = 'Interface', label = 'Boussole : format', type = 'select', default = 'compact', options = { { 'compact', 'Compacte (en bas à gauche)' }, { 'top', 'Grande bande en haut' } } },
    { key = 'compass_street', group = 'Interface', label = 'Boussole : afficher le nom de la rue', type = 'bool', default = true },
    { key = 'compass_left', group = 'Interface', label = 'Boussole compacte : position gauche (vw)', type = 'number', default = 19.6, min = 0, max = 90, step = 0.1 },
    { key = 'compass_bottom', group = 'Interface', label = 'Boussole compacte : position bas (vh)', type = 'number', default = 3.4, min = 0, max = 90, step = 0.1 },

    -- ── Interface : HUD ─────────────────────────────────────────────────────
    -- ── Carnet du joueur ────────────────────────────────────────────────────
    { key = 'carnet_enabled', group = 'Carnet', label = 'Carnet du joueur activé', type = 'bool', default = true, hint = 'Série de connexion, objectifs du jour et de la semaine, défi de la ville (touche F3). Les récompenses sont versées automatiquement.' },
    { key = 'carnet_reward_mult', group = 'Carnet', label = 'Multiplicateur des récompenses', type = 'number', default = 1.0, min = 0, max = 10, step = 0.1, hint = 'S\'applique à toutes les récompenses du carnet (série, objectifs, défi de la ville), en plus du type d\'économie du serveur.' },
    { key = 'hud_needs', group = 'Interface', label = 'HUD : afficher faim et soif', type = 'bool', default = true },
    { key = 'hud_health', group = 'Interface', label = 'HUD : afficher la barre de vie', type = 'bool', default = true },
    { key = 'hud_armor', group = 'Interface', label = 'HUD : afficher la ligne d\'armure', type = 'bool', default = true },
    { key = 'hud2_server', group = 'Interface', label = 'Cartes en haut à droite : serveur (nom, Discord, joueurs)', type = 'bool', default = true, hint = 'Si tu désactives une carte ici, aucun joueur ne peut la réactiver.' },
    { key = 'hud2_job', group = 'Interface', label = 'Cartes en haut à droite : métier', type = 'bool', default = true },
    { key = 'hud2_money', group = 'Interface', label = 'Cartes en haut à droite : argent', type = 'bool', default = true },

    -- ── Voix ────────────────────────────────────────────────────────────────
    { key = 'voice_whisper', group = 'Voix', label = 'Distance « chuchoter » (m)', type = 'number', default = 3, min = 0.5, max = 50, step = 0.5, hint = 'Appliquée à tous les joueurs, sans redémarrage.' },
    { key = 'voice_normal', group = 'Voix', label = 'Distance « normal » (m)', type = 'number', default = 7, min = 1, max = 80, step = 0.5 },
    { key = 'voice_shout', group = 'Voix', label = 'Distance « crier » (m)', type = 'number', default = 15, min = 2, max = 150, step = 0.5 },

    -- ── Performance ─────────────────────────────────────────────────────────
    { key = 'perf_mode', group = 'Performance', label = 'Mode performance des interfaces', type = 'select', default = 'auto', options = { { 'auto', 'Automatique (activé seulement si les FPS du joueur sont bas)' }, { 'on', 'Toujours activé (tous les joueurs)' }, { 'off', 'Désactivé' } }, hint = 'Supprime les ombres, lueurs, flous et animations en boucle des interfaces (HUD, menus, builders) : gain de FPS sur les PC faibles. Aucun effet sur les bons PC en mode automatique.' },
    { key = 'perf_threshold', group = 'Performance', label = 'Seuil « FPS bas » du mode automatique', type = 'number', default = 40, min = 20, max = 60, step = 1, hint = 'Sous ce nombre d\'images par seconde pendant quelques secondes, le mode performance s\'active ; il se désactive quand les FPS remontent nettement.' },

    -- ── Économie ────────────────────────────────────────────────────────────
    { key = 'eco_weekend_income', group = 'Économie', label = 'Bonus de gains le week-end (×)', type = 'number', default = 1, min = 1, max = 3, step = 0.05, hint = '1 = aucun bonus. 1.5 = +50 % de gains le samedi et le dimanche (en plus du type d\'économie).' },
}
