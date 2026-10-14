fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'Pickax'
description 'CorePickax'
version '1.0'

shared_scripts {
    '@es_extended/imports.lua',

    'init/shared/mute.lua',
    'esx/notify.lua',
    'init/shared/init.lua',

    'system/**/config.lua',
    'esx/**/config.lua',
    'functions/config.lua',
    'config.lua',
    'utils/**/config.lua',
    'players/**/config.lua',
    'players/menuemote/animation.lua',
    'jobs/**/config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',

    'config_sv.lua',

    'init/server/sv_initESX.lua',
    'init/server/sv_init.lua',

    'maintenance.lua',

    'system/**/server.lua',
    'esx/**/server.lua',
    'jobs/**/server.lua',
    'functions/server.lua',
    'players/**/server.lua',
    'utils/**/server.lua',

    'players/wipe/function_sv.lua',

    'compat/ox_server.lua'
}

client_scripts {
    -- RageUI
    'menu/RageUI/RMenu.lua',
    'menu/RageUI/menu/RageUI.lua',
    'menu/RageUI/menu/Menu.lua',
    'menu/RageUI/menu/MenuController.lua',
    'menu/RageUI/components/*.lua',
    'menu/RageUI/menu/elements/*.lua',
    'menu/RageUI/menu/items/*.lua',
    'menu/RageUI/menu/panels/*.lua',
    'menu/RageUI/menu/windows/*.lua',
    'menu/RageUI/nui.lua',

    -- Bob74 IPL
    'dlc/bob74_ipl/lib/common.lua',
    'dlc/bob74_ipl/lib/observers/interiorIdObserver.lua',
    'dlc/bob74_ipl/lib/observers/officeSafeDoorHandler.lua',
    'dlc/bob74_ipl/client.lua',

    'dlc/bob74_ipl/gtav/base.lua',
    'dlc/bob74_ipl/gtav/ammunations.lua',
    'dlc/bob74_ipl/gtav/bahama.lua',
    'dlc/bob74_ipl/gtav/floyd.lua',
    'dlc/bob74_ipl/gtav/franklin.lua',
    'dlc/bob74_ipl/gtav/franklin_aunt.lua',
    'dlc/bob74_ipl/gtav/graffitis.lua',
    'dlc/bob74_ipl/gtav/pillbox_hospital.lua',
    'dlc/bob74_ipl/gtav/lester_factory.lua',
    'dlc/bob74_ipl/gtav/michael.lua',
    'dlc/bob74_ipl/gtav/north_yankton.lua',
    'dlc/bob74_ipl/gtav/red_carpet.lua',
    'dlc/bob74_ipl/gtav/simeon.lua',
    'dlc/bob74_ipl/gtav/stripclub.lua',
    'dlc/bob74_ipl/gtav/trevors_trailer.lua',
    'dlc/bob74_ipl/gtav/ufo.lua',
    'dlc/bob74_ipl/gtav/zancudo_gates.lua',

    'dlc/bob74_ipl/gta_online/apartment_hi_1.lua',
    'dlc/bob74_ipl/gta_online/apartment_hi_2.lua',
    'dlc/bob74_ipl/gta_online/house_hi_1.lua',
    'dlc/bob74_ipl/gta_online/house_hi_2.lua',
    'dlc/bob74_ipl/gta_online/house_hi_3.lua',
    'dlc/bob74_ipl/gta_online/house_hi_4.lua',
    'dlc/bob74_ipl/gta_online/house_hi_5.lua',
    'dlc/bob74_ipl/gta_online/house_hi_6.lua',
    'dlc/bob74_ipl/gta_online/house_hi_7.lua',
    'dlc/bob74_ipl/gta_online/house_hi_8.lua',
    'dlc/bob74_ipl/gta_online/house_mid_1.lua',
    'dlc/bob74_ipl/gta_online/house_low_1.lua',

    'dlc/bob74_ipl/dlc_high_life/apartment1.lua',
    'dlc/bob74_ipl/dlc_high_life/apartment2.lua',
    'dlc/bob74_ipl/dlc_high_life/apartment3.lua',
    'dlc/bob74_ipl/dlc_high_life/apartment4.lua',
    'dlc/bob74_ipl/dlc_high_life/apartment5.lua',
    'dlc/bob74_ipl/dlc_high_life/apartment6.lua',

    'dlc/bob74_ipl/dlc_heists/carrier.lua',
    'dlc/bob74_ipl/dlc_heists/yacht.lua',

    'dlc/bob74_ipl/dlc_executive/apartment1.lua',
    'dlc/bob74_ipl/dlc_executive/apartment2.lua',
    'dlc/bob74_ipl/dlc_executive/apartment3.lua',

    'dlc/bob74_ipl/dlc_finance/office1.lua',
    'dlc/bob74_ipl/dlc_finance/office2.lua',
    'dlc/bob74_ipl/dlc_finance/office3.lua',
    'dlc/bob74_ipl/dlc_finance/office4.lua',
    'dlc/bob74_ipl/dlc_finance/organization.lua',

    'dlc/bob74_ipl/dlc_bikers/cocaine.lua',
    'dlc/bob74_ipl/dlc_bikers/counterfeit_cash.lua',
    'dlc/bob74_ipl/dlc_bikers/document_forgery.lua',
    'dlc/bob74_ipl/dlc_bikers/meth.lua',
    'dlc/bob74_ipl/dlc_bikers/weed.lua',
    'dlc/bob74_ipl/dlc_bikers/clubhouse1.lua',
    'dlc/bob74_ipl/dlc_bikers/clubhouse2.lua',
    'dlc/bob74_ipl/dlc_bikers/gang.lua',

    'dlc/bob74_ipl/dlc_import/garage1.lua',
    'dlc/bob74_ipl/dlc_import/garage2.lua',
    'dlc/bob74_ipl/dlc_import/garage3.lua',
    'dlc/bob74_ipl/dlc_import/garage4.lua',
    'dlc/bob74_ipl/dlc_import/vehicle_warehouse.lua',

    'dlc/bob74_ipl/dlc_gunrunning/bunkers.lua',
    'dlc/bob74_ipl/dlc_gunrunning/yacht.lua',

    'dlc/bob74_ipl/dlc_smuggler/hangar.lua',

    'dlc/bob74_ipl/dlc_doomsday/facility.lua',

    'dlc/bob74_ipl/dlc_afterhours/nightclubs.lua',

    'dlc/bob74_ipl/dlc_casino/casino.lua',
    'dlc/bob74_ipl/dlc_casino/penthouse.lua',

    'dlc/bob74_ipl/dlc_tuner/garage.lua',
    'dlc/bob74_ipl/dlc_tuner/meetup.lua',
    'dlc/bob74_ipl/dlc_tuner/methlab.lua',

    'dlc/bob74_ipl/dlc_security/studio.lua',
    'dlc/bob74_ipl/dlc_security/billboards.lua',
    'dlc/bob74_ipl/dlc_security/musicrooftop.lua',
    'dlc/bob74_ipl/dlc_security/garage.lua',
    'dlc/bob74_ipl/dlc_security/office1.lua',
    'dlc/bob74_ipl/dlc_security/office2.lua',
    'dlc/bob74_ipl/dlc_security/office3.lua',
    'dlc/bob74_ipl/dlc_security/office4.lua',

    -- INIT IMPORTANT
    'init/client/cl_initESX.lua',
    'init/client/cl_init.lua',

    -- GLOBAL MARKERS
    'init/client/cl_marker.lua',

    -- CORE CLIENT
    'system/**/client.lua',
    'esx/**/client.lua',
    'functions/client.lua',
    'utils/**/client.lua',

    -- PLAYERS
    'players/**/client.lua',
    'players/contextMenu/function.lua',

    -- JOBS
    'jobs/**/client.lua',

    -- OX INVENTORY
    'compat/ox_client.lua'
}

ui_page 'players/jsfour-idcard/html/index.html'

files {
    'utils/gifMenu/banner.html',
    'players/jsfour-idcard/html/index.html',
    'players/jsfour-idcard/html/assets/css/*.css',
    'players/jsfour-idcard/html/assets/js/*.js',
    'players/jsfour-idcard/html/assets/fonts/*.woff',
    'players/jsfour-idcard/html/assets/fonts/*.woff2',
    'players/jsfour-idcard/html/assets/images/*.png',

    'utils/weapon/weapons.meta'
}

escrow_ignore {
    'config.lua',
    'config_sv.lua',

    'esx/**/config.lua',
    'system/**/config.lua',
    'functions/config.lua',
    'utils/**/config.lua',
    'players/**/config.lua',
    'players/menuemote/animation.lua',
    'players/contextMenu/function.lua',
    'jobs/**/config.lua',

    'players/wipe/function_sv.lua',

    'compat/ox_server.lua',
    'compat/ox_client.lua',

    'init/client/cl_marker.lua'
}

data_file 'WEAPONINFO_FILE_PATCH' 'utils/weapon/weapons.meta'

data_file 'DLC_ITYP_REQUEST' 'stream/loq_atm.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/addon_emotes.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/addon2_props.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/addon3_props.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/apple_1.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/addon4_props.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/addon5_pizzas.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/addon6_props_lollipops.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/ultra_ringcase.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/addon7_props.ytyp'

dependencies {
    'es_extended',
    'oxmysql',
    'ox_lib',
    'ox_inventory',
    'pickax_ui'
}