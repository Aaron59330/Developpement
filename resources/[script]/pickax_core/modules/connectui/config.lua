Config = {}

--  Informations générales
Config.ServerName = "Bienvenue sur " .. ((PickaxTheme and PickaxTheme.short) or "BLUEBAY")   -- réglé dans pickax_core/config.lua
Config.MaxClientsConvar = "sv_maxclients"

--  File d'attente
Config.SecondsPerPlayer = 5
Config.NoPlayerText = "Aucun joueur en connexion"

--  Liens
Config.DiscordURL = "https://discord.gg/JGxkBuckU"   -- (lien propre à l'écran de connexion)
Config.ShopURL = "https://bluebayrp.tebex.io/"
do   -- si TebexStore est renseigné dans pickax_core/config.lua, le bouton Boutique pointe dessus
    local ok, st = pcall(function() return exports['pickax_core']:GetGlobalStyle() end)
    if ok and type(st) == 'table' and type(st.tebex) == 'string' and st.tebex ~= '' then Config.ShopURL = st.tebex end
end

--  Textes
Config.Texts = {
    playersConnecting = "👥 Joueurs en connexion : %s/%s",
    estimatedTime = "⏳ Temps d’attente estimé : %s sec",
    waitingListTitle = "📋 Liste des joueurs dans la liste d'attente",
    playHint = "Clique sur **Jouer** pour entrer en jeu",
    cancelMessage = "Connexion annulée."
}

--  Boutons
Config.Buttons = {
    play = {
        title = "🎮 Jouer",
        action = "play"
    },
    discord = {
        title = "💬 Discord",
        url = Config.DiscordURL
    },
    shop = {
        title = "🛒 Boutique",
        url = Config.ShopURL
    }
}
