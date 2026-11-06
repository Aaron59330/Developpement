fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_context'
description 'Menu contextuel du joueur (style ox_lib) : sous-menus en cascade à côté du personnage, avec uniquement les systèmes du serveur'
version '1.0.0'

shared_script 'config.lua'
client_script 'client/main.lua'

ui_page 'html/index.html'
files { 'html/index.html', 'html/fonts.css', 'html/style.css', 'html/script.js', 'html/fonts/*' }
