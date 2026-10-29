# pickax_mapgroups — fiche du lieu

Quand tu **sélectionnes un blip sur la carte** (carte → blip → « Définir un point de passage »), une petite fiche s'affiche **en haut à gauche** : image du lieu, type, nom, description et distance.

- L'image et la description se règlent **dans le builder** (World Builder : onglet Personnaliser → carte « Blip sur la carte »). Image = lien `https://…` ou nom d'un fichier du dossier `html/places/`.
- **Deux lieux de même nom** (deux garages « Garage ») gardent **chacun leur blip**, avec exactement le même nom, et **partagent la même fiche** (la fiche indique « 1 autre lieu du même nom »).
- La fiche reste tant que la carte est ouverte (puis 12 s) et disparaît si tu retires le point de passage.
- Aucune dépendance. À démarrer avec les builders (déjà couvert par `ensure [dev]`).
