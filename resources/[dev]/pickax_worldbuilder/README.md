# worldbuilder — World Builder ESX complet (UI + oxmysql)

Crée **en jeu** (sans toucher au code ni redémarrer) :

| Module | Ce que tu peux faire |
|---|---|
| **Garages** | Garages publics, ports, hangars (types de véhicules filtrables), garages **liés**, **flotte de métier** (véhicules prêtés par grade), frais de sortie, plusieurs places de sortie, point de rangement séparé, PNJ, blip |
| **Fourrières** | Récupération payante (frais de base + par jour + plafond), **mise en fourrière par un métier** (raison + frais), véhicules « perdus » récupérables, société créditée, export serveur `ImpoundVehicle` |
| **Locations** | Flotte louable (prix, **caution**, durée max), caution rendue au retour (réduite selon les dégâts), point de retour séparé, expiration automatique |
| **Stations essence** | Pompes illimitées, prix au litre, **cuve** avec stock et réapprovisionnement, plein avec animation, vente de **jerricanes**, société créditée |
| **Drogues** | Filières complètes : **récolte** (épuisement/repousse, outil, cooldown), **laboratoires** (recettes multi-ingrédients, lots, chance de raté, outil), **portes/intérieurs** (téléportation), **vente dealer** (prix aléatoires, limite horaire), **blanchiment** (taux, limites) — alertes police, policiers requis, accès par métier/gang/item clé |
| **Banques** | Agences (guichets avec agent) et distributeurs : dépôt, retrait, virement entre joueurs, frais en %, limites par opération et par jour, société créditée |
| **Auto-écoles** | Permis configurables (code, moto, camion…) : **code de la route en QCM** (banque de questions, tirage au sort, % de réussite) puis **conduite sur parcours** (points de passage, limite de vitesse, fautes max, véhicule d'examen), prix, permis prérequis, délai avant de repasser ; compatible esx_license (sinon table interne) |
| **Stations de lavage** | Baies de lavage avec programmes payants (nom, prix, durée), véhicule immobilisé pendant le lavage puis nettoyé, société créditée |
| **Serruriers** | Duplicata de clés de véhicules possédés (véhicule présent près de l'atelier, vérifié serveur), prix, délai anti-spam ; **branché sur ton script de clés** (core `pickax_core` : `open_car` + `RegisterNewKeys`, voir `patches/vehicle`), ou item ox_inventory avec la plaque, ou hooks `Config.GiveKey` / `Config.GiveKeys` |
| **Portes** | Portes verrouillables du jeu (visées en jeu, portes doubles) : accès par **métier**, par **job2 / gang** et par item clé, reverrouillage automatique, **touche (L par défaut) pour verrouiller / déverrouiller la porte la plus proche**, état synchronisé pour tous |
| **Occasion** | Annonces de véhicules entre joueurs (type leboncoin) : menu de mise en vente (prix, description, téléphone), véhicule **exposé sur une place** avec ses infos affichées au-dessus, achat, retrait, modification du prix, frais + commission, expiration, versement au vendeur même hors ligne |
| **Courses poursuites** | Intégration de *pickax_chase* : lobbies multijoueurs fugitif / poursuivants, choix du véhicule (stats), partie isolée (routing bucket), compte à rebours, avance du fugitif, détection de contact **100 % serveur**, HUD, récompenses, classement ; PNJ d'accueil, cartes et véhicules gérés dans l'éditeur |
| **Zones PVP** | Intégration de *pickax_pvp* : zones de combat (rayon, couleur, murs visibles), **armes données à l'entrée et retirées à la sortie** (natif ou ox_inventory), revive automatique avec réapparition sur spawns, invincibilité, munitions infinies, soin au kill, récompense par kill, kill-feed, HUD, classement |
| **Pôles emploi** | Guichet avec PNJ : menu de **petits jobs en libre accès** (jardinier, bricoleur, électricien, plombier, déménageur, laveur de vitres, ouvrier de chantier, coursier). Un clic = `setJob` automatique ; les jobs, leurs 3 grades et leur fiche jobbuilder sont **créés tout seuls dans la base** dès qu'un module Pôle emploi est enregistré (`/wbjobs` pour forcer). Chaque job a 3 **quêtes** (aller sur place, travailler avec une animation, être payé), promotion automatique par grade, gains selon le grade ; lancement depuis le guichet ou depuis **F6 → Mes quêtes**, départ du job depuis F6 → Quitter le métier. **Tout est modifiable dans le builder** (module Pôle emploi → onglet *Jobs & quêtes* : « Personnaliser », puis chaque job, ses grades/salaires, ses quêtes — nom, description, animation, durée, gains, textes — et les lieux des quêtes). L'embauche se fait **uniquement au marker du guichet** ; F6 sert à quitter le job et à voir « Mes quêtes ». Réglages : `Config.JobCenter` |
| **Braquages** | Supérettes, magasins d'alcool, stations, banques, bijouteries ou **tout ce que tu inventes** : déclenchement « en joue » sur le vendeur *ou* touche E, caisses / coffres / coffre-fort / butin, mini-jeux (ox_lib), outils requis, policiers requis, cooldown persistant, alerte police, gardes armés, mode coopératif, butin cash + items avec probabilités |

Interface au même style que le Shop Builder, réservée aux groupes ESX (`_dev`, `admin`, `superadmin`), **droits vérifiés côté serveur à chaque action**.

## Installation
1. Copie le dossier `pickax_worldbuilder` dans `resources/`.
2. `server.cfg` (après les dépendances) :
   ```
   ensure oxmysql
   ensure es_extended
   ensure ox_inventory   # optionnel : l'inventaire ESX classique fonctionne aussi
   ensure ox_lib         # optionnel : mini-jeux (perçage, piratage…)
   ensure pickax_worldbuilder
   ```
3. Les tables `worldbuilder_*` sont dans `database.sql` à la racine du serveur (importe-le) ; si `sql/install.sql` existe dans la ressource, elles se créent aussi toutes seules au démarrage.
4. **OneSync activé** (nécessaire pour la gestion serveur des véhicules).
5. En jeu : `/worldbuilder`.

## Créer un module en 1 minute
1. `/worldbuilder` → **Nouveau module** → choisis le type (garage, fourrière, location, station, drogue, braquage) puis un **modèle** (ex : *Supérette 24/7*, *Cannabis*, *Banque*…).
2. Onglet **Points / Emplacements** → **Mode placement** : marche librement, `Entrée` enregistre ta position pour la cible suivante, `←/→` change de cible, `Retour` revient au menu. Pour un garage, ajoute aussi ses **places de sortie**.
3. Ajuste les réglages (onglets Règles / Véhicules / Flotte / Station…). Les items inconnus de ton serveur sont signalés par un avertissement.
4. Onglet **Général** → coche **Module actif** → **Enregistrer**. Visible immédiatement pour tous.

## Adapter à ton serveur (`config.lua`)
- `Config.Vehicles` : table/colonnes des véhicules joueurs (défaut `owned_vehicles`). Au démarrage, le script détecte les colonnes : si `stored` manque il utilise `state` ou l'ajoute automatiquement ; si `type` manque, le filtre par type est désactivé.
- `Config.OnRestart` : que deviennent les véhicules sortis au redémarrage (`'garage'`, `'impound'`, `'none'`).
- `Config.PoliceJobs` : métiers comptés comme police (alertes, policiers requis).
- `Config.AlertHook(coords, titre, message)` : brancher ps-dispatch / cd_dispatch / qs-dispatch (retourne `true` si géré).
- `Config.GiveKeys(plate, vehicle)` : clés de véhicule (qs-vehiclekeys, wasabi_carlock…).
- `Config.GetFuel / SetFuel` : carburant (ox_fuel, LegacyFuel ou natif).
- `Config.Templates` : **modèles** de modules (ajoute les tiens), `Config.Animations`, `Config.Payments`, `Config.Marker`, `Config.Target = 'ox_target'`.
- Noms d'items des modèles (`weed`, `weed_pooch`, `coke_pooch`, `thermite`, `drill`…) : à adapter à ton inventaire — modifiable ensuite en jeu.

## Sécurité
- Prix, quantités, gains, accès, distances, cooldowns, policiers requis et moyens de paiement sont **recalculés côté serveur** ; le client ne fait que demander une action.
- Les actions chronométrées (récolte, fabrication, plein, braquage) passent par `begin → finish` : le serveur refuse un `finish` trop rapide, éloigné ou sans `begin`.
- Toutes les données du builder passent par un **nettoyeur à schéma** (types, bornes, noms d'items/modèles, métiers existants).
- Véhicules : propriété vérifiée en base, véhicule réel vérifié (entité serveur, plaque, distance).

## Dépannage
- `/wbreset` : débloque l'interface si elle reste « ouverte ».
- « Aucune place de sortie » : ajoute des places au garage / fourrière / location (carte du point → *Places de sortie*).
- Item en rouge dans le builder : il n'existe pas dans ton inventaire.
- Un véhicule sorti du garage n'apparaît pas en fourrière : il existe encore dans le monde ; il y sera listé dès qu'il a disparu (ou au redémarrage avec `Config.OnRestart = 'impound'`).

## Limites connues
- Les locations en cours ne survivent pas à un redémarrage de la ressource (mémoire).
- Les gardes de braquage sont créés par le client du braqueur.

## Migration depuis pickax_chase
Le module **Courses poursuites** reprend `pickax_chase` : arrête l'ancienne ressource (`stop pickax_chase`) pour éviter les doublons. Ses tables (`pickax_chase_*`) ne sont pas lues ; le classement repart de zéro dans `worldbuilder_chase_stats`. Crée le module (modèle « Course poursuite » : 16 véhicules et 3 cartes d'exemple), place le PNJ d'accueil et ajuste les cartes.

## Migration depuis pickax_pvp
Arrête `pickax_pvp` avant de lancer `worldbuilder`. Le module **Zones PVP** (modèle « Zones PVP ») reprend ses fonctions : PNJ d'accueil et zones deviennent des points du module (la zone est placée à ta position, centre = position). Les anciennes tables `pickax_pvp_*` ne sont pas lues ; le classement repart de zéro (`worldbuilder_pvp_stats`). Config des scripts d'ambulance : ignorer la mort quand `LocalPlayer.state.inPvpZone` est vrai, ou renseigner `Config.Pvp.ReviveEvents`.

## Job Gazoline (ravitaillement des stations essence)
- Le job `gazoline` (3 grades) est créé automatiquement et proposé au **Pôle emploi**. Le dépôt se définit en jeu : place-toi à l'endroit voulu et tape **`/gazdepot`** (groupe admin).
- Les livreurs en service chargent une citerne au dépôt (**E**, camion + citerne apparaissent 10 m devant), reçoivent la station qui en a le plus besoin, la livrent (décharger avec **E**) et rendent le camion pour une prime. Paie au litre, majorée si la station est presque vide.
- Les stations (module « Station essence ») se vident à chaque plein ; les livreurs sont prévenus sous 20 %.
- **Réserve de secours** : il reste toujours au moins une station avec de l'essence (la station de plus grande cuve est remplie à 15 % si toutes sont à sec).
- Tout se règle dans `Config.Gazoline` (`config.lua`).

## Pré-placement automatique
Au premier démarrage, **27 stations essence** (une cuve par station) et **8 agences bancaires** sont créées et activées, une seule fois. `Config.Preset` pour modifier, `/wbseed` (admin) pour recréer ce qui manque.
