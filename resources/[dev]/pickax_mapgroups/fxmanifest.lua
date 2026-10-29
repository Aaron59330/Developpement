fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_mapgroups'
description 'Fiche d\'un lieu (image + description saisies dans le builder) affichée en haut à gauche quand on sélectionne son blip sur la carte ; les lieux de même nom partagent la même fiche'
version '1.0.0'

client_scripts { 'client.lua' }

ui_page 'html/index.html'
files { 'html/index.html', 'html/style.css', 'html/script.js', 'html/places/**/*' }   -- images des lieux : html/places/<fichier>

