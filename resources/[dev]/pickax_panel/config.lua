Config = {}

-- Dans server.cfg :
--   set aero_panel_url "https://panel.mondomaine.fr"
--   set aero_panel_key "AERO-XXXXXX-XXXXXX-XXXXXX-XXXXXX"
Config.Interval        = 10        -- secondes entre deux échanges avec le panel (le panel peut l'imposer)
Config.ResourcesEvery  = 60        -- secondes entre deux envois de la liste des ressources
Config.Timeout         = 8000      -- délai maximum d'une requête (ms)

-- Licence : si le panel dit « invalide » (expirée, suspendue…), ou est injoignable depuis plus de GraceHours,
-- les ressources de StopResources sont arrêtées. Laisse Enforce = false sur TON serveur ; mets true chez un client.
Config.Enforce         = false
Config.GraceHours      = 72
Config.StopResources   = { 'pickax_core', 'pickax_jobbuilder', 'pickax_gangbuilder', 'pickax_illegalbuilder', 'pickax_shopbuilder', 'pickax_worldbuilder' }

-- Ressources que le panel a le droit de redémarrer (vide = toutes sauf celles de Protected)
Config.RestartAllow    = {}
Config.Protected       = { 'pickax_panel', 'oxmysql', 'ox_lib', 'es_extended', 'monitor', 'txAdmin' }

-- Lien du chat pour les annonces : événement client qui affiche un texte (laisse tel quel avec pickax_notify)
Config.AnnounceTitle   = 'Annonce'

-- Éditeur de fichiers du panel (fs/main.js) : lecture/écriture limitées au dossier resources/ (pickax_panel exclu)
Config.AllowFiles       = true     -- false = l'éditeur de fichiers du panel est désactivé sur ce serveur
Config.CheckLuaSyntax   = true     -- refuse d'enregistrer un .lua qui ne compile pas (évite de casser une ressource)

-- Console du panel : seules ces commandes (premier mot) sont autorisées
Config.AllowConsole     = true
Config.ConsoleAllowed   = { 'ensure', 'restart', 'start', 'stop', 'refresh', 'say', 'status', 'players' }
Config.RestartDelay     = 30       -- secondes de préavis avant « Redémarrer le serveur » (annonce aux joueurs)
