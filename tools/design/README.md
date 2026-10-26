# Designs : Arcade / ancien

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
