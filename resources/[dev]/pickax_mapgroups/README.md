# pickax_mapgroups — blips groupés et fiche du lieu

Des lieux portant **exactement le même nom** (deux garages « Garage ») ne forment **qu'un seul blip** sur la carte, avec le nom tel quel (rien n'est ajouté).

**Carte ouverte :** la fiche du blip groupé le plus proche s'affiche à l'ouverture avec « Lieu 1 / 2 ». Ensuite :
- **← →** : le blip passe au lieu précédent / suivant (il clignote, une fiche s'affiche en haut à gauche : « Lieu 2 / 3 »).
- **↑ ↓** : s'il y a plusieurs blips groupés, choisit celui que ← → font défiler (par défaut le plus proche de toi).
- **Point de passage posé sur le blip** : affiche aussi la fiche du lieu où il se trouve.

**La fiche** (image, type, nom, description, distance) se règle **dans le builder** (World Builder : Personnaliser → « Blip sur la carte » → Image + Description) ; chaque lieu peut avoir la sienne. Image = lien `https://…` ou nom d'un fichier du dossier `html/places/`. Sans description, la rue du lieu est affichée.

- Le blip commence sur le lieu le plus proche de toi.
- Un nom différent, même d'une majuscule, suffit à garder deux blips séparés.
- Sans cette ressource, le blip groupé reste un seul blip (sur le premier lieu) sans navigation.
- Aucune dépendance. À démarrer avec les builders (déjà couvert par `ensure [dev]`).

## Si les flèches ne changent rien sur ta carte
Deux autres moyens, toujours disponibles :
- **Touches configurables** : Paramètres FiveM → Touches → « Carte : lieu suivant / précédent du blip groupé » (par défaut → et ←, à changer si tu veux).
- **Commande `/lieu`** (suivant) et `/lieu prec` (précédent), utilisable partout.
