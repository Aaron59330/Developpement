ConfigTelescopes = {
    Text = {
        HelpText = "Appuyez sur ~INPUT_PICKUP~ pour utiliser le téléscopes.",
        TelescopeInUse = "Quelqu'un utilise déjà ce téléscopes.",
        ToFarAway = "~r~Information\n~s~Vous vous éloignez de trop.",
        Zoom = "Zoomer",
        Dezoom = "Dézoomer",
        Leave = "Quitter le telescopes"
    },

    MaxInteractionDist = 1.75,

    MovementSpeed = {
        Keyboard = 2.75,
        Controller = 1.0
    },

    Zoom = {
        Max = 50.0,
        Min = 5.0,
        Speed = 5.0
    },

    Animations = {
        ["default"] = {
            enter = "enter_front",
            enterTime = 1500,
            exit = "exit_front",
            idle = "idle"
        },
        ["public"] = {
            enter = "public_enter_front",
            enterTime = 1500,
            exit = "public_exit_front",
            idle = "public_idle"
        },
        ["upright"] = {
            enter = "upright_enter_front",
            enterTime = 2500,
            exit = "upright_exit_front",
            idle = "upright_idle"
        }
    },

    Models = {
        [1186047406] = { MaxHorizontal = 55.0, MaxVertical = 20.0, offset = vector3(-0.03, 0.96, 0.0), headingOffset = 180.0, animation = "public", cameraOffset = vector3(0.0, -0.5, 0.7), scaleform = "OBSERVATORY_SCOPE" },
        [844159446] = { MaxHorizontal = 55.0, MaxVertical = 20.0, offset = vector3(0.02, -0.78, 1.0), animation = "upright", cameraOffset = vector3(0.0, 0.2, 1.7), scaleform = "BINOCULARS" },
        [-656927072] = { MaxHorizontal = 55.0, MaxVertical = 35.0, offset = vector3(1.14, 0.0, 0.0), headingOffset = 90.0, animation = "default", cameraOffset = vector3(-0.25, 0.0, 1.3), scaleform = "OBSERVATORY_SCOPE" },
        [1930051531] = { MaxHorizontal = 55.0, MaxVertical = 20.0, offset = vector3(-0.03, 0.96, 0.0), headingOffset = 180.0, animation = "public", cameraOffset = vector3(0.0, -0.5, 0.7), scaleform = "BINOCULARS" }
    }
}