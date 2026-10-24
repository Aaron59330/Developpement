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
        {name = "Futo", model = "futo", price = "1000"},
        {name = "Dominator", model = "dominator", price = "1000"},
        {name = "Buffalo S", model = "buffalo2", price = "1000"},
        {name = "Kuruma", model = "kuruma", price = "1500"},
        {name = "Banshee", model = "banshee", price = "1500"},
        {name = "Sultan RS", model = "sultanrs", price = "1500"},
        {name = "Comet", model = "comet2", price = "1500"},
        {name = "Baller", model = "baller2", price = "1500"},
        {name = "Schafter V12", model = "schafter3", price = "1500"},
        {name = "Elegy RH8", model = "elegy2", price = "2000"},
        {name = "Jester", model = "jester", price = "2000"},
        {name = "Infernus", model = "infernus", price = "2000"},
        {name = "Entity XF", model = "entityxf", price = "2500"},
        {name = "Turismo R", model = "turismor", price = "2500"},
        {name = "Zentorno", model = "zentorno", price = "2500"},
        {name = "Adder", model = "adder", price = "2500"}
    },
    
    Motos = {
        {name = "Faggio", model = "faggio", price = "1000"},
        {name = "Sanchez", model = "sanchez", price = "1000"},
        {name = "Ruffian", model = "ruffian", price = "1000"},
        {name = "PCJ 600", model = "pcj", price = "1500"},
        {name = "Vader", model = "vader", price = "1500"},
        {name = "Bagger", model = "bagger", price = "1500"},
        {name = "Double-T", model = "double", price = "2000"},
        {name = "Akuma", model = "akuma", price = "2000"},
        {name = "Hakuchou", model = "hakuchou", price = "2000"},
        {name = "Bati 801", model = "bati", price = "2000"}
    },

    Autres = {
        {Separator = true, name = "↓ Avions et hélicoptères ↓"},
        {name = "Dodo", model = "dodo", price = "2500", type = "aircraft"},
        {name = "Frogger", model = "frogger", price = "3000", type = "aircraft"},
        {name = "Maverick", model = "maverick", price = "3000", type = "aircraft"},
        {name = "Luxor", model = "luxor", price = "4000", type = "aircraft"},
        {Separator = true, name = "↓ Bateaux ↓"},
        {name = "Seashark", model = "seashark", price = "800", type = "boat"},
        {name = "Dinghy", model = "dinghy", price = "1000", type = "boat"},
        {name = "Jetmax", model = "jetmax", price = "1500", type = "boat"},
        {name = "Marquis", model = "marquis", price = "2500", type = "boat"}
    },

    weapon = {
        {name = "Pistolet MK2", model = "weapon_pistol_mk2", price = "1500", balle = "250"},
        {name = "SMG MK2", model = "weapon_smg_mk2", price = "3500", balle = "250"}
    },
    
    caisse = {
        {name = "Caisse bronze", model = "caisse1", price = "1000", desc = "Une Dominator, une Buffalo S ou une Futo.\nUne micro SMG, un pistolet calibre 50 ainsi qu'un pétoire.\n500, 750 et 1000 coins.\n75000$, 150000$ et 250000$."},
        {name = "Caisse argent", model = "caisse2", price = "1500", desc = "Une Banshee, Sultan RS, Kuruma, Comet ou Jester.\nUne SMG, UZI, Pistolet calibre 50.\n1000, 1500 et 2000 coins.\n500000$, 750000$ et 1000000$."},
        {name = "Caisse or", model = "caisse3", price = "1500", desc = "Une Adder, Zentorno, Turismo R, Entity XF, Infernus ou Elegy RH8.\nUne AK Compact, SMG, AK47.\n1000, 1500 et 2000 coins.\n1000000$, 1500000$ et 2000000$."}
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
        },
        -- Packs VIP (niveaux et avantages : pickax_core/players/vip/config.lua). `vip` = niveau 1-3, `days` = durée ; un achat du même niveau prolonge le VIP.
        {
            name = "VIP Bronze (31 jours)",
            desc = "Salaire majoré, inventaire plus grand, coins offerts chaque heure, récompense quotidienne et coffre VIP personnel.\nDétails dans le menu F5 > Espace VIP.",
            price = "1500",
            Win = { { vip = 1, days = 31 } }
        },
        {
            name = "VIP Argent (31 jours)",
            desc = "Tous les avantages du Bronze en plus fort : salaire x2, inventaire 48 kg, 10 coins/heure, plus grosse récompense quotidienne et coffre agrandi.\nDétails dans le menu F5 > Espace VIP.",
            price = "3000",
            Win = { { vip = 2, days = 31 } }
        },
        {
            name = "VIP Or (31 jours)",
            desc = "Le niveau maximum : salaire x3, inventaire 64 kg, 20 coins/heure, récompense quotidienne premium et très grand coffre VIP.\nDétails dans le menu F5 > Espace VIP.",
            price = "5500",
            Win = { { vip = 3, days = 31 } }
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
                { name = "Dominator", vehicle = "dominator", tier = 5},
                { name = "Buffalo S", vehicle = "buffalo2", tier = 5},
                { name = "Futo", vehicle = "futo", tier = 5},
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
                {  name = "Banshee", vehicle = "banshee", tier = 5},
                {  name = "Sultan RS", vehicle = "sultanrs", tier = 5},
                {  name = "Kuruma", vehicle = "kuruma", tier = 5},
                {  name = "Comet", vehicle = "comet2", tier = 5},
                {  name = "Jester", vehicle = "jester", tier = 5},
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
                { name = "Adder", vehicle = "adder", tier = 5},
                { name = "Zentorno", vehicle = "zentorno", tier = 5},
                { name = "Turismo R", vehicle = "turismor", tier = 5},
                { name = "Entity XF", vehicle = "entityxf", tier = 5},
                { name = "Infernus", vehicle = "infernus", tier = 5},
                { name = "Elegy RH8", vehicle = "elegy2", tier = 5},
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