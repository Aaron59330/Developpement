fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_casino'
description 'Casino complet : caisse (achat / rachat de jetons), machines à sous, blackjack et roulette ; tout le hasard est tiré côté serveur'
version '1.0.0'

shared_scripts { 'config.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/games.lua', 'server/main.lua' }
client_scripts { 'client/main.lua' }

ui_page 'html/index.html'
files { 'html/index.html', 'html/style.css', 'html/script.js' }

dependencies { 'es_extended', 'oxmysql', 'pickax_worldbuilder' }
