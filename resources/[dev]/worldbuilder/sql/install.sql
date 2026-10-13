-- WorldBuilder : tables créées automatiquement au démarrage si absentes.

CREATE TABLE IF NOT EXISTS `worldbuilder_entities` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` varchar(20) NOT NULL,
  `name` varchar(50) NOT NULL,
  `label` varchar(100) NOT NULL,
  `enabled` tinyint(1) NOT NULL DEFAULT 1,
  `settings` longtext DEFAULT NULL,
  `points` longtext DEFAULT NULL,
  `stats` longtext DEFAULT NULL,
  `created_by` varchar(80) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_worldbuilder_name` (`name`),
  KEY `idx_worldbuilder_type` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `worldbuilder_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `entity_id` int(11) NOT NULL DEFAULT 0,
  `entity_label` varchar(100) DEFAULT NULL,
  `type` varchar(20) DEFAULT NULL,
  `identifier` varchar(80) DEFAULT NULL,
  `player_name` varchar(100) DEFAULT NULL,
  `action` varchar(40) NOT NULL,
  `detail` varchar(255) DEFAULT NULL,
  `amount` int(11) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_worldbuilder_logs_entity` (`entity_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `worldbuilder_settings` (
  `k` varchar(50) NOT NULL,
  `v` longtext DEFAULT NULL,
  PRIMARY KEY (`k`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Cooldowns persistants (braquages...)
CREATE TABLE IF NOT EXISTS `worldbuilder_state` (
  `k` varchar(80) NOT NULL,
  `v` bigint(20) NOT NULL DEFAULT 0,
  PRIMARY KEY (`k`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Véhicules mis en fourrière (par un métier) : raison, frais, date
CREATE TABLE IF NOT EXISTS `worldbuilder_impound` (
  `plate` varchar(12) NOT NULL,
  `impound_id` int(11) NOT NULL DEFAULT 0,
  `reason` varchar(200) DEFAULT NULL,
  `fee` int(11) NOT NULL DEFAULT 0,
  `officer` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Garages « liés » : le véhicule n'est disponible que dans le garage où il a été rangé
CREATE TABLE IF NOT EXISTS `worldbuilder_parking` (
  `plate` varchar(12) NOT NULL,
  `entity_id` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Permis obtenus via les auto-écoles (utilisé seul si esx_license est absent)
CREATE TABLE IF NOT EXISTS `worldbuilder_licenses` (
  `identifier` varchar(80) NOT NULL,
  `license` varchar(40) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`identifier`, `license`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Annonces de véhicules d'occasion (module Occasion)
CREATE TABLE IF NOT EXISTS `worldbuilder_listings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `entity_id` int(11) NOT NULL,
  `slot` int(11) NOT NULL,
  `seller` varchar(80) NOT NULL,
  `seller_name` varchar(100) DEFAULT NULL,
  `plate` varchar(12) NOT NULL,
  `props` longtext DEFAULT NULL,
  `price` int(11) NOT NULL DEFAULT 0,
  `description` varchar(300) DEFAULT NULL,
  `phone` varchar(30) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `expires_at` bigint(20) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_listing_plate` (`plate`),
  KEY `idx_listing_entity` (`entity_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Gains de ventes à verser aux vendeurs hors ligne
CREATE TABLE IF NOT EXISTS `worldbuilder_payouts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(80) NOT NULL,
  `amount` int(11) NOT NULL DEFAULT 0,
  `note` varchar(200) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_payout_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Classement du module Course poursuite
CREATE TABLE IF NOT EXISTS `worldbuilder_chase_stats` (
  `identifier` varchar(80) NOT NULL,
  `name` varchar(100) NOT NULL DEFAULT '',
  `matches` int(11) NOT NULL DEFAULT 0,
  `wins_runner` int(11) NOT NULL DEFAULT 0,
  `wins_chaser` int(11) NOT NULL DEFAULT 0,
  `losses` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Classement du module Zones PVP
CREATE TABLE IF NOT EXISTS `worldbuilder_pvp_stats` (
  `identifier` varchar(80) NOT NULL,
  `name` varchar(100) NOT NULL DEFAULT '',
  `kills` int(11) NOT NULL DEFAULT 0,
  `deaths` int(11) NOT NULL DEFAULT 0,
  `best_streak` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
