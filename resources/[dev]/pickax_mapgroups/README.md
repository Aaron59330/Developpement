# pickax_mapgroups — fiche du lieu

**Blips de même nom :** chaque lieu garde son blip sur la carte, et tous les blips portant **exactement le même nom** reçoivent **le même style** (icône, couleur, taille, visibilité, nom) que le premier : ils ne sont plus « différents ». GTA les range alors dans **une seule ligne de la légende** de la carte (flèches ← → de la légende pour passer de l'un à l'autre).

**Fiche du lieu :** quand tu **sélectionnes un blip** (carte → blip → « Définir un point de passage »), une fiche s'affiche **en haut à gauche** : image, type, nom, description, distance, « Lieu 2 sur 2 de ce nom ».
- L'image et la description se règlent **dans le builder** (World Builder : Personnaliser → « Blip sur la carte »), une fiche par lieu. Image = lien `https://…` ou nom d'un fichier de `html/places/`. Sans description, la rue du lieu est affichée.
- Un nom différent, même d'une majuscule, garde son style propre.
- Sans cette ressource, les blips s'affichent normalement, sans fiche.
- Aucune dépendance. À démarrer avec les builders (déjà couvert par `ensure [dev]`).
