fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_mapgroups'
description 'Blips de même nom regroupés en un seul (← → sur la carte pour passer d\'un lieu à l\'autre) + fiche du lieu (image, description) affichée en haut à gauche'
version '1.0.0'

client_scripts { 'client.lua' }

ui_page 'html/index.html'
files { 'html/index.html', 'html/style.css', 'html/script.js', 'html/places/**/*' }   -- images des lieux : html/places/<fichier>

