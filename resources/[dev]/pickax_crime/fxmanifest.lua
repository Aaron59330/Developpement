fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_crime'
description 'Illégal avec mini-jeux : crochetage de véhicules, piratage de terminaux, faux papiers (qualité contrôlée), désossage de véhicules et recel'
version '1.0.0'

shared_scripts { '@ox_lib/init.lua', 'config.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/main.lua' }
client_scripts { 'client/main.lua' }

dependencies { 'es_extended', 'oxmysql', 'ox_lib', 'ox_inventory', 'pickax_skillgames' }
