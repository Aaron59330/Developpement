fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_auction'
description 'Hôtel des ventes : enchères entre joueurs (objets ox_inventory et véhicules), achat immédiat, mise en dépôt sécurisée, remboursement des surenchères, réclamations'
version '1.0.0'

shared_scripts { '@ox_lib/init.lua', 'config.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/main.lua' }
client_scripts { 'client/main.lua' }

ui_page 'html/index.html'
files { 'html/index.html', 'html/style.css', 'html/script.js' }

dependencies { 'oxmysql', 'ox_lib', 'es_extended', 'ox_inventory' }
