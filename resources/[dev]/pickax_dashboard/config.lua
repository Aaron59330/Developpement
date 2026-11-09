Config = {}

Config.Command = 'tableau'            -- /tableau ouvre le tableau de bord
Config.Key = 'HOME'                   -- touche par défaut (modifiable dans les paramètres FiveM) ; '' = aucune
Config.Lang = 'Français'

-- ═════════════ DONNÉES DU JOUEUR ═════════════
-- Déjà branchés : identité, temps de jeu (compté par cette ressource), factures (table `billing` d'ESX), véhicules (table `owned_vehicles`).
Config.Billing = { Table = 'billing', IdentifierColumn = 'identifier', AmountColumn = 'amount', LabelColumn = 'label' }
Config.Vehicles = { Table = 'owned_vehicles', OwnerColumn = 'owner', StoredColumn = 'stored' }   -- StoredColumn : 1 = rangé, 0 = sorti ; '' = ignoré

-- Données lues dans tes systèmes : niveau et récompenses (pickax_xp), carnet (pickax_carnet), métier et organisation (ESX job / job2).

-- ═════════════ SERVICES (page « Services » et raccourcis du bas) ═════════════
-- Un service n'apparaît que si sa ressource est démarrée. command = commande lancée au clic.
Config.Services = {
    { res = 'pickax_phone',     label = 'Téléphone',        desc = 'Messages, appels, annonces, réseaux.',               icon = 'phone',   command = 'phone' },
    { res = 'pickax_minigames', label = 'Mini-jeux',        desc = 'Ton profil : niveau, défis, succès, classements.',    icon = 'game',    command = 'mgprofil' },
    { res = 'pickax_bourse',    label = 'Bourse',           desc = 'Achète et vends des actions.',                        icon = 'chart',   command = 'bourse' },
    { res = 'pickax_auction',   label = 'Enchères',         desc = 'Véhicules saisis mis aux enchères.',                  icon = 'gavel',   command = 'encheres' },
    { res = 'pickax_carplay',   label = 'CarPlay',          desc = 'Musique et navigation dans ton véhicule.',            icon = 'car',     command = 'carplay' },
    { res = 'pickax_mechanic',  label = 'Mécanique',        desc = 'Diagnostic et réparation du véhicule proche.',        icon = 'tool',    command = 'meca' },
    { res = 'pickax_medical',   label = 'Examen médical',   desc = 'Examen du patient le plus proche.',                   icon = 'heart',   command = 'ems' },
    { res = 'pickax_tutorial',  label = 'Tutoriel',         desc = 'Revois le guide du serveur.',                         icon = 'help',    command = 'tutoriel' },
    { res = 'pickax_keybinds',  label = 'Mes touches',      desc = 'Raccourcis clavier du serveur.',                      icon = 'key',     command = 'touches' },
    { res = 'pickax_compass',   label = 'Boussole',         desc = 'Réglages de la boussole.',                            icon = 'compass', command = 'boussole' },
}
-- Actions de la page « Métier & organisation »
Config.JobActions  = { { label = 'Menu du métier', icon = 'list', command = 'jobmenu' }, { label = 'Décorer ma propriété', icon = 'building', command = 'decorer' } }
Config.GangActions = { { label = 'Menu de l\'organisation', icon = 'list', command = 'gangmenu' }, { label = 'Tablette', icon = 'book', command = 'gangtablet' } }

-- ═════════════ BOUTIQUE ═════════════
-- Rien à régler ici : le catalogue, les prix et les coins viennent de la vraie boutique (pickax_core). « Acheter » lance l'achat de la boutique,
-- « Historique » ouvre la boutique et « Inventaire » ouvre ton inventaire boutique (pickax_inventory).

-- ═════════════ JOURNAL HORS LIGNE ═════════════
-- Autres ressources : exports.pickax_dashboard:AddJournal(identifier, 'texte')  (serveur) -> s'affiche dans Paramètres > Historique > Journal hors ligne.
-- Les sanctions affichées viennent de la table staff_warns (avertissements du menu staff).
