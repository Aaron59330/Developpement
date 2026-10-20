# Images de la boutique

Dépose ici les images des articles (PNG, WEBP ou JPG, de préférence 600×375, fond transparent ou sombre) :

- `vehicles/<modèle>.png`  — ex. `vehicles/rs3.png`, `vehicles/ferrari812.png` (voitures, motos, avions, bateaux : nom du modèle du config)
- `weapons/<arme en minuscules>.png` — ex. `weapons/weapon_pistol_mk2.png`
- `caisses/<modèle>.png` — ex. `caisses/caisse1.png`
- `packs/<nom du pack en minuscules, sans espaces>.png` — ex. `packs/packstarter.png`

Les images des 34 véhicules GTA de base de la boutique (dépôt FiveM docs, `vehicles/<modèle>.webp`) sont déjà incluses : aucun accès Internet n'est nécessaire. Pour remplacer une image, dépose un fichier du même nom (png / webp / jpg).

Si une image est absente, l'interface cherche automatiquement :
1. l'image fournie ici (png → webp → jpg),
2. pour les véhicules d'origine GTA : `docs.fivem.net/vehicles/<modèle>.webp`,
3. pour les armes : l'image de ox_inventory (`web/images/WEAPON_XXX.png`),
4. sinon une illustration générée aux couleurs du serveur.
