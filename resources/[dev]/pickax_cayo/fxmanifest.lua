fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_cayo'
description 'Braquage de Cayo Perico : tablette de planification (cible, approche, équipement, équipe), préparatifs, île avec gardes, butin, fuite et partage'
version '1.0.0'

shared_script 'config.lua'
server_script 'server/main.lua'
client_scripts { 'client/main.lua', 'client/island.lua' }

ui_page 'html/index.html'
files { 'html/index.html', 'html/fonts.css', 'html/style.css', 'html/script.js', 'html/fonts/*' }

dependencies { 'es_extended', 'ox_inventory' }
