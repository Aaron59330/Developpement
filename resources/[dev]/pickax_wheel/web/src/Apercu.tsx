import type { ReactElement } from 'react';
import { useState } from 'react';
import { EMPLACEMENTS_DEMO } from './donnees';
import { Roulette } from './Roulette';

const ignorer = (): void => undefined;

export default function Apercu(): ReactElement {
  const [equipee, setEquipee] = useState<number | null>(1);
  return (
    <main className="apercu">
      <Roulette emplacements={EMPLACEMENTS_DEMO} equipee={equipee} choisir={setEquipee} fermer={ignorer} />
    </main>
  );
}
