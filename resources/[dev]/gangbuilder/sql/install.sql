-- GangBuilder : tables propres au builder (créées automatiquement au démarrage si absentes).
-- Les gangs eux-mêmes sont écrits dans TES tables job2 : jobs2 / job2_grades (+ users.job2 / users.job2_grade pour les membres).
-- Aucune table existante (jobs, jobs2 hors lignes du builder, gangbuilder, fx_*, pgang_*, entreprise...) n'est modifiée.

CREATE TABLE IF NOT EXISTS `gangbuilder_gangs` (
  `name` varchar(50) NOT NULL,
  `label` varchar(100) NOT NULL,
  `type` varchar(30) NOT NULL DEFAULT 'custom',
  `color` varchar(7) NOT NULL DEFAULT '#ef4444',
  `boss_grade` int(11) NOT NULL DEFAULT 0,
  `money` bigint(20) NOT NULL DEFAULT 0,
  `dirty` bigint(20) NOT NULL DEFAULT 0,
  `rep` int(11) NOT NULL DEFAULT 0,
  `blip` longtext DEFAULT NULL,
  `settings` longtext DEFAULT NULL,
  `created_by` varchar(80) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `gangbuilder_points` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `gang_name` varchar(50) NOT NULL,
  `type` varchar(20) NOT NULL,
  `label` varchar(100) NOT NULL DEFAULT '',
  `coords` longtext NOT NULL,
  `min_grade` int(11) NOT NULL DEFAULT 0,
  `data` longtext DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_gangbuilder_points_gang` (`gang_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `gangbuilder_territories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `label` varchar(100) NOT NULL,
  `coords` longtext NOT NULL,
  `radius` float NOT NULL DEFAULT 40,
  `settings` longtext DEFAULT NULL,
  `owner` varchar(50) DEFAULT NULL,
  `captured_at` int(11) NOT NULL DEFAULT 0,
  `protected_until` int(11) NOT NULL DEFAULT 0,
  `last_income` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_gangbuilder_territories_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `gangbuilder_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `gang_name` varchar(50) NOT NULL,
  `identifier` varchar(80) DEFAULT NULL,
  `player_name` varchar(100) DEFAULT NULL,
  `action` varchar(40) NOT NULL,
  `detail` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_gangbuilder_logs_gang` (`gang_name`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `gangbuilder_stats` (
  `identifier` varchar(80) NOT NULL,
  `gang_name` varchar(50) NOT NULL,
  `harvested` int(11) NOT NULL DEFAULT 0,
  `processed` int(11) NOT NULL DEFAULT 0,
  `sold` bigint(20) NOT NULL DEFAULT 0,
  `laundered` bigint(20) NOT NULL DEFAULT 0,
  `contribution` bigint(20) NOT NULL DEFAULT 0,
  `last_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`identifier`, `gang_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Réglages modifiables en jeu (Paramètres du builder)
CREATE TABLE IF NOT EXISTS `gangbuilder_settings` (
  `name` varchar(40) NOT NULL,
  `value` longtext NOT NULL,
  `updated_by` varchar(100) DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
