fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_panel'
description 'Agent de liaison avec le panel web de configuration (clé unique dans server.cfg)'
version '2.0.0'

client_scripts {
    'client.lua',
}

server_scripts {
    'lib/patcher.lua',
    'schema.lua',
    'server.lua',
}
