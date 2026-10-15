fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_panel'
description 'Panel web de configuration (loading screen, menus RageUI, HUD, notifications...) relié à la base de données'
version '1.0.0'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'lib/patcher.lua',
    'schema.lua',
    'server.lua',
}
