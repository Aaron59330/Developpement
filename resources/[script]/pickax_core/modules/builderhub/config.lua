Config = {}

Config.Command        = 'builders'                        -- /builders ouvre le panel
Config.OpenKey        = false                             -- touche pour l'ouvrir sans commande (ex : 'F10')
Config.AllowedGroups  = { '_dev', 'admin', 'superadmin' } -- groupes ESX autorisés
Config.AcePermission  = 'builderhub.admin'                -- (optionnel) permission ACE alternative

-- Les builders affichés. `command` = la commande qui ouvre le builder (celle de son config.lua).
-- `stats` = { libellé, table SQL } : compteur affiché sur la carte (ignoré si la table n'existe pas).
Config.Builders = {
    {
        id = 'jobbuilder', resource = 'pickax_core', command = 'jobbuilder', icon = 'job',
        label = 'Job Builder',
        desc = 'Crée métiers, grades, points, coffres, véhicules, missions, annonces et comptes société.',
        stats = { { 'Métiers', 'jobbuilder_jobs' }, { 'Points', 'jobbuilder_points' }, { 'Propriétés', 'jobbuilder_properties' } },
    },
    {
        id = 'gangbuilder', resource = 'pickax_core', command = 'gangbuilder', icon = 'gang',
        label = 'Gang Builder',
        desc = 'Crée gangs, territoires, points, réputation, trésorerie et règles de guerre.',
        stats = { { 'Gangs', 'gangbuilder_gangs' }, { 'Territoires', 'gangbuilder_territories' }, { 'Points', 'gangbuilder_points' } },
    },
    {
        id = 'shopbuilder', resource = 'pickax_core', command = 'shopbuilder', icon = 'shop',
        label = 'Shop Builder',
        desc = 'Crée des boutiques, leurs articles, prix, stocks et horaires.',
        stats = { { 'Boutiques', 'shopbuilder_shops' }, { 'Logs', 'shopbuilder_logs' } },
    },
    {
        id = 'worldbuilder', resource = 'pickax_core', command = 'worldbuilder', icon = 'world',
        label = 'World Builder',
        desc = 'Garages, fourrières, locations, stations, drogues, braquages, portes et zones PVP.',
        stats = { { 'Éléments', 'worldbuilder_entities' }, { 'Fourrière', 'worldbuilder_impound' }, { 'Logs', 'worldbuilder_logs' } },
    },
}
