fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_dialog'
description 'Dialogue de PNJ : le PNJ se tourne vers le joueur et écrit un texte avec un bouton Accepter / Refuser avant d\'ouvrir un service (fourrière, banque, auto-école, marché noir…)'
version '1.0.0'

shared_script 'config.lua'
client_script 'client.lua'

ui_page 'html/index.html'

files { 'html/index.html', 'html/style.css', 'html/script.js', 'html/fonts/*.woff2' }
