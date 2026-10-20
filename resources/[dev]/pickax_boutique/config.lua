Config = {}

Config.CheckoutSpacing = 3000        -- ms entre deux articles du panier (laisse le temps aux véhicules d'être livrés au garage)
Config.MaxCartItems    = 30          -- articles maximum dans un panier (quantités comprises)
Config.CouponSeconds   = 600         -- durée de validité d'une remise appliquée à un panier en cours de paiement
Config.HistoryLimit    = 100         -- lignes d'historique affichées par joueur
Config.Webhook         = ''          -- (optionnel) webhook Discord : achats, codes utilisés, parrainages

-- Parrainage : valeurs par défaut (modifiables en jeu par un administrateur : Boutique → Gestion)
Config.Referral = {
    Enabled      = true,
    FilleulCoins = 100,              -- coins offerts au joueur qui saisit le code d'un parrain
    ParrainCoins = 200,              -- coins offerts au parrain
}

-- Tebex : la boutique web (dossier tebex-theme/) crédite des coins en jeu via une commande console.
-- Dans Tebex, sur chaque pack de coins : Commande de jeu →   pickax_tebex {id} 500 {transaction}
-- ({id} = ID serveur du joueur en ligne ; 500 = coins ; {transaction} = numéro de commande, évite les doublons)
-- Alternative avec l'ID boutique du joueur (visible dans le menu boutique) :   pickax_tebex b{id boutique} 500 {transaction}
Config.Tebex = {
    Command    = 'pickax_tebex',
    BonusPct   = 0,                  -- % de coins offerts en plus sur tous les achats (ex : 10 pour une promo +10 %)
}

-- Qui peut modifier les descriptifs des articles en jeu (clic sur un article → « Modifier le descriptif ») : groupes ESX (colonne `group`)
Config.DescGroups = { _dev = true }
