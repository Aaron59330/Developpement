fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_medical'
description 'EMS avancé : blessures par zone, saignements, soins (bandage, suture, attelle, chirurgie), RCR, dossier médical, groupe sanguin / transfusion, triage'
version '1.0.0'

shared_scripts { '@ox_lib/init.lua', 'config.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/main.lua' }
client_scripts { 'client/main.lua' }

ui_page 'html/index.html'
files { 'html/index.html', 'html/style.css', 'html/script.js' }

dependencies { 'es_extended', 'oxmysql', 'ox_lib', 'ox_inventory', 'pickax_skillgames' }
