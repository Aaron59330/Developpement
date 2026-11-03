fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_mechanic'
description 'Mécanicien réaliste : usure des véhicules, diagnostic, réparations avec mini-jeux et pièces à acheter en magasin (stock limité qui se reconstitue)'
version '1.0.0'

shared_scripts { 'ui.lua', 'config.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/main.lua' }
client_scripts { 'client/main.lua' }

ui_page 'html/index.html'
files { 'html/index.html', 'html/style.css', 'html/script.js' }

dependencies { 'es_extended', 'oxmysql', 'ox_inventory', 'pickax_skillgames' }
