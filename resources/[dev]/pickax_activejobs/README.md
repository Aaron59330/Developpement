# pickax_activejobs — Métiers actifs

Sept métiers avec de vraies missions. Chaque métier se recrute auprès du PNJ de son dépôt (touche **E**) ; les jobs ESX
(`eboueur`, `depanneur`, `laveurauto`, `camionneur`, `fermier`, `pompier`, `conducteurtrain`) sont créés tout seuls dans la table `jobs`
avec leurs grades (modifiables dans `config.lua`). Progression : XP → niveaux (+3 % de paie par niveau, bonus VIP 5/10/15 %), promotion de grade aux niveaux 5 et 12.

| Métier | Déroulement |
|---|---|
| Éboueur | Camion-benne, sacs au bord des routes d'une zone, on les ramasse à pied et on les jette à l'arrière ; prime si tournée complète |
| Dépanneur | Voiture en panne dans la ville, on la charge sur la dépanneuse (E), on la dépose à la fourrière ; paie selon la distance. Missions enchaînées |
| Laveur auto | Des clients arrivent dans les baies, on lave 4 côtés (barre de progression) ; pourboire selon la rapidité |
| Camionneur | Semi + remorque, destination lointaine, temps limité, état de la cargaison, prime de retour au dépôt |
| Fermier | Parcelles persistantes (BDD) : semer → arroser (pousse 40 % plus vite) → récolter → vendre au marché ; graines achetées au marché |
| Pompier | Incendies **automatiques** (toutes les 7 min si un pompier est en service, ou 20 s après la prise de service) ; plusieurs foyers à éteindre (canon du camion / extincteur), prime à la fin, échec si hors de contrôle |
| Conducteur de train | Métro à conduire (Z/S, Espace = urgence), arrêt précis en station, montée des voyageurs, prime de fin de ligne |

## Installation
1. `ensure pickax_activejobs` (après `es_extended`, `oxmysql`, `ox_inventory`).
2. Redémarrer `ox_inventory` (nouveaux items `wheat_seed`, `corn_seed`, `wheat`, `corn`).
3. Au premier démarrage, si des jobs sont créés, redémarrer `es_extended` pour qu'il les connaisse.

## Placer les points en jeu (admin)
Les coordonnées par défaut sont des valeurs de départ **approximatives** à vérifier :
`/ajpoint <métier> <type> [nom]` (à ta position) · `/ajpoints <métier>` · `/ajdelpoint <id>` · `/ajfire` (déclenche un incendie).
Types : `depot` (PNJ), `spawn` (sortie du véhicule), `scrap` (dépanneur), `bay` (laveur), `dest` (camionneur), `field` / `market` (fermier), `station` (train, dans l'ordre de la ligne).
Dès qu'un type a au moins un point en base, il remplace les valeurs par défaut.

Commandes joueur : `/finservice` termine le service.
