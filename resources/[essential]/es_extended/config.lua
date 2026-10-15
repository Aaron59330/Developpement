Config = {}
Config.Locale = GetConvar('esx:locale', 'fr')
Config.Accounts = {
	bank = {
		label = TranslateCap('account_bank'),
		round = true
	},
	black_money = {
		label = TranslateCap('account_black_money'),
		round = true
	},
	money = {
		label = TranslateCap('account_money'),
		round = true
	}
}

Config.OxInventory = true

Config.StartingAccountMoney = {money = 25000, bank = 25000}

Config.StartingInventoryItems = {
    { name = "water", count = 5, slot = 1 },
    { name = "bread", count = 5, slot = 2 }
}

Config.DefaultSpawns = {
	{x = -787.70355224609, y = -120.35318756104, z = 19.950307846069, heading = 122.05529785156},
	{x = -785.39807128906, y = -123.42031860352, z = 19.950307846069, heading = 122.10639953613},
	{x = -788.8955078125, y = -125.28238677979, z = 19.950307846069, heading = 199.07623291016},
	{x = -791.79339599609, y = -127.08434295654, z = 19.950307846069, heading = 217.92971801758},
	{x = -794.86853027344, y = -130.68717956543, z = 19.950307846069, heading = 214.54321289062},
	{x = -798.57763671875, y = -132.64096069336, z = 19.950307846069, heading = 208.77958679199},
	{x = -803.04168701172, y = -135.15399169922, z = 19.950307846069, heading = 207.92242431641},
	{x = -807.69781494141, y = -137.36682128906, z = 19.950307846069, heading = 223.89823913574},
	{x = -812.64868164062, y = -140.1315612793, z = 19.950307846069, heading = 205.1346282959},
	{x = -818.11334228516, y = -142.97817993164, z = 19.950351715088, heading = 217.02627563477},
	{x = -823.80859375, y = -146.79368591309, z = 19.950353622437, heading = 191.00483703613},
	{x = -834.08557128906, y = -151.92419433594, z = 19.950353622437, heading = 203.74971008301},
	{x = -840.86309814453, y = -156.03675842285, z = 19.950353622437, heading = 216.99020385742},
	{x = -848.31787109375, y = -159.87037658691, z = 19.950353622437, heading = 214.12704467773},
	{x = -852.21984863281, y = -155.34460449219, z = 19.950353622437, heading = 21.643077850342},
	{x = -846.96936035156, y = -152.31051635742, z = 19.950353622437, heading = 32.842990875244},
	{x = -842.83538818359, y = -149.80912780762, z = 19.950353622437, heading = 41.713111877441},
	{x = -838.32189941406, y = -147.28001403809, z = 19.950353622437, heading = 29.087940216064},
	{x = -829.34875488281, y = -141.31649780273, z = 19.950353622437, heading = 21.539989471436},
	{x = -822.17761230469, y = -137.38368225098, z = 19.950353622437, heading = 24.39896774292},
	{x = -815.94055175781, y = -134.19975280762, z = 19.950330734253, heading = 32.792625427246},
	{x = -810.43774414062, y = -131.27940368652, z = 19.950325012207, heading = 34.517398834229},
	{x = -796.20648193359, y = -121.84392547607, z = 19.950325012207, heading = 31.251331329346},
	{x = -791.39965820312, y = -119.55378723145, z = 19.950323104858, heading = 14.774391174316},
	{x = -823.40972900391, y = -121.29649353027, z = 28.175319671631, heading = 214.2293548584},
	{x = -820.44891357422, y = -119.33081054688, z = 28.175321578979, heading = 209.91119384766},
	{x = -827.931640625, y = -120.96731567383, z = 28.175300598145, heading = 212.96575927734},
	{x = -824.13775634766, y = -128.53785705566, z = 28.175354003906, heading = 272.18884277344},
	{x = -823.0537109375, y = -133.48847961426, z = 28.175350189209, heading = 309.6120300293},
	{x = -815.52172851562, y = -135.12147521973, z = 28.175350189209, heading = 37.608783721924},
	{x = -812.90283203125, y = -130.41172790527, z = 28.175350189209, heading = 100.25142669678},
	{x = -814.15002441406, y = -126.39063262939, z = 28.17534828186, heading = 98.994903564453},
	{x = -811.50164794922, y = -135.93655395508, z = 28.17534828186, heading = 298.74102783203},
	{x = -808.81671142578, y = -139.57586669922, z = 28.17534828186, heading = 306.23504638672},
	{x = -805.42297363281, y = -141.85328674316, z = 28.17534828186, heading = 120.86782836914},
	{x = -807.23602294922, y = -144.17520141602, z = 28.175361633301, heading = 41.384563446045},
	{x = -810.10809326172, y = -146.59014892578, z = 28.17534828186, heading = 20.761566162109},
	{x = -813.46661376953, y = -147.75856018066, z = 28.175365447998, heading = 337.95013427734},
	{x = -815.62152099609, y = -145.38276672363, z = 28.175350189209, heading = 303.71258544922},
	{x = -816.68707275391, y = -138.85618591309, z = 28.175350189209, heading = 108.54591369629}
}

Config.CustomCore = "pickax_core"--à rename si vous voulez rename le core
Config.Framework = "es_extended"--à rename si vous voulez rename le framework

Config.AdminGroups = {
	['_dev'] = true
}

Config.EnablePaycheck = true--enable paycheck
Config.LogPaycheck = false-- Logs paychecks to a nominated Discord channel via webhook (default is false)
Config.EnableSocietyPayouts = false-- pay from the society account that the player is employed at? Requirement: esx_society

Config.MaxWeight = 24-- the max inventory weight without backpack

Config.PaycheckInterval = 25 * 60000-- how often to recieve pay checks in milliseconds

Config.EnableDebug = false-- Use Debug options?
Config.EnableDefaultInventory = false-- Display the default Inventory ( F2 )
Config.EnableWantedLevel = false-- Use Normal GTA wanted Level?
Config.EnablePVP = true-- Allow Player to player combat

Config.Multichar = false
Config.Identity = true-- Select a characters identity data before they have loaded in (this happens by default with multichar)
Config.DistanceGive = 4.0-- Max distance when giving items, weapons etc.
Config.AdminLogging = false-- Logs the usage of certain commands by those with group.admin ace permissions (default is false)

Config.DisableHealthRegeneration = true-- Player will no longer regenerate health
Config.DisableVehicleRewards = true-- Disables Player Recieving weapons from vehicles
Config.DisableNPCDrops = true-- stops NPCs from dropping weapons on death
Config.DisableDispatchServices = true-- Disable Dispatch services
Config.DisableScenarios = true-- Disable Scenarios
Config.DisableWeaponWheel = false-- Disables default weapon wheel
Config.DisableAimAssist = false-- disables AIM assist (mainly on controllers)
Config.DisableVehicleSeatShuff = false-- Disables vehicle seat shuff

Config.RemoveHudCommonents = {
	[1] = false,--WANTED_STARS,
	[2] = false,--WEAPON_ICON
	[3] = false,--CASH
	[4] = false,--MP_CASH
	[5] = false,--MP_MESSAGE
	[6] = false,--VEHICLE_NAME
	[7] = false,-- AREA_NAME
	[8] = false,-- VEHICLE_CLASS
	[9] = false,--STREET_NAME
	[10] = false,--HELP_TEXT
	[11] = false,--FLOATING_HELP_TEXT_1
	[12] = false,--FLOATING_HELP_TEXT_2
	[13] = false,--CASH_CHANGE
	[14] = false,--RETICLE
	[15] = false,--SUBTITLE_TEXT
	[16] = false,--RADIO_STATIONS
	[17] = false,--SAVING_GAME,
	[18] = false,--GAME_STREAM
	[19] = false,--WEAPON_WHEEL
	[20] = false,--WEAPON_WHEEL_STATS
	[21] = false,--HUD_COMPONENTS
	[22] = false,--HUD_WEAPONS
}

Config.SpawnVehMaxUpgrades = true-- admin vehicles spawn with max vehcle settings
Config.CustomAIPlates = '........'-- Custom plates for AI vehicles

Config.Commands = {
	["setcoords"] = {--Ne pas modifier ceci !!
		Active = true,--Mettre false si vous voulez plus de la commande
		Command = "setcoords",--La commande peux etre en table ce qui vous permet de mettre plusieur commande avec la même interaction
		Group = {"superadmin", "_dev"}--Les group sont les group qui sont autoriser à effectuer la commande (en table ou juste en string)
	},
	["setjob"] = {--Ne pas modifier ceci !!
		Active = true,--Mettre false si vous voulez plus de la commande
		Command = "setjob",--La commande peux etre en table ce qui vous permet de mettre plusieur commande avec la même interaction
		Group = {"superadmin", "_dev"}--Les group sont les group qui sont autoriser à effectuer la commande (en table ou juste en string)
	},
	["setjob2"] = {--Ne pas modifier ceci !!
		Active = true,--Mettre false si vous voulez plus de la commande
		Command = "setjob2",--La commande peux etre en table ce qui vous permet de mettre plusieur commande avec la même interaction
		Group = {"superadmin", "_dev"}--Les group sont les group qui sont autoriser à effectuer la commande (en table ou juste en string)
	},
	["car"] = {--Ne pas modifier ceci !!
		Active = true,--Mettre false si vous voulez plus de la commande
		Command = "car",--La commande peux etre en table ce qui vous permet de mettre plusieur commande avec la même interaction
		Group = {"superadmin", "_dev"}--Les group sont les group qui sont autoriser à effectuer la commande (en table ou juste en string)
	},
	["dv"] = {--Ne pas modifier ceci !!
		Active = true,--Mettre false si vous voulez plus de la commande
		Command = {"cardel", "dv" },--La commande peux etre en table ce qui vous permet de mettre plusieur commande avec la même interaction
		Group = {"mod", "admin", "superadmin", "_dev"}--Les group sont les group qui sont autoriser à effectuer la commande (en table ou juste en string)
	},
	["setaccountmoney"] = {--Ne pas modifier ceci !!
		Active = true,--Mettre false si vous voulez plus de la commande
		Command = "setaccountmoney",--La commande peux etre en table ce qui vous permet de mettre plusieur commande avec la même interaction
		Group = {"superadmin", "_dev"}--Les group sont les group qui sont autoriser à effectuer la commande (en table ou juste en string)
	},
	["giveaccountmoney"] = {--Ne pas modifier ceci !!
		Active = true,--Mettre false si vous voulez plus de la commande
		Command = "giveaccountmoney",--La commande peux etre en table ce qui vous permet de mettre plusieur commande avec la même interaction
		Group = {"superadmin", "_dev"}--Les group sont les group qui sont autoriser à effectuer la commande (en table ou juste en string)
	},
	["removeaccountmoney"] = {--Ne pas modifier ceci !!
		Active = true,--Mettre false si vous voulez plus de la commande
		Command = "removeaccountmoney",--La commande peux etre en table ce qui vous permet de mettre plusieur commande avec la même interaction
		Group = {"superadmin", "_dev"}--Les group sont les group qui sont autoriser à effectuer la commande (en table ou juste en string)
	},
	["giveitem"] = {--Ne pas modifier ceci !!
		Active = true,--Mettre false si vous voulez plus de la commande
		Command = "giveitem",--La commande peux etre en table ce qui vous permet de mettre plusieur commande avec la même interaction
		Group = {"superadmin", "_dev"}--Les group sont les group qui sont autoriser à effectuer la commande (en table ou juste en string)
	},
	["giveweapon"] = {--Ne pas modifier ceci !!
		Active = true,--Mettre false si vous voulez plus de la commande
		Command = "giveweapon",--La commande peux etre en table ce qui vous permet de mettre plusieur commande avec la même interaction
		Group = {"superadmin", "_dev"}--Les group sont les group qui sont autoriser à effectuer la commande (en table ou juste en string)
	},
	["giveammo"] = {--Ne pas modifier ceci !!
		Active = true,--Mettre false si vous voulez plus de la commande
		Command = "giveammo",--La commande peux etre en table ce qui vous permet de mettre plusieur commande avec la même interaction
		Group = {"superadmin", "_dev"}--Les group sont les group qui sont autoriser à effectuer la commande (en table ou juste en string)
	},
	["giveweaponcomponent"] = {--Ne pas modifier ceci !!
		Active = true,--Mettre false si vous voulez plus de la commande
		Command = "giveweaponcomponent",--La commande peux etre en table ce qui vous permet de mettre plusieur commande avec la même interaction
		Group = {"superadmin", "_dev"}--Les group sont les group qui sont autoriser à effectuer la commande (en table ou juste en string)
	},
	["refreshjobs"] = {--Ne pas modifier ceci !!
		Active = true,--Mettre false si vous voulez plus de la commande
		Command = "refreshjobs",--La commande peux etre en table ce qui vous permet de mettre plusieur commande avec la même interaction
		Group = {"superadmin", "_dev"}--Les group sont les group qui sont autoriser à effectuer la commande (en table ou juste en string)
	},
	["clearinventory"] = {--Ne pas modifier ceci !!
		Active = true,--Mettre false si vous voulez plus de la commande
		Command = "clearinventory",--La commande peux etre en table ce qui vous permet de mettre plusieur commande avec la même interaction
		Group = {"superadmin", "_dev"}--Les group sont les group qui sont autoriser à effectuer la commande (en table ou juste en string)
	},
	["clearloadout"] = {--Ne pas modifier ceci !!
		Active = true,--Mettre false si vous voulez plus de la commande
		Command = "clearloadout",--La commande peux etre en table ce qui vous permet de mettre plusieur commande avec la même interaction
		Group = {"superadmin", "_dev"}--Les group sont les group qui sont autoriser à effectuer la commande (en table ou juste en string)
	},
	["save"] = {--Ne pas modifier ceci !!
		Active = true,--Mettre false si vous voulez plus de la commande
		Command = "save",--La commande peux etre en table ce qui vous permet de mettre plusieur commande avec la même interaction
		Group = {"admin", "superadmin", "_dev"}--Les group sont les group qui sont autoriser à effectuer la commande (en table ou juste en string)
	},
	["saveall"] = {--Ne pas modifier ceci !!
		Active = true,--Mettre false si vous voulez plus de la commande
		Command = "saveall",--La commande peux etre en table ce qui vous permet de mettre plusieur commande avec la même interaction
		Group = {"admin", "superadmin", "_dev"}--Les group sont les group qui sont autoriser à effectuer la commande (en table ou juste en string)
	},
	["tpm"] = {--Ne pas modifier ceci !!
		Active = true,--Mettre false si vous voulez plus de la commande
		Command = "tpm",--La commande peux etre en table ce qui vous permet de mettre plusieur commande avec la même interaction
		Group = {"admin", "superadmin", "_dev"}--Les group sont les group qui sont autoriser à effectuer la commande (en table ou juste en string)
	},
	["goto"] = {--Ne pas modifier ceci !!
		Active = true,--Mettre false si vous voulez plus de la commande
		Command = "goto",--La commande peux etre en table ce qui vous permet de mettre plusieur commande avec la même interaction
		Group = {"mod", "admin", "superadmin", "_dev"}--Les group sont les group qui sont autoriser à effectuer la commande (en table ou juste en string)
	},
	["bring"] = {--Ne pas modifier ceci !!
		Active = true,--Mettre false si vous voulez plus de la commande
		Command = "bring",--La commande peux etre en table ce qui vous permet de mettre plusieur commande avec la même interaction
		Group = {"mod", "admin", "superadmin", "_dev"}--Les group sont les group qui sont autoriser à effectuer la commande (en table ou juste en string)
	},
	["kill"] = {--Ne pas modifier ceci !!
		Active = true,--Mettre false si vous voulez plus de la commande
		Command = "kill",--La commande peux etre en table ce qui vous permet de mettre plusieur commande avec la même interaction
		Group = {"admin", "superadmin", "_dev"}--Les group sont les group qui sont autoriser à effectuer la commande (en table ou juste en string)
	},
	["freeze"] = {--Ne pas modifier ceci !!
		Active = true,--Mettre false si vous voulez plus de la commande
		Command = "freeze",--La commande peux etre en table ce qui vous permet de mettre plusieur commande avec la même interaction
		Group = {"admin", "superadmin", "_dev"}--Les group sont les group qui sont autoriser à effectuer la commande (en table ou juste en string)
	},
	["unfreeze"] = {--Ne pas modifier ceci !!
		Active = true,--Mettre false si vous voulez plus de la commande
		Command = "unfreeze",--La commande peux etre en table ce qui vous permet de mettre plusieur commande avec la même interaction
		Group = {"admin", "superadmin", "_dev"}--Les group sont les group qui sont autoriser à effectuer la commande (en table ou juste en string)
	}
}