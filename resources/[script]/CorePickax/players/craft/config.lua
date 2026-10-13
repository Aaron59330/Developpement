ConfigCraft = {
    Marker = {
        MarkerDist = 3,
        MarkerType = 22,
        Scale = {x = 0.3, y = 0.3, z = 0.3},
        Color = {r = 0, g = 0, b = 255, a = 255},
        BobUpAndDown = true,
        FaceCamera = true,
        Rotate = true,
    },
    DistMenu = 1,

    Craft = {
        {
            Pose = {
                x = -223.3990020752,
                y = -278.88296508789,
                z = 49.077857971191
            },
            ItemNameToCraft = "Item1",
            Jobs = "job",--ou job2
            RequiredJob = {--Si vous ne voulez pas mettre de job requis alors mettez simplement rien dedans
                "police",
                "ambulance"
            }
        }
    },

    Farm = {
        {
            Pose = {
                x = -221.64183044434,
                y = -275.10006713867,
                z = 48.964473724365
            },
            Label = "Plastique",
            ItemReward = "plastique",
            amount = 1,
            TimerWait = 1500,

            Jobs = "job",--ou job2
            RequiredJob = {
                "police",
                "ambulance"
            }
        },
        {
            Pose = {
                x = -220.04409790039,
                y = -271.72506713867,
                z = 48.970283508301
            },
            Label = "Bois",
            ItemReward = "wood",
            amount = 1,
            TimerWait = 1500,

            Jobs = "job",--ou job2
            RequiredJob = {
                "police",
                "ambulance"
            }
        },
        {
            Pose = {
                x = -220.05851745605,
                y = -266.66741943359,
                z = 49.076580047607
            },
            Label = "Fer",
            ItemReward = "iron",
            amount = 1,
            TimerWait = 1500,

            Jobs = "job",--ou job2
            RequiredJob = {
                "police",
                "ambulance"
            }
        },
    },
    Notification = {
        Menu = {
            ["Title"] = "Craft",
            ["SubTitle"] = "Que voulez-vous faire ?",
            ["TimeWaitLabel"] = "~r~Temps attente : %ss"
        },
        HelpNotification = {
            ["AccesCraft"] = "Appuyez sur ~INPUT_CONTEXT~ pour accéder au craft",
            ["AccesFarm"] = "Appuyez sur ~INPUT_CONTEXT~ pour accéder au farm du %s"
        },

        ["NeedItem"] = "Vous avez besoin de : ~y~%s~s~ ~b~x%s~s~",
        ["Cheat"] = "Désynchronisation avec le serveur ou Detection de Cheat (si vous pensez que c'est une erreur, Merci de vous rendre sur notre discord !)",
        ["CraftItem"] = "Vous avez fabriquez : ~y~%s~s~",
        ["ReceiveItem"] = "Vous avez récupérer : ~y~%s~s~"
    },

    ItemCraft = {
        ["Item1"] = {
            [1] = {
                ItemLabel = "Chargeur",
                ItemName = "magazine",
                Desc = "Requis :\nx2 ~y~Bois~s~\nx2 ~y~Plastique~s~\nx2 ~y~Fer~s~",
                RewardsAmountItem = 1,
                required = {
                    { label = 'Bois', name = "wood", amount = 2},
                    { label = 'Plastique', name = "plastique", amount = 2},
                    { label = 'Fer', name = "iron", amount = 2},
                },
                TimeToWait = 5000--milliseconde
            }
            -- [2] = {
            --     ItemLabel = "Pain",
            --     ItemName = "bread",
            --     Desc = "Requis :\nx2 ~y~water~s~\n",
            --     RewardsAmountItem = 1,
            --     required = {
            --         { label = 'Scrab', name = "water", amount =  2}
            --     },
            --     TimeToWait = 10000--milliseconde
            -- }
        }
    }
}