# pickax_weaponcarry

Les armes de l'inventaire (ox_inventory) sont affichées sur le personnage selon le placement choisi :
**dans le dos**, **à la ceinture (devant)**, **dans la poche** (petites armes) ou **cachée** (invisible, comportement de base du jeu).

- **Choisir le placement :** menu contextuel (ALT) → clic sur toi → une entrée par arme possédée → choisis l'endroit.
- Une arme sortie en main disparaît de son emplacement, et y revient quand tu la ranges.
- Les autres joueurs proches voient tes armes rangées. Masquées en véhicule (`Config.HideInVehicle`).
- Les placements autorisés dépendent du type : fusil → dos ou cachée ; pistolet → dos, ceinture, poche ou cachée…

## Régler les positions (admin `_dev`)
Les décalages de départ sont approximatifs. En jeu : `/wctune back long 0.075 -0.15 -0.02 0 165 0`
(placement, type, x y z rotX rotY rotZ) → l'arme se replace tout de suite ; la ligne à copier dans `config.lua` s'affiche en F8.
Types : `pistol`, `smg`, `long`, `melee`. Placements : `back`, `front`, `pocket`.
