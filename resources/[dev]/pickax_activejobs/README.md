# pickax_activejobs — Moteur des métiers actifs

Sept métiers de terrain avec de vraies missions. **Les jobs se créent dans le Job Builder** (`/jobbuilder` → nouveau job), comme tous les autres :
grades, salaires, société, vestiaire, coffre, boss, prise de service (F6), props, factures. Ce script ne gère que le gameplay, l'XP et la paie.

| Type de job (Job Builder) | Déroulement |
|---|---|
| Éboueur | Camion-benne, sacs au bord des routes d'une zone, ramassage à pied, jet à l'arrière ; prime si tournée complète |
| Dépanneur | Voiture en panne, chargement sur la dépanneuse (E), dépose à la fourrière ; paie selon la distance ; missions enchaînées |
| Laveur auto | Clients dans les baies, lavage des 4 côtés (barre de progression), pourboire selon la rapidité |
| Camionneur (poids lourd) | Semi + remorque, destination lointaine, temps limité, état de la cargaison, prime de retour |
| Fermier | Parcelles persistantes (BDD) : semer → arroser → récolter → vendre au marché (graines achetées au marché) |
| Pompier | Incendies **automatiques** (toutes les 7 min si un pompier est en service, ou 20 s après la prise de service), plusieurs foyers, canon du camion / extincteur, prime finale, échec si hors de contrôle |
| Conducteur de train | Métro à conduire (Z/S, Espace = urgence), arrêt précis en station, montée des voyageurs, prime de fin de ligne |

## Mise en place dans le Job Builder
1. `/jobbuilder` → **Nouveau job** → choisis le modèle (Éboueur, Dépanneur…) : grades, blip et actions sont pré-remplis.
2. Onglet **Points** : place un **Poste d'activité** (c'est là que l'employé *en service* démarre ; « sortie du véhicule » optionnelle), puis des **Points d'activité** avec leur rôle :
   zone de ramassage (éboueur), lieu de panne + fourrière (dépanneur), baie de lavage (laveur), destination (camionneur), champ + marché (fermier), lieu d'incendie (pompier), stations dans l'ordre (train).
   Un rôle sans point utilise des valeurs par défaut approximatives. Ajoute aussi vestiaire / coffre / boss comme pour un autre job.
3. Enregistre. Les employés prennent leur service (F6) puis utilisent le poste (E).

XP / niveaux (+3 % de paie par niveau, bonus VIP 5/10/15 %), promotion automatique aux niveaux 5 et 12 (jamais jusqu'au grade boss).
`/finservice` ou fin de service du Job Builder = fin de l'activité. `/ajfire` (admin) déclenche un incendie.

## Installation
`ensure pickax_jobbuilder` puis `ensure pickax_activejobs` ; redémarrer `ox_inventory` (items `wheat_seed`, `corn_seed`, `wheat`, `corn`).
