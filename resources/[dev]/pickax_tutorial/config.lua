Config = {}

Config.Command   = 'tutoriel'     -- rouvrir le tutoriel à tout moment
Config.AutoOpen  = true           -- ouvrir automatiquement la première fois (une seule fois par personnage)
Config.Delay     = 6000           -- ms d'attente après le chargement d'un personnage existant
Config.AfterCreationDelay = 4000  -- ms d'attente après la fin de création d'un nouveau personnage (laisse démarrer le choix de destination)
Config.Skippable = true           -- bouton « Passer »

-- Récompense versée UNE fois, à la fin du tutoriel (le serveur vérifie, le client ne décide de rien)
Config.Reward = {
    money = 0,                    -- argent liquide
    bank  = 0,                    -- argent en banque
    items = {},                   -- ex. { { name = 'phone', count = 1 }, { name = 'water', count = 3 } }
}

-- Étapes : icon (emoji), title, text, keys = { { 'F1', 'Téléphone', 'phone' } }, bullets = { '...' }
-- Pour une touche, le 3e élément est la commande du raccourci : si pickax_keybinds tourne, la touche réellement attribuée au joueur remplace la touche par défaut.
-- Modifie librement les textes ; ajoute ou retire des étapes.
Config.Steps = {
    { icon = '👋', title = 'Bienvenue sur {server}', text = 'Ce guide rapide te montre l\'essentiel pour bien démarrer. Il ne dure qu\'une minute et tu pourras le rouvrir avec /{command}.',
      bullets = { 'Roleplay sérieux : joue ton personnage, pas toi', 'Le staff est là pour t\'aider : demande en cas de doute' } },
    { icon = '⌨️', title = 'Les touches à connaître', text = 'Toutes les touches se modifient dans Paramètres FiveM → Touches.',
      keys = { { 'F1', 'Téléphone', 'phone' }, { 'F6', 'Menu de ton métier (en service)', 'jobmenu' }, { 'F7', 'Menu de ton gang', 'gangmenu' }, { 'F10', 'Meubles / laboratoire (dans ta propriété)', 'decorer' }, { 'K', 'Menu des emotes', 'emoteui' }, { 'M', 'Menu pause et carte' } },
      bullets = { 'Les touches affichées sont celles de TON jeu (si pickax_keybinds est démarré) — /touches pour tout voir' } },
    { icon = '📱', title = 'Ton téléphone', text = 'Contacts, messages, banque, annonces, GPS : tout est dans ton téléphone. Pense à le recharger : la batterie baisse quand il est sorti.',
      bullets = { 'Batterie externe ou recharge dans un véhicule', 'Mode avion et ne pas déranger dans les réglages' } },
    { icon = '💼', title = 'Trouver un métier', text = 'Rends-toi au centre pour l\'emploi ou aux entreprises pour postuler. Les métiers actifs (poubelles, dépannage, lavage, routier, fermier, pompier, train) sont accessibles dès le départ.',
      bullets = { 'Repère les blips sur la carte', 'Demande un recrutement aux entreprises whitelist' } },
    { icon = '💶', title = 'Argent & banque', text = 'Ton argent liquide est dans ton inventaire, le reste est en banque. Dans les concessions, tu choisis de payer en liquide ou par banque.',
      bullets = { 'Ne garde pas de grosses sommes sur toi', 'Un compte en banque se gère depuis le téléphone' } },
    { icon = '🏠', title = 'Logement', text = 'Les agents immobiliers vendent et louent des biens. Dans ta propriété tu peux poser des meubles (limite selon ton VIP).' },
    { icon = '📜', title = 'Les règles essentielles', text = 'Respecte ces règles pour que tout le monde profite du serveur.',
      bullets = { 'Pas de RDM / VDM : pas de tuer ni d\'écraser sans raison RP', 'Pas de métagaming ni de powergaming', 'Valorise la vie de ton personnage (FearRP)', 'Le staff a toujours le dernier mot' } },
    { icon = '🚀', title = 'C\'est parti !', text = 'Besoin d\'aide ? Demande à un joueur, ouvre un ticket sur le Discord : {discord}.' },
}
