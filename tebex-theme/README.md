# Thème Tebex « Pickax Store »

Même style que la boutique en jeu (fond #16171c, couleur principale configurable, cartes avec barre centrée).

## 1. Installer le site
1. Tebex → **Webstore → Themes** → importer `tebex-theme.zip` (à la racine du dépôt), puis l'activer.
2. Dans **Customize / Theme settings** : couleur (`accent`, même valeur que `AccentColor` du core), nom, slogan, logo, Discord, adresse `cfx.re/join/…`.

## 2. Créer les packs de coins (catégorie « Coins »)
Sur chaque pack → **Game server commands** → *Add command* :

```
pickax_tebex {id} 500 {transaction}
```
- `{id}` : ID serveur du joueur (il doit être connecté au moment de l'achat → cocher « Require player to be online »).
- `500` : nombre de coins du pack (mets 1000 + bonus, etc.).
- `{transaction}` : évite qu'un achat soit crédité deux fois.

Variante avec l'ID boutique du joueur (affiché dans le menu boutique en jeu) : `pickax_tebex b{id} 500 {transaction}`.

## 3. Relier le serveur
1. Installer le plugin Tebex (`tebex_main` / `tebex`) et mettre dans `server.cfg` : `sv_tebexSecret "TON_CODE_SECRET"` (Tebex → Game servers).
2. `pickax_core/config.lua` : `TebexStore = 'https://tonsite.tebex.io'` → le bouton « Acheter des coins » du menu boutique ouvre ce site.
3. `restart pickax_core` puis `restart pickax_boutique`.

## Test
Console serveur : `pickax_tebex 1 100` (donne 100 coins au joueur d'ID serveur 1).
