# pickax_mapgroups — blips de même nom et fiche du lieu

Des lieux portant **exactement le même nom** (deux garages « Garage ») gardent **chacun leur blip sur la carte** (rien n'est supprimé, rien n'est ajouté au nom) mais forment **un groupe** que tu parcours au clavier.

**Carte ouverte :**
- **← →** : sélectionne le lieu précédent / suivant du groupe : son blip **grossit et clignote**, et sa **fiche** s'affiche en haut à gauche (« Lieu 2 / 3 »).
- **↑ ↓** : s'il y a plusieurs groupes, choisit celui que ← → font défiler (par défaut le plus proche de toi).
- **Point de passage posé sur un blip** : le sélectionne aussi (fiche affichée).

**La fiche** (image, type, nom, description, distance) se règle **dans le builder** (World Builder : Personnaliser → « Blip sur la carte » → Image + Description) ; chaque lieu peut avoir la sienne. Image = lien `https://…` ou nom d'un fichier du dossier `html/places/`. Sans description, la rue du lieu est affichée.

- La sélection commence par le lieu le plus proche de toi.
- Un nom différent, même d'une majuscule, suffit pour ne pas être dans le même groupe.
- Sans cette ressource, les blips s'affichent normalement, sans sélection ni fiche.
- Aucune dépendance. À démarrer avec les builders (déjà couvert par `ensure [dev]`).
