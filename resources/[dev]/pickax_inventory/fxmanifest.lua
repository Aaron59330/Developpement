fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_inventory'
description 'Interface d inventaire (équipement, inventaire, sac, raccourcis, aperçu) branchée sur ox_inventory'
version '1.0.0'

shared_script 'config.lua'
server_script 'server/main.lua'
client_script 'client/main.lua'

ui_page 'html/index.html'
files { 'html/index.html', 'html/fonts.css', 'html/style.css', 'html/script.js', 'html/fonts/*' }

dependencies { 'es_extended', 'ox_inventory' }
