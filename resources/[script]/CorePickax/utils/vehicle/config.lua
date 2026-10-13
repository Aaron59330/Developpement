ConfigVehicle = {
    CanGiveKey = false,--permet de mettre si vous voulez donner vos clefs

    Drift = true,
    Bikerick = true,
    DisableKey = false,--Mettre true si vous voulez que des que vous obtenez une voiture sa sajoute auto les clef et que sa desactive le serrurier (BLIPS DANS BLIPS a desactiver)
    DisableMenuKey = false,--Mettre true si vous voulez que le menu G soit désactiver (Menu clé)
    HideInTruck = true,
    ChangeSeat = true,
    DriveByWithSpeed = true,
    MaxSpeedDriveBY = 50,--Au dessus de 50 vous ne pouvez plus drive by (CONDUCTEUR)
    AntiVehiclePoliceUnemployed = true,
    AntiVehiclePoliceUnemployedJobsListAcces = {
        ["police"] = true,
        ["bcso"] = true,
        ["ambulance"] = true
    },
    
    Marker = {
        Distance = 20.0,
        PushEDistance = 3.0,
        PushEText = "Appuyez sur ~INPUT_CONTEXT~ pour intéragir.",
        MarkerDebug = 0.0,
        MarkerType = 22,
        Scale = {x = 0.3, y = 0.3, z = 0.3},
        Color = {r = 0, g = 0, b = 255, a = 255},
        BobUpAndDown = true,
        FaceCamera = true,
        Rotate = true,
    },

    BlacklistVehDrift = {--mettre en verrMAJ
        ["RHINO"] = false
    },

    AfterRebootDeleteLandKey = false,--Si vous voulez que les clefs preter soient supprimer après un reboot de la ressource ou du serveur.

    MenuEtNotification = {
        ["PushE"] = "Appuyez sur ~INPUT_CONTEXT~ pour accéder au menu clée",
        ["Title1"] = "Menu clée",
        ["SubTitle1"] = "Que vous-vous faire ?",
        ["NoKeys"] = "~r~Aucun véhicule sans clée~s~",
        ["NewKeys"] = "↓ Enregistrer une nouvelle clée ↓",
        ["Button"] = "%s [%s]",
        ["YourKeys"] = "Vos clée",
        ["YourKeysSub"] = "Que voulez vous faire ?",
        ["NoKeys2"] = "~r~Vous ne posséder pas de clée~s~",
        ["Button2"] = "Clé : ~p~%s",
        ["Button3"] = "[DOUBLE] Clé : ~p~%s",
        ["NoPerson"] = "Personne autour de vous.",

        ["Notif1"] = "Vous avez un nouvelle paires de clés !",
        ["Notif2"] = "Clés bien enregistrer !",
        ["Notif3"] = "~g~Vous avez reçu les clefs du véhicules (%s)~s~",
        ["Notif4"] = "~g~Vous avez donner les clefs du véhicules (%s)~s~",
        ["Notif5"] = "Vous avez reçu un double de clé",
        ["Notif6"] = "Vous avez prété votre clé",

        ["Give"] = "Donner",
        ["Lend"] = "Preter",
        ["Error"] = "~r~Aucune intéractions~s~",
        ["Drift"] = "Le ~b~mode drift~s~ est ~g~activée ~s~",
        ["Drift1"] = "Le ~b~mode drift~s~ est ~r~desactivée ~s~",
    },

    Commande = {
        CommandeName = "MenuClef",
        DescCommande = "Ouvrir le menu clef",
        Bind = "G",

        CommandeName2 = "OpenCloseVehicle",
        DescCommande2 = "Ouvrir / fermer le véhicule",
        Bind2 = "U",
    },

    Positions = {
        {x = -26.34, y = -1672.36, z = 29.49},
        {x = -231.65, y = 6235.07, z = 30.5},
    },

    ListVehicleFreeze = {
        -- {rotation = true, model = "Jugular", x = -222.79418945313, y = 6258.7319335938, z = 31.472255706787, h = 50.0},--Voici le format
    }
}