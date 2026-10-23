fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_hub'
description 'Menu central du serveur : profil, métier, véhicules, activités, téléphone, réglages — une seule touche pour tout'
version '1.0.0'

shared_scripts { '@ox_lib/init.lua', 'pk_theme.lua', 'config.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/main.lua' }
client_scripts { 'client/main.lua' }

ui_page 'html/index.html'
files { 'html/index.html', 'html/style.css', 'html/script.js' }

dependencies { 'es_extended', 'oxmysql', 'ox_lib', 'pickax_theme' }
