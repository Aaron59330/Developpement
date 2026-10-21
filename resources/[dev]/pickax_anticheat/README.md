# pickax_anticheat — anti-cheat propre à la base Pickax

Anti-cheat **serveur d'abord** (OneSync), avec panel en jeu. Conçu pour **ne pas faire de faux bans** : chaque détection ajoute des points à un score qui retombe avec le temps, les sanctions n'arrivent qu'à un seuil, et le staff, les métiers, les mini-jeux et les événements sont exemptés.

## Installation
1. Mettre `ensure pickax_anticheat` dans `server.cfg` **après** `es_extended`, `oxmysql` et `pickax_core`.
2. Les tables `anticheat_logs` et `anticheat_settings` se créent seules au démarrage.
3. Ouvrir le panel avec `/anticheat` (ou `/ac`) : groupes `admin`, `superadmin`, `_dev` (voir `Config.Panel`).
4. **Commencer en mode « Observation »** (panel → Règles → Général) : rien n'est sanctionné, tout est écrit dans le journal (« simulé : ban »). Après quelques jours sans faux positif, passer en « Protection ».

## Panel
- **Tableau de bord** : détections 24 h, bans actifs, joueurs les plus signalés.
- **Joueurs** : liste triée par suspicion ; fiche joueur → avertir, expulser, bannir, exempter.
- **Détections** : journal filtrable, bouton « Faux positif » (la ligne est grisée).
- **Bannissements** : recherche, débannir, bannir hors ligne par licence. Les bans sont écrits dans la table `banlist` du core : le contrôle de connexion existant les applique.
- **Règles** : tout est modifiable sans redémarrage (modules, armes, modèles, événements, exemptions, webhook Discord…). Les réglages enregistrés dans le panel **remplacent** les valeurs de `config.lua` ; « Réinitialiser » revient à `config.lua`.

Seuls `BanGroups` (`superadmin`, `_dev`) peuvent bannir, débannir, exempter et modifier les règles.

## Ajouter facilement des éléments (config.lua ou panel)
| Je veux… | Où |
|---|---|
| Autoriser une arme | `weapons.whitelist` |
| Interdire une arme | `weapons.blacklist` |
| Armes d'un métier | `weapons.jobs = { police = { 'WEAPON_STUNGUN' } }` |
| Interdire un véhicule / PNJ / objet | `models.vehicles / peds / objects` |
| Piéger un événement (triche sûre) | `events.honeypots` |
| Limiter la fréquence d'un événement | `events.limits` : `{ event, max, window, weight }` |
| Exempter un groupe / métier / licence | `exempt.groups / jobs / licenses` |
| Exempter pendant un script | statebag dans `exempt.states` ou export (voir ci-dessous) |

## Exemptions depuis un autre script
```lua
-- serveur : exempte 10 s juste avant une téléportation / un soin légitime
exports.pickax_anticheat:Exempt(source, 10, 'raison')
-- ou
TriggerEvent('pickax_anticheat:exempt', source, 10, 'raison')
-- statebag (reste actif tant qu'il vaut true) : inMinigame, inPvpZone, inGunfight, inArena, inEvent, acExempt
Player(source).state:set('acExempt', true, true)
```
`pickax_minigames` pose déjà `inMinigame` et exempte aux téléportations.

Autres exports : `IsExempt(src, module)`, `Flag(src, module, details, weight)`, `Ban(src, reason, seconds, by)`.

## Modules
Mouvement, téléportation (journal seulement par défaut), invincibilité, santé/armure, armes hors inventaire, armes interdites, modèles interdits, création en masse, explosions, fréquence d'événements, honeypots, battement client, signalements client (modificateurs de dégâts, invisibilité, spectateur), double compte (comparaison des identifiants avec la liste de bans ; kick par défaut, jamais de ban auto).

Pour chaque module : **Poids** (points par détection), **Expulsion / Ban** (score à atteindre, 0 = jamais). Le score diminue linéairement (`scoreDecay`).

## Limites honnêtes
- Un anti-cheat ne bloque pas tout (injecteurs exécutés côté client). Il détecte surtout les effets observables par le serveur.
- Les honeypots sont des noms d'événements que **rien dans ce dépôt** n'utilise. Si une ressource externe (hors dépôt) en utilise un, retire-le de la liste.
- Non testé en jeu : valider en mode Observation avant de passer en Protection.
