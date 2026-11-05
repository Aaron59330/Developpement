import type { MouseEvent, ReactElement, WheelEvent } from 'react';
import { useEffect, useId, useMemo, useRef, useState } from 'react';
import type { ElementRoue, Emplacement } from './roue';
import { caseDuNumero, caseVisee, disposer, geometrie, TAILLE, voisine } from './roue';
import type { EtatCase } from './Secteur';
import { ContenuSecteur, DessinSecteur } from './Secteur';

export const MAINS_NUES = {
  nom: 'mains_nues',
  libelle: 'Mains nues',
  categorie: 'Corps à corps',
} as const satisfies ElementRoue;

const TOUCHE_OUVERTURE = 'Tab';
const DELAI_MOLETTE_MS = 110;

export interface ProprietesRoulette {
  readonly emplacements: readonly Emplacement[];
  readonly equipee: number | null;
  readonly vise?: number | null;
  readonly choisir?: (emplacement: number | null) => void;
  readonly fermer?: () => void;
  readonly mainsNues?: ElementRoue;
}

interface Zone {
  readonly x: number;
  readonly y: number;
  readonly rayon: number;
}

export function Roulette({
  emplacements,
  equipee,
  vise: viseImpose,
  choisir,
  fermer,
  mainsNues = MAINS_NUES,
}: ProprietesRoulette): ReactElement {
  const id = useId();
  const roue = useRef<HTMLButtonElement>(null);
  const zone = useRef<Zone | null>(null);
  const dernierCran = useRef(0);
  const cases = useMemo(() => disposer(emplacements, mainsNues), [emplacements, mainsNues]);
  const formes = useMemo(() => geometrie(cases.length), [cases.length]);
  const indexEquipee = caseDuNumero(equipee);
  const [viseLocal, setVise] = useState<number | null>(indexEquipee);
  const pilotee = viseImpose !== undefined;
  const vise = pilotee ? viseImpose : viseLocal;

  useEffect(() => {
    if (pilotee) return undefined;
    const mesurer = (): void => {
      const rect = roue.current?.getBoundingClientRect();
      zone.current =
        rect === undefined
          ? null
          : { x: rect.left + rect.width / 2, y: rect.top + rect.height / 2, rayon: rect.width / 2 };
    };
    mesurer();
    window.addEventListener('resize', mesurer);
    return () => window.removeEventListener('resize', mesurer);
  }, [pilotee]);

  const valider = (): void => {
    const visee = vise === null ? undefined : cases[vise];
    if (visee === undefined || visee.element === null) {
      fermer?.();
      return;
    }
    choisir?.(visee.numero);
  };

  const validerRef = useRef(valider);
  validerRef.current = valider;
  useEffect(() => {
    if (pilotee) return undefined;
    const appui = (e: KeyboardEvent): void => {
      if (e.key === TOUCHE_OUVERTURE) e.preventDefault();
      else if (e.key === 'ArrowLeft') setVise((v) => voisine(v, -1));
      else if (e.key === 'ArrowRight') setVise((v) => voisine(v, 1));
      else if (e.key === 'Enter') validerRef.current();
    };
    const relache = (e: KeyboardEvent): void => {
      if (e.key !== TOUCHE_OUVERTURE) return;
      e.preventDefault();
      validerRef.current();
    };
    window.addEventListener('keydown', appui);
    window.addEventListener('keyup', relache);
    return () => {
      window.removeEventListener('keydown', appui);
      window.removeEventListener('keyup', relache);
    };
  }, [pilotee]);

  // Pilotage par le jeu : relâcher la touche valide la case visée (le NUI ne reçoit pas le clavier).
  useEffect(() => {
    const valide = (): void => validerRef.current();
    window.addEventListener('roulette-valider', valide);
    return () => window.removeEventListener('roulette-valider', valide);
  }, []);

  const viser = (e: MouseEvent<HTMLDivElement>): void => {
    const z = zone.current;
    if (z === null) return;
    const dx = e.clientX - z.x;
    const dy = e.clientY - z.y;
    setVise((v) => caseVisee(dx, dy, z.rayon, v));
  };

  const molette = (e: WheelEvent<HTMLDivElement>): void => {
    if (e.timeStamp - dernierCran.current < DELAI_MOLETTE_MS) return;
    dernierCran.current = e.timeStamp;
    setVise((v) => voisine(v, e.deltaY > 0 ? 1 : -1));
  };

  const etatDe = (index: number): EtatCase => {
    if (vise === index) return 'visee';
    if (cases[index]?.element === null) return 'vide';
    return index === indexEquipee ? 'equipee' : 'normale';
  };

  const affiche = vise === null ? (cases[indexEquipee]?.element ?? mainsNues) : (cases[vise]?.element ?? null);

  return (
    <div
      className="roue-calque"
      role="dialog"
      aria-modal="true"
      aria-label="Roulette d’armes"
      onMouseMove={pilotee ? undefined : viser}
      onWheel={pilotee ? undefined : molette}
    >
      <button
        type="button"
        className="roue"
        ref={roue}
        tabIndex={-1}
        aria-label={affiche === null ? 'Fermer' : `Équiper ${affiche.libelle}`}
        onClick={pilotee ? undefined : valider}
      >
        <svg className="roue-dessin" aria-hidden="true" viewBox={`0 0 ${TAILLE} ${TAILLE}`}>
          {formes.map((forme, i) => (
            <DessinSecteur key={cases[i]?.numero ?? 'main'} id={id} index={i} forme={forme} etat={etatDe(i)} />
          ))}
        </svg>
        {formes.map((forme, i) => (
          <ContenuSecteur
            key={cases[i]?.numero ?? 'main'}
            element={cases[i]?.element ?? null}
            numero={cases[i]?.numero ?? null}
            forme={forme}
            vise={vise === i}
          />
        ))}
        <span className="roue-coeur" aria-live="polite">
          <span className="roue-nom">{affiche?.libelle ?? 'Emplacement libre'}</span>
          <span className="roue-categorie">{affiche?.categorie ?? ''}</span>
        </span>
      </button>
    </div>
  );
}
