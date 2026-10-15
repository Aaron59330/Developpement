Config = {}

--  Informations générales
Config.ServerName = "Bienvenue sur BLUEBAY"
Config.MaxClientsConvar = "sv_maxclients"

--  File d'attente
Config.SecondsPerPlayer = 5
Config.NoPlayerText = "Aucun joueur en connexion"

--  Liens
Config.DiscordURL = "https://discord.gg/JGxkBuckU"
Config.ShopURL = "https://bluebayrp.tebex.io/"

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
