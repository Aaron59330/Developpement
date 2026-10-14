# Générateur d'icônes d'objets

Ces fichiers ont servi à créer les images manquantes de `web/images` (même style : contour sombre, ombrage doux, reflet).

- `icons.cjs` : une fonction par objet (nom de l'item = nom du fichier). Des gabarits existent : bouteille, canette, verre, carton de jus, pochon, fruit, feuille, poisson, mallette, carte, paquet…
- `render.cjs` : génère un PNG 128×128 par objet (`node render.cjs <dossier de sortie>`), nécessite Node + Playwright.

Pour ajouter un objet : ajoute une ligne dans `icons.cjs` (ex. `monitem: bottle({ body: '#c33', label: '#fff' })`), lance `render.cjs`, copie le PNG dans `web/images/`.
Un objet sans image affiche `_default.png` (caisse avec « ? »).
