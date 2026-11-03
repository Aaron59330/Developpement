fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_life'
description 'Vie quotidienne avec mini-jeux : pêche, chasse, cuisine, taxi et livraison (permis, quotas, revente, pourboire selon la conduite)'
version '1.0.0'

shared_scripts { 'ui.lua', 'config.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/main.lua' }
client_scripts { 'client/main.lua' }

dependencies { 'es_extended', 'oxmysql', 'ox_inventory', 'pickax_skillgames' }
