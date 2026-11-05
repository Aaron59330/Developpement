import type { Emplacement } from './roue';

export type MessageRoulette =
  | {
      readonly action: 'ouvrir';
      readonly emplacements: readonly Emplacement[];
      readonly equipee: number | null;
      readonly vise?: number | null;
      readonly couleurs?: { readonly vise?: string; readonly equipee?: string };
    }
  | { readonly action: 'viser'; readonly index: number | null }
  | { readonly action: 'valider' }
  | { readonly action: 'fermer' };

export type RetourRoulette =
  | { readonly nom: 'choisir'; readonly emplacement: number | null }
  | { readonly nom: 'fermer' };

declare global {
  interface Window {
    GetParentResourceName?: () => string;
  }
}

export const enJeu: boolean = typeof window.GetParentResourceName === 'function';

export function estMessageRoulette(donnees: unknown): donnees is MessageRoulette {
  if (typeof donnees !== 'object' || donnees === null || !('action' in donnees)) return false;
  const { action } = donnees;
  return action === 'ouvrir' || action === 'viser' || action === 'valider' || action === 'fermer';
}

export function envoyer(retour: RetourRoulette): void {
  const ressource = window.GetParentResourceName?.();
  if (ressource === undefined) return;
  const { nom, ...corps } = retour;
  void fetch(`https://${ressource}/${nom}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(corps),
  }).catch(() => undefined);
}
