import bandage from './assets/demo/bandage.webp';
import couteau from './assets/demo/couteau.webp';
import gilet from './assets/demo/gilet.webp';
import pistolet from './assets/demo/pistolet.webp';
import type { Emplacement } from './roue';

export const EMPLACEMENTS_DEMO: readonly Emplacement[] = [
  {
    nom: 'pistolet_combat',
    libelle: 'Pistolet de combat',
    categorie: 'Arme de poing',
    image: pistolet,
    munitions: { chargeur: 20, reserve: 80 },
  },
  { nom: 'gilet', libelle: 'Gilet pare-balles', categorie: 'Équipement', image: gilet, quantite: 1 },
  { nom: 'bandage', libelle: 'Bandage', categorie: 'Soins', image: bandage, quantite: 6 },
  { nom: 'couteau', libelle: 'Couteau', categorie: 'Corps à corps', image: couteau },
  null,
];
