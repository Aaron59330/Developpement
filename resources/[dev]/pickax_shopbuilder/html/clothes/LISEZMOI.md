# Images des vêtements (cabine d'essayage)

La cabine affiche une vignette par pièce. Pour qu'elle montre la vraie photo du vêtement, dépose les images ici :

```
html/clothes/m/<pièce>/<numéro>.webp        (homme)
html/clothes/f/<pièce>/<numéro>.webp        (femme)
html/clothes/m/<pièce>/<numéro>_<variante>.webp   (optionnel : image de la variante choisie)
```
`<pièce>` = `tshirt`, `torso`, `arms`, `bproof`, `decals`, `pants`, `shoes`, `helmet`, `glasses`, `ears`, `mask`, `chain`, `bags`, `watches`, `bracelets`.
Exemple : `html/clothes/m/tshirt/12.webp` = le T-shirt n°12 pour un homme.

Sans image, la cabine affiche une silhouette propre de la pièce avec son numéro : elle reste utilisable.

## Générer les images automatiquement (admin, en jeu)
Avec la ressource `screenshot-basic` démarrée : `/clothshots tshirt` (ou `torso`, `pants`, `shoes`, `helmet`…) parcourt chaque numéro avec ton personnage devant un fond neutre et enregistre les images dans ce dossier.
Arrêt en cours de route : `/clothshotsstop`. Les images sont prises à la résolution de ton écran : redimensionne-les ensuite (par ex. 256×300 px) pour alléger le chargement.
