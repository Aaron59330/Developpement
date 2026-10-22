# pickax_staff — panel staff en jeu

Panel staff moderne, organisé par thème. **Deux menus complets coexistent** :
- le **panel** (`/staff`) ;
- l'**ancien menu RageUI** (`/menuadmin_old`), qui a reçu les nouveautés du panel (geler, tuer, avertir, notes, retirer argent / objets, donner objet / arme, voir l'inventaire, annonce, météo, heure, nettoyage, chat staff, entretien véhicule).

La touche **F11** et `/menuadmin` ouvrent celui que tu choisis dans `pickax_core/players/menuadmin/config.lua` : `DefaultMenu = 'panel'` ou `'legacy'`. Chaque menu a un bouton pour ouvrir l'autre (panel : Outils → Ancien menu ; ancien menu : « Ouvrir le panel moderne »).

## Installation
```
ensure pickax_staff      # après es_extended, oxmysql et pickax_core
restart pickax_core      # nécessaire une fois (nouvelles API pour le panel)
```
Touche **F11** (celle du menu admin) ou commande `/staff`. Tables créées seules : `staff_logs`, `staff_warns`, `staff_notes`, `staff_settings`.

## Organisation
| Onglet | Contenu |
|---|---|
| **Accueil** | joueurs / staff / reports / bans, actions rapides (soin, réanimation, TP marqueur…), équipe en ligne, dernières actions |
| **Joueurs** | liste filtrable (tous, staff, proches, avertis) → **fiche joueur** : téléportation, santé, message, avertissement, spectate, prison, expulsion, bannissement, argent, objets, armes, vider l'inventaire, métier / gang, identité, grade staff, notes, historique, inventaire en lecture seule |
| **Reports** | file d'attente et reports en cours : prendre, aller sur lui / l'amener, répondre, fermer |
| **Véhicules** | apparition, réparer, nettoyer, retourner, plein, déverrouiller, custom max, plaque, néons, supprimer |
| **Monde** | météo, heure, annonce serveur, nettoyage de zone, réanimer / soigner tout le monde |
| **Sanctions** | avertissements du serveur, accès au panel anti-cheat (bans) |
| **Équipe** | chat staff, droits du panel, **grades staff** (créer, supprimer, couleur), **droits de l'ancien menu** (rang 4) |
| **Journal** | toutes les actions du staff, filtrables (90 jours) |
| **Outils** | coordonnées (copie vector3/4…), favoris, lieux rapides, **outils développeur** (info intérieur, menu PNJ, cutscenes, animations, intérieurs), tous les builders, anti-cheat |

Colonne de gauche, toujours visible : **mode administration** (tenue staff, comme avant) et réglages NoClip / invisible / invincible / noms / HUD.

## Droits
Le rang vient de `pickax_core` (mod = 1, admin = 2, superadmin = 3, _dev = 4 ; les grades personnalisés héritent de leur rang). `config.lua → Config.Perm` donne le **rang minimum par action** ; l'onglet Équipe → Droits (rang 4) les modifie en jeu sans redémarrage. Toutes les vérifications sont faites côté serveur. Un membre du staff ne peut pas sanctionner un rang égal ou supérieur.

## Configurer (config.lua)
Durées de ban, durées de prison, motifs rapides, météos, lieux rapides, seuil d'expulsion automatique par avertissements (`Config.Warn.KickAt`), rayon max de nettoyage.

## Limites honnêtes
- Non testé en jeu.
- Prison, soin d'un autre joueur et spectate passent par les commandes existantes du core (exécutées depuis ton client).
- Wipe et capture d'écran passent par les événements du core (leurs droits restent ceux de l'ancien système : `func_18` et `take_screen`).
- Le « give véhicule » (garage + clé) utilise la fonction du core, comme avant.
- Le journal Discord n'est pas branché ici (les actions staff sont dans l'onglet Journal).
