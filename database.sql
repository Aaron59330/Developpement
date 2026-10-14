-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: (masqué)
-- Installation propre : structure + données de référence uniquement
-- Server version: 12.2.2-MariaDB
-- PHP Version: 8.2.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `s85796_pickax`
--

-- --------------------------------------------------------

--
-- Table structure for table `account_info`
--

CREATE TABLE `account_info` (
  `account_id` int(11) NOT NULL,
  `license` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `steam` varchar(22) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `xbl` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `discord` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `live` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `fivem` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `ip` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `guid` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `first_connection` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `addon_account`
--

CREATE TABLE `addon_account` (
  `name` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `label` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `shared` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `addon_account_data`
--

CREATE TABLE `addon_account_data` (
  `id` int(11) NOT NULL,
  `account_name` varchar(100) DEFAULT NULL,
  `money` int(11) NOT NULL,
  `owner` varchar(55) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `addon_inventory`
--

CREATE TABLE `addon_inventory` (
  `name` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `label` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `shared` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `addon_inventory_items`
--

CREATE TABLE `addon_inventory_items` (
  `id` int(11) NOT NULL,
  `inventory_name` varchar(100) NOT NULL,
  `name` varchar(100) NOT NULL,
  `count` int(11) NOT NULL,
  `owner` varchar(55) DEFAULT NULL,
  `type` varchar(50) DEFAULT 'item_standard',
  `type_clothes` varchar(50) DEFAULT NULL,
  `clothes_name` varchar(50) DEFAULT NULL,
  `ammo` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `banlist`
--

CREATE TABLE `banlist` (
  `licenseid` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `playerip` varchar(25) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `targetName` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `sourceName` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `reason` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `timeat` int(11) NOT NULL,
  `expiration` int(11) NOT NULL,
  `permanent` int(11) NOT NULL DEFAULT 0,
  `banid` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `banlisthistory`
--

CREATE TABLE `banlisthistory` (
  `id` int(11) NOT NULL,
  `licenseid` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `playerip` varchar(25) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `targetName` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `sourceName` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `reason` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `timeat` int(11) NOT NULL,
  `expiration` int(11) NOT NULL,
  `permanent` int(11) NOT NULL DEFAULT 0,
  `banid` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `billing`
--

CREATE TABLE `billing` (
  `id` int(11) NOT NULL,
  `identifier` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `sender` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `target_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `target` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `label` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `amount` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `boitegant`
--

CREATE TABLE `boitegant` (
  `id` int(11) NOT NULL,
  `plate` varchar(50) NOT NULL,
  `data` longtext DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `clothes_player`
--

CREATE TABLE `clothes_player` (
  `id` int(11) NOT NULL,
  `label` varchar(50) DEFAULT NULL,
  `skin` longtext DEFAULT NULL,
  `identifier` varchar(50) DEFAULT NULL,
  `type` varchar(50) DEFAULT NULL,
  `equip` varchar(50) DEFAULT 'n'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `coffre_armeperm`
--

CREATE TABLE `coffre_armeperm` (
  `id` int(11) NOT NULL,
  `armes` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `munitions` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `identifier` varchar(55) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `label` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `coffre_veh`
--

CREATE TABLE `coffre_veh` (
  `info` longtext DEFAULT NULL,
  `data` longtext DEFAULT NULL,
  `id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `datastore`
--

CREATE TABLE `datastore` (
  `name` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `label` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `shared` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `datastore_data`
--

CREATE TABLE `datastore_data` (
  `id` int(11) NOT NULL,
  `name` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `owner` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `dpkeybinds`
--

CREATE TABLE `dpkeybinds` (
  `id` varchar(50) DEFAULT NULL,
  `keybind1` varchar(50) DEFAULT 'num4',
  `emote1` varchar(255) DEFAULT '',
  `keybind2` varchar(50) DEFAULT 'num5',
  `emote2` varchar(255) DEFAULT '',
  `keybind3` varchar(50) DEFAULT 'num6',
  `emote3` varchar(255) DEFAULT '',
  `keybind4` varchar(50) DEFAULT 'num7',
  `emote4` varchar(255) DEFAULT '',
  `keybind5` varchar(50) DEFAULT 'num8',
  `emote5` varchar(255) DEFAULT '',
  `keybind6` varchar(50) DEFAULT 'num9',
  `emote6` varchar(255) DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `gangbuilder_gangs`
--

CREATE TABLE `gangbuilder_gangs` (
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
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `gangbuilder_logs`
--

CREATE TABLE `gangbuilder_logs` (
  `id` int(11) NOT NULL,
  `gang_name` varchar(50) NOT NULL,
  `identifier` varchar(80) DEFAULT NULL,
  `player_name` varchar(100) DEFAULT NULL,
  `action` varchar(40) NOT NULL,
  `detail` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `gangbuilder_points`
--

CREATE TABLE `gangbuilder_points` (
  `id` int(11) NOT NULL,
  `gang_name` varchar(50) NOT NULL,
  `type` varchar(20) NOT NULL,
  `label` varchar(100) NOT NULL DEFAULT '',
  `coords` longtext NOT NULL,
  `min_grade` int(11) NOT NULL DEFAULT 0,
  `data` longtext DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `gangbuilder_settings`
--

CREATE TABLE `gangbuilder_settings` (
  `name` varchar(40) NOT NULL,
  `value` longtext NOT NULL,
  `updated_by` varchar(100) DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `gangbuilder_stats`
--

CREATE TABLE `gangbuilder_stats` (
  `identifier` varchar(80) NOT NULL,
  `gang_name` varchar(50) NOT NULL,
  `harvested` int(11) NOT NULL DEFAULT 0,
  `processed` int(11) NOT NULL DEFAULT 0,
  `sold` bigint(20) NOT NULL DEFAULT 0,
  `laundered` bigint(20) NOT NULL DEFAULT 0,
  `contribution` bigint(20) NOT NULL DEFAULT 0,
  `last_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `gangbuilder_territories`
--

CREATE TABLE `gangbuilder_territories` (
  `id` int(11) NOT NULL,
  `name` varchar(50) NOT NULL,
  `label` varchar(100) NOT NULL,
  `coords` longtext NOT NULL,
  `radius` float NOT NULL DEFAULT 40,
  `settings` longtext DEFAULT NULL,
  `owner` varchar(50) DEFAULT NULL,
  `captured_at` int(11) NOT NULL DEFAULT 0,
  `protected_until` int(11) NOT NULL DEFAULT 0,
  `last_income` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `items`
--

CREATE TABLE `items` (
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `label` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `weight` float NOT NULL DEFAULT 1,
  `rare` tinyint(1) NOT NULL DEFAULT 0,
  `can_remove` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `jail`
--

CREATE TABLE `jail` (
  `source` varchar(50) NOT NULL,
  `temps` int(11) NOT NULL,
  `reason` varchar(50) NOT NULL,
  `identifier` varchar(50) NOT NULL,
  `identifiersource` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `job2_grades`
--

CREATE TABLE `job2_grades` (
  `id` int(11) NOT NULL,
  `job_name` varchar(50) DEFAULT NULL,
  `grade` int(11) NOT NULL,
  `name` varchar(50) NOT NULL,
  `label` varchar(50) NOT NULL,
  `salary` int(11) NOT NULL,
  `skin_male` longtext NOT NULL,
  `skin_female` longtext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `jobbuilder_announces`
--

CREATE TABLE `jobbuilder_announces` (
  `id` int(11) NOT NULL,
  `job_name` varchar(50) NOT NULL,
  `author` varchar(80) DEFAULT NULL,
  `kind` varchar(30) NOT NULL DEFAULT 'info',
  `title` varchar(80) NOT NULL,
  `text` varchar(500) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `jobbuilder_bank_clients`
--

CREATE TABLE `jobbuilder_bank_clients` (
  `id` int(11) NOT NULL,
  `job_name` varchar(50) NOT NULL,
  `identifier` varchar(80) DEFAULT NULL,
  `firstname` varchar(50) NOT NULL,
  `lastname` varchar(50) NOT NULL,
  `rating` varchar(1) NOT NULL DEFAULT 'C',
  `flag` varchar(10) NOT NULL DEFAULT 'normal',
  `notes` text DEFAULT NULL,
  `created_by` varchar(80) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `jobbuilder_bank_entries`
--

CREATE TABLE `jobbuilder_bank_entries` (
  `id` int(11) NOT NULL,
  `client_id` int(11) NOT NULL,
  `job_name` varchar(50) NOT NULL,
  `kind` varchar(20) NOT NULL,
  `label` varchar(120) NOT NULL,
  `amount` int(11) NOT NULL DEFAULT 0,
  `officer` varchar(80) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `jobbuilder_bank_loans`
--

CREATE TABLE `jobbuilder_bank_loans` (
  `id` int(11) NOT NULL,
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
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `jobbuilder_dealer_sales`
--

CREATE TABLE `jobbuilder_dealer_sales` (
  `id` int(11) NOT NULL,
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
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `jobbuilder_dealer_vehicles`
--

CREATE TABLE `jobbuilder_dealer_vehicles` (
  `id` int(11) NOT NULL,
  `job_name` varchar(50) NOT NULL,
  `model` varchar(40) NOT NULL,
  `label` varchar(80) NOT NULL,
  `category` varchar(40) NOT NULL DEFAULT '',
  `vtype` varchar(20) NOT NULL DEFAULT 'car',
  `price` int(11) NOT NULL DEFAULT 0,
  `stock` int(11) NOT NULL DEFAULT -1,
  `min_grade` int(11) NOT NULL DEFAULT 0,
  `enabled` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `jobbuilder_jobs`
--

CREATE TABLE `jobbuilder_jobs` (
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
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `jobbuilder_logs`
--

CREATE TABLE `jobbuilder_logs` (
  `id` int(11) NOT NULL,
  `job_name` varchar(50) NOT NULL,
  `identifier` varchar(80) DEFAULT NULL,
  `player_name` varchar(100) DEFAULT NULL,
  `action` varchar(40) NOT NULL,
  `detail` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `jobbuilder_mission_stats`
--

CREATE TABLE `jobbuilder_mission_stats` (
  `identifier` varchar(80) NOT NULL,
  `job_name` varchar(50) NOT NULL,
  `done` int(11) NOT NULL DEFAULT 0,
  `earned` bigint(20) NOT NULL DEFAULT 0,
  `last_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `jobbuilder_patients`
--

CREATE TABLE `jobbuilder_patients` (
  `id` int(11) NOT NULL,
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
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `jobbuilder_patient_entries`
--

CREATE TABLE `jobbuilder_patient_entries` (
  `id` int(11) NOT NULL,
  `patient_id` int(11) NOT NULL,
  `job_name` varchar(50) NOT NULL,
  `kind` varchar(20) NOT NULL,
  `label` varchar(120) NOT NULL,
  `amount` int(11) NOT NULL DEFAULT 0,
  `details` text DEFAULT NULL,
  `officer` varchar(80) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `jobbuilder_points`
--

CREATE TABLE `jobbuilder_points` (
  `id` int(11) NOT NULL,
  `job_name` varchar(50) NOT NULL,
  `type` varchar(20) NOT NULL,
  `label` varchar(100) NOT NULL DEFAULT '',
  `coords` longtext NOT NULL,
  `min_grade` int(11) NOT NULL DEFAULT 0,
  `data` longtext DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `jobbuilder_properties`
--

CREATE TABLE `jobbuilder_properties` (
  `id` int(11) NOT NULL,
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
  `sold_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `jobbuilder_property_history`
--

CREATE TABLE `jobbuilder_property_history` (
  `id` int(11) NOT NULL,
  `property_id` int(11) DEFAULT NULL,
  `job_name` varchar(50) NOT NULL,
  `action` varchar(30) NOT NULL,
  `actor` varchar(100) DEFAULT NULL,
  `detail` varchar(200) DEFAULT NULL,
  `amount` int(11) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `jobbuilder_property_outfits`
--

CREATE TABLE `jobbuilder_property_outfits` (
  `id` int(11) NOT NULL,
  `property_id` int(11) NOT NULL,
  `identifier` varchar(80) NOT NULL,
  `label` varchar(60) NOT NULL,
  `clothes` longtext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `jobbuilder_property_points`
--

CREATE TABLE `jobbuilder_property_points` (
  `id` int(11) NOT NULL,
  `property_id` int(11) NOT NULL,
  `type` varchar(20) NOT NULL,
  `label` varchar(80) NOT NULL DEFAULT '',
  `coords` longtext NOT NULL,
  `data` longtext DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `jobbuilder_records`
--

CREATE TABLE `jobbuilder_records` (
  `id` int(11) NOT NULL,
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
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `jobbuilder_record_entries`
--

CREATE TABLE `jobbuilder_record_entries` (
  `id` int(11) NOT NULL,
  `record_id` int(11) NOT NULL,
  `job_name` varchar(50) NOT NULL,
  `kind` varchar(20) NOT NULL,
  `label` varchar(120) NOT NULL,
  `amount` int(11) NOT NULL DEFAULT 0,
  `details` text DEFAULT NULL,
  `officer` varchar(80) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `jobbuilder_settings`
--

CREATE TABLE `jobbuilder_settings` (
  `name` varchar(40) NOT NULL,
  `value` longtext NOT NULL,
  `updated_by` varchar(100) DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `jobbuilder_treasury_log`
--

CREATE TABLE `jobbuilder_treasury_log` (
  `id` int(11) NOT NULL,
  `kind` varchar(20) NOT NULL,
  `source` varchar(60) DEFAULT NULL,
  `actor` varchar(100) DEFAULT NULL,
  `detail` varchar(200) DEFAULT NULL,
  `amount` int(11) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `jobs`
--

CREATE TABLE `jobs` (
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `label` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `whitelisted` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `jobs2`
--

CREATE TABLE `jobs2` (
  `name` varchar(50) NOT NULL,
  `label` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `job_grades`
--

CREATE TABLE `job_grades` (
  `id` int(11) NOT NULL,
  `job_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `grade` int(11) NOT NULL,
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `label` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `salary` int(11) NOT NULL,
  `skin_male` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `skin_female` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `leboncoin`
--

CREATE TABLE `leboncoin` (
  `id` int(11) NOT NULL,
  `owner` varchar(50) DEFAULT NULL,
  `plate` varchar(12) DEFAULT NULL,
  `vehicle` longtext DEFAULT NULL,
  `price` longtext DEFAULT NULL,
  `location` varchar(255) DEFAULT NULL,
  `locationId` int(11) DEFAULT NULL,
  `buyed` tinyint(4) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `licenses`
--

CREATE TABLE `licenses` (
  `type` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `label` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `lotery`
--

CREATE TABLE `lotery` (
  `id` int(11) NOT NULL,
  `identifier` varchar(255) DEFAULT NULL,
  `code` varchar(255) DEFAULT NULL,
  `win` int(11) DEFAULT 0,
  `gain` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `newplayer_playtime`
--

CREATE TABLE `newplayer_playtime` (
  `identifier` varchar(80) NOT NULL,
  `played_seconds` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `open_car`
--

CREATE TABLE `open_car` (
  `id` int(11) NOT NULL,
  `identifier` varchar(50) DEFAULT NULL,
  `label` varchar(255) DEFAULT NULL,
  `value` varchar(50) DEFAULT NULL,
  `got` varchar(50) DEFAULT NULL,
  `NB` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `owned_properties`
--

CREATE TABLE `owned_properties` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `price` double NOT NULL,
  `rented` int(11) NOT NULL,
  `owner` varchar(60) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `owned_vehicles`
--

CREATE TABLE `owned_vehicles` (
  `owner` varchar(50) NOT NULL,
  `state` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'etat du véhicule',
  `plate` varchar(12) NOT NULL,
  `name` varchar(30) DEFAULT NULL,
  `vehicle` longtext DEFAULT NULL,
  `type` varchar(20) NOT NULL DEFAULT 'car',
  `glovebox` longtext DEFAULT NULL,
  `trunk` longtext DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `ox_inventory`
--

CREATE TABLE `ox_inventory` (
  `owner` varchar(60) DEFAULT NULL,
  `name` varchar(100) NOT NULL,
  `data` longtext DEFAULT NULL,
  `lastupdated` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `ox_inventory_clothing`
--

CREATE TABLE `ox_inventory_clothing` (
  `owner` varchar(100) NOT NULL,
  `slots` longtext DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ox_inventory_lockers`
--

CREATE TABLE `ox_inventory_lockers` (
  `id` int(11) NOT NULL,
  `coords_x` float NOT NULL,
  `coords_y` float NOT NULL,
  `coords_z` float NOT NULL,
  `label` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ox_inventory_locker_casiers`
--

CREATE TABLE `ox_inventory_locker_casiers` (
  `id` int(11) NOT NULL,
  `locker_id` int(11) NOT NULL,
  `casier_number` int(11) NOT NULL,
  `label` varchar(255) DEFAULT NULL,
  `pin_code` varchar(4) DEFAULT NULL,
  `note` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ox_inventory_medical`
--

CREATE TABLE `ox_inventory_medical` (
  `owner` varchar(100) NOT NULL,
  `data` longtext DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ox_inventory_outfits`
--

CREATE TABLE `ox_inventory_outfits` (
  `owner` varchar(100) NOT NULL,
  `outfits` longtext DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ox_inventory_outfit_catalog`
--

CREATE TABLE `ox_inventory_outfit_catalog` (
  `clothe_id` int(11) NOT NULL,
  `name` varchar(64) NOT NULL,
  `data` longtext DEFAULT NULL,
  `price` int(11) NOT NULL DEFAULT 100,
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ox_inventory_placed_items`
--

CREATE TABLE `ox_inventory_placed_items` (
  `id` int(11) NOT NULL,
  `owner` varchar(60) NOT NULL,
  `item_name` varchar(100) NOT NULL,
  `prop_model` varchar(100) NOT NULL,
  `coords_x` float NOT NULL,
  `coords_y` float NOT NULL,
  `coords_z` float NOT NULL,
  `heading` float NOT NULL,
  `slot` int(11) NOT NULL,
  `metadata` longtext DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `pgang_objectives`
--

CREATE TABLE `pgang_objectives` (
  `gang` varchar(50) NOT NULL,
  `day` int(11) NOT NULL,
  `id` varchar(32) NOT NULL,
  `progress` int(11) NOT NULL DEFAULT 0,
  `claimed` tinyint(4) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `pgang_relations`
--

CREATE TABLE `pgang_relations` (
  `gang_a` varchar(50) NOT NULL,
  `gang_b` varchar(50) NOT NULL,
  `status` varchar(10) NOT NULL DEFAULT 'pending',
  `requested_by` varchar(50) NOT NULL,
  `since` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_backups`
--

CREATE TABLE `phone_backups` (
  `id` varchar(100) NOT NULL,
  `phone_number` varchar(15) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `phone_clock_alarms`
--

CREATE TABLE `phone_clock_alarms` (
  `id` int(10) UNSIGNED NOT NULL,
  `phone_number` varchar(15) NOT NULL,
  `hours` int(2) NOT NULL DEFAULT 0,
  `minutes` int(2) NOT NULL DEFAULT 0,
  `label` varchar(50) DEFAULT NULL,
  `enabled` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_crypto`
--

CREATE TABLE `phone_crypto` (
  `id` varchar(100) NOT NULL,
  `coin` varchar(15) NOT NULL,
  `amount` double UNSIGNED NOT NULL DEFAULT 0,
  `invested` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_crypto_coins`
--

CREATE TABLE `phone_crypto_coins` (
  `coin` varchar(15) NOT NULL,
  `coin_value` double UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `phone_darkchat_accounts`
--

CREATE TABLE `phone_darkchat_accounts` (
  `phone_number` varchar(15) NOT NULL,
  `username` varchar(20) NOT NULL,
  `password` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `phone_darkchat_channels`
--

CREATE TABLE `phone_darkchat_channels` (
  `name` varchar(50) NOT NULL,
  `password` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `phone_darkchat_members`
--

CREATE TABLE `phone_darkchat_members` (
  `channel_name` varchar(50) NOT NULL,
  `username` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `phone_darkchat_messages`
--

CREATE TABLE `phone_darkchat_messages` (
  `id` int(11) NOT NULL,
  `channel` varchar(50) NOT NULL,
  `sender` varchar(20) NOT NULL,
  `content` varchar(1000) DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `phone_instagram_accounts`
--

CREATE TABLE `phone_instagram_accounts` (
  `display_name` varchar(30) NOT NULL,
  `username` varchar(20) NOT NULL,
  `password` varchar(100) NOT NULL,
  `profile_image` varchar(500) DEFAULT NULL,
  `bio` varchar(100) DEFAULT NULL,
  `post_count` int(11) NOT NULL DEFAULT 0,
  `story_count` int(11) NOT NULL DEFAULT 0,
  `follower_count` int(11) NOT NULL DEFAULT 0,
  `following_count` int(11) NOT NULL DEFAULT 0,
  `phone_number` varchar(15) NOT NULL,
  `private` tinyint(1) DEFAULT 0,
  `verified` tinyint(1) DEFAULT 0,
  `date_joined` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_instagram_comments`
--

CREATE TABLE `phone_instagram_comments` (
  `id` varchar(10) NOT NULL,
  `post_id` varchar(50) NOT NULL,
  `username` varchar(20) NOT NULL,
  `comment` varchar(500) NOT NULL DEFAULT '',
  `like_count` int(11) NOT NULL DEFAULT 0,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Triggers `phone_instagram_comments`
--
DELIMITER $$
CREATE TRIGGER `phone_instagram_decrement_comment_count` AFTER DELETE ON `phone_instagram_comments` FOR EACH ROW BEGIN
    UPDATE phone_instagram_posts
    SET comment_count = comment_count - 1
    WHERE id = OLD.post_id;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `phone_instagram_increment_comment_count` AFTER INSERT ON `phone_instagram_comments` FOR EACH ROW BEGIN
    UPDATE phone_instagram_posts
    SET comment_count = comment_count + 1
    WHERE id = NEW.post_id;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `phone_instagram_follows`
--

CREATE TABLE `phone_instagram_follows` (
  `followed` varchar(20) NOT NULL,
  `follower` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Triggers `phone_instagram_follows`
--
DELIMITER $$
CREATE TRIGGER `phone_instagram_update_counts_after_follow` AFTER INSERT ON `phone_instagram_follows` FOR EACH ROW BEGIN
    UPDATE phone_instagram_accounts
    SET follower_count = follower_count + 1
    WHERE username = NEW.followed;

    UPDATE phone_instagram_accounts
    SET following_count = following_count + 1
    WHERE username = NEW.follower;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `phone_instagram_update_counts_after_unfollow` AFTER DELETE ON `phone_instagram_follows` FOR EACH ROW BEGIN
    UPDATE phone_instagram_accounts
    SET follower_count = follower_count - 1
    WHERE username = OLD.followed;

    UPDATE phone_instagram_accounts
    SET following_count = following_count - 1
    WHERE username = OLD.follower;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `phone_instagram_follow_requests`
--

CREATE TABLE `phone_instagram_follow_requests` (
  `requester` varchar(20) NOT NULL,
  `requestee` varchar(20) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_instagram_likes`
--

CREATE TABLE `phone_instagram_likes` (
  `id` varchar(10) NOT NULL,
  `username` varchar(20) NOT NULL,
  `is_comment` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Triggers `phone_instagram_likes`
--
DELIMITER $$
CREATE TRIGGER `phone_instagram_decrement_like_count` AFTER DELETE ON `phone_instagram_likes` FOR EACH ROW BEGIN
    IF OLD.is_comment = 0 THEN
        UPDATE phone_instagram_posts
        SET like_count = like_count - 1
        WHERE id = OLD.id;
    ELSE
        UPDATE phone_instagram_comments
        SET like_count = like_count - 1
        WHERE id = OLD.id;
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `phone_instagram_increment_like_count` AFTER INSERT ON `phone_instagram_likes` FOR EACH ROW BEGIN
    IF NEW.is_comment = 0 THEN
        UPDATE phone_instagram_posts
        SET like_count = like_count + 1
        WHERE id = NEW.id;
    ELSE
        UPDATE phone_instagram_comments
        SET like_count = like_count + 1
        WHERE id = NEW.id;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `phone_instagram_messages`
--

CREATE TABLE `phone_instagram_messages` (
  `id` varchar(10) NOT NULL,
  `sender` varchar(20) NOT NULL,
  `recipient` varchar(20) NOT NULL,
  `content` varchar(1000) DEFAULT NULL,
  `attachments` text DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_instagram_notifications`
--

CREATE TABLE `phone_instagram_notifications` (
  `id` varchar(10) NOT NULL,
  `username` varchar(20) NOT NULL,
  `from` varchar(20) NOT NULL,
  `type` varchar(20) NOT NULL,
  `post_id` varchar(50) DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_instagram_posts`
--

CREATE TABLE `phone_instagram_posts` (
  `id` varchar(10) NOT NULL,
  `media` text DEFAULT NULL,
  `caption` varchar(500) NOT NULL DEFAULT '',
  `location` varchar(50) DEFAULT NULL,
  `like_count` int(11) NOT NULL DEFAULT 0,
  `comment_count` int(11) NOT NULL DEFAULT 0,
  `username` varchar(20) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Triggers `phone_instagram_posts`
--
DELIMITER $$
CREATE TRIGGER `phone_instagram_decrement_post_count` AFTER DELETE ON `phone_instagram_posts` FOR EACH ROW BEGIN
    UPDATE phone_instagram_accounts
    SET post_count = post_count - 1
    WHERE username = OLD.username;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `phone_instagram_increment_post_count` AFTER INSERT ON `phone_instagram_posts` FOR EACH ROW BEGIN
    UPDATE phone_instagram_accounts
    SET post_count = post_count + 1
    WHERE username = NEW.username;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `phone_instagram_stories`
--

CREATE TABLE `phone_instagram_stories` (
  `id` varchar(10) NOT NULL,
  `username` varchar(20) NOT NULL,
  `image` varchar(500) NOT NULL,
  `metadata` longtext DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Triggers `phone_instagram_stories`
--
DELIMITER $$
CREATE TRIGGER `phone_instagram_decrement_story_count` AFTER DELETE ON `phone_instagram_stories` FOR EACH ROW BEGIN
    UPDATE phone_instagram_accounts
    SET story_count = story_count - 1
    WHERE username = OLD.username;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `phone_instagram_increment_story_count` AFTER INSERT ON `phone_instagram_stories` FOR EACH ROW BEGIN
    UPDATE phone_instagram_accounts
    SET story_count = story_count + 1
    WHERE username = NEW.username;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `phone_instagram_stories_views`
--

CREATE TABLE `phone_instagram_stories_views` (
  `story_id` varchar(50) NOT NULL,
  `viewer` varchar(20) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_last_phone`
--

CREATE TABLE `phone_last_phone` (
  `id` varchar(100) NOT NULL,
  `phone_number` varchar(15) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `phone_logged_in_accounts`
--

CREATE TABLE `phone_logged_in_accounts` (
  `phone_number` varchar(15) NOT NULL,
  `app` varchar(50) NOT NULL,
  `username` varchar(100) NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `phone_mail_accounts`
--

CREATE TABLE `phone_mail_accounts` (
  `address` varchar(100) NOT NULL,
  `password` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_mail_deleted`
--

CREATE TABLE `phone_mail_deleted` (
  `message_id` int(10) UNSIGNED NOT NULL,
  `address` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_mail_messages`
--

CREATE TABLE `phone_mail_messages` (
  `id` int(10) UNSIGNED NOT NULL,
  `recipient` varchar(100) NOT NULL,
  `sender` varchar(100) NOT NULL,
  `subject` varchar(100) NOT NULL,
  `content` text NOT NULL,
  `attachments` longtext DEFAULT NULL,
  `actions` longtext DEFAULT NULL,
  `read` tinyint(1) NOT NULL DEFAULT 0,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_maps_locations`
--

CREATE TABLE `phone_maps_locations` (
  `id` int(10) UNSIGNED NOT NULL,
  `phone_number` varchar(15) NOT NULL,
  `name` varchar(50) NOT NULL,
  `x_pos` float NOT NULL,
  `y_pos` float NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_marketplace_posts`
--

CREATE TABLE `phone_marketplace_posts` (
  `id` int(11) NOT NULL,
  `phone_number` varchar(15) NOT NULL,
  `title` varchar(50) NOT NULL,
  `description` varchar(1000) NOT NULL,
  `attachments` text DEFAULT NULL,
  `price` int(11) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_message_channels`
--

CREATE TABLE `phone_message_channels` (
  `id` int(11) NOT NULL,
  `is_group` tinyint(1) NOT NULL DEFAULT 0,
  `name` varchar(50) DEFAULT NULL,
  `photo` varchar(500) DEFAULT NULL,
  `last_message` varchar(50) NOT NULL DEFAULT '',
  `last_message_timestamp` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_message_members`
--

CREATE TABLE `phone_message_members` (
  `channel_id` int(11) NOT NULL,
  `phone_number` varchar(15) NOT NULL,
  `is_owner` tinyint(1) NOT NULL DEFAULT 0,
  `deleted` tinyint(1) NOT NULL DEFAULT 0,
  `unread` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_message_messages`
--

CREATE TABLE `phone_message_messages` (
  `id` int(11) NOT NULL,
  `channel_id` int(11) NOT NULL,
  `sender` varchar(15) NOT NULL,
  `content` varchar(1000) DEFAULT NULL,
  `attachments` text DEFAULT NULL,
  `reply_to` int(11) DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_message_reactions`
--

CREATE TABLE `phone_message_reactions` (
  `message_id` int(11) NOT NULL,
  `phone_number` varchar(15) NOT NULL,
  `reaction` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_music_playlists`
--

CREATE TABLE `phone_music_playlists` (
  `id` int(10) UNSIGNED NOT NULL,
  `phone_number` varchar(15) NOT NULL,
  `name` varchar(50) NOT NULL,
  `cover` varchar(500) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_music_saved_playlists`
--

CREATE TABLE `phone_music_saved_playlists` (
  `playlist_id` int(10) UNSIGNED NOT NULL,
  `phone_number` varchar(15) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_music_songs`
--

CREATE TABLE `phone_music_songs` (
  `song_id` varchar(100) NOT NULL,
  `playlist_id` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_notes`
--

CREATE TABLE `phone_notes` (
  `id` int(10) UNSIGNED NOT NULL,
  `phone_number` varchar(15) NOT NULL,
  `title` varchar(50) NOT NULL,
  `content` longtext DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_notifications`
--

CREATE TABLE `phone_notifications` (
  `id` int(11) NOT NULL,
  `phone_number` varchar(15) NOT NULL,
  `app` varchar(50) NOT NULL,
  `title` varchar(50) DEFAULT NULL,
  `content` varchar(500) DEFAULT NULL,
  `thumbnail` varchar(500) DEFAULT NULL,
  `avatar` varchar(500) DEFAULT NULL,
  `show_avatar` tinyint(1) DEFAULT 0,
  `custom_data` text DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_phones`
--

CREATE TABLE `phone_phones` (
  `id` varchar(100) NOT NULL,
  `owner_id` varchar(100) NOT NULL,
  `phone_number` varchar(15) NOT NULL,
  `name` varchar(50) DEFAULT NULL,
  `pin` varchar(4) DEFAULT NULL,
  `face_id` varchar(100) DEFAULT NULL,
  `settings` longtext DEFAULT NULL,
  `is_setup` tinyint(1) DEFAULT 0,
  `assigned` tinyint(1) DEFAULT 0,
  `battery` int(11) NOT NULL DEFAULT 100,
  `last_seen` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `phone_phone_blocked_numbers`
--

CREATE TABLE `phone_phone_blocked_numbers` (
  `phone_number` varchar(15) NOT NULL,
  `blocked_number` varchar(15) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_phone_calls`
--

CREATE TABLE `phone_phone_calls` (
  `id` int(10) UNSIGNED NOT NULL,
  `caller` varchar(15) NOT NULL,
  `callee` varchar(15) NOT NULL,
  `duration` int(11) NOT NULL DEFAULT 0,
  `answered` tinyint(1) DEFAULT 0,
  `hide_caller_id` tinyint(1) DEFAULT 0,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_phone_contacts`
--

CREATE TABLE `phone_phone_contacts` (
  `contact_phone_number` varchar(15) NOT NULL,
  `firstname` varchar(50) NOT NULL DEFAULT '',
  `lastname` varchar(50) NOT NULL DEFAULT '',
  `profile_image` varchar(500) DEFAULT NULL,
  `email` varchar(50) DEFAULT NULL,
  `address` varchar(50) DEFAULT NULL,
  `favourite` tinyint(1) DEFAULT 0,
  `phone_number` varchar(15) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_phone_voicemail`
--

CREATE TABLE `phone_phone_voicemail` (
  `id` int(10) UNSIGNED NOT NULL,
  `caller` varchar(15) NOT NULL,
  `callee` varchar(15) NOT NULL,
  `url` varchar(500) NOT NULL,
  `duration` int(11) NOT NULL,
  `hide_caller_id` tinyint(1) DEFAULT 0,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_photos`
--

CREATE TABLE `phone_photos` (
  `id` int(11) NOT NULL,
  `phone_number` varchar(15) NOT NULL,
  `link` varchar(500) NOT NULL,
  `is_video` tinyint(1) DEFAULT 0,
  `size` float NOT NULL DEFAULT 0,
  `metadata` varchar(20) DEFAULT NULL,
  `is_favourite` tinyint(1) DEFAULT 0,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_photo_albums`
--

CREATE TABLE `phone_photo_albums` (
  `id` int(11) NOT NULL,
  `phone_number` varchar(15) NOT NULL,
  `title` varchar(100) NOT NULL,
  `shared` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_photo_album_members`
--

CREATE TABLE `phone_photo_album_members` (
  `album_id` int(11) NOT NULL,
  `phone_number` varchar(15) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_photo_album_photos`
--

CREATE TABLE `phone_photo_album_photos` (
  `album_id` int(11) NOT NULL,
  `photo_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_services_channels`
--

CREATE TABLE `phone_services_channels` (
  `id` int(10) UNSIGNED NOT NULL,
  `phone_number` varchar(15) NOT NULL,
  `company` varchar(50) NOT NULL,
  `last_message` varchar(100) DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_services_messages`
--

CREATE TABLE `phone_services_messages` (
  `id` int(10) UNSIGNED NOT NULL,
  `channel_id` int(10) UNSIGNED NOT NULL,
  `sender` varchar(15) NOT NULL,
  `message` varchar(1000) NOT NULL,
  `x_pos` int(11) DEFAULT NULL,
  `y_pos` int(11) DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_tiktok_accounts`
--

CREATE TABLE `phone_tiktok_accounts` (
  `name` varchar(30) NOT NULL,
  `bio` varchar(100) DEFAULT NULL,
  `avatar` varchar(500) DEFAULT NULL,
  `username` varchar(20) NOT NULL,
  `password` varchar(100) NOT NULL,
  `verified` tinyint(1) DEFAULT 0,
  `follower_count` int(11) NOT NULL DEFAULT 0,
  `following_count` int(11) NOT NULL DEFAULT 0,
  `like_count` int(11) NOT NULL DEFAULT 0,
  `video_count` int(11) NOT NULL DEFAULT 0,
  `twitter` varchar(20) DEFAULT NULL,
  `instagram` varchar(20) DEFAULT NULL,
  `show_likes` tinyint(1) DEFAULT 1,
  `phone_number` varchar(15) NOT NULL,
  `date_joined` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_tiktok_channels`
--

CREATE TABLE `phone_tiktok_channels` (
  `id` varchar(10) NOT NULL,
  `last_message` varchar(50) NOT NULL,
  `member_1` varchar(20) NOT NULL,
  `member_2` varchar(20) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_tiktok_comments`
--

CREATE TABLE `phone_tiktok_comments` (
  `id` varchar(10) NOT NULL,
  `reply_to` varchar(10) DEFAULT NULL,
  `video_id` varchar(10) NOT NULL,
  `username` varchar(20) NOT NULL,
  `comment` varchar(550) NOT NULL,
  `likes` int(11) NOT NULL DEFAULT 0,
  `replies` int(11) NOT NULL DEFAULT 0,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Triggers `phone_tiktok_comments`
--
DELIMITER $$
CREATE TRIGGER `phone_tiktok_decrement_video_comments` BEFORE DELETE ON `phone_tiktok_comments` FOR EACH ROW BEGIN
    DECLARE v_replies_count INT;

    
    SELECT COUNT(*) INTO v_replies_count
    FROM phone_tiktok_comments
    WHERE reply_to = OLD.id;

    
    UPDATE phone_tiktok_videos
    SET comments = comments - (1 + v_replies_count)
    WHERE id = OLD.video_id;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `phone_tiktok_increment_video_comments` AFTER INSERT ON `phone_tiktok_comments` FOR EACH ROW BEGIN
    UPDATE phone_tiktok_videos
    SET comments = comments + 1
    WHERE id = NEW.video_id;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `phone_tiktok_comments_likes`
--

CREATE TABLE `phone_tiktok_comments_likes` (
  `username` varchar(20) NOT NULL,
  `comment_id` varchar(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Triggers `phone_tiktok_comments_likes`
--
DELIMITER $$
CREATE TRIGGER `phone_tiktok_decrement_comment_likes` AFTER DELETE ON `phone_tiktok_comments_likes` FOR EACH ROW BEGIN
    UPDATE phone_tiktok_comments
    SET likes = likes - 1
    WHERE id = OLD.comment_id;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `phone_tiktok_increment_comment_likes` AFTER INSERT ON `phone_tiktok_comments_likes` FOR EACH ROW BEGIN
    UPDATE phone_tiktok_comments
    SET likes = likes + 1
    WHERE id = NEW.comment_id;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `phone_tiktok_follows`
--

CREATE TABLE `phone_tiktok_follows` (
  `followed` varchar(20) NOT NULL,
  `follower` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Triggers `phone_tiktok_follows`
--
DELIMITER $$
CREATE TRIGGER `phone_tiktok_update_counts_after_follow` AFTER INSERT ON `phone_tiktok_follows` FOR EACH ROW BEGIN
    
    UPDATE phone_tiktok_accounts
    SET follower_count = follower_count + 1
    WHERE username = NEW.followed;

    
    UPDATE phone_tiktok_accounts
    SET following_count = following_count + 1
    WHERE username = NEW.follower;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `phone_tiktok_update_counts_after_unfollow` AFTER DELETE ON `phone_tiktok_follows` FOR EACH ROW BEGIN
    
    UPDATE phone_tiktok_accounts
    SET follower_count = follower_count - 1
    WHERE username = OLD.followed;

    
    UPDATE phone_tiktok_accounts
    SET following_count = following_count - 1
    WHERE username = OLD.follower;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `phone_tiktok_likes`
--

CREATE TABLE `phone_tiktok_likes` (
  `username` varchar(20) NOT NULL,
  `video_id` varchar(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Triggers `phone_tiktok_likes`
--
DELIMITER $$
CREATE TRIGGER `phone_tiktok_decrement_account_likes` AFTER DELETE ON `phone_tiktok_likes` FOR EACH ROW BEGIN
    UPDATE phone_tiktok_accounts
    JOIN phone_tiktok_videos ON phone_tiktok_videos.username = phone_tiktok_accounts.username
    SET phone_tiktok_accounts.like_count = phone_tiktok_accounts.like_count - 1
    WHERE phone_tiktok_videos.id = OLD.video_id;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `phone_tiktok_decrement_video_likes` AFTER DELETE ON `phone_tiktok_likes` FOR EACH ROW BEGIN
    UPDATE phone_tiktok_videos
    SET likes = likes - 1
    WHERE id = OLD.video_id;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `phone_tiktok_increment_account_likes` AFTER INSERT ON `phone_tiktok_likes` FOR EACH ROW BEGIN
    UPDATE phone_tiktok_accounts
    JOIN phone_tiktok_videos ON phone_tiktok_videos.username = phone_tiktok_accounts.username
    SET phone_tiktok_accounts.like_count = phone_tiktok_accounts.like_count + 1
    WHERE phone_tiktok_videos.id = NEW.video_id;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `phone_tiktok_increment_video_likes` AFTER INSERT ON `phone_tiktok_likes` FOR EACH ROW BEGIN
    UPDATE phone_tiktok_videos
    SET likes = likes + 1
    WHERE id = NEW.video_id;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `phone_tiktok_messages`
--

CREATE TABLE `phone_tiktok_messages` (
  `id` varchar(10) NOT NULL,
  `channel_id` varchar(10) NOT NULL,
  `sender` varchar(20) NOT NULL,
  `content` varchar(500) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Triggers `phone_tiktok_messages`
--
DELIMITER $$
CREATE TRIGGER `phone_tiktok_update_last_message` AFTER INSERT ON `phone_tiktok_messages` FOR EACH ROW BEGIN
    DECLARE modified_content TEXT CHARACTER SET utf8mb4;

    IF NEW.content LIKE '<!SHARED-VIDEO-URL%' THEN
        SET modified_content = 'Shared a video';
    ELSEIF LENGTH(NEW.content) > 50 THEN
        SET modified_content = CONCAT(SUBSTR(NEW.content, 1, 17), '...');
    ELSE
        SET modified_content = NEW.content;
    END IF;

    UPDATE phone_tiktok_channels
    SET last_message = modified_content
    WHERE id = NEW.channel_id;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `phone_tiktok_notifications`
--

CREATE TABLE `phone_tiktok_notifications` (
  `id` int(11) NOT NULL,
  `username` varchar(20) NOT NULL,
  `from` varchar(20) NOT NULL,
  `type` varchar(20) NOT NULL,
  `video_id` varchar(10) DEFAULT NULL,
  `comment_id` varchar(10) DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_tiktok_pinned_videos`
--

CREATE TABLE `phone_tiktok_pinned_videos` (
  `username` varchar(20) NOT NULL,
  `video_id` varchar(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_tiktok_saves`
--

CREATE TABLE `phone_tiktok_saves` (
  `username` varchar(20) NOT NULL,
  `video_id` varchar(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Triggers `phone_tiktok_saves`
--
DELIMITER $$
CREATE TRIGGER `phone_tiktok_decrement_video_saves` AFTER DELETE ON `phone_tiktok_saves` FOR EACH ROW BEGIN
    UPDATE phone_tiktok_videos
    SET saves = saves - 1
    WHERE id = OLD.video_id;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `phone_tiktok_increment_video_saves` AFTER INSERT ON `phone_tiktok_saves` FOR EACH ROW BEGIN
    UPDATE phone_tiktok_videos
    SET saves = saves + 1
    WHERE id = NEW.video_id;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `phone_tiktok_unread_messages`
--

CREATE TABLE `phone_tiktok_unread_messages` (
  `username` varchar(20) NOT NULL,
  `channel_id` varchar(10) NOT NULL,
  `amount` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_tiktok_videos`
--

CREATE TABLE `phone_tiktok_videos` (
  `id` varchar(10) NOT NULL,
  `username` varchar(20) NOT NULL,
  `src` varchar(500) NOT NULL,
  `caption` varchar(100) DEFAULT NULL,
  `metadata` longtext DEFAULT NULL,
  `music` text DEFAULT NULL,
  `likes` int(11) NOT NULL DEFAULT 0,
  `comments` int(11) NOT NULL DEFAULT 0,
  `views` int(11) NOT NULL DEFAULT 0,
  `saves` int(11) NOT NULL DEFAULT 0,
  `pinned_comment` varchar(10) DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Triggers `phone_tiktok_videos`
--
DELIMITER $$
CREATE TRIGGER `phone_tiktok_increment_video_count` AFTER INSERT ON `phone_tiktok_videos` FOR EACH ROW BEGIN
    UPDATE phone_tiktok_accounts
    SET video_count = video_count + 1
    WHERE username = NEW.username;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `phone_tiktok_views`
--

CREATE TABLE `phone_tiktok_views` (
  `username` varchar(20) NOT NULL,
  `video_id` varchar(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Triggers `phone_tiktok_views`
--
DELIMITER $$
CREATE TRIGGER `phone_tiktok_increment_video_views` AFTER INSERT ON `phone_tiktok_views` FOR EACH ROW BEGIN
    UPDATE phone_tiktok_videos
    SET views = views + 1
    WHERE id = NEW.video_id;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `phone_tinder_accounts`
--

CREATE TABLE `phone_tinder_accounts` (
  `name` varchar(50) NOT NULL,
  `phone_number` varchar(15) NOT NULL,
  `photos` text DEFAULT NULL,
  `bio` varchar(500) DEFAULT NULL,
  `dob` date NOT NULL,
  `is_male` tinyint(1) NOT NULL,
  `interested_men` tinyint(1) NOT NULL,
  `interested_women` tinyint(1) NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT 1,
  `last_seen` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_tinder_matches`
--

CREATE TABLE `phone_tinder_matches` (
  `phone_number_1` varchar(15) NOT NULL,
  `phone_number_2` varchar(15) NOT NULL,
  `latest_sender` varchar(15) DEFAULT NULL,
  `latest_message` varchar(1000) DEFAULT NULL,
  `latest_message_timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  `phone_number_1_has_unread` tinyint(1) NOT NULL DEFAULT 0,
  `phone_number_2_has_unread` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_tinder_messages`
--

CREATE TABLE `phone_tinder_messages` (
  `id` int(11) NOT NULL,
  `sender` varchar(15) NOT NULL,
  `recipient` varchar(15) NOT NULL,
  `content` varchar(1000) DEFAULT NULL,
  `attachments` text DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_tinder_swipes`
--

CREATE TABLE `phone_tinder_swipes` (
  `swiper` varchar(15) NOT NULL,
  `swipee` varchar(15) NOT NULL,
  `liked` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_twitter_accounts`
--

CREATE TABLE `phone_twitter_accounts` (
  `display_name` varchar(30) NOT NULL,
  `username` varchar(20) NOT NULL,
  `password` varchar(100) NOT NULL,
  `phone_number` varchar(15) NOT NULL,
  `bio` varchar(100) DEFAULT NULL,
  `profile_image` varchar(500) DEFAULT NULL,
  `profile_header` varchar(500) DEFAULT NULL,
  `pinned_tweet` varchar(50) DEFAULT NULL,
  `verified` tinyint(4) DEFAULT 0,
  `follower_count` int(11) NOT NULL DEFAULT 0,
  `following_count` int(11) NOT NULL DEFAULT 0,
  `private` tinyint(1) DEFAULT 0,
  `date_joined` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_twitter_follows`
--

CREATE TABLE `phone_twitter_follows` (
  `followed` varchar(20) NOT NULL,
  `follower` varchar(20) NOT NULL,
  `notifications` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Triggers `phone_twitter_follows`
--
DELIMITER $$
CREATE TRIGGER `phone_twitter_update_counts_after_follow` AFTER INSERT ON `phone_twitter_follows` FOR EACH ROW BEGIN
    
    UPDATE phone_twitter_accounts
    SET follower_count = follower_count + 1
    WHERE username = NEW.followed;

    
    UPDATE phone_twitter_accounts
    SET following_count = following_count + 1
    WHERE username = NEW.follower;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `phone_twitter_update_counts_after_unfollow` AFTER DELETE ON `phone_twitter_follows` FOR EACH ROW BEGIN
    
    UPDATE phone_twitter_accounts
    SET follower_count = follower_count - 1
    WHERE username = OLD.followed;

    
    UPDATE phone_twitter_accounts
    SET following_count = following_count - 1
    WHERE username = OLD.follower;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `phone_twitter_follow_requests`
--

CREATE TABLE `phone_twitter_follow_requests` (
  `requester` varchar(20) NOT NULL,
  `requestee` varchar(20) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_twitter_hashtags`
--

CREATE TABLE `phone_twitter_hashtags` (
  `hashtag` varchar(50) NOT NULL,
  `amount` int(11) NOT NULL DEFAULT 0,
  `last_used` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_twitter_likes`
--

CREATE TABLE `phone_twitter_likes` (
  `tweet_id` varchar(50) NOT NULL,
  `username` varchar(20) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Triggers `phone_twitter_likes`
--
DELIMITER $$
CREATE TRIGGER `phone_twitter_update_like_count_after_like` AFTER INSERT ON `phone_twitter_likes` FOR EACH ROW BEGIN
    UPDATE phone_twitter_tweets
    SET like_count = like_count + 1
    WHERE id = NEW.tweet_id;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `phone_twitter_update_like_count_after_unlike` AFTER DELETE ON `phone_twitter_likes` FOR EACH ROW BEGIN
    UPDATE phone_twitter_tweets
    SET like_count = like_count - 1
    WHERE id = OLD.tweet_id;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `phone_twitter_messages`
--

CREATE TABLE `phone_twitter_messages` (
  `id` varchar(10) NOT NULL,
  `sender` varchar(20) NOT NULL,
  `recipient` varchar(20) NOT NULL,
  `content` varchar(1000) DEFAULT NULL,
  `attachments` text DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_twitter_notifications`
--

CREATE TABLE `phone_twitter_notifications` (
  `id` varchar(10) NOT NULL,
  `username` varchar(20) NOT NULL,
  `from` varchar(20) NOT NULL,
  `type` varchar(20) NOT NULL,
  `tweet_id` varchar(50) DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_twitter_promoted`
--

CREATE TABLE `phone_twitter_promoted` (
  `tweet_id` varchar(50) NOT NULL,
  `promotions` int(11) NOT NULL DEFAULT 0,
  `views` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_twitter_retweets`
--

CREATE TABLE `phone_twitter_retweets` (
  `tweet_id` varchar(50) NOT NULL,
  `username` varchar(20) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Triggers `phone_twitter_retweets`
--
DELIMITER $$
CREATE TRIGGER `phone_twitter_update_retweet_count_after_retweet` AFTER INSERT ON `phone_twitter_retweets` FOR EACH ROW BEGIN
    UPDATE phone_twitter_tweets
    SET retweet_count = retweet_count + 1
    WHERE id = NEW.tweet_id;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `phone_twitter_update_retweet_count_after_unretweet` AFTER DELETE ON `phone_twitter_retweets` FOR EACH ROW BEGIN
    UPDATE phone_twitter_tweets
    SET retweet_count = retweet_count - 1
    WHERE id = OLD.tweet_id;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `phone_twitter_tweets`
--

CREATE TABLE `phone_twitter_tweets` (
  `id` varchar(10) NOT NULL,
  `username` varchar(20) NOT NULL,
  `content` varchar(280) DEFAULT NULL,
  `attachments` text DEFAULT NULL,
  `reply_to` varchar(50) DEFAULT NULL,
  `like_count` int(11) DEFAULT 0,
  `reply_count` int(11) DEFAULT 0,
  `retweet_count` int(11) DEFAULT 0,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_voice_memos_recordings`
--

CREATE TABLE `phone_voice_memos_recordings` (
  `id` int(11) NOT NULL,
  `phone_number` varchar(15) NOT NULL,
  `file_name` varchar(50) NOT NULL,
  `file_url` varchar(500) NOT NULL,
  `file_length` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_wallet_transactions`
--

CREATE TABLE `phone_wallet_transactions` (
  `id` int(11) NOT NULL,
  `phone_number` varchar(15) NOT NULL,
  `amount` int(11) NOT NULL,
  `company` varchar(50) NOT NULL,
  `logo` varchar(200) DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_yellow_pages_posts`
--

CREATE TABLE `phone_yellow_pages_posts` (
  `id` int(10) UNSIGNED NOT NULL,
  `phone_number` varchar(15) NOT NULL,
  `title` varchar(50) NOT NULL,
  `description` varchar(1000) NOT NULL,
  `attachment` varchar(500) DEFAULT NULL,
  `price` int(11) DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `pickax_chase_maps`
--

CREATE TABLE `pickax_chase_maps` (
  `id` varchar(40) NOT NULL,
  `label` varchar(60) NOT NULL,
  `description` varchar(160) NOT NULL DEFAULT '',
  `x` double NOT NULL,
  `y` double NOT NULL,
  `z` double NOT NULL,
  `h` double NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `pickax_chase_npcs`
--

CREATE TABLE `pickax_chase_npcs` (
  `id` int(11) NOT NULL,
  `label` varchar(60) NOT NULL,
  `model` varchar(60) NOT NULL,
  `x` double NOT NULL,
  `y` double NOT NULL,
  `z` double NOT NULL,
  `h` double NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `pickax_chase_settings`
--

CREATE TABLE `pickax_chase_settings` (
  `name` varchar(40) NOT NULL,
  `value` varchar(40) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `pickax_chase_vehicles`
--

CREATE TABLE `pickax_chase_vehicles` (
  `model` varchar(40) NOT NULL,
  `label` varchar(60) NOT NULL,
  `category` varchar(30) NOT NULL DEFAULT 'Autre',
  `speed` int(11) NOT NULL DEFAULT 50,
  `accel` int(11) NOT NULL DEFAULT 50,
  `handling` int(11) NOT NULL DEFAULT 50
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `playerstattoos`
--

CREATE TABLE `playerstattoos` (
  `identifier` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `tattoos` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `p_outfits`
--

CREATE TABLE `p_outfits` (
  `id` int(11) NOT NULL,
  `identifier` varchar(80) NOT NULL,
  `name` varchar(60) NOT NULL,
  `data` longtext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `races`
--

CREATE TABLE `races` (
  `identifier` varchar(80) NOT NULL,
  `name` varchar(255) NOT NULL,
  `race` varchar(255) DEFAULT NULL,
  `lastTime` text NOT NULL,
  `timeDisplay` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `shopbuilder_logs`
--

CREATE TABLE `shopbuilder_logs` (
  `id` int(11) NOT NULL,
  `shop_id` int(11) NOT NULL DEFAULT 0,
  `shop_label` varchar(100) DEFAULT NULL,
  `identifier` varchar(80) DEFAULT NULL,
  `player_name` varchar(100) DEFAULT NULL,
  `action` varchar(40) NOT NULL,
  `detail` varchar(255) DEFAULT NULL,
  `amount` int(11) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `shopbuilder_settings`
--

CREATE TABLE `shopbuilder_settings` (
  `k` varchar(50) NOT NULL,
  `v` longtext DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `shopbuilder_shops`
--

CREATE TABLE `shopbuilder_shops` (
  `id` int(11) NOT NULL,
  `name` varchar(50) NOT NULL,
  `label` varchar(100) NOT NULL,
  `type` varchar(30) NOT NULL DEFAULT 'custom',
  `enabled` tinyint(1) NOT NULL DEFAULT 1,
  `settings` longtext DEFAULT NULL,
  `items` longtext DEFAULT NULL,
  `locations` longtext DEFAULT NULL,
  `stats` longtext DEFAULT NULL,
  `created_by` varchar(80) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `society`
--

CREATE TABLE `society` (
  `id` int(11) NOT NULL,
  `name` longtext NOT NULL,
  `money` varchar(255) NOT NULL,
  `moneysale` varchar(255) NOT NULL,
  `data` longtext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `societymoney`
--

CREATE TABLE `societymoney` (
  `name` varchar(50) NOT NULL,
  `money` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `identifier` varchar(60) NOT NULL,
  `accounts` longtext DEFAULT NULL,
  `group` varchar(50) DEFAULT 'user',
  `inventory` longtext DEFAULT NULL,
  `job` varchar(20) DEFAULT 'unemployed',
  `job2` varchar(20) DEFAULT 'unemployed2',
  `job_grade` int(11) DEFAULT 0,
  `job2_grade` int(11) DEFAULT 0,
  `loadout` longtext DEFAULT NULL,
  `metadata` longtext DEFAULT NULL,
  `position` longtext DEFAULT NULL,
  `firstname` varchar(16) DEFAULT NULL,
  `lastname` varchar(16) DEFAULT NULL,
  `dateofbirth` varchar(10) DEFAULT NULL,
  `sex` varchar(1) DEFAULT NULL,
  `height` int(11) DEFAULT NULL,
  `skin` longtext DEFAULT NULL,
  `status` longtext DEFAULT NULL,
  `is_dead` tinyint(1) DEFAULT 0,
  `last_property` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `last_seen` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  `points` int(11) NOT NULL DEFAULT 0,
  `boutique_id` int(11) NOT NULL,
  `vip` tinyint(1) DEFAULT 0,
  `isDead` tinyint(1) DEFAULT 0,
  `caractere` longtext DEFAULT NULL,
  `health` int(11) NOT NULL DEFAULT 200,
  `playtime` int(11) DEFAULT 0,
  `nationality` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `user_licenses`
--

CREATE TABLE `user_licenses` (
  `id` int(11) NOT NULL,
  `type` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `owner` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `vehicles`
--

CREATE TABLE `vehicles` (
  `name` varchar(60) NOT NULL,
  `model` varchar(60) NOT NULL,
  `price` int(11) NOT NULL,
  `category` varchar(60) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `vehicle_categories`
--

CREATE TABLE `vehicle_categories` (
  `name` varchar(60) NOT NULL,
  `label` varchar(60) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `vehicle_sold`
--

CREATE TABLE `vehicle_sold` (
  `client` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `model` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `plate` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `soldby` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `date` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `society` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL DEFAULT 'carshop'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `vips`
--

CREATE TABLE `vips` (
  `identifier` varchar(50) NOT NULL,
  `vip` int(11) DEFAULT NULL,
  `expiration` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `worldbuilder_chase_stats`
--

CREATE TABLE `worldbuilder_chase_stats` (
  `identifier` varchar(80) NOT NULL,
  `name` varchar(100) NOT NULL DEFAULT '',
  `matches` int(11) NOT NULL DEFAULT 0,
  `wins_runner` int(11) NOT NULL DEFAULT 0,
  `wins_chaser` int(11) NOT NULL DEFAULT 0,
  `losses` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `worldbuilder_entities`
--

CREATE TABLE `worldbuilder_entities` (
  `id` int(11) NOT NULL,
  `type` varchar(20) NOT NULL,
  `name` varchar(50) NOT NULL,
  `label` varchar(100) NOT NULL,
  `enabled` tinyint(1) NOT NULL DEFAULT 1,
  `settings` longtext DEFAULT NULL,
  `points` longtext DEFAULT NULL,
  `stats` longtext DEFAULT NULL,
  `created_by` varchar(80) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `worldbuilder_impound`
--

CREATE TABLE `worldbuilder_impound` (
  `plate` varchar(12) NOT NULL,
  `impound_id` int(11) NOT NULL DEFAULT 0,
  `reason` varchar(200) DEFAULT NULL,
  `fee` int(11) NOT NULL DEFAULT 0,
  `officer` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `worldbuilder_licenses`
--

CREATE TABLE `worldbuilder_licenses` (
  `identifier` varchar(80) NOT NULL,
  `license` varchar(40) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `worldbuilder_listings`
--

CREATE TABLE `worldbuilder_listings` (
  `id` int(11) NOT NULL,
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
  `expires_at` bigint(20) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `worldbuilder_logs`
--

CREATE TABLE `worldbuilder_logs` (
  `id` int(11) NOT NULL,
  `entity_id` int(11) NOT NULL DEFAULT 0,
  `entity_label` varchar(100) DEFAULT NULL,
  `type` varchar(20) DEFAULT NULL,
  `identifier` varchar(80) DEFAULT NULL,
  `player_name` varchar(100) DEFAULT NULL,
  `action` varchar(40) NOT NULL,
  `detail` varchar(255) DEFAULT NULL,
  `amount` int(11) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `worldbuilder_parking`
--

CREATE TABLE `worldbuilder_parking` (
  `plate` varchar(12) NOT NULL,
  `entity_id` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `worldbuilder_payouts`
--

CREATE TABLE `worldbuilder_payouts` (
  `id` int(11) NOT NULL,
  `identifier` varchar(80) NOT NULL,
  `amount` int(11) NOT NULL DEFAULT 0,
  `note` varchar(200) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `worldbuilder_pvp_stats`
--

CREATE TABLE `worldbuilder_pvp_stats` (
  `identifier` varchar(80) NOT NULL,
  `name` varchar(100) NOT NULL DEFAULT '',
  `kills` int(11) NOT NULL DEFAULT 0,
  `deaths` int(11) NOT NULL DEFAULT 0,
  `best_streak` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `worldbuilder_settings`
--

CREATE TABLE `worldbuilder_settings` (
  `k` varchar(50) NOT NULL,
  `v` longtext DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `worldbuilder_state`
--

CREATE TABLE `worldbuilder_state` (
  `k` varchar(80) NOT NULL,
  `v` bigint(20) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


--
-- Indexes for dumped tables
--

--
-- Indexes for table `account_info`
--
ALTER TABLE `account_info`
  ADD PRIMARY KEY (`account_id`),
  ADD UNIQUE KEY `license` (`license`);

--
-- Indexes for table `addon_account`
--
ALTER TABLE `addon_account`
  ADD PRIMARY KEY (`name`) USING BTREE;

--
-- Indexes for table `addon_account_data`
--
ALTER TABLE `addon_account_data`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `index_addon_account_data_account_name_owner` (`account_name`,`owner`),
  ADD KEY `index_addon_account_data_account_name` (`account_name`);

--
-- Indexes for table `addon_inventory`
--
ALTER TABLE `addon_inventory`
  ADD PRIMARY KEY (`name`) USING BTREE;

--
-- Indexes for table `addon_inventory_items`
--
ALTER TABLE `addon_inventory_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `index_addon_inventory_items_inventory_name_name` (`inventory_name`,`name`),
  ADD KEY `index_addon_inventory_items_inventory_name_name_owner` (`inventory_name`,`name`,`owner`),
  ADD KEY `index_addon_inventory_inventory_name` (`inventory_name`);

--
-- Indexes for table `banlist`
--
ALTER TABLE `banlist`
  ADD PRIMARY KEY (`licenseid`);

--
-- Indexes for table `banlisthistory`
--
ALTER TABLE `banlisthistory`
  ADD PRIMARY KEY (`id`) USING BTREE;

--
-- Indexes for table `billing`
--
ALTER TABLE `billing`
  ADD PRIMARY KEY (`id`) USING BTREE,
  ADD KEY `index_billing_identifier` (`identifier`) USING BTREE;

--
-- Indexes for table `boitegant`
--
ALTER TABLE `boitegant`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `clothes_player`
--
ALTER TABLE `clothes_player`
  ADD UNIQUE KEY `id` (`id`);

--
-- Indexes for table `coffre_armeperm`
--
ALTER TABLE `coffre_armeperm`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `coffre_veh`
--
ALTER TABLE `coffre_veh`
  ADD UNIQUE KEY `id` (`id`);

--
-- Indexes for table `datastore`
--
ALTER TABLE `datastore`
  ADD PRIMARY KEY (`name`) USING BTREE;

--
-- Indexes for table `datastore_data`
--
ALTER TABLE `datastore_data`
  ADD PRIMARY KEY (`id`) USING BTREE,
  ADD KEY `index_datastore_data_name` (`name`) USING BTREE,
  ADD KEY `index_datastore_data_name_owner` (`name`,`owner`) USING BTREE;

--
-- Indexes for table `gangbuilder_gangs`
--
ALTER TABLE `gangbuilder_gangs`
  ADD PRIMARY KEY (`name`);

--
-- Indexes for table `gangbuilder_logs`
--
ALTER TABLE `gangbuilder_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_gangbuilder_logs_gang` (`gang_name`,`id`);

--
-- Indexes for table `gangbuilder_points`
--
ALTER TABLE `gangbuilder_points`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_gangbuilder_points_gang` (`gang_name`);

--
-- Indexes for table `gangbuilder_settings`
--
ALTER TABLE `gangbuilder_settings`
  ADD PRIMARY KEY (`name`);

--
-- Indexes for table `gangbuilder_stats`
--
ALTER TABLE `gangbuilder_stats`
  ADD PRIMARY KEY (`identifier`,`gang_name`);

--
-- Indexes for table `gangbuilder_territories`
--
ALTER TABLE `gangbuilder_territories`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_gangbuilder_territories_name` (`name`);

--
-- Indexes for table `items`
--
ALTER TABLE `items`
  ADD PRIMARY KEY (`name`) USING BTREE;

--
-- Indexes for table `job2_grades`
--
ALTER TABLE `job2_grades`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `jobbuilder_announces`
--
ALTER TABLE `jobbuilder_announces`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_jobbuilder_announces_job` (`job_name`,`id`);

--
-- Indexes for table `jobbuilder_bank_clients`
--
ALTER TABLE `jobbuilder_bank_clients`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_jobbuilder_bank_clients_job` (`job_name`),
  ADD KEY `idx_jobbuilder_bank_clients_ident` (`job_name`,`identifier`);

--
-- Indexes for table `jobbuilder_bank_entries`
--
ALTER TABLE `jobbuilder_bank_entries`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_jobbuilder_bank_entries_c` (`client_id`,`id`),
  ADD KEY `idx_jobbuilder_bank_entries_job` (`job_name`,`id`);

--
-- Indexes for table `jobbuilder_bank_loans`
--
ALTER TABLE `jobbuilder_bank_loans`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_jobbuilder_bank_loans_job` (`job_name`,`status`),
  ADD KEY `idx_jobbuilder_bank_loans_ident` (`identifier`,`status`),
  ADD KEY `fk_jobbuilder_bank_loans_c` (`client_id`);

--
-- Indexes for table `jobbuilder_dealer_sales`
--
ALTER TABLE `jobbuilder_dealer_sales`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_jobbuilder_dealer_sales_job` (`job_name`,`id`);

--
-- Indexes for table `jobbuilder_dealer_vehicles`
--
ALTER TABLE `jobbuilder_dealer_vehicles`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_jobbuilder_dealer_vehicles_job` (`job_name`);

--
-- Indexes for table `jobbuilder_jobs`
--
ALTER TABLE `jobbuilder_jobs`
  ADD PRIMARY KEY (`name`);

--
-- Indexes for table `jobbuilder_logs`
--
ALTER TABLE `jobbuilder_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_jobbuilder_logs_job` (`job_name`,`id`);

--
-- Indexes for table `jobbuilder_mission_stats`
--
ALTER TABLE `jobbuilder_mission_stats`
  ADD PRIMARY KEY (`identifier`,`job_name`);

--
-- Indexes for table `jobbuilder_patients`
--
ALTER TABLE `jobbuilder_patients`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_jobbuilder_patients_job` (`job_name`),
  ADD KEY `idx_jobbuilder_patients_ident` (`job_name`,`identifier`);

--
-- Indexes for table `jobbuilder_patient_entries`
--
ALTER TABLE `jobbuilder_patient_entries`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_jobbuilder_patient_entries_p` (`patient_id`,`id`);

--
-- Indexes for table `jobbuilder_points`
--
ALTER TABLE `jobbuilder_points`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_jobbuilder_points_job` (`job_name`);

--
-- Indexes for table `jobbuilder_properties`
--
ALTER TABLE `jobbuilder_properties`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_jobbuilder_properties_job` (`job_name`),
  ADD KEY `idx_jobbuilder_properties_owner` (`owner`);

--
-- Indexes for table `jobbuilder_property_history`
--
ALTER TABLE `jobbuilder_property_history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_jobbuilder_property_history_job` (`job_name`,`id`);

--
-- Indexes for table `jobbuilder_property_outfits`
--
ALTER TABLE `jobbuilder_property_outfits`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_jobbuilder_property_outfits` (`property_id`,`identifier`);

--
-- Indexes for table `jobbuilder_property_points`
--
ALTER TABLE `jobbuilder_property_points`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_jobbuilder_property_points_prop` (`property_id`);

--
-- Indexes for table `jobbuilder_records`
--
ALTER TABLE `jobbuilder_records`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_jobbuilder_records_job` (`job_name`,`wanted`),
  ADD KEY `idx_jobbuilder_records_ident` (`job_name`,`identifier`);

--
-- Indexes for table `jobbuilder_record_entries`
--
ALTER TABLE `jobbuilder_record_entries`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_jobbuilder_record_entries_rec` (`record_id`,`id`);

--
-- Indexes for table `jobbuilder_settings`
--
ALTER TABLE `jobbuilder_settings`
  ADD PRIMARY KEY (`name`);

--
-- Indexes for table `jobbuilder_treasury_log`
--
ALTER TABLE `jobbuilder_treasury_log`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_jobbuilder_treasury_log_kind` (`kind`,`id`);

--
-- Indexes for table `jobs`
--
ALTER TABLE `jobs`
  ADD PRIMARY KEY (`name`) USING BTREE;

--
-- Indexes for table `jobs2`
--
ALTER TABLE `jobs2`
  ADD PRIMARY KEY (`name`);

--
-- Indexes for table `job_grades`
--
ALTER TABLE `job_grades`
  ADD PRIMARY KEY (`id`) USING BTREE;

--
-- Indexes for table `leboncoin`
--
ALTER TABLE `leboncoin`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `licenses`
--
ALTER TABLE `licenses`
  ADD PRIMARY KEY (`type`) USING BTREE;

--
-- Indexes for table `lotery`
--
ALTER TABLE `lotery`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `newplayer_playtime`
--
ALTER TABLE `newplayer_playtime`
  ADD PRIMARY KEY (`identifier`);

--
-- Indexes for table `open_car`
--
ALTER TABLE `open_car`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `owned_properties`
--
ALTER TABLE `owned_properties`
  ADD PRIMARY KEY (`id`) USING BTREE;

--
-- Indexes for table `owned_vehicles`
--
ALTER TABLE `owned_vehicles`
  ADD PRIMARY KEY (`plate`),
  ADD KEY `owner` (`owner`),
  ADD KEY `name` (`name`),
  ADD KEY `vehicle` (`vehicle`(767)),
  ADD KEY `type` (`type`);

--
-- Indexes for table `ox_inventory`
--
ALTER TABLE `ox_inventory`
  ADD UNIQUE KEY `owner` (`owner`,`name`);

--
-- Indexes for table `ox_inventory_clothing`
--
ALTER TABLE `ox_inventory_clothing`
  ADD PRIMARY KEY (`owner`);

--
-- Indexes for table `ox_inventory_lockers`
--
ALTER TABLE `ox_inventory_lockers`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `ox_inventory_locker_casiers`
--
ALTER TABLE `ox_inventory_locker_casiers`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_casier` (`locker_id`,`casier_number`);

--
-- Indexes for table `ox_inventory_medical`
--
ALTER TABLE `ox_inventory_medical`
  ADD PRIMARY KEY (`owner`);

--
-- Indexes for table `ox_inventory_outfits`
--
ALTER TABLE `ox_inventory_outfits`
  ADD PRIMARY KEY (`owner`);

--
-- Indexes for table `ox_inventory_outfit_catalog`
--
ALTER TABLE `ox_inventory_outfit_catalog`
  ADD PRIMARY KEY (`clothe_id`);

--
-- Indexes for table `ox_inventory_placed_items`
--
ALTER TABLE `ox_inventory_placed_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `owner` (`owner`);

--
-- Indexes for table `pgang_objectives`
--
ALTER TABLE `pgang_objectives`
  ADD PRIMARY KEY (`gang`,`day`,`id`);

--
-- Indexes for table `pgang_relations`
--
ALTER TABLE `pgang_relations`
  ADD PRIMARY KEY (`gang_a`,`gang_b`);

--
-- Indexes for table `phone_backups`
--
ALTER TABLE `phone_backups`
  ADD PRIMARY KEY (`id`,`phone_number`),
  ADD KEY `phone_number` (`phone_number`);

--
-- Indexes for table `phone_clock_alarms`
--
ALTER TABLE `phone_clock_alarms`
  ADD PRIMARY KEY (`id`,`phone_number`),
  ADD KEY `phone_number` (`phone_number`);

--
-- Indexes for table `phone_crypto`
--
ALTER TABLE `phone_crypto`
  ADD PRIMARY KEY (`id`,`coin`);

--
-- Indexes for table `phone_crypto_coins`
--
ALTER TABLE `phone_crypto_coins`
  ADD PRIMARY KEY (`coin`);

--
-- Indexes for table `phone_darkchat_accounts`
--
ALTER TABLE `phone_darkchat_accounts`
  ADD PRIMARY KEY (`username`),
  ADD KEY `phone_number` (`phone_number`);

--
-- Indexes for table `phone_darkchat_channels`
--
ALTER TABLE `phone_darkchat_channels`
  ADD PRIMARY KEY (`name`);

--
-- Indexes for table `phone_darkchat_members`
--
ALTER TABLE `phone_darkchat_members`
  ADD PRIMARY KEY (`channel_name`,`username`),
  ADD KEY `username` (`username`);

--
-- Indexes for table `phone_darkchat_messages`
--
ALTER TABLE `phone_darkchat_messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `channel` (`channel`),
  ADD KEY `sender` (`sender`);

--
-- Indexes for table `phone_instagram_accounts`
--
ALTER TABLE `phone_instagram_accounts`
  ADD PRIMARY KEY (`username`),
  ADD KEY `phone_number` (`phone_number`);

--
-- Indexes for table `phone_instagram_comments`
--
ALTER TABLE `phone_instagram_comments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `post_id` (`post_id`),
  ADD KEY `username` (`username`);

--
-- Indexes for table `phone_instagram_follows`
--
ALTER TABLE `phone_instagram_follows`
  ADD PRIMARY KEY (`followed`,`follower`),
  ADD KEY `follower` (`follower`);

--
-- Indexes for table `phone_instagram_follow_requests`
--
ALTER TABLE `phone_instagram_follow_requests`
  ADD PRIMARY KEY (`requester`,`requestee`),
  ADD KEY `requestee` (`requestee`);

--
-- Indexes for table `phone_instagram_likes`
--
ALTER TABLE `phone_instagram_likes`
  ADD PRIMARY KEY (`id`,`username`),
  ADD KEY `username` (`username`);

--
-- Indexes for table `phone_instagram_messages`
--
ALTER TABLE `phone_instagram_messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `sender` (`sender`),
  ADD KEY `recipient` (`recipient`);

--
-- Indexes for table `phone_instagram_notifications`
--
ALTER TABLE `phone_instagram_notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `username` (`username`),
  ADD KEY `from` (`from`);

--
-- Indexes for table `phone_instagram_posts`
--
ALTER TABLE `phone_instagram_posts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `username` (`username`);

--
-- Indexes for table `phone_instagram_stories`
--
ALTER TABLE `phone_instagram_stories`
  ADD PRIMARY KEY (`id`),
  ADD KEY `username` (`username`);

--
-- Indexes for table `phone_instagram_stories_views`
--
ALTER TABLE `phone_instagram_stories_views`
  ADD PRIMARY KEY (`story_id`,`viewer`),
  ADD KEY `viewer` (`viewer`);

--
-- Indexes for table `phone_last_phone`
--
ALTER TABLE `phone_last_phone`
  ADD PRIMARY KEY (`id`),
  ADD KEY `phone_number` (`phone_number`);

--
-- Indexes for table `phone_logged_in_accounts`
--
ALTER TABLE `phone_logged_in_accounts`
  ADD PRIMARY KEY (`phone_number`,`app`,`username`);

--
-- Indexes for table `phone_mail_accounts`
--
ALTER TABLE `phone_mail_accounts`
  ADD PRIMARY KEY (`address`);

--
-- Indexes for table `phone_mail_deleted`
--
ALTER TABLE `phone_mail_deleted`
  ADD PRIMARY KEY (`message_id`,`address`),
  ADD KEY `address` (`address`);

--
-- Indexes for table `phone_mail_messages`
--
ALTER TABLE `phone_mail_messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_recipient` (`recipient`),
  ADD KEY `idx_sender` (`sender`);

--
-- Indexes for table `phone_maps_locations`
--
ALTER TABLE `phone_maps_locations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `phone_number` (`phone_number`);

--
-- Indexes for table `phone_marketplace_posts`
--
ALTER TABLE `phone_marketplace_posts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `phone_number` (`phone_number`);

--
-- Indexes for table `phone_message_channels`
--
ALTER TABLE `phone_message_channels`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `phone_message_members`
--
ALTER TABLE `phone_message_members`
  ADD PRIMARY KEY (`channel_id`,`phone_number`),
  ADD KEY `idx_members_phone_number` (`phone_number`);

--
-- Indexes for table `phone_message_messages`
--
ALTER TABLE `phone_message_messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `channel_id` (`channel_id`);

--
-- Indexes for table `phone_message_reactions`
--
ALTER TABLE `phone_message_reactions`
  ADD PRIMARY KEY (`message_id`,`phone_number`,`reaction`),
  ADD KEY `phone_number` (`phone_number`);

--
-- Indexes for table `phone_music_playlists`
--
ALTER TABLE `phone_music_playlists`
  ADD PRIMARY KEY (`id`),
  ADD KEY `phone_number` (`phone_number`);

--
-- Indexes for table `phone_music_saved_playlists`
--
ALTER TABLE `phone_music_saved_playlists`
  ADD PRIMARY KEY (`playlist_id`,`phone_number`),
  ADD KEY `phone_number` (`phone_number`);

--
-- Indexes for table `phone_music_songs`
--
ALTER TABLE `phone_music_songs`
  ADD PRIMARY KEY (`song_id`,`playlist_id`),
  ADD KEY `playlist_id` (`playlist_id`);

--
-- Indexes for table `phone_notes`
--
ALTER TABLE `phone_notes`
  ADD PRIMARY KEY (`id`),
  ADD KEY `phone_number` (`phone_number`);

--
-- Indexes for table `phone_notifications`
--
ALTER TABLE `phone_notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `phone_number` (`phone_number`);

--
-- Indexes for table `phone_phones`
--
ALTER TABLE `phone_phones`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `phone_number` (`phone_number`);

--
-- Indexes for table `phone_phone_blocked_numbers`
--
ALTER TABLE `phone_phone_blocked_numbers`
  ADD PRIMARY KEY (`phone_number`,`blocked_number`);

--
-- Indexes for table `phone_phone_calls`
--
ALTER TABLE `phone_phone_calls`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_calls_missed` (`callee`,`answered`),
  ADD KEY `idx_calls_callee_id` (`callee`),
  ADD KEY `idx_calls_caller_id` (`caller`);

--
-- Indexes for table `phone_phone_contacts`
--
ALTER TABLE `phone_phone_contacts`
  ADD PRIMARY KEY (`contact_phone_number`,`phone_number`);

--
-- Indexes for table `phone_phone_voicemail`
--
ALTER TABLE `phone_phone_voicemail`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `phone_photos`
--
ALTER TABLE `phone_photos`
  ADD PRIMARY KEY (`id`),
  ADD KEY `phone_number` (`phone_number`);

--
-- Indexes for table `phone_photo_albums`
--
ALTER TABLE `phone_photo_albums`
  ADD PRIMARY KEY (`id`),
  ADD KEY `phone_number` (`phone_number`);

--
-- Indexes for table `phone_photo_album_members`
--
ALTER TABLE `phone_photo_album_members`
  ADD PRIMARY KEY (`album_id`,`phone_number`),
  ADD KEY `phone_number` (`phone_number`);

--
-- Indexes for table `phone_photo_album_photos`
--
ALTER TABLE `phone_photo_album_photos`
  ADD PRIMARY KEY (`album_id`,`photo_id`),
  ADD KEY `photo_id` (`photo_id`);

--
-- Indexes for table `phone_services_channels`
--
ALTER TABLE `phone_services_channels`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `phone_services_messages`
--
ALTER TABLE `phone_services_messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `channel_id` (`channel_id`);

--
-- Indexes for table `phone_tiktok_accounts`
--
ALTER TABLE `phone_tiktok_accounts`
  ADD PRIMARY KEY (`username`),
  ADD KEY `phone_number` (`phone_number`);

--
-- Indexes for table `phone_tiktok_channels`
--
ALTER TABLE `phone_tiktok_channels`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `member_1` (`member_1`,`member_2`),
  ADD KEY `member_2` (`member_2`);

--
-- Indexes for table `phone_tiktok_comments`
--
ALTER TABLE `phone_tiktok_comments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `video_id` (`video_id`),
  ADD KEY `username` (`username`),
  ADD KEY `reply_to` (`reply_to`);

--
-- Indexes for table `phone_tiktok_comments_likes`
--
ALTER TABLE `phone_tiktok_comments_likes`
  ADD PRIMARY KEY (`username`,`comment_id`),
  ADD KEY `comment_id` (`comment_id`);

--
-- Indexes for table `phone_tiktok_follows`
--
ALTER TABLE `phone_tiktok_follows`
  ADD PRIMARY KEY (`followed`,`follower`),
  ADD KEY `follower` (`follower`);

--
-- Indexes for table `phone_tiktok_likes`
--
ALTER TABLE `phone_tiktok_likes`
  ADD PRIMARY KEY (`username`,`video_id`),
  ADD KEY `video_id` (`video_id`);

--
-- Indexes for table `phone_tiktok_messages`
--
ALTER TABLE `phone_tiktok_messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `channel_id` (`channel_id`),
  ADD KEY `sender` (`sender`);

--
-- Indexes for table `phone_tiktok_notifications`
--
ALTER TABLE `phone_tiktok_notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `username` (`username`),
  ADD KEY `from` (`from`),
  ADD KEY `video_id` (`video_id`),
  ADD KEY `comment_id` (`comment_id`);

--
-- Indexes for table `phone_tiktok_pinned_videos`
--
ALTER TABLE `phone_tiktok_pinned_videos`
  ADD PRIMARY KEY (`username`,`video_id`),
  ADD KEY `video_id` (`video_id`);

--
-- Indexes for table `phone_tiktok_saves`
--
ALTER TABLE `phone_tiktok_saves`
  ADD PRIMARY KEY (`username`,`video_id`),
  ADD KEY `video_id` (`video_id`);

--
-- Indexes for table `phone_tiktok_unread_messages`
--
ALTER TABLE `phone_tiktok_unread_messages`
  ADD PRIMARY KEY (`username`,`channel_id`),
  ADD KEY `channel_id` (`channel_id`);

--
-- Indexes for table `phone_tiktok_videos`
--
ALTER TABLE `phone_tiktok_videos`
  ADD PRIMARY KEY (`id`),
  ADD KEY `username` (`username`);

--
-- Indexes for table `phone_tiktok_views`
--
ALTER TABLE `phone_tiktok_views`
  ADD PRIMARY KEY (`username`,`video_id`),
  ADD KEY `video_id` (`video_id`);

--
-- Indexes for table `phone_tinder_accounts`
--
ALTER TABLE `phone_tinder_accounts`
  ADD PRIMARY KEY (`phone_number`);

--
-- Indexes for table `phone_tinder_matches`
--
ALTER TABLE `phone_tinder_matches`
  ADD PRIMARY KEY (`phone_number_1`,`phone_number_2`),
  ADD KEY `phone_number_2` (`phone_number_2`);

--
-- Indexes for table `phone_tinder_messages`
--
ALTER TABLE `phone_tinder_messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `sender` (`sender`),
  ADD KEY `recipient` (`recipient`);

--
-- Indexes for table `phone_tinder_swipes`
--
ALTER TABLE `phone_tinder_swipes`
  ADD PRIMARY KEY (`swiper`,`swipee`),
  ADD KEY `swipee` (`swipee`);

--
-- Indexes for table `phone_twitter_accounts`
--
ALTER TABLE `phone_twitter_accounts`
  ADD PRIMARY KEY (`username`),
  ADD KEY `phone_number` (`phone_number`);

--
-- Indexes for table `phone_twitter_follows`
--
ALTER TABLE `phone_twitter_follows`
  ADD PRIMARY KEY (`followed`,`follower`),
  ADD KEY `follower` (`follower`);

--
-- Indexes for table `phone_twitter_follow_requests`
--
ALTER TABLE `phone_twitter_follow_requests`
  ADD PRIMARY KEY (`requester`,`requestee`),
  ADD KEY `requestee` (`requestee`);

--
-- Indexes for table `phone_twitter_hashtags`
--
ALTER TABLE `phone_twitter_hashtags`
  ADD PRIMARY KEY (`hashtag`);

--
-- Indexes for table `phone_twitter_likes`
--
ALTER TABLE `phone_twitter_likes`
  ADD PRIMARY KEY (`tweet_id`,`username`),
  ADD KEY `username` (`username`);

--
-- Indexes for table `phone_twitter_messages`
--
ALTER TABLE `phone_twitter_messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `sender` (`sender`),
  ADD KEY `recipient` (`recipient`);

--
-- Indexes for table `phone_twitter_notifications`
--
ALTER TABLE `phone_twitter_notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `username` (`username`),
  ADD KEY `from` (`from`);

--
-- Indexes for table `phone_twitter_promoted`
--
ALTER TABLE `phone_twitter_promoted`
  ADD PRIMARY KEY (`tweet_id`);

--
-- Indexes for table `phone_twitter_retweets`
--
ALTER TABLE `phone_twitter_retweets`
  ADD PRIMARY KEY (`tweet_id`,`username`),
  ADD KEY `username` (`username`);

--
-- Indexes for table `phone_twitter_tweets`
--
ALTER TABLE `phone_twitter_tweets`
  ADD PRIMARY KEY (`id`),
  ADD KEY `username` (`username`);

--
-- Indexes for table `phone_voice_memos_recordings`
--
ALTER TABLE `phone_voice_memos_recordings`
  ADD PRIMARY KEY (`id`),
  ADD KEY `phone_number` (`phone_number`);

--
-- Indexes for table `phone_wallet_transactions`
--
ALTER TABLE `phone_wallet_transactions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `phone_number` (`phone_number`);

--
-- Indexes for table `phone_yellow_pages_posts`
--
ALTER TABLE `phone_yellow_pages_posts`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `pickax_chase_maps`
--
ALTER TABLE `pickax_chase_maps`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `pickax_chase_npcs`
--
ALTER TABLE `pickax_chase_npcs`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `pickax_chase_settings`
--
ALTER TABLE `pickax_chase_settings`
  ADD PRIMARY KEY (`name`);

--
-- Indexes for table `pickax_chase_vehicles`
--
ALTER TABLE `pickax_chase_vehicles`
  ADD PRIMARY KEY (`model`);

--
-- Indexes for table `playerstattoos`
--
ALTER TABLE `playerstattoos`
  ADD PRIMARY KEY (`identifier`) USING BTREE;

--
-- Indexes for table `p_outfits`
--
ALTER TABLE `p_outfits`
  ADD PRIMARY KEY (`id`),
  ADD KEY `identifier` (`identifier`);

--
-- Indexes for table `races`
--
ALTER TABLE `races`
  ADD KEY `identifier` (`identifier`);

--
-- Indexes for table `shopbuilder_logs`
--
ALTER TABLE `shopbuilder_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_shopbuilder_logs_shop` (`shop_id`,`id`);

--
-- Indexes for table `shopbuilder_settings`
--
ALTER TABLE `shopbuilder_settings`
  ADD PRIMARY KEY (`k`);

--
-- Indexes for table `shopbuilder_shops`
--
ALTER TABLE `shopbuilder_shops`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_shopbuilder_name` (`name`);

--
-- Indexes for table `society`
--
ALTER TABLE `society`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`identifier`),
  ADD UNIQUE KEY `boutique_id` (`boutique_id`);

--
-- Indexes for table `user_licenses`
--
ALTER TABLE `user_licenses`
  ADD PRIMARY KEY (`id`) USING BTREE;

--
-- Indexes for table `vehicles`
--
ALTER TABLE `vehicles`
  ADD PRIMARY KEY (`model`);

--
-- Indexes for table `vehicle_categories`
--
ALTER TABLE `vehicle_categories`
  ADD PRIMARY KEY (`name`);

--
-- Indexes for table `vehicle_sold`
--
ALTER TABLE `vehicle_sold`
  ADD PRIMARY KEY (`plate`) USING BTREE;

--
-- Indexes for table `vips`
--
ALTER TABLE `vips`
  ADD PRIMARY KEY (`identifier`);

--
-- Indexes for table `worldbuilder_chase_stats`
--
ALTER TABLE `worldbuilder_chase_stats`
  ADD PRIMARY KEY (`identifier`);

--
-- Indexes for table `worldbuilder_entities`
--
ALTER TABLE `worldbuilder_entities`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_worldbuilder_name` (`name`),
  ADD KEY `idx_worldbuilder_type` (`type`);

--
-- Indexes for table `worldbuilder_impound`
--
ALTER TABLE `worldbuilder_impound`
  ADD PRIMARY KEY (`plate`);

--
-- Indexes for table `worldbuilder_licenses`
--
ALTER TABLE `worldbuilder_licenses`
  ADD PRIMARY KEY (`identifier`,`license`);

--
-- Indexes for table `worldbuilder_listings`
--
ALTER TABLE `worldbuilder_listings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_listing_plate` (`plate`),
  ADD KEY `idx_listing_entity` (`entity_id`);

--
-- Indexes for table `worldbuilder_logs`
--
ALTER TABLE `worldbuilder_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_worldbuilder_logs_entity` (`entity_id`,`id`);

--
-- Indexes for table `worldbuilder_parking`
--
ALTER TABLE `worldbuilder_parking`
  ADD PRIMARY KEY (`plate`);

--
-- Indexes for table `worldbuilder_payouts`
--
ALTER TABLE `worldbuilder_payouts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_payout_identifier` (`identifier`);

--
-- Indexes for table `worldbuilder_pvp_stats`
--
ALTER TABLE `worldbuilder_pvp_stats`
  ADD PRIMARY KEY (`identifier`);

--
-- Indexes for table `worldbuilder_settings`
--
ALTER TABLE `worldbuilder_settings`
  ADD PRIMARY KEY (`k`);

--
-- Indexes for table `worldbuilder_state`
--
ALTER TABLE `worldbuilder_state`
  ADD PRIMARY KEY (`k`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `account_info`
--
ALTER TABLE `account_info`
  MODIFY `account_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;

--
-- AUTO_INCREMENT for table `addon_account_data`
--
ALTER TABLE `addon_account_data`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;

--
-- AUTO_INCREMENT for table `addon_inventory_items`
--
ALTER TABLE `addon_inventory_items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `banlisthistory`
--
ALTER TABLE `banlisthistory`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `billing`
--
ALTER TABLE `billing`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;

--
-- AUTO_INCREMENT for table `boitegant`
--
ALTER TABLE `boitegant`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `clothes_player`
--
ALTER TABLE `clothes_player`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;

--
-- AUTO_INCREMENT for table `coffre_armeperm`
--
ALTER TABLE `coffre_armeperm`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `datastore_data`
--
ALTER TABLE `datastore_data`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;

--
-- AUTO_INCREMENT for table `gangbuilder_logs`
--
ALTER TABLE `gangbuilder_logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;

--
-- AUTO_INCREMENT for table `gangbuilder_points`
--
ALTER TABLE `gangbuilder_points`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;

--
-- AUTO_INCREMENT for table `gangbuilder_territories`
--
ALTER TABLE `gangbuilder_territories`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;

--
-- AUTO_INCREMENT for table `job2_grades`
--
ALTER TABLE `job2_grades`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;

--
-- AUTO_INCREMENT for table `jobbuilder_announces`
--
ALTER TABLE `jobbuilder_announces`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;

--
-- AUTO_INCREMENT for table `jobbuilder_bank_clients`
--
ALTER TABLE `jobbuilder_bank_clients`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;

--
-- AUTO_INCREMENT for table `jobbuilder_bank_entries`
--
ALTER TABLE `jobbuilder_bank_entries`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;

--
-- AUTO_INCREMENT for table `jobbuilder_bank_loans`
--
ALTER TABLE `jobbuilder_bank_loans`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;

--
-- AUTO_INCREMENT for table `jobbuilder_dealer_sales`
--
ALTER TABLE `jobbuilder_dealer_sales`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `jobbuilder_dealer_vehicles`
--
ALTER TABLE `jobbuilder_dealer_vehicles`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `jobbuilder_logs`
--
ALTER TABLE `jobbuilder_logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;

--
-- AUTO_INCREMENT for table `jobbuilder_patients`
--
ALTER TABLE `jobbuilder_patients`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `jobbuilder_patient_entries`
--
ALTER TABLE `jobbuilder_patient_entries`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `jobbuilder_points`
--
ALTER TABLE `jobbuilder_points`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;

--
-- AUTO_INCREMENT for table `jobbuilder_properties`
--
ALTER TABLE `jobbuilder_properties`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `jobbuilder_property_history`
--
ALTER TABLE `jobbuilder_property_history`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `jobbuilder_property_outfits`
--
ALTER TABLE `jobbuilder_property_outfits`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `jobbuilder_property_points`
--
ALTER TABLE `jobbuilder_property_points`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `jobbuilder_records`
--
ALTER TABLE `jobbuilder_records`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;

--
-- AUTO_INCREMENT for table `jobbuilder_record_entries`
--
ALTER TABLE `jobbuilder_record_entries`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;

--
-- AUTO_INCREMENT for table `jobbuilder_treasury_log`
--
ALTER TABLE `jobbuilder_treasury_log`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `job_grades`
--
ALTER TABLE `job_grades`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;

--
-- AUTO_INCREMENT for table `leboncoin`
--
ALTER TABLE `leboncoin`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `lotery`
--
ALTER TABLE `lotery`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `open_car`
--
ALTER TABLE `open_car`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;

--
-- AUTO_INCREMENT for table `owned_properties`
--
ALTER TABLE `owned_properties`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;

--
-- AUTO_INCREMENT for table `ox_inventory_lockers`
--
ALTER TABLE `ox_inventory_lockers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ox_inventory_locker_casiers`
--
ALTER TABLE `ox_inventory_locker_casiers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ox_inventory_placed_items`
--
ALTER TABLE `ox_inventory_placed_items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `phone_clock_alarms`
--
ALTER TABLE `phone_clock_alarms`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `phone_darkchat_messages`
--
ALTER TABLE `phone_darkchat_messages`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;

--
-- AUTO_INCREMENT for table `phone_mail_messages`
--
ALTER TABLE `phone_mail_messages`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `phone_maps_locations`
--
ALTER TABLE `phone_maps_locations`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `phone_marketplace_posts`
--
ALTER TABLE `phone_marketplace_posts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `phone_message_channels`
--
ALTER TABLE `phone_message_channels`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `phone_message_messages`
--
ALTER TABLE `phone_message_messages`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `phone_music_playlists`
--
ALTER TABLE `phone_music_playlists`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `phone_notes`
--
ALTER TABLE `phone_notes`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `phone_notifications`
--
ALTER TABLE `phone_notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `phone_phone_calls`
--
ALTER TABLE `phone_phone_calls`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `phone_phone_voicemail`
--
ALTER TABLE `phone_phone_voicemail`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `phone_photos`
--
ALTER TABLE `phone_photos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `phone_photo_albums`
--
ALTER TABLE `phone_photo_albums`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `phone_services_channels`
--
ALTER TABLE `phone_services_channels`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `phone_services_messages`
--
ALTER TABLE `phone_services_messages`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `phone_tiktok_notifications`
--
ALTER TABLE `phone_tiktok_notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `phone_tinder_messages`
--
ALTER TABLE `phone_tinder_messages`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `phone_voice_memos_recordings`
--
ALTER TABLE `phone_voice_memos_recordings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `phone_wallet_transactions`
--
ALTER TABLE `phone_wallet_transactions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `phone_yellow_pages_posts`
--
ALTER TABLE `phone_yellow_pages_posts`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `pickax_chase_npcs`
--
ALTER TABLE `pickax_chase_npcs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;

--
-- AUTO_INCREMENT for table `p_outfits`
--
ALTER TABLE `p_outfits`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;

--
-- AUTO_INCREMENT for table `shopbuilder_logs`
--
ALTER TABLE `shopbuilder_logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;

--
-- AUTO_INCREMENT for table `shopbuilder_shops`
--
ALTER TABLE `shopbuilder_shops`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;

--
-- AUTO_INCREMENT for table `society`
--
ALTER TABLE `society`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `boutique_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;

--
-- AUTO_INCREMENT for table `user_licenses`
--
ALTER TABLE `user_licenses`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;

--
-- AUTO_INCREMENT for table `worldbuilder_entities`
--
ALTER TABLE `worldbuilder_entities`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;

--
-- AUTO_INCREMENT for table `worldbuilder_listings`
--
ALTER TABLE `worldbuilder_listings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;

--
-- AUTO_INCREMENT for table `worldbuilder_logs`
--
ALTER TABLE `worldbuilder_logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;

--
-- AUTO_INCREMENT for table `worldbuilder_payouts`
--
ALTER TABLE `worldbuilder_payouts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `jobbuilder_bank_entries`
--
ALTER TABLE `jobbuilder_bank_entries`
  ADD CONSTRAINT `fk_jobbuilder_bank_entries_1` FOREIGN KEY (`client_id`) REFERENCES `jobbuilder_bank_clients` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `jobbuilder_bank_loans`
--
ALTER TABLE `jobbuilder_bank_loans`
  ADD CONSTRAINT `fk_jobbuilder_bank_loans_1` FOREIGN KEY (`client_id`) REFERENCES `jobbuilder_bank_clients` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `jobbuilder_patient_entries`
--
ALTER TABLE `jobbuilder_patient_entries`
  ADD CONSTRAINT `fk_jobbuilder_patient_entries_1` FOREIGN KEY (`patient_id`) REFERENCES `jobbuilder_patients` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `jobbuilder_property_points`
--
ALTER TABLE `jobbuilder_property_points`
  ADD CONSTRAINT `fk_jobbuilder_property_points_1` FOREIGN KEY (`property_id`) REFERENCES `jobbuilder_properties` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `jobbuilder_record_entries`
--
ALTER TABLE `jobbuilder_record_entries`
  ADD CONSTRAINT `fk_jobbuilder_record_entries_1` FOREIGN KEY (`record_id`) REFERENCES `jobbuilder_records` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `phone_backups`
--
ALTER TABLE `phone_backups`
  ADD CONSTRAINT `fk_phone_backups_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_clock_alarms`
--
ALTER TABLE `phone_clock_alarms`
  ADD CONSTRAINT `fk_phone_clock_alarms_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_darkchat_accounts`
--
ALTER TABLE `phone_darkchat_accounts`
  ADD CONSTRAINT `fk_phone_darkchat_accounts_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_darkchat_members`
--
ALTER TABLE `phone_darkchat_members`
  ADD CONSTRAINT `fk_phone_darkchat_members_1` FOREIGN KEY (`channel_name`) REFERENCES `phone_darkchat_channels` (`name`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_phone_darkchat_members_2` FOREIGN KEY (`username`) REFERENCES `phone_darkchat_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_darkchat_messages`
--
ALTER TABLE `phone_darkchat_messages`
  ADD CONSTRAINT `fk_phone_darkchat_messages_1` FOREIGN KEY (`channel`) REFERENCES `phone_darkchat_channels` (`name`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_phone_darkchat_messages_2` FOREIGN KEY (`sender`) REFERENCES `phone_darkchat_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_instagram_accounts`
--
ALTER TABLE `phone_instagram_accounts`
  ADD CONSTRAINT `fk_phone_instagram_accounts_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_instagram_comments`
--
ALTER TABLE `phone_instagram_comments`
  ADD CONSTRAINT `fk_phone_instagram_comments_1` FOREIGN KEY (`post_id`) REFERENCES `phone_instagram_posts` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_phone_instagram_comments_2` FOREIGN KEY (`username`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_instagram_follows`
--
ALTER TABLE `phone_instagram_follows`
  ADD CONSTRAINT `fk_phone_instagram_follows_1` FOREIGN KEY (`followed`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_phone_instagram_follows_2` FOREIGN KEY (`follower`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_instagram_follow_requests`
--
ALTER TABLE `phone_instagram_follow_requests`
  ADD CONSTRAINT `fk_phone_instagram_follow_requests_1` FOREIGN KEY (`requester`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_phone_instagram_follow_requests_2` FOREIGN KEY (`requestee`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_instagram_likes`
--
ALTER TABLE `phone_instagram_likes`
  ADD CONSTRAINT `fk_phone_instagram_likes_1` FOREIGN KEY (`username`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_instagram_messages`
--
ALTER TABLE `phone_instagram_messages`
  ADD CONSTRAINT `fk_phone_instagram_messages_1` FOREIGN KEY (`sender`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_phone_instagram_messages_2` FOREIGN KEY (`recipient`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_instagram_notifications`
--
ALTER TABLE `phone_instagram_notifications`
  ADD CONSTRAINT `fk_phone_instagram_notifications_1` FOREIGN KEY (`username`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_phone_instagram_notifications_2` FOREIGN KEY (`from`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_instagram_posts`
--
ALTER TABLE `phone_instagram_posts`
  ADD CONSTRAINT `fk_phone_instagram_posts_1` FOREIGN KEY (`username`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_instagram_stories`
--
ALTER TABLE `phone_instagram_stories`
  ADD CONSTRAINT `fk_phone_instagram_stories_1` FOREIGN KEY (`username`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_instagram_stories_views`
--
ALTER TABLE `phone_instagram_stories_views`
  ADD CONSTRAINT `fk_phone_instagram_stories_views_1` FOREIGN KEY (`story_id`) REFERENCES `phone_instagram_stories` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_phone_instagram_stories_views_2` FOREIGN KEY (`viewer`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_last_phone`
--
ALTER TABLE `phone_last_phone`
  ADD CONSTRAINT `fk_phone_last_phone_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_logged_in_accounts`
--
ALTER TABLE `phone_logged_in_accounts`
  ADD CONSTRAINT `fk_phone_logged_in_accounts_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_mail_deleted`
--
ALTER TABLE `phone_mail_deleted`
  ADD CONSTRAINT `fk_phone_mail_deleted_1` FOREIGN KEY (`message_id`) REFERENCES `phone_mail_messages` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_phone_mail_deleted_2` FOREIGN KEY (`address`) REFERENCES `phone_mail_accounts` (`address`) ON DELETE CASCADE;

--
-- Constraints for table `phone_maps_locations`
--
ALTER TABLE `phone_maps_locations`
  ADD CONSTRAINT `fk_phone_maps_locations_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_marketplace_posts`
--
ALTER TABLE `phone_marketplace_posts`
  ADD CONSTRAINT `fk_phone_marketplace_posts_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_message_members`
--
ALTER TABLE `phone_message_members`
  ADD CONSTRAINT `fk_phone_message_members_1` FOREIGN KEY (`channel_id`) REFERENCES `phone_message_channels` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_message_messages`
--
ALTER TABLE `phone_message_messages`
  ADD CONSTRAINT `fk_phone_message_messages_1` FOREIGN KEY (`channel_id`) REFERENCES `phone_message_channels` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_message_reactions`
--
ALTER TABLE `phone_message_reactions`
  ADD CONSTRAINT `fk_phone_message_reactions_1` FOREIGN KEY (`message_id`) REFERENCES `phone_message_messages` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_phone_message_reactions_2` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_music_playlists`
--
ALTER TABLE `phone_music_playlists`
  ADD CONSTRAINT `fk_phone_music_playlists_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_music_saved_playlists`
--
ALTER TABLE `phone_music_saved_playlists`
  ADD CONSTRAINT `fk_phone_music_saved_playlists_1` FOREIGN KEY (`playlist_id`) REFERENCES `phone_music_playlists` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_phone_music_saved_playlists_2` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_music_songs`
--
ALTER TABLE `phone_music_songs`
  ADD CONSTRAINT `fk_phone_music_songs_1` FOREIGN KEY (`playlist_id`) REFERENCES `phone_music_playlists` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `phone_notes`
--
ALTER TABLE `phone_notes`
  ADD CONSTRAINT `fk_phone_notes_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_notifications`
--
ALTER TABLE `phone_notifications`
  ADD CONSTRAINT `fk_phone_notifications_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_photos`
--
ALTER TABLE `phone_photos`
  ADD CONSTRAINT `fk_phone_photos_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_photo_albums`
--
ALTER TABLE `phone_photo_albums`
  ADD CONSTRAINT `fk_phone_photo_albums_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_photo_album_members`
--
ALTER TABLE `phone_photo_album_members`
  ADD CONSTRAINT `fk_phone_photo_album_members_1` FOREIGN KEY (`album_id`) REFERENCES `phone_photo_albums` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_phone_photo_album_members_2` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_photo_album_photos`
--
ALTER TABLE `phone_photo_album_photos`
  ADD CONSTRAINT `fk_phone_photo_album_photos_1` FOREIGN KEY (`album_id`) REFERENCES `phone_photo_albums` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_phone_photo_album_photos_2` FOREIGN KEY (`photo_id`) REFERENCES `phone_photos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_services_messages`
--
ALTER TABLE `phone_services_messages`
  ADD CONSTRAINT `fk_phone_services_messages_1` FOREIGN KEY (`channel_id`) REFERENCES `phone_services_channels` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `phone_tiktok_accounts`
--
ALTER TABLE `phone_tiktok_accounts`
  ADD CONSTRAINT `fk_phone_tiktok_accounts_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_tiktok_channels`
--
ALTER TABLE `phone_tiktok_channels`
  ADD CONSTRAINT `fk_phone_tiktok_channels_1` FOREIGN KEY (`member_1`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_phone_tiktok_channels_2` FOREIGN KEY (`member_2`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_tiktok_comments`
--
ALTER TABLE `phone_tiktok_comments`
  ADD CONSTRAINT `fk_phone_tiktok_comments_1` FOREIGN KEY (`video_id`) REFERENCES `phone_tiktok_videos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_phone_tiktok_comments_2` FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_phone_tiktok_comments_3` FOREIGN KEY (`reply_to`) REFERENCES `phone_tiktok_comments` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_tiktok_comments_likes`
--
ALTER TABLE `phone_tiktok_comments_likes`
  ADD CONSTRAINT `fk_phone_tiktok_comments_likes_1` FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_phone_tiktok_comments_likes_2` FOREIGN KEY (`comment_id`) REFERENCES `phone_tiktok_comments` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_tiktok_follows`
--
ALTER TABLE `phone_tiktok_follows`
  ADD CONSTRAINT `fk_phone_tiktok_follows_1` FOREIGN KEY (`followed`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_phone_tiktok_follows_2` FOREIGN KEY (`follower`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_tiktok_likes`
--
ALTER TABLE `phone_tiktok_likes`
  ADD CONSTRAINT `fk_phone_tiktok_likes_1` FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_phone_tiktok_likes_2` FOREIGN KEY (`video_id`) REFERENCES `phone_tiktok_videos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_tiktok_messages`
--
ALTER TABLE `phone_tiktok_messages`
  ADD CONSTRAINT `fk_phone_tiktok_messages_1` FOREIGN KEY (`channel_id`) REFERENCES `phone_tiktok_channels` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_phone_tiktok_messages_2` FOREIGN KEY (`sender`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_tiktok_notifications`
--
ALTER TABLE `phone_tiktok_notifications`
  ADD CONSTRAINT `fk_phone_tiktok_notifications_1` FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_phone_tiktok_notifications_2` FOREIGN KEY (`from`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_phone_tiktok_notifications_3` FOREIGN KEY (`video_id`) REFERENCES `phone_tiktok_videos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_phone_tiktok_notifications_4` FOREIGN KEY (`comment_id`) REFERENCES `phone_tiktok_comments` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_tiktok_pinned_videos`
--
ALTER TABLE `phone_tiktok_pinned_videos`
  ADD CONSTRAINT `fk_phone_tiktok_pinned_videos_1` FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_phone_tiktok_pinned_videos_2` FOREIGN KEY (`video_id`) REFERENCES `phone_tiktok_videos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_tiktok_saves`
--
ALTER TABLE `phone_tiktok_saves`
  ADD CONSTRAINT `fk_phone_tiktok_saves_1` FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_phone_tiktok_saves_2` FOREIGN KEY (`video_id`) REFERENCES `phone_tiktok_videos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_tiktok_unread_messages`
--
ALTER TABLE `phone_tiktok_unread_messages`
  ADD CONSTRAINT `fk_phone_tiktok_unread_messages_1` FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_phone_tiktok_unread_messages_2` FOREIGN KEY (`channel_id`) REFERENCES `phone_tiktok_channels` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_tiktok_videos`
--
ALTER TABLE `phone_tiktok_videos`
  ADD CONSTRAINT `fk_phone_tiktok_videos_1` FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_tiktok_views`
--
ALTER TABLE `phone_tiktok_views`
  ADD CONSTRAINT `fk_phone_tiktok_views_1` FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_phone_tiktok_views_2` FOREIGN KEY (`video_id`) REFERENCES `phone_tiktok_videos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_tinder_accounts`
--
ALTER TABLE `phone_tinder_accounts`
  ADD CONSTRAINT `fk_phone_tinder_accounts_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_tinder_matches`
--
ALTER TABLE `phone_tinder_matches`
  ADD CONSTRAINT `fk_phone_tinder_matches_1` FOREIGN KEY (`phone_number_1`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_phone_tinder_matches_2` FOREIGN KEY (`phone_number_2`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_tinder_messages`
--
ALTER TABLE `phone_tinder_messages`
  ADD CONSTRAINT `fk_phone_tinder_messages_1` FOREIGN KEY (`sender`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_phone_tinder_messages_2` FOREIGN KEY (`recipient`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_tinder_swipes`
--
ALTER TABLE `phone_tinder_swipes`
  ADD CONSTRAINT `fk_phone_tinder_swipes_1` FOREIGN KEY (`swiper`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_phone_tinder_swipes_2` FOREIGN KEY (`swipee`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_twitter_accounts`
--
ALTER TABLE `phone_twitter_accounts`
  ADD CONSTRAINT `fk_phone_twitter_accounts_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_twitter_follows`
--
ALTER TABLE `phone_twitter_follows`
  ADD CONSTRAINT `fk_phone_twitter_follows_1` FOREIGN KEY (`followed`) REFERENCES `phone_twitter_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_phone_twitter_follows_2` FOREIGN KEY (`follower`) REFERENCES `phone_twitter_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_twitter_follow_requests`
--
ALTER TABLE `phone_twitter_follow_requests`
  ADD CONSTRAINT `fk_phone_twitter_follow_requests_1` FOREIGN KEY (`requester`) REFERENCES `phone_twitter_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_phone_twitter_follow_requests_2` FOREIGN KEY (`requestee`) REFERENCES `phone_twitter_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_twitter_likes`
--
ALTER TABLE `phone_twitter_likes`
  ADD CONSTRAINT `fk_phone_twitter_likes_1` FOREIGN KEY (`username`) REFERENCES `phone_twitter_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_twitter_messages`
--
ALTER TABLE `phone_twitter_messages`
  ADD CONSTRAINT `fk_phone_twitter_messages_1` FOREIGN KEY (`sender`) REFERENCES `phone_twitter_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_phone_twitter_messages_2` FOREIGN KEY (`recipient`) REFERENCES `phone_twitter_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_twitter_notifications`
--
ALTER TABLE `phone_twitter_notifications`
  ADD CONSTRAINT `fk_phone_twitter_notifications_1` FOREIGN KEY (`username`) REFERENCES `phone_twitter_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_phone_twitter_notifications_2` FOREIGN KEY (`from`) REFERENCES `phone_twitter_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_twitter_promoted`
--
ALTER TABLE `phone_twitter_promoted`
  ADD CONSTRAINT `fk_phone_twitter_promoted_1` FOREIGN KEY (`tweet_id`) REFERENCES `phone_twitter_tweets` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `phone_twitter_retweets`
--
ALTER TABLE `phone_twitter_retweets`
  ADD CONSTRAINT `fk_phone_twitter_retweets_1` FOREIGN KEY (`username`) REFERENCES `phone_twitter_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_twitter_tweets`
--
ALTER TABLE `phone_twitter_tweets`
  ADD CONSTRAINT `fk_phone_twitter_tweets_1` FOREIGN KEY (`username`) REFERENCES `phone_twitter_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_voice_memos_recordings`
--
ALTER TABLE `phone_voice_memos_recordings`
  ADD CONSTRAINT `fk_phone_voice_memos_recordings_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_wallet_transactions`
--
ALTER TABLE `phone_wallet_transactions`
  ADD CONSTRAINT `fk_phone_wallet_transactions_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

-- ============================================================================
-- CORRECTIFS DE STRUCTURE
-- ============================================================================
-- Un seul enregistrement de raccourcis / d'emprisonnement par joueur
ALTER TABLE `dpkeybinds` MODIFY `id` varchar(50) NOT NULL, ADD PRIMARY KEY (`id`);
ALTER TABLE `jail` ADD PRIMARY KEY (`identifier`);
-- esx_identity : colonne nationalité
ALTER TABLE `users` ADD COLUMN IF NOT EXISTS `nationality` varchar(50) NULL DEFAULT NULL;

-- ============================================================================
-- DONNÉES DE RÉFÉRENCE (aucune donnée joueur)
-- ============================================================================
SET FOREIGN_KEY_CHECKS=0;
INSERT INTO `jobs` (`name`, `label`, `whitelisted`) VALUES
('unemployed', 'Chomeur', '0');
INSERT INTO `job_grades` (`job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES
('unemployed', '0', 'unemployed', 'RSA', '25', '{}', '{}');
INSERT INTO `jobs2` (`name`, `label`) VALUES
('unemployed2', 'Unemployed2');
INSERT INTO `job2_grades` (`job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES
('unemployed2', '0', 'unemployed2', 'Unemployed2', '200', '{}', '{}');
INSERT INTO `licenses` (`type`, `label`) VALUES
('code', 'Code de la route'),
('drive', 'Permis de conduire'),
('drive_bike', 'Permis moto'),
('drive_truck', 'Permis camion'),
('weapon', 'PPA');
INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`) VALUES
('armor', 'Kevlar', '3', '0', '1'),
('bandage', 'Bandage', '0.2', '0', '1'),
('basic_cuff', 'Menottes Basique', '0.3', '0', '1'),
('basic_key', 'Clefs de Menottes Basique', '0.1', '0', '1'),
('beer', 'Bière', '0.1', '0', '1'),
('blowpipe', 'Chalumeaux', '1.5', '0', '1'),
('bread', 'Pain', '0.1', '0', '1'),
('burger', 'Burger', '0.3', '0', '1'),
('carokit', 'Kit carosserie', '3', '0', '1'),
('carotool', 'Outils carosserie', '4', '0', '1'),
('chip', 'Jeton', '0', '0', '1'),
('cigarette', 'Cigarette', '0.1', '0', '1'),
('clip', 'Chargeur', '0.3', '0', '1'),
('coca', 'Coca', '0.1', '0', '1'),
('coke', 'Coke', '1', '0', '1'),
('coke_pooch', 'Pochon de coke', '0.25', '0', '1'),
('cola', 'Cola', '0.2', '0', '1'),
('corde', 'Corde', '2', '0', '1'),
('defibrillateur', 'Défibrillateur', '2', '0', '1'),
('feuille_coca', 'Feuille de coca', '1', '0', '1'),
('firstaidkit', 'Trousse premier secours', '1', '0', '1'),
('fixkit', 'Kit réparation', '1.5', '0', '1'),
('fixtool', 'Outils réparation', '2', '0', '1'),
('gazbottle', 'Bouteille de gaz', '2', '0', '1'),
('gitanes', 'Gitanes', '0.1', '0', '1'),
('grand_cru', 'Grand cru', '0.2', '0', '1'),
('grapperaisin', 'Grappe de raisin', '0.3', '0', '1'),
('handcuff', 'Serre câble ', '0.3', '0', '1'),
('ice', 'Glaçon', '0.1', '0', '1'),
('jager', 'Jägermeister', '0.5', '0', '1'),
('jagerbomb', 'Jägermeister', '0.5', '0', '1'),
('jagercerbere', 'Jäger Cerbère', '0.5', '0', '1'),
('jumelles', 'Jumelles', '0.25', '0', '1'),
('yusuf', 'Skin de Luxe', '4', '0', '1'),
('grip', 'Poignée', '1', '0', '1'),
('magazine', 'Chargeur agrandi', '2', '0', '1'),
('silencieux', 'Silencieux', '1', '0', '1'),
('flashlight', 'Lampe', '1', '0', '1'),
('scope', 'Viseur', '1', '0', '1'),
('jus_coca', 'Jus de coca', '0.5', '0', '1'),
('jus_raisin', 'Jus de raisin', '0.5', '0', '1'),
('jusfruit', 'Jus de fruits', '0.5', '0', '1'),
('limonade', 'Limonade', '0.5', '0', '1'),
('lockpick', 'Pied de Biche', '1', '0', '1'),
('malbora', 'Malboro', '0.1', '0', '1'),
('martini', 'Martini blanc', '1', '0', '1'),
('meat', 'Viande', '0.3', '0', '1'),
('medikit', 'Medikit', '2', '0', '1'),
('menthe', 'Feuille de menthe', '1', '0', '1'),
('meth', 'Meth', '1', '0', '1'),
('meth_pooch', 'Pochon de meth', '0.25', '0', '1'),
('metreshooter', 'Mètre de shooter', '0.1', '0', '1'),
('mixapero', 'Mix Apéritif', '0.1', '0', '1'),
('mojito', 'Mojito', '0.1', '0', '1'),
('opium', 'Opium', '1', '0', '1'),
('opium_pooch', 'Pochon d''opium', '0.25', '0', '1'),
('orange', 'Orange', '0.1', '0', '1'),
('orange_juice', 'Jus d''orange', '0.3', '0', '1'),
('oxygen_mask', 'Masque à Oxygène', '0.6', '0', '1'),
('pepperspray', 'Gazeuse', '1', '0', '-1'),
('phone', 'Téléphone', '0.3', '0', '1'),
('piluleoubli', 'GHB', '1', '0', '1'),
('pomme', 'Pomme', '0.1', '0', '1'),
('radio', 'Radio', '0.5', '0', '1'),
('raisin', 'Raisin', '0.3', '0', '1'),
('redbull', 'Redbull', '0.3', '0', '1'),
('repairkit', 'Repairkit', '2', '0', '1'),
('rhum', 'Rhum', '0.4', '0', '1'),
('rhumcoca', 'Rhum-Coca', '0.5', '0', '1'),
('rhumfruit', 'Rhum-Jus de fruits', '0.5', '0', '1'),
('tabac', 'Tabac', '0.5', '0', '1'),
('tabacblond', 'Tabac Blond', '0.5', '0', '1'),
('tabacblondsec', 'Tabac Blond Séché', '0.5', '0', '1'),
('tabacbrun', 'Tabac Brun', '0.5', '0', '1'),
('tabacbrunsec', 'Tabac Brun Séché', '0.5', '0', '1'),
('tarte_pomme', 'Tarte aux Pommes', '0.3', '0', '1'),
('teqpaf', 'Teq''paf', '0.5', '0', '1'),
('tequila', 'Tequila', '0.5', '0', '1'),
('vine', 'Vin', '0.5', '0', '1'),
('vittvin', 'Vin Blanc', '0.5', '0', '1'),
('vodka', 'Vodka', '0.3', '0', '1'),
('vodkaenergy', 'Vodka-Energy', '0.4', '0', '1'),
('vodkafruit', 'Vodka-Jus de fruits', '0.3', '0', '1'),
('vodkaredbull', 'Vodka-Redbull', '0.3', '0', '1'),
('water', 'Bouteille d''eau', '0.1', '0', '1'),
('weed', 'Weed', '1', '0', '1'),
('weed_pooch', 'Pochon de weed', '0.25', '0', '1'),
('whisky', 'Whisky', '0.4', '0', '1'),
('whiskycoca', 'Whisky-coca', '0.5', '0', '1'),
('gym_membership', 'Pass membre GYM', '0.5', '0', '1'),
('fishingrod', 'Canne à pêche', '0.5', '0', '1'),
('macro', 'Macro', '0.5', '0', '1'),
('bar', 'Bar', '0.5', '0', '1'),
('dorade', 'Dorade', '0.5', '0', '1'),
('lieu', 'Lieu', '0.5', '0', '1'),
('raie', 'Raie', '0.5', '0', '1'),
('sardine', 'Sardine', '0.5', '0', '1'),
('saumon', 'Saumon', '0.5', '0', '1'),
('thon', 'Thon', '0.5', '0', '1'),
('requin', 'Requin', '2', '0', '1'),
('zetony', 'Jetons', '-1', '0', '1');
INSERT INTO `vehicle_categories` (`name`, `label`) VALUES
('compacts', 'Compacts'),
('coupes', 'Coupés'),
('muscle', 'Muscle'),
('offroad', 'Off Road'),
('sedans', 'Sedans'),
('sports', 'Sports'),
('sportsclassics', 'Sports Classics'),
('super', 'Super'),
('suvs', 'SUVs'),
('vans', 'Vans'),
('imports', 'Imports'),
('dlc', 'Dlc'),
('motorcycles', 'Motos'),
('Motosimports', 'Moto Importées'),
('velo', 'Vélo'),
('boat', 'Boats'),
('subs', 'Submersibles');
INSERT INTO `vehicles` (`name`, `model`, `price`, `category`) VALUES
('Adder', 'adder', '900000', 'super'),
('Alpha', 'alpha', '75000', 'sports'),
('Asbo', 'asbo', '20000', 'dlc'),
('Asea', 'asea', '15000', 'sedans'),
('Autarch', 'autarch', '1955000', 'super'),
('Baller', 'baller2', '80000', 'suvs'),
('Baller Sport', 'baller3', '120000', 'suvs'),
('Banshee', 'banshee', '80000', 'sports'),
('Banshee 900R', 'banshee2', '255000', 'super'),
('Bestia GTS', 'bestiagts', '95000', 'sports'),
('Bf Injection', 'bfinjection', '35400', 'offroad'),
('Bifta', 'bifta', '40000', 'offroad'),
('Bison', 'bison', '43000', 'vans'),
('Blade', 'blade', '25000', 'muscle'),
('Blazer', 'blazer', '22500', 'offroad'),
('Blazer Sport', 'blazer4', '35000', 'offroad'),
('Blista', 'blista', '8000', 'compacts'),
('Bobcat XL', 'bobcatxl', '35000', 'vans'),
('Brawler', 'brawler', '80000', 'offroad'),
('Brioso R/A', 'brioso', '18000', 'compacts'),
('Brioso 300', 'brioso2', '25000', 'dlc'),
('Btype', 'btype', '110000', 'sportsclassics'),
('Btype Hotroad', 'btype2', '140000', 'sportsclassics'),
('Btype Luxe', 'btype3', '167000', 'sportsclassics'),
('Buccaneer', 'buccaneer', '20000', 'muscle'),
('Buccaneer Rider', 'buccaneer2', '28000', 'muscle'),
('Buffalo', 'buffalo', '37500', 'sports'),
('Buffalo S', 'buffalo2', '40000', 'sports'),
('Bullet', 'bullet', '90000', 'super'),
('Burrito', 'burrito3', '40000', 'vans'),
('Camper', 'camper', '45000', 'vans'),
('Carbonizzare', 'carbonizzare', '68900', 'sports'),
('Casco', 'casco', '67800', 'sportsclassics'),
('Cavalcade', 'cavalcade2', '30000', 'suvs'),
('Cheetah', 'cheetah', '375000', 'super'),
('Chino', 'chino', '27500', 'muscle'),
('Chino Luxe', 'chino2', '30000', 'muscle'),
('Cognoscenti Cabrio', 'cogcabrio', '30000', 'coupes'),
('Cognoscenti', 'cognoscenti', '55000', 'sedans'),
('Comet', 'comet2', '115000', 'sports'),
('Comet 5', 'comet5', '145000', 'sports'),
('Contender', 'contender', '70000', 'suvs'),
('Coquette', 'coquette', '135000', 'sports'),
('Coquette Classic', 'coquette2', '40000', 'dlc'),
('Coquette BlackFin', 'coquette3', '50000', 'muscle'),
('Cyclone', 'cyclone', '1890000', 'super'),
('Dominator', 'dominator', '50000', 'muscle'),
('8F Drafter', 'drafter', '190000', 'dlc'),
('Dubsta', 'dubsta', '75000', 'suvs'),
('Dubsta Luxuary', 'dubsta2', '100000', 'suvs'),
('Bubsta 6x6', 'dubsta3', '150000', 'offroad'),
('Dukes', 'dukes', '22500', 'muscle'),
('Dune Buggy', 'dune', '30000', 'offroad'),
('Dynasty', 'Dynasty', '25000', 'dlc'),
('Elegy', 'elegy2', '105000', 'sports'),
('Emerus', 'emerus', '300000', 'dlc'),
('Emperor', 'emperor', '10000', 'sedans'),
('Entity XF', 'entityxf', '425000', 'super'),
('Everon', 'everon', '80000', 'dlc'),
('Exemplar', 'exemplar', '40000', 'coupes'),
('F620', 'f620', '45000', 'coupes'),
('Faction', 'faction', '25000', 'muscle'),
('Faction Rider', 'faction2', '34500', 'muscle'),
('Faction XL', 'faction3', '145000', 'muscle'),
('Felon', 'felon', '37500', 'coupes'),
('Felon GT', 'felon2', '45000', 'coupes'),
('Feltzer', 'feltzer2', '75000', 'sports'),
('Stirling GT', 'feltzer3', '115000', 'sportsclassics'),
('FMJ', 'fmj', '285000', 'super'),
('Fhantom', 'fq2', '125000', 'suvs'),
('Fugitive', 'fugitive', '32000', 'sedans'),
('Furia', 'furia', '225000', 'dlc'),
('Furore GT', 'furoregt', '92000', 'sports'),
('Fusilade', 'fusilade', '55000', 'sports'),
('Gauntlet', 'gauntlet', '42000', 'muscle'),
('Gauntlet Classic', 'gauntlet3', '110000', 'dlc'),
('Gauntlet Hellfire', 'gauntlet4', '90000', 'dlc'),
('Gang Burrito', 'gburrito', '45000', 'vans'),
('Burrito', 'gburrito2', '42555', 'vans'),
('Glendale', 'glendale', '17500', 'sedans'),
('Grabger', 'granger', '50000', 'suvs'),
('Gresley', 'gresley', '42000', 'suvs'),
('GT 500', 'gt500', '132300', 'sportsclassics'),
('Guardian', 'guardian', '62500', 'offroad'),
('Hellion', 'hellion', '125000', 'dlc'),
('Hermes', 'hermes', '62340', 'muscle'),
('Hotknife', 'hotknife', '75000', 'muscle'),
('Huntley S', 'huntley', '35000', 'suvs'),
('Hustler', 'hustler', '85000', 'muscle'),
('Imorgon', 'imorgon', '125000', 'dlc'),
('Infernus', 'infernus', '180000', 'super'),
('Intruder', 'intruder', '27400', 'sedans'),
('Issi', 'issi2', '10000', 'compacts'),
('Issi Sport', 'issi7', '123000', 'dlc'),
('Itali RSX', 'italirsx', '300000', 'dlc'),
('Jackal', 'jackal', '38000', 'coupes'),
('JB 700W', 'jb7002', '76550', 'dlc'),
('Jester', 'jester', '62000', 'sports'),
('Jester(Racecar)', 'jester2', '80000', 'sports'),
('Journey', 'journey', '12300', 'vans'),
('Jugular', 'jugular', '175000', 'dlc'),
('Kamacho', 'kamacho', '95000', 'offroad'),
('Blista Kanjo', 'kanjo', '58000', 'dlc'),
('Khamelion', 'khamelion', '52500', 'sports'),
('Komoda', 'komoda', '133000', 'dlc'),
('Krieger', 'krieger', '125000', 'dlc'),
('Kuruma', 'kuruma', '135000', 'sports'),
('Landstalker', 'landstalker', '47600', 'suvs'),
('RE-7B', 'le7b', '325000', 'super'),
('Locust', 'locust', '210000', 'dlc'),
('Lynx', 'lynx', '145000', 'sports'),
('Mamba', 'mamba', '95700', 'sports'),
('Manana', 'manana', '34500', 'sportsclassics'),
('Massacro', 'massacro', '78000', 'sports'),
('Massacro(Racecar)', 'massacro2', '100000', 'sports'),
('Mesa', 'mesa', '36000', 'suvs'),
('Mesa Trail', 'mesa3', '40000', 'suvs'),
('Minivan', 'minivan', '35000', 'vans'),
('Monroe', 'monroe', '89000', 'sportsclassics'),
('Moonbeam', 'moonbeam', '50000', 'vans'),
('Moonbeam Rider', 'moonbeam2', '60000', 'vans'),
('Nebula turbo', 'nebula', '25000', 'dlc'),
('Neo', 'neo', '250000', 'dlc'),
('Neon', 'neon', '250000', 'sports'),
('Nightshade', 'nightshade', '65000', 'muscle'),
('9F', 'ninef', '97500', 'sports'),
('9F Cabrio', 'ninef2', '125000', 'sports'),
('Novak', 'Novak', '60000', 'dlc'),
('Omnis', 'omnis', '75000', 'sports'),
('Oracle XS', 'oracle2', '40000', 'coupes'),
('Osiris', 'osiris', '160000', 'super'),
('Outlaw', 'outlaw', '115000', 'dlc'),
('Panto', 'panto', '10000', 'compacts'),
('Paradise', 'paradise', '19000', 'vans'),
('Paragon R', 'paragon', '60000', 'dlc'),
('Pariah', 'pariah', '145000', 'sports'),
('Patriot', 'patriot', '55000', 'suvs'),
('Penumbra', 'penumbra', '64500', 'sports'),
('Peyote Gasser', 'peyote2', '60000', 'dlc'),
('Pfister', 'pfister811', '85000', 'super'),
('Phoenix', 'phoenix', '34500', 'muscle'),
('Picador', 'picador', '32000', 'muscle'),
('Pigalle', 'pigalle', '75600', 'sportsclassics'),
('Prairie', 'prairie', '12000', 'compacts'),
('Premier', 'premier', '13200', 'sedans'),
('Primo Custom', 'primo2', '47500', 'sedans'),
('X80 Proto', 'prototipo', '2500000', 'super'),
('Radius', 'radi', '32500', 'suvs'),
('Raiden', 'raiden', '450000', 'sports'),
('Rapid GT', 'rapidgt', '84500', 'sports'),
('Rapid GT Convertible', 'rapidgt2', '90000', 'sports'),
('Rapid GT3', 'rapidgt3', '60000', 'sportsclassics'),
('Reaper', 'reaper', '150000', 'super'),
('Rebel', 'rebel2', '22000', 'offroad'),
('Rebla GTS', 'rebla', '90000', 'dlc'),
('Regina', 'regina', '12200', 'sedans'),
('Retinue', 'retinue', '55000', 'sportsclassics'),
('Retinue MK ll', 'retinue2', '35000', 'dlc'),
('Revolter', 'revolter', '105000', 'sports'),
('Riata', 'riata', '55000', 'offroad'),
('Rocoto', 'rocoto', '55500', 'suvs'),
('Rumpo', 'rumpo', '25000', 'vans'),
('Rumpo Trail', 'rumpo3', '85000', 'vans'),
('S80RR', 's80', '120000', 'dlc'),
('Sabre Turbo', 'sabregt', '27500', 'muscle'),
('Sabre GT', 'sabregt2', '37500', 'muscle'),
('Sandking', 'sandking', '64000', 'offroad'),
('Savestra', 'savestra', '112000', 'sportsclassics'),
('SC 1', 'sc1', '1603000', 'super'),
('Schafter', 'schafter2', '72500', 'sedans'),
('Schafter V12', 'schafter3', '54600', 'sports'),
('Seminole', 'seminole', '45600', 'suvs'),
('Sentinel', 'sentinel', '35000', 'coupes'),
('Sentinel XS', 'sentinel2', '40000', 'coupes'),
('Sentinel3', 'sentinel3', '42000', 'sports'),
('Seven 70', 'seven70', '420000', 'sports'),
('ETR1', 'sheava', '220000', 'super'),
('Slam Van', 'slamvan3', '37500', 'muscle'),
('Stinger', 'stinger', '92000', 'sportsclassics'),
('Stinger GT', 'stingergt', '120000', 'sportsclassics'),
('Streiter', 'streiter', '130000', 'sports'),
('Stretch', 'stretch', '290000', 'sedans'),
('Sugoi', 'Sugoi', '75000', 'dlc'),
('Sultan', 'sultan', '83400', 'sports'),
('Sultan Classic', 'sultan2', '150000', 'dlc'),
('Sultan RS', 'sultanrs', '65000', 'super'),
('Super Diamond', 'superd', '34500', 'sedans'),
('Surano', 'surano', '72400', 'sports'),
('Surfer', 'surfer', '15000', 'vans'),
('Tailgater', 'tailgater', '24600', 'sedans'),
('Tampa', 'tampa', '43500', 'muscle'),
('Drift Tampa', 'tampa2', '83403', 'sports'),
('Thrax', 'thrax', '300000', 'dlc'),
('Trophy Truck', 'trophytruck', '90000', 'offroad'),
('Trophy Truck Limited', 'trophytruck2', '115000', 'offroad'),
('Tropos', 'tropos', '92300', 'sports'),
('Turismo R', 'turismor', '350000', 'super'),
('Tyrus', 'tyrus', '600000', 'super'),
('Vacca', 'vacca', '120000', 'super'),
('Vagrant', 'vagrant', '50000', 'dlc'),
('Verlierer', 'verlierer2', '75000', 'sports'),
('Verus', 'verus', '15000', 'dlc'),
('Veto Classic', 'veto', '895000', 'dlc'),
('Veto Modern', 'veto2', '995000', 'dlc'),
('Vigero', 'vigero', '41500', 'muscle'),
('Virgo', 'virgo', '33500', 'muscle'),
('Viseris', 'viseris', '200000', 'sportsclassics'),
('Visione', 'visione', '2250000', 'super'),
('Voltic', 'voltic', '90000', 'super'),
('Voltic 2', 'voltic2', '3830400', 'super'),
('Voodoo', 'voodoo', '37500', 'muscle'),
('V-STR', 'vstr', '115000', 'dlc'),
('Warrener', 'warrener', '22000', 'sedans'),
('Washington', 'washington', '19000', 'sedans'),
('Weevil', 'weevil', '87000', 'dlc'),
('Windsor', 'windsor', '95000', 'coupes'),
('Windsor Drop', 'windsor2', '125000', 'coupes'),
('Dominator 3', 'dominator3', '60000', 'muscle'),
('XLS', 'xls', '65000', 'suvs'),
('Yosemite', 'yosemite', '52500', 'muscle'),
('Drift Yosemite', 'yosemite2', '35000', 'dlc'),
('Youga', 'youga', '25000', 'vans'),
('Youga Luxuary', 'youga2', '35000', 'vans'),
('Z190', 'z190', '105000', 'sportsclassics'),
('Zentorno', 'zentorno', '1500000', 'super'),
('Zion', 'zion', '36000', 'coupes'),
('Zion Cabrio', 'zion2', '45000', 'coupes'),
('Zion Classic', 'zion3', '35000', 'dlc'),
('Zorrusso', 'zorrusso', '225000', 'dlc'),
('Z-Type', 'ztype', '125000', 'sportsclassics'),
('Vulcar Warrener HKR', 'warrener2', '25000', 'dlc'),
('Vapid Dominator ASP', 'dominator7', '145000', 'dlc'),
('Vapid Dominator GTT', 'dominator8', '90000', 'dlc'),
('Annis Euros', 'euros', '205000', 'dlc'),
('Karin Futo GTX', 'futo2', '56000', 'dlc'),
('Dinka RT3000', 'rt3000', '145000', 'dlc'),
('Karin Sultan RS Classique', 'sultan3', '150000', 'dlc'),
('Obey Tailgater S', 'tailgater2', '256000', 'dlc'),
('Pfister Growler', 'growler', '280000', 'dlc'),
('Emperor Vectre', 'vectre', '235000', 'dlc'),
('Annis Remus', 'remus', '27500', 'dlc'),
('Karin Calico GTF', 'calico', '200000', 'dlc'),
('Ubermacht Cypher', 'cypher', '200000', 'dlc'),
('Dinka Jester RR', 'jester4', '180000', 'dlc'),
('Annis ZR350', 'zr350', '125000', 'dlc'),
('Karin Previon', 'previon', '125000', 'dlc'),
('Pfister Comet S2', 'comet6', '256000', 'dlc'),
('Akuma', 'AKUMA', '22000', 'motorcycles'),
('Avarus', 'avarus', '17500', 'motorcycles'),
('Bagger', 'bagger', '7500', 'motorcycles'),
('Bati 801', 'bati', '37500', 'motorcycles'),
('Bati 801RR', 'bati2', '45000', 'motorcycles'),
('BF400', 'bf400', '35000', 'motorcycles'),
('Bmx', 'bmx', '500', 'velo'),
('Carbon RS', 'carbonrs', '27500', 'motorcycles'),
('Chimera', 'chimera', '65000', 'motorcycles'),
('Cliffhanger', 'cliffhanger', '35000', 'motorcycles'),
('Cruiser', 'cruiser', '200', 'velo'),
('Daemon', 'daemon', '60000', 'motorcycles'),
('Daemon High', 'daemon2', '70000', 'motorcycles'),
('Defiler', 'defiler', '32500', 'motorcycles'),
('Diabolus', 'diablous', '20000', 'motorcycles'),
('Diabolus Custom', 'diablous2', '20000', 'motorcycles'),
('Double T', 'double', '35000', 'motorcycles'),
('Enduro', 'enduro', '20000', 'motorcycles'),
('Esskey', 'esskey', '27500', 'motorcycles'),
('Faggio', 'faggio', '2500', 'motorcycles'),
('Vespa', 'faggio3', '3000', 'motorcycles'),
('FCR 1000', 'fcr', '1000', 'motorcycles'),
('FCR 1000 custom', 'fcr2', '1000', 'motorcycles'),
('Fixter', 'fixter', '400', 'velo'),
('Gargoyle', 'gargoyle', '80000', 'motorcycles'),
('Hakuchou', 'hakuchou', '110000', 'motorcycles'),
('Hakuchou Sport', 'hakuchou2', '100000', 'motorcycles'),
('Hexer', 'hexer', '40000', 'motorcycles'),
('Innovation', 'innovation', '42000', 'motorcycles'),
('Manchez', 'manchez', '45000', 'motorcycles'),
('Manchez Scout', 'manchez2', '22500', 'dlc'),
('Nemesis', 'nemesis', '24000', 'motorcycles'),
('Nightblade', 'nightblade', '55000', 'motorcycles'),
('PCJ-600', 'pcj', '15500', 'motorcycles'),
('R6', 'R6', '50000', 'Motosimports'),
('Rat biker', 'ratbike', '14500', 'motorcycles'),
('Rampant Rocket', 'rrocket', '110000', 'dlc'),
('Ruffian', 'ruffian', '17550', 'motorcycles'),
('Sanchez', 'sanchez', '30000', 'motorcycles'),
('Sanchez Sport', 'sanchez2', '35000', 'motorcycles'),
('Sanctus', 'sanctus', '75000', 'motorcycles'),
('Scorcher', 'scorcher', '800', 'velo'),
('Sovereign', 'sovereign', '52000', 'motorcycles'),
('Thrust', 'thrust', '22000', 'motorcycles'),
('tm2019', 'tm2019', '42500', 'Motosimports'),
('Tmax', 'Tmax', '200000', 'Motosimports'),
('Whippet', 'tribike', '500', 'velo'),
('Endurex', 'tribike2', '500', 'velo'),
('Tri-cycles', 'tribike3', '1000', 'velo'),
('Vader', 'vader', '20000', 'motorcycles'),
('Vortex', 'vortex', '32000', 'motorcycles'),
('Woflsbane', 'wolfsbane', '62500', 'motorcycles'),
('Zombie', 'zombiea', '85000', 'motorcycles'),
('Zombie Luxuary', 'zombieb', '95000', 'motorcycles'),
('Dinghy 4Seat', 'dinghy', '25000', 'boat'),
('Dinghy 2Seat', 'dinghy2', '20000', 'boat'),
('Dinghy Yacht', 'dinghy4', '25000', 'boat'),
('Jetmax', 'jetmax', '30000', 'boat'),
('Marquis', 'marquis', '45000', 'boat'),
('Seashark', 'seashark', '10000', 'boat'),
('Seashark Yacht', 'seashark3', '10000', 'boat'),
('Speeder', 'speeder', '40000', 'boat'),
('Squalo', 'squalo', '32000', 'boat'),
('Submarine', 'submersible', '29000', 'subs'),
('Kraken', 'submersible2', '31000', 'subs'),
('Suntrap', 'suntrap', '34000', 'boat'),
('Toro', 'toro', '38000', 'boat'),
('Toro Yacht', 'toro2', '38000', 'boat'),
('Tropic', 'tropic', '27000', 'boat'),
('Tropic Yacht', 'tropic2', '27000', 'boat');
INSERT INTO `pickax_chase_maps` (`id`, `label`, `description`, `x`, `y`, `z`, `h`) VALUES
('freeway', 'Del Perro Freeway', 'Autoroute rapide, idéale pour les supercars.', '-1105', '-520', '34', '215'),
('sandy', 'Route 68 – Sandy', 'Longues lignes droites dans le désert.', '1583', '3584', '35.400001525878906', '300'),
('vinewood', 'Vinewood Boulevard', 'Grandes avenues et carrefours, trafic dense.', '293.1000061035156', '180.5', '104.19999694824219', '70');
INSERT INTO `pickax_chase_vehicles` (`model`, `label`, `category`, `speed`, `accel`, `handling`) VALUES
('adder', 'Truffade Adder', 'Super', '92', '82', '72'),
('akuma', 'Dinka Akuma', 'Moto', '82', '90', '80'),
('bati', 'Pegassi Bati 801', 'Moto', '84', '92', '82'),
('buffalo', 'Bravado Buffalo', 'Berline', '70', '68', '70'),
('comet2', 'Pfister Comet', 'Sportive', '76', '72', '77'),
('dominator', 'Vapid Dominator', 'Muscle', '74', '78', '55'),
('elegy2', 'Annis Elegy RH8', 'Sportive', '74', '70', '78'),
('gauntlet', 'Bravado Gauntlet', 'Muscle', '72', '76', '52'),
('jester', 'Dinka Jester', 'Sportive', '78', '74', '75'),
('kuruma', 'Karin Kuruma', 'Sportive', '72', '70', '70'),
('sanchez', 'Maibatsu Sanchez', 'Moto', '62', '74', '78'),
('schafter3', 'Benefactor Schafter V12', 'Berline', '70', '66', '68'),
('sultan', 'Karin Sultan', 'Sportive', '68', '66', '72'),
('t20', 'Progen T20', 'Super', '93', '90', '78'),
('vacca', 'Pegassi Vacca', 'Super', '86', '84', '78'),
('zentorno', 'Pegassi Zentorno', 'Super', '90', '88', '80');
INSERT INTO `pickax_chase_settings` (`name`, `value`) VALUES
('catchDistance', '8'),
('catchTime', '3'),
('countdown', '5'),
('durationDefault', '8'),
('durationMax', '20'),
('durationMin', '2'),
('headStart', '10'),
('maxChasers', '4'),
('maxPerformance', 'true'),
('requireVehicle', 'true'),
('rewardLose', '100'),
('rewardWin', '500'),
('runnerSeesChasers', 'true');
INSERT INTO `phone_crypto_coins` (`coin`, `coin_value`) VALUES
('lbc', '168.97426545106413');
INSERT INTO `addon_inventory` (`name`, `label`, `shared`) VALUES
('property', 'Propriété', '0'),
('trunk', 'Coffre Véhicule', '0');
INSERT INTO `datastore` (`name`, `label`, `shared`) VALUES
('property', 'Propriété', '0'),
('user_ears', 'Ears', '0'),
('user_glasses', 'Glasses', '0'),
('user_helmet', 'Helmet', '0'),
('user_mask', 'Mask', '0');
CREATE TABLE IF NOT EXISTS `society_moneywash` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(60) NOT NULL,
  `society` varchar(60) NOT NULL,
  `amount` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
SET FOREIGN_KEY_CHECKS=1;
