import type { ReactElement } from 'react';
import { lazy, Suspense, useCallback, useEffect, useState } from 'react';
import { BarriereErreur } from './BarriereErreur';
import { enJeu, envoyer, estMessageRoulette } from './nui';
import { Roulette } from './Roulette';
import { palette } from './Secteur';
import type { Emplacement } from './roue';

const Apercu = lazy(() => import('./Apercu'));

interface Ouverture {
  readonly emplacements: readonly Emplacement[];
  readonly equipee: number | null;
  readonly vise: number | null | undefined;
}

function RouletteJeu(): ReactElement | null {
  const [ouverture, setOuverture] = useState<Ouverture | null>(null);

  useEffect(() => {
    const recevoir = (e: MessageEvent<unknown>): void => {
      const message = e.data;
      if (!estMessageRoulette(message)) return;
      switch (message.action) {
        case 'ouvrir':
          if (message.couleurs?.vise !== undefined) palette.rose = message.couleurs.vise;
          if (message.couleurs?.equipee !== undefined) palette.turquoise = message.couleurs.equipee;
          // côté Lua, une case vide ou « rien d'équipé » arrive sous forme de `false` (pas de null en JSON Lua)
          setOuverture({
            emplacements: message.emplacements.map((e) => (e ? e : null)),
            equipee: message.equipee ? message.equipee : null,
            vise: message.vise,
          });
          return;
        case 'viser':
          setOuverture((o) => (o === null ? o : { ...o, vise: message.index }));
          return;
        case 'valider':
          window.dispatchEvent(new Event('roulette-valider'));
          return;
        case 'fermer':
          setOuverture(null);
          return;
        default: {
          const exhaustif: never = message;
          throw new Error(`message de roulette inconnu : ${JSON.stringify(exhaustif)}`);
        }
      }
    };
    window.addEventListener('message', recevoir);
    return () => window.removeEventListener('message', recevoir);
  }, []);

  const fermer = useCallback((): void => {
    setOuverture(null);
    envoyer({ nom: 'fermer' });
  }, []);

  const choisir = useCallback((emplacement: number | null): void => {
    setOuverture(null);
    envoyer({ nom: 'choisir', emplacement });
  }, []);

  useEffect(() => {
    if (ouverture === null) return undefined;
    const echap = (e: KeyboardEvent): void => {
      if (e.key === 'Escape') fermer();
    };
    window.addEventListener('keydown', echap);
    return () => window.removeEventListener('keydown', echap);
  }, [ouverture, fermer]);

  if (ouverture === null) return null;
  return (
    <Roulette
      emplacements={ouverture.emplacements}
      equipee={ouverture.equipee}
      {...(ouverture.vise === undefined ? {} : { vise: ouverture.vise })}
      fermer={fermer}
      choisir={choisir}
    />
  );
}

export function App(): ReactElement {
  return (
    <BarriereErreur>
      {enJeu ? (
        <RouletteJeu />
      ) : (
        <Suspense fallback={null}>
          <Apercu />
        </Suspense>
      )}
    </BarriereErreur>
  );
}
