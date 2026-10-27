# Designs : Arcade / ancien / Piñata

Ce dossier contient une copie complète des fichiers d'interface dans leurs deux versions :
- `ancien/` : design d'avant Arcade (HUD, notifications, aide, inventaire, voix, dialogues, compteur) ;
- `arcade/` : design Arcade appliqué.
`fichiers.txt` liste tous les fichiers concernés.

## Revenir aux anciens designs d'un coup
```
./tools/design/design.sh ancien
```
(et `./tools/design/design.sh arcade` pour revenir à Arcade). Le tag git `design-avant-arcade` pointe aussi sur l'état d'avant.

## Après changement, en jeu
```
refresh
restart pickax_hud1
restart pickax_hud2
restart pickax_compass
restart pickax_notify
restart pickax_dialog
restart pickax_speedometer
restart pma-voice
restart ox_inventory
```
(menus F5 / builders : le style se règle dans Préférences > Apparence des menus, ou en retirant `hx.css` des pages.)

## Bouton du panel (méthode recommandée)
Panel web → **Personnalisation** → « Revenir à l'ancien style » / « Passer au style Arcade » : bascule en direct tous les menus (y compris le menu personnel F5), HUD, notifications, inventaire et builders, sans toucher aux fichiers. `design.sh` reste la méthode de secours côté fichiers.

## Style « Piñata » (3e style)
Style épuré et sombre, dans le même esprit que le nouveau panel : surfaces noires, fins contours, coins arrondis, police Geist, une seule couleur d'accent (la couleur du serveur). Pas de néon, pas d'italique, pas de majuscules forcées.
Il n'y a **pas de copie de fichiers** : tout est dans `resources/[script]/pickax_theme/pinata.css`, chargé automatiquement par `theme.js` quand le style choisi est « Piñata ».
- Panel web → **Identité & thème** → « Style des interfaces » → *Piñata (épuré sombre)* (ou le bouton « Passer au style Piñata ») → Enregistrer. Les joueurs le voient après reconnexion.
- Couvre : HUD (faim/soif/vie, bandeau staff, zone sûre), cartes serveur/métier/argent, notifications et aide « Appuie sur E », boussole, dialogue PNJ, compteur de vitesse, voix, menu F5 (le style « Piñata » est aussi choisissable par chaque joueur dans Préférences > Apparence des menus), menus et builders (modèle commun : menu à gauche, cartes, onglets, boutons blancs). L'inventaire garde sa mise en page actuelle (déjà sombre).
- Pour en sortir : choisir Arcade ou Classique dans le panel (aucun fichier à toucher).
