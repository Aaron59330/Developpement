local PK_SHORT = (PickaxTheme and PickaxTheme.short) or 'BlueBay'
local PK_DISCORD = (PickaxTheme and PickaxTheme.discord) or 'discord.gg/bluebayrp'

ConfigDiscord = {
    Buttons = {
        {index = 0,name = 'Discord',url = 'https://' .. PK_DISCORD},
        {index = 1,name = 'Connect',url = 'fivem://connect/31.56.81.129/:30120'}
    },

    ActiviteJeux = {
        id = 1553750008107372584,
        image1 = "logo",
        text1 = PK_SHORT,
        image2 = "logo",
        text2 = PK_DISCORD,
        RichPresence = "%s [%s] - %s/ 128"
    },

    PauseMenu = {
        PauseMenu = "[FR] " .. PK_SHORT .. " | ~b~%s~s~ [~b~%s~s~] | https://" .. PK_DISCORD,
        Leave = 'Se déconnecter de ~b~' .. PK_SHORT,
        Quit = 'Quitter ~y~FiveM 🐌',
        Map = 'Carte',
        Gam = 'Jeu',
        Inf = 'Logs',
        Conf = 'Configuration',
        Sta = 'Statistiques',
        Galerie = 'Galerie',
        Rpl = 'Éditeur',
        FiveM = "FiveM " .. PK_SHORT
    }
}