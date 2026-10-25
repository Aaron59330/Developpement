fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_keybinds'
description 'Mes touches : liste en direct des raccourcis de la base avec la touche RÉELLEMENT attribuée au joueur, détection des conflits, aide pour les modifier'
version '1.0.0'

shared_script 'config.lua'
client_script 'client/main.lua'

ui_page 'html/index.html'
files { 'html/index.html', 'html/style.css', 'html/script.js' }

exports { 'GetKey', 'GetConflicts' }
