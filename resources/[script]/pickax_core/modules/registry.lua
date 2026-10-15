-- Modules intégrés à pickax_core (ex-ressources autonomes). Chaque module garde ses fichiers et son ORDRE de chargement d'origine.
-- Les entrées « @… » des anciens fxmanifest (oxmysql, ox_lib…) sont déjà chargées par le manifest du core.
--   shared : exécutés des deux côtés avant les scripts client / serveur
--   ui     : page du module, affichée dans un cadre du hub NUI (modules/_hub) — nil si le module n'a pas d'interface
return {
    { name = 'builderhub', shared = { 'config.lua' }, server = { 'server.lua' }, client = { 'client.lua' }, ui = 'html/index.html' },

    { name = 'jobbuilder', shared = { 'config.lua' }, ui = 'html/index.html',
      server = { 'server/notify.lua', 'server/core.lua', 'server/builder.lua', 'server/runtime.lua', 'server/property.lua', 'server/settings.lua', 'server/dealer.lua',
                 'server/gov.lua', 'server/missions.lua', 'server/kitchen.lua', 'server/tablet.lua', 'server/tuning.lua', 'server/death.lua', 'server/emstablet.lua',
                 'server/bank.lua', 'server/announce.lua', 'server/compat.lua' },
      client = { 'client/notify.lua', 'client/bb_map.lua', 'client/main.lua', 'client/actions.lua', 'client/property.lua', 'client/dealer.lua', 'client/gov.lua',
                 'client/missions.lua', 'client/kitchen.lua', 'client/tablet.lua', 'client/tuning.lua', 'client/death.lua', 'client/emstablet.lua', 'client/bank.lua' } },

    { name = 'gangbuilder', shared = { 'config.lua' }, ui = 'html/index.html',
      server = { 'server/core.lua', 'server/job2.lua', 'server/builder.lua', 'server/runtime.lua', 'server/activities.lua', 'server/territories.lua',
                 'server/conflicts.lua', 'server/objectives.lua', 'server/tablet.lua', 'server/settings.lua' },
      client = { 'client/bb_map.lua', 'client/main.lua', 'client/actions.lua', 'client/activities.lua', 'client/territories.lua', 'client/conflicts.lua', 'client/objectives.lua' } },

    { name = 'shopbuilder', shared = { 'config.lua' }, ui = 'html/index.html',
      server = { 'server/core.lua', 'server/builder.lua', 'server/shop.lua' },
      client = { 'client/bb_map.lua', 'client/main.lua', 'client/clothing.lua' } },

    { name = 'worldbuilder', shared = { 'config.lua' }, ui = 'html/index.html',
      server = { 'server/core.lua', 'server/builder.lua', 'server/garage.lua', 'server/rental.lua', 'server/bank.lua', 'server/driving.lua', 'server/fuel.lua',
                 'server/carwash.lua', 'server/locksmith.lua', 'server/drugs.lua', 'server/robbery.lua', 'server/doorlock.lua', 'server/carlot.lua', 'server/chase.lua', 'server/pvp.lua' },
      client = { 'client/bb_map.lua', 'client/main.lua', 'client/garage.lua', 'client/rental.lua', 'client/bank.lua', 'client/driving.lua', 'client/fuel.lua',
                 'client/carwash.lua', 'client/locksmith.lua', 'client/drugs.lua', 'client/robbery.lua', 'client/doorlock.lua', 'client/carlot.lua', 'client/chase.lua', 'client/pvp.lua' } },

    { name = 'hud1', shared = { 'config.lua' }, client = { 'client.lua' }, ui = 'index.html' },
    { name = 'hud2', client = { 'client.lua', 'ruidebdv.lua' }, server = { 'pickax.lua' }, ui = 'html/index.html' },
    { name = 'speedometer', client = { 'client/client.lua', 'client/utils.lua' }, ui = 'web/build/index.html' },
    { name = 'pause', shared = { 'config.lua' }, server = { 'server.lua' }, client = { 'client.lua' }, ui = 'html/index.html' },
    { name = 'connectui', shared = { 'config.lua' }, server = { 'server.lua' } },
}
