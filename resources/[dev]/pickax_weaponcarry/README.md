# pickax_weaponcarry

Les armes de l'inventaire (ox_inventory) sont affichées sur le personnage selon le placement choisi :
**dans le dos**, **bas du dos**, **ceinture (devant)**, **hanche droite / gauche**, **cuisse droite / gauche (holster)**, **poitrine (bandoulière)**, **poche**, **cheville** ou **cachée** (invisible, comportement de base du jeu). Les emplacements proposés dépendent du type d'arme.

- **Choisir le placement :** menu contextuel (ALT) → clic sur toi → **Gestion armes** → une entrée par arme possédée → choisis l'endroit.
- **Style de visée :** menu contextuel → clic sur toi → **Style de visée** → une arme → Standard / Gangster / Campagnard / Tactique (selon le type d'arme). Mémorisé par arme.
- Une arme sortie en main disparaît de son emplacement, et y revient quand tu la ranges.
- Les autres joueurs proches voient tes armes rangées. Masquées en véhicule (`Config.HideInVehicle`).
- Les placements autorisés dépendent du type : fusil → dos ou cachée ; pistolet → dos, ceinture, poche ou cachée…

## Régler les positions (admin `_dev`)
Les décalages de départ sont approximatifs. En jeu : `/wctune back long 0.075 -0.15 -0.02 0 165 0`
(placement, type, x y z rotX rotY rotZ) → l'arme se replace tout de suite ; la ligne à copier dans `config.lua` s'affiche en F8.
Types : `pistol`, `smg`, `long`, `melee`. Placements : `back`, `backlow`, `front`, `hipR`, `hipL`, `thighR`, `thighL`, `chest`, `pocket`, `ankle`. Les nouveaux emplacements ont des valeurs de départ approximatives : à affiner avec cette commande.
