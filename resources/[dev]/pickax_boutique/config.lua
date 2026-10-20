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
