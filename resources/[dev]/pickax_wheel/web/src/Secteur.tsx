import type { CSSProperties, ReactElement } from 'react';
import { memo } from 'react';
import poing from './assets/poing.png';
import type { ElementRoue, Emplacement, GeometrieCase } from './roue';
import { ARRONDI, BORDURE, RAYON_EXTERIEUR, RAYON_INTERIEUR, RAYON_TRAIT, TAILLE } from './roue';

export type EtatCase = 'vide' | 'normale' | 'equipee' | 'visee';

export const palette = { rose: 'rgb(255, 170, 205)', turquoise: 'rgb(64, 224, 208)' };
const OPACITE_FOND = 0.1;
const OPACITE_BORD = { vide: 0.25, normale: 0.25, equipee: 0.25, visee: 0.4 } as const satisfies Record<
  EtatCase,
  number
>;
const POSITION_TRAIT = (RAYON_TRAIT - RAYON_INTERIEUR) / (RAYON_EXTERIEUR - RAYON_INTERIEUR);

function couleurDe(etat: EtatCase): string | null {
  if (etat === 'visee') return palette.rose;
  if (etat === 'equipee') return palette.turquoise;
  return null;
}

interface ProprietesDessin {
  readonly id: string;
  readonly index: number;
  readonly forme: GeometrieCase;
  readonly etat: EtatCase;
}

export const DessinSecteur = memo(function DessinSecteur({ id, index, forme, etat }: ProprietesDessin): ReactElement {
  const couleur = couleurDe(etat);
  const axe = `${id}-axe-${index}`;
  const bord = `${id}-bord-${index}`;
  const lueur = `${id}-lueur-${index}`;
  return (
    <g>
      <defs>
        <linearGradient id={axe} gradientUnits="userSpaceOnUse" {...forme.axe}>
          <stop offset="0" stopColor="#fff" stopOpacity="0.5" />
          <stop offset={POSITION_TRAIT} stopColor="#fff" stopOpacity="1" />
          <stop offset="0.62" stopColor="#fff" stopOpacity="0" />
        </linearGradient>
        <mask id={bord} maskUnits="userSpaceOnUse" x="0" y="0" width={TAILLE} height={TAILLE}>
          <rect width={TAILLE} height={TAILLE} fill="#fff" />
          <path d={forme.chemin} fill="#000" stroke="#000" strokeWidth={ARRONDI} strokeLinejoin="round" />
        </mask>
        <mask id={lueur} maskUnits="userSpaceOnUse" x="0" y="0" width={TAILLE} height={TAILLE}>
          <path
            d={forme.chemin}
            fill={`url(#${axe})`}
            stroke={`url(#${axe})`}
            strokeWidth={ARRONDI}
            strokeLinejoin="round"
          />
        </mask>
      </defs>
      <path
        d={forme.chemin}
        fill="#fff"
        stroke="#fff"
        strokeWidth={ARRONDI}
        strokeLinejoin="round"
        opacity={OPACITE_FOND}
      />
      <rect
        className="teinte"
        width={TAILLE}
        height={TAILLE}
        fill={couleur ?? palette.rose}
        opacity={couleur === null ? 0 : etat === 'visee' ? 0.55 : 0.4}
        mask={`url(#${lueur})`}
      />
      <path
        className="bord"
        d={forme.chemin}
        fill="none"
        stroke="#fff"
        strokeOpacity={OPACITE_BORD[etat]}
        strokeWidth={ARRONDI + BORDURE * 2}
        strokeLinejoin="round"
        mask={`url(#${bord})`}
      />
      <path
        className="trait"
        d={forme.trait}
        fill="none"
        stroke={couleur ?? '#c4c8cf'}
        strokeOpacity={couleur === null ? 0.8 : 1}
        strokeWidth={1}
        strokeLinecap="round"
      />
    </g>
  );
});

interface ProprietesContenu {
  readonly element: Emplacement;
  readonly numero: number | null;
  readonly forme: GeometrieCase;
  readonly vise: boolean;
}

type StyleDecalage = CSSProperties & Readonly<Record<'--fx' | '--fy', number>>;

function styleDecalage({ decalage }: GeometrieCase): StyleDecalage {
  return { '--fx': decalage.x, '--fy': decalage.y };
}

function imageDe(element: ElementRoue): string {
  return element.image ?? poing;
}

export const ContenuSecteur = memo(function ContenuSecteur({
  element,
  numero,
  forme,
  vise,
}: ProprietesContenu): ReactElement {
  const munitions = element?.munitions;
  return (
    <span className={vise ? 'roue-contenu vise' : 'roue-contenu'} style={styleDecalage(forme)}>
      {element === null ? (
        <span className="roue-numero" role="img" aria-label={`Emplacement ${numero ?? ''} libre`}>
          {numero}
        </span>
      ) : (
        <>
          <img src={imageDe(element)} alt={element.libelle} decoding="async" draggable={false} />
          {munitions !== undefined && (
            <span className="roue-munitions">
              {munitions.chargeur} / {munitions.reserve}
            </span>
          )}
          {munitions === undefined && element.quantite !== undefined && (
            <span className="roue-compte">{element.quantite}x</span>
          )}
        </>
      )}
    </span>
  );
});
