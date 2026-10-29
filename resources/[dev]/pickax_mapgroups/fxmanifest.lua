fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_mapgroups'
description 'Blips groupés : plusieurs lieux de même nom = UN seul blip sur la carte (« Garage (2) ») ; sélectionne-le (poser un point dessus) pour choisir le lieu dans une liste'
version '1.0.0'

shared_scripts { '@ox_lib/init.lua' }
client_scripts { 'client.lua' }

ui_page 'html/index.html'
files { 'html/index.html', 'html/style.css', 'html/script.js', 'html/places/**/*' }   -- images des lieux : html/places/<fichier>

dependencies { 'ox_lib' }
