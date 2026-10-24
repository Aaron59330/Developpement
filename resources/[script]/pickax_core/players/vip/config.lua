ConfigVIP = {
    maxWeightDefault = 24,
    DureeVIP = 31,            -- durée par défaut (jours) quand aucune n'est précisée
    CheckInterval = 5,        -- minutes : vérification d'expiration des VIP en ligne
    CoinsInterval = 60,       -- minutes : intervalle de versement des coins boutique
    DailyCooldown = 24 * 3600,-- secondes entre deux récompenses quotidiennes

    -- Niveaux : 1 = Bronze, 2 = Argent, 3 = Or (le niveau est stocké dans vips.vip / users.vip)
    Tiers = {
        [1] = {
            name = 'VIP Bronze', color = '~o~', hex = '#cd7f32',
            salaryMult = 1.5,                       -- salaire x1.5
            maxWeight = 36,                         -- poids max de l'inventaire
            coinsPerHour = 5,                       -- coins boutique chaque heure
            chest = { slots = 30, weight = 50000 }, -- coffre VIP personnel
            daily = { money = 500, coins = 0, items = {} },
        },
        [2] = {
            name = 'VIP Argent', color = '~c~', hex = '#c0c0c0',
            salaryMult = 2.0,
            maxWeight = 48,
            coinsPerHour = 10,
            chest = { slots = 50, weight = 100000 },
            daily = { money = 1500, coins = 5, items = {} },
        },
        [3] = {
            name = 'VIP Or', color = '~y~', hex = '#ffd700',
            salaryMult = 3.0,
            maxWeight = 64,
            coinsPerHour = 20,
            chest = { slots = 80, weight = 200000 },
            daily = { money = 3000, coins = 15, items = { { name = 'bread', count = 5 }, { name = 'water', count = 5 } } },
        },
    },
}

-- Ancienne clé conservée pour compatibilité
ConfigVIP.maxWeightVIP = ConfigVIP.Tiers[1].maxWeight
ConfigVIP.CombienDeFoisLeSalaire = ConfigVIP.Tiers[1].salaryMult
ConfigVIP.CoinsAdd = ConfigVIP.Tiers[1].coinsPerHour
