# gangbuilder — Gang Builder ESX complet basé sur **job2** (UI + oxmysql)

Même esprit et même style que `jobbuilder`, mais pour les **gangs** : tu crées un gang en jeu (`/gangbuilder`) avec ses grades, garages, vestiaires, armureries, coffres, marché noir, **récolte → traitement → vente → blanchiment**, **trésorerie propre + sale**, **territoires à capturer** et gestion par le chef. Réservé au groupe ESX `_dev` (modifiable).

> Un gang = **une ligne dans `jobs2`** + ses grades dans **`job2_grades`**. Les membres sont rattachés par **`users.job2` / `users.job2_grade`**. Le builder n'écrit jamais dans `jobs` / `job_grades`.

## Installation
1. Copie le dossier `gangbuilder` dans `resources/`.
2. `server.cfg` (après les dépendances, à côté de `jobbuilder`) :
   ```
   ensure oxmysql
   ensure es_extended
   ensure ox_inventory
   ensure gangbuilder
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
