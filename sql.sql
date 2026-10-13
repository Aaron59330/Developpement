-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: 45.8.187.109:3306
-- Generation Time: Oct 13, 2026 at 10:32 PM
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
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `account_info`
--

INSERT INTO `account_info` (`account_id`, `license`, `steam`, `xbl`, `discord`, `live`, `fivem`, `name`, `ip`, `guid`, `first_connection`) VALUES
(9, 'license:1900e3062a0de4aadb8a6c959470425894c992fa', '', '', 'discord:392685405041983490', '', 'fivem:19581910', 'BoldToad5347', '81.49.97.21', '148618794345915336', '2026-09-27 15:17:47'),
(8, 'license:17015558e9d71c65e5de4c4c417d582ba4f005f1', '', '', 'discord:1483053647125545120', '', '', 'BoldAnt6449', '128.79.2.217', '148618792076656008', '2026-09-26 17:14:00'),
(7, 'license:1d522f6effdc6a92e62688a34602bd08135739ce', '', '', 'discord:1107694620038660116', '', 'fivem:10853226', 'schtroumpf', '88.166.13.88', '148618792432210040', '2026-09-26 09:17:12'),
(6, 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', '', '', 'discord:835234158598160394', '', 'fivem:2171901', 'Pickax', '109.9.46.105', '148618792018099180', '2026-09-26 02:30:02'),
(10, 'license:3afb15e367e2e7c2a142ecc8760f66805116c992', '', '', 'discord:653289623669440576', '', 'fivem:13975350', 'LoudSnaily3841', '92.159.69.201', '148618792007098071', '2026-09-27 17:59:16');

-- --------------------------------------------------------

--
-- Table structure for table `addon_account`
--

CREATE TABLE `addon_account` (
  `name` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `label` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `shared` int(11) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `addon_account`
--

INSERT INTO `addon_account` (`name`, `label`, `shared`) VALUES
('society_pillboxhopital', 'PillboxHopital', 1),
('society_pdm', 'Pdm', 1),
('society_lspd', 'Lspd', 1),
('society_bennys', 'Bennys', 1),
('society_banque', 'Banque', 1);

-- --------------------------------------------------------

--
-- Table structure for table `addon_account_data`
--

CREATE TABLE `addon_account_data` (
  `id` int(11) NOT NULL,
  `account_name` varchar(100) DEFAULT NULL,
  `money` int(11) NOT NULL,
  `owner` varchar(55) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `addon_account_data`
--

INSERT INTO `addon_account_data` (`id`, `account_name`, `money`, `owner`) VALUES
(2276, 'society_pillboxhopital', 20, NULL),
(2278, 'society_pdm', 0, NULL),
(2280, 'society_lspd', 0, NULL),
(2282, 'society_bennys', 0, NULL),
(2284, 'society_banque', 50502, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `addon_inventory`
--

CREATE TABLE `addon_inventory` (
  `name` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `label` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `shared` int(11) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `addon_inventory`
--

INSERT INTO `addon_inventory` (`name`, `label`, `shared`) VALUES
('property', 'Propriété', 0),
('society_pdm', 'Pdm', 1),
('trunk', 'Coffre Véhicule', 0),
('society_pillboxhopital', 'PillboxHopital', 1),
('society_banque', 'Banque', 1),
('society_lspd', 'Lspd', 1),
('society_bennys', 'Bennys', 1);

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

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
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

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
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

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
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `boitegant`
--

CREATE TABLE `boitegant` (
  `id` int(11) NOT NULL,
  `plate` varchar(50) NOT NULL,
  `data` longtext DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

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
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

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
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `coffre_veh`
--

CREATE TABLE `coffre_veh` (
  `info` longtext DEFAULT NULL,
  `data` longtext DEFAULT NULL,
  `id` int(11) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `datastore`
--

CREATE TABLE `datastore` (
  `name` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `label` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `shared` int(11) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `datastore`
--

INSERT INTO `datastore` (`name`, `label`, `shared`) VALUES
('property', 'Propriété', 0),
('society_pillboxhopital', 'PillboxHopital', 1),
('user_ears', 'Ears', 0),
('user_glasses', 'Glasses', 0),
('user_helmet', 'Helmet', 0),
('user_mask', 'Mask', 0),
('society_banque', 'Banque', 1),
('society_lspd', 'Lspd', 1),
('society_bennys', 'Bennys', 1),
('society_pdm', 'Pdm', 1);

-- --------------------------------------------------------

--
-- Table structure for table `datastore_data`
--

CREATE TABLE `datastore_data` (
  `id` int(11) NOT NULL,
  `name` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `owner` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `datastore_data`
--

INSERT INTO `datastore_data` (`id`, `name`, `data`, `owner`) VALUES
(2534, 'property', '{}', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8'),
(2535, 'user_helmet', '{}', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8'),
(2536, 'user_mask', '{}', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8'),
(2537, 'user_ears', '{}', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8'),
(2538, 'user_glasses', '{}', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8'),
(2539, 'society_pillboxhopital', '{}', NULL),
(2540, 'property', '{}', 'license:17015558e9d71c65e5de4c4c417d582ba4f005f1'),
(2541, 'user_ears', '{}', 'license:17015558e9d71c65e5de4c4c417d582ba4f005f1'),
(2542, 'user_helmet', '{}', 'license:17015558e9d71c65e5de4c4c417d582ba4f005f1'),
(2543, 'user_glasses', '{}', 'license:17015558e9d71c65e5de4c4c417d582ba4f005f1'),
(2544, 'user_mask', '{}', 'license:17015558e9d71c65e5de4c4c417d582ba4f005f1'),
(2545, 'society_pdm', '{}', NULL),
(2546, 'society_lspd', '{}', NULL),
(2547, 'society_bennys', '{}', NULL),
(2548, 'society_banque', '{}', NULL),
(2549, 'property', '{}', 'license:3afb15e367e2e7c2a142ecc8760f66805116c992'),
(2550, 'user_glasses', '{}', 'license:3afb15e367e2e7c2a142ecc8760f66805116c992'),
(2551, 'user_mask', '{}', 'license:3afb15e367e2e7c2a142ecc8760f66805116c992'),
(2552, 'user_helmet', '{}', 'license:3afb15e367e2e7c2a142ecc8760f66805116c992'),
(2553, 'user_ears', '{}', 'license:3afb15e367e2e7c2a142ecc8760f66805116c992');

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
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `gangbuilder_gangs`
--

INSERT INTO `gangbuilder_gangs` (`name`, `label`, `type`, `color`, `boss_grade`, `money`, `dirty`, `rep`, `blip`, `settings`, `created_by`, `created_at`, `updated_at`) VALUES
('ballas', 'Ballas', 'street', '#7d10c6', 3, 6550, 500, 2, '{\"label\":\"Ballas\",\"shortRange\":false,\"scale\":0.50000000000009,\"color\":83,\"coords\":{\"z\":20.8,\"h\":135.99,\"x\":104.56,\"y\":-1941.09},\"sprite\":310,\"enabled\":true}', '{\"motd\":\"\",\"capture_grade\":1,\"max_members\":-1,\"actions\":[\"handcuff\",\"escort\",\"search\"],\"recruit_grade\":0,\"plate_prefix\":\"BAL\",\"withdraw_grade\":3,\"sell_cut\":-1,\"salary_source\":\"system\"}', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', '2026-10-05 09:23:03', '2026-10-11 14:36:18'),
('cayoperico', 'CayoPerico', 'cartel', '#c89a4c', 4, 0, 0, 0, '{\"sprite\":310,\"enabled\":false,\"shortRange\":false,\"scale\":0.90000000000009,\"color\":1,\"label\":\"CayoPerico\"}', '{\"capture_grade\":0,\"actions\":[\"handcuff\",\"escort\",\"search\"],\"max_members\":-1,\"sell_cut\":-1,\"salary_source\":\"default\",\"withdraw_grade\":4,\"recruit_grade\":0,\"motd\":\"\",\"plate_prefix\":\"CAY\"}', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', '2026-10-05 09:58:08', '2026-10-05 18:00:11'),
('famillies', 'Famillies', 'street', '#0c5515', 3, 0, 0, 0, '{\"color\":2,\"enabled\":false,\"shortRange\":false,\"sprite\":310,\"scale\":0.90000000000009,\"label\":\"Famillies\"}', '{\"max_members\":-1,\"plate_prefix\":\"FAM\",\"actions\":[\"handcuff\",\"escort\",\"search\"],\"motd\":\"\",\"salary_source\":\"default\",\"withdraw_grade\":3,\"recruit_grade\":0,\"capture_grade\":0,\"sell_cut\":-1}', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', '2026-10-05 09:58:44', '2026-10-05 09:58:44'),
('vagos', 'Vagos', 'street', '#e4dd01', 3, 0, 0, 0, '{\"label\":\"Vagos\",\"shortRange\":false,\"scale\":0.50000000000009,\"color\":46,\"coords\":{\"z\":26.22,\"h\":55.59,\"x\":370.85,\"y\":-1997.46},\"sprite\":310,\"enabled\":true}', '{\"motd\":\"\",\"capture_grade\":0,\"max_members\":-1,\"actions\":[\"handcuff\",\"escort\",\"search\"],\"recruit_grade\":0,\"plate_prefix\":\"VAG\",\"withdraw_grade\":3,\"sell_cut\":-1,\"salary_source\":\"default\"}', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', '2026-10-05 09:57:47', '2026-10-11 14:36:48');

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `gangbuilder_logs`
--

INSERT INTO `gangbuilder_logs` (`id`, `gang_name`, `identifier`, `player_name`, `action`, `detail`, `created_at`) VALUES
(1, '_settings', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'settings_saved', 'ui', '2026-10-05 09:20:14'),
(2, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_created', '4 grades, 0 points', '2026-10-05 09:23:03'),
(3, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 1 points', '2026-10-05 09:23:20'),
(4, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 1 points', '2026-10-05 09:23:42'),
(5, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 1 points', '2026-10-05 09:33:07'),
(6, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 1 points', '2026-10-05 09:33:49'),
(7, '_settings', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'settings_saved', 'ui', '2026-10-05 09:34:19'),
(8, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 1 points', '2026-10-05 09:34:37'),
(9, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 1 points', '2026-10-05 09:35:47'),
(10, '_settings', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'settings_saved', 'general', '2026-10-05 09:36:11'),
(11, '_territories', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'territory_saved', 'ballas (grove)', '2026-10-05 09:36:41'),
(12, '_territories', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'territory_deleted', 'ballas', '2026-10-05 09:36:48'),
(13, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 1 points', '2026-10-05 09:36:50'),
(14, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 2 points', '2026-10-05 09:36:56'),
(15, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 1 points', '2026-10-05 09:38:27'),
(16, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 1 points', '2026-10-05 09:38:30'),
(17, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'leave', 'Maly Pablo', '2026-10-05 09:39:11'),
(18, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 2 points', '2026-10-05 09:39:48'),
(19, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'launder', '2500$ sale -> 2000$ propre (commission 500$)', '2026-10-05 09:40:42'),
(20, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 3 points', '2026-10-05 09:42:56'),
(21, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 3 points', '2026-10-05 09:43:04'),
(22, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'vehicle_out', 'Sultan (BAL51154)', '2026-10-05 09:43:18'),
(23, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'vehicle_in', 'BAL51154', '2026-10-05 09:43:24'),
(24, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 4 points', '2026-10-05 09:44:27'),
(25, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 4 points', '2026-10-05 09:44:34'),
(26, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'shop_buy', '1x weapon_pistol pour 1000$', '2026-10-05 09:44:38'),
(27, '_territories', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'territory_saved', 'ballas (ballas)', '2026-10-05 09:46:55'),
(28, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'treasury_deposit', '50$', '2026-10-05 09:47:30'),
(29, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'dirty_deposit', '500$', '2026-10-05 09:47:34'),
(30, '_territories', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'territory_deleted', 'ballas', '2026-10-05 09:49:35'),
(31, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 4 points', '2026-10-05 09:49:39'),
(32, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 5 points', '2026-10-05 09:50:48'),
(33, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'armory_take', '1x Pistol', '2026-10-05 09:50:52'),
(34, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 6 points', '2026-10-05 09:51:13'),
(35, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 7 points', '2026-10-05 09:53:33'),
(36, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 0 points', '2026-10-05 09:54:28'),
(37, 'vagos', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_created', '4 grades, 0 points', '2026-10-05 09:57:47'),
(38, 'cayoperico', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_created', '5 grades, 0 points', '2026-10-05 09:58:08'),
(39, 'cayoperico', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '5 grades, 0 points', '2026-10-05 09:58:17'),
(40, 'vagos', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 0 points', '2026-10-05 09:58:25'),
(41, 'famillies', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_created', '4 grades, 0 points', '2026-10-05 09:58:44'),
(42, 'cayoperico', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '5 grades, 0 points', '2026-10-05 10:08:32'),
(43, 'cayoperico', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '5 grades, 1 points', '2026-10-05 10:08:43'),
(44, 'cayoperico', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '5 grades, 1 points', '2026-10-05 10:08:45'),
(45, 'cayoperico', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '5 grades, 0 points', '2026-10-05 10:09:06'),
(51, '_deleted', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_deleted', 'TM (tm)', '2026-10-05 16:59:46'),
(52, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 0 points', '2026-10-05 18:00:08'),
(53, 'cayoperico', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '5 grades, 0 points', '2026-10-05 18:00:11'),
(54, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 1 points', '2026-10-11 14:29:51'),
(55, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 1 points', '2026-10-11 14:29:56'),
(56, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'vehicle_out', 'Sultan (BAL62284)', '2026-10-11 14:29:59'),
(57, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'vehicle_in', 'BAL62284', '2026-10-11 14:30:06'),
(58, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 2 points', '2026-10-11 14:30:41'),
(59, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 3 points', '2026-10-11 14:31:22'),
(60, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 4 points', '2026-10-11 14:31:45'),
(61, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 4 points', '2026-10-11 14:31:52'),
(62, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 4 points', '2026-10-11 14:32:23'),
(63, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 4 points', '2026-10-11 14:32:33'),
(64, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 4 points', '2026-10-11 14:33:29'),
(65, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 4 points', '2026-10-11 14:33:47'),
(66, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 4 points', '2026-10-11 14:34:20'),
(67, 'vagos', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 1 points', '2026-10-11 14:35:52'),
(68, 'vagos', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 1 points', '2026-10-11 14:36:14'),
(69, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 4 points', '2026-10-11 14:36:18'),
(70, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 4 points', '2026-10-11 14:36:27'),
(71, 'ballas', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 4 points', '2026-10-11 14:36:34'),
(72, 'vagos', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 1 points', '2026-10-11 14:36:48'),
(73, 'vagos', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 1 points', '2026-10-11 14:36:53'),
(74, 'vagos', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 2 points', '2026-10-11 14:38:11'),
(75, 'vagos', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 3 points', '2026-10-11 14:38:22'),
(76, 'vagos', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 3 points', '2026-10-11 14:38:23'),
(77, 'vagos', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 4 points', '2026-10-11 14:39:11'),
(78, 'vagos', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'vehicle_out', 'Sultan (VAG92419)', '2026-10-11 14:39:16'),
(79, 'vagos', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'vehicle_in', 'VAG92419', '2026-10-11 14:39:21'),
(80, 'vagos', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 4 points', '2026-10-11 14:39:45'),
(81, 'vagos', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'vehicle_out', 'Sultan (VAG94483)', '2026-10-11 14:39:47'),
(82, 'vagos', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'vehicle_in', 'VAG94483', '2026-10-11 14:39:52'),
(83, 'vagos', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 4 points', '2026-10-11 14:40:47'),
(84, 'vagos', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'gang_updated', '4 grades, 4 points', '2026-10-11 14:40:48'),
(85, 'vagos', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'vehicle_out', 'Sultan (VAG30968)', '2026-10-11 14:40:51'),
(86, 'vagos', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'vehicle_out', 'Sultan (VAG42081)', '2026-10-11 14:40:55'),
(87, 'vagos', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'vehicle_in', 'VAG42081', '2026-10-11 14:41:03'),
(88, 'vagos', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'vehicle_in', 'VAG30968', '2026-10-11 14:41:08');

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `gangbuilder_points`
--

INSERT INTO `gangbuilder_points` (`id`, `gang_name`, `type`, `label`, `coords`, `min_grade`, `data`) VALUES
(14, 'ballas', 'garage', 'Garage', '{\"z\":20.75,\"h\":250.01,\"x\":117.38,\"y\":-1950.43}', 0, '{\"vehicles\":[{\"label\":\"Sultan\",\"min_grade\":0,\"model\":\"sultan\"}],\"spawn\":{\"z\":20.69,\"h\":328.35,\"x\":112.56,\"y\":-1946.72},\"kind\":\"car\"}'),
(15, 'ballas', 'boss', 'Gestion du gang', '{\"z\":21.13,\"h\":224.08,\"x\":78.62,\"y\":-1969.96}', 3, '[]'),
(16, 'ballas', 'cloakroom', 'Vestiaire', '{\"z\":21.13,\"h\":317.68,\"x\":80.52,\"y\":-1961.19}', 0, '{\"outfits\":[{\"label\":\"Tenue\",\"male\":{\"chain_1\":0,\"chain_2\":0,\"torso_1\":22,\"tshirt_2\":0,\"helmet_2\":-1,\"mask_2\":0,\"arms_2\":0,\"helmet_1\":-1,\"glasses_2\":0,\"mask_1\":0,\"watches_2\":0,\"arms\":0,\"decals_1\":0,\"torso_2\":2,\"pants_1\":20,\"shoes_2\":0,\"ears_1\":-1,\"bracelets_1\":-1,\"watches_1\":-1,\"bags_2\":0,\"glasses_1\":0,\"shoes_1\":1,\"tshirt_1\":15,\"bproof_1\":0,\"bproof_2\":0,\"decals_2\":0,\"bracelets_2\":0,\"bags_1\":0,\"ears_2\":0,\"pants_2\":0},\"min_grade\":0}]}'),
(17, 'ballas', 'stash', 'Coffre', '{\"z\":21.13,\"h\":52.19,\"x\":83.04,\"y\":-1965.81}', 0, '{\"slots\":50,\"weight\":100}'),
(18, 'vagos', 'cloakroom', 'Vestiaire', '{\"z\":26.22,\"h\":54.78,\"x\":370.85,\"y\":-1997.46}', 0, '{\"outfits\":[{\"label\":\"Tenue\",\"male\":{\"chain_1\":0,\"chain_2\":0,\"torso_1\":22,\"tshirt_2\":0,\"helmet_2\":-1,\"mask_2\":0,\"arms_2\":0,\"helmet_1\":-1,\"glasses_2\":0,\"mask_1\":0,\"watches_2\":0,\"arms\":0,\"decals_1\":0,\"torso_2\":2,\"pants_1\":20,\"shoes_2\":0,\"ears_1\":-1,\"bracelets_1\":-1,\"watches_1\":-1,\"bags_2\":0,\"glasses_1\":0,\"shoes_1\":1,\"tshirt_1\":15,\"bproof_1\":0,\"bproof_2\":0,\"decals_2\":0,\"bracelets_2\":0,\"bags_1\":0,\"ears_2\":0,\"pants_2\":0},\"min_grade\":0}]}'),
(19, 'vagos', 'boss', 'Gestion du gang', '{\"z\":26.25,\"h\":30.3,\"x\":355.96,\"y\":-1989.29}', 3, '[]'),
(20, 'vagos', 'stash', 'Coffre', '{\"z\":26.25,\"h\":152.96,\"x\":357.59,\"y\":-1990.47}', 0, '{\"slots\":50,\"weight\":100}'),
(21, 'vagos', 'garage', 'Garage', '{\"z\":24.22,\"h\":250.67,\"x\":362.58,\"y\":-1980.41}', 0, '{\"vehicles\":[{\"color\":89,\"label\":\"Sultan\",\"min_grade\":0,\"model\":\"sultan\"}],\"spawn\":{\"z\":24.24,\"h\":341.4,\"x\":364.08,\"y\":-1976.24},\"kind\":\"car\"}');

-- --------------------------------------------------------

--
-- Table structure for table `gangbuilder_settings`
--

CREATE TABLE `gangbuilder_settings` (
  `name` varchar(40) NOT NULL,
  `value` longtext NOT NULL,
  `updated_by` varchar(100) DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `gangbuilder_settings`
--

INSERT INTO `gangbuilder_settings` (`name`, `value`, `updated_by`, `updated_at`) VALUES
('general', '{\"AcePermission\":\"gangbuilder.admin\",\"PlatePrefixLength\":3,\"UseGangColor\":true,\"MaxItemsPerPoint\":100,\"TargetDistance\":4,\"DrawDistance\":12,\"RestartResources\":[],\"MaxPoints\":80,\"InteractDistance\":1.5999999999999,\"ServerDistance\":10,\"AllowedGroups\":[\"_dev\"],\"Inventory\":\"ox\",\"MaxGangs\":0,\"MaxGrades\":15,\"Webhook\":\"\"}', 'Maly Pablo', '2026-10-05 09:36:11'),
('ui', '{\"UI.Accent\":[54,140,86]}', 'Maly Pablo', '2026-10-05 09:34:19');

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `gangbuilder_stats`
--

INSERT INTO `gangbuilder_stats` (`identifier`, `gang_name`, `harvested`, `processed`, `sold`, `laundered`, `contribution`, `last_at`) VALUES
('license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'ballas', 0, 0, 0, 2500, 550, '2026-10-05 09:47:34');

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `items`
--

INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`) VALUES
('armor', 'Kevlar', 3, 0, 1),
('bandage', 'Bandage', 0.2, 0, 1),
('basic_cuff', 'Menottes Basique', 0.3, 0, 1),
('basic_key', 'Clefs de Menottes Basique', 0.1, 0, 1),
('beer', 'Bière', 0.1, 0, 1),
('blowpipe', 'Chalumeaux', 1.5, 0, 1),
('bread', 'Pain', 0.1, 0, 1),
('burger', 'Burger', 0.3, 0, 1),
('carokit', 'Kit carosserie', 3, 0, 1),
('carotool', 'Outils carosserie', 4, 0, 1),
('chip', 'Jeton', 0, 0, 1),
('cigarette', 'Cigarette', 0.1, 0, 1),
('clip', 'Chargeur', 0.3, 0, 1),
('coca', 'Coca', 0.1, 0, 1),
('coke', 'Coke', 1, 0, 1),
('coke_pooch', 'Pochon de coke', 0.25, 0, 1),
('cola', 'Cola', 0.2, 0, 1),
('corde', 'Corde', 2, 0, 1),
('defibrillateur', 'Défibrillateur', 2, 0, 1),
('feuille_coca', 'Feuille de coca', 1, 0, 1),
('firstaidkit', 'Trousse premier secours', 1, 0, 1),
('fixkit', 'Kit réparation', 1.5, 0, 1),
('fixtool', 'Outils réparation', 2, 0, 1),
('gazbottle', 'Bouteille de gaz', 2, 0, 1),
('gitanes', 'Gitanes', 0.1, 0, 1),
('grand_cru', 'Grand cru', 0.2, 0, 1),
('grapperaisin', 'Grappe de raisin', 0.3, 0, 1),
('handcuff', 'Serre câble ', 0.3, 0, 1),
('ice', 'Glaçon', 0.1, 0, 1),
('jager', 'Jägermeister', 0.5, 0, 1),
('jagerbomb', 'Jägermeister', 0.5, 0, 1),
('jagercerbere', 'Jäger Cerbère', 0.5, 0, 1),
('jumelles', 'Jumelles', 0.25, 0, 1),
('yusuf', 'Skin de Luxe', 4, 0, 1),
('grip', 'Poignée', 1, 0, 1),
('magazine', 'Chargeur agrandi', 2, 0, 1),
('silencieux', 'Silencieux', 1, 0, 1),
('flashlight', 'Lampe', 1, 0, 1),
('scope', 'Viseur', 1, 0, 1),
('jus_coca', 'Jus de coca', 0.5, 0, 1),
('jus_raisin', 'Jus de raisin', 0.5, 0, 1),
('jusfruit', 'Jus de fruits', 0.5, 0, 1),
('limonade', 'Limonade', 0.5, 0, 1),
('lockpick', 'Pied de Biche', 1, 0, 1),
('malbora', 'Malboro', 0.1, 0, 1),
('martini', 'Martini blanc', 1, 0, 1),
('meat', 'Viande', 0.3, 0, 1),
('medikit', 'Medikit', 2, 0, 1),
('menthe', 'Feuille de menthe', 1, 0, 1),
('meth', 'Meth', 1, 0, 1),
('meth_pooch', 'Pochon de meth', 0.25, 0, 1),
('metreshooter', 'Mètre de shooter', 0.1, 0, 1),
('mixapero', 'Mix Apéritif', 0.1, 0, 1),
('mojito', 'Mojito', 0.1, 0, 1),
('opium', 'Opium', 1, 0, 1),
('opium_pooch', 'Pochon d\'opium', 0.25, 0, 1),
('orange', 'Orange', 0.1, 0, 1),
('orange_juice', 'Jus d\'orange', 0.3, 0, 1),
('oxygen_mask', 'Masque à Oxygène', 0.6, 0, 1),
('pepperspray', 'Gazeuse', 1, 0, -1),
('phone', 'Téléphone', 0.3, 0, 1),
('piluleoubli', 'GHB', 1, 0, 1),
('pomme', 'Pomme', 0.1, 0, 1),
('radio', 'Radio', 0.5, 0, 1),
('raisin', 'Raisin', 0.3, 0, 1),
('redbull', 'Redbull', 0.3, 0, 1),
('repairkit', 'Repairkit', 2, 0, 1),
('rhum', 'Rhum', 0.4, 0, 1),
('rhumcoca', 'Rhum-Coca', 0.5, 0, 1),
('rhumfruit', 'Rhum-Jus de fruits', 0.5, 0, 1),
('tabac', 'Tabac', 0.5, 0, 1),
('tabacblond', 'Tabac Blond', 0.5, 0, 1),
('tabacblondsec', 'Tabac Blond Séché', 0.5, 0, 1),
('tabacbrun', 'Tabac Brun', 0.5, 0, 1),
('tabacbrunsec', 'Tabac Brun Séché', 0.5, 0, 1),
('tarte_pomme', 'Tarte aux Pommes', 0.3, 0, 1),
('teqpaf', 'Teq\'paf', 0.5, 0, 1),
('tequila', 'Tequila', 0.5, 0, 1),
('vine', 'Vin', 0.5, 0, 1),
('vittvin', 'Vin Blanc', 0.5, 0, 1),
('vodka', 'Vodka', 0.3, 0, 1),
('vodkaenergy', 'Vodka-Energy', 0.4, 0, 1),
('vodkafruit', 'Vodka-Jus de fruits', 0.3, 0, 1),
('vodkaredbull', 'Vodka-Redbull', 0.3, 0, 1),
('water', 'Bouteille d\'eau', 0.1, 0, 1),
('weed', 'Weed', 1, 0, 1),
('weed_pooch', 'Pochon de weed', 0.25, 0, 1),
('whisky', 'Whisky', 0.4, 0, 1),
('whiskycoca', 'Whisky-coca', 0.5, 0, 1),
('gym_membership', 'Pass membre GYM', 0.5, 0, 1),
('fishingrod', 'Canne à pêche', 0.5, 0, 1),
('macro', 'Macro', 0.5, 0, 1),
('bar', 'Bar', 0.5, 0, 1),
('dorade', 'Dorade', 0.5, 0, 1),
('lieu', 'Lieu', 0.5, 0, 1),
('raie', 'Raie', 0.5, 0, 1),
('sardine', 'Sardine', 0.5, 0, 1),
('saumon', 'Saumon', 0.5, 0, 1),
('thon', 'Thon', 0.5, 0, 1),
('requin', 'Requin', 2, 0, 1),
('zetony', 'Jetons', -1, 0, 1);

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
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `job2_grades`
--

INSERT INTO `job2_grades` (`id`, `job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES
(1, 'unemployed2', 0, 'unemployed2', 'Unemployed2', 200, '{}', '{}'),
(164, 'famillies', 0, 'recrue', 'Petit', 50, '{}', '{}'),
(165, 'famillies', 1, 'soldat', 'Soldat', 100, '{}', '{}'),
(166, 'famillies', 2, 'capo', 'Lieutenant', 200, '{}', '{}'),
(167, 'famillies', 3, 'boss', 'Chef', 400, '{}', '{}'),
(208, 'cayoperico', 0, 'halcon', 'Halcón', 80, '{}', '{}'),
(209, 'cayoperico', 1, 'sicario', 'Sicario', 180, '{}', '{}'),
(210, 'cayoperico', 2, 'jefe', 'Jefe de plaza', 350, '{}', '{}'),
(211, 'cayoperico', 3, 'capo', 'Capo', 600, '{}', '{}'),
(212, 'cayoperico', 4, 'boss', 'Patrón', 1000, '{}', '{}'),
(273, 'ballas', 0, 'recrue', 'Petit', 50, '{}', '{}'),
(274, 'ballas', 1, 'soldat', 'Soldat', 100, '{}', '{}'),
(275, 'ballas', 2, 'capo', 'Lieutenant', 200, '{}', '{}'),
(276, 'ballas', 3, 'boss', 'Chef', 400, '{}', '{}'),
(309, 'vagos', 0, 'recrue', 'Petit', 50, '{}', '{}'),
(310, 'vagos', 1, 'soldat', 'Soldat', 100, '{}', '{}'),
(311, 'vagos', 2, 'capo', 'Lieutenant', 200, '{}', '{}'),
(312, 'vagos', 3, 'boss', 'Chef', 400, '{}', '{}');

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `jobbuilder_announces`
--

INSERT INTO `jobbuilder_announces` (`id`, `job_name`, `author`, `kind`, `title`, `text`, `created_at`) VALUES
(4, 'pillboxhopital', 'Maly Pablo', 'info', 'ZQDQZ', 'qzdqzdqd', '2026-10-10 22:20:12'),
(5, 'pdm', 'Maly Pablo', 'info', 'defgeds', 'seeses', '2026-10-11 14:48:11'),
(6, 'banque', 'Maly Pablo', 'info', 'QZDZQ', 'QZDZQDQZD', '2026-10-12 12:31:50');

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `jobbuilder_bank_clients`
--

INSERT INTO `jobbuilder_bank_clients` (`id`, `job_name`, `identifier`, `firstname`, `lastname`, `rating`, `flag`, `notes`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 'banque', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly', 'Pablo', 'C', 'normal', NULL, 'jUNE GUEVARO', '2026-10-12 13:19:19', '2026-10-12 13:23:07'),
(2, 'banque', 'license:17015558e9d71c65e5de4c4c417d582ba4f005f1', 'MOUNIR', 'PABLO', 'C', 'normal', NULL, 'jUNE GUEVARO', '2026-10-12 13:19:40', '2026-10-12 13:19:44');

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `jobbuilder_bank_entries`
--

INSERT INTO `jobbuilder_bank_entries` (`id`, `client_id`, `job_name`, `kind`, `label`, `amount`, `officer`, `created_at`) VALUES
(1, 2, 'banque', 'deposit', 'Dépôt au guichet', 1000, 'jUNE GUEVARO', '2026-10-12 13:19:44'),
(2, 1, 'banque', 'deposit', 'Dépôt au guichet', 500, 'jUNE GUEVARO', '2026-10-12 13:20:06'),
(3, 1, 'banque', 'loan', 'Prêt #1 accordé : 5 000 $ à 10 % sur 3 échéances', 5000, 'jUNE GUEVARO', '2026-10-12 13:22:57'),
(4, 1, 'banque', 'payment', 'Échéance prélevée (1/3)', 1834, 'Système', '2026-10-12 13:23:04'),
(5, 1, 'banque', 'payment', 'Échéance prélevée (2/3)', 1834, 'Système', '2026-10-12 13:23:06'),
(6, 1, 'banque', 'payment', 'Échéance prélevée (3/3)', 1834, 'Système', '2026-10-12 13:23:07'),
(7, 1, 'banque', 'note', 'Prêt #1 soldé', 0, 'Système', '2026-10-12 13:23:07');

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `jobbuilder_bank_loans`
--

INSERT INTO `jobbuilder_bank_loans` (`id`, `job_name`, `client_id`, `identifier`, `principal`, `rate`, `installment`, `installments`, `left_count`, `paid`, `penalties`, `late_count`, `status`, `next_due`, `officer`, `note`, `created_at`) VALUES
(1, 'banque', 1, 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 5000, 10, 1834, 3, 0, 5502, 0, 0, 'paid', '2026-10-13 13:23:07', 'jUNE GUEVARO', NULL, '2026-10-12 13:22:57');

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `jobbuilder_jobs`
--

INSERT INTO `jobbuilder_jobs` (`name`, `label`, `type`, `whitelisted`, `society`, `boss_grade`, `blip`, `settings`, `created_by`, `created_at`, `updated_at`) VALUES
('banque', 'Banque', 'bank', 1, 1, 3, '{\"label\":\"Banquier\",\"coords\":{\"z\":30.41,\"h\":91.93,\"x\":40.69,\"y\":-873.59},\"scale\":0.50000000000009,\"enabled\":true,\"sprite\":108,\"color\":9,\"shortRange\":false}', '{\"tablet_admin_grade\":3,\"care_grade\":0,\"treasury\":true,\"dealer_admin_grade\":3,\"dealer_sell_grade\":0,\"dealer_commission\":10,\"announce_grade\":3,\"bank_fees\":[{\"label\":\"Ouverture de compte\",\"amount\":150},{\"label\":\"Carte bancaire\",\"amount\":80},{\"label\":\"Chéquier\",\"amount\":40},{\"label\":\"Coffre-fort personnel\",\"amount\":500},{\"label\":\"Conseil financier\",\"amount\":200},{\"label\":\"Frais de dossier\",\"amount\":100}],\"dealer_categories\":[],\"care_custom\":true,\"missions_mult\":100,\"dealer_self_service\":false,\"missions_source\":\"system\",\"bank_rate_min\":0,\"care_prices\":[],\"bank_tablet_grade\":0,\"gov_admin_grade\":3,\"fine_grade\":0,\"tuning_markup\":100,\"prop_admin_grade\":3,\"ui_accent\":[168,85,247],\"announce_duration\":12,\"announce_radius\":0,\"actions\":[\"invoice\"],\"tablet_records\":true,\"menu\":[],\"bank_fee_grade\":0,\"announce_cost\":0,\"fine_custom\":true,\"ems_tablet_grade\":0,\"announce_cooldown\":120,\"announce_enabled\":true,\"announce_types\":[],\"tuning_billing\":\"customer\",\"tuning_grade\":0,\"prop_grade\":0,\"bank_rate_max\":25,\"bank_loan_max\":100000,\"bank_funding\":\"society\",\"dealer_auto\":true,\"bank_ops\":true,\"marker\":{\"color\":[168,85,247]},\"tablet_enabled\":true,\"gov_grade\":0,\"tablet_grade\":0,\"bank_admin_grade\":3,\"ems_tablet_enabled\":true,\"fines\":[],\"dealer_markup\":100,\"bank_loan_grade\":2,\"bank_tablet_enabled\":true,\"commission\":10,\"ems_admin_grade\":3,\"pursuit_grade\":0,\"plate_prefix\":\"BAN\",\"missions_enabled\":true,\"tablet_map\":true,\"tablet_dispatch\":true,\"bank_loans\":true}', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', '2026-10-12 12:30:24', '2026-10-13 12:28:07'),
('bennys', 'Bennys', 'mecano', 1, 1, 3, '{\"coords\":{\"z\":31.3,\"y\":-1326.98,\"x\":-212.63,\"h\":270.12},\"enabled\":true,\"sprite\":446,\"color\":5,\"shortRange\":false,\"scale\":0.50000000000009,\"label\":\"Bennys\"}', '{\"tablet_admin_grade\":3,\"missions_mult\":100,\"bank_tablet_enabled\":true,\"ems_tablet_enabled\":true,\"missions_source\":\"system\",\"missions_enabled\":true,\"prop_grade\":0,\"announce_duration\":12,\"announce_types\":[],\"announce_radius\":0,\"treasury\":true,\"announce_cost\":0,\"dealer_sell_grade\":0,\"marker\":{\"color\":[249,115,22]},\"tablet_grade\":0,\"tablet_map\":true,\"prop_admin_grade\":3,\"announce_enabled\":true,\"dealer_admin_grade\":3,\"gov_grade\":0,\"announce_grade\":3,\"bank_fee_grade\":0,\"dealer_self_service\":false,\"plate_prefix\":\"BEN\",\"tuning_grade\":0,\"bank_funding\":\"society\",\"bank_fees\":[],\"tablet_records\":true,\"gov_admin_grade\":3,\"ems_tablet_grade\":0,\"menu\":[],\"bank_rate_min\":0,\"dealer_categories\":[],\"bank_tablet_grade\":0,\"announce_cooldown\":120,\"care_prices\":[],\"bank_loans\":true,\"bank_admin_grade\":3,\"tablet_enabled\":true,\"tuning_billing\":\"customer\",\"bank_loan_grade\":2,\"commission\":10,\"pursuit_grade\":0,\"fines\":[],\"dealer_markup\":100,\"bank_loan_max\":100000,\"care_custom\":true,\"fine_grade\":0,\"tablet_dispatch\":true,\"care_grade\":0,\"ems_admin_grade\":3,\"bank_rate_max\":25,\"dealer_auto\":true,\"bank_ops\":true,\"fine_custom\":true,\"tuning_markup\":100,\"ui_accent\":[249,115,22],\"actions\":[\"repair\",\"clean\",\"invoice\"],\"dealer_commission\":10}', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', '2026-10-11 21:53:09', '2026-10-12 12:51:06'),
('lspd', 'Lspd', 'police', 1, 1, 4, '{\"coords\":{\"z\":21.45,\"y\":-981.42,\"x\":452.53,\"h\":83.2},\"enabled\":true,\"sprite\":60,\"color\":29,\"shortRange\":false,\"scale\":0.50000000000009,\"label\":\"Lspd\"}', '{\"tablet_admin_grade\":4,\"missions_mult\":100,\"bank_tablet_enabled\":true,\"ems_tablet_enabled\":true,\"missions_source\":\"system\",\"missions_enabled\":true,\"prop_grade\":0,\"announce_duration\":12,\"announce_types\":[],\"announce_radius\":0,\"treasury\":true,\"announce_cost\":0,\"dealer_sell_grade\":0,\"marker\":{\"color\":[59,130,246]},\"tablet_grade\":0,\"tablet_map\":true,\"prop_admin_grade\":4,\"announce_enabled\":true,\"dealer_admin_grade\":4,\"gov_grade\":0,\"announce_grade\":4,\"bank_fee_grade\":0,\"dealer_self_service\":false,\"plate_prefix\":\"LSP\",\"tuning_grade\":0,\"bank_funding\":\"society\",\"bank_fees\":[],\"tablet_records\":true,\"gov_admin_grade\":4,\"ems_tablet_grade\":0,\"menu\":[],\"bank_rate_min\":0,\"dealer_categories\":[],\"bank_tablet_grade\":0,\"announce_cooldown\":120,\"care_prices\":[],\"bank_loans\":true,\"bank_admin_grade\":4,\"tablet_enabled\":true,\"tuning_billing\":\"customer\",\"bank_loan_grade\":2,\"commission\":10,\"pursuit_grade\":0,\"fines\":[{\"amount\":250,\"label\":\"Excès de vitesse\"},{\"amount\":600,\"label\":\"Conduite dangereuse\"},{\"amount\":1500,\"label\":\"Refus d\'obtempérer\"},{\"amount\":150,\"label\":\"Stationnement gênant\"},{\"amount\":2500,\"label\":\"Port d\'arme illégal\"},{\"amount\":800,\"label\":\"Trouble à l\'ordre public\"}],\"dealer_markup\":100,\"bank_loan_max\":100000,\"care_custom\":true,\"fine_grade\":0,\"tablet_dispatch\":true,\"care_grade\":0,\"ems_admin_grade\":4,\"bank_rate_max\":25,\"dealer_auto\":true,\"bank_ops\":true,\"fine_custom\":true,\"tuning_markup\":100,\"ui_accent\":[59,130,246],\"actions\":[\"handcuff\",\"escort\",\"search\",\"invoice\"],\"dealer_commission\":10}', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', '2026-10-11 17:52:43', '2026-10-12 12:51:17'),
('pdm', 'Pdm', 'dealer', 1, 1, 3, '{\"shortRange\":false,\"enabled\":true,\"coords\":{\"z\":26.42,\"h\":85.41,\"x\":-36.39,\"y\":-1101.2},\"label\":\"Pdm\",\"color\":47,\"scale\":0.50000000000009,\"sprite\":225}', '{\"dealer_markup\":100,\"dealer_auto\":true,\"dealer_categories\":[],\"tuning_grade\":0,\"missions_enabled\":true,\"marker\":{\"color\":[249,115,22]},\"care_custom\":true,\"tablet_records\":true,\"dealer_commission\":10,\"prop_admin_grade\":3,\"announce_radius\":0,\"plate_prefix\":\"PDM\",\"ems_admin_grade\":3,\"commission\":10,\"dealer_self_service\":false,\"tuning_billing\":\"customer\",\"tablet_admin_grade\":3,\"announce_grade\":3,\"prop_grade\":0,\"care_grade\":0,\"dealer_admin_grade\":3,\"dealer_sell_grade\":0,\"ems_tablet_grade\":0,\"tablet_enabled\":true,\"missions_mult\":100,\"tablet_dispatch\":true,\"fine_custom\":true,\"announce_types\":[],\"treasury\":true,\"menu\":[],\"announce_duration\":12,\"announce_cost\":0,\"actions\":[\"invoice\"],\"announce_cooldown\":120,\"gov_grade\":0,\"announce_enabled\":true,\"tuning_markup\":100,\"fine_grade\":0,\"ems_tablet_enabled\":true,\"care_prices\":[],\"tablet_map\":true,\"fines\":[],\"pursuit_grade\":0,\"ui_accent\":[249,115,22],\"missions_source\":\"system\",\"tablet_grade\":0,\"gov_admin_grade\":3}', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', '2026-10-11 14:42:43', '2026-10-11 17:51:23'),
('pillboxhopital', 'PillboxHopital', 'ems', 1, 1, 3, '{\"scale\":0.50000000000009,\"shortRange\":false,\"enabled\":true,\"color\":1,\"coords\":{\"z\":43.28,\"h\":79.52,\"x\":301.32,\"y\":-585.26},\"label\":\"PillboxHopital\",\"sprite\":61}', '{\"announce_radius\":0,\"dealer_admin_grade\":3,\"fines\":[],\"announce_cooldown\":120,\"announce_enabled\":true,\"menu\":[],\"fine_grade\":0,\"tablet_admin_grade\":3,\"tuning_markup\":100,\"ems_admin_grade\":3,\"marker\":{\"bob\":false,\"rotate\":false,\"scale\":{\"z\":0.5999999999999,\"x\":0.90000000000009,\"y\":0.90000000000009},\"marker\":25,\"alpha\":140,\"offset\":-0.95000000000004,\"color\":[239,68,68]},\"prop_admin_grade\":3,\"announce_cost\":0,\"prop_grade\":0,\"actions\":[\"revive\",\"heal\",\"invoice\"],\"dealer_auto\":true,\"missions_source\":\"system\",\"care_prices\":[],\"dealer_commission\":10,\"plate_prefix\":\"PIL\",\"announce_types\":[],\"ems_tablet_grade\":0,\"missions_enabled\":true,\"pursuit_grade\":0,\"gov_grade\":0,\"dealer_sell_grade\":0,\"treasury\":true,\"tuning_billing\":\"customer\",\"announce_grade\":3,\"dealer_self_service\":false,\"missions_mult\":100,\"announce_duration\":12,\"tablet_dispatch\":true,\"commission\":10,\"dealer_categories\":[],\"care_custom\":true,\"tablet_enabled\":true,\"fine_custom\":true,\"care_grade\":0,\"ems_tablet_enabled\":true,\"ui_accent\":[239,68,68],\"tablet_map\":true,\"tuning_grade\":0,\"tablet_records\":true,\"tablet_grade\":0,\"dealer_markup\":100,\"gov_admin_grade\":3}', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', '2026-10-10 22:00:38', '2026-10-11 10:14:35');

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `jobbuilder_logs`
--

INSERT INTO `jobbuilder_logs` (`id`, `job_name`, `identifier`, `player_name`, `action`, `detail`, `created_at`) VALUES
(1, '_settings', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'settings_saved', 'ui', '2026-10-05 09:06:59'),
(2, '_settings', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'settings_saved', 'ui', '2026-10-05 09:07:01'),
(3, '_settings', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'settings_saved', 'police', '2026-10-05 09:07:21'),
(10, '_settings', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'settings_saved', 'police', '2026-10-05 10:30:41'),
(11, '_settings', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'settings_saved', 'police', '2026-10-05 10:30:46'),
(12, '_settings', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'settings_saved', 'police', '2026-10-05 10:31:19'),
(13, '_settings', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'settings_saved', 'police', '2026-10-05 10:31:36'),
(14, '_settings', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'settings_saved', 'police', '2026-10-05 10:32:00'),
(15, '_settings', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'settings_saved', 'police', '2026-10-05 10:32:17'),
(16, '_settings', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'settings_saved', 'police', '2026-10-05 10:32:56'),
(17, '_settings', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'settings_saved', 'police', '2026-10-05 10:33:00'),
(18, '_settings', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'settings_reset', 'police', '2026-10-05 10:33:03'),
(19, '_settings', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'settings_saved', 'police', '2026-10-05 10:33:04'),
(21, '_deleted', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_deleted', 'qzdqzd (qzd)', '2026-10-05 10:39:05'),
(30, '_deleted', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_deleted', 'lspd (lspd)', '2026-10-05 17:45:59'),
(31, '_deleted', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_deleted', 'Pickax (pickax)', '2026-10-05 17:46:01'),
(32, '_deleted', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_deleted', 'Sheriff (sheriff)', '2026-10-05 17:46:04'),
(33, 'unemployed', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-10 15:54:21'),
(34, 'unemployed', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-10 15:54:23'),
(35, 'unemployed', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-10 15:54:50'),
(36, 'unemployed', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-10 15:55:27'),
(37, 'unemployed', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-10 15:56:24'),
(38, 'unemployed', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-10 15:56:31'),
(39, 'unemployed', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-10 15:57:04'),
(40, 'unemployed', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-10 15:58:30'),
(41, 'unemployed', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-10 16:00:38'),
(42, 'unemployed', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-10 16:14:30'),
(43, 'unemployed', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-10 16:15:45'),
(44, 'unemployed', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-10 16:16:26'),
(45, 'unemployed', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-10 16:23:21'),
(46, 'unemployed', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-10 16:23:25'),
(47, 'unemployed', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-10 16:23:33'),
(48, 'unemployed', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-10 16:23:37'),
(49, 'unemployed', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-10 16:23:44'),
(50, 'unemployed', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-10 16:23:55'),
(51, 'unemployed', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-10 16:24:05'),
(52, 'unemployed', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-10 16:24:51'),
(53, 'unemployed', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-10 16:25:04'),
(54, 'unemployed', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-10 16:28:07'),
(55, 'unemployed', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-10 16:28:23'),
(56, 'unemployed', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-10 16:28:32'),
(57, 'unemployed', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-10 16:28:47'),
(58, 'unemployed', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-10 16:32:57'),
(59, 'unemployed', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-10 16:37:44'),
(60, 'unemployed', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-10 16:37:53'),
(61, 'unemployed', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-10 16:43:04'),
(62, 'unemployed', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-10 16:43:13'),
(63, 'unemployed', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-10 16:49:27'),
(64, 'unemployed', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-10 17:09:04'),
(65, 'unemployed', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-10 17:09:34'),
(66, 'unemployed', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-10 20:38:06'),
(67, '_hospital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'hospital_fee', '500$ sur 500$ (Hôpital Pillbox)', '2026-10-10 20:45:56'),
(68, '_hospital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'hospital_fee', '500$ sur 500$ (Hôpital Pillbox)', '2026-10-10 20:49:49'),
(69, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_created', '4 grades, 0 points', '2026-10-10 22:00:38'),
(70, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 0 points', '2026-10-10 22:01:13'),
(71, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 1 points', '2026-10-10 22:01:58'),
(72, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 0 points', '2026-10-10 22:02:29'),
(73, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 1 points', '2026-10-10 22:05:14'),
(74, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'vehicle_out', 'ambulance (PIL81862)', '2026-10-10 22:05:17'),
(75, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'vehicle_in', 'PIL81862', '2026-10-10 22:06:12'),
(76, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 2 points', '2026-10-10 22:07:43'),
(77, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 2 points', '2026-10-10 22:08:36'),
(78, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 2 points', '2026-10-10 22:09:03'),
(79, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 3 points', '2026-10-10 22:09:51'),
(80, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 3 points', '2026-10-10 22:10:03'),
(81, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'shop_buy', '1x Bouteille d\'eau pour 10$', '2026-10-10 22:10:19'),
(82, '_settings', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'settings_saved', 'ui', '2026-10-10 22:11:05'),
(83, '_settings', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'settings_saved', 'pointTypes', '2026-10-10 22:17:06'),
(84, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 3 points', '2026-10-10 22:17:22'),
(85, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 3 points', '2026-10-10 22:17:51'),
(86, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'shop_buy', '1x Bouteille d\'eau pour 10$', '2026-10-10 22:19:07'),
(87, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 2', '2026-10-10 22:19:41'),
(88, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 2', '2026-10-10 22:19:54'),
(89, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_announce', '[Information] ZQDQZ', '2026-10-10 22:20:12'),
(90, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 3 points', '2026-10-10 22:20:59'),
(91, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 3 points', '2026-10-10 22:21:01'),
(92, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 3 points', '2026-10-10 22:21:21'),
(93, '_hospital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'hospital_fee', '500$ sur 500$ (Hôpital Pillbox)', '2026-10-10 22:26:16'),
(94, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 3 points', '2026-10-10 22:27:51'),
(95, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 3 points', '2026-10-10 22:28:31'),
(96, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 3 points', '2026-10-10 22:33:24'),
(97, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 3 points', '2026-10-10 22:33:27'),
(98, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 3 points', '2026-10-10 22:37:50'),
(99, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 3 points', '2026-10-10 22:37:57'),
(100, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 3 points', '2026-10-10 22:38:02'),
(101, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 3 points', '2026-10-10 22:38:10'),
(102, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 3 points', '2026-10-10 22:38:25'),
(103, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 4 points', '2026-10-10 22:39:45'),
(104, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'vehicle_out', 'ambulance (PIL14163)', '2026-10-10 22:39:50'),
(105, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'vehicle_in', 'PIL14163', '2026-10-10 22:39:52'),
(106, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 4 points', '2026-10-10 22:41:28'),
(107, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 3 points', '2026-10-10 22:41:37'),
(108, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 3 points', '2026-10-10 22:41:50'),
(109, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'vehicle_out', 'ambulance (PIL96380)', '2026-10-10 22:41:59'),
(110, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'vehicle_in', 'PIL96380', '2026-10-10 22:42:02'),
(111, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'vehicle_out', 'ambulance (PIL14543)', '2026-10-10 22:42:07'),
(112, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'vehicle_in', 'PIL14543', '2026-10-10 22:42:09'),
(113, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 3 points', '2026-10-10 22:47:41'),
(114, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 3 points', '2026-10-10 22:47:50'),
(115, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'vehicle_out', 'ambulance (PIL74963)', '2026-10-10 22:54:10'),
(116, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'vehicle_in', 'PIL74963', '2026-10-10 22:54:13'),
(117, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'vehicle_out', 'ambulance (PIL89224)', '2026-10-10 22:54:40'),
(118, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'vehicle_in', 'PIL89224', '2026-10-10 22:54:42'),
(119, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 3 points', '2026-10-11 10:14:35'),
(120, '_staff', NULL, 'système', 'revive_command', 'ID 3', '2026-10-11 10:22:34'),
(121, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 4', '2026-10-11 10:24:42'),
(122, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 4', '2026-10-11 10:25:36'),
(123, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 4', '2026-10-11 10:26:01'),
(124, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 4', '2026-10-11 10:26:06'),
(125, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 4', '2026-10-11 10:41:15'),
(126, '_staff', NULL, 'système', 'revive_command', 'ID 3', '2026-10-11 10:41:39'),
(127, '_staff', NULL, 'système', 'revive_command', 'ID 3', '2026-10-11 10:41:39'),
(128, '_staff', NULL, 'système', 'revive_command', 'ID 3', '2026-10-11 10:41:39'),
(129, '_staff', NULL, 'système', 'revive_command', 'ID 3', '2026-10-11 10:42:17'),
(130, '_staff', NULL, 'système', 'revive_command', 'ID 3', '2026-10-11 10:42:17'),
(131, '_staff', NULL, 'système', 'revive_command', 'ID 3', '2026-10-11 10:42:18'),
(132, '_staff', NULL, 'système', 'revive_command', 'ID 3', '2026-10-11 10:42:18'),
(133, '_staff', NULL, 'système', 'revive_command', 'ID 3', '2026-10-11 10:42:20'),
(134, '_staff', NULL, 'système', 'revive_command', 'ID 3', '2026-10-11 10:42:20'),
(135, '_staff', NULL, 'système', 'revive_command', 'ID 3', '2026-10-11 10:42:20'),
(136, '_staff', NULL, 'système', 'revive_command', 'ID 3', '2026-10-11 10:43:03'),
(137, '_staff', NULL, 'système', 'revive_command', 'ID 3', '2026-10-11 10:43:03'),
(138, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-11 11:39:19'),
(139, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-11 11:39:23'),
(140, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-11 11:39:25'),
(141, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-11 11:39:28'),
(142, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-11 11:40:33'),
(143, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-11 12:15:44'),
(144, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-11 12:19:01'),
(145, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-11 12:19:03'),
(146, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-11 12:19:21'),
(147, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-11 12:20:37'),
(148, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-11 12:24:18'),
(149, 'pillboxhopital', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-11 12:47:20'),
(150, 'pdm', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_created', '4 grades, 0 points', '2026-10-11 14:42:43'),
(151, 'pdm', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 0 points', '2026-10-11 14:43:00'),
(152, 'pdm', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 0 points', '2026-10-11 14:43:05'),
(153, 'pdm', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 0 points', '2026-10-11 14:43:13'),
(154, 'pdm', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 0 points', '2026-10-11 14:43:26'),
(155, 'pdm', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 1 points', '2026-10-11 14:43:43'),
(156, 'pdm', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 1 points', '2026-10-11 14:43:46'),
(157, 'pdm', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 2 points', '2026-10-11 14:45:02'),
(158, 'pdm', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 2 points', '2026-10-11 14:45:17'),
(159, 'pdm', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 2 points', '2026-10-11 14:45:25'),
(160, 'pdm', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 2 points', '2026-10-11 14:45:45'),
(161, 'pdm', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 0 points', '2026-10-11 14:45:53'),
(162, 'pdm', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 1 points', '2026-10-11 14:46:17'),
(163, 'pdm', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 2 points', '2026-10-11 14:46:36'),
(164, 'pdm', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 2 points', '2026-10-11 14:46:48'),
(165, 'pdm', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_announce', '[Information] defgeds', '2026-10-11 14:48:11'),
(166, 'pdm', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 2 points', '2026-10-11 14:48:20'),
(167, 'pdm', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 2 points', '2026-10-11 14:48:25'),
(168, 'pdm', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 3 points', '2026-10-11 14:50:11'),
(169, 'pdm', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 4 points', '2026-10-11 14:50:57'),
(170, 'pdm', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 4 points', '2026-10-11 14:50:59'),
(171, 'pdm', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 5 points', '2026-10-11 14:51:50'),
(172, 'pdm', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 5 points', '2026-10-11 17:51:24'),
(173, 'lspd', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_created', '5 grades, 0 points', '2026-10-11 17:52:43'),
(174, 'lspd', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '5 grades, 0 points', '2026-10-11 17:52:49'),
(175, 'lspd', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '5 grades, 0 points', '2026-10-11 17:53:03'),
(176, 'lspd', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '5 grades, 0 points', '2026-10-11 17:53:07'),
(177, 'lspd', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '5 grades, 1 points', '2026-10-11 17:54:41'),
(178, 'lspd', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '5 grades, 1 points', '2026-10-11 21:50:41'),
(179, 'lspd', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '5 grades, 1 points', '2026-10-11 21:52:55'),
(180, 'bennys', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_created', '4 grades, 0 points', '2026-10-11 21:53:09'),
(181, 'bennys', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 1 points', '2026-10-11 21:53:45'),
(182, 'bennys', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 1 points', '2026-10-11 21:53:51'),
(183, 'bennys', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 3 points', '2026-10-11 21:54:45'),
(184, 'bennys', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 3 points', '2026-10-11 21:55:22'),
(185, 'bennys', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 3 points', '2026-10-11 21:55:36'),
(186, 'bennys', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 3 points', '2026-10-11 21:55:53'),
(187, 'bennys', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 3 points', '2026-10-11 21:55:55'),
(188, 'bennys', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 4 points', '2026-10-11 22:02:33'),
(189, 'bennys', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'vehicle_out', 'Sultan (BEN50399)', '2026-10-11 22:02:39'),
(190, 'bennys', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'vehicle_in', 'BEN50399', '2026-10-11 22:02:44'),
(191, 'bennys', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'vehicle_out', 'Sultan (BEN92176)', '2026-10-11 22:02:49'),
(192, 'bennys', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'vehicle_in', 'BEN92176', '2026-10-11 22:06:58'),
(193, 'bennys', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'vehicle_out', 'Sultan (BEN41356)', '2026-10-11 22:16:44'),
(194, 'bennys', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'vehicle_in', 'BEN41356', '2026-10-11 22:16:48'),
(195, 'bennys', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 4 points', '2026-10-11 22:17:14'),
(196, 'banque', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_created', '4 grades, 0 points', '2026-10-12 12:30:24'),
(197, 'banque', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 0 points', '2026-10-12 12:30:27'),
(198, 'banque', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 0 points', '2026-10-12 12:31:04'),
(199, 'banque', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 1 points', '2026-10-12 12:31:12'),
(200, 'banque', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 1 points', '2026-10-12 12:31:14'),
(201, 'banque', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_announce', '[Information] QZDZQ', '2026-10-12 12:31:50'),
(202, 'bennys', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '4 grades, 4 points', '2026-10-12 12:51:06'),
(203, 'lspd', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'job_updated', '5 grades, 1 points', '2026-10-12 12:51:17'),
(204, 'banque', 'license:3afb15e367e2e7c2a142ecc8760f66805116c992', 'jUNE GUEVARO', 'bank_deposit', 'MOUNIR PABLO : 1000$', '2026-10-12 13:19:44'),
(205, 'banque', 'license:3afb15e367e2e7c2a142ecc8760f66805116c992', 'jUNE GUEVARO', 'bank_deposit', 'Maly Pablo : 500$', '2026-10-12 13:20:06'),
(206, '_staff', NULL, 'système', 'revive_command', 'ID 2', '2026-10-12 13:20:24'),
(207, 'banque', 'license:3afb15e367e2e7c2a142ecc8760f66805116c992', 'jUNE GUEVARO', 'job_updated', '4 grades, 1 points', '2026-10-12 13:21:14'),
(208, 'banque', 'license:3afb15e367e2e7c2a142ecc8760f66805116c992', 'jUNE GUEVARO', 'job_updated', '4 grades, 2 points', '2026-10-12 13:22:12'),
(209, 'banque', 'license:3afb15e367e2e7c2a142ecc8760f66805116c992', 'jUNE GUEVARO', 'society_deposit', '50000$', '2026-10-12 13:22:27'),
(210, 'banque', 'license:3afb15e367e2e7c2a142ecc8760f66805116c992', 'jUNE GUEVARO', 'bank_loan', 'Maly Pablo : 5000$ à 10% (3 x 1834$)', '2026-10-12 13:22:57'),
(211, 'banque', 'license:3afb15e367e2e7c2a142ecc8760f66805116c992', 'jUNE GUEVARO', 'job_updated', '4 grades, 1 points', '2026-10-12 13:23:51'),
(212, 'banque', 'license:3afb15e367e2e7c2a142ecc8760f66805116c992', 'jUNE GUEVARO', 'job_updated', '4 grades, 2 points', '2026-10-12 13:26:22'),
(213, 'banque', 'license:3afb15e367e2e7c2a142ecc8760f66805116c992', 'jUNE GUEVARO', 'job_updated', '4 grades, 2 points', '2026-10-12 13:26:28'),
(214, 'banque', 'license:3afb15e367e2e7c2a142ecc8760f66805116c992', 'jUNE GUEVARO', 'vehicle_out', 'tolrs6 (BAN78728)', '2026-10-12 13:27:26'),
(215, 'banque', 'license:3afb15e367e2e7c2a142ecc8760f66805116c992', 'jUNE GUEVARO', 'vehicle_in', 'BAN78728', '2026-10-12 13:27:47'),
(216, 'banque', 'license:3afb15e367e2e7c2a142ecc8760f66805116c992', 'jUNE GUEVARO', 'vehicle_out', 'tolrs6 (BAN73260)', '2026-10-12 13:27:53'),
(217, 'banque', 'license:3afb15e367e2e7c2a142ecc8760f66805116c992', 'jUNE GUEVARO', 'vehicle_in', 'BAN73260', '2026-10-12 13:29:06'),
(218, 'banque', 'license:3afb15e367e2e7c2a142ecc8760f66805116c992', 'jUNE GUEVARO', 'job_updated', '4 grades, 3 points', '2026-10-12 13:29:34'),
(219, 'banque', 'license:3afb15e367e2e7c2a142ecc8760f66805116c992', 'jUNE GUEVARO', 'mission_done', 'Visite client : 598$ en 33s', '2026-10-12 13:30:20'),
(220, 'lspd', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-12 13:52:26'),
(221, 'lspd', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'revive_command', 'ID 1', '2026-10-12 17:14:44'),
(222, 'banque', 'license:3afb15e367e2e7c2a142ecc8760f66805116c992', 'jUNE GUEVARO', 'revive_command', 'ID 4', '2026-10-12 20:12:45'),
(223, 'banque', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Pickax', 'job_updated', '4 grades, 3 points', '2026-10-13 12:27:54'),
(224, 'banque', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Pickax', 'job_updated', '4 grades, 3 points', '2026-10-13 12:28:01'),
(225, 'banque', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Pickax', 'job_updated', '4 grades, 3 points', '2026-10-13 12:28:07');

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `jobbuilder_mission_stats`
--

INSERT INTO `jobbuilder_mission_stats` (`identifier`, `job_name`, `done`, `earned`, `last_at`) VALUES
('license:3afb15e367e2e7c2a142ecc8760f66805116c992', 'banque', 1, 598, '2026-10-12 13:30:20');

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `jobbuilder_points`
--

INSERT INTO `jobbuilder_points` (`id`, `job_name`, `type`, `label`, `coords`, `min_grade`, `data`) VALUES
(5, 'pillboxhopital', 'garage', 'Garage', '{\"z\":43.25,\"h\":167.15,\"x\":293.08,\"y\":-597.73}', 0, '{\"spawn\":{\"z\":43.24,\"h\":69.18,\"x\":297.92,\"y\":-605.16},\"store\":{\"coords\":{\"z\":43.19,\"h\":242.46,\"x\":293.7,\"y\":-603.42},\"radius\":5,\"any\":false},\"kind\":\"car\",\"vehicles\":[{\"model\":\"ambulance\",\"min_grade\":0,\"label\":\"ambulance\"}]}'),
(6, 'pillboxhopital', 'cloakroom', 'Vestiaire', '{\"z\":43.28,\"h\":151.78,\"x\":299.12,\"y\":-598.3}', 0, '{\"outfits\":[{\"male\":{\"arms\":0,\"watches_2\":0,\"decals_1\":0,\"torso_1\":22,\"helmet_2\":-1,\"bags_1\":0,\"bracelets_2\":0,\"mask_2\":0,\"arms_2\":0,\"pants_2\":0,\"glasses_1\":0,\"ears_2\":0,\"chain_1\":0,\"chain_2\":0,\"glasses_2\":0,\"helmet_1\":-1,\"ears_1\":-1,\"shoes_1\":1,\"watches_1\":-1,\"shoes_2\":0,\"tshirt_2\":0,\"pants_1\":20,\"bracelets_1\":-1,\"tshirt_1\":15,\"decals_2\":0,\"bproof_1\":0,\"torso_2\":2,\"bags_2\":0,\"bproof_2\":0,\"mask_1\":0},\"min_grade\":0,\"label\":\"Tenue\"}]}'),
(7, 'pillboxhopital', 'shop', 'Boutique', '{\"z\":43.28,\"h\":194.48,\"x\":306.52,\"y\":-601.5}', 0, '{\"public\":false,\"items\":[{\"name\":\"water\",\"price\":10,\"min_grade\":0,\"label\":\"Bouteille d\'eau\"}]}'),
(11, 'pdm', 'display', 'Véhicule expo', '{\"z\":26.42,\"h\":293.66,\"x\":-47.88,\"y\":-1101.36}', 0, '{\"model\":\"sultan\",\"color\":4}'),
(12, 'pdm', 'showroom', 'Showroom', '{\"z\":26.42,\"h\":311.5,\"x\":-33.26,\"y\":-1099.74}', 0, '{\"spawn\":{\"z\":26.42,\"h\":324.16,\"x\":-31.98,\"y\":-1090.59}}'),
(13, 'pdm', 'boss', 'Gestion boss', '{\"z\":26.42,\"h\":238.33,\"x\":-31.35,\"y\":-1106.47}', 3, '[]'),
(14, 'pdm', 'missions', 'Missions PNJ', '{\"z\":26.42,\"h\":335.38,\"x\":-42.56,\"y\":-1092.72}', 0, '{\"spawn\":{\"z\":26.42,\"h\":335.38,\"x\":-42.56,\"y\":-1092.72}}'),
(15, 'pdm', 'stash', 'Coffre', '{\"z\":26.42,\"h\":12.43,\"x\":-29.15,\"y\":-1103.59}', 0, '{\"weight\":100,\"slots\":50}'),
(16, 'lspd', 'garage', 'Garage', '{\"z\":21.45,\"y\":-981.41,\"x\":452.29,\"h\":108.48}', 0, '{\"store\":{\"coords\":{\"z\":21.45,\"y\":-977.62,\"x\":432.9,\"h\":171.75},\"radius\":5,\"any\":false},\"spawn\":{\"z\":21.45,\"y\":-980.75,\"x\":444.27,\"h\":265.74},\"vehicles\":[{\"model\":\"police\",\"min_grade\":0,\"label\":\"police\"}],\"kind\":\"car\"}'),
(17, 'bennys', 'tuning', 'Atelier tuning', '{\"z\":31.3,\"y\":-1318.83,\"x\":-201.79,\"h\":356.75}', 0, '{\"radius\":6}'),
(18, 'bennys', 'boss', 'Gestion boss', '{\"z\":31.3,\"y\":-1315.86,\"x\":-194.81,\"h\":248.72}', 3, '[]'),
(19, 'bennys', 'cloakroom', 'Vestiaire', '{\"z\":31.3,\"y\":-1339.0,\"x\":-206.64,\"h\":172.55}', 0, '{\"outfits\":[]}'),
(20, 'bennys', 'garage', 'Garage', '{\"z\":31.3,\"y\":-1332.92,\"x\":-232.7,\"h\":267.27}', 0, '{\"store\":{\"coords\":{\"z\":31.3,\"y\":-1315.43,\"x\":-234.01,\"h\":128.08},\"radius\":5,\"any\":false},\"spawn\":{\"z\":31.3,\"y\":-1338.91,\"x\":-234.56,\"h\":1.7},\"vehicles\":[{\"model\":\"sultan\",\"min_grade\":0,\"label\":\"Sultan\"}],\"kind\":\"car\"}'),
(22, 'banque', 'boss', 'Gestion boss', '{\"z\":30.65,\"h\":219.36,\"x\":44.45,\"y\":-858.24}', 3, '[]'),
(23, 'banque', 'garage', 'Garage', '{\"z\":30.4,\"h\":263.27,\"x\":40.7,\"y\":-873.59}', 0, '{\"vehicles\":[{\"label\":\"tolrs6\",\"model\":\"tolrs6\",\"color\":23,\"min_grade\":3}],\"spawn\":{\"z\":30.28,\"h\":345.19,\"x\":24.15,\"y\":-878.45},\"kind\":\"car\",\"store\":{\"coords\":{\"z\":30.27,\"h\":241.52,\"x\":39.65,\"y\":-882.92},\"any\":false,\"radius\":5}}'),
(24, 'banque', 'missions', 'Missions PNJ', '{\"z\":30.33,\"h\":0.28,\"x\":33.0,\"y\":-876.82}', 0, '[]');

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `jobbuilder_settings`
--

CREATE TABLE `jobbuilder_settings` (
  `name` varchar(40) NOT NULL,
  `value` longtext NOT NULL,
  `updated_by` varchar(100) DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `jobbuilder_settings`
--

INSERT INTO `jobbuilder_settings` (`name`, `value`, `updated_by`, `updated_at`) VALUES
('pointTypes', '{\"garage_return\":{\"color\":[64,224,208],\"offset\":-0.95000000000004,\"marker\":25,\"scale\":{\"z\":0.5999999999999,\"y\":0.90000000000009,\"x\":0.90000000000009},\"bob\":false,\"alpha\":140,\"label\":\"Rangement véhicule\",\"rotate\":false},\"garage\":{\"color\":[64,224,208],\"offset\":-0.95000000000004,\"marker\":25,\"scale\":{\"z\":0.5999999999999,\"y\":0.90000000000009,\"x\":0.90000000000009},\"bob\":false,\"alpha\":140,\"label\":\"Garage\",\"rotate\":false},\"garage_boat\":{\"color\":[64,224,208],\"marker\":25,\"bob\":false,\"alpha\":140,\"label\":\"Garage bateaux\",\"rotate\":false,\"offset\":-0.95000000000004,\"scale\":{\"z\":0.5999999999999,\"y\":0.90000000000009,\"x\":0.90000000000009},\"hidden\":true},\"garage_aircraft\":{\"color\":[64,224,208],\"marker\":25,\"bob\":false,\"alpha\":140,\"label\":\"Garage aéronefs\",\"rotate\":false,\"offset\":-0.95000000000004,\"scale\":{\"z\":0.5999999999999,\"y\":0.90000000000009,\"x\":0.90000000000009},\"hidden\":true},\"showroom\":{\"color\":[64,224,208],\"offset\":-0.95000000000004,\"marker\":25,\"scale\":{\"z\":0.5999999999999,\"y\":0.90000000000009,\"x\":0.90000000000009},\"bob\":false,\"alpha\":140,\"label\":\"Showroom\",\"rotate\":false},\"boss\":{\"color\":[64,224,208],\"offset\":-0.95000000000004,\"marker\":25,\"scale\":{\"z\":0.5999999999999,\"y\":0.90000000000009,\"x\":0.90000000000009},\"bob\":false,\"alpha\":140,\"label\":\"Gestion boss\",\"rotate\":false},\"shop\":{\"color\":[75,22,22],\"offset\":-0.95000000000004,\"marker\":25,\"scale\":{\"z\":0.5999999999999,\"y\":0.90000000000009,\"x\":0.90000000000009},\"bob\":false,\"alpha\":140,\"label\":\"Boutique\",\"rotate\":false},\"stash\":{\"color\":[64,224,208],\"offset\":-0.95000000000004,\"marker\":25,\"scale\":{\"z\":0.5999999999999,\"y\":0.90000000000009,\"x\":0.90000000000009},\"bob\":false,\"alpha\":140,\"label\":\"Coffre\",\"rotate\":false},\"garage_bike\":{\"color\":[64,224,208],\"marker\":25,\"bob\":false,\"alpha\":140,\"label\":\"Garage motos\",\"rotate\":false,\"offset\":-0.95000000000004,\"scale\":{\"z\":0.5999999999999,\"y\":0.90000000000009,\"x\":0.90000000000009},\"hidden\":true},\"armory\":{\"color\":[64,224,208],\"offset\":-0.95000000000004,\"marker\":25,\"scale\":{\"z\":0.5999999999999,\"y\":0.90000000000009,\"x\":0.90000000000009},\"bob\":false,\"alpha\":140,\"label\":\"Armurerie\",\"rotate\":false},\"kitchen\":{\"color\":[64,224,208],\"offset\":-0.95000000000004,\"marker\":25,\"scale\":{\"z\":0.5999999999999,\"y\":0.90000000000009,\"x\":0.90000000000009},\"bob\":false,\"alpha\":140,\"label\":\"Cuisine / Bar\",\"rotate\":false},\"display\":{\"color\":[64,224,208],\"offset\":-0.95000000000004,\"marker\":25,\"scale\":{\"z\":0.5999999999999,\"y\":0.90000000000009,\"x\":0.90000000000009},\"bob\":false,\"alpha\":140,\"label\":\"Véhicule expo\",\"rotate\":false},\"missions\":{\"color\":[64,224,208],\"offset\":-0.95000000000004,\"marker\":25,\"scale\":{\"z\":0.5999999999999,\"y\":0.90000000000009,\"x\":0.90000000000009},\"bob\":false,\"alpha\":140,\"label\":\"Missions PNJ\",\"rotate\":false},\"tuning\":{\"color\":[64,224,208],\"offset\":-0.95000000000004,\"marker\":25,\"scale\":{\"z\":0.5999999999999,\"y\":0.90000000000009,\"x\":0.90000000000009},\"bob\":false,\"alpha\":140,\"label\":\"Atelier tuning\",\"rotate\":false},\"harvest\":{\"color\":[64,224,208],\"offset\":-0.95000000000004,\"marker\":25,\"scale\":{\"z\":0.5999999999999,\"y\":0.90000000000009,\"x\":0.90000000000009},\"bob\":false,\"alpha\":140,\"label\":\"Récolte\",\"rotate\":false},\"cloakroom\":{\"color\":[64,224,208],\"offset\":-0.95000000000004,\"marker\":25,\"scale\":{\"z\":0.5999999999999,\"y\":0.90000000000009,\"x\":0.90000000000009},\"bob\":false,\"alpha\":140,\"label\":\"Vestiaire\",\"rotate\":false},\"testdrive\":{\"color\":[64,224,208],\"offset\":-0.95000000000004,\"marker\":25,\"scale\":{\"z\":0.5999999999999,\"y\":0.90000000000009,\"x\":0.90000000000009},\"bob\":false,\"alpha\":140,\"label\":\"Essai routier\",\"rotate\":false}}', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', '2026-10-10 22:17:06'),
('police', '{\"CallCooldown\":30,\"PursuitMax\":900,\"NearbyRange\":80,\"MaxCalls\":100,\"Landmarks\":[[\"Legion Square\",195,-933],[\"Hôpital Pillbox\",298,-584],[\"Mission Row\",428,-984],[\"Vinewood\",300,200],[\"Aéroport LSIA\",-1037,-2737],[\"Del Perro\",-1850,-1233],[\"Port de LS\",1000,-3000],[\"Mirror Park\",1050,-500],[\"Sandy Shores\",1961,3741],[\"Grapeseed\",2500,4700],[\"Mont Chiliad\",450,5600],[\"Paleto Bay\",-140,6240],[\"Fort Zancudo\",-2300,3200],[\"Prison\",1700,2600],[\"Raton Canyon\",-1500,4400],[\"Barrage\",-300,1900]],\"Map\":{\"MaxY\":8429.300000000745,\"Tiles\":\"map/mapStyles/styleAtlas/{z}/{x}/{y}.jpg\",\"TileMaxZoom\":5,\"MinY\":-4058.5,\"MinX\":-5661,\"Image\":\"\",\"MaxX\":6693.9000000003729},\"CallCommand\":\"appel\",\"PanicCommand\":\"panic\",\"DefaultFines\":[{\"amount\":250,\"label\":\"Excès de vitesse\"},{\"amount\":600,\"label\":\"Conduite dangereuse\"},{\"amount\":1500,\"label\":\"Refus d\'obtempérer\"},{\"amount\":150,\"label\":\"Stationnement gênant\"},{\"amount\":2500,\"label\":\"Port d\'arme illégal\"},{\"amount\":800,\"label\":\"Trouble à l\'ordre public\"}],\"PursuitTrail\":40,\"RefreshMs\":2000,\"ClosedKeepMinutes\":30,\"MinFine\":1,\"MaxFine\":50000}', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', '2026-10-05 10:33:04'),
('ui', '{\"Accent\":[239,68,68]}', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', '2026-10-10 22:11:05'),
('_seen_bank', '1', NULL, '2026-10-12 12:22:53');

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `jobs`
--

CREATE TABLE `jobs` (
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `label` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `whitelisted` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `jobs`
--

INSERT INTO `jobs` (`name`, `label`, `whitelisted`) VALUES
('ambulance', 'Ambulance', 1),
('banque', 'Banque', 1),
('bennys', 'Bennys', 1),
('pillboxhopital', 'PillboxHopital', 1),
('pdm', 'Pdm', 1),
('lspd', 'Lspd', 1),
('unemployed', 'Chomeur', 0),
('unemployed2', 'Aucune', 1),
('LsCustoms', 'lscustoms', 1);

-- --------------------------------------------------------

--
-- Table structure for table `jobs2`
--

CREATE TABLE `jobs2` (
  `name` varchar(50) NOT NULL,
  `label` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `jobs2`
--

INSERT INTO `jobs2` (`name`, `label`) VALUES
('ballas', 'Ballas'),
('cayoperico', 'CayoPerico'),
('famillies', 'Famillies'),
('unemployed2', 'Unemployed2'),
('vagos', 'Vagos');

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
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `job_grades`
--

INSERT INTO `job_grades` (`id`, `job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES
(1, 'ambulance', 0, 'ambulance', 'Ambulancier', 350, '{\"beard_1\":0,\"eye_color\":0,\"makeup_3\":0,\"blemishes_1\":0,\"mask_1\":0,\"glasses_1\":0,\"bproof_2\":0,\"lipstick_3\":0,\"beard_2\":0,\"torso_1\":249,\"pants_1\":24,\"blush_3\":0,\"torso_2\":0,\"blush_2\":0,\"complexion_1\":0,\"lipstick_2\":0,\"makeup_2\":0,\"bproof_1\":0,\"sun_2\":0,\"complexion_2\":0,\"chain_2\":0,\"sun_1\":0,\"eyebrows_3\":0,\"tshirt_1\":94,\"hair_color_1\":0,\"eyebrows_2\":0,\"mask_2\":0,\"helmet_2\":0,\"hair_2\":0,\"beard_3\":0,\"moles_2\":0,\"bags_1\":0,\"arms_2\":0,\"decals_2\":0,\"age_1\":0,\"ears_1\":-1,\"moles_1\":0,\"bracelets_2\":0,\"watches_1\":-1,\"face\":0,\"bags_2\":0,\"pants_2\":5,\"chest_3\":0,\"blemishes_2\":0,\"chest_1\":0,\"hair_color_2\":0,\"blush_1\":0,\"tshirt_2\":0,\"helmet_1\":-1,\"hair_1\":0,\"shoes_2\":0,\"lipstick_4\":0,\"eyebrows_4\":0,\"ears_2\":0,\"watches_2\":0,\"bodyb_2\":0,\"bodyb_1\":0,\"eyebrows_1\":0,\"decals_1\":57,\"makeup_4\":0,\"glasses_2\":0,\"age_2\":0,\"shoes_1\":8,\"arms\":90,\"chain_1\":126,\"bracelets_1\":-1,\"chest_2\":0,\"beard_4\":0,\"makeup_1\":0,\"lipstick_1\":0,\"skin\":0,\"sex\":0}', '{\"age_1\":0,\"blush_3\":0,\"complexion_2\":0,\"bracelets_2\":0,\"chain_2\":0,\"bodyb_1\":0,\"pants_1\":23,\"hair_1\":4,\"lipstick_4\":0,\"bproof_2\":0,\"bodyb_2\":0,\"shoes_2\":1,\"sun_2\":0,\"blush_1\":0,\"shoes_1\":4,\"decals_1\":65,\"eyebrows_2\":10,\"makeup_1\":6,\"glasses\":0,\"chest_3\":0,\"bags_2\":0,\"arms\":105,\"watches_1\":2,\"arms_2\":0,\"hair_color_1\":28,\"beard_3\":0,\"chain_1\":96,\"chest_1\":0,\"mask_1\":0,\"sex\":1,\"decals_2\":0,\"bproof_1\":0,\"hair_color_2\":28,\"eyebrows_3\":61,\"makeup_2\":8,\"helmet_1\":-1,\"bags_1\":0,\"lipstick_3\":23,\"face\":45,\"bracelets_1\":-1,\"tshirt_1\":29,\"beard_4\":0,\"moles_2\":10,\"mask_2\":0,\"helmet_2\":0,\"makeup_3\":25,\"skin\":10,\"beard_2\":0,\"shoes\":1,\"blemishes_2\":0,\"moles_1\":0,\"pants_2\":0,\"complexion_1\":0,\"glasses_2\":1,\"age_2\":0,\"ears_1\":12,\"watches_2\":0,\"eyebrows_4\":0,\"eye_color\":3,\"lipstick_2\":4,\"glasses_1\":11,\"eyebrows_1\":1,\"ears_2\":0,\"makeup_4\":18,\"sun_1\":0,\"blush_2\":0,\"torso_2\":0,\"chest_2\":0,\"hair_2\":0,\"tshirt_2\":0,\"torso_1\":257,\"lipstick_1\":1,\"blemishes_1\":0,\"beard_1\":0}'),
(2, 'ambulance', 1, 'doctor', 'Medecin', 500, '{\"beard_1\":0,\"eye_color\":0,\"makeup_3\":0,\"blemishes_1\":0,\"mask_1\":0,\"glasses_1\":0,\"bproof_2\":0,\"lipstick_3\":0,\"beard_2\":0,\"torso_1\":13,\"pants_1\":24,\"blush_3\":0,\"torso_2\":3,\"blush_2\":0,\"complexion_1\":0,\"lipstick_2\":0,\"makeup_2\":0,\"bproof_1\":0,\"sun_2\":0,\"complexion_2\":0,\"chain_2\":0,\"sun_1\":0,\"eyebrows_3\":0,\"tshirt_1\":15,\"hair_color_1\":0,\"eyebrows_2\":0,\"mask_2\":0,\"helmet_2\":0,\"hair_2\":0,\"beard_3\":0,\"moles_2\":0,\"bags_1\":0,\"arms_2\":0,\"decals_2\":0,\"age_1\":0,\"ears_1\":-1,\"moles_1\":0,\"bracelets_2\":0,\"watches_1\":-1,\"face\":0,\"bags_2\":0,\"pants_2\":5,\"chest_3\":0,\"blemishes_2\":0,\"chest_1\":0,\"hair_color_2\":0,\"blush_1\":0,\"tshirt_2\":0,\"helmet_1\":-1,\"hair_1\":0,\"shoes_2\":9,\"lipstick_4\":0,\"eyebrows_4\":0,\"ears_2\":0,\"watches_2\":0,\"bodyb_2\":0,\"bodyb_1\":0,\"eyebrows_1\":0,\"decals_1\":57,\"makeup_4\":0,\"glasses_2\":0,\"age_2\":0,\"shoes_1\":57,\"arms\":92,\"chain_1\":126,\"bracelets_1\":-1,\"chest_2\":0,\"beard_4\":0,\"makeup_1\":0,\"lipstick_1\":0,\"skin\":0,\"sex\":0}', '{\"age_1\":0,\"blush_3\":0,\"complexion_2\":0,\"bracelets_2\":0,\"chain_2\":0,\"bodyb_1\":0,\"pants_1\":51,\"hair_1\":4,\"lipstick_4\":0,\"bproof_2\":0,\"bodyb_2\":0,\"shoes_2\":7,\"sun_2\":0,\"blush_1\":0,\"shoes_1\":1,\"decals_1\":66,\"eyebrows_2\":10,\"makeup_1\":6,\"glasses\":0,\"chest_3\":0,\"bags_2\":0,\"arms\":106,\"watches_1\":2,\"arms_2\":0,\"hair_color_1\":28,\"beard_3\":0,\"chain_1\":96,\"chest_1\":0,\"mask_1\":0,\"sex\":1,\"decals_2\":0,\"bproof_1\":0,\"hair_color_2\":28,\"eyebrows_3\":61,\"makeup_2\":8,\"helmet_1\":-1,\"bags_1\":0,\"lipstick_3\":23,\"face\":45,\"bracelets_1\":-1,\"tshirt_1\":29,\"beard_4\":0,\"moles_2\":10,\"mask_2\":0,\"helmet_2\":0,\"makeup_3\":25,\"skin\":10,\"beard_2\":0,\"shoes\":1,\"blemishes_2\":0,\"moles_1\":0,\"pants_2\":0,\"complexion_1\":0,\"glasses_2\":1,\"age_2\":0,\"ears_1\":12,\"watches_2\":0,\"eyebrows_4\":0,\"eye_color\":3,\"lipstick_2\":4,\"glasses_1\":11,\"eyebrows_1\":1,\"ears_2\":0,\"makeup_4\":18,\"sun_1\":0,\"blush_2\":0,\"torso_2\":2,\"chest_2\":0,\"hair_2\":0,\"tshirt_2\":0,\"torso_1\":9,\"lipstick_1\":1,\"blemishes_1\":0,\"beard_1\":0}'),
(3, 'ambulance', 2, 'chief_doctor', 'Médecin-Chef', 700, '{\"beard_1\":0,\"eye_color\":0,\"makeup_3\":0,\"blemishes_1\":0,\"mask_1\":0,\"glasses_1\":0,\"bproof_2\":0,\"lipstick_3\":0,\"beard_2\":0,\"torso_1\":250,\"pants_1\":24,\"blush_3\":0,\"torso_2\":0,\"blush_2\":0,\"complexion_1\":0,\"lipstick_2\":0,\"makeup_2\":0,\"bproof_1\":0,\"sun_2\":0,\"complexion_2\":0,\"chain_2\":0,\"sun_1\":0,\"eyebrows_3\":0,\"tshirt_1\":15,\"hair_color_1\":0,\"eyebrows_2\":0,\"mask_2\":0,\"helmet_2\":0,\"hair_2\":0,\"beard_3\":0,\"moles_2\":0,\"bags_1\":0,\"arms_2\":0,\"decals_2\":0,\"age_1\":0,\"ears_1\":-1,\"moles_1\":0,\"bracelets_2\":0,\"watches_1\":-1,\"face\":0,\"bags_2\":0,\"pants_2\":5,\"chest_3\":0,\"blemishes_2\":0,\"chest_1\":0,\"hair_color_2\":0,\"blush_1\":0,\"tshirt_2\":0,\"helmet_1\":-1,\"hair_1\":0,\"shoes_2\":0,\"lipstick_4\":0,\"eyebrows_4\":0,\"ears_2\":0,\"watches_2\":0,\"bodyb_2\":0,\"bodyb_1\":0,\"eyebrows_1\":0,\"decals_1\":57,\"makeup_4\":0,\"glasses_2\":0,\"age_2\":0,\"shoes_1\":26,\"arms\":74,\"chain_1\":126,\"bracelets_1\":-1,\"chest_2\":0,\"beard_4\":0,\"makeup_1\":0,\"lipstick_1\":0,\"skin\":0,\"sex\":0}', '{\"age_1\":0,\"blush_3\":0,\"complexion_2\":0,\"bracelets_2\":0,\"chain_2\":0,\"bodyb_1\":0,\"pants_1\":50,\"hair_1\":4,\"lipstick_4\":0,\"bproof_2\":0,\"bodyb_2\":0,\"shoes_2\":2,\"sun_2\":0,\"blush_1\":0,\"shoes_1\":4,\"decals_1\":66,\"eyebrows_2\":10,\"makeup_1\":6,\"glasses\":0,\"chest_3\":0,\"bags_2\":0,\"arms\":96,\"watches_1\":2,\"arms_2\":0,\"hair_color_1\":28,\"beard_3\":0,\"chain_1\":96,\"chest_1\":0,\"mask_1\":0,\"sex\":1,\"decals_2\":0,\"bproof_1\":0,\"hair_color_2\":28,\"eyebrows_3\":61,\"makeup_2\":8,\"helmet_1\":-1,\"bags_1\":0,\"lipstick_3\":23,\"face\":45,\"bracelets_1\":-1,\"tshirt_1\":29,\"beard_4\":0,\"moles_2\":10,\"mask_2\":0,\"helmet_2\":0,\"makeup_3\":25,\"skin\":10,\"beard_2\":0,\"shoes\":1,\"blemishes_2\":0,\"moles_1\":0,\"pants_2\":0,\"complexion_1\":0,\"glasses_2\":1,\"age_2\":0,\"ears_1\":12,\"watches_2\":0,\"eyebrows_4\":0,\"eye_color\":3,\"lipstick_2\":4,\"glasses_1\":11,\"eyebrows_1\":1,\"ears_2\":0,\"makeup_4\":18,\"sun_1\":0,\"blush_2\":0,\"torso_2\":0,\"chest_2\":0,\"hair_2\":0,\"tshirt_2\":0,\"torso_1\":258,\"lipstick_1\":1,\"blemishes_1\":0,\"beard_1\":0}'),
(4, 'ambulance', 3, 'boss', 'Directeur', 900, '{\"beard_1\":0,\"eye_color\":0,\"makeup_3\":0,\"blemishes_1\":0,\"mask_1\":0,\"glasses_1\":5,\"bproof_2\":0,\"lipstick_3\":0,\"eyebrows_4\":0,\"torso_1\":102,\"pants_1\":24,\"blush_3\":0,\"torso_2\":1,\"blush_2\":0,\"complexion_1\":0,\"lipstick_2\":0,\"makeup_2\":0,\"bproof_1\":35,\"sun_2\":0,\"makeup_4\":0,\"chain_2\":0,\"sun_1\":0,\"eyebrows_3\":0,\"tshirt_1\":72,\"hair_color_1\":14,\"hair_1\":49,\"mask_2\":0,\"helmet_2\":0,\"hair_2\":0,\"beard_3\":0,\"moles_2\":0,\"bags_1\":0,\"arms_2\":0,\"decals_2\":0,\"age_1\":0,\"ears_1\":-1,\"moles_1\":0,\"lipstick_4\":0,\"arms\":75,\"face\":0,\"eyebrows_1\":0,\"pants_2\":5,\"chest_3\":0,\"chest_1\":0,\"bodyb_2\":0,\"beard_2\":0,\"glasses_2\":1,\"tshirt_2\":4,\"helmet_1\":-1,\"blush_1\":0,\"bags_2\":0,\"decals_1\":0,\"watches_1\":1,\"chain_1\":126,\"watches_2\":0,\"bracelets_1\":-1,\"bodyb_1\":0,\"bracelets_2\":0,\"ears_2\":0,\"lipstick_1\":0,\"blemishes_2\":0,\"age_2\":0,\"shoes_2\":1,\"complexion_2\":0,\"shoes_1\":30,\"beard_4\":0,\"chest_2\":0,\"hair_color_2\":0,\"makeup_1\":0,\"eyebrows_2\":0,\"skin\":0,\"sex\":0}', '{\"age_1\":0,\"blush_3\":0,\"complexion_2\":0,\"bracelets_2\":0,\"chain_2\":0,\"bodyb_1\":0,\"pants_1\":51,\"hair_1\":4,\"lipstick_4\":0,\"bproof_2\":0,\"bodyb_2\":0,\"shoes_2\":2,\"sun_2\":0,\"blush_1\":0,\"shoes_1\":81,\"decals_1\":66,\"eyebrows_2\":10,\"makeup_1\":6,\"glasses\":0,\"chest_3\":0,\"bags_2\":0,\"arms\":96,\"watches_1\":2,\"arms_2\":0,\"hair_color_1\":28,\"beard_3\":0,\"chain_1\":96,\"chest_1\":0,\"mask_1\":0,\"sex\":1,\"decals_2\":0,\"bproof_1\":0,\"hair_color_2\":28,\"eyebrows_3\":61,\"makeup_2\":8,\"helmet_1\":-1,\"bags_1\":0,\"lipstick_3\":23,\"face\":45,\"bracelets_1\":-1,\"tshirt_1\":29,\"beard_4\":0,\"moles_2\":10,\"mask_2\":0,\"helmet_2\":0,\"makeup_3\":25,\"skin\":10,\"beard_2\":0,\"shoes\":1,\"blemishes_2\":0,\"moles_1\":0,\"pants_2\":0,\"complexion_1\":0,\"glasses_2\":1,\"age_2\":0,\"ears_1\":12,\"watches_2\":0,\"eyebrows_4\":0,\"eye_color\":3,\"lipstick_2\":4,\"glasses_1\":11,\"eyebrows_1\":1,\"ears_2\":0,\"makeup_4\":18,\"sun_1\":0,\"blush_2\":0,\"torso_2\":2,\"chest_2\":0,\"hair_2\":0,\"tshirt_2\":0,\"torso_1\":14,\"lipstick_1\":1,\"blemishes_1\":0,\"beard_1\":0}'),
(18226, 'lspd', 4, 'boss', 'Commissaire', 800, '{}', '{}'),
(74, 'unemployed', 0, 'unemployed', 'RSA', 25, '{}', '{}'),
(157, 'unemployed2', 0, 'unemployed2', 'Citoyen', 0, '{}', '{}'),
(18262, 'banque', 3, 'boss', 'Directeur', 900, '{}', '{}'),
(18261, 'banque', 2, 'advisor', 'Conseiller financier', 550, '{}', '{}'),
(18259, 'banque', 0, 'trainee', 'Stagiaire', 200, '{}', '{}'),
(18260, 'banque', 1, 'teller', 'Chargé de clientèle', 350, '{}', '{}'),
(18220, 'bennys', 2, 'chief', 'Chef d\'atelier', 400, '{}', '{}'),
(18221, 'bennys', 3, 'boss', 'Patron', 600, '{}', '{}'),
(18219, 'bennys', 1, 'novice', 'Mécanicien', 250, '{}', '{}'),
(18218, 'bennys', 0, 'recrue', 'Apprenti', 150, '{}', '{}'),
(18224, 'lspd', 2, 'sergeant', 'Sergent', 300, '{}', '{}'),
(18223, 'lspd', 1, 'officer', 'Agent', 200, '{}', '{}'),
(18222, 'lspd', 0, 'recruit', 'Recrue', 100, '{}', '{}'),
(18225, 'lspd', 3, 'lieutenant', 'Lieutenant', 500, '{}', '{}'),
(18120, 'pdm', 1, 'vendeur', 'Vendeur', 300, '{}', '{}'),
(18121, 'pdm', 2, 'chef', 'Chef des ventes', 500, '{}', '{}'),
(18122, 'pdm', 3, 'boss', 'Directeur', 800, '{}', '{}'),
(17627, 'LsCustoms', 2, 'boss', 'PDG', 5000, '{}', '{}'),
(17626, 'LsCustoms', 0, 'employer', 'Employer', 1250, '{}', '{}'),
(18119, 'pdm', 0, 'stagiaire', 'Stagiaire', 150, '{}', '{}'),
(18034, 'pillboxhopital', 3, 'boss', 'Directeur', 900, '{}', '{}'),
(18033, 'pillboxhopital', 2, 'chief_doctor', 'Médecin-chef', 700, '{}', '{}'),
(18032, 'pillboxhopital', 1, 'doctor', 'Médecin', 500, '{}', '{}'),
(18031, 'pillboxhopital', 0, 'ambulance', 'Ambulancier', 350, '{}', '{}'),
(17628, 'LsCustoms', 1, 'responsable', 'Responsable', 2500, '{}', '{}');

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
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `licenses`
--

CREATE TABLE `licenses` (
  `type` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `label` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `licenses`
--

INSERT INTO `licenses` (`type`, `label`) VALUES
('code', 'Code de la route'),
('drive', 'Permis de conduire'),
('drive_bike', 'Permis moto'),
('drive_truck', 'Permis camion'),
('weapon', 'PPA');

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
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `newplayer_playtime`
--

CREATE TABLE `newplayer_playtime` (
  `identifier` varchar(80) NOT NULL,
  `played_seconds` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `newplayer_playtime`
--

INSERT INTO `newplayer_playtime` (`identifier`, `played_seconds`, `updated_at`) VALUES
('license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 161721, '2026-10-13 21:29:02'),
('license:17015558e9d71c65e5de4c4c417d582ba4f005f1', 14592, '2026-10-12 13:21:35'),
('license:1900e3062a0de4aadb8a6c959470425894c992fa', 631, '2026-09-27 17:04:00'),
('license:1d522f6effdc6a92e62688a34602bd08135739ce', 14064, '2026-10-04 18:08:59'),
('license:3afb15e367e2e7c2a142ecc8760f66805116c992', 24221, '2026-10-13 20:11:52');

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
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `open_car`
--

INSERT INTO `open_car` (`id`, `identifier`, `label`, `value`, `got`, `NB`) VALUES
(1, 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Cles', '04EAP598', 'true', 1),
(2, 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Cles', '77PHJ349', 'true', 1),
(3, 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Cles', '95VSW571', 'true', 1);

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
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

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
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `owned_vehicles`
--

INSERT INTO `owned_vehicles` (`owner`, `state`, `plate`, `name`, `vehicle`, `type`, `glovebox`, `trunk`) VALUES
('license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 1, '04EAP598', NULL, '{\"modFender\":-1,\"modLivery\":-1,\"color1\":111,\"modWindows\":-1,\"neonColor\":[255,0,255],\"modHorns\":-1,\"modRightFender\":-1,\"tankHealth\":1000.0,\"modSuspension\":-1,\"modOrnaments\":-1,\"pearlescentColor\":0,\"modCustomBackWheels\":false,\"modArchCover\":-1,\"modSeats\":-1,\"modSpoilers\":-1,\"modTrimA\":-1,\"modExhaust\":-1,\"modTrunk\":-1,\"modFrame\":-1,\"interiorColor\":0,\"modSteeringWheel\":-1,\"plateIndex\":0,\"modStruts\":-1,\"modHydrolic\":-1,\"modSmokeEnabled\":1,\"modEngine\":-1,\"tyresCanBurst\":1,\"modVanityPlate\":-1,\"dashboardColor\":0,\"bodyHealth\":1000.0,\"color2\":111,\"modTransmission\":-1,\"modXenon\":false,\"windowsBroken\":{\"0\":false,\"1\":false,\"2\":false,\"3\":false,\"4\":true,\"5\":true,\"6\":true,\"7\":false},\"modAerials\":-1,\"modFrontWheels\":-1,\"modEngineBlock\":-1,\"modRoofLivery\":-1,\"modGrille\":-1,\"modRoof\":-1,\"fuelLevel\":51.1,\"modAirFilter\":-1,\"plate\":\"04EAP598\",\"engineHealth\":1000.0,\"dirtLevel\":8.0,\"xenonColor\":255,\"tyreBurst\":{\"4\":false,\"1\":false,\"0\":false,\"5\":false},\"modDial\":-1,\"windowTint\":-1,\"doorsBroken\":{\"0\":false,\"1\":false,\"2\":false,\"3\":false},\"modBrakes\":-1,\"modFrontBumper\":-1,\"modCustomFrontWheels\":false,\"modDoorSpeaker\":-1,\"modTank\":-1,\"modBackWheels\":-1,\"modAPlate\":-1,\"modLightbar\":-1,\"modArmor\":-1,\"model\":-431692672,\"modSideSkirt\":-1,\"modShifterLeavers\":-1,\"wheels\":5,\"extras\":{\"1\":1,\"2\":1,\"3\":1,\"4\":1,\"5\":1},\"modPlateHolder\":-1,\"wheelColor\":156,\"modRearBumper\":-1,\"modDashboard\":-1,\"modTrimB\":-1,\"neonEnabled\":[false,false,false,false],\"driftTyresEnabled\":false,\"modTurbo\":false,\"modSpeakers\":-1,\"tyreSmokeColor\":[255,255,255],\"modHood\":-1}', 'car', NULL, NULL),
('license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 1, '95VSW571', NULL, '{\"modSuspension\":3,\"tyresCanBurst\":1,\"modAPlate\":-1,\"modTrimA\":-1,\"modFrontBumper\":-1,\"xenonColor\":255,\"modTank\":-1,\"modFrame\":-1,\"modRightFender\":-1,\"modArmor\":4,\"dashboardColor\":0,\"modGrille\":-1,\"modTrunk\":-1,\"modWindows\":-1,\"modDoorSpeaker\":-1,\"modTransmission\":2,\"modSpoilers\":-1,\"modCustomBackWheels\":false,\"doorsBroken\":{\"0\":false,\"1\":false,\"2\":false,\"3\":false,\"4\":false},\"pearlescentColor\":0,\"modFrontWheels\":4,\"tyreBurst\":{\"4\":false,\"1\":false,\"5\":false,\"0\":false},\"plateIndex\":1,\"modXenon\":false,\"modAirFilter\":-1,\"color2\":150,\"engineHealth\":999.2,\"windowTint\":3,\"color1\":29,\"driftTyresEnabled\":false,\"modTurbo\":1,\"tankHealth\":999.9,\"modAerials\":-1,\"modDashboard\":-1,\"modSpeakers\":-1,\"modEngineBlock\":-1,\"modPlateHolder\":-1,\"modDial\":-1,\"modSmokeEnabled\":1,\"wheelColor\":0,\"dirtLevel\":1.4,\"modSteeringWheel\":-1,\"model\":-673554578,\"modRoofLivery\":-1,\"interiorColor\":0,\"modRoof\":-1,\"fuelLevel\":74.0,\"neonColor\":[255,0,255],\"modHood\":-1,\"modBrakes\":2,\"modVanityPlate\":-1,\"modShifterLeavers\":-1,\"modLivery\":0,\"modFender\":-1,\"modArchCover\":-1,\"plate\":\"95VSW571\",\"modBackWheels\":-1,\"modExhaust\":-1,\"windowsBroken\":{\"0\":false,\"1\":false,\"2\":false,\"3\":false,\"4\":true,\"5\":true,\"6\":false,\"7\":false},\"modSideSkirt\":-1,\"tyreSmokeColor\":[255,255,255],\"wheels\":7,\"modHydrolic\":-1,\"modTrimB\":-1,\"modRearBumper\":-1,\"extras\":{\"2\":false,\"1\":1},\"neonEnabled\":[false,false,false,false],\"bodyHealth\":998.8,\"modLightbar\":-1,\"modCustomFrontWheels\":false,\"modHorns\":2,\"modOrnaments\":-1,\"modSeats\":-1,\"modStruts\":-1,\"modEngine\":3}', 'car', NULL, NULL),
('license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 1, '77PHJ349', NULL, '{\"modFender\":-1,\"modLivery\":-1,\"color1\":0,\"modWindows\":-1,\"neonColor\":[255,0,255],\"modHorns\":-1,\"modRightFender\":-1,\"tankHealth\":999.8,\"modSuspension\":-1,\"modOrnaments\":-1,\"pearlescentColor\":0,\"modCustomBackWheels\":false,\"modArchCover\":-1,\"modSeats\":-1,\"modSpoilers\":-1,\"modTrimA\":-1,\"modExhaust\":-1,\"modTrunk\":-1,\"modFrame\":-1,\"interiorColor\":0,\"modSteeringWheel\":-1,\"plateIndex\":2,\"modStruts\":-1,\"modHydrolic\":-1,\"modSmokeEnabled\":1,\"modEngine\":-1,\"tyresCanBurst\":1,\"modVanityPlate\":-1,\"dashboardColor\":0,\"bodyHealth\":998.5,\"color2\":0,\"modTransmission\":-1,\"modXenon\":false,\"windowsBroken\":{\"0\":false,\"1\":false,\"2\":false,\"3\":false,\"4\":false,\"5\":false,\"6\":false,\"7\":false},\"modAerials\":-1,\"modFrontWheels\":-1,\"modEngineBlock\":-1,\"modRoofLivery\":-1,\"modGrille\":-1,\"modRoof\":-1,\"fuelLevel\":74.0,\"modAirFilter\":-1,\"plate\":\"77PHJ349\",\"engineHealth\":999.5,\"dirtLevel\":4.4,\"xenonColor\":255,\"tyreBurst\":{\"4\":false,\"1\":false,\"0\":false,\"5\":false},\"modDial\":-1,\"windowTint\":-1,\"doorsBroken\":{\"0\":false,\"1\":false,\"2\":false,\"3\":false,\"4\":false,\"5\":false},\"modBrakes\":-1,\"modFrontBumper\":-1,\"modCustomFrontWheels\":false,\"modDoorSpeaker\":-1,\"modTank\":-1,\"modBackWheels\":-1,\"modAPlate\":-1,\"modLightbar\":-1,\"modArmor\":-1,\"model\":-473989337,\"modSideSkirt\":-1,\"modShifterLeavers\":-1,\"wheels\":7,\"extras\":{\"2\":false},\"modPlateHolder\":-1,\"wheelColor\":0,\"modRearBumper\":-1,\"modDashboard\":-1,\"modTrimB\":-1,\"neonEnabled\":[false,false,false,false],\"driftTyresEnabled\":false,\"modTurbo\":false,\"modSpeakers\":-1,\"tyreSmokeColor\":[255,255,255],\"modHood\":-1}', 'car', NULL, NULL);

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

--
-- Dumping data for table `ox_inventory`
--

INSERT INTO `ox_inventory` (`owner`, `name`, `data`, `lastupdated`) VALUES
('', 'gangbuilder_8', NULL, '2026-10-05 09:55:00');

-- --------------------------------------------------------

--
-- Table structure for table `ox_inventory_clothing`
--

CREATE TABLE `ox_inventory_clothing` (
  `owner` varchar(100) NOT NULL,
  `slots` longtext DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ox_inventory_medical`
--

CREATE TABLE `ox_inventory_medical` (
  `owner` varchar(100) NOT NULL,
  `data` longtext DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ox_inventory_outfits`
--

CREATE TABLE `ox_inventory_outfits` (
  `owner` varchar(100) NOT NULL,
  `outfits` longtext DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

--
-- Dumping data for table `pgang_objectives`
--

INSERT INTO `pgang_objectives` (`gang`, `day`, `id`, `progress`, `claimed`) VALUES
('pickax', 20261004, 'colis', 1, 1),
('pickax', 20261004, 'deposit', 10000, 1);

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phone_backups`
--

CREATE TABLE `phone_backups` (
  `id` varchar(100) NOT NULL,
  `phone_number` varchar(15) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `phone_backups`
--

INSERT INTO `phone_backups` (`id`, `phone_number`) VALUES
('license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', '2054919277');

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

--
-- Dumping data for table `phone_crypto_coins`
--

INSERT INTO `phone_crypto_coins` (`coin`, `coin_value`) VALUES
('lbc', 168.97426545106413);

-- --------------------------------------------------------

--
-- Table structure for table `phone_darkchat_accounts`
--

CREATE TABLE `phone_darkchat_accounts` (
  `phone_number` varchar(15) NOT NULL,
  `username` varchar(20) NOT NULL,
  `password` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `phone_darkchat_accounts`
--

INSERT INTO `phone_darkchat_accounts` (`phone_number`, `username`, `password`) VALUES
('2054919277', 'dqzdzqdzq', '$2a$11$XY3h7Vm59jT.gx87WuNzzuD2kdmbTUlZHVLZBVqMUlmsl4ehzSAWy');

-- --------------------------------------------------------

--
-- Table structure for table `phone_darkchat_channels`
--

CREATE TABLE `phone_darkchat_channels` (
  `name` varchar(50) NOT NULL,
  `password` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `phone_darkchat_channels`
--

INSERT INTO `phone_darkchat_channels` (`name`, `password`) VALUES
('test', '$2a$11$jX92vNZ3ETu4v7vNwUh8EOZuRrOQQF1vdEpUBMphjuU8RLeGm7I2i');

-- --------------------------------------------------------

--
-- Table structure for table `phone_darkchat_members`
--

CREATE TABLE `phone_darkchat_members` (
  `channel_name` varchar(50) NOT NULL,
  `username` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `phone_darkchat_members`
--

INSERT INTO `phone_darkchat_members` (`channel_name`, `username`) VALUES
('test', 'dqzdzqdzq');

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

--
-- Dumping data for table `phone_darkchat_messages`
--

INSERT INTO `phone_darkchat_messages` (`id`, `channel`, `sender`, `content`, `timestamp`) VALUES
(1, 'test', 'dqzdzqdzq', 'QZDQZDQZ', '2026-09-30 13:29:26');

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

--
-- Dumping data for table `phone_last_phone`
--

INSERT INTO `phone_last_phone` (`id`, `phone_number`) VALUES
('license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', '5204318368');

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

--
-- Dumping data for table `phone_logged_in_accounts`
--

INSERT INTO `phone_logged_in_accounts` (`phone_number`, `app`, `username`, `active`) VALUES
('2054919277', 'DarkChat', 'dqzdzqdzq', 1);

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

--
-- Dumping data for table `phone_phones`
--

INSERT INTO `phone_phones` (`id`, `owner_id`, `phone_number`, `name`, `pin`, `face_id`, `settings`, `is_setup`, `assigned`, `battery`, `last_seen`) VALUES
('4i5vS', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', '5204318368', NULL, NULL, NULL, NULL, 0, 1, 100, '2026-10-12 12:24:17'),
('95y3b', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', '2054919277', 'Téléphone de Maly', '1407', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', '{\"security\":{\"pinCode\":true,\"faceId\":true},\"locale\":\"fr\",\"sound\":{\"silent\":false,\"volume\":0.5,\"ringtone\":\"default\",\"callVolume\":0.5,\"texttone\":\"default\"},\"notifications\":[],\"version\":\"2.9.0\",\"name\":\"Téléphone de Maly\",\"wallpaper\":{\"blur\":false,\"background\":\"cloud8\"},\"storage\":{\"total\":128000000,\"used\":9155631},\"doNotDisturb\":false,\"streamerMode\":false,\"latestVersion\":\"2.9.0\",\"time\":{\"twelveHourClock\":false},\"airplaneMode\":false,\"weather\":{\"celcius\":false},\"lockscreen\":{\"fontStyle\":1,\"layout\":1,\"color\":\"gradient\"},\"phone\":{\"showCallerId\":true},\"apps\":[[\"Phone\",\"Messages\",\"Camera\",\"Photos\"],[\"Settings\",\"AppStore\",\"Clock\",\"Mail\",\"Weather\",\"Browser\",\"Wallet\",\"Garage\",\"Home\",\"Maps\",\"Notes\",\"Calculator\",\"VoiceMemo\",\"Music\",\"Services\",\"Tinder\",\"Crypto\",\"TikTok\",\"DarkChat\",\"YellowPages\",\"Twitter\",\"Instagram\",\"MarketPlace\"]],\"display\":{\"theme\":\"dark\",\"size\":0.7,\"automatic\":false,\"brightness\":1}}', 1, 1, 100, '2026-09-30 14:51:55');

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

--
-- Dumping data for table `pickax_chase_maps`
--

INSERT INTO `pickax_chase_maps` (`id`, `label`, `description`, `x`, `y`, `z`, `h`) VALUES
('freeway', 'Del Perro Freeway', 'Autoroute rapide, idéale pour les supercars.', -1105, -520, 34, 215),
('sandy', 'Route 68 – Sandy', 'Longues lignes droites dans le désert.', 1583, 3584, 35.400001525878906, 300),
('vinewood', 'Vinewood Boulevard', 'Grandes avenues et carrefours, trafic dense.', 293.1000061035156, 180.5, 104.19999694824219, 70);

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `pickax_chase_settings`
--

CREATE TABLE `pickax_chase_settings` (
  `name` varchar(40) NOT NULL,
  `value` varchar(40) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

--
-- Dumping data for table `pickax_chase_settings`
--

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

--
-- Dumping data for table `pickax_chase_vehicles`
--

INSERT INTO `pickax_chase_vehicles` (`model`, `label`, `category`, `speed`, `accel`, `handling`) VALUES
('adder', 'Truffade Adder', 'Super', 92, 82, 72),
('akuma', 'Dinka Akuma', 'Moto', 82, 90, 80),
('bati', 'Pegassi Bati 801', 'Moto', 84, 92, 82),
('buffalo', 'Bravado Buffalo', 'Berline', 70, 68, 70),
('comet2', 'Pfister Comet', 'Sportive', 76, 72, 77),
('dominator', 'Vapid Dominator', 'Muscle', 74, 78, 55),
('elegy2', 'Annis Elegy RH8', 'Sportive', 74, 70, 78),
('gauntlet', 'Bravado Gauntlet', 'Muscle', 72, 76, 52),
('jester', 'Dinka Jester', 'Sportive', 78, 74, 75),
('kuruma', 'Karin Kuruma', 'Sportive', 72, 70, 70),
('sanchez', 'Maibatsu Sanchez', 'Moto', 62, 74, 78),
('schafter3', 'Benefactor Schafter V12', 'Berline', 70, 66, 68),
('sultan', 'Karin Sultan', 'Sportive', 68, 66, 72),
('t20', 'Progen T20', 'Super', 93, 90, 78),
('vacca', 'Pegassi Vacca', 'Super', 86, 84, 78),
('zentorno', 'Pegassi Zentorno', 'Super', 90, 88, 80);

-- --------------------------------------------------------

--
-- Table structure for table `playerstattoos`
--

CREATE TABLE `playerstattoos` (
  `identifier` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `tattoos` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `p_outfits`
--

CREATE TABLE `p_outfits` (
  `id` int(11) NOT NULL,
  `identifier` varchar(80) NOT NULL,
  `name` varchar(60) NOT NULL,
  `data` longtext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

--
-- Dumping data for table `p_outfits`
--

INSERT INTO `p_outfits` (`id`, `identifier`, `name`, `data`) VALUES
(1, 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'TEST', '{\"shoes_1\":1,\"watches_2\":0,\"pants_1\":20,\"bracelets_1\":-1,\"torso_1\":22,\"glasses_1\":0,\"pants_2\":0,\"ears_1\":41,\"glasses_2\":0,\"ears_2\":4,\"chain_1\":49,\"watches_1\":4,\"arms\":0,\"bproof_1\":0,\"bproof_2\":0,\"tshirt_1\":15,\"shoes_2\":0,\"tshirt_2\":0,\"chain_2\":0,\"bracelets_2\":0,\"torso_2\":2,\"helmet_1\":-1,\"mask_2\":0,\"helmet_2\":-1,\"arms_2\":0,\"bags_1\":0,\"bags_2\":0,\"mask_1\":0}');

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
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `shopbuilder_logs`
--

INSERT INTO `shopbuilder_logs` (`id`, `shop_id`, `shop_label`, `identifier`, `player_name`, `action`, `detail`, `amount`, `created_at`) VALUES
(1, 1, 'superette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'superette (general) — 6 produit(s)', 0, '2026-10-05 16:40:01'),
(2, 1, 'superette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 0 emplacement(s), désactivée', 0, '2026-10-05 16:40:10'),
(3, 1, 'superette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 1 emplacement(s), désactivée', 0, '2026-10-05 16:40:22'),
(4, 1, 'superette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 1 emplacement(s), désactivée', 0, '2026-10-05 16:40:25'),
(5, 1, 'superette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 1 emplacement(s), active', 0, '2026-10-05 16:40:34'),
(6, 1, 'superette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 1 emplacement(s), active', 0, '2026-10-05 16:40:43'),
(7, 1, 'superette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'buy', '10x Eau — 30$ (Carte bancaire)', 30, '2026-10-05 16:41:06'),
(8, 1, 'superette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'buy', '1x Eau — 3$ (Carte bancaire)', 3, '2026-10-05 16:41:11'),
(9, 1, 'superette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'buy', '4x Eau — 12$ (Carte bancaire)', 12, '2026-10-05 16:41:16'),
(10, 1, 'superette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'buy', '1x Eau — 3$ (Espèces)', 3, '2026-10-05 16:41:19'),
(11, 1, 'superette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'delete', 'superette', 0, '2026-10-05 16:41:39'),
(12, 2, 'Armurerie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Armurerie (weapons) — 6 produit(s)', 0, '2026-10-05 16:41:53'),
(13, 2, 'Armurerie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 0 emplacement(s), désactivée', 0, '2026-10-05 16:42:16'),
(14, 2, 'Armurerie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 0 emplacement(s), désactivée', 0, '2026-10-05 16:42:43'),
(15, 2, 'Armurerie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 1 emplacement(s), désactivée', 0, '2026-10-05 16:43:00'),
(16, 2, 'Armurerie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 1 emplacement(s), désactivée', 0, '2026-10-05 16:43:19'),
(17, 2, 'Armurerie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 2 emplacement(s), désactivée', 0, '2026-10-05 16:43:37'),
(18, 2, 'Armurerie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 2 emplacement(s), désactivée', 0, '2026-10-05 16:44:03'),
(19, 2, 'Armurerie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 2 emplacement(s), active', 0, '2026-10-05 16:44:14'),
(20, 2, 'Armurerie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'buy', '1x Batte — 120$ (Espèces)', 120, '2026-10-05 16:45:32'),
(21, 3, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Boutique de vêtements (clothing) — 0 produit(s)', 0, '2026-10-05 16:46:34'),
(22, 3, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '0 produit(s), 1 emplacement(s), désactivée', 0, '2026-10-05 16:46:45'),
(23, 3, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '0 produit(s), 1 emplacement(s), active', 0, '2026-10-05 16:46:48'),
(24, 2, 'Armurerie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 2 emplacement(s), active', 0, '2026-10-05 16:49:05'),
(25, 2, 'Armurerie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 2 emplacement(s), active', 0, '2026-10-05 16:49:35'),
(26, 3, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '0 produit(s), 1 emplacement(s), active', 0, '2026-10-05 16:49:39'),
(27, 3, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '0 produit(s), 1 emplacement(s), active', 0, '2026-10-05 16:55:05'),
(28, 2, 'Armurerie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 1 emplacement(s), active', 0, '2026-10-05 16:55:34'),
(29, 4, 'Bricolage / Outils', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Bricolage / Outils (hardware) — 2 produit(s)', 0, '2026-10-05 16:56:46'),
(30, 4, 'Bricolage / Outils', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 produit(s), 1 emplacement(s), désactivée', 0, '2026-10-05 16:57:12'),
(31, 4, 'Bricolage / Outils', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 produit(s), 1 emplacement(s), active', 0, '2026-10-05 16:57:18'),
(32, 3, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'clothing', 'Tenue — 150$ (Carte bancaire)', 150, '2026-10-05 17:11:26'),
(33, 3, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '0 produit(s), 1 emplacement(s), active', 0, '2026-10-05 17:12:54'),
(34, 3, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'clothing', 'Tenue — 150$ (Carte bancaire)', 150, '2026-10-05 17:31:27'),
(35, 5, 'Coiffeur', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Coiffeur (barber) — 0 produit(s)', 0, '2026-10-05 17:31:44'),
(36, 5, 'Coiffeur', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '0 produit(s), 1 emplacement(s), active', 0, '2026-10-05 17:31:51'),
(37, 5, 'Coiffeur', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'clothing', 'Tenue — 60$ (Carte bancaire)', 60, '2026-10-05 17:32:14'),
(38, 5, 'Coiffeur', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'clothing', 'Tenue — 60$ (Carte bancaire)', 60, '2026-10-05 17:32:24'),
(39, 3, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'clothing', 'Tenue — 150$ (Carte bancaire)', 150, '2026-10-05 17:32:50'),
(40, 3, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'clothing', 'Tenue — 150$ (Carte bancaire)', 150, '2026-10-05 17:33:21'),
(41, 4, 'Bricolage / Outils', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'buy', '1x Crochet — 150$ (Carte bancaire)', 150, '2026-10-05 17:35:26'),
(42, 3, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'clothing', 'Tenue (0 pièce(s)) — 150$ (Carte bancaire)', 150, '2026-10-05 17:38:36'),
(43, 3, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'clothing', 'Tenue (0 pièce(s)) — 150$ (Carte bancaire)', 150, '2026-10-05 17:38:54'),
(44, 3, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'clothing', 'Tenue (0 pièce(s)) — 150$ (Carte bancaire)', 150, '2026-10-05 17:39:16'),
(45, 5, 'Coiffeur', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'delete', 'Coiffeur', 0, '2026-10-05 17:45:45'),
(46, 4, 'Bricolage / Outils', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'delete', 'Bricolage / Outils', 0, '2026-10-05 17:45:47'),
(47, 3, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'delete', 'Boutique de vêtements', 0, '2026-10-05 17:45:49'),
(48, 2, 'Armurerie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'delete', 'Armurerie', 0, '2026-10-05 17:45:51'),
(49, 6, 'Armurerie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Armurerie (weapons) — 6 produit(s)', 0, '2026-10-10 17:04:26'),
(50, 6, 'Armurerie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 0 emplacement(s), désactivée', 0, '2026-10-10 17:04:28'),
(51, 6, 'Armurerie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 0 emplacement(s), désactivée', 0, '2026-10-10 17:04:34'),
(52, 6, 'Armurerie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 1 emplacement(s), désactivée', 0, '2026-10-10 17:04:43'),
(53, 6, 'Armurerie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 1 emplacement(s), désactivée', 0, '2026-10-10 17:04:57'),
(54, 6, 'Armurerie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 1 emplacement(s), désactivée', 0, '2026-10-10 17:05:07'),
(55, 6, 'Armurerie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 1 emplacement(s), désactivée', 0, '2026-10-10 17:05:11'),
(56, 6, 'Armurerie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 1 emplacement(s), active', 0, '2026-10-10 17:05:25'),
(57, 6, 'Armurerie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 1 emplacement(s), active', 0, '2026-10-10 17:05:56'),
(58, 6, 'Armurerie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 1 emplacement(s), active', 0, '2026-10-10 17:06:25'),
(59, 6, 'Armurerie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 1 emplacement(s), active', 0, '2026-10-10 17:06:33'),
(60, 6, 'Armurerie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 1 emplacement(s), active', 0, '2026-10-10 17:06:48'),
(61, 6, 'Armurerie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 1 emplacement(s), active', 0, '2026-10-10 17:07:19'),
(62, 6, 'Armurerie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'buy', '1x Pistolet — 2500$ (Carte bancaire)', 2500, '2026-10-10 17:07:31'),
(63, 7, 'Supérette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Supérette (general) — 6 produit(s)', 0, '2026-10-10 17:09:42'),
(64, 7, 'Supérette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 0 emplacement(s), désactivée', 0, '2026-10-10 17:09:42'),
(65, 7, 'Supérette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 0 emplacement(s), désactivée', 0, '2026-10-10 17:09:49'),
(66, 7, 'Supérette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 1 emplacement(s), désactivée', 0, '2026-10-10 17:09:55'),
(67, 7, 'Supérette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 1 emplacement(s), désactivée', 0, '2026-10-10 17:10:09'),
(68, 7, 'Supérette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 1 emplacement(s), active', 0, '2026-10-10 17:10:13'),
(69, 7, 'Supérette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'buy', '1x Téléphone — 450$ (Carte bancaire)', 450, '2026-10-10 17:10:23'),
(70, 7, 'Supérette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 1 emplacement(s), active', 0, '2026-10-10 17:10:32'),
(71, 7, 'Supérette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 1 emplacement(s), active', 0, '2026-10-10 17:10:35'),
(72, 7, 'Supérette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 1 emplacement(s), active', 0, '2026-10-10 17:11:10'),
(73, 7, 'Supérette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'delete', 'Supérette', 0, '2026-10-10 17:15:17'),
(74, 8, 'Supérette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Supérette (general) — 6 produit(s)', 0, '2026-10-10 17:16:01'),
(75, 8, 'Supérette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 0 emplacement(s), désactivée', 0, '2026-10-10 17:16:02'),
(76, 8, 'Supérette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 0 emplacement(s), active', 0, '2026-10-10 17:16:05'),
(77, 8, 'Supérette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 1 emplacement(s), active', 0, '2026-10-10 17:16:11'),
(78, 8, 'Supérette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 1 emplacement(s), active', 0, '2026-10-10 17:16:28'),
(79, 8, 'Supérette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'buy', '1x Pain, 1x Burger, 1x Eau — 20$ (Carte bancaire)', 20, '2026-10-10 17:16:40'),
(80, 8, 'Supérette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 1 emplacement(s), active', 0, '2026-10-10 17:16:52'),
(81, 8, 'Supérette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'delete', 'Supérette', 0, '2026-10-10 17:20:11'),
(82, 9, 'Supérette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Supérette (general) — 6 produit(s)', 0, '2026-10-10 17:20:45'),
(83, 9, 'Supérette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 1 emplacement(s), désactivée', 0, '2026-10-10 17:20:51'),
(84, 9, 'Supérette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 1 emplacement(s), active', 0, '2026-10-10 17:20:56'),
(85, 9, 'Supérette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 1 emplacement(s), active', 0, '2026-10-10 17:21:12'),
(86, 9, 'Supérette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'buy', '1x Pain, 1x Eau — 8$ (Carte bancaire)', 8, '2026-10-10 17:21:22'),
(87, 9, 'Supérette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'buy', '1x Pain, 1x Eau — 8$ (Carte bancaire)', 8, '2026-10-10 17:21:26'),
(88, 9, 'Supérette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 1 emplacement(s), active', 0, '2026-10-10 17:21:38'),
(89, 9, 'Supérette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 produit(s), 1 emplacement(s), active', 0, '2026-10-10 17:21:41'),
(90, 10, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Boutique de vêtements (clothing) — 0 produit(s)', 0, '2026-10-10 21:39:56'),
(91, 10, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '0 produit(s), 0 emplacement(s), désactivée', 0, '2026-10-10 21:39:57'),
(92, 10, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '0 produit(s), 1 emplacement(s), désactivée', 0, '2026-10-10 21:40:02'),
(93, 10, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '0 produit(s), 1 emplacement(s), active', 0, '2026-10-10 21:40:06'),
(94, 10, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '0 produit(s), 1 emplacement(s), active', 0, '2026-10-10 21:44:47'),
(95, 10, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '0 produit(s), 1 emplacement(s), active', 0, '2026-10-10 21:45:05'),
(96, 10, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '0 produit(s), 1 emplacement(s), active', 0, '2026-10-10 21:45:27'),
(97, 10, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '0 produit(s), 1 emplacement(s), active', 0, '2026-10-10 21:45:41'),
(98, 10, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '0 produit(s), 1 emplacement(s), active', 0, '2026-10-10 21:45:57'),
(99, 11, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Boutique de vêtements (clothing) — 0 produit(s)', 0, '2026-10-10 21:47:55'),
(100, 11, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '0 produit(s), 1 emplacement(s), désactivée', 0, '2026-10-10 21:48:14'),
(101, 11, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '0 produit(s), 1 emplacement(s), active', 0, '2026-10-10 21:48:16'),
(102, 11, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '0 produit(s), 1 emplacement(s), active', 0, '2026-10-10 21:48:20'),
(103, 11, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '0 produit(s), 1 emplacement(s), active', 0, '2026-10-10 21:48:48'),
(104, 11, 'Boutique de vêtements centre ville', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '0 produit(s), 1 emplacement(s), active', 0, '2026-10-10 21:49:24'),
(105, 11, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '0 produit(s), 1 emplacement(s), active', 0, '2026-10-10 21:54:20'),
(106, 11, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '0 produit(s), 1 emplacement(s), active', 0, '2026-10-10 21:54:40'),
(107, 10, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '0 produit(s), 1 emplacement(s), active', 0, '2026-10-10 21:54:43'),
(108, 10, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '0 produit(s), 1 emplacement(s), active', 0, '2026-10-10 21:56:20'),
(109, 11, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'clothing', 'Tenue (0 pièce(s)) — 150$ (Carte bancaire)', 150, '2026-10-10 21:58:02'),
(110, 11, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '0 produit(s), 1 emplacement(s), active', 0, '2026-10-11 10:14:56'),
(111, 12, 'Supérette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Supérette (general) — 6 produit(s)', 0, '2026-10-11 14:52:49'),
(112, 12, 'Supérette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'delete', 'Supérette', 0, '2026-10-11 14:52:56'),
(113, 13, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Boutique de vêtements (clothing) — 0 produit(s)', 0, '2026-10-11 14:53:00'),
(114, 13, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '0 produit(s), 0 emplacement(s), désactivée', 0, '2026-10-11 14:53:23'),
(115, 13, 'Bijouterie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '0 produit(s), 0 emplacement(s), active', 0, '2026-10-11 14:53:32'),
(116, 13, 'Bijouterie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '0 produit(s), 1 emplacement(s), active', 0, '2026-10-11 14:53:36'),
(117, 13, 'Bijouterie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '0 produit(s), 1 emplacement(s), active', 0, '2026-10-11 14:54:05'),
(118, 13, 'Bijouterie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '0 produit(s), 1 emplacement(s), active', 0, '2026-10-11 14:54:35'),
(119, 13, 'Bijouterie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'clothing', 'Tenue (0 pièce(s)) — 150$ (Carte bancaire)', 150, '2026-10-11 14:54:58'),
(120, 13, 'Bijouterie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'clothing', 'Tenue (0 pièce(s)) — 150$ (Espèces)', 150, '2026-10-11 14:56:16'),
(121, 13, 'Bijouterie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '0 produit(s), 1 emplacement(s), active', 0, '2026-10-11 14:57:13'),
(122, 13, 'Bijouterie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '0 produit(s), 1 emplacement(s), active', 0, '2026-10-11 14:57:15'),
(123, 13, 'Bijouterie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '0 produit(s), 1 emplacement(s), active', 0, '2026-10-11 14:58:00'),
(124, 13, 'Bijouterie', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '0 produit(s), 1 emplacement(s), active', 0, '2026-10-11 14:58:33'),
(125, 11, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'clothing', 'Tenue (0 pièce(s)) — 150$ (Carte bancaire)', 150, '2026-10-11 19:25:32'),
(126, 11, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'clothing', 'Tenue (item) — 150$ (Carte bancaire)', 150, '2026-10-11 19:36:58'),
(127, 11, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'clothing', 'Tenue (item) — 150$ (Carte bancaire)', 150, '2026-10-11 19:38:05'),
(128, 11, 'Boutique de vêtements', 'license:17015558e9d71c65e5de4c4c417d582ba4f005f1', 'MOUNIR PABLO', 'clothing', 'Tenue (item) — 150$ (Carte bancaire)', 150, '2026-10-12 13:17:58'),
(129, 11, 'Boutique de vêtements', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'clothing', 'Tenue (item) — 150$ (Carte bancaire)', 150, '2026-10-13 13:10:33'),
(130, 9, 'Supérette', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'buy', '4x Eau — 12$ (Carte bancaire)', 12, '2026-10-13 18:29:36');

-- --------------------------------------------------------

--
-- Table structure for table `shopbuilder_settings`
--

CREATE TABLE `shopbuilder_settings` (
  `k` varchar(50) NOT NULL,
  `v` longtext DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `shopbuilder_settings`
--

INSERT INTO `shopbuilder_settings` (`k`, `v`) VALUES
('accent', '[123,44,160]');

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `shopbuilder_shops`
--

INSERT INTO `shopbuilder_shops` (`id`, `name`, `label`, `type`, `enabled`, `settings`, `items`, `locations`, `stats`, `created_by`, `created_at`, `updated_at`) VALUES
(6, 'armurerie', 'Armurerie', 'weapons', 1, '{\"access\":{\"jobs\":[],\"license\":\"\"},\"payments\":{\"cash\":true,\"black_money\":false,\"bank\":true},\"ped\":{\"model\":\"s_m_y_ammucity_01\",\"enabled\":true,\"scenario\":\"WORLD_HUMAN_STAND_IMPATIENT\"},\"categories\":[\"Armes de poing\",\"Armes blanches\",\"Munitions\",\"Accessoires\"],\"marker\":{\"enabled\":true,\"type\":25},\"blip\":{\"shortRange\":true,\"enabled\":true,\"label\":\"\",\"scale\":0.49999999999995,\"sprite\":110,\"color\":1},\"society\":\"\",\"restock\":{\"last\":1791651866,\"minutes\":0,\"amount\":0},\"discount\":0,\"mode\":\"items\",\"hours\":{\"to\":22,\"enabled\":false,\"from\":8},\"color\":[168,85,247],\"note\":\"\",\"clothing\":{\"parts\":[],\"price\":100},\"jobDiscounts\":[]}', '[{\"promo\":0,\"max_stock\":0,\"label\":\"Pistolet\",\"jobs\":[],\"enabled\":true,\"name\":\"WEAPON_PISTOL\",\"ammo\":0,\"price\":2500,\"max\":100,\"license\":\"weapon\",\"stock\":-1,\"category\":\"Armes de poing\"},{\"promo\":0,\"max_stock\":0,\"label\":\"Pistolet de combat\",\"jobs\":[],\"enabled\":true,\"name\":\"WEAPON_COMBATPISTOL\",\"ammo\":0,\"price\":3200,\"max\":100,\"license\":\"weapon\",\"stock\":-1,\"category\":\"Armes de poing\"},{\"promo\":0,\"max_stock\":0,\"label\":\"Couteau\",\"jobs\":[],\"enabled\":true,\"name\":\"WEAPON_KNIFE\",\"ammo\":0,\"price\":150,\"max\":100,\"license\":\"\",\"stock\":-1,\"category\":\"Armes blanches\"},{\"promo\":0,\"max_stock\":0,\"label\":\"Batte\",\"jobs\":[],\"enabled\":true,\"name\":\"WEAPON_BAT\",\"ammo\":0,\"price\":120,\"max\":100,\"license\":\"\",\"stock\":-1,\"category\":\"Armes blanches\"},{\"promo\":0,\"max_stock\":0,\"label\":\"Lampe torche\",\"jobs\":[],\"enabled\":true,\"name\":\"WEAPON_FLASHLIGHT\",\"ammo\":0,\"price\":60,\"max\":100,\"license\":\"\",\"stock\":-1,\"category\":\"Accessoires\"},{\"promo\":0,\"max_stock\":0,\"label\":\"Munitions 9mm\",\"jobs\":[],\"enabled\":true,\"name\":\"ammo-9\",\"ammo\":0,\"price\":2,\"max\":100,\"license\":\"weapon\",\"stock\":-1,\"category\":\"Munitions\"}]', '[{\"ped\":{\"x\":22.97,\"y\":-1105.39,\"z\":29.8,\"h\":160.35},\"coords\":{\"x\":21.75,\"y\":-1107.29,\"z\":29.8,\"h\":335.68},\"label\":\"\"}]', '{\"items\":{\"WEAPON_PISTOL\":{\"r\":2500,\"q\":1}},\"revenue\":2500,\"sales\":1}', 'Pickax', '2026-10-10 17:04:26', '2026-10-10 17:07:41'),
(9, 'superette', 'Supérette', 'general', 1, '{\"access\":{\"jobs\":[],\"license\":\"\"},\"payments\":{\"cash\":true,\"black_money\":false,\"bank\":true},\"ped\":{\"model\":\"mp_m_shopkeep_01\",\"enabled\":true,\"scenario\":\"WORLD_HUMAN_STAND_IMPATIENT\"},\"categories\":[\"Nourriture\",\"Boissons\",\"Divers\"],\"marker\":{\"enabled\":true,\"type\":25},\"blip\":{\"shortRange\":true,\"enabled\":true,\"label\":\"\",\"scale\":0.49999999999995,\"sprite\":52,\"color\":2},\"society\":\"\",\"restock\":{\"last\":1791652845,\"minutes\":0,\"amount\":0},\"discount\":0,\"mode\":\"items\",\"hours\":{\"to\":22,\"enabled\":false,\"from\":8},\"color\":[34,197,94],\"note\":\"\",\"clothing\":{\"parts\":[],\"price\":100},\"jobDiscounts\":[]}', '[{\"max_stock\":0,\"jobs\":[],\"label\":\"Pain\",\"price\":5,\"license\":\"\",\"promo\":0,\"stock\":-1,\"category\":\"Nourriture\",\"max\":100,\"name\":\"bread\",\"ammo\":0,\"enabled\":true},{\"max_stock\":0,\"jobs\":[],\"label\":\"Burger\",\"price\":12,\"license\":\"\",\"promo\":0,\"stock\":-1,\"category\":\"Nourriture\",\"max\":100,\"name\":\"burger\",\"ammo\":0,\"enabled\":true},{\"max_stock\":0,\"jobs\":[],\"label\":\"Eau\",\"price\":3,\"license\":\"\",\"promo\":0,\"stock\":-1,\"category\":\"Boissons\",\"max\":100,\"name\":\"water\",\"ammo\":0,\"enabled\":true},{\"max_stock\":0,\"jobs\":[],\"label\":\"Cola\",\"price\":4,\"license\":\"\",\"promo\":0,\"stock\":-1,\"category\":\"Boissons\",\"max\":100,\"name\":\"cola\",\"ammo\":0,\"enabled\":true},{\"max_stock\":0,\"jobs\":[],\"label\":\"Téléphone\",\"price\":450,\"license\":\"\",\"promo\":0,\"stock\":-1,\"category\":\"Divers\",\"max\":100,\"name\":\"phone\",\"ammo\":0,\"enabled\":true},{\"max_stock\":0,\"jobs\":[],\"label\":\"Radio\",\"price\":250,\"license\":\"\",\"promo\":0,\"stock\":-1,\"category\":\"Divers\",\"max\":100,\"name\":\"radio\",\"ammo\":0,\"enabled\":true}]', '[{\"ped\":{\"x\":24.43,\"y\":-1347.38,\"z\":29.5,\"h\":264.4},\"coords\":{\"x\":26.06,\"y\":-1347.33,\"z\":29.5,\"h\":95.23},\"label\":\"\"}]', '{\"items\":{\"bread\":{\"r\":10,\"q\":2},\"water\":{\"r\":18,\"q\":6}},\"sales\":3,\"revenue\":28}', 'Pickax', '2026-10-10 17:20:45', '2026-10-13 18:30:02'),
(10, 'boutique_de_vetements', 'Boutique de vêtements', 'clothing', 1, '{\"color\":[236,72,153],\"access\":{\"license\":\"\",\"jobs\":[]},\"society\":\"\",\"jobDiscounts\":[],\"mode\":\"clothing\",\"tag\":\"Centre ville\",\"clothing\":{\"price\":150,\"parts\":[\"top\",\"pants\",\"shoes\",\"hat\",\"glasses\",\"mask\",\"chain\",\"ears\",\"watches\",\"bracelets\",\"bags\"]},\"ped\":{\"model\":\"s_f_y_shop_mid\",\"scenario\":\"WORLD_HUMAN_STAND_IMPATIENT\",\"enabled\":true},\"marker\":{\"enabled\":true,\"type\":25},\"note\":\"\",\"categories\":[],\"hours\":{\"to\":22,\"enabled\":false,\"from\":8},\"restock\":{\"minutes\":0,\"last\":1791668396,\"amount\":0},\"payments\":{\"cash\":true,\"bank\":true,\"black_money\":false},\"discount\":0,\"memo\":\"pres de la superette centre ville\",\"blip\":{\"color\":47,\"shortRange\":true,\"enabled\":true,\"scale\":0.49999999999995,\"sprite\":73,\"label\":\"\"}}', '[]', '[{\"coords\":{\"h\":94.42,\"x\":71.48,\"y\":-1399.14,\"z\":29.38},\"label\":\"\",\"tag\":\"\",\"ped\":{\"h\":313.34,\"x\":69.87,\"y\":-1400.36,\"z\":29.38}}]', '[]', 'Pickax', '2026-10-10 21:39:56', '2026-10-10 21:56:20'),
(11, 'boutique_de_vetements_2', 'Boutique de vêtements', 'clothing', 1, '{\"restock\":{\"minutes\":0,\"last\":1791668875,\"amount\":0},\"ped\":{\"model\":\"s_f_y_shop_mid\",\"scenario\":\"WORLD_HUMAN_STAND_IMPATIENT\",\"enabled\":true},\"note\":\"\",\"access\":{\"jobs\":[],\"license\":\"\"},\"clothing\":{\"parts\":[\"top\",\"pants\",\"shoes\",\"hat\",\"glasses\",\"mask\",\"chain\",\"ears\",\"watches\",\"bracelets\",\"bags\"],\"price\":150},\"jobDiscounts\":[],\"society\":\"\",\"memo\":\"pres du commisariat\",\"color\":[99,102,241],\"categories\":[],\"discount\":0,\"marker\":{\"type\":25,\"enabled\":true},\"mode\":\"clothing\",\"hours\":{\"to\":22,\"from\":8,\"enabled\":false},\"payments\":{\"cash\":true,\"bank\":true,\"black_money\":false},\"tag\":\"Centre ville\",\"blip\":{\"label\":\"\",\"enabled\":true,\"shortRange\":true,\"color\":47,\"scale\":0.49999999999995,\"sprite\":73}}', '[]', '[{\"ped\":{\"h\":141.65,\"z\":29.5,\"y\":-798.77,\"x\":431.13},\"coords\":{\"h\":278.71,\"z\":29.49,\"y\":-799.95,\"x\":429.53},\"label\":\"\",\"tag\":\"\"}]', '{\"items\":{\"clothing\":{\"r\":900,\"q\":6}},\"sales\":6,\"revenue\":900}', 'Pickax', '2026-10-10 21:47:55', '2026-10-13 13:10:44'),
(13, 'boutique_de_vetements_3', 'Bijouterie', 'clothing', 1, '{\"jobDiscounts\":[],\"memo\":\"\",\"hours\":{\"enabled\":false,\"from\":8,\"to\":22},\"note\":\"\",\"blip\":{\"enabled\":true,\"scale\":0.49999999999995,\"color\":50,\"label\":\"\",\"shortRange\":true,\"sprite\":439},\"categories\":[],\"color\":[86,29,93],\"clothing\":{\"parts\":[\"chain\",\"bracelets\",\"watches\",\"glasses\",\"ears\"],\"price\":150},\"access\":{\"license\":\"\",\"jobs\":[]},\"ped\":{\"enabled\":true,\"model\":\"s_f_y_shop_mid\",\"scenario\":\"WORLD_HUMAN_STAND_IMPATIENT\"},\"marker\":{\"enabled\":true,\"type\":25},\"tag\":\"\",\"society\":\"\",\"mode\":\"clothing\",\"payments\":{\"bank\":true,\"cash\":true,\"black_money\":false},\"restock\":{\"minutes\":0,\"amount\":0,\"last\":1791730380},\"discount\":0}', '[]', '[{\"coords\":{\"x\":-626.26,\"y\":-235.16,\"z\":38.06,\"h\":132.14},\"label\":\"\",\"ped\":{\"x\":-623.27,\"y\":-236.99,\"z\":38.06,\"h\":34.24},\"tag\":\"\"}]', '{\"sales\":2,\"revenue\":300,\"items\":{\"clothing\":{\"r\":300,\"q\":2}}}', 'Pickax', '2026-10-11 14:53:00', '2026-10-11 14:58:00');

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
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `societymoney`
--

CREATE TABLE `societymoney` (
  `name` varchar(50) NOT NULL,
  `money` int(11) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`identifier`, `accounts`, `group`, `inventory`, `job`, `job2`, `job_grade`, `job2_grade`, `loadout`, `metadata`, `position`, `firstname`, `lastname`, `dateofbirth`, `sex`, `height`, `skin`, `status`, `is_dead`, `last_property`, `created_at`, `last_seen`, `points`, `boutique_id`, `vip`, `isDead`, `caractere`, `health`, `playtime`, `nationality`) VALUES
('license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', '{\"bank\":25000,\"black_money\":0,\"money\":25000}', 'admin', '[{\"name\":\"water\",\"slot\":1,\"count\":5},{\"name\":\"bread\",\"slot\":2,\"count\":5},{\"name\":\"money\",\"slot\":3,\"count\":25000},{\"name\":\"clothes_vest\",\"slot\":60,\"count\":1,\"metadata\":{\"bproof_1\":0,\"bproof_2\":0}},{\"name\":\"clothes_bag\",\"slot\":61,\"count\":1,\"metadata\":{\"bags_1\":0,\"bags_2\":0}},{\"name\":\"clothes_chain\",\"slot\":63,\"count\":1,\"metadata\":{\"chain_1\":0,\"chain_2\":0}},{\"name\":\"clothes_tshirt\",\"slot\":53,\"count\":1,\"metadata\":{\"tshirt_1\":0,\"tshirt_2\":0}},{\"name\":\"clothes_torso\",\"slot\":54,\"count\":1,\"metadata\":{\"torso_1\":0,\"torso_2\":0}},{\"name\":\"clothes_arms\",\"slot\":55,\"count\":1,\"metadata\":{\"arms_2\":0,\"arms\":0}},{\"name\":\"clothes_pants\",\"slot\":56,\"count\":1,\"metadata\":{\"pants_2\":0,\"pants_1\":0}},{\"name\":\"clothes_shoes\",\"slot\":57,\"count\":1,\"metadata\":{\"shoes_1\":0,\"shoes_2\":0}},{\"name\":\"clothes_mask\",\"slot\":58,\"count\":1,\"metadata\":{\"mask_2\":0,\"mask_1\":0}},{\"name\":\"clothes_glasses\",\"slot\":59,\"count\":1,\"metadata\":{\"glasses_1\":0,\"glasses_2\":0}}]', 'unemployed', 'unemployed2', 0, 0, '[]', '[]', '{\"y\":-127.9120864868164,\"z\":19.945068359375,\"x\":-793.7274780273438}', 'Maly', 'Pablo', '30/07/2000', 'm', 185, '{\"decals_2\":0,\"bodyb_2\":0,\"hair_1\":3,\"bags_1\":0,\"chest_3\":0,\"makeup_1\":0,\"arms_2\":0,\"chain_1\":0,\"bracelets_1\":-1,\"eyebrows_2\":0,\"age_2\":0,\"hair_color_1\":0,\"makeup_3\":0,\"beard_2\":0,\"blemishes_1\":0,\"lipstick_1\":0,\"watches_2\":0,\"moles_2\":0,\"mask_1\":0,\"ears_1\":-1,\"bproof_1\":0,\"makeup_2\":0,\"pants_1\":0,\"chest_1\":0,\"bproof_2\":0,\"torso_1\":0,\"mask_2\":0,\"sun_1\":0,\"age_1\":0,\"arms\":0,\"skin\":0,\"ears_2\":0,\"decals_1\":0,\"eyebrows_4\":0,\"beard_4\":0,\"complexion_1\":0,\"blemishes_2\":0,\"blush_3\":0,\"beard_3\":0,\"glasses_2\":0,\"bodyb_1\":0,\"eyebrows_3\":0,\"helmet_1\":-1,\"complexion_2\":0,\"bags_2\":0,\"blush_2\":0,\"sun_2\":0,\"shoes_2\":0,\"face\":0,\"eyebrows_1\":0,\"moles_1\":0,\"tshirt_1\":0,\"helmet_2\":-1,\"glasses_1\":0,\"hair_2\":0,\"eye_color\":0,\"pants_2\":0,\"blush_1\":0,\"beard_1\":0,\"shoes_1\":0,\"chain_2\":0,\"tshirt_2\":0,\"hair_color_2\":0,\"chest_2\":0,\"lipstick_3\":0,\"watches_1\":-1,\"sex\":0,\"torso_2\":0,\"lipstick_4\":0,\"makeup_4\":0,\"lipstick_2\":0,\"bracelets_2\":0}', '[{\"val\":989100,\"name\":\"hunger\",\"percent\":98.91},{\"val\":986920,\"name\":\"thirst\",\"percent\":98.69200000000001},{\"val\":0,\"name\":\"drunk\",\"percent\":0.0},{\"val\":989100,\"name\":\"hunger\",\"percent\":98.91},{\"val\":986920,\"name\":\"thirst\",\"percent\":98.69200000000001},{\"val\":0,\"name\":\"drunk\",\"percent\":0.0}]', 0, NULL, '2026-10-13 21:27:09', '2026-10-13 21:29:02', 0, 37, 0, 0, NULL, 200, 0, 'Française'),
('license:17015558e9d71c65e5de4c4c417d582ba4f005f1', '{\"money\":24000,\"black_money\":200,\"bank\":42450}', '_dev', '[{\"metadata\":{\"bproof_2\":0,\"bproof_1\":0},\"name\":\"clothes_vest\",\"slot\":60,\"count\":1},{\"metadata\":{\"bags_2\":0,\"bags_1\":81},\"name\":\"clothes_bag\",\"slot\":61,\"count\":1},{\"metadata\":{\"skin\":{\"chain_2\":0,\"mask_2\":0,\"bracelets_1\":-1,\"mask_1\":0,\"torso_1\":9,\"shoes_2\":3,\"bracelets_2\":0,\"shoes_1\":0,\"tshirt_2\":0,\"watches_2\":0,\"bproof_2\":0,\"ears_1\":-1,\"bags_2\":0,\"chain_1\":0,\"arms\":185,\"watches_1\":-1,\"tshirt_1\":0,\"helmet_1\":-1,\"bags_1\":81,\"torso_2\":1,\"pants_2\":3,\"ears_2\":0,\"pants_1\":113,\"glasses_2\":0,\"arms_2\":0,\"bproof_1\":0,\"helmet_2\":-1,\"glasses_1\":0},\"sex\":\"male\",\"label\":\"Tenue — Boutique de vêtements\",\"description\":\"Tenue complete (28 reglages). Glisse-la sur la case Tenue de ton inventaire pour la porter.\"},\"name\":\"clothes_outfit\",\"slot\":2,\"count\":1},{\"metadata\":{\"chain_2\":0,\"chain_1\":0},\"name\":\"clothes_chain\",\"slot\":63,\"count\":1},{\"name\":\"black_money\",\"slot\":5,\"count\":200},{\"metadata\":{\"tshirt_1\":15,\"tshirt_2\":3},\"name\":\"clothes_tshirt\",\"slot\":53,\"count\":1},{\"metadata\":{\"torso_1\":178,\"torso_2\":3},\"name\":\"clothes_torso\",\"slot\":54,\"count\":1},{\"metadata\":{\"arms\":31,\"arms_2\":0},\"name\":\"clothes_arms\",\"slot\":55,\"count\":1},{\"metadata\":{\"pants_1\":77,\"pants_2\":3},\"name\":\"clothes_pants\",\"slot\":56,\"count\":1},{\"metadata\":{\"shoes_1\":55,\"shoes_2\":3},\"name\":\"clothes_shoes\",\"slot\":57,\"count\":1},{\"metadata\":{\"mask_2\":0,\"mask_1\":0},\"name\":\"clothes_mask\",\"slot\":58,\"count\":1},{\"metadata\":{\"glasses_2\":0,\"glasses_1\":0},\"name\":\"clothes_glasses\",\"slot\":59,\"count\":1},{\"name\":\"money\",\"slot\":3,\"count\":24000}]', 'unemployed', 'unemployed2', 0, 0, '[]', '[]', '{\"x\":42.06593322753906,\"z\":30.10546875,\"y\":-865.1340942382813}', 'MOUNIR', 'PABLO', '04/10/2000', 'm', 185, '{\"eyebrows_2\":0,\"helmet_1\":-1,\"makeup_1\":0,\"blush_1\":0,\"makeup_2\":0,\"bproof_2\":0,\"beard_1\":0,\"ears_2\":0,\"pants_2\":3,\"hair_2\":0,\"bracelets_2\":0,\"moles_1\":0,\"hair_1\":0,\"decals_1\":0,\"age_1\":0,\"eyebrows_1\":0,\"watches_1\":-1,\"face\":0,\"hair_color_2\":0,\"tshirt_2\":3,\"glasses_1\":0,\"helmet_2\":-1,\"eye_color\":0,\"shoes_2\":3,\"blush_3\":0,\"ears_1\":-1,\"eyebrows_3\":0,\"mask_2\":0,\"bracelets_1\":-1,\"beard_3\":0,\"mask_1\":0,\"eyebrows_4\":0,\"bodyb_1\":0,\"shoes_1\":55,\"blush_2\":0,\"watches_2\":0,\"sun_2\":0,\"bodyb_2\":0,\"chain_2\":0,\"bags_1\":81,\"glasses_2\":0,\"arms\":31,\"bproof_1\":0,\"torso_2\":3,\"tshirt_1\":15,\"makeup_3\":0,\"age_2\":0,\"moles_2\":0,\"chest_2\":0,\"chest_1\":0,\"chest_3\":0,\"torso_1\":178,\"makeup_4\":0,\"sun_1\":0,\"blemishes_2\":0,\"blemishes_1\":0,\"beard_2\":0,\"decals_2\":0,\"complexion_2\":0,\"complexion_1\":0,\"skin\":0,\"lipstick_1\":0,\"beard_4\":0,\"lipstick_2\":0,\"lipstick_3\":0,\"pants_1\":77,\"bags_2\":0,\"sex\":0,\"chain_1\":0,\"lipstick_4\":0,\"arms_2\":0,\"hair_color_1\":0}', '[{\"val\":994200,\"percent\":99.42,\"name\":\"hunger\"},{\"val\":993040,\"percent\":99.304,\"name\":\"thirst\"},{\"val\":0,\"percent\":0.0,\"name\":\"drunk\"},{\"val\":994200,\"percent\":99.42,\"name\":\"hunger\"},{\"val\":993040,\"percent\":99.304,\"name\":\"thirst\"},{\"val\":0,\"percent\":0.0,\"name\":\"drunk\"}]', 0, NULL, '2026-09-26 17:14:33', '2026-10-12 13:21:35', 0, 17, 0, 0, NULL, 200, 2880, NULL),
('license:1900e3062a0de4aadb8a6c959470425894c992fa', '{\"money\":25000,\"black_money\":0,\"bank\":25000}', 'user', '[{\"name\":\"water\",\"count\":5,\"slot\":1},{\"name\":\"bread\",\"count\":5,\"slot\":2},{\"name\":\"money\",\"count\":25000,\"slot\":3}]', 'unemployed', 'unemployed2', 0, 0, '[]', '[]', '{\"x\":-819.2307739257813,\"y\":-134.86154174804688,\"z\":19.945068359375}', 'Pierre', 'Dedisse', '12/04/1995', 'm', 200, NULL, '[{\"name\":\"hunger\",\"percent\":93.83,\"val\":938300},{\"name\":\"thirst\",\"percent\":92.596,\"val\":925960},{\"name\":\"drunk\",\"percent\":0.0,\"val\":0},{\"name\":\"hunger\",\"percent\":93.83,\"val\":938300},{\"name\":\"thirst\",\"percent\":92.596,\"val\":925960},{\"name\":\"drunk\",\"percent\":0.0,\"val\":0}]', 0, NULL, '2026-09-27 15:18:10', '2026-09-27 17:04:00', 0, 18, 0, 0, NULL, 200, 0, NULL),
('license:1d522f6effdc6a92e62688a34602bd08135739ce', '{\"black_money\":1112423510,\"money\":2233233,\"bank\":4556601089}', '_dev', '[{\"slot\":1,\"count\":2233233,\"name\":\"money\"},{\"slot\":2,\"count\":1112423510,\"name\":\"black_money\"},{\"slot\":3,\"count\":1,\"metadata\":{\"serial\":\"588874BVM800054\",\"durability\":100,\"components\":[],\"registered\":\"Pablo Rodriguez\",\"ammo\":200},\"name\":\"WEAPON_KNIFE\"},{\"slot\":4,\"count\":1,\"metadata\":{\"serial\":\"557369XYN282721\",\"durability\":100,\"components\":[],\"registered\":\"Pablo Rodriguez\",\"ammo\":0},\"name\":\"WEAPON_NAVYREVOLVER\"},{\"slot\":5,\"count\":1,\"metadata\":{\"serial\":\"294622TYZ822858\",\"durability\":100,\"components\":[],\"registered\":\"Pablo Rodriguez\",\"ammo\":0},\"name\":\"WEAPON_SNIPERRIFLE\"},{\"slot\":60,\"count\":1,\"metadata\":{\"bproof_1\":0,\"bproof_2\":0},\"name\":\"clothes_vest\"},{\"slot\":61,\"count\":1,\"metadata\":{\"bags_1\":81,\"bags_2\":0},\"name\":\"clothes_bag\"},{\"slot\":63,\"count\":1,\"metadata\":{\"chain_2\":0,\"chain_1\":0},\"name\":\"clothes_chain\"},{\"slot\":53,\"count\":1,\"metadata\":{\"tshirt_2\":0,\"tshirt_1\":0},\"name\":\"clothes_tshirt\"},{\"slot\":9,\"count\":1,\"metadata\":{\"serial\":\"574269PWM319659\",\"durability\":100,\"components\":[],\"registered\":\"Pablo Rodriguez\",\"ammo\":200},\"name\":\"WEAPON_PISTOL\"},{\"slot\":55,\"count\":1,\"metadata\":{\"arms\":0,\"arms_2\":0},\"name\":\"clothes_arms\"},{\"slot\":56,\"count\":1,\"metadata\":{\"pants_1\":0,\"pants_2\":0},\"name\":\"clothes_pants\"},{\"slot\":57,\"count\":1,\"metadata\":{\"shoes_1\":0,\"shoes_2\":0},\"name\":\"clothes_shoes\"},{\"slot\":58,\"count\":1,\"metadata\":{\"mask_2\":0,\"mask_1\":0},\"name\":\"clothes_mask\"},{\"slot\":59,\"count\":1,\"metadata\":{\"glasses_2\":0,\"glasses_1\":0},\"name\":\"clothes_glasses\"},{\"slot\":54,\"count\":1,\"metadata\":{\"torso_1\":0,\"torso_2\":0},\"name\":\"clothes_torso\"}]', 'unemployed', 'unemployed2', 0, 0, '[]', '[]', '{\"z\":33.997802734375,\"x\":-120.47472381591797,\"y\":-1524.4747314453126}', 'Pablo', 'Rodriguez', '30/07/1996', 'm', 200, '{\"arms_2\":0,\"eye_color\":0,\"sex\":0,\"chain_2\":0,\"age_1\":0,\"arms\":0,\"blemishes_1\":0,\"pants_2\":0,\"decals_2\":0,\"sun_2\":0,\"lipstick_1\":0,\"makeup_4\":0,\"moles_1\":0,\"ears_1\":-1,\"skin\":0,\"beard_1\":0,\"makeup_2\":0,\"face\":0,\"ears_2\":0,\"decals_1\":0,\"bproof_1\":0,\"beard_3\":0,\"hair_2\":0,\"blush_1\":0,\"bproof_2\":0,\"helmet_1\":-1,\"lipstick_4\":0,\"mask_1\":0,\"tshirt_1\":0,\"beard_4\":0,\"age_2\":0,\"chest_2\":0,\"helmet_2\":-1,\"bodyb_2\":0,\"makeup_1\":0,\"blush_3\":0,\"beard_2\":0,\"glasses_1\":0,\"bags_2\":0,\"chain_1\":0,\"moles_2\":0,\"complexion_1\":0,\"torso_2\":0,\"bracelets_2\":0,\"blush_2\":0,\"lipstick_3\":0,\"shoes_1\":0,\"bags_1\":81,\"pants_1\":0,\"hair_1\":0,\"complexion_2\":0,\"hair_color_2\":0,\"eyebrows_4\":0,\"eyebrows_2\":0,\"chest_1\":0,\"eyebrows_3\":0,\"tshirt_2\":0,\"chest_3\":0,\"watches_2\":0,\"bodyb_1\":0,\"shoes_2\":0,\"mask_2\":0,\"makeup_3\":0,\"glasses_2\":0,\"sun_1\":0,\"hair_color_1\":0,\"lipstick_2\":0,\"bracelets_1\":-1,\"eyebrows_1\":0,\"watches_1\":-1,\"torso_1\":0,\"blemishes_2\":0}', '[{\"percent\":96.32,\"name\":\"hunger\",\"val\":963200},{\"percent\":95.584,\"name\":\"thirst\",\"val\":955840},{\"percent\":0.0,\"name\":\"drunk\",\"val\":0},{\"percent\":96.32,\"name\":\"hunger\",\"val\":963200},{\"percent\":95.584,\"name\":\"thirst\",\"val\":955840},{\"percent\":0.0,\"name\":\"drunk\",\"val\":0}]', 0, NULL, '2026-09-26 09:17:40', '2026-10-04 18:08:59', 0, 12, 0, 0, NULL, 200, 3480, NULL),
('license:3afb15e367e2e7c2a142ecc8760f66805116c992', '{\"bank\":1036625,\"black_money\":0,\"money\":2600}', '_dev', '[{\"name\":\"water\",\"count\":3,\"slot\":1},{\"name\":\"bread\",\"count\":5,\"slot\":2},{\"name\":\"money\",\"count\":2600,\"slot\":3}]', 'bennys', 'unemployed2', 3, 0, '[]', '[]', '{\"z\":31.234375,\"y\":-1306.20654296875,\"x\":-266.3208923339844}', 'jUNE', 'GUEVARO', '09/26/2000', 'm', 182, NULL, '[{\"percent\":100.0,\"val\":1000000,\"name\":\"hunger\"},{\"percent\":100.0,\"val\":1000000,\"name\":\"thirst\"},{\"percent\":0.0,\"val\":0,\"name\":\"drunk\"}]', 0, NULL, '2026-09-27 18:04:44', '2026-10-13 20:11:52', 0, 19, 0, 0, NULL, 200, 5400, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `user_licenses`
--

CREATE TABLE `user_licenses` (
  `id` int(11) NOT NULL,
  `type` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `owner` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `user_licenses`
--

INSERT INTO `user_licenses` (`id`, `type`, `owner`) VALUES
(2, 'weapon', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8');

-- --------------------------------------------------------

--
-- Table structure for table `vehicles`
--

CREATE TABLE `vehicles` (
  `name` varchar(60) NOT NULL,
  `model` varchar(60) NOT NULL,
  `price` int(11) NOT NULL,
  `category` varchar(60) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `vehicles`
--

INSERT INTO `vehicles` (`name`, `model`, `price`, `category`) VALUES
('Adder', 'adder', 900000, 'super'),
('Alpha', 'alpha', 75000, 'sports'),
('Asbo', 'asbo', 20000, 'dlc'),
('Asea', 'asea', 15000, 'sedans'),
('Autarch', 'autarch', 1955000, 'super'),
('Baller', 'baller2', 80000, 'suvs'),
('Baller Sport', 'baller3', 120000, 'suvs'),
('Banshee', 'banshee', 80000, 'sports'),
('Banshee 900R', 'banshee2', 255000, 'super'),
('Bestia GTS', 'bestiagts', 95000, 'sports'),
('Bf Injection', 'bfinjection', 35400, 'offroad'),
('Bifta', 'bifta', 40000, 'offroad'),
('Bison', 'bison', 43000, 'vans'),
('Blade', 'blade', 25000, 'muscle'),
('Blazer', 'blazer', 22500, 'offroad'),
('Blazer Sport', 'blazer4', 35000, 'offroad'),
('Blista', 'blista', 8000, 'compacts'),
('Bobcat XL', 'bobcatxl', 35000, 'vans'),
('Brawler', 'brawler', 80000, 'offroad'),
('Brioso R/A', 'brioso', 18000, 'compacts'),
('Brioso 300', 'brioso2', 25000, 'dlc'),
('Btype', 'btype', 110000, 'sportsclassics'),
('Btype Hotroad', 'btype2', 140000, 'sportsclassics'),
('Btype Luxe', 'btype3', 167000, 'sportsclassics'),
('Buccaneer', 'buccaneer', 20000, 'muscle'),
('Buccaneer Rider', 'buccaneer2', 28000, 'muscle'),
('Buffalo', 'buffalo', 37500, 'sports'),
('Buffalo S', 'buffalo2', 40000, 'sports'),
('Bullet', 'bullet', 90000, 'super'),
('Burrito', 'burrito3', 40000, 'vans'),
('Camper', 'camper', 45000, 'vans'),
('Carbonizzare', 'carbonizzare', 68900, 'sports'),
('Casco', 'casco', 67800, 'sportsclassics'),
('Cavalcade', 'cavalcade2', 30000, 'suvs'),
('Cheetah', 'cheetah', 375000, 'super'),
('Chino', 'chino', 27500, 'muscle'),
('Chino Luxe', 'chino2', 30000, 'muscle'),
('Cognoscenti Cabrio', 'cogcabrio', 30000, 'coupes'),
('Cognoscenti', 'cognoscenti', 55000, 'sedans'),
('Comet', 'comet2', 115000, 'sports'),
('Comet 5', 'comet5', 145000, 'sports'),
('Contender', 'contender', 70000, 'suvs'),
('Coquette', 'coquette', 135000, 'sports'),
('Coquette Classic', 'coquette2', 40000, 'dlc'),
('Coquette BlackFin', 'coquette3', 50000, 'muscle'),
('Cyclone', 'cyclone', 1890000, 'super'),
('Dominator', 'dominator', 50000, 'muscle'),
('8F Drafter', 'drafter', 190000, 'dlc'),
('Dubsta', 'dubsta', 75000, 'suvs'),
('Dubsta Luxuary', 'dubsta2', 100000, 'suvs'),
('Bubsta 6x6', 'dubsta3', 150000, 'offroad'),
('Dukes', 'dukes', 22500, 'muscle'),
('Dune Buggy', 'dune', 30000, 'offroad'),
('Dynasty', 'Dynasty', 25000, 'dlc'),
('Elegy', 'elegy2', 105000, 'sports'),
('Emerus', 'emerus', 300000, 'dlc'),
('Emperor', 'emperor', 10000, 'sedans'),
('Entity XF', 'entityxf', 425000, 'super'),
('Everon', 'everon', 80000, 'dlc'),
('Exemplar', 'exemplar', 40000, 'coupes'),
('F620', 'f620', 45000, 'coupes'),
('Faction', 'faction', 25000, 'muscle'),
('Faction Rider', 'faction2', 34500, 'muscle'),
('Faction XL', 'faction3', 145000, 'muscle'),
('Felon', 'felon', 37500, 'coupes'),
('Felon GT', 'felon2', 45000, 'coupes'),
('Feltzer', 'feltzer2', 75000, 'sports'),
('Stirling GT', 'feltzer3', 115000, 'sportsclassics'),
('FMJ', 'fmj', 285000, 'super'),
('Fhantom', 'fq2', 125000, 'suvs'),
('Fugitive', 'fugitive', 32000, 'sedans'),
('Furia', 'furia', 225000, 'dlc'),
('Furore GT', 'furoregt', 92000, 'sports'),
('Fusilade', 'fusilade', 55000, 'sports'),
('Gauntlet', 'gauntlet', 42000, 'muscle'),
('Gauntlet Classic', 'gauntlet3', 110000, 'dlc'),
('Gauntlet Hellfire', 'gauntlet4', 90000, 'dlc'),
('Gang Burrito', 'gburrito', 45000, 'vans'),
('Burrito', 'gburrito2', 42555, 'vans'),
('Glendale', 'glendale', 17500, 'sedans'),
('Grabger', 'granger', 50000, 'suvs'),
('Gresley', 'gresley', 42000, 'suvs'),
('GT 500', 'gt500', 132300, 'sportsclassics'),
('Guardian', 'guardian', 62500, 'offroad'),
('Hellion', 'hellion', 125000, 'dlc'),
('Hermes', 'hermes', 62340, 'muscle'),
('Hotknife', 'hotknife', 75000, 'muscle'),
('Huntley S', 'huntley', 35000, 'suvs'),
('Hustler', 'hustler', 85000, 'muscle'),
('Imorgon', 'imorgon', 125000, 'dlc'),
('Infernus', 'infernus', 180000, 'super'),
('Intruder', 'intruder', 27400, 'sedans'),
('Issi', 'issi2', 10000, 'compacts'),
('Issi Sport', 'issi7', 123000, 'dlc'),
('Itali RSX', 'italirsx', 300000, 'dlc'),
('Jackal', 'jackal', 38000, 'coupes'),
('JB 700W', 'jb7002', 76550, 'dlc'),
('Jester', 'jester', 62000, 'sports'),
('Jester(Racecar)', 'jester2', 80000, 'sports'),
('Journey', 'journey', 12300, 'vans'),
('Jugular', 'jugular', 175000, 'dlc'),
('Kamacho', 'kamacho', 95000, 'offroad'),
('Blista Kanjo', 'kanjo', 58000, 'dlc'),
('Khamelion', 'khamelion', 52500, 'sports'),
('Komoda', 'komoda', 133000, 'dlc'),
('Krieger', 'krieger', 125000, 'dlc'),
('Kuruma', 'kuruma', 135000, 'sports'),
('Landstalker', 'landstalker', 47600, 'suvs'),
('RE-7B', 'le7b', 325000, 'super'),
('Locust', 'locust', 210000, 'dlc'),
('Lynx', 'lynx', 145000, 'sports'),
('Mamba', 'mamba', 95700, 'sports'),
('Manana', 'manana', 34500, 'sportsclassics'),
('Massacro', 'massacro', 78000, 'sports'),
('Massacro(Racecar)', 'massacro2', 100000, 'sports'),
('Mesa', 'mesa', 36000, 'suvs'),
('Mesa Trail', 'mesa3', 40000, 'suvs'),
('Minivan', 'minivan', 35000, 'vans'),
('Monroe', 'monroe', 89000, 'sportsclassics'),
('Moonbeam', 'moonbeam', 50000, 'vans'),
('Moonbeam Rider', 'moonbeam2', 60000, 'vans'),
('Nebula turbo', 'nebula', 25000, 'dlc'),
('Neo', 'neo', 250000, 'dlc'),
('Neon', 'neon', 250000, 'sports'),
('Nightshade', 'nightshade', 65000, 'muscle'),
('9F', 'ninef', 97500, 'sports'),
('9F Cabrio', 'ninef2', 125000, 'sports'),
('Novak', 'Novak', 60000, 'dlc'),
('Omnis', 'omnis', 75000, 'sports'),
('Oracle XS', 'oracle2', 40000, 'coupes'),
('Osiris', 'osiris', 160000, 'super'),
('Outlaw', 'outlaw', 115000, 'dlc'),
('Panto', 'panto', 10000, 'compacts'),
('Paradise', 'paradise', 19000, 'vans'),
('Paragon R', 'paragon', 60000, 'dlc'),
('Pariah', 'pariah', 145000, 'sports'),
('Patriot', 'patriot', 55000, 'suvs'),
('Penumbra', 'penumbra', 64500, 'sports'),
('Peyote Gasser', 'peyote2', 60000, 'dlc'),
('Pfister', 'pfister811', 85000, 'super'),
('Phoenix', 'phoenix', 34500, 'muscle'),
('Picador', 'picador', 32000, 'muscle'),
('Pigalle', 'pigalle', 75600, 'sportsclassics'),
('Prairie', 'prairie', 12000, 'compacts'),
('Premier', 'premier', 13200, 'sedans'),
('Primo Custom', 'primo2', 47500, 'sedans'),
('X80 Proto', 'prototipo', 2500000, 'super'),
('Radius', 'radi', 32500, 'suvs'),
('Raiden', 'raiden', 450000, 'sports'),
('Rapid GT', 'rapidgt', 84500, 'sports'),
('Rapid GT Convertible', 'rapidgt2', 90000, 'sports'),
('Rapid GT3', 'rapidgt3', 60000, 'sportsclassics'),
('Reaper', 'reaper', 150000, 'super'),
('Rebel', 'rebel2', 22000, 'offroad'),
('Rebla GTS', 'rebla', 90000, 'dlc'),
('Regina', 'regina', 12200, 'sedans'),
('Retinue', 'retinue', 55000, 'sportsclassics'),
('Retinue MK ll', 'retinue2', 35000, 'dlc'),
('Revolter', 'revolter', 105000, 'sports'),
('Riata', 'riata', 55000, 'offroad'),
('Rocoto', 'rocoto', 55500, 'suvs'),
('Rumpo', 'rumpo', 25000, 'vans'),
('Rumpo Trail', 'rumpo3', 85000, 'vans'),
('S80RR', 's80', 120000, 'dlc'),
('Sabre Turbo', 'sabregt', 27500, 'muscle'),
('Sabre GT', 'sabregt2', 37500, 'muscle'),
('Sandking', 'sandking', 64000, 'offroad'),
('Savestra', 'savestra', 112000, 'sportsclassics'),
('SC 1', 'sc1', 1603000, 'super'),
('Schafter', 'schafter2', 72500, 'sedans'),
('Schafter V12', 'schafter3', 54600, 'sports'),
('Seminole', 'seminole', 45600, 'suvs'),
('Sentinel', 'sentinel', 35000, 'coupes'),
('Sentinel XS', 'sentinel2', 40000, 'coupes'),
('Sentinel3', 'sentinel3', 42000, 'sports'),
('Seven 70', 'seven70', 420000, 'sports'),
('ETR1', 'sheava', 220000, 'super'),
('Slam Van', 'slamvan3', 37500, 'muscle'),
('Stinger', 'stinger', 92000, 'sportsclassics'),
('Stinger GT', 'stingergt', 120000, 'sportsclassics'),
('Streiter', 'streiter', 130000, 'sports'),
('Stretch', 'stretch', 290000, 'sedans'),
('Sugoi', 'Sugoi', 75000, 'dlc'),
('Sultan', 'sultan', 83400, 'sports'),
('Sultan Classic', 'sultan2', 150000, 'dlc'),
('Sultan RS', 'sultanrs', 65000, 'super'),
('Super Diamond', 'superd', 34500, 'sedans'),
('Surano', 'surano', 72400, 'sports'),
('Surfer', 'surfer', 15000, 'vans'),
('Tailgater', 'tailgater', 24600, 'sedans'),
('Tampa', 'tampa', 43500, 'muscle'),
('Drift Tampa', 'tampa2', 83403, 'sports'),
('Thrax', 'thrax', 300000, 'dlc'),
('Trophy Truck', 'trophytruck', 90000, 'offroad'),
('Trophy Truck Limited', 'trophytruck2', 115000, 'offroad'),
('Tropos', 'tropos', 92300, 'sports'),
('Turismo R', 'turismor', 350000, 'super'),
('Tyrus', 'tyrus', 600000, 'super'),
('Vacca', 'vacca', 120000, 'super'),
('Vagrant', 'vagrant', 50000, 'dlc'),
('Verlierer', 'verlierer2', 75000, 'sports'),
('Verus', 'verus', 15000, 'dlc'),
('Veto Classic', 'veto', 895000, 'dlc'),
('Veto Modern', 'veto2', 995000, 'dlc'),
('Vigero', 'vigero', 41500, 'muscle'),
('Virgo', 'virgo', 33500, 'muscle'),
('Viseris', 'viseris', 200000, 'sportsclassics'),
('Visione', 'visione', 2250000, 'super'),
('Voltic', 'voltic', 90000, 'super'),
('Voltic 2', 'voltic2', 3830400, 'super'),
('Voodoo', 'voodoo', 37500, 'muscle'),
('V-STR', 'vstr', 115000, 'dlc'),
('Warrener', 'warrener', 22000, 'sedans'),
('Washington', 'washington', 19000, 'sedans'),
('Weevil', 'weevil', 87000, 'dlc'),
('Windsor', 'windsor', 95000, 'coupes'),
('Windsor Drop', 'windsor2', 125000, 'coupes'),
('Dominator 3', 'dominator3', 60000, 'muscle'),
('XLS', 'xls', 65000, 'suvs'),
('Yosemite', 'yosemite', 52500, 'muscle'),
('Drift Yosemite', 'yosemite2', 35000, 'dlc'),
('Youga', 'youga', 25000, 'vans'),
('Youga Luxuary', 'youga2', 35000, 'vans'),
('Z190', 'z190', 105000, 'sportsclassics'),
('Zentorno', 'zentorno', 1500000, 'super'),
('Zion', 'zion', 36000, 'coupes'),
('Zion Cabrio', 'zion2', 45000, 'coupes'),
('Zion Classic', 'zion3', 35000, 'dlc'),
('Zorrusso', 'zorrusso', 225000, 'dlc'),
('Z-Type', 'ztype', 125000, 'sportsclassics'),
('Vulcar Warrener HKR', 'warrener2', 25000, 'dlc'),
('Vapid Dominator ASP', 'dominator7', 145000, 'dlc'),
('Vapid Dominator GTT', 'dominator8', 90000, 'dlc'),
('Annis Euros', 'euros', 205000, 'dlc'),
('Karin Futo GTX', 'futo2', 56000, 'dlc'),
('Dinka RT3000', 'rt3000', 145000, 'dlc'),
('Karin Sultan RS Classique', 'sultan3', 150000, 'dlc'),
('Obey Tailgater S', 'tailgater2', 256000, 'dlc'),
('Pfister Growler', 'growler', 280000, 'dlc'),
('Emperor Vectre', 'vectre', 235000, 'dlc'),
('Annis Remus', 'remus', 27500, 'dlc'),
('Karin Calico GTF', 'calico', 200000, 'dlc'),
('Ubermacht Cypher', 'cypher', 200000, 'dlc'),
('Dinka Jester RR', 'jester4', 180000, 'dlc'),
('Annis ZR350', 'zr350', 125000, 'dlc'),
('Karin Previon', 'previon', 125000, 'dlc'),
('Pfister Comet S2', 'comet6', 256000, 'dlc'),
('Akuma', 'AKUMA', 22000, 'motorcycles'),
('Avarus', 'avarus', 17500, 'motorcycles'),
('Bagger', 'bagger', 7500, 'motorcycles'),
('Bati 801', 'bati', 37500, 'motorcycles'),
('Bati 801RR', 'bati2', 45000, 'motorcycles'),
('BF400', 'bf400', 35000, 'motorcycles'),
('Bmx', 'bmx', 500, 'velo'),
('Carbon RS', 'carbonrs', 27500, 'motorcycles'),
('Chimera', 'chimera', 65000, 'motorcycles'),
('Cliffhanger', 'cliffhanger', 35000, 'motorcycles'),
('Cruiser', 'cruiser', 200, 'velo'),
('Daemon', 'daemon', 60000, 'motorcycles'),
('Daemon High', 'daemon2', 70000, 'motorcycles'),
('Defiler', 'defiler', 32500, 'motorcycles'),
('Diabolus', 'diablous', 20000, 'motorcycles'),
('Diabolus Custom', 'diablous2', 20000, 'motorcycles'),
('Double T', 'double', 35000, 'motorcycles'),
('Enduro', 'enduro', 20000, 'motorcycles'),
('Esskey', 'esskey', 27500, 'motorcycles'),
('Faggio', 'faggio', 2500, 'motorcycles'),
('Vespa', 'faggio3', 3000, 'motorcycles'),
('FCR 1000', 'fcr', 1000, 'motorcycles'),
('FCR 1000 custom', 'fcr2', 1000, 'motorcycles'),
('Fixter', 'fixter', 400, 'velo'),
('Gargoyle', 'gargoyle', 80000, 'motorcycles'),
('Hakuchou', 'hakuchou', 110000, 'motorcycles'),
('Hakuchou Sport', 'hakuchou2', 100000, 'motorcycles'),
('Hexer', 'hexer', 40000, 'motorcycles'),
('Innovation', 'innovation', 42000, 'motorcycles'),
('Manchez', 'manchez', 45000, 'motorcycles'),
('Manchez Scout', 'manchez2', 22500, 'dlc'),
('Nemesis', 'nemesis', 24000, 'motorcycles'),
('Nightblade', 'nightblade', 55000, 'motorcycles'),
('PCJ-600', 'pcj', 15500, 'motorcycles'),
('R6', 'R6', 50000, 'Motosimports'),
('Rat biker', 'ratbike', 14500, 'motorcycles'),
('Rampant Rocket', 'rrocket', 110000, 'dlc'),
('Ruffian', 'ruffian', 17550, 'motorcycles'),
('Sanchez', 'sanchez', 30000, 'motorcycles'),
('Sanchez Sport', 'sanchez2', 35000, 'motorcycles'),
('Sanctus', 'sanctus', 75000, 'motorcycles'),
('Scorcher', 'scorcher', 800, 'velo'),
('Sovereign', 'sovereign', 52000, 'motorcycles'),
('Thrust', 'thrust', 22000, 'motorcycles'),
('tm2019', 'tm2019', 42500, 'Motosimports'),
('Tmax', 'Tmax', 200000, 'Motosimports'),
('Whippet', 'tribike', 500, 'velo'),
('Endurex', 'tribike2', 500, 'velo'),
('Tri-cycles', 'tribike3', 1000, 'velo'),
('Vader', 'vader', 20000, 'motorcycles'),
('Vortex', 'vortex', 32000, 'motorcycles'),
('Woflsbane', 'wolfsbane', 62500, 'motorcycles'),
('Zombie', 'zombiea', 85000, 'motorcycles'),
('Zombie Luxuary', 'zombieb', 95000, 'motorcycles'),
('Dinghy 4Seat', 'dinghy', 25000, 'boat'),
('Dinghy 2Seat', 'dinghy2', 20000, 'boat'),
('Dinghy Yacht', 'dinghy4', 25000, 'boat'),
('Jetmax', 'jetmax', 30000, 'boat'),
('Marquis', 'marquis', 45000, 'boat'),
('Seashark', 'seashark', 10000, 'boat'),
('Seashark Yacht', 'seashark3', 10000, 'boat'),
('Speeder', 'speeder', 40000, 'boat'),
('Squalo', 'squalo', 32000, 'boat'),
('Submarine', 'submersible', 29000, 'subs'),
('Kraken', 'submersible2', 31000, 'subs'),
('Suntrap', 'suntrap', 34000, 'boat'),
('Toro', 'toro', 38000, 'boat'),
('Toro Yacht', 'toro2', 38000, 'boat'),
('Tropic', 'tropic', 27000, 'boat'),
('Tropic Yacht', 'tropic2', 27000, 'boat');

-- --------------------------------------------------------

--
-- Table structure for table `vehicle_categories`
--

CREATE TABLE `vehicle_categories` (
  `name` varchar(60) NOT NULL,
  `label` varchar(60) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `vehicle_categories`
--

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
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `vips`
--

CREATE TABLE `vips` (
  `identifier` varchar(50) NOT NULL,
  `vip` int(11) DEFAULT NULL,
  `expiration` int(11) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `worldbuilder_chase_stats`
--

INSERT INTO `worldbuilder_chase_stats` (`identifier`, `name`, `matches`, `wins_runner`, `wins_chaser`, `losses`) VALUES
('license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 11, 4, 2, 5),
('license:17015558e9d71c65e5de4c4c417d582ba4f005f1', 'MOUNIR PABLO', 11, 3, 3, 5),
('license:3afb15e367e2e7c2a142ecc8760f66805116c992', 'jUNE GUEVARO', 1, 0, 0, 1);

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `worldbuilder_entities`
--

INSERT INTO `worldbuilder_entities` (`id`, `type`, `name`, `label`, `enabled`, `settings`, `points`, `stats`, `created_by`, `created_at`, `updated_at`) VALUES
(11, 'rental', 'location_de_voitures', 'Location de voitures', 1, '{\"marker\":{\"enabled\":true,\"type\":25},\"access\":{\"jobs\":[],\"item\":\"\"},\"society\":\"\",\"refundDamage\":true,\"payments\":{\"cash\":true,\"bank\":true,\"black_money\":false},\"fleet\":[{\"label\":\"Scooter\",\"model\":\"faggio\",\"deposit\":150,\"price\":80,\"minGrade\":0},{\"label\":\"Citadine\",\"model\":\"panto\",\"deposit\":300,\"price\":150,\"minGrade\":0},{\"label\":\"Compacte\",\"model\":\"blista\",\"deposit\":450,\"price\":220,\"minGrade\":0},{\"label\":\"Berline sport\",\"model\":\"sultan\",\"deposit\":1000,\"price\":450,\"minGrade\":0}],\"note\":\"\",\"blip\":{\"sprite\":225,\"label\":\"Location\",\"scale\":0.5,\"enabled\":true,\"shortRange\":true,\"color\":16},\"minutes\":60}', '[{\"ret\":{\"z\":37.53,\"y\":-128.52,\"x\":-821.2,\"h\":330.77},\"color2\":[254,11,11],\"spawns\":[{\"z\":37.47,\"y\":-125.9,\"x\":-817.77,\"h\":243.7}],\"color\":[0,168,255],\"label\":\"Agence de location\",\"coords\":{\"z\":37.45,\"y\":-122.03,\"x\":-819.54,\"h\":200.48},\"kind\":\"main\",\"blip\":true,\"ped\":{\"enabled\":true,\"scenario\":\"WORLD_HUMAN_STAND_IMPATIENT\",\"model\":\"a_m_y_business_02\",\"pos\":{\"z\":37.48,\"y\":-120.85,\"x\":-820.09,\"h\":201.82}}}]', '{\"rentals\":3,\"revenue\":610}', 'Pickax', '2026-10-07 19:35:54', '2026-10-13 18:27:02'),
(21, 'locksmith', 'serrurier', 'Serrurier', 1, '{\"access\":{\"item\":\"\",\"jobs\":[]},\"marker\":{\"enabled\":true,\"type\":25},\"society\":\"\",\"blip\":{\"enabled\":true,\"shortRange\":true,\"scale\":0.5,\"color\":5,\"sprite\":402,\"label\":\"Serrurier\"},\"requireNearby\":true,\"cooldown\":60,\"payments\":{\"black_money\":false,\"bank\":true,\"cash\":true},\"note\":\"\",\"price\":250,\"keyItem\":\"\"}', '[{\"blip\":true,\"coords\":{\"x\":258.54,\"h\":172.01,\"z\":30.52,\"y\":-782.7},\"kind\":\"shop\",\"label\":\"Atelier de serrurier\",\"ped\":{\"enabled\":true,\"model\":\"s_m_y_construct_01\",\"pos\":{\"x\":259.78,\"h\":70.27,\"z\":30.51,\"y\":-783.15},\"scenario\":\"WORLD_HUMAN_CLIPBOARD\"}}]', '{\"keys\":5,\"revenue\":1250}', 'Pickax', '2026-10-07 20:17:35', '2026-10-10 21:36:52'),
(24, 'pvp', 'zones_pvp', 'Zones PVP', 1, '{\"blip\":{\"sprite\":110,\"enabled\":true,\"color\":1,\"label\":\"Zones PVP\",\"scale\":0.5,\"shortRange\":true},\"rewardAccount\":\"black_money\",\"color\":[255,0,0],\"access\":{\"jobs\":[],\"item\":\"\"},\"marker\":{\"type\":25,\"enabled\":true},\"note\":\"Les zones se placent en jeu : position = centre\"}', '[{\"blip\":true,\"label\":\"Zones PVP\",\"ped\":{\"model\":\"s_m_y_ammucity_01\",\"pos\":{\"y\":-2506.21,\"x\":-689.91,\"h\":244.76,\"z\":13.94},\"scenario\":\"WORLD_HUMAN_GUARD_STAND\",\"enabled\":true},\"kind\":\"lobby\",\"coords\":{\"y\":-2506.66,\"x\":-688.94,\"h\":80.16,\"z\":13.94}},{\"weapons\":[{\"name\":\"WEAPON_PISTOL\",\"ammo\":250}],\"infiniteAmmo\":true,\"radius\":40,\"color\":[226,24,24],\"reviveEnabled\":true,\"giveWeapons\":true,\"blip\":false,\"reviveDelay\":3,\"healOnKill\":false,\"spawnProtection\":3,\"ped\":{\"model\":\"\",\"scenario\":\"\",\"enabled\":false},\"armorOnRespawn\":false,\"coords\":{\"y\":-3044.12,\"x\":-1336.21,\"h\":314.97,\"z\":13.94},\"removeOnExit\":true,\"killReward\":100,\"kind\":\"zone\",\"label\":\"Arène\",\"spawns\":[{\"y\":-3016.38,\"x\":-1345.67,\"h\":110.17,\"z\":13.96},{\"y\":-3015.12,\"x\":-1324.44,\"h\":87.62,\"z\":14.29},{\"y\":-3030.57,\"x\":-1312.01,\"h\":14.61,\"z\":14.28}]}]', '{\"kills\":2}', 'Pickax', '2026-10-07 20:53:44', '2026-10-11 12:23:03'),
(25, 'chase', 'course_poursuite', 'Course poursuite', 1, '{\"color\":[202,10,255],\"headStart\":0,\"note\":\"Un fugitif contre des poursuivants : colle le fugitif assez longtemps pour gagner\",\"catchDistance\":8,\"vehicles\":[{\"model\":\"sultan\",\"accel\":66,\"speed\":68,\"category\":\"Sportive\",\"label\":\"Karin Sultan\",\"handling\":72},{\"model\":\"elegy2\",\"accel\":70,\"speed\":74,\"category\":\"Sportive\",\"label\":\"Annis Elegy RH8\",\"handling\":78},{\"model\":\"jester\",\"accel\":74,\"speed\":78,\"category\":\"Sportive\",\"label\":\"Dinka Jester\",\"handling\":75},{\"model\":\"kuruma\",\"accel\":70,\"speed\":72,\"category\":\"Sportive\",\"label\":\"Karin Kuruma\",\"handling\":70},{\"model\":\"comet2\",\"accel\":72,\"speed\":76,\"category\":\"Sportive\",\"label\":\"Pfister Comet\",\"handling\":77},{\"model\":\"zentorno\",\"accel\":88,\"speed\":90,\"category\":\"Super\",\"label\":\"Pegassi Zentorno\",\"handling\":80},{\"model\":\"adder\",\"accel\":82,\"speed\":92,\"category\":\"Super\",\"label\":\"Truffade Adder\",\"handling\":72},{\"model\":\"t20\",\"accel\":90,\"speed\":93,\"category\":\"Super\",\"label\":\"Progen T20\",\"handling\":78},{\"model\":\"vacca\",\"accel\":84,\"speed\":86,\"category\":\"Super\",\"label\":\"Pegassi Vacca\",\"handling\":78},{\"model\":\"dominator\",\"accel\":78,\"speed\":74,\"category\":\"Muscle\",\"label\":\"Vapid Dominator\",\"handling\":55},{\"model\":\"gauntlet\",\"accel\":76,\"speed\":72,\"category\":\"Muscle\",\"label\":\"Bravado Gauntlet\",\"handling\":52},{\"model\":\"buffalo\",\"accel\":68,\"speed\":70,\"category\":\"Berline\",\"label\":\"Bravado Buffalo\",\"handling\":70},{\"model\":\"schafter3\",\"accel\":66,\"speed\":70,\"category\":\"Berline\",\"label\":\"Benefactor Schafter V12\",\"handling\":68},{\"model\":\"bati\",\"accel\":92,\"speed\":84,\"category\":\"Moto\",\"label\":\"Pegassi Bati 801\",\"handling\":82},{\"model\":\"akuma\",\"accel\":90,\"speed\":82,\"category\":\"Moto\",\"label\":\"Dinka Akuma\",\"handling\":80},{\"model\":\"sanchez\",\"accel\":74,\"speed\":62,\"category\":\"Moto\",\"label\":\"Maibatsu Sanchez\",\"handling\":78},{\"model\":\"tolrs6\",\"accel\":100,\"speed\":100,\"category\":\"Sportive\",\"label\":\"Rs6\",\"handling\":100}],\"blip\":{\"sprite\":315,\"scale\":0.5,\"shortRange\":true,\"color\":3,\"label\":\"Course poursuite\",\"enabled\":true},\"catchTime\":3,\"rewardLose\":0,\"entryFee\":500,\"durationDefault\":8,\"durationMin\":2,\"durationMax\":20,\"countdown\":5,\"maxChasers\":4,\"requireVehicle\":true,\"access\":{\"jobs\":[],\"item\":\"\"},\"maxPerformance\":true,\"traffic\":false,\"runnerSeesChasers\":false,\"rewardWin\":0,\"rewardAccount\":\"bank\",\"marker\":{\"enabled\":true,\"type\":25}}', '[{\"blip\":true,\"ped\":{\"model\":\"s_m_y_cop_01\",\"enabled\":true,\"pos\":{\"h\":238.62,\"x\":-707.79,\"y\":-2448.21,\"z\":13.94},\"scenario\":\"WORLD_HUMAN_CLIPBOARD\"},\"kind\":\"lobby\",\"label\":\"Course poursuite\",\"coords\":{\"h\":238.24,\"x\":-706.75,\"y\":-2448.85,\"z\":13.94}},{\"blip\":false,\"desc\":\"Grandes avenues et carrefours, trafic dense.\",\"ped\":{\"model\":\"\",\"enabled\":false,\"scenario\":\"\"},\"kind\":\"map\",\"runner\":{\"h\":164.01,\"x\":287.01,\"y\":185.2,\"z\":104.41},\"spawns\":[{\"h\":159.06,\"x\":298.6,\"y\":181.4,\"z\":104.19}],\"label\":\"Vinewood Boulevard\",\"coords\":{\"h\":70,\"x\":293.0999999999767,\"y\":180.5,\"z\":104.20000000001164}},{\"blip\":false,\"desc\":\"Autoroute rapide, idéale pour les supercars.\",\"ped\":{\"model\":\"\",\"enabled\":false,\"scenario\":\"\"},\"kind\":\"map\",\"spawns\":[],\"label\":\"Del Perro Freeway\",\"coords\":{\"h\":215,\"x\":-1105,\"y\":-520,\"z\":34}},{\"blip\":false,\"desc\":\"Longues lignes droites dans le désert.\",\"ped\":{\"model\":\"\",\"enabled\":false,\"scenario\":\"\"},\"kind\":\"map\",\"spawns\":[],\"label\":\"Route 68 – Sandy\",\"coords\":{\"h\":300,\"x\":1583,\"y\":3584,\"z\":35.39999999999418}}]', '{\"matches\":12}', 'Pickax', '2026-10-10 16:56:24', '2026-10-12 13:42:12'),
(26, 'fuel', 'station_essence', 'Station essence', 1, '{\"access\":{\"item\":\"\",\"jobs\":[]},\"marker\":{\"enabled\":true,\"type\":25},\"tank\":5000,\"society\":\"\",\"restockMinutes\":60,\"blip\":{\"enabled\":true,\"shortRange\":true,\"scale\":0.5,\"color\":1,\"sprite\":361,\"label\":\"Station essence\"},\"restockLiters\":200,\"payments\":{\"black_money\":false,\"bank\":true,\"cash\":true},\"note\":\"\",\"price\":3,\"jerrycan\":{\"enabled\":true,\"price\":80,\"item\":\"WEAPON_PETROLCAN\"}}', '[{\"blip\":true,\"color\":[254,138,6],\"coords\":{\"x\":263.88,\"h\":169.96,\"z\":29.14,\"y\":-1253.45},\"kind\":\"pump\",\"label\":\"Pompe 1\",\"ped\":{\"enabled\":false,\"model\":\"\",\"scenario\":\"\"}},{\"blip\":false,\"color\":[255,149,0],\"coords\":{\"x\":263.85,\"h\":278.37,\"z\":29.14,\"y\":-1261.34},\"kind\":\"pump\",\"label\":\"Pompe 2\",\"ped\":{\"enabled\":false,\"model\":\"\",\"scenario\":\"\"}}]', '{\"tank\":5000,\"liters\":26,\"revenue\":78,\"restockAt\":1791929645}', 'Pickax', '2026-10-10 17:02:39', '2026-10-13 22:14:08'),
(27, 'bank', 'agence_bancaire', 'Agence bancaire', 1, '{\"society\":\"\",\"dailyLimit\":0,\"blip\":{\"sprite\":108,\"enabled\":true,\"label\":\"Banque\",\"scale\":0.5,\"shortRange\":true,\"color\":2},\"atmDeposit\":false,\"transferFee\":2,\"maxTransaction\":0,\"color\":[0,153,18],\"access\":{\"item\":\"\",\"jobs\":[]},\"withdrawFee\":0,\"marker\":{\"enabled\":true,\"type\":25},\"depositFee\":0,\"uiColor\":[0,153,18],\"note\":\"\"}', '[{\"coords\":{\"x\":150.32,\"h\":159.09,\"z\":29.37,\"y\":-1040.16},\"blip\":true,\"ped\":{\"pos\":{\"x\":149.36,\"h\":336.95,\"z\":29.37,\"y\":-1042.11},\"enabled\":true,\"scenario\":\"WORLD_HUMAN_CLIPBOARD\",\"model\":\"ig_bankman\"},\"kind\":\"counter\",\"label\":\"Guichet\"},{\"coords\":{\"x\":147.69,\"h\":67.49,\"z\":29.34,\"y\":-1035.63},\"blip\":false,\"ped\":{\"scenario\":\"\",\"enabled\":false,\"model\":\"\"},\"kind\":\"atm\",\"label\":\"Distributeur\"}]', '{\"deposits\":100,\"revenue\":0,\"withdrawn\":100}', 'Pickax', '2026-10-10 20:58:56', '2026-10-11 15:00:33'),
(29, 'impound', 'fourriere', 'Fourrière', 1, '{\"maxFee\":5000,\"payments\":{\"cash\":true,\"black_money\":false,\"bank\":true},\"blip\":{\"sprite\":68,\"enabled\":true,\"label\":\"Fourrière\",\"scale\":0.5,\"shortRange\":true,\"color\":47},\"impoundJobs\":[],\"fee\":500,\"access\":{\"item\":\"\",\"jobs\":[]},\"types\":[],\"marker\":{\"enabled\":true,\"type\":25},\"perDay\":100,\"society\":\"\",\"note\":\"\"}', '[{\"label\":\"Fourrière\",\"blip\":true,\"ped\":{\"pos\":{\"x\":408.91,\"h\":230.45,\"z\":29.29,\"y\":-1622.86},\"enabled\":true,\"scenario\":\"WORLD_HUMAN_CLIPBOARD\",\"model\":\"s_m_y_construct_01\"},\"spawns\":[{\"x\":410.91,\"h\":228.32,\"z\":29.29,\"y\":-1636.62}],\"kind\":\"main\",\"coords\":{\"x\":409.79,\"h\":141.36,\"z\":29.29,\"y\":-1623.46}}]', '{\"revenue\":1500,\"released\":3}', 'Pickax', '2026-10-11 10:15:49', '2026-10-11 15:01:11'),
(30, 'garage', 'garage_public', 'Garage public', 1, '{\"marker\":{\"enabled\":true,\"type\":25},\"fleet\":[],\"types\":[\"car\",\"bike\"],\"bound\":false,\"mode\":\"owned\",\"society\":\"\",\"access\":{\"jobs\":[],\"item\":\"\"},\"plate\":\"SRV\",\"note\":\"\",\"blip\":{\"shortRange\":true,\"enabled\":true,\"scale\":0.5,\"sprite\":357,\"color\":3,\"label\":\"Garage\"},\"payments\":{\"cash\":true,\"bank\":true,\"black_money\":false},\"fee\":0}', '[{\"color\":[0,157,255],\"blip\":true,\"coords\":{\"z\":31.08,\"y\":-887.42,\"x\":-283.4,\"h\":345.96},\"store\":{\"z\":31.08,\"y\":-894.93,\"x\":-286.44,\"h\":243.68},\"kind\":\"main\",\"color2\":[0,145,255],\"spawns\":[{\"z\":31.08,\"y\":-887.75,\"x\":-285.62,\"h\":168.28}],\"ped\":{\"scenario\":\"WORLD_HUMAN_CLIPBOARD\",\"pos\":{\"z\":31.08,\"y\":-887.63,\"x\":-282.29,\"h\":72.91},\"enabled\":true,\"model\":\"s_m_y_valet_01\"},\"label\":\"Garage\"}]', '[]', 'Pickax', '2026-10-11 15:03:03', '2026-10-11 17:49:48'),
(31, 'garage', 'garage_public_copie', 'Garage public (copie)', 1, '{\"marker\":{\"enabled\":true,\"type\":25},\"fleet\":[],\"types\":[\"car\",\"bike\"],\"bound\":false,\"mode\":\"owned\",\"society\":\"\",\"access\":{\"jobs\":[],\"item\":\"\"},\"plate\":\"SRV\",\"note\":\"\",\"blip\":{\"shortRange\":true,\"enabled\":true,\"scale\":0.5,\"sprite\":357,\"color\":3,\"label\":\"Garage\"},\"payments\":{\"cash\":true,\"bank\":true,\"black_money\":false},\"fee\":0}', '[{\"color\":[0,157,255],\"blip\":true,\"coords\":{\"z\":30.73,\"y\":-810.03,\"x\":215.94,\"h\":160.78},\"store\":{\"z\":30.88,\"y\":-799.43,\"x\":212.18,\"h\":55.12},\"kind\":\"main\",\"color2\":[0,145,255],\"spawns\":[{\"z\":30.68,\"y\":-808.92,\"x\":219.66,\"h\":249.22}],\"ped\":{\"scenario\":\"WORLD_HUMAN_CLIPBOARD\",\"pos\":{\"z\":30.76,\"y\":-809.69,\"x\":214.9,\"h\":247.27},\"enabled\":true,\"model\":\"s_m_y_valet_01\"},\"label\":\"Garage\"}]', '[]', 'Pickax', '2026-10-11 17:47:48', '2026-10-11 17:49:52'),
(37, 'doorlock', 'bennys', 'bennys', 1, '{\"access\":{\"item\":\"\",\"jobs\":[]},\"blip\":{\"enabled\":false,\"scale\":0.79999999999995,\"shortRange\":true,\"label\":\"\",\"sprite\":52,\"color\":0},\"note\":\"Réservées au métier choisi\",\"marker\":{\"enabled\":true,\"type\":25}}', '[{\"label\":\"Porte d\'entrée\",\"locked\":true,\"useKey\":true,\"blip\":false,\"doors\":[{\"z\":30.45,\"y\":-1313.29,\"x\":-207.77,\"model\":-1453834687,\"h\":180}],\"showText\":true,\"kind\":\"lock\",\"showMarker\":false,\"access\":{\"jobs2\":[],\"mode\":\"any\",\"item\":\"\",\"jobs\":{\"bennys\":0}},\"autoLock\":0,\"coords\":{\"x\":-208.08,\"h\":136.5,\"z\":31.3,\"y\":-1321.72},\"ped\":{\"enabled\":false,\"model\":\"\",\"scenario\":\"\"}}]', '{\"uses\":18}', 'Pickax', '2026-10-12 12:48:43', '2026-10-13 19:22:39');

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `worldbuilder_licenses`
--

CREATE TABLE `worldbuilder_licenses` (
  `identifier` varchar(80) NOT NULL,
  `license` varchar(40) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `worldbuilder_licenses`
--

INSERT INTO `worldbuilder_licenses` (`identifier`, `license`, `created_at`) VALUES
('license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'dmv', '2026-10-07 19:58:15'),
('license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'drive', '2026-10-07 20:03:03');

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `worldbuilder_logs`
--

INSERT INTO `worldbuilder_logs` (`id`, `entity_id`, `entity_label`, `type`, `identifier`, `player_name`, `action`, `detail`, `amount`, `created_at`) VALUES
(1, 1, 'Station essence', 'fuel', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Station essence (station)', 0, '2026-10-05 18:47:30'),
(2, 1, 'Station essence', 'fuel', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), désactivé', 0, '2026-10-05 18:47:33'),
(3, 1, 'Station essence', 'fuel', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-05 18:47:41'),
(4, 1, 'Station essence', 'fuel', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'jerrycan', 'WEAPON_PETROLCAN', 80, '2026-10-05 18:47:56'),
(5, 1, 'Station essence', 'fuel', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'delete', 'Station essence', 0, '2026-10-05 18:48:03'),
(6, 2, 'Fourrière', 'impound', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Fourrière (impound)', 0, '2026-10-05 18:48:09'),
(7, 2, 'Fourrière', 'impound', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), désactivé', 0, '2026-10-05 18:48:20'),
(8, 2, 'Fourrière', 'impound', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), désactivé', 0, '2026-10-05 18:48:40'),
(9, 2, 'Fourrière', 'impound', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-05 18:48:43'),
(10, 2, 'Fourrière', 'impound', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'delete', 'Fourrière', 0, '2026-10-07 18:49:14'),
(11, 3, 'test', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'test (public)', 0, '2026-10-07 18:49:21'),
(12, 3, 'test', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 18:49:30'),
(13, 4, 'Location de bateaux', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Location de bateaux (boats)', 0, '2026-10-07 18:51:09'),
(14, 4, 'Location de bateaux', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 18:51:12'),
(15, 4, 'Location de bateaux', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 18:51:24'),
(16, 4, 'Location de bateaux', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'delete', 'Location de bateaux', 0, '2026-10-07 18:51:35'),
(17, 5, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Location de voitures (cars)', 0, '2026-10-07 18:51:40'),
(18, 5, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), désactivé', 0, '2026-10-07 18:51:52'),
(19, 5, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 18:51:59'),
(20, 5, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 18:52:34'),
(21, 5, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'rent', 'faggio (LOC21141)', 230, '2026-10-07 18:52:38'),
(22, 5, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'return', 'LOC21141 — caution rendue 150/150', 150, '2026-10-07 18:52:43'),
(23, 5, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'rent', 'faggio (LOC81851)', 230, '2026-10-07 18:52:51'),
(24, 5, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'return', 'LOC81851 — caution rendue 150/150', 150, '2026-10-07 18:52:57'),
(25, 3, 'test', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 18:53:50'),
(26, 3, 'test', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 18:54:32'),
(27, 5, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 18:55:12'),
(28, 5, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'delete', 'Location de voitures', 0, '2026-10-07 18:55:25'),
(29, 3, 'test', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 18:55:45'),
(30, 3, 'test', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 18:55:55'),
(31, 3, 'test', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 19:00:07'),
(32, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 19:00:44'),
(33, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 19:01:29'),
(34, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'take', '04EAP598', 0, '2026-10-07 19:03:50'),
(35, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'store', '04EAP598', 0, '2026-10-07 19:03:59'),
(36, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 19:04:23'),
(37, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 19:04:41'),
(38, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 19:04:45'),
(39, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 19:05:19'),
(40, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 19:08:44'),
(41, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'take', '77PHJ349', 0, '2026-10-07 19:08:51'),
(42, 6, 'Station essence', 'fuel', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Station essence (station)', 0, '2026-10-07 19:09:13'),
(43, 6, 'Station essence', 'fuel', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), désactivé', 0, '2026-10-07 19:09:16'),
(44, 6, 'Station essence', 'fuel', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-07 19:09:19'),
(45, 6, 'Station essence', 'fuel', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'fuel', '23 L', 69, '2026-10-07 19:09:32'),
(46, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'store', '77PHJ349', 0, '2026-10-07 19:09:47'),
(47, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'take', '77PHJ349', 0, '2026-10-07 19:09:53'),
(48, 6, 'Station essence', 'fuel', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'fuel', '9 L', 27, '2026-10-07 19:10:11'),
(49, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'store', '77PHJ349', 0, '2026-10-07 19:10:21'),
(50, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'take', '77PHJ349', 0, '2026-10-07 19:10:28'),
(51, 6, 'Station essence', 'fuel', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'jerrycan', 'WEAPON_PETROLCAN', 80, '2026-10-07 19:10:50'),
(52, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'store', '77PHJ349', 0, '2026-10-07 19:11:31'),
(53, 7, 'Banque (coffre)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Banque (coffre) (bank)', 0, '2026-10-07 19:11:48'),
(54, 7, 'Banque (coffre)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 point(s), désactivé', 0, '2026-10-07 19:11:59'),
(55, 7, 'Banque (coffre)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 point(s), actif', 0, '2026-10-07 19:12:04'),
(56, 7, 'Banque (coffre)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 point(s), actif', 0, '2026-10-07 19:12:11'),
(57, 7, 'Banque (coffre)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 point(s), actif', 0, '2026-10-07 19:12:13'),
(58, 7, 'Banque (coffre)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 point(s), actif', 0, '2026-10-07 19:12:22'),
(59, 7, 'Banque (coffre)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 point(s), actif', 0, '2026-10-07 19:12:31'),
(60, 7, 'Banque (coffre)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 point(s), actif', 0, '2026-10-07 19:12:41'),
(61, 7, 'Banque (coffre)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 point(s), actif', 0, '2026-10-07 19:12:48'),
(62, 7, 'Banque (coffre)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 point(s), actif', 0, '2026-10-07 19:12:56'),
(63, 7, 'Banque (coffre)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'delete', 'Banque (coffre)', 0, '2026-10-07 19:13:17'),
(64, 8, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Supérette (24/7) (store)', 0, '2026-10-07 19:13:21'),
(65, 8, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), désactivé', 0, '2026-10-07 19:13:24'),
(66, 8, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), désactivé', 0, '2026-10-07 19:14:06'),
(67, 8, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-07 19:14:13'),
(68, 8, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-07 19:14:31'),
(69, 8, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-07 19:14:37'),
(70, 8, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-07 19:14:41'),
(71, 8, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-07 19:14:59'),
(72, 8, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-07 19:15:01'),
(73, 8, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-07 19:15:40'),
(74, 8, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-07 19:16:02'),
(75, 8, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-07 19:16:07'),
(76, 8, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-07 19:16:25'),
(77, 8, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-07 19:16:28'),
(78, 8, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 point(s), actif', 0, '2026-10-07 19:17:19'),
(79, 8, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 point(s), actif', 0, '2026-10-07 19:19:02'),
(80, 8, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 point(s), actif', 0, '2026-10-07 19:19:23'),
(81, 8, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 point(s), actif', 0, '2026-10-07 19:19:38'),
(82, 8, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 point(s), actif', 0, '2026-10-07 19:19:49'),
(83, 8, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 point(s), actif', 0, '2026-10-07 19:19:52'),
(84, 8, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 point(s), actif', 0, '2026-10-07 19:19:53'),
(85, 8, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 point(s), actif', 0, '2026-10-07 19:21:37'),
(86, 8, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 point(s), actif', 0, '2026-10-07 19:21:55'),
(87, 8, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'delete', 'Supérette (24/7)', 0, '2026-10-07 19:22:01'),
(88, 9, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Supérette (24/7) (store)', 0, '2026-10-07 19:22:11'),
(89, 9, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), désactivé', 0, '2026-10-07 19:22:29'),
(90, 9, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), désactivé', 0, '2026-10-07 19:22:32'),
(91, 9, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-07 19:22:42'),
(92, 9, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-07 19:23:00'),
(93, 9, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-07 19:23:03'),
(94, 9, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-07 19:23:06'),
(95, 9, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-07 19:23:09'),
(96, 9, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-07 19:23:19'),
(97, 9, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'rob_start', 'Supérette (24/7)', 0, '2026-10-07 19:23:22'),
(98, 9, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'rob_loot', 'Caisse 1 — ', 851, '2026-10-07 19:23:39'),
(99, 9, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'rob_loot', 'Caisse 2 — ', 898, '2026-10-07 19:23:55'),
(100, 9, 'Supérette (24/7)', 'robbery', NULL, 'système', 'rob_end', 'temps écoulé', 0, '2026-10-07 19:26:22'),
(101, 10, 'Blanchiment d\'argent', 'drug', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Blanchiment d\'argent (launder)', 0, '2026-10-07 19:27:47'),
(102, 10, 'Blanchiment d\'argent', 'drug', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 19:28:05'),
(103, 10, 'Blanchiment d\'argent', 'drug', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'launder', '3749 → 2624', 2624, '2026-10-07 19:28:08'),
(104, 10, 'Blanchiment d\'argent', 'drug', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-07 19:28:59'),
(105, 10, 'Blanchiment d\'argent', 'drug', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'process', 'Nouvelle recette ×1 (0 raté)', 1, '2026-10-07 19:29:11'),
(106, 10, 'Blanchiment d\'argent', 'drug', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 19:29:44'),
(107, 10, 'Blanchiment d\'argent', 'drug', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 19:30:37'),
(108, 10, 'Blanchiment d\'argent', 'drug', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 19:30:37'),
(109, 10, 'Blanchiment d\'argent', 'drug', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 19:31:18'),
(110, 10, 'Blanchiment d\'argent', 'drug', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 19:31:21'),
(111, 10, 'Blanchiment d\'argent', 'drug', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-07 19:32:15'),
(112, 10, 'Blanchiment d\'argent', 'drug', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-07 19:32:54'),
(113, 10, 'Blanchiment d\'argent', 'drug', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'delete', 'Blanchiment d\'argent', 0, '2026-10-07 19:33:29'),
(114, 9, 'Supérette (24/7)', 'robbery', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'delete', 'Supérette (24/7)', 0, '2026-10-07 19:34:18'),
(115, 6, 'Station essence', 'fuel', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'delete', 'Station essence', 0, '2026-10-07 19:34:23'),
(116, 11, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Location de voitures (cars)', 0, '2026-10-07 19:35:54'),
(117, 11, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), désactivé', 0, '2026-10-07 19:36:06'),
(118, 11, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), désactivé', 0, '2026-10-07 19:36:51'),
(119, 11, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 19:36:56'),
(120, 11, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'rent', 'sultan (LOC90638)', 1450, '2026-10-07 19:37:05'),
(121, 11, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 19:38:13'),
(122, 11, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 19:38:20'),
(123, 11, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'return', 'LOC90638 — caution rendue 1000/1000', 1000, '2026-10-07 19:38:42'),
(124, 11, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'rent', 'faggio (LOC89395)', 230, '2026-10-07 19:39:21'),
(125, 11, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'return', 'LOC89395 — caution rendue 150/150', 150, '2026-10-07 19:39:27'),
(126, 11, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 19:39:49'),
(127, 11, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 19:39:59'),
(128, 11, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 19:40:02'),
(129, 11, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 19:40:04'),
(130, 11, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 19:40:24'),
(131, 11, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 19:40:32'),
(132, 11, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 19:40:35'),
(133, 11, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 19:40:38'),
(134, 11, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 19:40:40'),
(135, 11, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 19:40:43'),
(136, 11, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 19:40:45'),
(137, 11, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 19:40:48'),
(138, 11, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 19:40:50'),
(139, 11, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 19:40:52'),
(140, 12, 'Agence bancaire', 'bank', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Agence bancaire (branch)', 0, '2026-10-07 19:44:29'),
(141, 12, 'Agence bancaire', 'bank', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-07 19:44:36'),
(142, 12, 'Agence bancaire', 'bank', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-07 19:46:03'),
(143, 12, 'Agence bancaire', 'bank', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'deposit', 'frais 0', 100, '2026-10-07 19:49:11'),
(144, 12, 'Agence bancaire', 'bank', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'deposit', 'frais 0', 57929, '2026-10-07 19:49:22'),
(145, 12, 'Agence bancaire', 'bank', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'deposit', 'frais 0', 949809, '2026-10-07 19:49:26'),
(146, 13, 'Fourrière', 'impound', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Fourrière (impound)', 0, '2026-10-07 19:50:40'),
(147, 13, 'Fourrière', 'impound', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), désactivé', 0, '2026-10-07 19:50:42'),
(148, 13, 'Fourrière', 'impound', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 19:50:44'),
(149, 13, 'Fourrière', 'impound', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 19:51:03'),
(150, 13, 'Fourrière', 'impound', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'release', '95VSW571', 500, '2026-10-07 19:51:09'),
(151, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'store', '95VSW571', 0, '2026-10-07 19:51:25'),
(152, 14, 'Auto-école', 'driving', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Auto-école (school)', 0, '2026-10-07 19:56:39'),
(153, 16, 'Auto-école vide', 'driving', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Auto-école vide (custom)', 0, '2026-10-07 19:56:39'),
(154, 17, 'Agence bancaire', 'bank', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Agence bancaire (branch)', 0, '2026-10-07 19:56:39'),
(155, 14, 'Auto-école', 'driving', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'delete', 'Auto-école', 0, '2026-10-07 19:56:43'),
(156, 16, 'Auto-école vide', 'driving', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'delete', 'Auto-école vide', 0, '2026-10-07 19:56:46'),
(157, 17, 'Agence bancaire', 'bank', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'delete', 'Agence bancaire', 0, '2026-10-07 19:56:48'),
(158, 19, 'Auto-école', 'driving', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Auto-école (school)', 0, '2026-10-07 19:56:52'),
(159, 19, 'Auto-école', 'driving', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 point(s), désactivé', 0, '2026-10-07 19:56:58'),
(160, 19, 'Auto-école', 'driving', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 point(s), actif', 0, '2026-10-07 19:57:02'),
(161, 19, 'Auto-école', 'driving', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'theory', 'dmv : 9/10 (réussi)', 0, '2026-10-07 19:58:15'),
(162, 19, 'Auto-école', 'driving', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 point(s), actif', 0, '2026-10-07 19:59:00'),
(163, 19, 'Auto-école', 'driving', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 point(s), actif', 0, '2026-10-07 19:59:19'),
(164, 19, 'Auto-école', 'driving', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 point(s), actif', 0, '2026-10-07 19:59:33'),
(165, 19, 'Auto-école', 'driving', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 point(s), actif', 0, '2026-10-07 19:59:50'),
(166, 19, 'Auto-école', 'driving', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '6 point(s), actif', 0, '2026-10-07 20:00:11'),
(167, 19, 'Auto-école', 'driving', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'practical', 'drive : 3 faute(s) (réussi)', 0, '2026-10-07 20:03:03'),
(168, 13, 'Fourrière', 'impound', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'delete', 'Fourrière', 0, '2026-10-07 20:03:55'),
(169, 12, 'Agence bancaire', 'bank', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'delete', 'Agence bancaire', 0, '2026-10-07 20:03:58'),
(170, 19, 'Auto-école', 'driving', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'delete', 'Auto-école', 0, '2026-10-07 20:04:01'),
(171, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 20:04:03'),
(172, 20, 'Station de lavage', 'carwash', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Station de lavage (station)', 0, '2026-10-07 20:10:33'),
(173, 20, 'Station de lavage', 'carwash', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-07 20:10:38'),
(174, 20, 'Station de lavage', 'carwash', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'wash', 'Lavage premium', 120, '2026-10-07 20:11:28'),
(175, 20, 'Station de lavage', 'carwash', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'delete', 'Station de lavage', 0, '2026-10-07 20:11:41'),
(176, 21, 'Serrurier', 'locksmith', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Serrurier (shop)', 0, '2026-10-07 20:17:35'),
(177, 21, 'Serrurier', 'locksmith', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), désactivé', 0, '2026-10-07 20:17:36'),
(178, 21, 'Serrurier', 'locksmith', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 20:17:39'),
(179, 21, 'Serrurier', 'locksmith', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 20:18:01'),
(180, 21, 'Serrurier', 'locksmith', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 20:18:49'),
(181, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'take', '95VSW571', 0, '2026-10-07 20:19:00'),
(182, 21, 'Serrurier', 'locksmith', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'key', '95VSW571', 250, '2026-10-07 20:19:12'),
(183, 21, 'Serrurier', 'locksmith', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 20:19:51'),
(184, 21, 'Serrurier', 'locksmith', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-07 20:20:06'),
(185, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'store', '95VSW571', 0, '2026-10-07 20:20:29'),
(186, 22, 'Parking d\'occasion', 'carlot', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Parking d\'occasion (lot)', 0, '2026-10-07 20:31:18'),
(187, 22, 'Parking d\'occasion', 'carlot', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '5 point(s), actif', 0, '2026-10-07 20:31:26'),
(188, 22, 'Parking d\'occasion', 'carlot', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '5 point(s), actif', 0, '2026-10-07 20:32:16'),
(189, 22, 'Parking d\'occasion', 'carlot', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'list', '95VSW571 à 5000', 5000, '2026-10-07 20:32:31'),
(190, 22, 'Parking d\'occasion', 'carlot', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'cancel', '95VSW571', 0, '2026-10-07 20:32:48'),
(191, 23, 'Course poursuite', 'chase', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Course poursuite (course)', 0, '2026-10-07 20:42:06'),
(192, 23, 'Course poursuite', 'chase', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), désactivé', 0, '2026-10-07 20:42:54'),
(193, 23, 'Course poursuite', 'chase', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-07 20:42:56'),
(194, 23, 'Course poursuite', 'chase', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-07 20:43:04'),
(195, 23, 'Course poursuite', 'chase', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'delete', 'Course poursuite', 0, '2026-10-07 20:53:29'),
(196, 24, 'Zones PVP', 'pvp', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Zones PVP (arena)', 0, '2026-10-07 20:53:44'),
(197, 24, 'Zones PVP', 'pvp', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), désactivé', 0, '2026-10-07 20:54:01'),
(198, 24, 'Zones PVP', 'pvp', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), désactivé', 0, '2026-10-07 20:54:09'),
(199, 24, 'Zones PVP', 'pvp', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), désactivé', 0, '2026-10-07 20:54:14'),
(200, 24, 'Zones PVP', 'pvp', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), désactivé', 0, '2026-10-07 20:54:23'),
(201, 24, 'Zones PVP', 'pvp', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-07 20:54:26'),
(202, 24, 'Zones PVP', 'pvp', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-07 20:54:35'),
(203, 24, 'Zones PVP', 'pvp', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-07 20:54:51'),
(204, 24, 'Zones PVP', 'pvp', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-07 20:54:57'),
(205, 24, 'Zones PVP', 'pvp', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-10 16:46:03'),
(206, 24, 'Zones PVP', 'pvp', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-10 16:48:27'),
(207, 24, 'Zones PVP', 'pvp', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-10 16:48:45'),
(208, 24, 'Zones PVP', 'pvp', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-10 16:50:34'),
(209, 24, 'Zones PVP', 'pvp', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-10 16:50:38'),
(210, 24, 'Zones PVP', 'pvp', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-10 16:50:46'),
(211, 24, 'Zones PVP', 'pvp', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-10 16:51:31'),
(212, 24, 'Zones PVP', 'pvp', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-10 16:51:39'),
(213, 24, 'Zones PVP', 'pvp', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-10 16:51:40'),
(214, 24, 'Zones PVP', 'pvp', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-10 16:51:54'),
(215, 24, 'Zones PVP', 'pvp', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-10 16:51:57'),
(216, 24, 'Zones PVP', 'pvp', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-10 16:52:23'),
(217, 24, 'Zones PVP', 'pvp', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-10 16:52:39'),
(218, 24, 'Zones PVP', 'pvp', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-10 16:53:28'),
(219, 24, 'Zones PVP', 'pvp', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-10 16:53:47'),
(220, 24, 'Zones PVP', 'pvp', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-10 16:54:13'),
(221, 24, 'Zones PVP', 'pvp', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-10 16:55:48'),
(222, 25, 'Course poursuite', 'chase', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Course poursuite (course)', 0, '2026-10-10 16:56:24'),
(223, 25, 'Course poursuite', 'chase', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), désactivé', 0, '2026-10-10 16:56:41'),
(224, 25, 'Course poursuite', 'chase', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), désactivé', 0, '2026-10-10 16:56:58'),
(225, 25, 'Course poursuite', 'chase', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-10 16:57:00'),
(226, 25, 'Course poursuite', 'chase', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-10 16:57:24'),
(227, 25, 'Course poursuite', 'chase', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-10 16:58:06'),
(228, 24, 'Zones PVP', 'pvp', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-10 16:58:17'),
(229, 25, 'Course poursuite', 'chase', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-10 16:58:20'),
(230, 22, 'Parking d\'occasion', 'carlot', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'delete', 'Parking d\'occasion', 0, '2026-10-10 17:00:46'),
(231, 21, 'Serrurier', 'locksmith', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-10 17:01:16'),
(232, 21, 'Serrurier', 'locksmith', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-10 17:01:21'),
(233, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'take', '95VSW571', 0, '2026-10-10 17:02:19'),
(234, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'store', '95VSW571', 0, '2026-10-10 17:02:23'),
(235, 26, 'Station essence', 'fuel', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Station essence (station)', 0, '2026-10-10 17:02:39'),
(236, 26, 'Station essence', 'fuel', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), désactivé', 0, '2026-10-10 17:02:48'),
(237, 26, 'Station essence', 'fuel', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-10 17:02:52'),
(238, 26, 'Station essence', 'fuel', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-10 17:02:54'),
(239, 26, 'Station essence', 'fuel', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-10 17:03:13'),
(240, 26, 'Station essence', 'fuel', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-10 17:03:41'),
(241, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'take', '04EAP598', 0, '2026-10-10 20:51:14'),
(242, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'store', '04EAP598', 0, '2026-10-10 20:51:18'),
(243, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'take', '95VSW571', 0, '2026-10-10 20:55:50'),
(244, 21, 'Serrurier', 'locksmith', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'key', '95VSW571', 250, '2026-10-10 20:57:17'),
(245, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'store', '95VSW571', 0, '2026-10-10 20:57:48'),
(246, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'take', '77PHJ349', 0, '2026-10-10 20:58:05'),
(247, 27, 'Agence bancaire', 'bank', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Agence bancaire (branch)', 0, '2026-10-10 20:58:56'),
(248, 27, 'Agence bancaire', 'bank', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), désactivé', 0, '2026-10-10 20:59:02'),
(249, 27, 'Agence bancaire', 'bank', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), désactivé', 0, '2026-10-10 20:59:24'),
(250, 27, 'Agence bancaire', 'bank', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), désactivé', 0, '2026-10-10 20:59:27'),
(251, 27, 'Agence bancaire', 'bank', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-10 20:59:37'),
(252, 27, 'Agence bancaire', 'bank', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'withdraw', 'frais 0', 100, '2026-10-10 20:59:43'),
(253, 27, 'Agence bancaire', 'bank', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'deposit', 'frais 0', 100, '2026-10-10 20:59:44'),
(254, 27, 'Agence bancaire', 'bank', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-10 21:00:03'),
(255, 27, 'Agence bancaire', 'bank', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-10 21:00:27'),
(256, 27, 'Agence bancaire', 'bank', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-10 21:06:08'),
(257, 27, 'Agence bancaire', 'bank', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-10 21:06:43'),
(258, 27, 'Agence bancaire', 'bank', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-10 21:07:04'),
(259, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'store', '77PHJ349', 0, '2026-10-10 21:07:46'),
(260, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'take', '77PHJ349', 0, '2026-10-10 21:18:43'),
(261, 21, 'Serrurier', 'locksmith', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'key', '77PHJ349', 250, '2026-10-10 21:18:54'),
(262, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'take', '04EAP598', 0, '2026-10-10 21:21:52'),
(263, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'store', '04EAP598', 0, '2026-10-10 21:21:55'),
(264, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'take', '04EAP598', 0, '2026-10-10 21:22:05'),
(265, 21, 'Serrurier', 'locksmith', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'key', '04EAP598', 250, '2026-10-10 21:22:17'),
(266, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'store', '04EAP598', 0, '2026-10-10 21:22:39'),
(267, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'take', '95VSW571', 0, '2026-10-10 21:22:49'),
(268, 28, 'Fourrière', 'impound', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Fourrière (impound)', 0, '2026-10-10 21:28:28'),
(269, 28, 'Fourrière', 'impound', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), désactivé', 0, '2026-10-10 21:28:29'),
(270, 28, 'Fourrière', 'impound', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-10 21:28:33'),
(271, 28, 'Fourrière', 'impound', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-10 21:28:35'),
(272, 28, 'Fourrière', 'impound', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-10 21:36:21'),
(273, 28, 'Fourrière', 'impound', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'release', '77PHJ349', 500, '2026-10-10 21:36:26'),
(274, 21, 'Serrurier', 'locksmith', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'key', '77PHJ349', 250, '2026-10-10 21:36:37'),
(275, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'store', '77PHJ349', 0, '2026-10-10 21:37:02'),
(276, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'take', '77PHJ349', 0, '2026-10-10 21:38:22'),
(277, 28, 'Fourrière', 'impound', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'delete', 'Fourrière', 0, '2026-10-10 21:58:42'),
(278, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'take', '04EAP598', 0, '2026-10-11 10:13:48'),
(279, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'store', '04EAP598', 0, '2026-10-11 10:13:52'),
(280, 29, 'Fourrière', 'impound', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Fourrière (impound)', 0, '2026-10-11 10:15:49'),
(281, 29, 'Fourrière', 'impound', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), désactivé', 0, '2026-10-11 10:15:50'),
(282, 29, 'Fourrière', 'impound', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), désactivé', 0, '2026-10-11 10:16:00'),
(283, 29, 'Fourrière', 'impound', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), désactivé', 0, '2026-10-11 10:16:10'),
(284, 29, 'Fourrière', 'impound', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-11 10:16:13'),
(285, 29, 'Fourrière', 'impound', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-11 10:16:40'),
(286, 29, 'Fourrière', 'impound', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'release', '95VSW571', 500, '2026-10-11 10:16:45'),
(287, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'store', '95VSW571', 0, '2026-10-11 10:17:33'),
(288, 29, 'Fourrière', 'impound', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'release', '77PHJ349', 500, '2026-10-11 10:18:02'),
(289, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'store', '77PHJ349', 0, '2026-10-11 10:18:33'),
(290, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'take', '77PHJ349', 0, '2026-10-11 10:26:59'),
(291, 25, 'Course poursuite', 'chase', NULL, 'système', 'chase_end', 'Pickaxxx — chasers', 0, '2026-10-11 10:31:28'),
(292, 25, 'Course poursuite', 'chase', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-11 10:32:07'),
(293, 25, 'Course poursuite', 'chase', NULL, 'système', 'chase_end', 'Course de Maly Pablo — runner', 0, '2026-10-11 10:34:47'),
(294, 25, 'Course poursuite', 'chase', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-11 10:35:21'),
(295, 25, 'Course poursuite', 'chase', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-11 10:35:41'),
(296, 25, 'Course poursuite', 'chase', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-11 10:35:49'),
(297, 25, 'Course poursuite', 'chase', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-11 10:35:54'),
(298, 25, 'Course poursuite', 'chase', NULL, 'système', 'chase_end', 'Course de MOUNIR PABLO — chasers', 0, '2026-10-11 10:38:38'),
(299, 25, 'Course poursuite', 'chase', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-11 10:39:20'),
(300, 25, 'Course poursuite', 'chase', NULL, 'système', 'chase_end', 'Course de MOUNIR PABLO — chasers', 0, '2026-10-11 10:43:06'),
(301, 24, 'Zones PVP', 'pvp', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-11 12:22:25'),
(302, 24, 'Zones PVP', 'pvp', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-11 12:23:03'),
(303, 29, 'Fourrière', 'impound', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-11 14:59:32'),
(304, 29, 'Fourrière', 'impound', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-11 15:00:21'),
(305, 27, 'Agence bancaire', 'bank', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-11 15:00:33'),
(306, 29, 'Fourrière', 'impound', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-11 15:00:56'),
(307, 29, 'Fourrière', 'impound', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'release', '77PHJ349', 500, '2026-10-11 15:01:08'),
(308, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'store', '77PHJ349', 0, '2026-10-11 15:01:37'),
(309, 30, 'Garage public', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Garage public (public)', 0, '2026-10-11 15:03:03'),
(310, 30, 'Garage public', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), désactivé', 0, '2026-10-11 15:03:35'),
(311, 30, 'Garage public', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-11 15:03:38'),
(312, 3, 'Garage', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'delete', 'Garage', 0, '2026-10-11 15:04:19'),
(313, 30, 'Garage public', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-11 15:04:20'),
(314, 30, 'Garage public', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-11 15:04:44'),
(315, 30, 'Garage public', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'take', '04EAP598', 0, '2026-10-11 15:04:52'),
(316, 30, 'Garage public', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-11 15:05:29'),
(317, 30, 'Garage public', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'store', '04EAP598', 0, '2026-10-11 15:05:32'),
(318, 30, 'Garage public', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'take', '95VSW571', 0, '2026-10-11 15:05:36'),
(319, 30, 'Garage public', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'store', '95VSW571', 0, '2026-10-11 15:05:45'),
(320, 30, 'Garage public', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'take', '95VSW571', 0, '2026-10-11 17:46:45');
INSERT INTO `worldbuilder_logs` (`id`, `entity_id`, `entity_label`, `type`, `identifier`, `player_name`, `action`, `detail`, `amount`, `created_at`) VALUES
(321, 30, 'Garage public', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'store', '95VSW571', 0, '2026-10-11 17:46:51'),
(322, 30, 'Garage public', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'take', '95VSW571', 0, '2026-10-11 17:46:57'),
(323, 31, 'Garage public (copie)', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'duplicate', 'copie de Garage public', 0, '2026-10-11 17:47:48'),
(324, 31, 'Garage public (copie)', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), désactivé', 0, '2026-10-11 17:48:25'),
(325, 31, 'Garage public (copie)', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-11 17:48:28'),
(326, 31, 'Garage public (copie)', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'store', '95VSW571', 0, '2026-10-11 17:48:40'),
(327, 31, 'Garage public (copie)', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'take', '95VSW571', 0, '2026-10-11 17:48:44'),
(328, 31, 'Garage public (copie)', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'store', '95VSW571', 0, '2026-10-11 17:48:50'),
(329, 30, 'Garage public', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-11 17:49:48'),
(330, 31, 'Garage public (copie)', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-11 17:49:52'),
(331, 31, 'Garage public (copie)', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'take', '77PHJ349', 0, '2026-10-11 21:50:17'),
(332, 31, 'Garage public (copie)', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'store', '77PHJ349', 0, '2026-10-11 21:50:25'),
(333, 32, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'bennys (job)', 0, '2026-10-11 21:56:13'),
(334, 32, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), désactivé', 0, '2026-10-11 21:56:24'),
(335, 32, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '2 point(s), actif', 0, '2026-10-11 21:56:28'),
(336, 32, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-11 21:57:13'),
(337, 32, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-11 21:57:33'),
(338, 32, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-11 21:57:51'),
(339, 32, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-11 21:58:09'),
(340, 32, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'unlock', 'Porte d\'entrée', 0, '2026-10-11 21:58:11'),
(341, 32, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'lock', 'Porte d\'entrée', 0, '2026-10-11 21:58:12'),
(342, 32, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-11 21:58:27'),
(343, 32, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-11 21:58:45'),
(344, 32, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'unlock', 'Porte d\'entrée', 0, '2026-10-11 21:58:48'),
(345, 32, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'lock', 'Porte d\'entrée', 0, '2026-10-11 21:58:50'),
(346, 32, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'unlock', 'Porte d\'entrée', 0, '2026-10-11 21:58:56'),
(347, 32, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'lock', 'Porte d\'entrée', 0, '2026-10-11 21:58:58'),
(348, 32, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-11 21:59:29'),
(349, 32, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-11 21:59:42'),
(350, 32, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-11 21:59:46'),
(351, 32, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'unlock', 'Porte d\'entrée', 0, '2026-10-11 21:59:50'),
(352, 32, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'lock', 'Porte d\'entrée', 0, '2026-10-11 21:59:51'),
(353, 32, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-11 22:00:06'),
(354, 32, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'unlock', 'Porte d\'entrée', 0, '2026-10-11 22:00:08'),
(355, 32, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'lock', 'Porte d\'entrée', 0, '2026-10-11 22:00:10'),
(356, 32, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-11 22:00:47'),
(357, 32, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'unlock', 'Porte d\'entrée', 0, '2026-10-11 22:00:56'),
(358, 32, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'lock', 'Porte d\'entrée', 0, '2026-10-11 22:00:59'),
(359, 32, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'unlock', 'Porte d\'entrée', 0, '2026-10-11 22:01:00'),
(360, 32, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-11 22:01:19'),
(361, 32, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'unlock', 'Porte d\'entrée', 0, '2026-10-11 22:01:21'),
(362, 32, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'lock', 'Porte d\'entrée', 0, '2026-10-11 22:01:25'),
(363, 32, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'unlock', 'Porte d\'entrée', 0, '2026-10-11 22:16:38'),
(364, 32, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'unlock', 'Porte d\'entrée', 0, '2026-10-12 12:24:48'),
(365, 33, 'Portes de métier (ex : commissariat)', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'Portes de métier (ex : commissariat) (job)', 0, '2026-10-12 12:25:46'),
(366, 33, 'Portes de métier (ex : commissariat)', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'delete', 'Portes de métier (ex : commissariat)', 0, '2026-10-12 12:26:04'),
(367, 32, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'delete', 'bennys', 0, '2026-10-12 12:26:07'),
(368, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'bennys (job)', 0, '2026-10-12 12:26:39'),
(369, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), désactivé', 0, '2026-10-12 12:26:59'),
(370, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-12 12:27:14'),
(371, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-12 12:27:15'),
(372, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-12 12:27:35'),
(373, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-12 12:27:40'),
(374, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'unlock', 'Porte d\'entrée', 0, '2026-10-12 12:27:42'),
(375, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'lock', 'Porte d\'entrée', 0, '2026-10-12 12:27:43'),
(376, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'unlock', 'Porte d\'entrée', 0, '2026-10-12 12:27:53'),
(377, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'lock', 'Porte d\'entrée', 0, '2026-10-12 12:27:57'),
(378, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'unlock', 'Porte d\'entrée', 0, '2026-10-12 12:28:43'),
(379, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'lock', 'Porte d\'entrée', 0, '2026-10-12 12:28:44'),
(380, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'unlock', 'Porte d\'entrée', 0, '2026-10-12 12:28:45'),
(381, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'lock', 'Porte d\'entrée', 0, '2026-10-12 12:28:46'),
(382, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-12 12:34:41'),
(383, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'unlock', 'Porte d\'entrée', 0, '2026-10-12 12:34:47'),
(384, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'lock', 'Porte d\'entrée', 0, '2026-10-12 12:34:48'),
(385, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'unlock', 'Porte d\'entrée', 0, '2026-10-12 12:34:52'),
(386, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'lock', 'Porte d\'entrée', 0, '2026-10-12 12:34:55'),
(387, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'unlock', 'Porte d\'entrée', 0, '2026-10-12 12:34:56'),
(388, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'lock', 'Porte d\'entrée', 0, '2026-10-12 12:34:57'),
(389, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'unlock', 'Porte d\'entrée', 0, '2026-10-12 12:35:40'),
(390, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'lock', 'Porte d\'entrée', 0, '2026-10-12 12:35:40'),
(391, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'unlock', 'Porte d\'entrée', 0, '2026-10-12 12:36:17'),
(392, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'lock', 'Porte d\'entrée', 0, '2026-10-12 12:36:17'),
(393, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'unlock', 'Porte d\'entrée', 0, '2026-10-12 12:36:19'),
(394, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'lock', 'Porte d\'entrée', 0, '2026-10-12 12:36:20'),
(395, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'unlock', 'Porte d\'entrée', 0, '2026-10-12 12:36:23'),
(396, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'lock', 'Porte d\'entrée', 0, '2026-10-12 12:36:24'),
(397, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-12 12:37:06'),
(398, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-12 12:37:22'),
(399, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-12 12:37:55'),
(400, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-12 12:37:58'),
(401, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'unlock', 'Porte d\'entrée', 0, '2026-10-12 12:38:00'),
(402, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'lock', 'Porte d\'entrée', 0, '2026-10-12 12:38:01'),
(403, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-12 12:38:12'),
(404, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'unlock', 'Porte d\'entrée', 0, '2026-10-12 12:38:15'),
(405, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'lock', 'Porte d\'entrée', 0, '2026-10-12 12:38:16'),
(406, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-12 12:38:42'),
(407, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'unlock', 'Porte d\'entrée', 0, '2026-10-12 12:38:45'),
(408, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'lock', 'Porte d\'entrée', 0, '2026-10-12 12:38:45'),
(409, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'unlock', 'Porte d\'entrée', 0, '2026-10-12 12:40:17'),
(410, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'lock', 'Porte d\'entrée', 0, '2026-10-12 12:40:18'),
(411, 34, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'delete', 'bennys', 0, '2026-10-12 12:40:25'),
(412, 35, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'bennys (job)', 0, '2026-10-12 12:40:35'),
(413, 35, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), désactivé', 0, '2026-10-12 12:40:53'),
(414, 35, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), désactivé', 0, '2026-10-12 12:40:57'),
(415, 35, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-12 12:41:06'),
(416, 35, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-12 12:41:45'),
(417, 35, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-12 12:42:03'),
(418, 35, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-12 12:42:12'),
(419, 35, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-12 12:42:38'),
(420, 35, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'unlock', 'Porte d\'entrée', 0, '2026-10-12 12:42:43'),
(421, 35, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'lock', 'Porte d\'entrée', 0, '2026-10-12 12:42:44'),
(422, 35, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'delete', 'bennys', 0, '2026-10-12 12:46:33'),
(423, 36, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'bennys (job)', 0, '2026-10-12 12:46:41'),
(424, 36, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), désactivé', 0, '2026-10-12 12:47:00'),
(425, 36, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-12 12:47:10'),
(426, 36, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'unlock', 'Porte d\'entrée', 0, '2026-10-12 12:47:13'),
(427, 36, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'lock', 'Porte d\'entrée', 0, '2026-10-12 12:47:14'),
(428, 36, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'delete', 'bennys', 0, '2026-10-12 12:48:02'),
(429, 37, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'create', 'bennys (job)', 0, '2026-10-12 12:48:43'),
(430, 37, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), désactivé', 0, '2026-10-12 12:48:52'),
(431, 37, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), désactivé', 0, '2026-10-12 12:48:57'),
(432, 37, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), désactivé', 0, '2026-10-12 12:48:59'),
(433, 37, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-12 12:49:11'),
(434, 37, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'unlock', 'Porte d\'entrée', 0, '2026-10-12 12:49:16'),
(435, 37, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'lock', 'Porte d\'entrée', 0, '2026-10-12 12:49:17'),
(436, 37, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'unlock', 'Porte d\'entrée', 0, '2026-10-12 12:50:53'),
(437, 37, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'lock', 'Porte d\'entrée', 0, '2026-10-12 12:50:54'),
(438, 37, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'unlock', 'Porte d\'entrée', 0, '2026-10-12 12:51:08'),
(439, 37, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'lock', 'Porte d\'entrée', 0, '2026-10-12 12:51:09'),
(440, 37, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'unlock', 'Porte d\'entrée', 0, '2026-10-12 12:51:18'),
(441, 37, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'lock', 'Porte d\'entrée', 0, '2026-10-12 12:51:18'),
(442, 37, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'unlock', 'Porte d\'entrée', 0, '2026-10-12 12:52:18'),
(443, 37, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'lock', 'Porte d\'entrée', 0, '2026-10-12 12:52:19'),
(444, 37, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-12 12:52:55'),
(445, 37, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'unlock', 'Porte d\'entrée', 0, '2026-10-12 12:52:56'),
(446, 37, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'lock', 'Porte d\'entrée', 0, '2026-10-12 12:52:57'),
(447, 37, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-12 12:54:27'),
(448, 37, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'unlock', 'Porte d\'entrée', 0, '2026-10-12 12:54:48'),
(449, 37, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'lock', 'Porte d\'entrée', 0, '2026-10-12 12:54:49'),
(450, 37, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'unlock', 'Porte d\'entrée', 0, '2026-10-12 12:54:50'),
(451, 37, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'lock', 'Porte d\'entrée', 0, '2026-10-12 12:54:51'),
(452, 37, 'bennys', 'doorlock', 'license:17015558e9d71c65e5de4c4c417d582ba4f005f1', 'MOUNIR PABLO', 'unlock', 'Porte d\'entrée', 0, '2026-10-12 12:54:56'),
(453, 37, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-12 12:55:03'),
(454, 37, 'bennys', 'doorlock', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '1 point(s), actif', 0, '2026-10-12 12:55:22'),
(455, 25, 'Course poursuite', 'chase', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-12 12:58:06'),
(456, 25, 'Course poursuite', 'chase', NULL, 'système', 'chase_end', 'Course de Maly Pablo — chasers', 0, '2026-10-12 12:58:07'),
(457, 25, 'Course poursuite', 'chase', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-12 12:58:30'),
(458, 25, 'Course poursuite', 'chase', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-12 12:58:42'),
(459, 25, 'Course poursuite', 'chase', NULL, 'système', 'chase_end', 'Course de Maly Pablo — runner', 0, '2026-10-12 13:01:04'),
(460, 25, 'Course poursuite', 'chase', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-12 13:02:43'),
(461, 25, 'Course poursuite', 'chase', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-12 13:02:55'),
(462, 25, 'Course poursuite', 'chase', NULL, 'système', 'chase_end', 'Course de MOUNIR PABLO — chasers', 0, '2026-10-12 13:03:33'),
(463, 25, 'Course poursuite', 'chase', NULL, 'système', 'chase_end', 'Course de Maly Pablo — runner', 0, '2026-10-12 13:05:55'),
(464, 25, 'Course poursuite', 'chase', NULL, 'système', 'chase_end', 'Course de Maly Pablo — runner', 0, '2026-10-12 13:08:24'),
(465, 25, 'Course poursuite', 'chase', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-12 13:08:44'),
(466, 25, 'Course poursuite', 'chase', NULL, 'système', 'chase_end', 'Course de Maly Pablo — runner', 0, '2026-10-12 13:11:07'),
(467, 25, 'Course poursuite', 'chase', NULL, 'système', 'chase_end', 'Course de MOUNIR PABLO — runner', 0, '2026-10-12 13:14:26'),
(468, 25, 'Course poursuite', 'chase', NULL, 'système', 'chase_end', 'qzdzqd — runner', 0, '2026-10-12 13:33:02'),
(469, 25, 'Course poursuite', 'chase', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-12 13:33:45'),
(470, 25, 'Course poursuite', 'chase', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-12 13:39:10'),
(471, 25, 'Course poursuite', 'chase', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-12 13:39:33'),
(472, 25, 'Course poursuite', 'chase', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-12 13:40:20'),
(473, 25, 'Course poursuite', 'chase', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-12 13:41:49'),
(474, 25, 'Course poursuite', 'chase', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'save', '4 point(s), actif', 0, '2026-10-12 13:42:12'),
(475, 11, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'rent', 'faggio (LOC58445)', 230, '2026-10-13 18:26:47'),
(476, 11, 'Location de voitures', 'rental', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'return', 'LOC58445 — caution rendue 150/150', 150, '2026-10-13 18:26:53'),
(477, 31, 'Garage public (copie)', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'take', '95VSW571', 0, '2026-10-13 18:27:42'),
(478, 26, 'Station essence', 'fuel', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'fuel', '26 L', 78, '2026-10-13 18:28:39'),
(479, 31, 'Garage public (copie)', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'store', '95VSW571', 0, '2026-10-13 18:31:54'),
(480, 31, 'Garage public (copie)', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'take', '77PHJ349', 0, '2026-10-13 18:31:59'),
(481, 31, 'Garage public (copie)', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'store', '77PHJ349', 0, '2026-10-13 18:32:53'),
(482, 37, 'bennys', 'doorlock', 'license:3afb15e367e2e7c2a142ecc8760f66805116c992', 'jUNE GUEVARO', 'unlock', 'Porte d\'entrée', 0, '2026-10-13 19:22:13'),
(483, 31, 'Garage public (copie)', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'take', '77PHJ349', 0, '2026-10-13 20:02:57'),
(484, 31, 'Garage public (copie)', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'store', '77PHJ349', 0, '2026-10-13 20:04:11'),
(485, 31, 'Garage public (copie)', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'take', '04EAP598', 0, '2026-10-13 20:10:12'),
(486, 31, 'Garage public (copie)', 'garage', 'license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 'store', '04EAP598', 0, '2026-10-13 20:10:18');

-- --------------------------------------------------------

--
-- Table structure for table `worldbuilder_parking`
--

CREATE TABLE `worldbuilder_parking` (
  `plate` varchar(12) NOT NULL,
  `entity_id` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `worldbuilder_payouts`
--

CREATE TABLE `worldbuilder_payouts` (
  `id` int(11) NOT NULL,
  `identifier` varchar(80) NOT NULL,
  `amount` int(11) NOT NULL DEFAULT 0,
  `note` varchar(200) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `worldbuilder_pvp_stats`
--

INSERT INTO `worldbuilder_pvp_stats` (`identifier`, `name`, `kills`, `deaths`, `best_streak`) VALUES
('license:0155311d5350cbfe73f6d33c117fd0b8675be1e8', 'Maly Pablo', 0, 27, 0),
('license:17015558e9d71c65e5de4c4c417d582ba4f005f1', 'MOUNIR PABLO', 2, 0, 2);

-- --------------------------------------------------------

--
-- Table structure for table `worldbuilder_settings`
--

CREATE TABLE `worldbuilder_settings` (
  `k` varchar(50) NOT NULL,
  `v` longtext DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `worldbuilder_settings`
--

INSERT INTO `worldbuilder_settings` (`k`, `v`) VALUES
('accent', '[59,130,246]');

-- --------------------------------------------------------

--
-- Table structure for table `worldbuilder_state`
--

CREATE TABLE `worldbuilder_state` (
  `k` varchar(80) NOT NULL,
  `v` bigint(20) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `worldbuilder_state`
--

INSERT INTO `worldbuilder_state` (`k`, `v`) VALUES
('drvt:license:0155311d5350cbfe73f6d33c117fd0b8675be1e8:19:dmv', 1),
('rob:9', 1791402382);

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
  MODIFY `account_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `addon_account_data`
--
ALTER TABLE `addon_account_data`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2285;

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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `boitegant`
--
ALTER TABLE `boitegant`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `clothes_player`
--
ALTER TABLE `clothes_player`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `coffre_armeperm`
--
ALTER TABLE `coffre_armeperm`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `datastore_data`
--
ALTER TABLE `datastore_data`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2554;

--
-- AUTO_INCREMENT for table `gangbuilder_logs`
--
ALTER TABLE `gangbuilder_logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=89;

--
-- AUTO_INCREMENT for table `gangbuilder_points`
--
ALTER TABLE `gangbuilder_points`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- AUTO_INCREMENT for table `gangbuilder_territories`
--
ALTER TABLE `gangbuilder_territories`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `job2_grades`
--
ALTER TABLE `job2_grades`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=313;

--
-- AUTO_INCREMENT for table `jobbuilder_announces`
--
ALTER TABLE `jobbuilder_announces`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `jobbuilder_bank_clients`
--
ALTER TABLE `jobbuilder_bank_clients`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `jobbuilder_bank_entries`
--
ALTER TABLE `jobbuilder_bank_entries`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `jobbuilder_bank_loans`
--
ALTER TABLE `jobbuilder_bank_loans`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=226;

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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `jobbuilder_record_entries`
--
ALTER TABLE `jobbuilder_record_entries`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `jobbuilder_treasury_log`
--
ALTER TABLE `jobbuilder_treasury_log`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `job_grades`
--
ALTER TABLE `job_grades`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18263;

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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `owned_properties`
--
ALTER TABLE `owned_properties`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `p_outfits`
--
ALTER TABLE `p_outfits`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `shopbuilder_logs`
--
ALTER TABLE `shopbuilder_logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=131;

--
-- AUTO_INCREMENT for table `shopbuilder_shops`
--
ALTER TABLE `shopbuilder_shops`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `society`
--
ALTER TABLE `society`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `boutique_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=38;

--
-- AUTO_INCREMENT for table `user_licenses`
--
ALTER TABLE `user_licenses`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `worldbuilder_entities`
--
ALTER TABLE `worldbuilder_entities`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=38;

--
-- AUTO_INCREMENT for table `worldbuilder_listings`
--
ALTER TABLE `worldbuilder_listings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `worldbuilder_logs`
--
ALTER TABLE `worldbuilder_logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=487;

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
  ADD CONSTRAINT `fk_jobbuilder_bank_entries_c` FOREIGN KEY (`client_id`) REFERENCES `jobbuilder_bank_clients` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `jobbuilder_bank_loans`
--
ALTER TABLE `jobbuilder_bank_loans`
  ADD CONSTRAINT `fk_jobbuilder_bank_loans_c` FOREIGN KEY (`client_id`) REFERENCES `jobbuilder_bank_clients` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `jobbuilder_patient_entries`
--
ALTER TABLE `jobbuilder_patient_entries`
  ADD CONSTRAINT `fk_jobbuilder_patient_entries_p` FOREIGN KEY (`patient_id`) REFERENCES `jobbuilder_patients` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `jobbuilder_property_points`
--
ALTER TABLE `jobbuilder_property_points`
  ADD CONSTRAINT `fk_jobbuilder_property_points` FOREIGN KEY (`property_id`) REFERENCES `jobbuilder_properties` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `jobbuilder_record_entries`
--
ALTER TABLE `jobbuilder_record_entries`
  ADD CONSTRAINT `fk_jobbuilder_record_entries_rec` FOREIGN KEY (`record_id`) REFERENCES `jobbuilder_records` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `phone_backups`
--
ALTER TABLE `phone_backups`
  ADD CONSTRAINT `1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_clock_alarms`
--
ALTER TABLE `phone_clock_alarms`
  ADD CONSTRAINT `1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_darkchat_accounts`
--
ALTER TABLE `phone_darkchat_accounts`
  ADD CONSTRAINT `1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_darkchat_members`
--
ALTER TABLE `phone_darkchat_members`
  ADD CONSTRAINT `1` FOREIGN KEY (`channel_name`) REFERENCES `phone_darkchat_channels` (`name`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `2` FOREIGN KEY (`username`) REFERENCES `phone_darkchat_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_darkchat_messages`
--
ALTER TABLE `phone_darkchat_messages`
  ADD CONSTRAINT `1` FOREIGN KEY (`channel`) REFERENCES `phone_darkchat_channels` (`name`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `2` FOREIGN KEY (`sender`) REFERENCES `phone_darkchat_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_instagram_accounts`
--
ALTER TABLE `phone_instagram_accounts`
  ADD CONSTRAINT `1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_instagram_comments`
--
ALTER TABLE `phone_instagram_comments`
  ADD CONSTRAINT `1` FOREIGN KEY (`post_id`) REFERENCES `phone_instagram_posts` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `2` FOREIGN KEY (`username`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_instagram_follows`
--
ALTER TABLE `phone_instagram_follows`
  ADD CONSTRAINT `1` FOREIGN KEY (`followed`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `2` FOREIGN KEY (`follower`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_instagram_follow_requests`
--
ALTER TABLE `phone_instagram_follow_requests`
  ADD CONSTRAINT `1` FOREIGN KEY (`requester`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `2` FOREIGN KEY (`requestee`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_instagram_likes`
--
ALTER TABLE `phone_instagram_likes`
  ADD CONSTRAINT `1` FOREIGN KEY (`username`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_instagram_messages`
--
ALTER TABLE `phone_instagram_messages`
  ADD CONSTRAINT `1` FOREIGN KEY (`sender`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `2` FOREIGN KEY (`recipient`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_instagram_notifications`
--
ALTER TABLE `phone_instagram_notifications`
  ADD CONSTRAINT `1` FOREIGN KEY (`username`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `2` FOREIGN KEY (`from`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_instagram_posts`
--
ALTER TABLE `phone_instagram_posts`
  ADD CONSTRAINT `1` FOREIGN KEY (`username`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_instagram_stories`
--
ALTER TABLE `phone_instagram_stories`
  ADD CONSTRAINT `1` FOREIGN KEY (`username`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_instagram_stories_views`
--
ALTER TABLE `phone_instagram_stories_views`
  ADD CONSTRAINT `1` FOREIGN KEY (`story_id`) REFERENCES `phone_instagram_stories` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `2` FOREIGN KEY (`viewer`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_last_phone`
--
ALTER TABLE `phone_last_phone`
  ADD CONSTRAINT `1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_logged_in_accounts`
--
ALTER TABLE `phone_logged_in_accounts`
  ADD CONSTRAINT `1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_mail_deleted`
--
ALTER TABLE `phone_mail_deleted`
  ADD CONSTRAINT `1` FOREIGN KEY (`message_id`) REFERENCES `phone_mail_messages` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `2` FOREIGN KEY (`address`) REFERENCES `phone_mail_accounts` (`address`) ON DELETE CASCADE;

--
-- Constraints for table `phone_maps_locations`
--
ALTER TABLE `phone_maps_locations`
  ADD CONSTRAINT `1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_marketplace_posts`
--
ALTER TABLE `phone_marketplace_posts`
  ADD CONSTRAINT `1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_message_members`
--
ALTER TABLE `phone_message_members`
  ADD CONSTRAINT `1` FOREIGN KEY (`channel_id`) REFERENCES `phone_message_channels` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_message_messages`
--
ALTER TABLE `phone_message_messages`
  ADD CONSTRAINT `1` FOREIGN KEY (`channel_id`) REFERENCES `phone_message_channels` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_message_reactions`
--
ALTER TABLE `phone_message_reactions`
  ADD CONSTRAINT `1` FOREIGN KEY (`message_id`) REFERENCES `phone_message_messages` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `2` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_music_playlists`
--
ALTER TABLE `phone_music_playlists`
  ADD CONSTRAINT `1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_music_saved_playlists`
--
ALTER TABLE `phone_music_saved_playlists`
  ADD CONSTRAINT `1` FOREIGN KEY (`playlist_id`) REFERENCES `phone_music_playlists` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `2` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_music_songs`
--
ALTER TABLE `phone_music_songs`
  ADD CONSTRAINT `1` FOREIGN KEY (`playlist_id`) REFERENCES `phone_music_playlists` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `phone_notes`
--
ALTER TABLE `phone_notes`
  ADD CONSTRAINT `1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_notifications`
--
ALTER TABLE `phone_notifications`
  ADD CONSTRAINT `1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_photos`
--
ALTER TABLE `phone_photos`
  ADD CONSTRAINT `1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_photo_albums`
--
ALTER TABLE `phone_photo_albums`
  ADD CONSTRAINT `1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_photo_album_members`
--
ALTER TABLE `phone_photo_album_members`
  ADD CONSTRAINT `1` FOREIGN KEY (`album_id`) REFERENCES `phone_photo_albums` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `2` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_photo_album_photos`
--
ALTER TABLE `phone_photo_album_photos`
  ADD CONSTRAINT `1` FOREIGN KEY (`album_id`) REFERENCES `phone_photo_albums` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `2` FOREIGN KEY (`photo_id`) REFERENCES `phone_photos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_services_messages`
--
ALTER TABLE `phone_services_messages`
  ADD CONSTRAINT `1` FOREIGN KEY (`channel_id`) REFERENCES `phone_services_channels` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `phone_tiktok_accounts`
--
ALTER TABLE `phone_tiktok_accounts`
  ADD CONSTRAINT `1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_tiktok_channels`
--
ALTER TABLE `phone_tiktok_channels`
  ADD CONSTRAINT `1` FOREIGN KEY (`member_1`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `2` FOREIGN KEY (`member_2`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_tiktok_comments`
--
ALTER TABLE `phone_tiktok_comments`
  ADD CONSTRAINT `1` FOREIGN KEY (`video_id`) REFERENCES `phone_tiktok_videos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `2` FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `3` FOREIGN KEY (`reply_to`) REFERENCES `phone_tiktok_comments` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_tiktok_comments_likes`
--
ALTER TABLE `phone_tiktok_comments_likes`
  ADD CONSTRAINT `1` FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `2` FOREIGN KEY (`comment_id`) REFERENCES `phone_tiktok_comments` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_tiktok_follows`
--
ALTER TABLE `phone_tiktok_follows`
  ADD CONSTRAINT `1` FOREIGN KEY (`followed`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `2` FOREIGN KEY (`follower`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_tiktok_likes`
--
ALTER TABLE `phone_tiktok_likes`
  ADD CONSTRAINT `1` FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `2` FOREIGN KEY (`video_id`) REFERENCES `phone_tiktok_videos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_tiktok_messages`
--
ALTER TABLE `phone_tiktok_messages`
  ADD CONSTRAINT `1` FOREIGN KEY (`channel_id`) REFERENCES `phone_tiktok_channels` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `2` FOREIGN KEY (`sender`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_tiktok_notifications`
--
ALTER TABLE `phone_tiktok_notifications`
  ADD CONSTRAINT `1` FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `2` FOREIGN KEY (`from`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `3` FOREIGN KEY (`video_id`) REFERENCES `phone_tiktok_videos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `4` FOREIGN KEY (`comment_id`) REFERENCES `phone_tiktok_comments` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_tiktok_pinned_videos`
--
ALTER TABLE `phone_tiktok_pinned_videos`
  ADD CONSTRAINT `1` FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `2` FOREIGN KEY (`video_id`) REFERENCES `phone_tiktok_videos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_tiktok_saves`
--
ALTER TABLE `phone_tiktok_saves`
  ADD CONSTRAINT `1` FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `2` FOREIGN KEY (`video_id`) REFERENCES `phone_tiktok_videos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_tiktok_unread_messages`
--
ALTER TABLE `phone_tiktok_unread_messages`
  ADD CONSTRAINT `1` FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `2` FOREIGN KEY (`channel_id`) REFERENCES `phone_tiktok_channels` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_tiktok_videos`
--
ALTER TABLE `phone_tiktok_videos`
  ADD CONSTRAINT `1` FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_tiktok_views`
--
ALTER TABLE `phone_tiktok_views`
  ADD CONSTRAINT `1` FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `2` FOREIGN KEY (`video_id`) REFERENCES `phone_tiktok_videos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_tinder_accounts`
--
ALTER TABLE `phone_tinder_accounts`
  ADD CONSTRAINT `1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_tinder_matches`
--
ALTER TABLE `phone_tinder_matches`
  ADD CONSTRAINT `1` FOREIGN KEY (`phone_number_1`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `2` FOREIGN KEY (`phone_number_2`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_tinder_messages`
--
ALTER TABLE `phone_tinder_messages`
  ADD CONSTRAINT `1` FOREIGN KEY (`sender`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `2` FOREIGN KEY (`recipient`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_tinder_swipes`
--
ALTER TABLE `phone_tinder_swipes`
  ADD CONSTRAINT `1` FOREIGN KEY (`swiper`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `2` FOREIGN KEY (`swipee`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_twitter_accounts`
--
ALTER TABLE `phone_twitter_accounts`
  ADD CONSTRAINT `1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_twitter_follows`
--
ALTER TABLE `phone_twitter_follows`
  ADD CONSTRAINT `1` FOREIGN KEY (`followed`) REFERENCES `phone_twitter_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `2` FOREIGN KEY (`follower`) REFERENCES `phone_twitter_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_twitter_follow_requests`
--
ALTER TABLE `phone_twitter_follow_requests`
  ADD CONSTRAINT `1` FOREIGN KEY (`requester`) REFERENCES `phone_twitter_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `2` FOREIGN KEY (`requestee`) REFERENCES `phone_twitter_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_twitter_likes`
--
ALTER TABLE `phone_twitter_likes`
  ADD CONSTRAINT `1` FOREIGN KEY (`username`) REFERENCES `phone_twitter_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_twitter_messages`
--
ALTER TABLE `phone_twitter_messages`
  ADD CONSTRAINT `1` FOREIGN KEY (`sender`) REFERENCES `phone_twitter_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `2` FOREIGN KEY (`recipient`) REFERENCES `phone_twitter_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_twitter_notifications`
--
ALTER TABLE `phone_twitter_notifications`
  ADD CONSTRAINT `1` FOREIGN KEY (`username`) REFERENCES `phone_twitter_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `2` FOREIGN KEY (`from`) REFERENCES `phone_twitter_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_twitter_promoted`
--
ALTER TABLE `phone_twitter_promoted`
  ADD CONSTRAINT `1` FOREIGN KEY (`tweet_id`) REFERENCES `phone_twitter_tweets` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `phone_twitter_retweets`
--
ALTER TABLE `phone_twitter_retweets`
  ADD CONSTRAINT `1` FOREIGN KEY (`username`) REFERENCES `phone_twitter_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_twitter_tweets`
--
ALTER TABLE `phone_twitter_tweets`
  ADD CONSTRAINT `1` FOREIGN KEY (`username`) REFERENCES `phone_twitter_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_voice_memos_recordings`
--
ALTER TABLE `phone_voice_memos_recordings`
  ADD CONSTRAINT `1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `phone_wallet_transactions`
--
ALTER TABLE `phone_wallet_transactions`
  ADD CONSTRAINT `1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
