-- ============================================================================
--  CORRECTIFS PROPOSÉS pour la base EXISTANTE (à lire avant d'exécuter !)
--  Pour repartir de zéro, utilise plutôt :
--    * sql_clean_install.sql  -> nouvelle base vide, déjà corrigée (structure + catalogues)
--    * sql_reset_data.sql     -> vide la base actuelle (joueurs, jobs, logs...)
--  1) FAIS UNE SAUVEGARDE COMPLÈTE de la base avant toute commande.
--  2) Exécute les blocs un par un, pas tout d'un coup.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- A. Tables anciennes en MyISAM + latin1 (accents abîmés, pas de transactions,
--    collations incompatibles avec les tables utf8mb4 -> "Illegal mix of collations")
--    Conversion en InnoDB + utf8mb4_unicode_ci.
-- ---------------------------------------------------------------------------
ALTER TABLE `account_info`        ENGINE=InnoDB, CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `addon_account`       ENGINE=InnoDB, CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `addon_inventory`     ENGINE=InnoDB, CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `banlist`             ENGINE=InnoDB, CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `banlisthistory`      ENGINE=InnoDB, CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `billing`             ENGINE=InnoDB, CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `boitegant`           ENGINE=InnoDB, CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `clothes_player`      ENGINE=InnoDB, CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `coffre_armeperm`     ENGINE=InnoDB, CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `coffre_veh`          ENGINE=InnoDB, CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `datastore`           ENGINE=InnoDB, CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `datastore_data`      ENGINE=InnoDB, CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `dpkeybinds`          ENGINE=InnoDB, CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `items`               ENGINE=InnoDB, CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `jail`                ENGINE=InnoDB, CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `jobs`                ENGINE=InnoDB, CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `job_grades`          ENGINE=InnoDB, CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `leboncoin`           ENGINE=InnoDB, CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `licenses`            ENGINE=InnoDB, CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `lotery`              ENGINE=InnoDB, CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `open_car`            ENGINE=InnoDB, CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `owned_properties`    ENGINE=InnoDB;
ALTER TABLE `owned_vehicles`      ENGINE=InnoDB, CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `playerstattoos`      ENGINE=InnoDB, CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `races`               ENGINE=InnoDB, CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `society`             ENGINE=InnoDB, CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `societymoney`        ENGINE=InnoDB, CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `user_licenses`       ENGINE=InnoDB, CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `vehicles`            ENGINE=InnoDB, CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `vehicle_categories`  ENGINE=InnoDB, CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `vehicle_sold`        ENGINE=InnoDB, CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `vips`                ENGINE=InnoDB, CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- B. Tables sans clé primaire
-- ---------------------------------------------------------------------------
-- dpkeybinds : un seul enregistrement de raccourcis par joueur
ALTER TABLE `dpkeybinds` MODIFY `id` varchar(50) NOT NULL, ADD PRIMARY KEY (`id`);
-- jail : un seul emprisonnement par joueur
ALTER TABLE `jail` ADD PRIMARY KEY (`identifier`);

-- ---------------------------------------------------------------------------
-- C. Jobs en doublon / résiduels (à vérifier avant : sont-ils encore utilisés ?)
--    'ambulance' (vs pillboxhopital), 'LsCustoms' (vs bennys) n'ont aucun compte
--    society_*, et 'unemployed2' ne devrait exister que dans jobs2.
-- ---------------------------------------------------------------------------
-- DELETE FROM `job_grades` WHERE `job_name` IN ('ambulance', 'LsCustoms');
-- DELETE FROM `jobs`       WHERE `name`     IN ('ambulance', 'LsCustoms');

-- ---------------------------------------------------------------------------
-- D. Dates de naissance : format mélangé (30/07/2000 et 09/26/2000).
--    Choisis UN format (JJ/MM/AAAA recommandé) ; la fiche à corriger à la main :
-- ---------------------------------------------------------------------------
-- SELECT identifier, firstname, lastname, dateofbirth FROM users WHERE dateofbirth REGEXP '^[0-9]{2}/(1[3-9]|2[0-9]|3[01])/';

-- E. Table manquante utilisée par CorePickax/esx/society (blanchiment)
CREATE TABLE IF NOT EXISTS `society_moneywash` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(60) NOT NULL,
  `society` varchar(60) NOT NULL,
  `amount` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
