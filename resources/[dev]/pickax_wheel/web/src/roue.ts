export interface Munitions {
  readonly chargeur: number;
  readonly reserve: number;
}

export interface ElementRoue {
  readonly nom: string;
  readonly libelle: string;
  readonly image?: string | undefined;
  readonly munitions?: Munitions | undefined;
  readonly quantite?: number | undefined;
  readonly categorie?: string | undefined;
}

export type Emplacement = ElementRoue | null;

export interface CaseDisposee {
  readonly element: Emplacement;
  readonly numero: number | null;
}

export interface GeometrieCase {
  readonly chemin: string;
  readonly trait: string;
  readonly axe: { readonly x1: number; readonly y1: number; readonly x2: number; readonly y2: number };
  readonly decalage: { readonly x: number; readonly y: number };
}

export const EMPLACEMENTS = 5;
export const CASES = EMPLACEMENTS + 1;
export const POSITION_MAIN = 3;
export const DEPART_EMPLACEMENTS = 4;
export const HYSTERESIS_DEGRES = 6;

export const TAILLE = 200;
export const CENTRE = TAILLE / 2;
export const RAYON_EXTERIEUR = 97;
export const RAYON_INTERIEUR = 56;
export const RAYON_TRAIT = RAYON_INTERIEUR + 5;
export const ECART = 2.2;
export const BORDURE = 0.7;
export const ARRONDI = 3.2;

const radians = (degres: number) => (degres * Math.PI) / 180;
const degres = (radians: number) => (radians * 180) / Math.PI;
const arrondir = (n: number) => Math.round(n * 100) / 100;

function point(rayon: number, angle: number): readonly [number, number] {
  return [arrondir(CENTRE + rayon * Math.cos(radians(angle))), arrondir(CENTRE + rayon * Math.sin(radians(angle)))];
}

export function angleCase(index: number, total: number): number {
  return -90 + (index * 360) / total;
}

function cheminCase(index: number, total: number): string {
  const angle = angleCase(index, total);
  const demi = 180 / total;
  const marge = ECART / 2 + ARRONDI / 2;
  const exterieur = RAYON_EXTERIEUR - ARRONDI / 2;
  const interieur = RAYON_INTERIEUR + ARRONDI / 2;
  const ecartExterieur = degres(Math.asin(marge / exterieur));
  const ecartInterieur = degres(Math.asin(marge / interieur));
  const [x1, y1] = point(exterieur, angle - demi + ecartExterieur);
  const [x2, y2] = point(exterieur, angle + demi - ecartExterieur);
  const [x3, y3] = point(interieur, angle + demi - ecartInterieur);
  const [x4, y4] = point(interieur, angle - demi + ecartInterieur);
  return `M${x1} ${y1}A${exterieur} ${exterieur} 0 0 1 ${x2} ${y2}L${x3} ${y3}A${interieur} ${interieur} 0 0 0 ${x4} ${y4}Z`;
}

function traitCase(index: number, total: number): string {
  const angle = angleCase(index, total);
  const demi = 180 / total;
  const ecart = degres(Math.asin((ECART / 2 + ARRONDI + 2) / RAYON_TRAIT));
  const [x1, y1] = point(RAYON_TRAIT, angle - demi + ecart);
  const [x2, y2] = point(RAYON_TRAIT, angle + demi - ecart);
  return `M${x1} ${y1}A${RAYON_TRAIT} ${RAYON_TRAIT} 0 0 1 ${x2} ${y2}`;
}

function decalageCase(index: number, total: number): GeometrieCase['decalage'] {
  const [x, y] = point((RAYON_EXTERIEUR + RAYON_INTERIEUR) / 2, angleCase(index, total));
  return { x: arrondir((x - CENTRE) / TAILLE), y: arrondir((y - CENTRE) / TAILLE) };
}

function axeCase(index: number, total: number): GeometrieCase['axe'] {
  const angle = angleCase(index, total);
  const [x1, y1] = point(RAYON_INTERIEUR, angle);
  const [x2, y2] = point(RAYON_EXTERIEUR, angle);
  return { x1, y1, x2, y2 };
}

export function geometrie(total: number): readonly GeometrieCase[] {
  return Array.from({ length: total }, (_, i) => ({
    chemin: cheminCase(i, total),
    trait: traitCase(i, total),
    axe: axeCase(i, total),
    decalage: decalageCase(i, total),
  }));
}

export function disposer(emplacements: readonly Emplacement[], main: ElementRoue): readonly CaseDisposee[] {
  const cases: CaseDisposee[] = Array.from({ length: CASES }, () => ({ element: null, numero: null }));
  cases[POSITION_MAIN] = { element: main, numero: null };
  for (let k = 0; k < EMPLACEMENTS; k++) {
    cases[(DEPART_EMPLACEMENTS + k) % CASES] = { element: emplacements[k] ?? null, numero: k + 1 };
  }
  return cases;
}

export function caseDuNumero(numero: number | null): number {
  return numero === null ? POSITION_MAIN : (DEPART_EMPLACEMENTS + numero - 1) % CASES;
}

export function secteurVise(x: number, y: number, total: number, actuel: number | null): number {
  const angle = (degres(Math.atan2(y, x)) + 90 + 360) % 360;
  const pas = 360 / total;
  if (actuel !== null) {
    const ecart = Math.abs(((angle - actuel * pas + 540) % 360) - 180);
    if (ecart < pas / 2 + HYSTERESIS_DEGRES) return actuel;
  }
  return Math.round(angle / pas) % total;
}

export function caseVisee(dx: number, dy: number, rayon: number, actuelle: number | null): number | null {
  if (Math.hypot(dx, dy) < (rayon * RAYON_INTERIEUR) / CENTRE) return actuelle;
  return secteurVise(dx, dy, CASES, actuelle);
}

export function voisine(index: number | null, sens: 1 | -1): number {
  if (index === null) return sens === 1 ? 0 : CASES - 1;
  return (index + sens + CASES) % CASES;
}
