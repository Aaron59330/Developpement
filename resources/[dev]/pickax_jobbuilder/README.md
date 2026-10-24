# jobbuilder — Job Builder ESX complet (UI + oxmysql)

Crée des jobs **police, EMS, mécano, taxi, agence immobilière, bar, personnalisé** directement en jeu, avec garages, vestiaires, armureries, coffres, boutiques et gestion boss. Réservé au groupe ESX `_dev` (modifiable dans `config.lua`).

## Installation
1. Copie le dossier `pickax_jobbuilder` dans `resources/`.
2. `server.cfg` (après les dépendances) :
   ```
   ensure oxmysql
   ensure es_extended
   ensure ox_inventory
   ensure pickax_jobbuilder
   ```
3. Les tables `jobbuilder_jobs`, `jobbuilder_points`, `jobbuilder_logs` se créent **toutes seules** au démarrage (ou importe `sql/install.sql`).
4. En jeu : `/jobbuilder` (groupe `_dev` requis, vérifié côté serveur à chaque action).

## Où sont écrits les jobs (ta base)
| Table | Contenu |
|---|---|
| `jobs` | name, label, whitelisted |
| `job_grades` | grades + salaires (uniquement ceux du job concerné) |
| `addon_account` / `addon_account_data` | compte `society_<job>` |
| `addon_inventory`, `datastore`, `datastore_data` | stockage société (compat. esx_addonaccount / esx_datastore / esx_society) |
| `jobbuilder_*` | points, blip, réglages, logs |

**Pas de mélange entre jobs :**
- un job existant dans `jobs` (ex. `lspd`, `ambulance`, `LsCustoms`) ou dans `jobs2` n'est **jamais** écrasé : le builder refuse le nom ;
- chaque point (garage, armurerie, coffre…) n'est utilisable que par **son** job, avec grade minimum, contrôlé côté serveur (job + grade + distance) ;
- chaque job a son compte société, son coffre `jobbuilder_<id>`, ses plaques, ses logs ;
- suppression = uniquement les lignes créées par le builder pour ce job ; les joueurs repassent `unemployed`.
- Les tables `jobs2`, `job2_grades`, `gangbuilder`, `entreprise`, `society` ne sont pas touchées.

## Fonctionnalités
- **Templates** : police, ems, mecano, taxi, realestate, bar, custom (grades, blip, actions pré-remplis, tout modifiable).
- **Grades** : ajout / suppression / ordre / salaires, grade « boss ».
- **Points** : 📍 *Ma position* + TP pour chaque point.
  - **Garage** : un job peut en avoir **plusieurs, de types différents** — 🚗 voitures, 🏍️ motos & vélos, ✈️ avions & hélicoptères, ⛵ bateaux. Chaque garage a son type, sa sortie (dans l'eau pour un bateau, sur une piste pour un avion), ses véhicules par grade (suggestions filtrées par type d'après ta table `vehicles`, validation du modèle, **« Ajouter toute la catégorie »** en un clic), son marker (réglable dans Paramètres → Markers des points). Le rangement n'accepte que le bon type de véhicule (d'après sa classe GTA) ; le dégagement exigé à la sortie est plus large pour bateaux et aéronefs (`Config.GarageKinds`).
  - **Vestiaire** : tenues H/F capturées en jeu, par grade + retour tenue civile.
  - **Armurerie** : armes/objets (catalogue ox_inventory), quantité, munitions, grade.
  - **Coffre** : stash ox_inventory restreint au job/grade.
  - **Boss** : solde société, dépôt/retrait, recruter, promouvoir/rétrograder, virer (même hors ligne), salaires, journal.
  - **Boutique** : privée ou publique, l'argent va à la société.
- **Menu métier (F6)** : menotter, escorter, fouiller (police) · réanimer, soigner (EMS) · réparer, nettoyer (mécano) · facturer (tous, paiement → société).
- **Blip** du job sur la carte, **logs** en base (+ webhook Discord optionnel).
- Le brouillon reste en mémoire quand tu fermes avec Échap (pour aller relever des coordonnées / une tenue).

## 🚜 Métiers actifs (types Éboueur, Dépanneur, Laveur auto, Camionneur, Fermier, Pompier, Conducteur de train)
Tout est dans le Job Builder (aucune autre ressource). Crée le job avec son modèle, puis dans l'onglet **Points** : un **Poste d'activité** (l'employé *en service* y démarre son activité) et des **Points d'activité** avec un rôle (zone de ramassage, lieu de panne, fourrière, baie, destination, champ, marché, incendie, station — pour le train, l'ordre de création = l'ordre de la ligne). Un rôle sans point utilise des positions par défaut approximatives.
- Éboueur : camion-benne, sacs à ramasser à pied puis à jeter à l'arrière, prime de tournée. Dépanneur : charger la voiture en panne sur la dépanneuse et la déposer à la fourrière (paie à la distance). Laveur : clients dans les baies, 4 côtés à laver, pourboire. Camionneur : semi + remorque, destination lointaine, temps limité, état de la cargaison, prime de retour.
- Fermier : parcelles persistantes (semer, arroser, récolter, vendre ; graines au marché). Pompier : incendies automatiques (toutes les 7 min, ou 20 s après la prise de service), plusieurs foyers, canon du camion / extincteur, prime finale. Conducteur : métro à conduire, arrêts précis en station.
- XP / niveaux (+3 % de paie par niveau, bonus VIP 5/10/15 %), promotion automatique aux niveaux 5 et 12 (jamais jusqu'au grade boss). Réglages et lieux par défaut : `config_active.lua`. `/finservice` termine l'activité, `/ajfire` (admin) déclenche un incendie. Tables `activejobs_stats` et `activejobs_farm` créées automatiquement ; items ox_inventory `wheat_seed`, `corn_seed`, `wheat`, `corn`.

## 🏠 Agence immobilière (jobs de type `realestate`)
Les agents ouvrent **F6 → Gestion immobilière** (aucune case à cocher : automatique pour ce type de job).
- **Tableau de bord** : revenus 30 jours, taux d'occupation, biens disponibles / vendus / loués, activité récente.
- **Créer une propriété** : nom, adresse, vente ou location (loyer / semaine), intérieur (préréglages ou *Intérieur personnalisé* = ton MLO / shell), position de l'entrée, **coffres** (emplacements + poids) et **penderies** à placer à l'intérieur.
- **Visiter** un bien disponible (instance séparée), **vendre / louer au client le plus proche** : le client reçoit l'offre à l'écran et paie ; commission configurable pour l'agent (le reste va à la société de l'agence).
- **Côté joueur** (marker à la porte) : entrer, sonner (les occupants acceptent / refusent), doubles de clés (4 max), payer le loyer, résilier le bail, penderie personnelle (10 tenues), coffre ox_inventory réservé au propriétaire et aux clés.
- **Sécurité** : chaque propriété est une instance (routing bucket) ; coffres verrouillés par hook ox_inventory (propriétaire / clés, présents dans le bien) ; loyers impayés → expulsion automatique et coffre vidé ; suppression d'un bien occupé refusée.
- Tables dédiées `jobbuilder_properties*` — ta table `properties` / `owned_properties` n'est pas utilisée.
- Réglages d'agence dans le builder (onglet Général) : commission, grade min. pour créer/vendre, grade min. pour supprimer/reprendre. Réglages globaux : `Config.Real` (durée de loyer, limites, blips, intérieurs).
- ⚠ Les coordonnées des intérieurs préréglés (`Config.Real.Interiors`) sont les emplacements GTA Online classiques : vérifie-les en jeu, sinon utilise « Intérieur personnalisé ».
- Pour placer un coffre / une penderie : enregistre le bien → **Visiter** → F6 → **Modifier** → « Ma position » depuis l'intérieur.

## 🛋️ Meubles (propriétaires)
Dans sa propriété, le **propriétaire** appuie sur **F10** (ou `/decorer`) : menu de décoration (catalogue par catégories, recherche, « Mes meubles » avec déplacer / retirer). Mode placement avec fantôme : flèches ← → ou molette pour tourner, ↑ ↓ pour la hauteur, Entrée pour poser. **Limite par propriété : 10 meubles**, **15 / 20 / 30** avec le VIP Bronze / Argent / Or du propriétaire (`Config.Real.Furniture`, catalogue modifiable). Les meubles sont enregistrés en base (`jobbuilder_furniture`), visibles par tous les occupants, et supprimés si la propriété est reprise ou remise en vente.

## 🚗 Concessionnaire (jobs de type `dealer`)
**F6 → Gestion concession** (automatique) :
- **Catalogue automatique** : une concession vend **directement tous les véhicules de ta table `vehicles`** (prix de la table × marge réglable). Filtre par **catégories** (ex : une concession de motos = `motorcycles` + `velo`) et marge dans le builder (carte Concession). Option désactivable pour un catalogue 100 % manuel.
- **Catalogue & prix** (direction) : recherche + filtre par catégorie ; modifier un prix, un stock (-1 = illimité), un grade minimum, un type ou masquer un véhicule crée un **ajustement** (cadre jaune, annulable en un clic) ; véhicules personnalisés hors table possibles. Le type écrit dans `owned_vehicles` vient de la catégorie (`Config.Dealer.CategoryTypes`).
- **Vente au client** : le vendeur choisit un véhicule, le **client le plus proche** reçoit l'offre à l'écran et paie. Commission du vendeur réglable, le reste va à la société.
- **Libre-service** (optionnel par concession) : les clients achètent seuls depuis le showroom.
- **Points** à placer dans le builder : **Showroom** (catalogue public + position de livraison), **Véhicule expo** (modèle figé à l'endroit voulu, E = fiche), **Essai routier** (départ + durée ; le client revient où il était à la fin).
- **Livraison** : le véhicule sort devant le client (ses propriétés réelles sont enregistrées) ou arrive directement au garage (`Paramètres → Concession`).
- Le véhicule est ajouté à **ta table `owned_vehicles`** (colonnes dans `Config.Dealer.Cols`). ⚠ Vérifie la signification de la colonne `state` dans ton système de garage et règle `StateOut` / `StateStored` en conséquence.
- Tableau de bord : CA 30 j, ventes, commissions versées, taxes payées, historique.

## 🏛️ Gouvernement (jobs de type `government`, ex : gouverneur)
**F6 → Gouvernement** (automatique) : le compte société du job est le **trésor public**.
- **Taxes** réglables en jeu par le gouverneur (0–50 %) sur les ventes de véhicules, l'immobilier (ventes et loyers), les boutiques et les factures : prélevées sur la part de la société qui vend et versées au trésor.
- **Trésor** (dépôt / retrait), **subventions** vers le compte de n'importe quelle société, **primes** aux citoyens (le plus proche), **annonces officielles** affichées à tous (délai anti-spam), **journal** complet.
- Grades : accès général / direction (trésor, taxes, subventions, primes) réglables par job ; plusieurs jobs gouvernement possibles, un seul « Trésor public ».
- Limites et taxes aussi modifiables par les `_dev` (`Paramètres → Gouvernement`).

## 🎨 Couleur des menus (rouge par défaut, modifiable en jeu)
Tous les menus (builder, F6, boss, concession, agence, gouvernement, missions, annonces…) utilisent une **couleur d'accentuation** : cartes teintées, onglet actif à bordure colorée, boutons pleins, pastilles en majuscules, icônes, barres de progression. Rouge par défaut. **Paramètres → Apparence** : sélecteur de couleur libre + 9 couleurs prédéfinies (rouge, orange, jaune, vert, turquoise, bleu, violet, rose, blanc), aperçu immédiat, puis « Enregistrer et appliquer » : la nouvelle couleur est envoyée en direct à **tous les joueurs**. Le texte des boutons passe automatiquement en sombre ou en clair selon la couleur choisie (lisibilité). Valeur par défaut : `Config.UI.Accent` dans `config.lua`.

## ⚙️ Paramètres modifiables en jeu (`/jobbuilder` → Paramètres)
Les `_dev` modifient la config du script **sans toucher aux fichiers**, appliquée en direct à tous les joueurs et stockée en base (`jobbuilder_settings`). Les valeurs de `config.lua` restent les défauts (« Réinitialiser cette section » y revient).
- **Général** : distances (affichage, interaction, tolérance serveur, joueur→joueur), limites (grades, points, objets), durées réparation/nettoyage, event de revive, groupes autorisés, ACE, inventaire, webhook Discord.
- **Base commune** : tous les points de job (garage, vestiaire, armurerie, coffre, boss, boutique, showroom, missions…) et les coffres / penderies des propriétés partent du **même marker : type 25, bleu clair turquoise** — y compris les portes de propriétés, leur sortie et les marqueurs d'étapes des missions (réglables ensuite un par un dans Paramètres). Si tu avais déjà enregistré des markers dans Paramètres, ils priment sur `config.lua` (`/jbcheck` te le signale) : utilise « Réinitialiser cette section » (Markers des points **et** Immobilier) pour revenir à cette base.
- **Markers des points** (garage, vestiaire, armurerie, coffre, boss, boutique) : nom, type (30 formes), couleur, opacité, taille X/Y/Z, décalage vertical, rebond, rotation + **Aperçu en jeu** (8 s devant toi).
- **Immobilier** : règles (loyer, clés, limites, commission…), blips à vendre / à louer, markers des portes (disponible / tes clés / occupée), de la sortie, du coffre et de la penderie.
- **Intérieurs** : ajouter / modifier / supprimer les intérieurs des propriétés (sortie en « Ma position »).
- **Modèles de jobs** : grades, salaires, blip et actions par défaut de chaque modèle, créer ses propres modèles.
- Garde-fous : on ne peut pas se retirer son propre groupe, supprimer un intérieur utilisé, ni un modèle utilisé par un job.
- Non modifiable en jeu (redémarrage requis) : touche / noms de commandes, `SocietyPrefix`, `BucketBase`.

## 📍 Mode placement
Bouton **Mode placement** (points de job, blip, intérieurs, formulaire de propriété) : le menu se réduit en petit HUD en haut à droite et tu te déplaces librement. **Entrée** = enregistrer ta position pour la cible courante (puis passe à la suivante), **← / →** = changer de cible, **Retour arrière** = revenir au menu. Le brouillon n'est jamais perdu.

## 🎯 Missions PNJ (par job, activables)
Chaque job peut proposer des missions thématiques, **activables ou non job par job** (builder → Général → *Missions PNJ*) et globalement (Paramètres → Missions PNJ).
- Ajoute un point **Missions PNJ** (onglet Points) : les employés viennent y choisir une mission (grade minimum, délai, gains affichés). **F6 → Missions PNJ** (ou `/missionstop`) pour suivre ou annuler la mission en cours.
- **Missions fournies** :
  - 🚗 **Concession** : livraison de véhicule (un véhicule du catalogue à rendre au client, PNJ qui attend, remise des clés), démarchage client.
  - 🚓 **Police** : patrouille, appel témoin, transport de preuves.
  - 🚑 **EMS** : urgence médicale (patient blessé à soigner), livraison de médicaments.
  - 🔧 **Mécano** : dépannage (véhicule en panne à réparer), livraison de pièces.
  - 🚕 **Taxi** : course client (le PNJ monte, tu le déposes). 🏠 **Immobilier** : visite, pose de pancartes. 🍸 **Bar** : livraison de commande. 🏛️ **Gouvernement** : inspections, remise de documents. ⭐ **Custom** : livraison de colis.
- **Gains** : plage par mission × multiplicateur du job, bonus si dans le temps imparti, pénalité si le véhicule est abîmé. Paiement **créé par le serveur** (compte liquide ou banque) ou **prélevé sur la société** du job (non payé si la société est à sec).
- **Sécurité** : le serveur choisit les lieux, vérifie la position du joueur à chaque étape, impose une durée minimale et un délai entre deux missions ; statistiques par joueur et par job.
- **Tout est modifiable en jeu** (Paramètres → Missions PNJ) : lieux de mission (avec mode placement), modèles de PNJ, et pour chaque type de job les missions (nom, description, gains, grade, temps, véhicules) et leurs **étapes** (véhicule, aller à un lieu, interaction avec animation, prendre / déposer un client…). Tu peux créer tes propres missions.
- Les lieux par défaut sont des coordonnées de Los Santos écrites de mémoire (le sol est détecté automatiquement) : ajuste-les dans Paramètres si l'un d'eux ne te convient pas.

## 🧹 Suppression d'un job
Supprimer un job nettoie **tout** : `jobs`, `job_grades`, compte société (`addon_account`, `addon_account_data`, `addon_inventory(_items)`, `datastore(_data)`), coffres `ox_inventory`, points, propriétés / catalogue concession / ventes / logs du job, et les joueurs repassent chômeurs (en ligne et hors ligne). Chaque étape est indépendante : si l'une échoue (table absente…), le reste est quand même supprimé et le détail s'affiche. Une agence qui a encore des biens occupés ne peut pas être supprimée.

## 💰 Argent des jobs : même système que le reste du serveur, en direct
L'argent d'un job est le compte partagé `society_<job>` d'`esx_addonaccount` (ici celui d'`pickax_core`), qui le garde **en mémoire**. Le builder passe donc par lui — comme esx_society — au lieu d'écrire en SQL derrière son dos : dépôts/retraits du boss, ventes, factures, loyers, commissions, taxes, subventions, missions payées par la société… tous les scripts voient le **même solde**. Détection automatique ; repli SQL si le compte n'est pas encore connu d'`esx_addonaccount` (job créé en jeu avant son redémarrage) ou si son API ne répond pas.
- **En direct** : le serveur pousse le nouveau solde aux employés connectés à chaque opération, et les panels (gestion boss, trésor public) relisent le solde toutes les 2 s : une opération faite par un autre script apparaît toute seule, sans rouvrir le menu ni perdre ta saisie.
- **Pour les autres scripts** (équivalent de `GetGangMoney` / `AddGangMoney` / `RemoveGangMoney`) : `exports['pickax_jobbuilder']:GetJobMoney('police')`, `AddJobMoney('police', 500)`, `RemoveJobMoney('police', 500)` (retourne `false` si fonds insuffisants), `RefreshJob('police')` (pousse le solde aux employés). Fonctionne pour n'importe quel job ayant un compte `society_<job>`.
- **Diagnostic** : `/jobmoney [job]` (console serveur ou `_dev`) compare le solde en mémoire et en base pour chaque job et indique si le compte est connu d'`esx_addonaccount`.

## 🧩 Ce que chaque type de job peut placer et utiliser

Pour garder des jobs cohérents, l'éditeur ne propose que ce qui correspond au **type** du job (le type « Personnalisé » peut tout prendre) :
- **Points** : atelier tuning → mécano · cuisine / récolte → bar · showroom, véhicule expo, essai routier → concession · armurerie → police et EMS. Garage, vestiaire, coffre, boss, boutique et missions sont ouverts à tous.
- **Actions du menu F6** : menotter / escorter / fouiller → police · réanimer / soigner → EMS · réparer / nettoyer → mécano · vendre un produit → bar · facturer → tous.
- Les points ou actions déjà présents sur un ancien job mais non autorisés pour son type sont signalés (⚠) dans l'éditeur, ignorés en jeu, et refusés à l'enregistrement tant que tu ne les as pas supprimés.

## 🎨 Apparence par job : markers et couleur de l'interface

Rien n'oblige à changer tous les markers d'un coup (Paramètres → Markers des points reste le réglage **global**). Chaque job a en plus :
- **Style de markers du job** (onglet Général → carte « Markers du job ») : type, couleur, taille, opacité, rebond, rotation, aperçu en jeu. Il s'applique à tous les markers de CE job uniquement.
- **Style d'un point** (en bas de l'éditeur de chaque point) : écrase le style du job pour ce point seulement.
- Ordre de priorité : **point → job → type de point (global)**. Seuls les champs que tu modifies sont gardés, le reste est hérité ; « Revenir à l'héritage » supprime la personnalisation.
- **Couleur des markers du job, en un clic** : onglet Général → Apparence du job → « Couleur des markers de ce job » (sélecteur + préréglages) : tous les points du job prennent cette couleur d'un coup, sans toucher à chaque point.
- **Couleur de l'interface du job** (onglet Général → Apparence du job) : couleur des menus (F6, boss, tablette, atelier…) vue par les employés de ce job, indépendante des autres jobs et de la couleur globale. « Utiliser la couleur globale » la retire.

## 🅿️ Rangement des véhicules (intégré au garage)

Dans l'éditeur d'un **garage**, la carte **Rangement des véhicules** permet d'ajouter un point de rangement avec sa **propre position** (cour, parking, quai, piste…) : le joueur arrive **au volant** sur ce marker et appuie sur **E**, le véhicule est rangé, sans passer par le menu du garage.
- Il hérite du garage : type de véhicules (voitures, motos, bateaux, aéronefs), grade minimum et style de marker. Rayon d'activation réglable, position prise avec « Ma position » ou le mode placement.
- Par défaut, seuls les véhicules **du service** (plaque avec le préfixe du job) sont acceptés : la voiture perso d'un joueur n'est jamais supprimée. Case « Accepter tous les véhicules » pour désactiver cette protection.
- **Obligatoire** : le menu du garage ne permet plus de ranger un véhicule (il sert uniquement à en sortir). Chaque garage doit avoir son point de rangement placé, sinon le job ne s'enregistre pas. Les anciens points « Rangement véhicule » séparés (même type de véhicule) continuent de compter.

## 🩺 Tablette médicale EMS (F6 → Tablette médicale)

Pour chaque job de type **ems** (propre à chaque job, rien n'est partagé) :
- **Urgences** : les appels des patients inconscients (touche E) apparaissent en direct, avec distance, ancienneté et collègues en route. Prendre / quitter (GPS automatique), GPS, clôturer. Bouton **Urgence sur place** pour alerter l'équipe d'un accident vu sur le terrain (alerte + blip pour tous).
- **Patients** : dossiers médicaux (identité, groupe sanguin, allergies, antécédents) et historique (consultation, soin, opération, ordonnance, observation, décès). « Patient en face » crée ou retrouve le dossier de la personne devant toi. Suppression réservée au grade « suppression » du job.
- **Soins** : tarifs du job (modifiables) + soins libres ; le **patient le plus proche** reçoit la facture à l'écran et la règle (argent → société) ; le soin est ajouté à son dossier une fois payé (ou noté « refusé / impayé »).
- **Équipe** : collègues en service, disponibles ou en intervention, avec la distance.
- **Statistiques (30 jours)** : patients, réanimations, urgences prises, soins facturés et revenus, agents les plus actifs.
- Réglages par job (onglet Général → Tablette médicale) : grades pour ouvrir / facturer / supprimer, soins libres, tarifs. Le bouton « Retour » ramène au menu F6.

## 🚑 Mort, appel des EMS et réanimation

Quand un joueur meurt, un écran d'inconscience s'affiche (minuteur) :
- **[E] Appeler les EMS** : tous les employés de jobs de type **ems** reçoivent une alerte et un **blip clignotant à la position du patient**. Le patient voit « N médecin(s) en route » dès qu'un EMS prend l'appel.
- **[G] maintenu : réapparaître** une fois le délai écoulé (réduit si aucun EMS n'est en service) : il se réveille à l'**hôpital le plus proche** avec des **soins complets (vie, faim et soif à 100 %)** contre des **frais** (500 $ par défaut, prélevés sur la banque puis le liquide ; réglable, voir Paramètres → Mort & EMS). Sans assez d'argent, on prend ce qu'il a et il est soigné quand même (option désactivable). Faim/soif utilisent `esx_status`.
- **Côté EMS** : touche **Y** pour prendre le dernier appel (GPS automatique), ou **F6 → Appels EMS** (liste triée par distance : prendre / quitter, GPS, clôturer). Sur place, **F6 → Réanimer** lance un massage cardiaque (animation, durée vérifiée par le serveur) puis relève le patient.
- **/revive [id]** (staff) : réanime et soigne à 100 % le joueur indiqué (toi-même sans id). Groupes autorisés : `_dev` du builder + `Config.Death.ReviveGroups` (`admin`, `superadmin`, `mod` par défaut) ; nom de la commande : `Config.Death.ReviveCommand`. Si `esx_ambulancejob` gère la mort, la commande déclenche aussi son événement de réanimation.
- Réglages : **Paramètres → Mort & EMS** (délais, frais, vie rendue, prime de l'EMS, liste des hôpitaux). Les exports `IsPlayerDead(src)` et `RevivePlayer(src, vie%)` sont disponibles pour tes autres scripts.
- **Mode** : par défaut « auto » = actif seulement si `esx_ambulancejob` n'est pas démarré (pour ne pas avoir deux systèmes de mort). Passe sur « Toujours actif » pour forcer celui du builder.

## 🔧 Atelier tuning (jobs mécano)

Nouveau point **Atelier tuning** (ajouté d'office au modèle Mécano). Le mécano gare le véhicule du client sur le marker (ou reste à son volant) et appuie sur **E** : une tablette s'ouvre à droite, avec une **caméra orbitale** autour du véhicule (glisser pour tourner, molette pour zoomer) et un **aperçu en direct** sur le véhicule.
- **Perf.** : moteur, freins, transmission, suspension, blindage (niveaux), turbo.
- **Carrosserie** : toutes les pièces disponibles sur le véhicule (ailerons, pare-chocs, bas de caisse, échappement, capot, toit, klaxon, intérieur, livrée…), avec les noms réels des pièces.
- **Roues** : type et modèle de jantes, couleur des jantes, fumée de pneus (couleur au choix).
- **Peinture** : couleur principale, secondaire, nacrage (palette de couleurs GTA).
- **Éclairage** : néons (4 côtés + couleur libre), phares xénon (couleur), vitres teintées, style de plaque.
- **Devis** : détail des modifications et total, puis **Valider**.

**Facturation par job** (onglet Général) : *facturé au client* (le client le plus proche reçoit la facture ; les modifications ne sont enregistrées qu'une fois payée, sinon elles sont annulées), *payé par la société* ou *gratuit*. **Grade minimum** et **majoration** (%) réglables par job ; les **prix de base** se règlent dans Paramètres → Tuning.
Les modifications sont enregistrées dans `owned_vehicles` (propriétés ESX) pour les véhicules possédés ; seules les pièces payées sont écrites, et tout est validé côté serveur (clés autorisées, valeurs, prix).

## 🚓 Tablette police (casiers, amendes, dispatch, carte en direct)

Chaque job de type **police** a sa propre tablette : **F6 → Tablette** (on peut aussi cocher l'action « Tablette » pour un autre type de job). Les données de chaque job sont totalement séparées (casiers, appels, poursuites, unités).

- **Casiers** : recherche par nom, création / modification / suppression, avis de recherche, notes, historique (amende, arrestation, avertissement, saisie, prison, note). « Personne en face » crée ou retrouve le casier du joueur devant toi. La suppression est réservée au grade « suppression » du job.
- **Amendes** : catalogue d'amendes du job (modifiable) + amendes libres (désactivables). La **personne la plus proche** reçoit l'amende à l'écran et la paie (argent → société, taxes comprises). Le résultat est inscrit automatiquement dans son casier (payée / refusée / impayée).
- **Dispatch** : appels citoyens avec `/appel <message>`, appels créés par les agents, `/panic` pour un policier en danger. Prendre / quitter un appel, GPS, voir sur la carte, clôturer, supprimer (direction). Les unités reçoivent une alerte + un blip temporaire. Les autres scripts peuvent envoyer un appel : `exports.pickax_jobbuilder:SendDispatch('police', 'Alarme', 'Braquage banque', {x=…, y=…, z=…})`.
- **Carte en direct** : toutes les unités du job, les appels et le **fugitif**. Pour lancer une poursuite : « Chercher autour de moi », choisis le suspect, « Poursuivre ». Sa position s'affiche en temps réel (avec traînée, vitesse) pour tout le service, et sur la carte du jeu de chaque membre. La poursuite s'arrête manuellement, si le suspect se déconnecte, ou après la durée maximale.
  - **Vraie carte en couleur** : la tablette sait afficher les tuiles standard « mapStyles » (le pack gratuit du projet open source *gta-v-map-leaflet*, lien dans son README GitHub). Décompresse-le pour obtenir `html/map/mapStyles/styleAtlas/{z}/{x}/{y}.jpg` (carte colorée), et/ou `styleSatelite` (satellite). C'est tout : le calage est automatique, la carte se zoome et se déplace (glisser / molette) avec les unités, les appels et le fugitif par-dessus. Choisis le style dans **Paramètres → Police → Carte de la tablette** (boutons Atlas / Satellite / Grille).
  - Tu préfères une image unique ? Dépose-la dans `html/map/` (carte carrée standard : limites X -5661 → 6694, Y -4058 → 8429, déjà préréglées) et renseigne son chemin dans le même écran.
  - Sans tuiles ni image, une carte schématique (grille + lieux) est affichée.
- **Réglages par job** (onglet Général) : grades pour ouvrir, amender, poursuivre, supprimer ; casiers / dispatch / carte activables séparément ; catalogue d'amendes. **Réglages globaux** : Paramètres → Police (durées, portée, délais, limites, commandes, lieux de la carte).

## 📣 Annonces d'entreprise (tous les jobs)

**F6 → Annonce entreprise** : un employé (grade suffisant) diffuse un bandeau coloré à tous les joueurs ou dans un rayon. Par job (onglet Général → Annonces) : activée ou non, grade minimum, délai, **coût prélevé sur la société**, rayon (0 = tout le serveur), durée d'affichage, types autorisés (Information, Recrutement, Promotion, Événement, Urgent… modifiables dans Paramètres → Annonces). Historique des dernières annonces dans le menu. Les joueurs masquent / réaffichent les annonces avec `/annonces`.

## 🍔 Restaurant / bar : récolte → frigo → cuisine → vente

Un enchaînement simple, tout se règle dans le builder (type de job **Bar / Restaurant**, ou n'importe quel job) :

1. **Récolte** (point *Récolte*) : un point = un objet (potager → `tomato`, élevage → `steak`…), quantité et durée réglables. L'employé reste sur place (animation + barre de progression, **X** pour annuler).
2. **Frigo** : un point *Coffre* que tu nommes « Frigo » (coffre propre au job, ox_inventory) pour ranger les ingrédients.
3. **Cuisine / Bar** (point *Cuisine / Bar*) : une liste de recettes. Chaque recette = ingrédients (item + quantité) → produit fini (item + quantité), durée, grade minimum. On peut préparer plusieurs exemplaires d'un coup (×1 à ×10). Plusieurs points possibles (cuisine, bar, four…) avec des recettes différentes.
4. **Vente directe** : onglet **Général → Carte** : liste des produits vendables avec leur prix. L'employé ouvre **F6 → Vendre un produit**, choisit un produit et une quantité : le client le plus proche reçoit l'offre à l'écran et paie directement (l'objet passe de l'employé au client, l'argent va à la société, taxes comprises). Il faut que l'action « Vendre un produit » soit cochée dans le menu F6 du job (cochée par défaut pour le modèle Bar).

Les objets doivent exister dans ox_inventory (la liste est proposée à la saisie). Les vérifications se font côté serveur : durée respectée, ingrédients et place dans l'inventaire revérifiés à la fin, échange vendeur ↔ client annulé si l'un des deux n'a plus l'objet ou l'argent. `/jbcheck` signale un job qui a « Vendre un produit » sans carte.

## 🏦 Coffre de l'entreprise dans les autres scripts (menu contextuel, tablettes…)
Un menu contextuel qui lit le coffre via `esx_society:getSocietyMoney` ne voit que les sociétés **enregistrées** auprès d'`esx_society`, et `esx_addonaccount` que les comptes chargés à son démarrage : les jobs créés par le builder leur étaient inconnus (coffre figé / à 0). Le builder **déclare maintenant chaque société** à `esx_society` (`esx_society:registerSociety`) et charge son compte en mémoire d'`esx_addonaccount` (export `AddSharedAccount`, le solde est conservé), automatiquement : au démarrage, à chaque création / modification de job, et à chaque redémarrage de `esx_society` / `esx_addonaccount` / `pickax_core`. Si ton `esx_addonaccount` n'a pas cet export, le solde reste intact et un `restart pickax_core` (ou le réglage « Ressources à redémarrer ») fait le travail.
- Ces menus relisent le solde quand tu les ouvres : après un dépôt / retrait dans le builder, ils affichent le bon montant à l'ouverture suivante.
- `/jobmoney` indique pour chaque job si la société est **enregistrée** auprès d'`esx_society`.
- Certains menus (dont le menu contextuel fourni) n'affichent l'entreprise qu'au joueur dont le **nom de grade** est `boss` : garde `boss` comme nom interne du grade de direction.

## 🔄 esx_society / esx_addonaccount (« Compte partagé introuvable : society_xxx »)
Ces scripts (ou un `pickax_core` qui les regroupe) chargent la liste des jobs et des comptes société **au démarrage**. Un job créé en jeu leur est donc inconnu tant qu'ils ne sont pas redémarrés : `Compte partagé introuvable`, `Compte entreprise introuvable`, `attempt to index a nil value (local 'job')`.
- Solution manuelle : `restart pickax_core` (ou `esx_society` + `esx_addonaccount`) après avoir créé / modifié / supprimé un job.
- Solution automatique : **Paramètres → Général → Ressources à redémarrer** (ex : `pickax_core`). Le builder les redémarre seul ~3 s après chaque changement (un seul redémarrage même si tu enchaînes plusieurs modifications). `es_extended`, `oxmysql`, `ox_lib`, `ox_inventory` et `pickax_jobbuilder` sont refusés (protégés).
- Si rien n'est configuré, le builder te dit après chaque enregistrement quelle ressource redémarrer (notification + console serveur).

## 🛠️ Dépannage
- **« Ce job n'a pas de compte société »** : corrigé (les cases `tinyint(1)` peuvent revenir en `true/false` selon la version d'oxmysql). Au démarrage, le builder réactive la société des jobs concernés et recrée les comptes manquants (`addon_account`, `addon_account_data`, `addon_inventory`, `datastore`) — redémarre ensuite `esx_society` / `esx_addonaccount` (ou `pickax_core`) pour qu'ils les voient.
- `/jbcheck` (console serveur ou joueur `_dev`) : **diagnostic complet** — dépendances, tables, et pour chaque job : présence dans `jobs` / `job_grades` / société, blip sans position, points sans position ou grade inexistant, pas de point boss, catalogue ou showroom manquant, missions sans point…
- `/jbdebug` : affiche ton métier, les points reçus par le client et leur distance (puis resynchronise). Si « points reçus : 0 », ton métier n'est pas celui du job ou ES n'a pas pris le job (voir plus bas).
- `/jbreset` : débloque l'interface si elle est restée « ouverte » (ex : mode placement oublié — tant que l'UI est considérée ouverte, markers et touche E sont désactivés).
- « Me mettre dans ce job » vérifie maintenant qu'ESX a bien accepté le job ; sinon un message te dit de faire `restart es_extended`.

## Prérequis / remarques
- **ESX Legacy récent** : le builder appelle `ESX.RefreshJobs()` pour que le job soit utilisable sans restart. Sinon : `restart es_extended` après création.
- Tenues : `skinchanger` / `esx_skin` par défaut ; adapte `Config.GetClothes / ApplyClothes / RestoreCivil` (config.lua) pour un autre système d'apparence.
- Clés de véhicule : hook `Config.OnVehicleSpawned`.
- Argent société : lu/écrit directement dans `addon_account_data` ; pour les jobs du builder, n'utilise pas `esx_addonaccount` en parallèle (son cache serait désynchronisé).
- Revive EMS : event `Config.ReviveEvent` (`esx_ambulancejob:revive` par défaut).


## Gunfight / arène : désactiver la mort du builder

Si un autre script (gunfight, arène, event…) gère déjà la mort, le builder ne doit pas afficher son écran de mort / appel EMS.
Dans `config.lua`, `Config.DeathBlock` (une seule règle suffit) :

- Par défaut les zones PVP de `pickax_worldbuilder` sont déjà gérées (state bag `inPvpZone` + export `IsInPvpZone`).
- `StateBags` : noms de state bags du joueur (`LocalPlayer.state.inGunfight`…) — s'il est vrai, la mort est ignorée ;
- `Exports` : `{ 'ressource', 'export' }` renvoyant `true` quand le joueur est en gunfight ;
- `Zones` : `{ x, y, z, rayon }` — la mort dans ce rayon est ignorée ;
- ou depuis ton script : `exports.pickax_jobbuilder:SetDeathBlocked(true)` à l'entrée et `false` à la sortie (côté client).

Mort dans l'eau : la réanimation place maintenant le joueur sur la rive la plus proche (≤ 250 m), sinon en surface.

## Banque (jobs de type « Banque »)

Nouveau modèle de job **Banque** (blip, grades Stagiaire → Directeur, points cloakroom / coffre / boutique / boss). Menu **F6 → Tablette bancaire** :

- **Tableau de bord** : trésorerie de la banque, prêts en cours / en retard / en défaut, encours total, remboursé / prêté / frais sur 30 jours, prochaines échéances, activité récente.
- **Clients** : fiches (cote de crédit A→E, statut Normal / VIP / Sous surveillance, notes, historique complet). Bouton **Client en face** : ouvre (ou crée) la fiche de la personne devant toi et affiche son solde (uniquement si elle est à côté de toi).
- **Prêts** : le conseiller choisit montant, intérêt total (%), nombre d'échéances ; le **client en face** reçoit l'offre à l'écran et doit l'**accepter**. Le capital est versé sur son compte bancaire (prélevé sur la société ou créé par le serveur). Chaque échéance est **prélevée automatiquement** sur son compte bancaire (toutes les 24 h, aussi à la connexion). Impayé : pénalité, nouvel essai, puis prêt « en défaut » (cote E). La cote limite le montant empruntable ; limite de prêts simultanés par client. Direction : rappel, prélèvement forcé, annulation de dette.
- **Guichet** : dépôt (espèces → compte) et retrait (compte → espèces) **uniquement avec la confirmation du client**.
- **Frais & services** : catalogue configurable (ouverture de compte, carte, chéquier…) ou frais libres, facturés au client en face (argent → compte de la banque).
- **Équipe** : conseillers en service.

Réglages par job (builder → job → Général → carte « Banque ») : tablette on/off, prêts on/off, guichet on/off, grades (ouvrir / accorder un prêt / guichet & frais / annuler & supprimer), prêt maximum, intérêts min/max, origine de l'argent prêté, catalogue des frais. Réglages globaux (intervalle, pénalité, défaut, durées proposées, cotes…) : `Config.Bank` dans `config.lua`. Les prêts exigent un **compte société** (job créé avec la société activée).

Tables créées automatiquement : `jobbuilder_bank_clients`, `jobbuilder_bank_entries`, `jobbuilder_bank_loans`. Missions PNJ de banque incluses (transport de fonds, visite client).

## Agent immobilier — gestion complète des biens
- **10 catégories de biens** : maison, appartement, villa, laboratoire, garage, entrepôt, bureau, local commercial, hôtel/motel, autre (`Config.Real.Categories`). Filtre par catégorie dans la liste, badge dans les fiches, icône de blip selon la catégorie, catégorie et description visibles sur le panneau de la porte.
- **Catalogue d'intérieurs** classés par catégorie : 4 appartements, 3 garages (2/6/10 places), un bureau exécutif et 5 laboratoires/entrepôts « Biker » (méthamphétamine, cannabis, cocaïne, faux billets, faux papiers). Les labos chargent leurs **IPL** à l'entrée. ⚠ Vérifie leur position avec « Visiter » : les coordonnées des intérieurs DLC dépendent de ta version du jeu (réglables dans `/jobbuilder` → Paramètres → Intérieurs).
- **N'importe quel intérieur** : ajoute tes propres intérieurs dans Paramètres → Intérieurs (clé, nom, catégorie, position de sortie, IPL) ou choisis **« Intérieur personnalisé »** directement sur le bien (position de sortie + liste d'IPL facultative) : MLO, shell, appartement d'un pack de mapping, etc.
- **Points intérieurs** : coffre, **coffre-fort** (réservé au propriétaire / locataire, pas aux détenteurs de clés) et penderie.
- **Dupliquer** un bien (même immeuble, plusieurs appartements identiques) : copie type, prix, intérieur et points ; il ne reste qu'à placer la nouvelle entrée.
- Mise à jour automatique de la base : les colonnes `category`, `description` et `ipl` de `jobbuilder_properties` sont ajoutées au démarrage si elles manquent.
