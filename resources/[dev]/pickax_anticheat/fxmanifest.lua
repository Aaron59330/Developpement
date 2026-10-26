fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_anticheat'
description 'Anti-cheat Pickax : détections côté serveur (OneSync), scores par module, panneau de gestion en jeu (joueurs, bans, détections, règles), sans faux bans par conception'
version '1.0.0'

shared_scripts { 'pk_theme.lua', 'config.lua' }

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/core.lua',
    'server/detect.lua',
    'server/panel.lua',
}

client_scripts { 'client/main.lua' }

ui_page 'html/index.html'

files { 'html/index.html', 'html/style.css', 'html/script.js', 'html/bb-ui.js' }

exports { 'Exempt', 'IsExempt', 'Flag', 'Ban' }

dependencies { 'es_extended', 'oxmysql' }

-- [AERO] protection de la base : cette ressource ne démarre pas sans pickax_guard (licence valide)
dependency 'pickax_guard'
