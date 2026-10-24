Config = {}

Config.Command        = 'builders'                        -- /builders ouvre le panel
Config.OpenKey        = false                             -- touche pour l'ouvrir sans commande (ex : 'F10')
Config.AllowedGroups  = { '_dev', 'admin', 'superadmin' } -- groupes ESX autorisés
Config.AcePermission  = 'builderhub.admin'                -- (optionnel) permission ACE alternative

-- Les builders affichés. `command` = la commande qui ouvre le builder (celle de son config.lua).
-- `stats` = { libellé, table SQL } : compteur affiché sur la carte (ignoré si la table n'existe pas).
Config.Builders = {
    {
        id = 'jobbuilder', resource = 'pickax_jobbuilder', command = 'jobbuilder', icon = 'job',
        label = 'Job Builder',
        desc = 'Crée métiers, grades, points, coffres, véhicules, missions, annonces et comptes société.',
        stats = { { 'Métiers', 'jobbuilder_jobs' }, { 'Points', 'jobbuilder_points' }, { 'Propriétés', 'jobbuilder_properties' } },
    },
    {
        id = 'gangbuilder', resource = 'pickax_gangbuilder', command = 'gangbuilder', icon = 'gang',
        label = 'Gang Builder',
        desc = 'Crée gangs, territoires, points, réputation, trésorerie et règles de guerre.',
        stats = { { 'Gangs', 'gangbuilder_gangs' }, { 'Territoires', 'gangbuilder_territories' }, { 'Points', 'gangbuilder_points' } },
    },
    {
        id = 'shopbuilder', resource = 'pickax_shopbuilder', command = 'shopbuilder', icon = 'shop',
        label = 'Shop Builder',
        desc = 'Crée des boutiques, leurs articles, prix, stocks et horaires.',
        stats = { { 'Boutiques', 'shopbuilder_shops' }, { 'Logs', 'shopbuilder_logs' } },
    },
    {
        id = 'eventbuilder', resource = 'pickax_eventbuilder', command = 'eventbuilder', icon = 'event',
        label = 'Event Builder',
        desc = 'Braquages de fourgon, largages, commerces, épaves, livraisons et zones : crée et lance des événements en jeu.',
        stats = { { 'Événements', 'eventbuilder_events' }, { 'Historique', 'eventbuilder_logs' } },
    },
    {
        id = 'minigames', resource = 'pickax_minigames', command = 'minigames', icon = 'minigames',
        label = 'Mini-jeux Builder',
        desc = 'Basket, football, tennis, boxe, paintball, laser game, courses : crée des mini-jeux avec lobby, scores, récompenses et classements.',
        stats = { { 'Mini-jeux', 'minigames_defs' }, { 'Joueurs classés', 'minigames_stats' }, { 'Historique', 'minigames_logs' } },
    },
    {
        id = 'worldbuilder', resource = 'pickax_worldbuilder', command = 'worldbuilder', icon = 'world',
        label = 'World Builder',
        desc = 'Garages, fourrières, locations, stations, banques, portes, zones PVP et courses poursuites.',
        stats = { { 'Éléments', 'worldbuilder_entities' }, { 'Fourrière', 'worldbuilder_impound' }, { 'Logs', 'worldbuilder_logs' } },
    },
    {
        id = 'illegalbuilder', resource = 'pickax_illegalbuilder', command = 'illegalbuilder', icon = 'gang',
        label = 'Builder Illégal',
        desc = 'Drogues, braquages et Go Fast : crée les activités illégales du serveur.',
        stats = { { 'Modules', 'illegalbuilder_entities' }, { 'Logs', 'illegalbuilder_logs' } },
    },
}
