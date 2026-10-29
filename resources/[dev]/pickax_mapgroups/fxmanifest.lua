fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_mapgroups'
description 'Blips de même nom : chaque lieu garde son blip, ← → sur la carte les sélectionnent l\'un après l\'autre (blip agrandi + fiche : image, description) ; fiche affichée en haut à gauche'
version '1.0.0'

client_scripts { 'client.lua' }

ui_page 'html/index.html'
files { 'html/index.html', 'html/style.css', 'html/script.js', 'html/places/**/*' }   -- images des lieux : html/places/<fichier>

