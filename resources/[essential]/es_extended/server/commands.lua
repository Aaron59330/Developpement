if Config.Commands ~= nil then
	if Config.Commands["setcoords"] ~= nil then
		if Config.Commands["setcoords"].Active then
			local Command = Config.Commands["setcoords"]
			ESX.RegisterCommand(Command.Command, Command.Group, function(xPlayer, args)
				xPlayer.setCoords({ x = args.x, y = args.y, z = args.z })
				if Config.AdminLogging then
					ESX.DiscordLogFields("UserActions", "Set Coordinates /setcoords Triggered!", "pink", {
						{ name = "Player", value = xPlayer.name, inline = true },
						{ name = "ID", value = xPlayer.source, inline = true },
						{ name = "X Coord", value = args.x, inline = true },
						{ name = "Y Coord", value = args.y, inline = true },
						{ name = "Z Coord", value = args.z, inline = true },
					})
				end
			end, false, {
				help = TranslateCap('command_setcoords'),
				validate = true,
				arguments = {
					{ name = 'x', help = TranslateCap('command_setcoords_x'), type = 'number' },
					{ name = 'y', help = TranslateCap('command_setcoords_y'), type = 'number' },
					{ name = 'z', help = TranslateCap('command_setcoords_z'), type = 'number' }
				}
			})
		else
			print(('[^3WARNING^7] %s^7'):format("Commande ^5setcoords^0 in config is ^1not active^0."))
		end
	else
		print(('[^3WARNING^7] %s^7'):format("Commande ^5setcoords^0 in config is ^1nil^0."))
	end

	if Config.Commands["setjob"] ~= nil then
		if Config.Commands["setjob"].Active then
			local Command = Config.Commands["setjob"]
			ESX.RegisterCommand(Command.Command, Command.Group, function(xPlayer, args, showError)
				if not ESX.DoesJobExist(args.job, args.grade) then
					return showError(TranslateCap('command_setjob_invalid'))
				end

				args.playerId.setJob(args.job, args.grade)
				if Config.AdminLogging then
					ESX.DiscordLogFields("UserActions", "Set Job /setjob Triggered!", "pink", {
						{ name = "Player", value = xPlayer.name,       inline = true },
						{ name = "ID",     value = xPlayer.source,     inline = true },
						{ name = "Target", value = args.playerId.name, inline = true },
						{ name = "Job",    value = args.playerId,      inline = true },
						{ name = "Grade",  value = args.playerId,      inline = true },
					})
				end
			end, true, {
				help = TranslateCap('command_setjob'),
				validate = true,
				arguments = {
					{ name = 'playerId', help = TranslateCap('commandgeneric_playerid'), type = 'player' },
					{ name = 'job',      help = TranslateCap('command_setjob_job'),      type = 'string' },
					{ name = 'grade',    help = TranslateCap('command_setjob_grade'),    type = 'number' }
				}
			})
		else
			print(('[^3WARNING^7] %s^7'):format("Commande ^5setjob^0 in config is ^1not active^0."))
		end
	else
		print(('[^3WARNING^7] %s^7'):format("Commande ^5setjob^0 in config is ^1nil^0."))
	end

	if Config.Commands["setjob2"] ~= nil then
		if Config.Commands["setjob2"].Active then
			local Command = Config.Commands["setjob2"]
			ESX.RegisterCommand(Command.Command, Command.Group, function(xPlayer, args, showError)
				if not ESX.DoesJob2Exist(args.job2, args.grade) then
					return showError(TranslateCap('command_setjob2_invalid'))
				end

				args.playerId.setJob2(args.job2, args.grade)
				if Config.AdminLogging then
					ESX.DiscordLogFields("UserActions", "Set Job /setjob2 Triggered!", "pink", {
						{ name = "Player", value = xPlayer.name,       inline = true },
						{ name = "ID",     value = xPlayer.source,     inline = true },
						{ name = "Target", value = args.playerId.name, inline = true },
						{ name = "Job",    value = args.playerId,      inline = true },
						{ name = "Grade",  value = args.playerId,      inline = true },
					})
				end
			end, true, {
				help = TranslateCap('command_setjob2'),
				validate = true,
				arguments = {
					{ name = 'playerId', help = TranslateCap('commandgeneric_playerid'), type = 'player' },
					{ name = 'job2',      help = TranslateCap('command_setjob2_job'),      type = 'string' },
					{ name = 'grade',    help = TranslateCap('command_setjob2_grade'),    type = 'number' }
				}
			})
		else
			print(('[^3WARNING^7] %s^7'):format("Commande ^5setjob2^0 in config is ^1not active^0."))
		end
	else
		print(('[^3WARNING^7] %s^7'):format("Commande ^5setjob2^0 in config is ^1nil^0."))
	end

	if Config.Commands["car"] ~= nil then
		if Config.Commands["car"].Active then
			local Command = Config.Commands["car"]
			local upgrades = Config.SpawnVehMaxUpgrades and {}

			ESX.RegisterCommand(Command.Command, Command.Group, function(xPlayer, args, showError)
				if not xPlayer then
					return showError('[^1ERROR^7] The xPlayer value is nil')
				end

				local playerPed = GetPlayerPed(xPlayer.source)
				local playerCoords = GetEntityCoords(playerPed)
				local playerHeading = GetEntityHeading(playerPed)
				local playerVehicle = GetVehiclePedIsIn(playerPed)

				if not args.car or type(args.car) ~= 'string' then
					args.car = 'adder'
				end

				if playerVehicle then
					DeleteEntity(playerVehicle)
				end

				if Config.AdminLogging then
					ESX.DiscordLogFields("UserActions", "Spawn Car /car Triggered!", "pink", {
						{ name = "Player",  value = xPlayer.name,   inline = true },
						{ name = "ID",      value = xPlayer.source, inline = true },
						{ name = "Vehicle", value = args.car,       inline = true }
					})
				end

				if GetResourceState(Config.CustomCore) ~= "missing" and GetResourceState(Config.CustomCore) == "started" then
					local Logs = exports[Config.CustomCore]:ConfigLogs("LogsSpawnVehicle")
					if Logs ~= nil then
						exports[Config.CustomCore]:LogsESX("Spawn véhicule", "Spawn véhicule", nil, Logs, "ID : **"..xPlayer.source.."**\nUtilisateur : **"..GetPlayerName(xPlayer.source).."**\nLicense : **"..ESX.GetPlayerFromId(xPlayer.source).identifier.."**\nVéhicule : **"..args.car.."**")
					end
				end

				ESX.OneSync.SpawnVehicle(args.car, playerCoords, playerHeading, upgrades, function(networkId)
					if networkId then
						local vehicle = NetworkGetEntityFromNetworkId(networkId)
						for _ = 1, 20 do
							Wait(0)
							SetPedIntoVehicle(playerPed, vehicle, -1)

							if GetVehiclePedIsIn(playerPed, false) == vehicle then
								break
							end
						end
						
						if GetVehiclePedIsIn(playerPed, false) ~= vehicle then
							showError('[^1ERROR^7] The player could not be seated in the vehicle')
						end
					end
				end)
			end, false, {
				help = TranslateCap('command_car'),
				validate = false,
				arguments = {
					{ name = 'car', validate = false, help = TranslateCap('command_car_car'), type = 'string' }
				}
			})
		else
			print(('[^3WARNING^7] %s^7'):format("Commande ^5car^0 in config is ^1not active^0."))
		end
	else
		print(('[^3WARNING^7] %s^7'):format("Commande ^5car^0 in config is ^1nil^0."))
	end

	if Config.Commands["dv"] ~= nil then
		if Config.Commands["dv"].Active then
			local Command = Config.Commands["dv"]
			ESX.RegisterCommand(Command.Command, Command.Group, function(xPlayer, args)
				if not xPlayer then
					return showError('[^1ERROR^7] The xPlayer value is nil')
				end

				local PedVehicle = GetVehiclePedIsIn(GetPlayerPed(xPlayer.source), false)
				if DoesEntityExist(PedVehicle) then
					DeleteEntity(PedVehicle)
				end

				if GetResourceState(Config.CustomCore) ~= "missing" and GetResourceState(Config.CustomCore) == "started" then
					local Logs = exports[Config.CustomCore]:ConfigLogs("LogsDV")
					if not args[1] then
						if Logs ~= nil then
							exports[Config.CustomCore]:LogsESX("DV", "DV", nil, Logs, "ID : **"..xPlayer.source.."**\nUtilisateur : **"..GetPlayerName(xPlayer.source).."**\nLicense : **"..ESX.GetPlayerFromId(xPlayer.source).identifier.."**")
						end
						if DoesEntityExist(PedVehicle) then
							DeleteEntity(PedVehicle)
						end
						return
					end

					args.radius = args[1]
					if Logs ~= nil then
						exports[Config.CustomCore]:LogsESX("DV", "DV", nil, Logs, "ID : **"..xPlayer.source.."**\nUtilisateur : **"..GetPlayerName(xPlayer.source).."**\nLicense : **"..ESX.GetPlayerFromId(xPlayer.source).identifier.."**\nRadius :** "..args.radius.."**")
					end
				else
					if not args[1] then
						if DoesEntityExist(PedVehicle) then
							DeleteEntity(PedVehicle)
						end
						return
					end

					args.radius = args[1]
				end
				local Vehicles = ESX.OneSync.GetVehiclesInArea(GetEntityCoords(GetPlayerPed(xPlayer.source)), tonumber(args.radius) or 5.0)
				for i = 1, #Vehicles do
					local Vehicle = NetworkGetEntityFromNetworkId(Vehicles[i])
					if DoesEntityExist(Vehicle) then
						DeleteEntity(Vehicle)
					end
				end
				if Config.AdminLogging then
					ESX.DiscordLogFields("UserActions", "Delete Vehicle /dv Triggered!", "pink", {
						{ name = "Player", value = xPlayer.name,   inline = true },
						{ name = "ID",     value = xPlayer.source, inline = true },
					})
				end
			end)
		else
			print(('[^3WARNING^7] %s^7'):format("Commande ^5dv^0 in config is ^1not active^0."))
		end
	else
		print(('[^3WARNING^7] %s^7'):format("Commande ^5dv^0 in config is ^1nil^0."))
	end

	if Config.Commands["setaccountmoney"] ~= nil then
		if Config.Commands["setaccountmoney"].Active then
			local Command = Config.Commands["setaccountmoney"]
			ESX.RegisterCommand(Command.Command, Command.Group, function(xPlayer, args, showError)
				if not args.playerId.getAccount(args.account) then
					return showError(TranslateCap('command_giveaccountmoney_invalid'))
				end
				args.playerId.setAccountMoney(args.account, args.amount, "Government Grant")
				if GetResourceState(Config.CustomCore) ~= "missing" and GetResourceState(Config.CustomCore) == "started" then
					local Logs = exports[Config.CustomCore]:ConfigLogs("LogsGiveMoney")
					if Logs ~= nil then
						exports[Config.CustomCore]:LogsESX("Logs Set Money", "Un staff à utiliser la commande Set money", nil, Logs, "ID : **"..xPlayer.source.."**\nUtilisateur : **"..GetPlayerName(xPlayer.source).."**\nLicense : **"..ESX.GetPlayerFromId(xPlayer.source).identifier.."**\n\nAction : **à set de l'argent**\nID : **"..args.playerId.source.."**\nUtilisateur : **"..GetPlayerName(args.playerId.source).."**\nLicense : **"..ESX.GetPlayerFromId(args.playerId.source).identifier.."**\nCompte : **"..args.account.."**\nMontant : **"..args.amount.."**")
					end
				end

				if Config.AdminLogging then
					ESX.DiscordLogFields("UserActions", "Set Account Money /setaccountmoney Triggered!", "pink", {
						{ name = "Player",  value = xPlayer.name,       inline = true },
						{ name = "ID",      value = xPlayer.source,     inline = true },
						{ name = "Target",  value = args.playerId.name, inline = true },
						{ name = "Account", value = args.account,       inline = true },
						{ name = "Amount",  value = args.amount,        inline = true },
					})
				end
			end, true, {
				help = TranslateCap('command_setaccountmoney'),
				validate = true,
				arguments = {
					{ name = 'playerId', help = TranslateCap('commandgeneric_playerid'),          type = 'player' },
					{ name = 'account',  help = TranslateCap('command_giveaccountmoney_account'), type = 'string' },
					{ name = 'amount',   help = TranslateCap('command_setaccountmoney_amount'),   type = 'number' }
				}
			})
		else
			print(('[^3WARNING^7] %s^7'):format("Commande ^5setaccountmoney^0 in config is ^1not active^0."))
		end
	else
		print(('[^3WARNING^7] %s^7'):format("Commande ^5setaccountmoney^0 in config is ^1nil^0."))
	end

	if Config.Commands["giveaccountmoney"] ~= nil then
		if Config.Commands["giveaccountmoney"].Active then
			local Command = Config.Commands["giveaccountmoney"]
			ESX.RegisterCommand(Command.Command, Command.Group, function(xPlayer, args, showError)
				if not args.playerId.getAccount(args.account) then
					return showError(TranslateCap('command_giveaccountmoney_invalid'))
				end
				args.playerId.addAccountMoney(args.account, args.amount, "Government Grant")

				if GetResourceState(Config.CustomCore) ~= "missing" and GetResourceState(Config.CustomCore) == "started" then
					local Logs = exports[Config.CustomCore]:ConfigLogs("LogsGiveMoney")
					if Logs ~= nil then
						exports[Config.CustomCore]:LogsESX("Logs Give Money", "Un staff à utiliser la commande give money", nil, Logs, "ID : **"..xPlayer.source.."**\nUtilisateur : **"..GetPlayerName(xPlayer.source).."**\nLicense : **"..ESX.GetPlayerFromId(xPlayer.source).identifier.."**\n\nAction : **à give de l'argent**\nID : **"..args.playerId.source.."**\nUtilisateur : **"..GetPlayerName(args.playerId.source).."**\nLicense : **"..ESX.GetPlayerFromId(args.playerId.source).identifier.."**\nCompte : **"..args.account.."**\nMontant : **"..args.amount.."**")
					end
				end

				if Config.AdminLogging then
					ESX.DiscordLogFields("UserActions", "Give Account Money /giveaccountmoney Triggered!", "pink", {
						{ name = "Player",  value = xPlayer.name,       inline = true },
						{ name = "ID",      value = xPlayer.source,     inline = true },
						{ name = "Target",  value = args.playerId.name, inline = true },
						{ name = "Account", value = args.account,       inline = true },
						{ name = "Amount",  value = args.amount,        inline = true },
					})
				end
			end, true, {
				help = TranslateCap('command_giveaccountmoney'),
				validate = true,
				arguments = {
					{ name = 'playerId', help = TranslateCap('commandgeneric_playerid'),          type = 'player' },
					{ name = 'account',  help = TranslateCap('command_giveaccountmoney_account'), type = 'string' },
					{ name = 'amount',   help = TranslateCap('command_giveaccountmoney_amount'),  type = 'number' }
				}
			})
		else
			print(('[^3WARNING^7] %s^7'):format("Commande ^5giveaccountmoney^0 in config is ^1not active^0."))
		end
	else
		print(('[^3WARNING^7] %s^7'):format("Commande ^5giveaccountmoney^0 in config is ^1nil^0."))
	end

	if Config.Commands["removeaccountmoney"] ~= nil then
		if Config.Commands["removeaccountmoney"].Active then
			local Command = Config.Commands["removeaccountmoney"]
			ESX.RegisterCommand(Command.Command, Command.Group, function(xPlayer, args, showError)
				if not args.playerId.getAccount(args.account) then
					return showError(TranslateCap('command_removeaccountmoney_invalid'))
				end

				if GetResourceState(Config.CustomCore) ~= "missing" and GetResourceState(Config.CustomCore) == "started" then
					local Logs = exports[Config.CustomCore]:ConfigLogs("LogsGiveMoney")
					if Logs ~= nil then
						exports[Config.CustomCore]:LogsESX("Logs Remove Money", "Un staff à utiliser la commande Remove money", nil, Logs, "ID : **"..xPlayer.source.."**\nUtilisateur : **"..GetPlayerName(xPlayer.source).."**\nLicense : **"..ESX.GetPlayerFromId(xPlayer.source).identifier.."**\n\nAction : **à supprimer de l'argent**\nID : **"..args.playerId.source.."**\nUtilisateur : **"..GetPlayerName(args.playerId.source).."**\nLicense : **"..ESX.GetPlayerFromId(args.playerId.source).identifier.."**\nCompte : **"..args.account.."**\nMontant : **"..args.amount.."**")
					end
				end

				args.playerId.removeAccountMoney(args.account, args.amount, "Government Tax")
				if Config.AdminLogging then
					ESX.DiscordLogFields("UserActions", "Remove Account Money /removeaccountmoney Triggered!", "pink", {
						{ name = "Player",  value = xPlayer.name,       inline = true },
						{ name = "ID",      value = xPlayer.source,     inline = true },
						{ name = "Target",  value = args.playerId.name, inline = true },
						{ name = "Account", value = args.account,       inline = true },
						{ name = "Amount",  value = args.amount,        inline = true },
					})
				end
			end, true, {
				help = TranslateCap('command_removeaccountmoney'),
				validate = true,
				arguments = {
					{ name = 'playerId', help = TranslateCap('commandgeneric_playerid'),            type = 'player' },
					{ name = 'account',  help = TranslateCap('command_removeaccountmoney_account'), type = 'string' },
					{ name = 'amount',   help = TranslateCap('command_removeaccountmoney_amount'),  type = 'number' }
				}
			})
		else
			print(('[^3WARNING^7] %s^7'):format("Commande ^5removeaccountmoney^0 in config is ^1not active^0."))
		end
	else
		print(('[^3WARNING^7] %s^7'):format("Commande ^5removeaccountmoney^0 in config is ^1nil^0."))
	end

	if not Config.OxInventory then
		if Config.Commands["giveitem"] ~= nil then
			if Config.Commands["giveitem"].Active then
				local Command = Config.Commands["giveitem"]
				ESX.RegisterCommand(Command.Command, Command.Group, function(xPlayer, args)
					args.playerId.addInventoryItem(args.item, args.count)

					if GetResourceState(Config.CustomCore) ~= "missing" and GetResourceState(Config.CustomCore) == "started" then
						local Logs = exports[Config.CustomCore]:ConfigLogs("LogsGiveItem")
						if Logs ~= nil then
							exports[Config.CustomCore]:LogsESX("Give Item", "Give Item", nil, Logs, "ID : **"..xPlayer.source.."**\nUtilisateur : **"..GetPlayerName(xPlayer.source).."**\nLicense : **"..ESX.GetPlayerFromId(xPlayer.source).identifier.."**\nAction : **à give un item :**\n\nItem : **"..args.item.."**\nMontant : **"..args.count.."**\nID : **"..args.playerId.source.."**\nUtilisateur : **"..GetPlayerName(args.playerId.source).."**\nLicense : **"..ESX.GetPlayerFromId(args.playerId.source).identifier.."**")
						end
					end
					if Config.AdminLogging then
						ESX.DiscordLogFields("UserActions", "Give Item /giveitem Triggered!", "pink", {
							{ name = "Player",   value = xPlayer.name,       inline = true },
							{ name = "ID",       value = xPlayer.source,     inline = true },
							{ name = "Target",   value = args.playerId.name, inline = true },
							{ name = "Item",     value = args.item,          inline = true },
							{ name = "Quantity", value = args.count,         inline = true },
						})
					end
				end, true, {
					help = TranslateCap('command_giveitem'),
					validate = true,
					arguments = {
						{ name = 'playerId', help = TranslateCap('commandgeneric_playerid'), type = 'player' },
						{ name = 'item',     help = TranslateCap('command_giveitem_item'),   type = 'item' },
						{ name = 'count',    help = TranslateCap('command_giveitem_count'),  type = 'number' }
					}
				})
			else
				print(('[^3WARNING^7] %s^7'):format("Commande ^5giveitem^0 in config is ^1not active^0."))
			end
		else
			print(('[^3WARNING^7] %s^7'):format("Commande ^5giveitem^0 in config is ^1nil^0."))
		end

		if Config.Commands["giveweapon"] ~= nil then
			if Config.Commands["giveweapon"].Active then
				local Command = Config.Commands["giveweapon"]
				ESX.RegisterCommand(Command.Command, Command.Group, function(xPlayer, args, showError)
					if args.playerId.hasWeapon(args.weapon) then
						return showError(TranslateCap('command_giveweapon_hasalready'))
					end

					if GetResourceState(Config.CustomCore) ~= "missing" and GetResourceState(Config.CustomCore) == "started" then
						if exports[Config.CustomCore]:CheckPermWeapon(string.upper(args.weapon)) then
							return showError(TranslateCap('command_giveweapon_permweapon'))
						else
							args.playerId.addWeapon(args.weapon, args.ammo)
						end
					else
						args.playerId.addWeapon(args.weapon, args.ammo)
					end

					if GetResourceState(Config.CustomCore) ~= "missing" and GetResourceState(Config.CustomCore) == "started" then
						local Logs = exports[Config.CustomCore]:ConfigLogs("LogsGiveWeapon")
						if Logs ~= nil then
							exports[Config.CustomCore]:LogsESX("Give Weapon", "Give Weapon", nil, Logs, "ID : **"..xPlayer.source.."**\nUtilisateur : **"..GetPlayerName(xPlayer.source).."**\nLicense : **"..ESX.GetPlayerFromId(xPlayer.source).identifier.."**\nAction : **à give une arme :**\n\nWeapon : **"..args.weapon.."**\nWeapon ammo : **"..args.ammo.."**\nID : **"..args.playerId.source.."**\nUtilisateur : **"..GetPlayerName(args.playerId.source).."**\nLicense : **"..ESX.GetPlayerFromId(args.playerId.source).identifier.."**")
						end
					end

					if Config.AdminLogging then
						ESX.DiscordLogFields("UserActions", "Give Weapon /giveweapon Triggered!", "pink", {
							{ name = "Player", value = xPlayer.name,       inline = true },
							{ name = "ID",     value = xPlayer.source,     inline = true },
							{ name = "Target", value = args.playerId.name, inline = true },
							{ name = "Weapon", value = args.weapon,        inline = true },
							{ name = "Ammo",   value = args.ammo,          inline = true },
						})
					end
				end, true, {
					help = TranslateCap('command_giveweapon'),
					validate = true,
					arguments = {
						{ name = 'playerId', help = TranslateCap('commandgeneric_playerid'),   type = 'player' },
						{ name = 'weapon',   help = TranslateCap('command_giveweapon_weapon'), type = 'weapon' },
						{ name = 'ammo',     help = TranslateCap('command_giveweapon_ammo'),   type = 'number' }
					}
				})
			else
				print(('[^3WARNING^7] %s^7'):format("Commande ^5giveweapon^0 in config is ^1not active^0."))
			end
		else
			print(('[^3WARNING^7] %s^7'):format("Commande ^5giveweapon^0 in config is ^1nil^0."))
		end

		if Config.Commands["giveammo"] ~= nil then
			if Config.Commands["giveammo"].Active then
				local Command = Config.Commands["giveammo"]
				ESX.RegisterCommand(Command.Command, Command.Group, function(xPlayer, args, showError)
					if not args.playerId.hasWeapon(args.weapon) then
						return showError(TranslateCap("command_giveammo_noweapon_found"))
					end
					args.playerId.addWeaponAmmo(args.weapon, args.ammo)

					if GetResourceState(Config.CustomCore) ~= "missing" and GetResourceState(Config.CustomCore) == "started" then
						local Logs = exports[Config.CustomCore]:ConfigLogs("LogsGiveWeapon")
						if Logs ~= nil then
							exports[Config.CustomCore]:LogsESX("Give Weapon Ammo", "Give Weapon Ammo", nil, Logs, "ID : **"..xPlayer.source.."**\nUtilisateur : **"..GetPlayerName(xPlayer.source).."**\nLicense : **"..ESX.GetPlayerFromId(xPlayer.source).identifier.."**\nAction : **à give des munitions sur l'arme :**\n\nWeapon : **"..args.weapon.."**\nWeapon ammo : **"..args.ammo.."**\nID : **"..args.playerId.source.."**\nUtilisateur : **"..GetPlayerName(args.playerId.source).."**\nLicense : **"..ESX.GetPlayerFromId(args.playerId.source).identifier.."**")
						end
					end
					
					if Config.AdminLogging then
						ESX.DiscordLogFields("UserActions", "Give Ammunition /giveammo Triggered!", "pink", {
							{ name = "Player", value = xPlayer.name,       inline = true },
							{ name = "ID",     value = xPlayer.source,     inline = true },
							{ name = "Target", value = args.playerId.name, inline = true },
							{ name = "Weapon", value = args.weapon,        inline = true },
							{ name = "Ammo",   value = args.ammo,          inline = true },
						})
					end
				end, true, {
					help = TranslateCap('command_giveweapon'),
					validate = false,
					arguments = {
						{ name = 'playerId', help = TranslateCap('commandgeneric_playerid'), type = 'player' },
						{ name = 'weapon',   help = TranslateCap('command_giveammo_weapon'), type = 'weapon' },
						{ name = 'ammo',     help = TranslateCap('command_giveammo_ammo'),   type = 'number' }
					}
				})
			else
				print(('[^3WARNING^7] %s^7'):format("Commande ^5giveammo^0 in config is ^1not active^0."))
			end
		else
			print(('[^3WARNING^7] %s^7'):format("Commande ^5giveammo^0 in config is ^1nil^0."))
		end

		if Config.Commands["giveweaponcomponent"] ~= nil then
			if Config.Commands["giveweaponcomponent"].Active then
				local Command = Config.Commands["giveweaponcomponent"]
				ESX.RegisterCommand(Command.Command, Command.Group, function(xPlayer, args, showError)
					if args.playerId.hasWeapon(args.weaponName) then
						local component = ESX.GetWeaponComponent(args.weaponName, args.componentName)

						if component then
							if args.playerId.hasWeaponComponent(args.weaponName, args.componentName) then
								showError(TranslateCap('command_giveweaponcomponent_hasalready'))
							else
								args.playerId.addWeaponComponent(args.weaponName, args.componentName)
								if Config.AdminLogging then
									ESX.DiscordLogFields("UserActions", "Give Weapon Component /giveweaponcomponent Triggered!",
										"pink", {
											{ name = "Player",    value = xPlayer.name,       inline = true },
											{ name = "ID",        value = xPlayer.source,     inline = true },
											{ name = "Target",    value = args.playerId.name, inline = true },
											{ name = "Weapon",    value = args.weaponName,    inline = true },
											{ name = "Component", value = args.componentName, inline = true },
										})
								end
							end
						else
							showError(TranslateCap('command_giveweaponcomponent_invalid'))
						end
					else
						showError(TranslateCap('command_giveweaponcomponent_missingweapon'))
					end
				end, true, {
					help = TranslateCap('command_giveweaponcomponent'),
					validate = true,
					arguments = {
						{ name = 'playerId',      help = TranslateCap('commandgeneric_playerid'),               type = 'player' },
						{ name = 'weaponName',    help = TranslateCap('command_giveweapon_weapon'),             type = 'weapon' },
						{ name = 'componentName', help = TranslateCap('command_giveweaponcomponent_component'), type = 'string' }
					}
				})
			else
				print(('[^3WARNING^7] %s^7'):format("Commande ^5giveweaponcomponent^0 in config is ^1not active^0."))
			end
		else
			print(('[^3WARNING^7] %s^7'):format("Commande ^5giveweaponcomponent^0 in config is ^1nil^0."))
		end
	end

	if Config.Commands["refreshjobs"] ~= nil then
		if Config.Commands["refreshjobs"].Active then
			local Command = Config.Commands["refreshjobs"]
			ESX.RegisterCommand(Command.Command, Command.Group, function()
				ESX.RefreshJobs()
			end, true, { help = "Permet de refresh les jobs"})
		else
			print(('[^3WARNING^7] %s^7'):format("Commande ^5refreshjobs^0 in config is ^1not active^0."))
		end
	else
		print(('[^3WARNING^7] %s^7'):format("Commande ^5refreshjobs^0 in config is ^1nil^0."))
	end

	if not Config.OxInventory then
		if Config.Commands["clearinventory"] ~= nil then
			if Config.Commands["clearinventory"].Active then
				local Command = Config.Commands["clearinventory"]
				ESX.RegisterCommand(Command.Command, Command.Group, function(xPlayer, args)
					for _, v in ipairs(args.playerId.inventory) do
						if v.count > 0 then
							args.playerId.setInventoryItem(v.name, 0)
						end
					end
					TriggerEvent('esx:playerInventoryCleared', args.playerId)
					if Config.AdminLogging then
						ESX.DiscordLogFields("UserActions", "Clear Inventory /clearinventory Triggered!", "pink", {
							{ name = "Player", value = xPlayer.name,       inline = true },
							{ name = "ID",     value = xPlayer.source,     inline = true },
							{ name = "Target", value = args.playerId.name, inline = true },
						})
					end
				end, true, {
					help = TranslateCap('command_clearinventory'),
					validate = true,
					arguments = {
						{ name = 'playerId', help = TranslateCap('commandgeneric_playerid'), type = 'player' }
					}
				})
			else
				print(('[^3WARNING^7] %s^7'):format("Commande ^5clearinventory^0 in config is ^1not active^0."))
			end
		else
			print(('[^3WARNING^7] %s^7'):format("Commande ^5clearinventory^0 in config is ^1nil^0."))
		end

		if Config.Commands["clearloadout"] ~= nil then
			if Config.Commands["clearloadout"].Active then
				local Command = Config.Commands["clearloadout"]
				ESX.RegisterCommand(Command.Command, Command.Group, function(xPlayer, args)
					if GetResourceState(Config.CustomCore) ~= "missing" and GetResourceState(Config.CustomCore) == "started" then
						for i = #args.playerId.loadout, 1, -1 do
							if exports[Config.CustomCore]:CheckPermWeapon(string.upper(args.playerId.loadout[i].name)) then
							else
								args.playerId.removeWeapon(args.playerId.loadout[i].name)
							end
						end
					else
						for i = #args.playerId.loadout, 1, -1 do
							args.playerId.removeWeapon(args.playerId.loadout[i].name)
						end
					end
					TriggerEvent('esx:playerLoadoutCleared', args.playerId)
					if Config.AdminLogging then
						ESX.DiscordLogFields("UserActions", "/clearloadout Triggered!", "pink", {
							{ name = "Player", value = xPlayer.name,       inline = true },
							{ name = "ID",     value = xPlayer.source,     inline = true },
							{ name = "Target", value = args.playerId.name, inline = true },
						})
					end
				end, true, {
					help = TranslateCap('command_clearloadout'),
					validate = true,
					arguments = {
						{ name = 'playerId', help = TranslateCap('commandgeneric_playerid'), type = 'player' }
					}
				})
			else
				print(('[^3WARNING^7] %s^7'):format("Commande ^5clearloadout^0 in config is ^1not active^0."))
			end
		else
			print(('[^3WARNING^7] %s^7'):format("Commande ^5clearloadout^0 in config is ^1nil^0."))
		end
	end

	if Config.Commands["save"] ~= nil then
		if Config.Commands["save"].Active then
			local Command = Config.Commands["save"]
			ESX.RegisterCommand(Command.Command, Command.Group, function(_, args)
				Core.SavePlayer(args.playerId)
				print(('[^2Info^0] Saved Player - ^5%s^0'):format(args.playerId.source))
			end, true, {
				help = TranslateCap('command_save'),
				validate = true,
				arguments = {
					{ name = 'playerId', help = TranslateCap('commandgeneric_playerid'), type = 'player' }
				}
			})
		else
			print(('[^3WARNING^7] %s^7'):format("Commande ^5save^0 in config is ^1not active^0."))
		end
	else
		print(('[^3WARNING^7] %s^7'):format("Commande ^5save^0 in config is ^1nil^0."))
	end

	if Config.Commands["saveall"] ~= nil then
		if Config.Commands["saveall"].Active then
			local Command = Config.Commands["saveall"]
			ESX.RegisterCommand(Command.Command, Command.Group, function()
				Core.SavePlayers()
			end, true, { help = TranslateCap('command_saveall') })
		else
			print(('[^3WARNING^7] %s^7'):format("Commande ^5saveall^0 in config is ^1not active^0."))
		end
	else
		print(('[^3WARNING^7] %s^7'):format("Commande ^5saveall^0 in config is ^1nil^0."))
	end

	if Config.Commands["tpm"] ~= nil then
		if Config.Commands["tpm"].Active then
			local Command = Config.Commands["tpm"]
			ESX.RegisterCommand(Command.Command, Command.Group, function(xPlayer)
				xPlayer.triggerEvent("esx:tpm")
				if Config.AdminLogging then
					ESX.DiscordLogFields("UserActions", "Admin Teleport /tpm Triggered!", "pink", {
						{ name = "Player", value = xPlayer.name,   inline = true },
						{ name = "ID",     value = xPlayer.source, inline = true },
					})
				end
			end, false)
		else
			print(('[^3WARNING^7] %s^7'):format("Commande ^5tpm^0 in config is ^1not active^0."))
		end
	else
		print(('[^3WARNING^7] %s^7'):format("Commande ^5tpm^0 in config is ^1nil^0."))
	end

	if Config.Commands["goto"] ~= nil then
		if Config.Commands["goto"].Active then
			local Command = Config.Commands["goto"]
			ESX.RegisterCommand(Command.Command, Command.Group, function(xPlayer, args)
				local xTarget = args.playerId
				if (xPlayer.getGroup() == "mod" and (xTarget.getGroup() == "admin" or xTarget.getGroup() == "superadmin" or xTarget.getGroup() == "_dev")) or (xPlayer.getGroup() == "admin" and (xTarget.getGroup() == "superadmin" or xTarget.getGroup() == "_dev")) or (xPlayer.getGroup() == "superadmin" and xTarget.getGroup() == "_dev") then
					print("Vous ne pouvez pas faire ceci sur une personne avec un group plus élevé que vous.")
					return
				end

				local targetCoords = args.playerId.getCoords()
				xPlayer.setCoords(targetCoords)
				if Config.AdminLogging then
					ESX.DiscordLogFields("UserActions", "Admin Teleport /goto Triggered!", "pink", {
						{ name = "Player",        value = xPlayer.name,       inline = true },
						{ name = "ID",            value = xPlayer.source,     inline = true },
						{ name = "Target",        value = args.playerId.name, inline = true },
						{ name = "Target Coords", value = targetCoords,       inline = true },
					})
				end
			end, false, {
				help = TranslateCap('command_goto'),
				validate = true,
				arguments = {
					{ name = 'playerId', help = TranslateCap('commandgeneric_playerid'), type = 'player' }
				}
			})
		else
			print(('[^3WARNING^7] %s^7'):format("Commande ^5goto^0 in config is ^1not active^0."))
		end
	else
		print(('[^3WARNING^7] %s^7'):format("Commande ^5goto^0 in config is ^1nil^0."))
	end

	if Config.Commands["bring"] ~= nil then
		if Config.Commands["bring"].Active then
			local Command = Config.Commands["bring"]
			ESX.RegisterCommand(Command.Command, Command.Group, function(xPlayer, args)
				local xTarget = args.playerId
				if (xPlayer.getGroup() == "mod" and (xTarget.getGroup() == "admin" or xTarget.getGroup() == "superadmin" or xTarget.getGroup() == "_dev")) or (xPlayer.getGroup() == "admin" and (xTarget.getGroup() == "superadmin" or xTarget.getGroup() == "_dev")) or (xPlayer.getGroup() == "superadmin" and xTarget.getGroup() == "_dev") then
					print("Vous ne pouvez pas faire ceci sur une personne avec un group plus élevé que vous.")
					return
				end

				local targetCoords = args.playerId.getCoords()
				local playerCoords = xPlayer.getCoords()
				args.playerId.setCoords(playerCoords)
				if Config.AdminLogging then
					ESX.DiscordLogFields("UserActions", "Admin Teleport /bring Triggered!", "pink", {
						{ name = "Player",        value = xPlayer.name,       inline = true },
						{ name = "ID",            value = xPlayer.source,     inline = true },
						{ name = "Target",        value = args.playerId.name, inline = true },
						{ name = "Target Coords", value = targetCoords,       inline = true },
					})
				end
			end, false, {
				help = TranslateCap('command_bring'),
				validate = true,
				arguments = {
					{ name = 'playerId', help = TranslateCap('commandgeneric_playerid'), type = 'player' }
				}
			})
		else
			print(('[^3WARNING^7] %s^7'):format("Commande ^5bring^0 in config is ^1not active^0."))
		end
	else
		print(('[^3WARNING^7] %s^7'):format("Commande ^5bring^0 in config is ^1nil^0."))
	end

	if Config.Commands["kill"] ~= nil then
		if Config.Commands["kill"].Active then
			local Command = Config.Commands["kill"]
			ESX.RegisterCommand(Command.Command, Command.Group, function(xPlayer, args)
				local xTarget = args.playerId
				if (xPlayer.getGroup() == "mod" and (xTarget.getGroup() == "admin" or xTarget.getGroup() == "superadmin" or xTarget.getGroup() == "_dev")) or (xPlayer.getGroup() == "admin" and (xTarget.getGroup() == "superadmin" or xTarget.getGroup() == "_dev")) or (xPlayer.getGroup() == "superadmin" and xTarget.getGroup() == "_dev") then
					print("Vous ne pouvez pas faire ceci sur une personne avec un group plus élevé que vous.")
					return
				end

				args.playerId.triggerEvent("esx:killPlayer")
				if Config.AdminLogging then
					ESX.DiscordLogFields("UserActions", "Kill Command /kill Triggered!", "pink", {
						{ name = "Player", value = xPlayer.name,       inline = true },
						{ name = "ID",     value = xPlayer.source,     inline = true },
						{ name = "Target", value = args.playerId.name, inline = true },
					})
				end
			end, true, {
				help = TranslateCap('command_kill'),
				validate = true,
				arguments = {
					{ name = 'playerId', help = TranslateCap('commandgeneric_playerid'), type = 'player' }
				}
			})
		else
			print(('[^3WARNING^7] %s^7'):format("Commande ^5kill^0 in config is ^1not active^0."))
		end
	else
		print(('[^3WARNING^7] %s^7'):format("Commande ^5kill^0 in config is ^1nil^0."))
	end

	if Config.Commands["freeze"] ~= nil then
		if Config.Commands["freeze"].Active then
			local Command = Config.Commands["freeze"]
			ESX.RegisterCommand(Command.Command, Command.Group, function(xPlayer, args)
				local xTarget = args.playerId
				if (xPlayer.getGroup() == "mod" and (xTarget.getGroup() == "admin" or xTarget.getGroup() == "superadmin" or xTarget.getGroup() == "_dev")) or (xPlayer.getGroup() == "admin" and (xTarget.getGroup() == "superadmin" or xTarget.getGroup() == "_dev")) or (xPlayer.getGroup() == "superadmin" and xTarget.getGroup() == "_dev") then
					print("Vous ne pouvez pas faire ceci sur une personne avec un group plus élevé que vous.")
					return
				end

				args.playerId.triggerEvent('esx:freezePlayer', "freeze")
				if Config.AdminLogging then
					ESX.DiscordLogFields("UserActions", "Admin Freeze /freeze Triggered!", "pink", {
						{ name = "Player", value = xPlayer.name,       inline = true },
						{ name = "ID",     value = xPlayer.source,     inline = true },
						{ name = "Target", value = args.playerId.name, inline = true },
					})
				end
			end, true, {
				help = TranslateCap('command_freeze'),
				validate = true,
				arguments = {
					{ name = 'playerId', help = TranslateCap('commandgeneric_playerid'), type = 'player' }
				}
			})
		else
			print(('[^3WARNING^7] %s^7'):format("Commande ^5freeze^0 in config is ^1not active^0."))
		end
	else
		print(('[^3WARNING^7] %s^7'):format("Commande ^5freeze^0 in config is ^1nil^0."))
	end

	if Config.Commands["unfreeze"] ~= nil then
		if Config.Commands["unfreeze"].Active then
			local Command = Config.Commands["unfreeze"]
			ESX.RegisterCommand(Command.Command, Command.Group, function(xPlayer, args)
				local xTarget = args.playerId
				if (xPlayer.getGroup() == "mod" and (xTarget.getGroup() == "admin" or xTarget.getGroup() == "superadmin" or xTarget.getGroup() == "_dev")) or (xPlayer.getGroup() == "admin" and (xTarget.getGroup() == "superadmin" or xTarget.getGroup() == "_dev")) or (xPlayer.getGroup() == "superadmin" and xTarget.getGroup() == "_dev") then
					print("Vous ne pouvez pas faire ceci sur une personne avec un group plus élevé que vous.")
					return
				end

				args.playerId.triggerEvent('esx:freezePlayer', "unfreeze")
				if Config.AdminLogging then
					ESX.DiscordLogFields("UserActions", "Admin UnFreeze /unfreeze Triggered!", "pink", {
						{ name = "Player", value = xPlayer.name,       inline = true },
						{ name = "ID",     value = xPlayer.source,     inline = true },
						{ name = "Target", value = args.playerId.name, inline = true },
					})
				end
			end, true, {
				help = TranslateCap('command_unfreeze'),
				validate = true,
				arguments = {
					{ name = 'playerId', help = TranslateCap('commandgeneric_playerid'), type = 'player' }
				}
			})
		else
			print(('[^3WARNING^7] %s^7'):format("Commande ^5unfreeze^0 in config is ^1not active^0."))
		end
	else
		print(('[^3WARNING^7] %s^7'):format("Commande ^5unfreeze^0 in config is ^1nil^0."))
	end

	--[[--Commande inutile !
	ESX.RegisterCommand({ 'clear', 'cls' }, {'user', 'admin', 'superadmin', "_dev"}, function(xPlayer)
		xPlayer.triggerEvent('Chat:clear')
	end, false, { help = TranslateCap('command_clear') })

	ESX.RegisterCommand({ 'clearall', 'clsall' }, {'superadmin', "_dev"}, function(xPlayer)
		TriggerClientEvent('Chat:clear', -1)
		if Config.AdminLogging then
			ESX.DiscordLogFields("UserActions", "Clear Chat /clearall Triggered!", "pink", {
				{ name = "Player", value = xPlayer.name,   inline = true },
				{ name = "ID",     value = xPlayer.source, inline = true },
			})
		end
	end, true, { help = TranslateCap('command_clearall') })

	ESX.RegisterCommand('group', {'user', 'admin', 'superadmin', "_dev"}, function(xPlayer, _, _)
		print(('%s, you are currently: ^5%s^0'):format(xPlayer.getName(), xPlayer.getGroup()))
	end, false)

	ESX.RegisterCommand('job', {'user', 'admin', 'superadmin', "_dev"}, function(xPlayer, _, _)
		print(('%s, your job is: ^5%s^0 - ^5%s^0'):format(xPlayer.getName(), xPlayer.getJob().name, xPlayer.getJob().grade_label))
	end, false)

	ESX.RegisterCommand('job2', {'user', 'admin', 'superadmin', "_dev"}, function(xPlayer, _, _)
		print(('%s, your second job is: ^5%s^0 - ^5%s^0'):format(xPlayer.getName(), xPlayer.getJob2().name, xPlayer.getJob2().grade_label))
	end, false)

	ESX.RegisterCommand('info', {'user', 'admin', 'superadmin', "_dev"}, function(xPlayer)
		local job = xPlayer.getJob().name
		local jobgrade = xPlayer.getJob().grade_name
		print(('^2ID: ^5%s^0 | ^2Name: ^5%s^0 | ^2Group: ^5%s^0 | ^2Job: ^5%s^0'):format(xPlayer.source, xPlayer.getName(), xPlayer.getGroup(), job))
	end, false)

	ESX.RegisterCommand('coords', {'admin', 'superadmin', "_dev"}, function(xPlayer)
		local ped = GetPlayerPed(xPlayer.source)
		local coords = GetEntityCoords(ped, false)
		local heading = GetEntityHeading(ped)
		print(('Coords - Vector3: ^5%s^0'):format(vector3(coords.x, coords.y, coords.z)))
		print(('Coords - Vector4: ^5%s^0'):format(vector4(coords.x, coords.y, coords.z, heading)))
	end, false)

	ESX.RegisterCommand("noclip", {'admin', 'superadmin', "_dev"}, function(xPlayer)
		xPlayer.triggerEvent('esx:noclip')
		if Config.AdminLogging then
			ESX.DiscordLogFields("UserActions", "Admin NoClip /noclip Triggered!", "pink", {
				{ name = "Player", value = xPlayer.name,   inline = true },
				{ name = "ID",     value = xPlayer.source, inline = true },
			})
		end
	end, false)

	ESX.RegisterCommand('players', {'admin', 'superadmin', "_dev"}, function()
		local xPlayers = ESX.GetExtendedPlayers() -- Returns all xPlayers
		print(('^5%s^2 online player(s)^0'):format(#xPlayers))
		for i = 1, #(xPlayers) do
			local xPlayer = xPlayers[i]
			print(('^1[^2ID: ^5%s^0 | ^2Name : ^5%s^0 | ^2Group : ^5%s^0 | ^2Identifier : ^5%s^1]^0\n'):format(xPlayer.source, xPlayer.getName(), xPlayer.getGroup(), xPlayer.identifier))
		end
	end, true)
	]]--
else
	print(('[^3WARNING^7] %s^7'):format("Commande: ^5Config.Commands^0 in config is ^1nil^0."))
end