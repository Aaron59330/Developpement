# Weapon wheel UI

Roulette d’armes inspirée de celle de GTA V, en style glassmorphisme. Frontend uniquement, pensé pour une NUI FiveM.

![Aperçu de la roulette](docs/apercu.png)

## Fonctionnement

- 6 cases : la main nue en bas, puis les emplacements 1 à 5 en partant de la gauche.
- La case visée s’éclaire en rose depuis son trait du bas, l’arme équipée en turquoise.
- Munitions affichées en `chargeur / réserve`, quantité pour les objets empilables, numéro pour les emplacements vides.
- Visée à la direction de la souris, molette pour passer d’une case à l’autre, relâcher `Tab` pour équiper, `Échap` pour fermer.
- Responsive : la roue garde ses proportions de l’écran 4K au téléphone.

## Technologies

React 19, TypeScript 5.8 (strict), Vite 6, CSS et SVG, police Poppins via `@fontsource`, Biome pour le lint et le formatage.

## Démarrer

```bash
npm install
npm run dev
```

L’aperçu s’ouvre sur http://127.0.0.1:5190 avec des données de démonstration.

| Commande         | Rôle                                     |
| ---------------- | ---------------------------------------- |
| `npm run dev`    | Serveur de développement                 |
| `npm run build`  | Vérifie les types puis construit `dist/` |
| `npm run lint`   | Biome et vérification TypeScript         |
| `npm run format` | Formate le code                          |

## Intégration NUI

Dans une ressource FiveM, pointer `ui_page` vers `web/dist/index.html`. La roue est pilotée par messages (`SendNUIMessage`) :

```ts
{ action: 'ouvrir', emplacements: Emplacement[], equipee: number | null, vise?: number | null }
{ action: 'viser', index: number | null }
{ action: 'fermer' }
```

Un emplacement vaut `null` ou :

```ts
{ nom: string, libelle: string, image?: string, munitions?: { chargeur: number, reserve: number }, quantite?: number, categorie?: string }
```

Sans message `viser`, la roue suit la souris elle-même. Elle renvoie ses choix par callbacks NUI :

- `choisir` avec `{ emplacement: number | null }` (`null` pour la main nue)
- `fermer` avec `{}`

## Licence

Distribué sous [GNU LGPL v3](COPYING.LESSER), qui complète la [GNU GPL v3](COPYING).
