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
  `last_income` int(11) NOT NULL DEFAULT 0,
  `level` tinyint(4) NOT NULL DEFAULT 1
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
  `category` varchar(20) NOT NULL DEFAULT 'house',
  `description` varchar(300) NOT NULL DEFAULT '',
  `ipl` varchar(300) NOT NULL DEFAULT '',
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
  `expiration` int(11) DEFAULT NULL,
  `last_claim` int(11) NOT NULL DEFAULT 0
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
('unemployed', '0', 'unemployed', 'RSA', '20', '{}', '{}');
INSERT INTO `jobs2` (`name`, `label`) VALUES
('unemployed2', 'Unemployed2');
INSERT INTO `job2_grades` (`job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES
('unemployed2', '0', 'unemployed2', 'Unemployed2', '0', '{}', '{}');
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

-- ═══════════ Smartphone Aero (pickax_phone) ═══════════


-- ── pickax_phone ──
CREATE TABLE IF NOT EXISTS aero_phones (
    identifier VARCHAR(80) NOT NULL PRIMARY KEY,
    number VARCHAR(20) NOT NULL UNIQUE,
    mail VARCHAR(120) NULL,
    settings LONGTEXT NULL,
    apps LONGTEXT NULL,
    battery TINYINT UNSIGNED NOT NULL DEFAULT 100,
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aero_kv (
    owner VARCHAR(80) NOT NULL,
    k VARCHAR(40) NOT NULL,
    v LONGTEXT NULL,
    PRIMARY KEY (owner, k)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aero_contacts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    owner VARCHAR(80) NOT NULL,
    name VARCHAR(60) NOT NULL,
    number VARCHAR(20) NOT NULL,
    email VARCHAR(120) NULL,
    avatar TEXT NULL,
    favorite TINYINT(1) NOT NULL DEFAULT 0,
    blocked TINYINT(1) NOT NULL DEFAULT 0,
    note VARCHAR(255) NULL,
    INDEX (owner)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aero_calls (
    id INT AUTO_INCREMENT PRIMARY KEY,
    caller VARCHAR(20) NOT NULL,
    callee VARCHAR(20) NOT NULL,
    status VARCHAR(12) NOT NULL DEFAULT 'missed',
    duration INT NOT NULL DEFAULT 0,
    hidden TINYINT(1) NOT NULL DEFAULT 0,
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX (caller), INDEX (callee)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aero_conv (
    id VARCHAR(60) NOT NULL PRIMARY KEY,
    kind VARCHAR(8) NOT NULL DEFAULT 'direct',
    name VARCHAR(60) NULL,
    avatar TEXT NULL,
    owner VARCHAR(20) NULL,
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aero_conv_members (
    conv VARCHAR(60) NOT NULL,
    number VARCHAR(20) NOT NULL,
    muted TINYINT(1) NOT NULL DEFAULT 0,
    pinned TINYINT(1) NOT NULL DEFAULT 0,
    hidden TINYINT(1) NOT NULL DEFAULT 0,
    last_read BIGINT NOT NULL DEFAULT 0,
    PRIMARY KEY (conv, number),
    INDEX (number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aero_messages (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    conv VARCHAR(60) NOT NULL,
    sender VARCHAR(20) NOT NULL,
    kind VARCHAR(12) NOT NULL DEFAULT 'text',
    body TEXT NULL,
    meta TEXT NULL,
    reply_to BIGINT NULL,
    reactions TEXT NULL,
    created BIGINT NOT NULL,
    INDEX (conv, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aero_photos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    owner VARCHAR(80) NOT NULL,
    url TEXT NOT NULL,
    kind VARCHAR(8) NOT NULL DEFAULT 'photo',
    favorite TINYINT(1) NOT NULL DEFAULT 0,
    created BIGINT NOT NULL,
    INDEX (owner)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aero_accounts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    app VARCHAR(12) NOT NULL,
    identifier VARCHAR(80) NOT NULL,
    handle VARCHAR(30) NOT NULL,
    display VARCHAR(60) NOT NULL,
    avatar TEXT NULL,
    banner TEXT NULL,
    bio VARCHAR(200) NULL,
    verified TINYINT(1) NOT NULL DEFAULT 0,
    created BIGINT NOT NULL,
    UNIQUE KEY uq_handle (app, handle),
    UNIQUE KEY uq_owner (app, identifier)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aero_posts (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    app VARCHAR(12) NOT NULL,
    handle VARCHAR(30) NOT NULL,
    kind VARCHAR(8) NOT NULL DEFAULT 'post',
    body TEXT NULL,
    images TEXT NULL,
    parent BIGINT NULL,
    repost BIGINT NULL,
    created BIGINT NOT NULL,
    INDEX (app, created), INDEX (parent), INDEX (handle)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aero_likes (
    app VARCHAR(12) NOT NULL,
    post BIGINT NOT NULL,
    handle VARCHAR(30) NOT NULL,
    PRIMARY KEY (app, post, handle)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aero_follows (
    app VARCHAR(12) NOT NULL,
    follower VARCHAR(30) NOT NULL,
    followee VARCHAR(30) NOT NULL,
    PRIMARY KEY (app, follower, followee)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aero_match (
    identifier VARCHAR(80) NOT NULL PRIMARY KEY,
    name VARCHAR(40) NOT NULL,
    age TINYINT UNSIGNED NOT NULL DEFAULT 25,
    gender VARCHAR(10) NOT NULL DEFAULT 'autre',
    looking VARCHAR(10) NOT NULL DEFAULT 'tous',
    bio VARCHAR(250) NULL,
    photos TEXT NULL,
    active TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aero_swipes (
    identifier VARCHAR(80) NOT NULL,
    target VARCHAR(80) NOT NULL,
    liked TINYINT(1) NOT NULL,
    created BIGINT NOT NULL,
    PRIMARY KEY (identifier, target)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aero_bank_tx (
    id INT AUTO_INCREMENT PRIMARY KEY,
    identifier VARCHAR(80) NOT NULL,
    kind VARCHAR(12) NOT NULL,
    amount DOUBLE NOT NULL,
    other VARCHAR(80) NULL,
    label VARCHAR(120) NULL,
    created BIGINT NOT NULL,
    INDEX (identifier, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aero_bills (
    id INT AUTO_INCREMENT PRIMARY KEY,
    identifier VARCHAR(80) NOT NULL,
    issuer VARCHAR(80) NOT NULL,
    society VARCHAR(40) NULL,
    amount DOUBLE NOT NULL,
    reason VARCHAR(200) NULL,
    status VARCHAR(8) NOT NULL DEFAULT 'open',
    created BIGINT NOT NULL,
    INDEX (identifier, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aero_crypto (
    identifier VARCHAR(80) NOT NULL,
    coin VARCHAR(10) NOT NULL,
    amount DOUBLE NOT NULL DEFAULT 0,
    invested DOUBLE NOT NULL DEFAULT 0,
    PRIMARY KEY (identifier, coin)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aero_crypto_prices (
    coin VARCHAR(10) NOT NULL PRIMARY KEY,
    price DOUBLE NOT NULL,
    history TEXT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aero_market (
    id INT AUTO_INCREMENT PRIMARY KEY,
    identifier VARCHAR(80) NOT NULL,
    number VARCHAR(20) NOT NULL,
    seller VARCHAR(60) NOT NULL,
    title VARCHAR(80) NOT NULL,
    descr TEXT NULL,
    price DOUBLE NOT NULL DEFAULT 0,
    category VARCHAR(30) NOT NULL,
    images TEXT NULL,
    sold TINYINT(1) NOT NULL DEFAULT 0,
    created BIGINT NOT NULL,
    INDEX (category), INDEX (identifier)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aero_mail (
    id INT AUTO_INCREMENT PRIMARY KEY,
    owner VARCHAR(120) NOT NULL,
    from_addr VARCHAR(120) NOT NULL,
    to_addr VARCHAR(120) NOT NULL,
    subject VARCHAR(120) NOT NULL,
    body TEXT NULL,
    folder VARCHAR(8) NOT NULL DEFAULT 'inbox',
    seen TINYINT(1) NOT NULL DEFAULT 0,
    starred TINYINT(1) NOT NULL DEFAULT 0,
    created BIGINT NOT NULL,
    INDEX (owner, folder)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aero_dc_users (
        identifier VARCHAR(80) NOT NULL PRIMARY KEY, alias VARCHAR(24) NOT NULL, color VARCHAR(8) NOT NULL, changed BIGINT NOT NULL DEFAULT 0, UNIQUE KEY uq_alias (alias)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aero_dc_rooms (
        id VARCHAR(32) NOT NULL PRIMARY KEY, name VARCHAR(40) NOT NULL, public TINYINT(1) NOT NULL DEFAULT 1, pass VARCHAR(64) NULL,
        ttl INT NOT NULL DEFAULT 24, creator VARCHAR(80) NULL, created BIGINT NOT NULL, last BIGINT NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aero_dc_members (
        room VARCHAR(32) NOT NULL, identifier VARCHAR(80) NOT NULL, PRIMARY KEY (room, identifier), INDEX (identifier)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aero_dc_msgs (
        id BIGINT AUTO_INCREMENT PRIMARY KEY, room VARCHAR(32) NOT NULL, alias VARCHAR(24) NOT NULL, color VARCHAR(8) NOT NULL, body TEXT NULL, image TEXT NULL,
        created BIGINT NOT NULL, identifier VARCHAR(80) NOT NULL, INDEX (room, id)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aero_scores (
        game VARCHAR(16) NOT NULL, identifier VARCHAR(80) NOT NULL, name VARCHAR(40) NOT NULL, score INT NOT NULL, updated BIGINT NOT NULL, PRIMARY KEY (game, identifier), INDEX (game, score)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aero_news (
        id INT AUTO_INCREMENT PRIMARY KEY, title VARCHAR(100) NOT NULL, body TEXT NULL, image TEXT NULL, author VARCHAR(60) NOT NULL, author_id VARCHAR(80) NULL,
        source VARCHAR(40) NULL, breaking TINYINT(1) NOT NULL DEFAULT 0, created BIGINT NOT NULL, INDEX (created)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aero_loto_tickets (
        id INT AUTO_INCREMENT PRIMARY KEY, identifier VARCHAR(80) NOT NULL, nums VARCHAR(40) NOT NULL, draw INT NOT NULL, won INT NOT NULL DEFAULT 0, matches TINYINT NOT NULL DEFAULT 0, created BIGINT NOT NULL, INDEX (identifier, draw)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aero_loto_state (
        id TINYINT NOT NULL PRIMARY KEY, pool BIGINT NOT NULL, next_draw BIGINT NOT NULL, draw INT NOT NULL, last TEXT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aero_findmy (
        owner VARCHAR(80) NOT NULL, viewer VARCHAR(80) NOT NULL, PRIMARY KEY (owner, viewer)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
