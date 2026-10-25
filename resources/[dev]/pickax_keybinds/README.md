# pickax_keybinds — « Mes touches »

`/touches` ouvre la liste des raccourcis de la base avec la touche **réellement attribuée** au joueur (lue dans FiveM, donc à jour s'il a changé ses touches), les conflits (deux actions sur la même touche) et un rappel pour les modifier (Échap → Paramètres → Raccourcis clavier → FiveM).

- Liste des raccourcis : `config.lua` → `Config.Actions` (ajoute une ligne `{ group, label, cmd, default }` par raccourci ; `cmd` = nom passé à `RegisterKeyMapping`).
- Exports client : `exports.pickax_keybinds:GetKey('phone')` (touche réelle ou nil), `GetConflicts()`.
- `pickax_tutorial` l'utilise pour afficher les vraies touches du joueur.
- FiveM ne permet pas à un script de réattribuer une touche enregistrée : le changement se fait dans les paramètres du jeu.
