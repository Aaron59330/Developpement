fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_hub'
description 'Menu personnel central (touche F5) en interface moderne : informations, factures, documents, véhicule, préférences, touches, commandes — reprend les fonctions du menu de base'
version '2.0.0'

shared_scripts { 'pk_theme.lua', 'config.lua' }
client_scripts { 'client/main.lua' }

ui_page 'html/index.html'
files { 'html/index.html', 'html/style.css', 'html/script.js' }

dependencies { 'es_extended', 'pickax_theme' }
