ConfigBoutique = {
    PermissionDebug = false,--Si vous vous etes mis admin mais que vous avez pas les permissions mettre en true

    weaponCustom = true,
    weaponCustomPrice = 500,
    WeaponAmmoInWeapon = 250,

    WeaponItem = false,
    Control = {
        ControlPressedRotation = 45,
        ControlPressedDelete = 177
    },
    Message = {
        Rotation = "Faire une rotation",
        Delete = "Sortir"
    },

    Position = {
        PositionVehicule = vector3(228.8, -994.08, -99),
        PositionVehiculeHeading = 152,
        PositionVehiculeCam = vector3(228.47, -1002.39, -98),
        PositionVehiculeCamHeading = 0,

        PositionWeapon = vector3(21.02, -1104.21, 30.8),
        PositionWeaponHeading = 340.0,
        PositionCamCoords = vector3(20.54, -1106.2, 30.8),
        PositionInterriorWeapon = false,--Si c'est un interieur (mettre false si y'a un bug)
        --Caisse
        PositionCaisse = vec3(965.638062, 42.255524, 123.126732),
        PositionCaisseHeading = 149.02780151367188,
        PositionCamCaisse = vec3(967.157349, 28.767076, 125.759918),
        PositionCamHeadingCaisse = 12.93956089019775,
        PositionCaisseWeapon = vector3(21.02, -1104.21, 30.8),
        PositionCaisseWeaponHeading = 340.0,
        PositionCaisseWeaponCam = vector3(20.54, -1106.2, 30.8),
        PositionInterrior = false--Si c'est un interieur
    },

    LinkShop = 'https://esxcustomdeveloppementscript.tebex.io/',

    Commande = {
        CommandeGiveViaIDIG = "giveid",
        CommandeGiveViaBoutiqueID = "giveboutiqueid",
        -- CommandeRemoveCoins = "RemoveCoins",--Supprimer pour éviter les abus

        CommandeName = "menuboutique",
        DescCommande = "Menu boutique",
        Bind = "F1"
    },

    Notification = {
		["KickPlayer"] = "Désynchronisation avec le serveur ou Detection de Cheat, merci de vous rendre sur notre discord !",
        ["Ubuy"] = "Vous avez payé : %s",
        ["YouHaveWeapon"] = "Vous posséder déja l'arme ~b~%s~s~ que vous tentez d'achetez",
        ["YouBuyEntreprise"] = "Vous avez payé une entreprise, Merci de faire un ticket sur le discord pour votre créations de votre entreprise",
        ["Ubuy2"] = "Vous avez payé : %s",
        ["NoCoins"] = "~r~Vous n'avez pas assez de coins pour acheter ceci.~s~",
        ["ReceiveCoins"] = "Vous avez reçu vos %s coins",
        ["ClearCoins"] = "~g~Vous avez supprimer %s coins à l'ID : %s~s~",
        ["Error"] = "Merci de définir un ID !",
        ["Error2"] = "Merci de définir un montant !",
        ["Error3"] = "Aucun joueur en ligne n'a cette ID !",
        ["Error4"] = "Merci de définir un bon id !",
        ["Error5"] = "Vous n'êtes pas staff.",
        ["Error6"] = "Merci de définir un bon code boutique !",
    },
    
    Menu = {
        ["Title1"] = "Boutique",
        ["Title2"] = "Boutique",
        ["Title4"] = "Boutique",
        ["Title6"] = "Boutique",
        ["Title8"] = "Boutique",
        ["Title11"] = "Boutique",
        ["Title13"] = "Boutique",
        ["Title14"] = "Boutique",
        ["Title16"] = "Administration",

        ["SubTitle1"] = "Que voulez-vous faire ?",
        ["SubTitle2"] = "Que voulez-vous faire ?",
        ["SubTitle4"] = "Que voulez-vous faire ?",
        ["SubTitle6"] = "Que voulez-vous faire ?",
        ["SubTitle8"] = "Que voulez-vous faire ?",
        ["SubTitle11"] = "Que voulez-vous faire ?",
        ["SubTitle13"] = "Que voulez-vous faire ?",
        ["SubTitle14"] = "Que voulez-vous faire ?",
        ["SubTitle16"] = "Que voulez-vous faire ?",

        Info = {
            ["Title"] = "Boutique",
            ["Desc"] = "\n~p~Votre pseudo : ~s~%s\n~p~Code boutique : ~s~%s\n~p~Vos coins : ~s~%s",
            ["DescVeh"] = "info du véhicule :\nNom du véhicule : %s.\nPlace : %s.\nPrix : %s ~s~coins",
            ["DescCam"] = "info du véhicule :\nNom du véhicule : %s.\nPlace : %s.",
            ["DescMoto"] = "info du véhicule :\nNom du véhicule : %s.\nPlace : %s.\nPrix : %s ~s~coins",
        },

        Keyboard = {
            ["Amount"] = "Combien ?",
            ["Give"] = "à qui voulez vous give ?",
            ["Remove"] = "à qui voulez vous retirer ?"
        },

        Bouton = {
            ["Bouton_Vehicle"] = "Acheter un véhicule",
            ["Bouton_Vehicle_Desc"] = nil,

            ["Bouton_Weapon"] = "Acheter une armes",
            ["Bouton_Weapon_Desc"] = "~r~Toute armes acheter sera permanente !",

            ["Bouton_WeaponCustom"] = "Acheter une amélioration d'armes",
            ["Bouton_WeaponCustom_Desc"] = "~r~Toute armes acheter sera permanente !",

            ["Bouton_Pack"] = "Acheter un pack",
            ["Bouton_Pack_Desc"] = "Si vous acheter ceci, vous obtiendrez tout le contenu du pack séléctionner.",

            ["Bouton_Case"] = "Acheter une caisse",
            ["Bouton_Case_Desc"] = "Si vous acheter ceci, vous obtiendrez une chose parmis les objets de la caisse.",

            ["Bouton_Entreprise"] = "Acheter une entreprise",
            ["Bouton_Entreprise_Desc"] = nil,

            ["Bouton_FullCustom"] = "Acheter un full custom",
            ["Bouton_FullCustom_Desc"] = "Prix en Coins : ~r~1000~s~\nCet achat vous permet de customiser un vehicule à 100% de ses performances, le turbo est une exclusivité (car il est non disponible au mécano)",

            ["Bouton_Admin"] = "Administration",
            ["Bouton_Admin_Desc"] = nil,

            ["Bouton_Link"] = "Liens de la boutique",
            ["Bouton_Link_Desc"] = nil,

            ["Bouton_GiveCoins"] = "Give des coins",
            ["Bouton_GiveCoins_Desc"] = nil,

            ["Bouton_RemoveCoins"] = "Supprimé des coins",
            ["Bouton_RemoveCoins_Desc"] = nil,

            ["Bouton_Caisse"] = "%s",
            ["Bouton_Caisse_Desc"] = nil,
            ["Bouton_Caisse_RightLabel"] = "%s Coins~s~",
            ["Bouton_Caisse_Info"] = "La %s contient :",

            ["Bouton_Pack2"] = "%s",
            ["Bouton_Pack2_Desc"] = "~p~Cliquez pour afficher plus d'informations.",
            ["Bouton_Pack2_RightLabel"] = "%s Coins~s~",
            ["Bouton_Pack2_Info"] = "Le %s contient :",

            ["Bouton_Entreprise2"] = "%s",
            ["Bouton_Entreprise2_Desc"] = "%s",
            ["Bouton_Entreprise2_RightLabel"] = "%s Coins~s~",

            ["Bouton_Weapon2"] = "%s",
            ["Bouton_Weapon2_Desc"] = nil,
            ["Bouton_Weapon2_RightLabel"] = "%s Coins~s~",
            ["Bouton_Weapon2_Info"] = "info armes :\nNom de l'arme : %s.\nNombre de balle : %s.\nPrix : %s ~s~coins",

            ["Bouton_FullCustom2"] = "Acheter une full custom",
            ["Bouton_FullCustom2_Desc"] = nil,
            ["Bouton_FullCustom2_Info"] = "\nInfo véhicule :\nNom du véhicule : %s.\nPrix : %s ~s~coins",

            ["Bouton_Vehicle2"] = "%s à ~p~%s~s~ Coins~s~",
            ["Bouton_Moto"] = "%s à ~p~%s~s~ Coins~s~",
        }
    },
    
    vehicle = {
        {name = "Alfa roméo", model = "gtam21", price = "1500"},
        {name = "RS3", model = "rs3", price = "1500"},
        {name = "A45 AMG", model = "a45", price = "1500"},
        {name = "Golf", model = "golf", price = "1500"},
        {name = "BMW 1", model = "bmw1", price = "1500"},
        {name = "RS5", model = "rs5r", price = "2500"},
        {name = "RS6", model = "rs6pd600", price = "2500"},
        {name = "Aston Martin", model = "ast", price = "2500"},
        {name = "Dodge Redeye", model = "redeye", price = "2500"},
        {name = "GTR", model = "gtr", price = "2500"},
        {name = "Porsche 718", model = "game718", price = "2500"},
        {name = "RSQ 7", model = "sq7", price = "2500"},
        {name = "Ferrari 812", model = "ferrari812", price = "2500"},
        {name = "Skyline", model = "skyline", price = "2500"}
    },
    
    Motos = {
        {name = "Honda 450 CRF", model = "450crf", price = "1000"},
        {name = "Kawasaki KX450F", model = "kx450f", price = "1000"},
        {name = "TM Racing 450", model = "450tm", price = "1000"},
        {name = "Tmax", model = "tmax", price = "1500"},
        {name = "Yamaha R6", model = "r6", price = "1500"},
        {name = "XADV", model = "xadv", price = "1500"},
        {name = "Kawasaki Ninjah 1000RR", model = "ninjah2", price = "2000"},
    },

    Autres = {
        {Separator = true, name = "↓ Avions ↓"},
        {name = "Besra", model = "besra", price = "1000", type = "aircraft"},
        {Separator = true, name = "↓ Bateau ↓"},
        {name = "Dinghy", model = "dinghy", price = "1000", type = "boat"}
    },

    weapon = {
        {name = "Pistolet MK2", model = "weapon_pistol_mk2", price = "1500", balle = "250"},
        {name = "SMG MK2", model = "weapon_smg_mk2", price = "3500", balle = "250"}
    },
    
    caisse = {
        {name = "Caisse bronze", model = "caisse1", price = "1000", desc = "Une mvisiongt, une teslax ainsi que une w124.\nUne micro SMG, un pistolet calibre 50 ainsi qu'un pétoire.\n500, 750 et 1000 coins.\n75000$, 150000$ et 250000$."},
        {name = "Caisse argent", model = "caisse2", price = "1500", desc = "Une A45AMG, C63S, RS5, Aston Martin, Dodge.\nUne SMG, UZI, Pistolet calibre 50.\n1000, 1500 et 2000 coins.\n500000$, 750000$ et 1000000$."},
        {name = "Caisse or", model = "caisse3", price = "1500", desc = "Une Senna, F458S, X6M, Huracan, F458, Lykan.\nUne AK Compact, SMG, AK47.\n1000, 1500 et 2000 coins.\n1000000$, 1500000$ et 2000000$."}
    },
    
    pack = {
        {
            name = "Pack starter",
            desc = "-10~y~ Pain~s~, 10~y~ bouteille d'eau~s~ et 1~y~ téléphone~s~.\n-~g~50000$",
            price = "500",
            Win = {
                {
                    item = "bread",
                    amount = 10
                },
                {
                    item = "water",
                    amount = 10
                },
                {
                    item = "tel",
                    amount = 1
                },
                {
                    money = 50000
                }
            }
        },
        {
            name = "Pack bronze",
            desc = "-20~y~ Pain~s~, 20~y~ bouteille d'eau~s~ et 1~y~ téléphone~s~.\n-~g~200000$\n-~p~Pistolet SNS (Non perm)",
            price = "1500",
            Win = {
                {
                    item = "bread",
                    amount = 20
                },
                {
                    item = "water",
                    amount = 20
                },
                {
                    item = "tel",
                    amount = 1
                },
                {
                    money = 200000
                },
                {
                    weapon = "weapon_snspistol"
                }
            }
        },
        {
            name = "Pack Or",
            desc = "-50~y~ Pain~s~, 50~y~ bouteille d'eau~s~, 1~y~ téléphone~s~ et 5 ~y~Pilule de l'oublie~s~.\n-~g~500000$\n-~p~Pistolet & Pistolet 50 (Non perm)",
            price = "2500",
            Win = {
                {
                    item = "bread",
                    amount = 50
                },
                {
                    item = "water",
                    amount = 50
                },
                {
                    item = "tel",
                    amount = 1
                },
                {
                    item = "pilluleoublie",
                    amount = 5
                },
                -- {
                --     Vehicle = "p207"--Pour add un véhicule
                -- },
                {
                    money = 500000
                },
                {
                    weapon = "weapon_snspistol"
                },
                {
                    weapon = "weapon_cal50"
                }
            }
        }
    },
    
    Entreprise = {
        {name = "Pack Gangs", price = "4000", desc = "-Ce pack contient une créations de gangs.\n\n~p~Ouvrez un ticket discord apres l'achat avec votre prenom / nom rp."},
        {name = "Entreprise Farming", price = "7500", desc = "-Ce pack contient une créations de entreprise de farm.\n\n~p~Ouvrez un ticket discord apres l'achat avec votre prenom / nom rp."},
        {name = "Entreprise Whitelist", price = "10000", desc = "-Ce pack contient une créations de entreprise (non farming) whitelist.\n\n~p~Ouvrez un ticket discord apres l'achat avec votre prenom / nom rp."},
    },
    
    boost = {
        {price = "1000"},
    },

    ["chance"] = {
        [1] = { name = "~g~Common~s~", rate = 50 },
        [2] = { name = "~b~Rare~s~", rate = 40 },
        [3] = { name = "~p~Epic~s~", rate = 8 },
        [4] = { name = "~o~Unique~s~", rate = 1.7} ,
        [5] = { name = "~y~Legendary~s~", rate = 0.1 },
    },

    ["ESXCustom"] = {
        ["caisse1"] = {
            name = "Case #1",
            list = {
                --Voiture
                { name = "MVisionGT", vehicle = "mvisiongt", tier = 5},
                { name = "Tesla X", vehicle = "teslax", tier = 5},
                { name = "BMW 124", vehicle = "bmw124", tier = 5},
                --------------------------------------
                {name = "Pistolet MK2", weapon = "weapon_pistol_mk2", amount=1, tier = 4},
                {name = "Pistolet SNS MK2", weapon = "weapon_snspistol_mk2", amount=1, tier = 4},
                --------------------------------------
                { modelTexture = "prop_cs_heist_bag_01", name = "Coins", Coins = 500, tier = 3},
                { modelTexture = "prop_cs_heist_bag_01", name = "Coins", Coins = 750, tier = 3},
                { modelTexture = "prop_cs_heist_bag_01", name = "Coins", Coins = 1000, tier = 3},
                --------------------------------------
                { modelTexture = "prop_cash_case_02", name = "Argent", money = 75000, tier = 2},
                { modelTexture = "prop_cash_case_02", name = "Argent", money = 150000, tier = 2},
                { modelTexture = "hei_prop_hei_cash_trolly_02", name = "Argent", money = 250000, tier = 2},
            }
        },
        
        ["caisse2"] = {
            name = "Case #2",
            list = {
                --Voiture
                {  name = "A45", vehicle = "a45", tier = 5},
                {  name = "C63", vehicle = "c63w205", tier = 5},
                {  name = "RS5", vehicle = "rs5r", tier = 5},
                {  name = "AST", vehicle = "ast", tier = 5},
                {  name = "Redeye", vehicle = "redeye", tier = 5},
                --------------------------------------
                { modelTexture = "w_pi_pistolmk2", name = "Pistolet MK2", weapon = "weapon_pistol_mk2", amount=1, tier = 4},
                { modelTexture = "w_sb_smgmk2", name = "SMG K2", weapon = "weapon_smg_mk2", amount=1, tier = 4},
                --------------------------------------
                { modelTexture = "prop_cs_heist_bag_01", name = "Coins", Coins = 1000, tier = 3},
                { modelTexture = "prop_cs_heist_bag_01", name = "Coins", Coins = 1500, tier = 3},
                { modelTexture = "prop_cs_heist_bag_01", name = "Coins", Coins = 2000, tier = 3},
                --------------------------------------
                { modelTexture = "hei_prop_hei_cash_trolly_02", name = "Argent", money = 500000, tier = 2},
                { modelTexture = "hei_prop_cash_crate_half_full", name = "Argent", money = 750000, tier = 2},
                { modelTexture = "hei_prop_cash_crate_half_full", name = "Argent", money = 1000000, tier = 2},
            }
        },
    
        ["caisse3"] = {
            name = "Case #3",
            list = {
                --Voiture
                { name = "Senna", vehicle = "senna", tier = 5},
                { name = "LW458", vehicle = "lw458s", tier = 5},
                { name = "X6M", vehicle = "rmodx6", tier = 5},
                { name = "Huracan", vehicle = "huracan", tier = 5},
                { name = "458 itali", vehicle = "italia458", tier = 5},
                { name = "Lykan", vehicle = "lykan", tier = 5},
                --------------------------------------
                { modelTexture = "w_sb_smgmk2", name = "SMG MK2", weapon = "weapon_smg_mk2", amount=1, tier = 4},
                { modelTexture = "w_ar_assaultriflemk2", name = "Fusil d'assaut MK2", weapon = "weapon_assaultrifle_mk2", amount=1, tier = 4},
                --------------------------------------
                { modelTexture = "prop_cs_heist_bag_01", name = "Coins", Coins = 1000, tier = 3},
                { modelTexture = "prop_cs_heist_bag_01", name = "Coins", Coins = 1500, tier = 3},
                { modelTexture = "prop_cs_heist_bag_01", name = "Coins", Coins = 2000, tier = 3},
                --------------------------------------
                { modelTexture = "hei_prop_cash_crate_half_full", name = "Argent", money = 1000000, tier = 2},
                { modelTexture = "prop_cash_crate_01", name = "Argent", money = 1500000, tier = 2},
                { modelTexture = "prop_cash_crate_01", name = "Argent", money = 2000000, tier = 2},
            }
        }
    },
    
    -- Rôles ESX (colonne `group` des joueurs) autorisés à utiliser « Administration » dans le menu boutique
    AdminGroups = { superadmin = true, _dev = true },
    AdminMaxAmount = 1000000,   -- maximum de coins par action
    AdminCanRemove = true,      -- false = les admins ne peuvent que donner des coins

    PermissionAllowed = {
        ["license:ebc3a4d7b0de5d708994814df999cfd9c3efa5ad"] = true
    }
}