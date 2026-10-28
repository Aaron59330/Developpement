# gangbuilder — Gang Builder ESX complet basé sur **job2** (UI + oxmysql)

Même esprit et même style que `pickax_jobbuilder`, mais pour les **gangs** : tu crées un gang en jeu (`/gangbuilder`) avec ses grades, garages, vestiaires, armureries, coffres, marché noir, **récolte → traitement → vente → blanchiment**, **trésorerie propre + sale**, **territoires à capturer** et gestion par le chef. Réservé au groupe ESX `_dev` (modifiable).

> Un gang = **une ligne dans `jobs2`** + ses grades dans **`job2_grades`**. Les membres sont rattachés par **`users.job2` / `users.job2_grade`**. Le builder n'écrit jamais dans `jobs` / `job_grades`.

## Installation
1. Copie le dossier `pickax_gangbuilder` dans `resources/`.
2. `server.cfg` (après les dépendances, à côté de `pickax_jobbuilder`) :
   ```
   ensure oxmysql
   ensure es_extended
   ensure ox_inventory
   ensure pickax_gangbuilder
   ```
3. Les tables `gangbuilder_*` se créent **toutes seules** au démarrage (ou importe `sql/install.sql`).
4. En jeu : `/gangbuilder` (groupe `_dev` requis, vérifié côté serveur à chaque action), puis `/gbcheck` dans la console serveur pour valider l'intégration.

## Où sont écrits les gangs (ta base)
| Table | Contenu |
|---|---|
| `jobs2` | `name`, `label` du gang |
| `job2_grades` | grades + salaires (uniquement ceux du gang concerné) |
| `users.job2` / `users.job2_grade` | rattachement des membres |
| `gangbuilder_gangs` | couleur, blip, réglages, **trésorerie** (`money`, `dirty`), réputation |
| `gangbuilder_points` | garages, vestiaires, armureries… de chaque gang |
| `gangbuilder_territories` | zones, propriétaire, protection, revenus |
| `gangbuilder_logs` / `gangbuilder_stats` / `gangbuilder_settings` | journal, stats par membre, réglages en jeu |

**Pas de mélange avec l'existant :**
- un nom déjà présent dans `jobs`, `jobs2`, `pgang_gangs` ou `fx_gangs` est **refusé** (liste modifiable : `Config.Job2.ConflictTables`) ;
- les tables `gangbuilder` (ancienne), `fx_gangs`, `fx_turfs`, `pgang_*`, `entreprise`, `jobbuilder_*` ne sont **jamais touchées** ;
- chaque point n'est utilisable que par **son** gang (job2 + grade minimum + distance, vérifiés côté serveur) ; les coffres ox sont protégés par un hook `openInventory` (job2 + grade) ;
- suppression = uniquement les lignes créées par le builder ; les membres repassent sur `unemployed2` (modifiable).
- ⚠ `users.job2` est un `varchar(20)` : **20 caractères max** pour le nom d'un gang (refusé au-delà, jamais tronqué).

## Fonctionnalités
- **Modèles** : gang de rue, mafia, club de motards, cartel, personnalisé (grades, couleur, blip, actions, points suggérés — tout modifiable en jeu **et** dans `config.lua`).
- **Grades** : ajout / suppression / ordre / salaires (écrits dans `job2_grades`), grade « bureau », grade de recrutement, grade pour retirer l'argent, grade pour capturer.
- **Points** (mode placement, TP, aperçu) :
  `Garage` (voitures / motos / aéronefs / bateaux) · `Vestiaire` (tenues H/F capturées) · `Armurerie` · `Coffre` (ox_inventory) · `Gestion du gang` · `Marché noir` (public ou privé, payé en sale/propre/banque) ·
  `Récolte` (objet, quantité, durée, délai, outil requis) · `Traitement` (recettes multi-ingrédients, chance de réussite) · `Point de vente` (prix ± variation, part reversée au gang, délai, alerte police) · `Blanchiment` (commission, plafonds, durée).
- **Trésorerie** : argent propre + sale, dépôt / retrait selon grade, plafonds, journal, solde **en direct** dans l'interface.
- **Gestion du gang (boss)** : recruter (joueur le plus proche, sans job2 existant), promouvoir, exclure, salaires, journal.
- **Territoires** : zones circulaires créées dans le builder (onglet *Territoires*) — capture par présence (une seule équipe), HUD de progression, protection après capture, revenu périodique dans la trésorerie, blips colorés par gang, zone dessinée au sol. Chaque zone peut surcharger durée / membres / revenu / protection.
- **Menu gang (F7)** : fiche du gang (message du jour, membres en ligne, territoires, stats perso), menottes / escorte / fouille (cible menottée ou non, réglable), quitter le gang.
- **Réputation**, **salaires** (optionnels), **stats par membre**, **journal** + webhook Discord.
- **Anti-triche** : durées des activités vérifiées côté serveur (`Activities.Grace`), distance, job2 et grade relus à chaque appel, montants bornés, argent débité avant la livraison.

## Config « très complète » — où modifier quoi
Tout est un **défaut** dans `config.lua`. **Presque tout est modifiable en jeu** : `/gangbuilder` → **Paramètres** (appliqué en direct à tous les joueurs, stocké dans `gangbuilder_settings`, « Réinitialiser cette section » = retour à `config.lua`).

| Section Paramètres | Exemples |
|---|---|
| Général | distances, limites, inventaire, groupes autorisés, ACE, webhook, ressources à redémarrer, couleurs de gang sur les markers |
| Gangs | membres max, grade des recrues, quitter autorisé, protection du bureau, fouille/escorte exigent des menottes |
| Trésorerie | activée, dépôt/retrait, argent sale, plafond, argent de départ, compte / objet d'argent sale (`black_money`) |
| Salaires | activés, intervalle, payé par la trésorerie ou le serveur, compte crédité |
| Réputation | points par capture, revenu, vente, blanchiment, fabrication, récolte |
| Territoires | durée de capture, membres min., protection, revenu, intervalle, rayon, blips, zone au sol |
| Activités | anti-triche, limites, animations, vente (variation, part du gang, délai, alerte police), blanchiment (commission, plafonds, durée) |
| Apparence | couleur d'accentuation de **tous** les menus |
| Markers des points | type, couleur, opacité, taille, rebond, rotation, **aperçu en jeu** |
| Modèles de gangs | crée / modifie tes modèles : couleur, blip, actions, points suggérés, grades |

Ajouter un réglage = l'ajouter dans `Config.Schema` : il apparaît tout seul dans Paramètres et est validé côté serveur (type / min / max).
Dans `config.lua` uniquement (redémarrage requis) : noms de tables / colonnes job2, commandes, touche F7, hooks (notification, tenues, clés de véhicule, alerte police).

## Intégration job2 avec ton es_extended
Le script ne présuppose rien de précis : tout est dans `Config.Job2` et `server/job2.lua`.
- **Lecture** : `xPlayer.job2` si ton ES le gère (`Source = 'auto'`), sinon directement `users.job2` en base.
- **Écriture** : `xPlayer.setJob2(name, grade)` si elle existe ; si ES ne prend pas le changement, **repli** : écriture en base + event client `esx:setJob2` + event serveur `esx:setJob2`.
- **Rechargement** : après création / modification d'un gang, `ESX.RefreshJobs2` / `RefreshJob2` / `RefreshJobs` sont appelés s'ils existent (`Config.Job2.RefreshFunctions`). Sinon renseigne `Config.Job2.Refresh = function() ... end`, `RefreshEvents`, ou `Config.RestartResources` — sans ça, ton ES peut refuser le job2 d'un gang créé en jeu avant un restart.
- `/gbcheck` (console serveur) te dit exactement ce qui est détecté (`xPlayer.job2`, `setJob2`, fonction de rechargement, tables, colonnes, gangs sans boss / blip…).

## Commandes
| Commande | Rôle |
|---|---|
| `/gangbuilder` | ouvre le builder (`_dev`) |
| `/gangmenu` (F7) | menu du gang |
| `/gbcheck` | diagnostic complet (console serveur ou `_dev`) |
| `/gbdebug` · `/gbreset` | état du client · débloque l'interface |

## Exports (autres scripts)
`GetGangMoney(gang, 'money'|'dirty')` · `AddGangMoney(gang, amount, kind)` · `RemoveGangMoney(gang, amount, kind)` · `AddGangRep(gang, amount)` · `GetPlayerGang(src)` · `SetPlayerGang(src, gang, grade)` · `GetGangMembers(gang)`.

## Dépannage
- **« Le job2 n'a pas été appliqué »** : ton ES ne connaît pas encore le gang → `/gbcheck`, puis `Config.Job2.Refresh*` ou un restart de la ressource qui charge `jobs2`.
- **Points invisibles** : `/gbdebug` (gang détecté ? points reçus ?). Un joueur sans job2 de gang ne voit que les boutiques publiques.
- **Markers pas aux couleurs de config.lua** : des markers enregistrés en base (Paramètres) priment ; `/gbcheck` les signale → « Réinitialiser cette section ».
- **Doublon de salaires** : si ton ES paie déjà `job2`, laisse `Salary.Enabled = false`.


## Affrontements et missions entre gangs

### Affrontement de territoire (`Config.Conflicts`)
- Un gang qui fait une **activité illégale** (récolte, traitement, vente) sur le **territoire d'un autre gang** déclenche un affrontement : le propriétaire reçoit une notification, la zone **clignote en rouge sur la carte** (GPS posé pour le propriétaire) et le gang intrus est prévenu qu'il a été repéré.
- Pendant `Duration` secondes, chaque **kill entre les deux gangs dans la zone** rapporte 1 point (le score s'affiche dans le HUD de zone et par notification).
- À la fin : le gang qui a le plus de points gagne (`RepWin` de réputation). Si c'est l'intrus (au moins `MinKillsToWin` kills d'avance) et que le territoire n'est pas protégé, il le **capture** (`WinnerCaptures`).
- Pas d'affrontement si personne du gang propriétaire n'est connecté ; délai `Cooldown` entre deux affrontements du même gang sur la même zone.
- Test staff : `/gbconflict <id territoire> <gang intrus>`.

### Missions « colis » (`Config.Objectives`)
1. Un colis apparaît dans une zone (annonce à tous les gangs connectés, zone jaune sur la carte). Lancement automatique toutes les `Interval` minutes (si `MinGangsOnline` gangs sont connectés) ou à la main : `/gbobjective [zone]`, arrêt : `/gbobjstop`.
2. Le **premier gang** qui prend le colis (touche E) doit **rester dans la zone `hold` secondes**. Le compteur avance **même si aucun gang adverse ne vient**. Si le porteur sort plus de `LeaveGrace` secondes, ou meurt hors zone, le colis retourne au centre ; s'il meurt dans la zone, il tombe sur place. Un autre gang qui le reprend doit refaire tout le temps de zone.
3. Temps écoulé : le porteur doit **ramener le colis à SON coffre de gang** (point « Coffre » du gang, GPS posé, position du porteur visible par les autres gangs si `RevealCarrier`). S'il meurt en route, le colis tombe : n'importe quel gang peut le prendre et doit le livrer à son propre coffre.
4. Livraison (automatique à `DeliverDistance` du coffre) : `Reward` dans la trésorerie du gang (`RewardAccount`) + `RewardRep` de réputation.
- Les zones sont dans `Config.Objectives.Zones` (nom, label, coords, rayon, temps à tenir, récompense) : adapte-les à ta map.
- Un gang **sans coffre** ne peut pas prendre le colis. Tout est calculé côté serveur (positions, temps, livraison).
- Réglages en jeu : `/gangbuilder` → Paramètres → **Affrontements** et **Missions colis**.
- Export serveur : `exports.pickax_gangbuilder:StartObjective('port')`, `exports.pickax_gangbuilder:GetObjective()`.


## Territoires 2.0 : niveaux, équité, racket

Tout est réglable dans `config.lua` (`Config.Territories`) et en jeu (Paramètres → Territoires).

- **Niveaux** (`Levels`) : le bureau du gang améliore un territoire depuis la tablette (Zones → Améliorer), payé par la trésorerie (`UpgradeAccount`). Chaque niveau augmente le revenu, ralentit la capture par un rival, allonge la protection après capture et augmente le racket. Un territoire capturé perd `LevelLoss` niveau(x).
- **Équité** : `MinDefenders` (membres du propriétaire connectés requis pour capturer : plus de raid dans le dos), `Windows` (heures du serveur où la capture est permise, ex. `{ {18, 23} }`), `MaxPerGang` (plafond de territoires par gang). Les affrontements du Builder Illégal respectent les mêmes règles.
- **Racket** : un gang qui vend de la drogue sur le territoire d'un autre paie `RacketRate` % au propriétaire (via `exports.pickax_gangbuilder:TerritoryTax`, appelé par le Builder Illégal). Les membres du gang propriétaire ne paient rien ; les notifications du propriétaire sont groupées (1 par minute et par territoire).
- Base de données : colonne `level` ajoutée automatiquement à `gangbuilder_territories` au démarrage (aussi dans `database.sql`).
- Tests hors jeu : `lua5.4 tools/tests/territories_test.lua` (42 vérifications).

## Zones de tribut (`Config.Tribute`)

Un commerce de la ville est disputé entre les gangs, puis le vainqueur va y collecter un tribut.
1. L'événement se lance tout seul toutes les `Interval` minutes (si `MinGangsOnline` gangs sont connectés) ou à la main : `/starttribute [nom]`, arrêt : `/stoptribute` (staff `_dev`). Tous les gangs sont prévenus, la zone s'affiche sur la carte et au sol.
2. Pendant `CaptureSeconds`, on se bat dans la zone. Le serveur compte chaque seconde les membres **vivants** de chaque gang dans la zone (HUD : temps restant et survivants par gang).
3. À la fin, le gang avec le plus de survivants gagne (égalité : celui qui a été le plus présent ; égalité parfaite ou moins de `MinPerGang` membres : pas de vainqueur).
4. Le gang vainqueur a `CollectWindow` secondes pour aller au point de collecte du commerce (touche E, vérifié côté serveur : gang, vie, distance). Il touche `Reward` dans la trésorerie (`RewardAccount`) et `RewardRep` de réputation ; l'annonce est publiée dans les actus. Une seule collecte par événement.
- Les commerces sont dans `Config.Tribute.Zones` (nom, libellé, centre, rayon, point de collecte, `reward` facultatif par commerce) : adapte les coordonnées à ta map.
- Export serveur : `exports.pickax_gangbuilder:StartTribute('ammunation')`.
- Tests hors jeu : `ROOT=. lua tools/tests/tribute_test.lua` (18 vérifications).

## Guerre de zone déclarée, logo, page Tributs (complète les scripts de territoires du commerce)

- **Guerre de zone (`Config.TurfWar`)** : le bureau d'un gang déclare la guerre au propriétaire d'un territoire — tablette → *Zones* → territoire → **Déclarer la guerre**, ou `/startturfwar <id du territoire>`.
  Conditions vérifiées côté serveur : territoire avec propriétaire adverse, pas protégé (sauf `AllowProtected`), `MinAttackers` attaquants et `MinDefenders` défenseurs connectés, fenêtre horaire et plafond de territoires respectés, délai `Cooldown` entre deux déclarations sur la même zone.
  Déroulé : les deux camps sont prévenus (alerte + zone qui clignote), **préparation** `PrepSeconds` (aucun point), puis **dispute** `Duration` : chaque kill entre les deux gangs dans la zone = 1 point. Gagnant : réputation (`RepWin`), perdant : `RepLoss` ; si l'attaquant gagne avec `MinKillsToWin` kills d'avance, il **capture** le territoire. Résultat dans les actus, le journal et les quêtes.
- **Logo du gang** : le chef l'enregistre depuis la tablette (Accueil → *Logo du gang*, adresse https d'une image). Il s'affiche dans la tablette (accueil, classement).
- **Page « Tributs »** de la tablette : zone de tribut en cours (survivants par gang, temps, GPS) et historique des derniers tributs (table `gangbuilder_tributes` créée automatiquement).
- Tests hors jeu : `ROOT=. lua tools/tests/turfwar_test.lua` (15 vérifications), `tribute_test.lua` (18).

## Saisons de gangs (`Config.Season`)
- **Points de saison = réputation gagnée** pendant la saison (captures, victoires de guerre / d'affrontement, colis, tributs, quêtes…) : rien à brancher, tout ce qui rapporte de la réputation compte.
- Une saison dure `Days` jours (7). À la fin, les gangs avec au moins `MinPoints` points sont classés ; les 3 premiers reçoivent leur récompense (argent dans la trésorerie + réputation, `Rewards`), les membres en ligne sont prévenus, l'actu est publiée, le résultat est conservé (tables `gangbuilder_seasons`, `gangbuilder_season_points`, `gangbuilder_season_results`) et une **nouvelle saison démarre à zéro**.
- Tablette → **Classement** : saison en cours (top 10, ton rang, récompenses, temps restant) et podium de la saison précédente. Staff : `/endseason` termine la saison tout de suite. Export : `exports.pickax_gangbuilder:GetSeasonInfo(gang)`.
- Réglable dans le panel : *Réglages du serveur → Gangs → Saisons de gangs*. Tests : `ROOT=. lua tools/tests/season_test.lua` (14 vérifications).

## QG de gang : niveaux et raids (`Config.HQ`)
Le **QG** d'un gang est son **coffre** (point « Coffre » du builder).
- **Niveaux** : le bureau améliore le QG depuis la tablette (Accueil → *QG du gang*), payé par la trésorerie (`UpgradeAccount`). Chaque niveau augmente le **revenu des territoires** et la **protection après capture**, et réduit ce qu'un raid peut piller (niveaux 2 à 4 : 25 000 / 60 000 / 120 000 $, réglables).
- **Raid** : le bureau d'un gang rival lance un raid (tablette → *Guerres* → *Raid de QG*, ou `/raidhq <gang>`). Conditions : 2 attaquants et 1 défenseur connectés, QG non raidé récemment, délai entre deux raids du même gang. Les deux camps sont prévenus, la zone (12 m) apparaît sur la carte et au sol avec la progression.
  Les attaquants doivent **tenir la zone 90 s sans qu'aucun défenseur vivant n'y soit** (un défenseur dans la zone fait reculer la prise, une zone vide aussi). Succès : ils volent **10 % de l'argent sale** du QG (plafond 20 000 $, × le coefficient du niveau du QG, 2 000 $ minimum), +25 de réputation ; le QG ne peut pas être raidé pendant 1 h.
- Tout est calculé côté serveur (positions, vie, temps). Réglable dans le panel : *Réglages du serveur → Gangs → QG de gang / Raids de QG*. Export : `exports.pickax_gangbuilder:GetHQLevel(gang)`. Test : `ROOT=. lua tools/tests/hq_test.lua` (24 vérifications).
