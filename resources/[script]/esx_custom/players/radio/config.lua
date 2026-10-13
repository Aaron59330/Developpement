--Notification--
NotificationRadio = {
    Water = "Vous êtes actuellement dans l'eau, vous n'avez pas accés à votre radio.",
    Water2 = "Vous êtes actuellement dans l'eau, votre radio c'est noyé.",
    RadioON = "~g~Vous avez allumée votre radio.",
    RadioOFF = "~r~Vous avez eteint votre radio.",
    SoundEffectsOff = "Bruitages radio désactives",
    SoundEffectsOn = "Bruitages radio activés",
    AccesYes = "~b~Fréquence définie sur %s MHZ",
    AccesNo = "~r~Fréquence brouillez, impossible de se connecter dessus",
    Error999 = "~r~Vous devez mettre une fréquence entre 1 et %s",
    ErrorNotNumber = "~r~Vous devez mettre un nombre !",
    DisconnectOfFrequence = "Vous vous êtes déconnecter de la fréquence",
    NoRadio = "~r~Vous n'avez pas de radio",
    SoundRadioMax = "Vous ne pouvez pas augmenter plus que ça.",
    SoundRadioMin = "Vous ne pouvez pas baisser plus que ça.",
    YouJoinAfterLeave = "Votre radio a été redéfinie.",
    EnableRadioFeedback = "~g~Vous avez activer le retour radio.~s~",
    DisableRadioFeedback = "~r~Vous avez désactiver le retour radio.~s~",
    RedefinedRadio = "Votre radio a été redéfinie."
}
--BUTTON--
ButtonRadio = {
    Enable = "~g~Activée",
    Disable = "~r~Désactivés", 
    TitleMenu = "Radio",
    SubtitleMenu = "Que voulez-vous faire ?",
    TurnOffOnRadio = "Allumer/Eteindre la radio",
    RightLabelTurnOffOnRadio = "~g~Allumée",
    RightLabelTurnOffOnRadio2 = "~r~Eteinte",
    TurnOnSoundEffect = "Activer/Désactiver les bruitages",
    BaisserSon = "Baisse le volume de la radio",
    AugmenterSon = "Augmenter le volume de la radio",
    ChooseFrequency = "Rejoindre une fréquence radio",
    Sound = "Volume: %s%s~s~",
    KeyboardInput = "Choissisez votre fréquence ?",
    TurnReturnRadio = "Activer le retour radio",
    DescTurnReturnRadio = "Après un déco reco, vous pouvez réactiver votre radio automatiquement"
}

ConfigRadio = {
    GestionRadio = {
        VoiceChat = "pma-voice",--pma-voice ou mumble-voip
        PersistentFrequency = true,--mettre en false si vous ne voulez pas que sa save la radio après un déco reco
        MaxFrequency = 99999,
    },

    Commande = {
        Bind = 'F9',
        Commande = "MenuRadio",--TriggerEvent("esx_custom:OpenRadio") pour ouvrir la radio sur d'autre script
        Description = "Menu Radio"
    },

    Item = {
        NeedItem = true,
        NameItem = "radio"
    },

    GestionJobs = {
        Job1 = true,
        Job2 = true,
        Jobs1 = {
            [205] = "police",
            [206] = "ambulance"
        },
        Jobs2 = {
            [105] = "ballas",
            [106] = "families"
        },
    },

    MenuRadio = {
        MenuChange = {
            MenuRetourRadio = 9,
            ChooseFrequency = 2,
            MenuEteindreAllumer = 1
        },

        [1] = {
            Menu = "Boutton",
            Title = ButtonRadio.TurnOffOnRadio,
            Desc = nil,
            RightLabel = ButtonRadio.RightLabelTurnOffOnRadio2,
            Selected = function()
                ChangeStateRadio(1)
            end
        },
        [2] = {
            Menu = "Boutton",
            Title = ButtonRadio.ChooseFrequency,
            Desc = nil,
            RightLabel = "0",
            Selected = function()
                AddFrequency()
                GetFrequency(2)
            end
        },
        [3] = {
            Menu = "Line"
        },
        [4] = {
            Menu = "Boutton",
            Title = ButtonRadio.AugmenterSon,
            Desc = nil,
            RightLabel = "→→→",
            Selected = function()
                GetVolumeRadio(true, 6)
            end
        },
        [5] = {
            Menu = "Boutton",
            Title = ButtonRadio.BaisserSon,
            Desc = nil,
            RightLabel = "→→→",
            Selected = function()
                GetVolumeRadio(false, 6)
            end
        },
        [6] = {
            Menu = "Separator",
            Title = (ButtonRadio.Sound):format("~r~", "100")
        },
        [7] = {
            Menu = "Line"
        },
        [8] = {
            Menu = "Boutton",
            Title = ButtonRadio.TurnOnSoundEffect,
            Desc = nil,
            RightLabel = "→→→",
            Selected = function()
                BruitagesRadio()
            end
        },
        [9] = {
            Menu = "CheckBox",
            Title = ButtonRadio.TurnReturnRadio,
            Desc = ButtonRadio.DescTurnReturnRadio,
            RightLabel = "→→→",
            Status = false,
            Selected = function()
                SaveFrequency(true, 9)
            end,
            Selected2 = function()
                SaveFrequency(false, 9)
            end
        },
    },
}