fx_version 'cerulean'
game 'gta5'

author 'Base Surge Studio'
description 'Puff Bar : prop, animations, LED et fumee blanche jet avant'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/contracts.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

dependencies {
    'ox_lib',
    'ox_inventory',
    '/onesync'
}

files {
    'stream/surge_razzbar_prop.ytyp',
    'stream/surge_puff_led.ytyp'
}

data_file 'DLC_ITYP_REQUEST' 'stream/surge_razzbar_prop.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/surge_puff_led.ytyp'
