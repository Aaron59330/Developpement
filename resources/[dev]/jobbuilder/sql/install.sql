-- JobBuilder : tables propres au builder (créées automatiquement au démarrage si absentes).
-- Les jobs eux-mêmes sont écrits dans TES tables ESX : jobs / job_grades (+ addon_account, addon_account_data, addon_inventory, datastore pour la société).

CREATE TABLE IF NOT EXISTS `jobbuilder_jobs` (
  `name` varchar(50) NOT NULL,
  `label` varchar(100) NOT NULL,
  `type` varchar(30) NOT NULL DEFAULT 'custom',
  `whitelisted` tinyint(1) NOT NULL DEFAULT 1,
  `society` tinyint(1) NOT NULL DEFAULT 1,
  `boss_grade` int(11) NOT NULL DEFAULT 0,
  `blip` longtext DEFAULT NULL,
  `settings` longtext DEFAULT NULL,
  `created_by` varchar(80) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `jobbuilder_points` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job_name` varchar(50) NOT NULL,
  `type` varchar(20) NOT NULL,
  `label` varchar(100) NOT NULL DEFAULT '',
  `coords` longtext NOT NULL,
  `min_grade` int(11) NOT NULL DEFAULT 0,
  `data` longtext DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_jobbuilder_points_job` (`job_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `jobbuilder_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job_name` varchar(50) NOT NULL,
  `identifier` varchar(80) DEFAULT NULL,
  `player_name` varchar(100) DEFAULT NULL,
  `action` varchar(40) NOT NULL,
  `detail` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_jobbuilder_logs_job` (`job_name`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ───────────── Immobilier (agences de type "realestate") ─────────────
-- Tables dédiées : n'utilisent PAS `properties` / `owned_properties` de ta base (autre système).
CREATE TABLE IF NOT EXISTS `jobbuilder_properties` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job_name` varchar(50) NOT NULL,
  `label` varchar(80) NOT NULL,
  `address` varchar(120) NOT NULL DEFAULT '',
  `deal` varchar(10) NOT NULL DEFAULT 'sale',
  `price` int(11) NOT NULL DEFAULT 0,
  `status` varchar(12) NOT NULL DEFAULT 'available',
  `owner` varchar(80) DEFAULT NULL,
  `owner_name` varchar(100) DEFAULT NULL,
  `rent_until` bigint(20) DEFAULT NULL,
  `key_holders` longtext DEFAULT NULL,
  `interior` varchar(40) NOT NULL DEFAULT 'custom',
  `entrance` longtext NOT NULL,
  `exit_coords` longtext DEFAULT NULL,
  `created_by` varchar(80) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `sold_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_jobbuilder_properties_job` (`job_name`),
  KEY `idx_jobbuilder_properties_owner` (`owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `jobbuilder_property_points` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `property_id` int(11) NOT NULL,
  `type` varchar(20) NOT NULL,
  `label` varchar(80) NOT NULL DEFAULT '',
  `coords` longtext NOT NULL,
  `data` longtext DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_jobbuilder_property_points_prop` (`property_id`),
  CONSTRAINT `fk_jobbuilder_property_points` FOREIGN KEY (`property_id`) REFERENCES `jobbuilder_properties` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `jobbuilder_property_outfits` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `property_id` int(11) NOT NULL,
  `identifier` varchar(80) NOT NULL,
  `label` varchar(60) NOT NULL,
  `clothes` longtext NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_jobbuilder_property_outfits` (`property_id`, `identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `jobbuilder_property_history` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `property_id` int(11) DEFAULT NULL,
  `job_name` varchar(50) NOT NULL,
  `action` varchar(30) NOT NULL,
  `actor` varchar(100) DEFAULT NULL,
  `detail` varchar(200) DEFAULT NULL,
  `amount` int(11) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_jobbuilder_property_history_job` (`job_name`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ───────────── Réglages modifiables en jeu (Paramètres du builder) ─────────────
CREATE TABLE IF NOT EXISTS `jobbuilder_settings` (
  `name` varchar(40) NOT NULL,
  `value` longtext NOT NULL,
  `updated_by` varchar(100) DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ───────────── Concession (jobs de type "dealer") ─────────────
CREATE TABLE IF NOT EXISTS `jobbuilder_dealer_vehicles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job_name` varchar(50) NOT NULL,
  `model` varchar(40) NOT NULL,
  `label` varchar(80) NOT NULL,
  `category` varchar(40) NOT NULL DEFAULT '',
  `vtype` varchar(20) NOT NULL DEFAULT 'car',
  `price` int(11) NOT NULL DEFAULT 0,
  `stock` int(11) NOT NULL DEFAULT -1,
  `min_grade` int(11) NOT NULL DEFAULT 0,
  `enabled` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `idx_jobbuilder_dealer_vehicles_job` (`job_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `jobbuilder_dealer_sales` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job_name` varchar(50) NOT NULL,
  `model` varchar(40) NOT NULL,
  `label` varchar(80) NOT NULL,
  `plate` varchar(12) NOT NULL,
  `buyer` varchar(80) NOT NULL,
  `buyer_name` varchar(100) DEFAULT NULL,
  `seller_name` varchar(100) DEFAULT NULL,
  `price` int(11) NOT NULL DEFAULT 0,
  `commission` int(11) NOT NULL DEFAULT 0,
  `tax` int(11) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_jobbuilder_dealer_sales_job` (`job_name`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ───────────── Gouvernement : journal du trésor public ─────────────
CREATE TABLE IF NOT EXISTS `jobbuilder_treasury_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `kind` varchar(20) NOT NULL,
  `source` varchar(60) DEFAULT NULL,
  `actor` varchar(100) DEFAULT NULL,
  `detail` varchar(200) DEFAULT NULL,
  `amount` int(11) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_jobbuilder_treasury_log_kind` (`kind`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ───────────── Missions PNJ : statistiques par joueur et par job ─────────────
CREATE TABLE IF NOT EXISTS `jobbuilder_mission_stats` (
  `identifier` varchar(80) NOT NULL,
  `job_name` varchar(50) NOT NULL,
  `done` int(11) NOT NULL DEFAULT 0,
  `earned` bigint(20) NOT NULL DEFAULT 0,
  `last_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`identifier`, `job_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ───────────── Tablette police : casiers judiciaires (isolés par job) ─────────────
CREATE TABLE IF NOT EXISTS `jobbuilder_records` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job_name` varchar(50) NOT NULL,
  `identifier` varchar(80) DEFAULT NULL,
  `firstname` varchar(50) NOT NULL,
  `lastname` varchar(50) NOT NULL,
  `birthdate` varchar(20) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `wanted` tinyint(1) NOT NULL DEFAULT 0,
  `wanted_reason` varchar(200) DEFAULT NULL,
  `created_by` varchar(80) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_jobbuilder_records_job` (`job_name`, `wanted`),
  KEY `idx_jobbuilder_records_ident` (`job_name`, `identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `jobbuilder_record_entries` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `record_id` int(11) NOT NULL,
  `job_name` varchar(50) NOT NULL,
  `kind` varchar(20) NOT NULL,
  `label` varchar(120) NOT NULL,
  `amount` int(11) NOT NULL DEFAULT 0,
  `details` text DEFAULT NULL,
  `officer` varchar(80) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_jobbuilder_record_entries_rec` (`record_id`, `id`),
  CONSTRAINT `fk_jobbuilder_record_entries_rec` FOREIGN KEY (`record_id`) REFERENCES `jobbuilder_records` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ───────────── Annonces d'entreprise : historique ─────────────
CREATE TABLE IF NOT EXISTS `jobbuilder_announces` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job_name` varchar(50) NOT NULL,
  `author` varchar(80) DEFAULT NULL,
  `kind` varchar(30) NOT NULL DEFAULT 'info',
  `title` varchar(80) NOT NULL,
  `text` varchar(500) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_jobbuilder_announces_job` (`job_name`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ───────────── Tablette médicale EMS : dossiers patients (isolés par job) ─────────────
CREATE TABLE IF NOT EXISTS `jobbuilder_patients` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job_name` varchar(50) NOT NULL,
  `identifier` varchar(80) DEFAULT NULL,
  `firstname` varchar(50) NOT NULL,
  `lastname` varchar(50) NOT NULL,
  `birthdate` varchar(20) DEFAULT NULL,
  `blood` varchar(4) DEFAULT NULL,
  `allergies` varchar(300) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_by` varchar(80) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_jobbuilder_patients_job` (`job_name`),
  KEY `idx_jobbuilder_patients_ident` (`job_name`, `identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `jobbuilder_patient_entries` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `patient_id` int(11) NOT NULL,
  `job_name` varchar(50) NOT NULL,
  `kind` varchar(20) NOT NULL,
  `label` varchar(120) NOT NULL,
  `amount` int(11) NOT NULL DEFAULT 0,
  `details` text DEFAULT NULL,
  `officer` varchar(80) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_jobbuilder_patient_entries_p` (`patient_id`, `id`),
  CONSTRAINT `fk_jobbuilder_patient_entries_p` FOREIGN KEY (`patient_id`) REFERENCES `jobbuilder_patients` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ───────────── Banque : fiches clients, prêts, historique (isolés par job) ─────────────
CREATE TABLE IF NOT EXISTS `jobbuilder_bank_clients` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job_name` varchar(50) NOT NULL,
  `identifier` varchar(80) DEFAULT NULL,
  `firstname` varchar(50) NOT NULL,
  `lastname` varchar(50) NOT NULL,
  `rating` varchar(1) NOT NULL DEFAULT 'C',
  `flag` varchar(10) NOT NULL DEFAULT 'normal',
  `notes` text DEFAULT NULL,
  `created_by` varchar(80) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_jobbuilder_bank_clients_job` (`job_name`),
  KEY `idx_jobbuilder_bank_clients_ident` (`job_name`, `identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `jobbuilder_bank_entries` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `client_id` int(11) NOT NULL,
  `job_name` varchar(50) NOT NULL,
  `kind` varchar(20) NOT NULL,
  `label` varchar(120) NOT NULL,
  `amount` int(11) NOT NULL DEFAULT 0,
  `officer` varchar(80) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_jobbuilder_bank_entries_c` (`client_id`, `id`),
  KEY `idx_jobbuilder_bank_entries_job` (`job_name`, `id`),
  CONSTRAINT `fk_jobbuilder_bank_entries_c` FOREIGN KEY (`client_id`) REFERENCES `jobbuilder_bank_clients` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `jobbuilder_bank_loans` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job_name` varchar(50) NOT NULL,
  `client_id` int(11) NOT NULL,
  `identifier` varchar(80) NOT NULL,
  `principal` int(11) NOT NULL,
  `rate` int(11) NOT NULL DEFAULT 0,
  `installment` int(11) NOT NULL,
  `installments` int(11) NOT NULL,
  `left_count` int(11) NOT NULL,
  `paid` int(11) NOT NULL DEFAULT 0,
  `penalties` int(11) NOT NULL DEFAULT 0,
  `late_count` int(11) NOT NULL DEFAULT 0,
  `status` varchar(10) NOT NULL DEFAULT 'active',
  `next_due` datetime NOT NULL,
  `officer` varchar(80) DEFAULT NULL,
  `note` varchar(200) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_jobbuilder_bank_loans_job` (`job_name`, `status`),
  KEY `idx_jobbuilder_bank_loans_ident` (`identifier`, `status`),
  CONSTRAINT `fk_jobbuilder_bank_loans_c` FOREIGN KEY (`client_id`) REFERENCES `jobbuilder_bank_clients` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
