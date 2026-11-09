Config = {}

Config.Command = 'tableau'            -- /tableau ouvre le tableau de bord
Config.Key = 'HOME'                   -- touche par défaut (modifiable dans les paramètres FiveM) ; '' = aucune
Config.Lang = 'Français'

-- ═════════════ DONNÉES DU JOUEUR ═════════════
-- Déjà branchés : identité, temps de jeu (compté par cette ressource), factures (table `billing` d'ESX), véhicules (table `owned_vehicles`).
Config.Billing = { Table = 'billing', IdentifierColumn = 'identifier', AmountColumn = 'amount' }
Config.Vehicles = { Table = 'owned_vehicles', OwnerColumn = 'owner', StoredColumn = 'stored' }   -- StoredColumn : 1 = rangé, 0 = sorti ; '' = ignoré

-- Les blocs ci-dessous n'existent pas encore dans la base : ils affichent leur état « vide ». Donne ta propre fonction pour les remplir.
-- Chaque fonction reçoit (source, xPlayer) et renvoie une table (voir html/script.js, objet DEMO, pour le format) ou nil.
Config.Providers = {
    quests     = nil,   -- { claim = 0, renew = '11 h 14 min', featured = { {label, courant, max} }, tabs = { daily = {…}, perm = {…}, groups = {…} }, totals = {...}, percent = 24, renewHours = '…' }
    jobs       = nil,   -- { level = 15, best = { label, level, pct, rank, of, xp, next }, list = {…}, board = {…} }
    properties = nil,   -- { count = 0 }
    animals    = nil,   -- { count = 0, max = 5 }
    services   = nil,   -- { have = 8, total = 29, list = { {'ok'|'no', '#couleur'} }, more = 13 }
}

-- ═════════════ BOUTIQUE (page « Boutique » du tableau de bord) ═════════════
-- Items : { id, tab ('daily'|'vehicle'|'bundles'|'weapons'|'items'), cat, title, desc, price, image (lien https ou nil), badges = { 'NOUVEAU' }, stats = { {'Dégâts', 35} } }
Config.Shop = {
    CoinsAccount = 'coins',           -- compte ESX qui contient les coins du joueur (0 si absent)
    BuyServerEvent = nil,             -- événement serveur appelé à l'achat : TriggerServerEvent(BuyServerEvent, id)
    Items = {},
}
