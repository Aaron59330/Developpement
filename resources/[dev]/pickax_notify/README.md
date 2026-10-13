# Pickax Notify

Ressource de notifications FiveM/ESX avec design configurable.

## Installation

1. Place `pickax_notify` dans tes resources.
2. Ajoute `ensure pickax_notify` dans ton `server.cfg`.
3. Dans ESX, garde les mêmes fonctions/appels :
   - `ESX.ShowNotification(msg, hudColorIndex)`
   - `ESX.ShowAdvancedNotification(title, subject, msg, icon, iconType, hudColorIndex)`
   - `ESX.ShowHelpNotification(msg)`
4. Après un changement du `config.lua`, fais `restart pickax_notify`.

## Configuration

Tout le design principal est dans `config.lua`.

Tu peux notamment changer :
- couleur principale ;
- couleur et transparence du fond ;
- couleur du texte et du petit texte ;
- largeur / hauteur ;
- bords carrés ou arrondis avec `Config.BorderRadius` ;
- épaisseur de la ligne principale avec `Config.SideLineWidth` ;
- position au-dessus de la minimap ;
- taille des textes ;
- taille / bord / fond de l’icône ;
- taille / position du compteur anti-spam ;
- fenêtre anti-spam (3 secondes par défaut) ;
- ligne de progression ;
- nombre maximum de notifications ;
- durées d’affichage.

### Exemple carré

```lua
Config.BorderRadius = 2
Config.IconRadius = 2
Config.CounterRadius = 2
```

### Exemple très arrondi

```lua
Config.BorderRadius = 18
Config.IconRadius = 10
Config.CounterRadius = 10
```

### Exemple ligne plus grosse

```lua
Config.SideLineWidth = 6
```

### Exemple changer les couleurs

```lua
Config.MainColor = '#ff3b30'
Config.BackgroundColor = '#090909'
Config.BackgroundTransparency = 0.55
Config.TextColor = '#ffffff'
Config.SmallTextColor = '#aaaaaa'
```

## Anti-spam

Par défaut, si une notification identique est répétée dans les 3000 ms, elle reste sur une seule carte et le compteur augmente.

```lua
Config.StackWindow = 3000
```
