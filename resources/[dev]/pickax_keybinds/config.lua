Config = {}

Config.Command = 'touches'      -- commande qui ouvre le menu « Mes touches » (aucune touche par défaut : évite un conflit de plus)

-- Raccourcis de la base. cmd = nom EXACT passé à RegisterKeyMapping (avec le « + » éventuel) ; default = touche par défaut annoncée.
-- Ajoute une ligne pour chaque nouveau raccourci : le menu lit la touche réellement attribuée au joueur dans FiveM.
Config.Actions = {
    { group = 'Général',    label = 'Téléphone',                   cmd = 'phone',            default = 'F1' },
    { group = 'Général',    label = 'Menu boutique',               cmd = 'menuboutique',     default = 'F1' },
    { group = 'Général',    label = 'Menu personnel',              cmd = 'menuF5',           default = 'F5' },
    { group = 'Général',    label = 'Carnet (objectifs et série)', cmd = 'carnet',          default = 'F3' },
    { group = 'Général',    label = 'Mode caméra',                 cmd = 'cam',              default = 'F4' },
    { group = 'Général',    label = 'Radio',                       cmd = 'MenuRadio',        default = 'F9' },
    { group = 'Général',    label = 'Menu emotes',                 cmd = 'emoteui',          default = 'K' },
    { group = 'Général',    label = 'Annuler l\'emote',            cmd = 'emotecancel',      default = 'X' },
    { group = 'Général',    label = 'Mains en l\'air',             cmd = 'handsup',          default = 'GRAVE' },
    { group = 'Général',    label = 'Pointer du doigt',            cmd = 'pointing',         default = 'B' },
    { group = 'Général',    label = 'S\'endormir / se réveiller',  cmd = 'ragdoll',          default = 'I' },
    { group = 'Général',    label = 'Afficher / cacher l\'argent', cmd = 'hidehud',          default = 'W' },
    { group = 'Métiers',    label = 'Menu du métier',              cmd = 'jobmenu',          default = 'F6' },
    { group = 'Métiers',    label = 'EMS : prendre le dernier appel', cmd = 'jbems_accept',  default = 'Y' },
    { group = 'Métiers',    label = 'Meubles / laboratoire',       cmd = 'decorer',          default = 'F10' },
    { group = 'Gang',       label = 'Menu du gang',                cmd = 'gangmenu',         default = 'F7' },
    { group = 'Véhicule',   label = 'Menu des clés',               cmd = 'MenuClef',         default = 'G' },
    { group = 'Véhicule',   label = 'Ouvrir / fermer le véhicule', cmd = 'OpenCloseVehicle', default = 'U' },
    { group = 'Véhicule',   label = 'Coffre du véhicule',          cmd = 'coffre',           default = 'L' },
    { group = 'Monde',      label = 'Verrouiller une porte',       cmd = 'lockdoor',         default = 'E' },
    { group = 'Monde',      label = 'Porte proche (World Builder)', cmd = 'wbdoor',          default = 'E' },
    { group = 'Équipe',     label = 'Menu admin',                  cmd = 'menuadmin',        default = 'F11' },
    { group = 'Équipe',     label = 'Noclip',                      cmd = 'noclip',           default = 'F2' },
    { group = 'Équipe',     label = 'Panel anti-cheat',            cmd = 'anticheat',        default = '' },
}
