fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_xp'
description 'Niveaux et expérience des joueurs : chaque action du serveur (achats, métiers, cuisine, mécanique, soins…) rapporte de l\'XP ; des paliers débloquent des récompenses'
version '1.0.0'

shared_scripts { '@pickax_theme/theme.lua', 'config.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/main.lua' }
client_scripts { 'client/main.lua' }

ui_page 'html/index.html'
files { 'html/index.html', 'html/style.css', 'html/script.js' }

dependencies { 'pickax_theme', 'es_extended', 'oxmysql' }
