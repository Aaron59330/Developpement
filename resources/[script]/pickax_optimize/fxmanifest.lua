fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_optimize'
description 'Optimisation de la base : index SQL automatiques, purge des journaux, cache mémoire partagé, diagnostic (/pickaxdoctor)'
version '1.0.0'

server_scripts { '@oxmysql/lib/MySQL.lua', 'config.lua', 'server/cache.lua', 'server/main.lua' }
dependencies { 'oxmysql' }
