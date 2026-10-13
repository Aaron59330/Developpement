ConfigDistributeur = {
    Payement = {
        Liquide = "Liquide",
        Banque = "Banque",

        LiquidePaiement = "Vous allez payé ~g~%s$~s~ liquide.",
        BanquePaiement = "Vous allez payé ~g~%s$~s~ en banque."
    },

    Water = {--Réservoir d'eau
        ZoneDist = 2,
        MoneyRemove = 2,
        Title = "Réservoir d'eau",
        Subtitle = "Que-voulez vous faire ?",
        Desc = nil,
        RightLabel = "~g~%s$",
        Bouton = "Prendre un verre d'eau",
        HelpNotification = "Appuyez sur ~INPUT_PICKUP~ pour accéder au menu."
    },

    Coffee = {--Machine à café
        ZoneDist = 2,
        MoneyRemove = 5,
        Title = "Machine à café",
        Subtitle = "Que-voulez vous faire ?",
        Desc = nil,
        RightLabel = "~g~%s$",
        Bouton = "Prendre un café",
        HelpNotification = "Appuyez sur ~INPUT_PICKUP~ pour accéder au menu."
    },

    Machine = {
        ZoneDist = 2,
        Props = {
            1114264700,
            992069095,
            -654402915
        },
        Bouton = {
            {Name = "Prendre du coca", Desc = nil, RightLabel = "~g~%s$", ItemReward = "coca", Price = 2},
            {Name = "Prendre du sprite", Desc = nil, RightLabel = "~g~%s$", ItemReward = "sprite", Price = 2},
            {Name = "Prendre du orangina", Desc = nil, RightLabel = "~g~%s$", ItemReward = "orangina", Price = 2},
            {Name = "Prendre du fanta", Desc = nil, RightLabel = "~g~%s$", ItemReward = "fanta", Price = 2}
        },

        Title = "Machine",
        Subtitle = "Que-voulez vous faire ?",
        HelpNotification = "Appuyez sur ~INPUT_PICKUP~ pour accéder au menu."
    },

    Notification = {
        YouBuy = "~g~Vous avez payé.",
    }
}