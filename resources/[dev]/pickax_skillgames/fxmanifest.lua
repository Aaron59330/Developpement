fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_skillgames'
description 'Interface commune (menus, formulaires, confirmations, progression) et bibliothèque de mini-jeux : crochetage, piratage, RCR, suture, bandage, cuisson, pêche, faux papiers… ; ui.lua remplace les interfaces d'ox_lib'
version '1.0.0'

shared_scripts { 'config.lua' }
client_scripts { 'client/main.lua' }
ui_page 'html/index.html'
files { 'html/index.html', 'html/style.css', 'html/script.js' }
