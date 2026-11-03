# Configuration de la base (sans panel)

Le panel web a été retiré : **tout se règle dans les fichiers de configuration**, puis `restart <ressource>` (ou redémarrage du serveur). Le panel est archivé dans `_archive_panel/` ; dis « remets le panel » pour le réinstaller (voir `_archive_panel/RESTAURER-LE-PANEL.md`).

## Je veux changer…

| Quoi | Où | Clé |
|---|---|---|
| Couleur principale, nom, slogan, logo, Discord du serveur | `resources/[script]/pickax_core/config.lua` | `AccentColor`, `ServerName`, `ServerShortName`, `ServerTagline`, `ServerDiscord`, `ServerLogo` |
| Couleur de l'inventaire | `pickax_core/config.lua` | `InventoryColor` (vide = couleur du serveur) |
| Bannière du menu F5 | `resources/[script]/pickax_ui/html/banner.jpg` (ou `ServerMenuBanner` dans `pickax_core/config.lua`) | — |
| Écran de chargement (musique, équipe, mises à jour, liens, fond, textes) | `pickax_core/config.lua` | `Config.Loading` (`restart pickax_core`) |
| Nom / description / tags / bannières dans la liste FiveM | `server.cfg` section 4 | `sv_projectName`, `sv_projectDesc`, `tags`, `banner_*` |
| Nombre de places | `server.cfg` | `sv_maxclients` |
| Whitelist, message de bienvenue | `resources/[dev]/pickax_basetools/config.lua` | `Config.Whitelist`, `Config.Motd` |
| Mode de jeu facile / difficile, maintenance, annonces, redémarrages, météo, combat, drogues, gangs, Discord… | `resources/[dev]/pickax_settings/config.lua` | `Settings.Overrides` (liste de toutes les clés plus bas) |
| Type d'économie (équilibré / réaliste / abusé) | `resources/[dev]/pickax_economy/config.lua` | `Config.Preset` |
| Parcours d'arrivée (création du personnage, apparition, bienvenue) | `resources/[script]/pickax_creator/config.lua` | — |
| Boutique à coins, roulette du jour, coupons | `resources/[dev]/pickax_boutique/config.lua` | `Config.Wheel`, … |
| Casino (jetons, machines, blackjack, roulette) | `resources/[dev]/pickax_casino/config.lua` + World Builder (postes et prix des jetons) | — |
| Sacs, portefeuille | `resources/[inventaire]/ox_inventory/data/config_sacs.lua` | — |
| Carnet du joueur | `resources/[dev]/pickax_carnet/config.lua` | `Config.Enabled`, `Config.RewardMultiplier` |
| Boutique des jobs, gangs, drogues, braquages, shops… | les builders en jeu (`/builders`) et le `config.lua` de chaque builder | — |
| Clavier (touches par défaut) | `resources/[dev]/pickax_keybinds/config.lua` | — |

## Tous les fichiers de configuration

| Ressource | Fichier | Rôle |
|---|---|---|
| `pickax_anticheat` | `resources/[dev]/pickax_anticheat/config.lua` | Anti-cheat Pickax : détections côté serveur (OneSync), scores par module, panneau de gestion en jeu (joueurs,  |
| `pickax_auction` | `resources/[dev]/pickax_auction/config.lua` | Hôtel des ventes : enchères entre joueurs (objets ox_inventory et véhicules), achat immédiat, mise en dépôt sé |
| `pickax_basetools` | `resources/[dev]/pickax_basetools/config.lua` | Outils de la base : audit de santé (ressources, SQL, items, données), sauvegardes / restauration de la configu |
| `pickax_bourse` | `resources/[dev]/pickax_bourse/config.lua` | Bourse : actions fictives dont le prix évolue côté serveur (marche aléatoire + actualités), achat / vente, por |
| `pickax_boutique` | `resources/[dev]/pickax_boutique/config.lua` | Interface moderne de la boutique à coins (véhicules, motos, armes, caisses, packs, entreprises) avec images ;  |
| `pickax_builderhub` | `resources/[dev]/pickax_builderhub/config.lua` | Panel central qui regroupe tous les builders (jobs, gangs, boutiques, monde) : accès rapide, état et statistiq |
| `pickax_carnet` | `resources/[dev]/pickax_carnet/config.lua` | Carnet du joueur : série de connexion, objectifs du jour et de la semaine, défi de la ville (récompenses autom |
| `pickax_carplay` | `resources/[dev]/pickax_carplay/config.lua` | CarPlay : autoradio de véhicule (YouTube, liens directs, radios, file d\ |
| `pickax_casino` | `resources/[dev]/pickax_casino/config.lua` | Casino complet : caisse (achat / rachat de jetons), machines à sous, blackjack et roulette ; tout le hasard es |
| `pickax_compass` | `resources/[dev]/pickax_compass/config.lua` | HUD boussole : cap, points cardinaux, rue et quartier en haut de l\ |
| `pickax_dialog` | `resources/[dev]/pickax_dialog/config.lua` | Dialogue de PNJ : le PNJ se tourne vers le joueur et écrit un texte avec un bouton Accepter / Refuser avant d\ |
| `pickax_economy` | `resources/[dev]/pickax_economy/config.lua` | Économie dynamique : multiplicateurs de prix selon l\ |
| `pickax_eventbuilder` | `resources/[dev]/pickax_eventbuilder/config.lua` | Event Builder : crée et lance des événements en jeu (braquage de fourgon blindé, largage, braquage de commerce |
| `pickax_gangbuilder` | `resources/[dev]/pickax_gangbuilder/config.lua` | Gang Builder ESX complet basé sur job2 : gangs, grades, garages, vestiaires, armureries, coffres, trésorerie,  |
| `pickax_hud1` | `resources/[dev]/pickax_hud1/config.lua` | HUD Hunger/Thirst BlueBay - ESX/esx_status compatible |
| `pickax_illegalbuilder` | `resources/[dev]/pickax_illegalbuilder/config.lua` | Builder Illégal ESX : drogues (récolte / laboratoires / traitement / vente / blanchiment), braquages (supérett |
| `pickax_jobbuilder` | `resources/[dev]/pickax_jobbuilder/config.lua` | Job Builder ESX complet : jobs, grades, garages, vestiaires, armureries, coffres, boss, boutiques (UI + oxmysq |
| `pickax_jobbuilder` | `resources/[dev]/pickax_jobbuilder/config_active.lua` | Job Builder ESX complet : jobs, grades, garages, vestiaires, armureries, coffres, boss, boutiques (UI + oxmysq |
| `pickax_jobbuilder` | `resources/[dev]/pickax_jobbuilder/config_events.lua` | Job Builder ESX complet : jobs, grades, garages, vestiaires, armureries, coffres, boss, boutiques (UI + oxmysq |
| `pickax_keybinds` | `resources/[dev]/pickax_keybinds/config.lua` | Mes touches : liste en direct des raccourcis de la base avec la touche RÉELLEMENT attribuée au joueur, détecti |
| `pickax_minigames` | `resources/[dev]/pickax_minigames/config.lua` | Mini-jeux Builder : crée en jeu des mini-jeux (basket, football, tennis, boxe, paintball, laser game, courses… |
| `pickax_notify` | `resources/[dev]/pickax_notify/config.lua` | Notifications ESX style Pickax - compatible ShowNotification / ShowAdvancedNotification / ShowHelpNotification |
| `pickax_phone` | `resources/[dev]/pickax_phone/config.lua` | Aero Smartphone — smartphone complet (ESX · QBCore · Qbox · standalone) : appels vocaux, messages, réseaux soc |
| `pickax_settings` | `resources/[dev]/pickax_settings/config.lua` | Réglages du serveur modifiables depuis le panel web : maintenance, annonces, redémarrages, monde et PNJ, météo |
| `pickax_shopbuilder` | `resources/[dev]/pickax_shopbuilder/config.lua` | Shop Builder ESX : crée n\ |
| `pickax_tutorial` | `resources/[dev]/pickax_tutorial/config.lua` | Tutoriel d\ |
| `pickax_weaponcarry` | `resources/[dev]/pickax_weaponcarry/config.lua` | Armes portées visibles sur le personnage (dans le dos, à la ceinture, dans la poche) ou invisibles ; le placem |
| `pickax_worldbuilder` | `resources/[dev]/pickax_worldbuilder/config.lua` | World Builder ESX : crée en jeu des garages, fourrières, locations de véhicules, stations essence, etc. (drogu |
| `es_extended` | `resources/[essential]/es_extended/config.logs.lua` | ES Extended |
| `es_extended` | `resources/[essential]/es_extended/config.lua` | ES Extended |
| `es_extended` | `resources/[essential]/es_extended/config.weapons.lua` | ES Extended |
| `ox_inventory` | `resources/[inventaire]/ox_inventory/config.lua` | Slot-based inventory with item metadata support |
| `p_bridge` | `resources/[inventaire]/p_bridge/config.lua` | pScripts - Official Bridge |
| `p_itemclothes` | `resources/[inventaire]/p_itemclothes/config.lua` | pScripts Inventory Clothing Items - ox_inventory |
| `p_outfits` | `resources/[inventaire]/p_outfits/config.lua` | Tenues completes : item "Tenue" a glisser sur la case Tenue de ox_inventory (equipe / retire toutes les pieces |
| `esx_identity` | `resources/[script]/esx_identity/config.lua` |  |
| `pickax_core` | `resources/[script]/pickax_core/config.lua` | pickax_core |
| `pickax_core` | `resources/[script]/pickax_core/config_sv.lua` | pickax_core |
| `pickax_creator` | `resources/[script]/pickax_creator/config.lua` | Écrans plein format : création d\ |
| `basicEvent` | `resources/[system]/basicEvent/config.lua` |  |

## Réglages de `pickax_settings` (clés de `Settings.Overrides`)

Exemple : dans `resources/[dev]/pickax_settings/config.lua` →

```lua
Settings.Overrides = {
    game_mode = 'facile',
    maintenance_enabled = false,
    announce_enabled = true,
}
```

| Groupe | Section | Clé | Réglage | Type | Défaut |
|---|---|---|---|---|---|
| Serveur | Maintenance | `maintenance_enabled` | Mode maintenance | bool | `false` |
| Serveur | Maintenance | `maintenance_message` | Message de maintenance | text | `Le serveur est en maintenance, reviens dans quelques minutes.` |
| Serveur | Maintenance | `maintenance_allow` | Identifiants autorisés pendant la maintenance | list | `{}` |
| Serveur | Maintenance | `maintenance_kick` | Expulser les joueurs en ligne à l'activation | bool | `true` |
| Serveur | Annonces automatiques | `announce_enabled` | Annonces automatiques | bool | `false` |
| Serveur | Annonces automatiques | `announce_interval` | Intervalle des annonces (minutes) | number | `15` |
| Serveur | Annonces automatiques | `announce_messages` | Messages des annonces | list | `{Pense à lire le règlement du serveur.}` |
| Serveur | Redémarrages programmés | `restart_enabled` | Redémarrages programmés | bool | `false` |
| Serveur | Redémarrages programmés | `restart_times` | Heures de redémarrage | text | `05:00` |
| Interface | Notifications | `notify_left` | Notifications : distance au bord gauche (vw) | number | `1.35` |
| Interface | Notifications | `notify_bottom` | Notifications : distance au bas (vh) | number | `22.5` |
| Interface | Boussole | `compass_layout` | Boussole : format | select | `compact` |
| Interface | Boussole | `compass_street` | Boussole : afficher le nom de la rue | bool | `true` |
| Interface | Boussole | `compass_left` | Boussole compacte : position gauche (vw) | number | `19.6` |
| Interface | Boussole | `compass_bottom` | Boussole compacte : position bas (vh) | number | `3.4` |
| Carnet | Récompenses | `carnet_enabled` | Carnet du joueur activé | bool | `true` |
| Carnet | Récompenses | `carnet_reward_mult` | Multiplicateur des récompenses | number | `1.0` |
| Interface | HUD (faim, soif, vie) | `hud_needs` | HUD : afficher faim et soif | bool | `true` |
| Interface | HUD (faim, soif, vie) | `hud_health` | HUD : afficher la barre de vie | bool | `true` |
| Interface | HUD (faim, soif, vie) | `hud_armor` | HUD : afficher la ligne d'armure | bool | `true` |
| Interface | Cartes en haut à droite | `hud2_server` | Cartes en haut à droite : serveur (nom, Discord, joueurs) | bool | `true` |
| Interface | Cartes en haut à droite | `hud2_job` | Cartes en haut à droite : métier | bool | `true` |
| Interface | Cartes en haut à droite | `hud2_money` | Cartes en haut à droite : argent | bool | `true` |
| Voix | Distances de la voix | `voice_whisper` | Distance « chuchoter » (m) | number | `3` |
| Voix | Distances de la voix | `voice_normal` | Distance « normal » (m) | number | `7` |
| Voix | Distances de la voix | `voice_shout` | Distance « crier » (m) | number | `15` |
| Performance | Mode performance | `perf_mode` | Mode performance des interfaces | select | `auto` |
| Performance | Mode performance | `perf_threshold` | Seuil « FPS bas » du mode automatique | number | `40` |
| Économie | Gains | `eco_weekend_income` | Bonus de gains le week-end (×) | number | `1` |
| Monde & PNJ | Population | `npc_enabled` | PNJ et circulation | bool | `false` |
| Monde & PNJ | Population | `npc_density` | Densité des piétons | number | `0.5` |
| Monde & PNJ | Population | `traffic_density` | Densité de la circulation | number | `0.5` |
| Monde & PNJ | Population | `parked_density` | Densité des véhicules garés | number | `0.5` |
| Monde & PNJ | Police et recherche | `npc_police` | Policiers PNJ (patrouilles, hélicoptères) | bool | `false` |
| Monde & PNJ | Police et recherche | `wanted_enabled` | Niveau de recherche (étoiles) | bool | `true` |
| Monde & PNJ | Transports ambiants | `npc_boats` | Bateaux PNJ | bool | `false` |
| Monde & PNJ | Transports ambiants | `npc_trains` | Trains PNJ | bool | `false` |
| Monde & PNJ | Transports ambiants | `npc_garbage` | Camions-poubelles PNJ | bool | `false` |
| Météo & heure | Météo | `weather_dynamic` | Météo dynamique | bool | `false` |
| Météo & heure | Météo | `weather_type` | Météo fixe | select | `EXTRASUNNY` |
| Météo & heure | Météo | `blackout` | Panne de courant (noir total) | bool | `false` |
| Météo & heure | Heure | `time_frozen` | Figer l'heure | bool | `false` |
| Météo & heure | Heure | `time_hour` | Heure figée | number | `12` |
| Joueurs & combat | Combat | `friendly_fire` | Tir ami (dégâts entre joueurs) | bool | `true` |
| Joueurs & combat | Combat | `weapon_damage` | Dégâts des armes (×) | number | `1.0` |
| Joueurs & combat | Combat | `melee_damage` | Dégâts au corps à corps (×) | number | `1.0` |
| Joueurs & combat | Combat | `critical_hits` | Coups critiques (tir à la tête) | bool | `true` |
| Joueurs & combat | Combat | `drive_by` | Tirer depuis un véhicule | bool | `true` |
| Joueurs & combat | Santé et endurance | `health_regen` | Régénération naturelle de la vie (×) | number | `1.0` |
| Joueurs & combat | Santé et endurance | `stamina_infinite` | Endurance infinie | bool | `false` |
| Joueurs & combat | Divers | `idle_cam` | Caméra d'inactivité (cinématique AFK) | bool | `true` |
| Nouveaux joueurs | Création du personnage | `start_money` | Argent bonus à l'arrivée (banque) | number | `0` |
| Nouveaux joueurs | Accueil | `welcome_message` | Message de bienvenue | text | `` |
| Interface | Viseur | `hud_crosshair` | Afficher le viseur | bool | `true` |
| Discord | Statut Discord | `discord_status` | Texte du statut (présence) | text | `` |
| Gangs | Territoires | `gb_terr_enabled` | Territoires activés | bool | `true` |
| Gangs | Territoires | `gb_capture_seconds` | Durée de capture (secondes) | number | `120` |
| Gangs | Territoires | `gb_capture_members` | Membres minimum pour capturer | number | `1` |
| Gangs | Territoires | `gb_owner_blocks` | La présence du propriétaire bloque la capture | bool | `true` |
| Gangs | Territoires | `gb_protection_min` | Protection après une capture (minutes) | number | `30` |
| Gangs | Territoires | `gb_income_interval` | Intervalle des revenus (minutes) | number | `15` |
| Gangs | Territoires | `gb_income_reward` | Revenu par période ($) | number | `500` |
| Gangs | Territoires | `gb_income_account` | Compte crédité par les revenus | select | `dirty` |
| Gangs | Territoires | `gb_min_defenders` | Défenseurs connectés requis pour capturer | number | `1` |
| Gangs | Territoires | `gb_max_per_gang` | Territoires maximum par gang | number | `0` |
| Gangs | Territoires | `gb_alert_owner` | Prévenir le propriétaire quand on attaque sa zone | bool | `true` |
| Gangs | Racket | `gb_racket_enabled` | Racket activé | bool | `true` |
| Gangs | Racket | `gb_racket_rate` | Taux du racket (%) | number | `10` |
| Gangs | Affrontements | `gb_conf_enabled` | Affrontements activés | bool | `true` |
| Gangs | Affrontements | `gb_conf_duration` | Durée (secondes) | number | `300` |
| Gangs | Affrontements | `gb_conf_cooldown` | Délai entre deux affrontements (secondes) | number | `900` |
| Gangs | Affrontements | `gb_conf_capture` | L'intrus qui gagne capture le territoire | bool | `true` |
| Gangs | Affrontements | `gb_conf_rep` | Réputation du gagnant | number | `20` |
| Gangs | Guerre de zone déclarée | `gb_turf_enabled` | Guerre de zone activée | bool | `true` |
| Gangs | Guerre de zone déclarée | `gb_turf_prep` | Préparation avant le début (secondes) | number | `120` |
| Gangs | Guerre de zone déclarée | `gb_turf_duration` | Durée de la dispute (secondes) | number | `600` |
| Gangs | Guerre de zone déclarée | `gb_turf_attackers` | Attaquants connectés requis | number | `2` |
| Gangs | Guerre de zone déclarée | `gb_turf_defenders` | Défenseurs connectés requis | number | `1` |
| Gangs | Guerre de zone déclarée | `gb_turf_cooldown` | Délai avant de redéclarer sur la même zone (secondes) | number | `1800` |
| Gangs | Guerre de zone déclarée | `gb_turf_minkills` | Kills d'avance pour que l'attaquant l'emporte | number | `1` |
| Gangs | Guerre de zone déclarée | `gb_turf_repwin` | Réputation du gagnant | number | `30` |
| Gangs | Guerre de zone déclarée | `gb_turf_replose` | Réputation retirée au perdant | number | `10` |
| Gangs | Guerre de zone déclarée | `gb_turf_protected` | Autoriser la guerre sur un territoire protégé | bool | `false` |
| Gangs | Zones de tribut | `gb_trib_enabled` | Zones de tribut activées | bool | `true` |
| Gangs | Zones de tribut | `gb_trib_auto` | Lancement automatique | bool | `true` |
| Gangs | Zones de tribut | `gb_trib_interval` | Intervalle entre deux événements (minutes) | number | `60` |
| Gangs | Zones de tribut | `gb_trib_gangs` | Gangs connectés requis pour un lancement automatique | number | `2` |
| Gangs | Zones de tribut | `gb_trib_minper` | Survivants minimum pour pouvoir gagner | number | `1` |
| Gangs | Zones de tribut | `gb_trib_seconds` | Durée de la dispute (secondes) | number | `300` |
| Gangs | Zones de tribut | `gb_trib_collect` | Temps pour collecter (secondes) | number | `600` |
| Gangs | Zones de tribut | `gb_trib_reward` | Tribut ($) | number | `3000` |
| Gangs | Zones de tribut | `gb_trib_account` | Compte crédité par le tribut | select | `dirty` |
| Gangs | Zones de tribut | `gb_trib_rep` | Réputation du gagnant | number | `15` |
| Gangs | Missions colis | `gb_obj_enabled` | Missions colis activées | bool | `true` |
| Gangs | Missions colis | `gb_obj_auto` | Lancement automatique | bool | `true` |
| Gangs | Missions colis | `gb_obj_interval` | Intervalle entre deux missions (minutes) | number | `45` |
| Gangs | Missions colis | `gb_obj_hold` | Temps à tenir dans la zone (secondes) | number | `180` |
| Gangs | Missions colis | `gb_obj_reward` | Récompense ($) | number | `5000` |
| Gangs | Missions colis | `gb_obj_rep` | Réputation | number | `40` |
| Gangs | Guerres entre gangs (tablette) | `gb_wars_enabled` | Guerres entre gangs activées | bool | `true` |
| Gangs | Guerres entre gangs (tablette) | `gb_wars_stake` | Mise maximum ($ sale) | number | `50000` |
| Gangs | Guerres entre gangs (tablette) | `gb_wars_cooldown` | Délai avant de se rebattre contre le même gang (minutes) | number | `30` |
| Gangs | Guerres entre gangs (tablette) | `gb_wars_repwin` | Réputation du gagnant | number | `60` |
| Gangs | Guerres entre gangs (tablette) | `gb_wars_replose` | Réputation retirée au perdant | number | `15` |
| Drogues & labos | Laboratoire interactif | `jb_lab_enabled` | Fabrication interactive activée | bool | `true` |
| Drogues & labos | Laboratoire interactif | `jb_lab_yield` | Part du rendement qui dépend de la qualité | number | `0.4` |
| Drogues & labos | Laboratoire interactif | `jb_lab_fail` | Risque de lot raté à qualité 0 (%) | number | `35` |
| Drogues & labos | Laboratoire interactif | `jb_lab_bonus_q` | Seuil de qualité du bonus (0-1) | number | `0.92` |
| Drogues & labos | Laboratoire interactif | `jb_lab_bonus_extra` | Pochons bonus si qualité parfaite | number | `1` |
| Drogues & labos | Laboratoire interactif | `jb_lab_minstep` | Durée minimale d'une étape (ms, anti-triche) | number | `1200` |
| Drogues & labos | Rendu 3D et caméra du labo | `jb_lab_3d` | Objets 3D sur la table | bool | `true` |
| Drogues & labos | Rendu 3D et caméra du labo | `jb_lab_light` | Lueur et éclairage de la table | bool | `true` |
| Drogues & labos | Rendu 3D et caméra du labo | `jb_lab_mat` | Tapis sombre sous les objets | bool | `true` |
| Drogues & labos | Rendu 3D et caméra du labo | `jb_lab_cam_dist` | Distance de la caméra (m) | number | `0.85` |
| Drogues & labos | Rendu 3D et caméra du labo | `jb_lab_cam_pitch` | Inclinaison de la caméra (°) | number | `-64` |
| Drogues & labos | Rendu 3D et caméra du labo | `jb_lab_cam_fov` | Champ de vision de la caméra (°) | number | `45` |
| Drogues & labos | Intoxication des laboratoires | `jb_toxic_enabled` | Intoxication activée | bool | `true` |
| Drogues & labos | Intoxication des laboratoires | `jb_toxic_gain` | Vitesse d'intoxication | number | `6` |
| Drogues & labos | Intoxication des laboratoires | `jb_toxic_damage` | Dégâts à partir du seuil (PV par tick) | number | `4` |
| Drogues & labos | Intoxication des laboratoires | `jb_toxic_kill` | Niveau mortel (0-100) | number | `100` |
| Drogues & labos | Vente de drogue aux PNJ | `ib_pedsales` | Vente de drogue aux PNJ (dealers) | bool | `true` |
| Drogues & labos | Vente dans la rue (menu contextuel) | `ib_street_enabled` | Vente dans la rue activée | bool | `true` |
| Drogues & labos | Vente dans la rue (menu contextuel) | `ib_street_tablet` | Tablette vendeur obligatoire | bool | `true` |
| Drogues & labos | Vente dans la rue (menu contextuel) | `ib_street_chance` | Chance qu'un PNJ accepte (%) | number | `60` |
| Drogues & labos | Vente dans la rue (menu contextuel) | `ib_street_qmin` | Quantité minimum par vente | number | `1` |
| Drogues & labos | Vente dans la rue (menu contextuel) | `ib_street_qmax` | Quantité maximum par vente | number | `3` |
| Drogues & labos | Vente dans la rue (menu contextuel) | `ib_street_factor` | Prix de rue (× le prix du dealer) | number | `0.8` |
| Drogues & labos | Vente dans la rue (menu contextuel) | `ib_street_cooldown` | Délai entre deux ventes (secondes) | number | `8` |
| Drogues & labos | Vente dans la rue (menu contextuel) | `ib_street_hour` | Unités vendues par joueur et par heure | number | `30` |
| Drogues & labos | Vente dans la rue (menu contextuel) | `ib_street_alert` | Alerte police après une vente (%) | number | `20` |
| Drogues & labos | Vente dans la rue (menu contextuel) | `ib_street_refuse` | Alerte police quand le PNJ refuse (%) | number | `10` |
| Drogues & labos | Vente dans la rue (menu contextuel) | `ib_street_cops` | Policiers en service requis | number | `0` |
| Drogues & labos | Pureté du produit | `ib_purity_enabled` | Pureté : influence sur le prix | bool | `true` |
| Drogues & labos | Pureté du produit | `ib_purity_default` | Pureté d'un produit sans pureté (%) | number | `50` |
| Drogues & labos | Pureté du produit | `ib_purity_min` | Prix à 0 % de pureté (×) | number | `0.6` |
| Drogues & labos | Pureté du produit | `ib_purity_max` | Prix à 100 % de pureté (×) | number | `1.4` |
| Drogues & labos | Accidents de labo | `jb_acc_enabled` | Accidents activés | bool | `true` |
| Drogues & labos | Accidents de labo | `jb_acc_threshold` | Seuil de qualité (0-1) sous lequel un accident est possible | number | `0.5` |
| Drogues & labos | Accidents de labo | `jb_acc_chance` | Risque d'accident à qualité 0 (%) | number | `60` |
| Drogues & labos | Accidents de labo | `jb_acc_leak` | Fuite : intoxication ajoutée (0-100) | number | `40` |
| Drogues & labos | Accidents de labo | `jb_acc_fire` | Incendie : points de vie perdus | number | `30` |
| Drogues & labos | Accidents de labo | `jb_acc_explosion` | Explosion : points de vie perdus | number | `70` |
| Drogues & labos | Accidents de labo | `jb_acc_lose` | Incendie / explosion : le lot est perdu | bool | `true` |
| Drogues & labos | Catalyseur | `jb_cat_enabled` | Catalyseur activé | bool | `true` |
| Drogues & labos | Catalyseur | `jb_cat_quality` | Bonus de qualité (0-1) | number | `0.12` |
| Drogues & labos | Catalyseur | `jb_cat_factor` | Risque d'accident avec catalyseur (×) | number | `0.5` |
| Drogues & labos | Niveaux de laborantin | `jb_lvl_enabled` | Niveaux activés | bool | `true` |
| Drogues & labos | Niveaux de laborantin | `jb_lvl_xp` | XP par lot réussi | number | `10` |
| Drogues & labos | Niveaux de laborantin | `jb_lvl_base` | XP du niveau 2 (le niveau n+1 demande Base × n²) | number | `100` |
| Drogues & labos | Niveaux de laborantin | `jb_lvl_max` | Niveau maximum | number | `10` |
| Drogues & labos | Niveaux de laborantin | `jb_lvl_quality` | Qualité gagnée par niveau (0-1) | number | `0.015` |
| Drogues & labos | Niveaux de laborantin | `jb_lvl_accident` | Risque d'accident retiré par niveau (0-1) | number | `0.06` |
| Drogues & labos | Niveaux de laborantin | `jb_lvl_coke` | Niveau requis : cocaïne | number | `2` |
| Drogues & labos | Niveaux de laborantin | `jb_lvl_meth` | Niveau requis : méthamphétamine | number | `3` |
| Drogues & labos | Niveaux de laborantin | `jb_lvl_opium` | Niveau requis : opium / héroïne | number | `2` |
| Drogues & labos | Réputation de dealer | `ib_rep_enabled` | Réputation de dealer activée | bool | `true` |
| Drogues & labos | Réputation de dealer | `ib_rep_unit` | Réputation par unité vendue | number | `1` |
| Drogues & labos | Réputation de dealer | `ib_rep_accept` | Acceptation en plus par niveau (%) | number | `4` |
| Drogues & labos | Réputation de dealer | `ib_rep_price` | Prix en plus par niveau (0-1) | number | `0.04` |
| Drogues & labos | Quartiers (saturation et chaleur) | `ib_zone_enabled` | Quartiers activés | bool | `true` |
| Drogues & labos | Quartiers (saturation et chaleur) | `ib_zone_cell` | Taille d'un secteur (m) | number | `300` |
| Drogues & labos | Quartiers (saturation et chaleur) | `ib_zone_sat` | Saturation par unité vendue | number | `4` |
| Drogues & labos | Quartiers (saturation et chaleur) | `ib_zone_satdecay` | Retombée de la saturation (par minute) | number | `3` |
| Drogues & labos | Quartiers (saturation et chaleur) | `ib_zone_drop` | Baisse de prix maximale à saturation 100 (0-1) | number | `0.4` |
| Drogues & labos | Quartiers (saturation et chaleur) | `ib_zone_heat` | Chaleur par vente | number | `6` |
| Drogues & labos | Quartiers (saturation et chaleur) | `ib_zone_heatdecay` | Retombée de la chaleur (par minute) | number | `2` |
| Drogues & labos | Quartiers (saturation et chaleur) | `ib_zone_heatalert` | Alerte police en plus par point de chaleur (%) | number | `0.3` |
| Drogues & labos | Quartiers (saturation et chaleur) | `ib_zone_heataccept` | Acceptation en moins par point de chaleur (%) | number | `0.25` |
| Gangs | Saisons de gangs | `gb_season_enabled` | Saisons activées | bool | `true` |
| Gangs | Saisons de gangs | `gb_season_days` | Durée d'une saison (jours) | number | `7` |
| Gangs | Saisons de gangs | `gb_season_min` | Points minimum pour être classé | number | `10` |
| Gangs | Saisons de gangs | `gb_season_account` | Compte crédité par les récompenses | select | `dirty` |
| Gangs | Saisons de gangs | `gb_season_r1` | Récompense du 1er ($) | number | `15000` |
| Gangs | Saisons de gangs | `gb_season_r2` | Récompense du 2e ($) | number | `8000` |
| Gangs | Saisons de gangs | `gb_season_r3` | Récompense du 3e ($) | number | `4000` |
| Gangs | Saisons de gangs | `gb_season_rep1` | Réputation du 1er | number | `50` |
| Gangs | Saisons de gangs | `gb_season_rep2` | Réputation du 2e | number | `30` |
| Gangs | Saisons de gangs | `gb_season_rep3` | Réputation du 3e | number | `15` |
| Gangs | QG de gang | `gb_hq_enabled` | QG de gang activé | bool | `true` |
| Gangs | QG de gang | `gb_hq_account` | Compte qui paie les améliorations | select | `dirty` |
| Gangs | QG de gang | `gb_hq_cost2` | Coût du niveau 2 ($) | number | `25000` |
| Gangs | QG de gang | `gb_hq_cost3` | Coût du niveau 3 ($) | number | `60000` |
| Gangs | QG de gang | `gb_hq_cost4` | Coût du niveau 4 ($) | number | `120000` |
| Gangs | Raids de QG | `gb_raid_enabled` | Raids de QG activés | bool | `true` |
| Gangs | Raids de QG | `gb_raid_hold` | Temps à tenir (secondes) | number | `90` |
| Gangs | Raids de QG | `gb_raid_radius` | Rayon de la zone (m) | number | `12.0` |
| Gangs | Raids de QG | `gb_raid_max` | Durée maximale d'un raid (secondes) | number | `600` |
| Gangs | Tags de gang | `gb_tags_enabled` | Tags activés | bool | `true` |
| Gangs | Tags de gang | `gb_tags_max` | Tags max par gang et par territoire | number | `5` |
| Gangs | Tags de gang | `gb_tags_income` | Revenu en plus par tag (%) | number | `4` |
| Gangs | Tags de gang | `gb_tags_incomemax` | Plafond du bonus de revenu (%) | number | `20` |
| Gangs | Tags de gang | `gb_tags_expire` | Durée de vie d'un tag (jours, 0 = illimité) | number | `7` |
| Gangs | Convois | `gb_convoy_enabled` | Convois activés | bool | `true` |
| Gangs | Convois | `gb_convoy_base` | Prime de base ($) | number | `4000` |
| Gangs | Convois | `gb_convoy_km` | Prime par kilomètre ($) | number | `2500` |
| Gangs | Convois | `gb_convoy_steal` | Part de la prime volée par les détourneurs (%) | number | `50` |
| Gangs | Convois | `gb_convoy_seconds` | Temps d'interception nécessaire (secondes) | number | `30` |
| Gangs | Convois | `gb_convoy_cool` | Délai entre deux convois d'un gang (secondes) | number | `1800` |
| Gangs | Raids de QG | `gb_raid_att` | Attaquants connectés requis | number | `2` |
| Gangs | Raids de QG | `gb_raid_def` | Défenseurs connectés requis | number | `1` |
| Gangs | Raids de QG | `gb_raid_pct` | Part de l'argent sale pillée (%) | number | `10` |
| Gangs | Raids de QG | `gb_raid_mindirty` | Argent sale minimum dans le QG ($) | number | `2000` |
| Gangs | Raids de QG | `gb_raid_maxsteal` | Pillage maximum ($) | number | `20000` |
| Gangs | Raids de QG | `gb_raid_cool` | Délai avant de raider le même QG (secondes) | number | `3600` |
| Gangs | Raids de QG | `gb_raid_acool` | Délai entre deux raids du même gang (secondes) | number | `1800` |
| Drogues & labos | Perquisitions et saisies (police) | `ib_seize_enabled` | Perquisitions activées | bool | `true` |
| Drogues & labos | Perquisitions et saisies (police) | `ib_seize_distance` | Distance policier ↔ suspect (m) | number | `3.0` |
| Drogues & labos | Perquisitions et saisies (police) | `ib_seize_cooldown` | Délai entre deux saisies d'un policier (secondes) | number | `4` |
| Drogues & labos | Perquisitions et saisies (police) | `ib_seize_black` | Saisir aussi l'argent sale | bool | `true` |
| Drogues & labos | Perquisitions et saisies (police) | `ib_seize_share` | Part de l'argent sale reversée à la société (%) | number | `100` |
| Drogues & labos | Perquisitions et saisies (police) | `ib_seize_society` | Compte société qui reçoit l'argent saisi | text | `society_police` |
| Drogues & labos | Perquisitions et saisies (police) | `ib_seize_evidence` | Objets saisis placés dans le casier de preuves (/preuves) | bool | `true` |
| Drogues & labos | Marché noir à rotation | `ib_bm_enabled` | Marché noir activé | bool | `true` |
| Drogues & labos | Marché noir à rotation | `ib_bm_hours` | Durée d'une rotation (heures) | number | `24` |
| Drogues & labos | Marché noir à rotation | `ib_bm_offers` | Produits proposés par rotation | number | `4` |
| Drogues & labos | Marché noir à rotation | `ib_bm_limit` | Achats max par produit et par joueur | number | `3` |
| Drogues & labos | Marché noir à rotation | `ib_bm_alert` | Chance d'alerter la police à un achat (%) | number | `10` |
| Drogues & labos | Contrats de livraison | `ib_ct_enabled` | Contrats activés | bool | `true` |
| Drogues & labos | Contrats de livraison | `ib_ct_base` | Paiement de base ($) | number | `600` |
| Drogues & labos | Contrats de livraison | `ib_ct_km` | Prime par kilomètre ($) | number | `900` |
| Drogues & labos | Contrats de livraison | `ib_ct_cool` | Délai entre deux contrats (secondes) | number | `120` |
| Drogues & labos | Contrats de livraison | `ib_ct_alert` | Chance d'alerter la police au départ (%) | number | `25` |
| Drogues & labos | Casier judiciaire et récidive | `ib_rec_enabled` | Casier : saisies et peines ajoutées à la tablette police | bool | `true` |
| Drogues & labos | Casier judiciaire et récidive | `ib_rec_recidive` | Récidive : amendes et peines aggravées | bool | `true` |
| Drogues & labos | Casier judiciaire et récidive | `ib_rec_recpct` | Aggravation par antécédent récent (%) | number | `20` |
| Drogues & labos | Prison | `ib_prison_enabled` | Prison activée | bool | `true` |
| Drogues & labos | Prison | `ib_prison_max` | Peine maximale (minutes) | number | `60` |
| Drogues & labos | Prison | `ib_prison_reduce` | Réduction par travail (secondes) | number | `30` |
| Drogues & labos | Prison | `ib_prison_cap` | Part de la peine réductible par le travail (%) | number | `50` |
| Drogues & labos | Évasion | `ib_esc_enabled` | Évasion activée | bool | `true` |
| Drogues & labos | Évasion | `ib_esc_seconds` | Durée de la tentative (secondes) | number | `45` |
| Drogues & labos | Évasion | `ib_esc_cops` | Policiers connectés nécessaires | number | `0` |
| Drogues & labos | Évasion | `ib_esc_penalty` | Pénalité à la reprise (minutes) | number | `10` |
| Drogues & labos | Caution | `ib_bail_enabled` | Caution activée | bool | `true` |
| Drogues & labos | Caution | `ib_bail_minute` | Prix par minute de peine restante ($) | number | `400` |
| Drogues & labos | Caution | `ib_bail_max` | Peine maximale avec caution (minutes) | number | `30` |
| Drogues & labos | Caution | `ib_bail_hours` | Durée du bracelet (heures) | number | `12` |
| Drogues & labos | Justice | `ib_just_enabled` | Avocats et juges activés | bool | `true` |
| Drogues & labos | Justice | `ib_just_lawyer` | Réduction par plaidoirie (%) | number | `25` |
| Drogues & labos | Équipes de braquage | `ib_crew_enabled` | Équipes activées | bool | `true` |
| Drogues & labos | Équipes de braquage | `ib_crew_max` | Taille maximale d'une équipe | number | `4` |
| Drogues & labos | Informateurs | `ib_inf_enabled` | Informateurs activés | bool | `true` |
| Drogues & labos | Informateurs | `ib_inf_bm` | Prix du tuyau « marché noir » ($) | number | `2500` |
| Drogues & labos | Informateurs | `ib_inf_ct` | Prix du tuyau « livraison » pour la police ($) | number | `1500` |
| Drogues & labos | Planques | `ib_stash_enabled` | Planques activées | bool | `true` |
| Drogues & labos | Planques | `ib_stash_max` | Planques par joueur | number | `2` |
| Drogues & labos | Planques | `ib_stash_chance` | Chance de la police de la trouver (%) | number | `35` |
| Drogues & labos | Planques | `ib_stash_expire` | Durée de vie d'une planque (jours, 0 = illimité) | number | `14` |
| Discord | Alertes Discord | `discord_alerts` | Alertes Discord activées | bool | `false` |
| Discord | Alertes Discord | `discord_webhook` | Adresse du webhook Discord | text | `` |
| Discord | Alertes Discord | `discord_cat_gangs` | Gangs : guerres, territoires, tributs, raids de QG, saisons | bool | `true` |
| Discord | Alertes Discord | `discord_cat_police` | Police : saisies | bool | `true` |
| Discord | Alertes Discord | `discord_cat_labs` | Laboratoires : accidents graves (incendie, explosion) | bool | `true` |
| Discord | Résumé quotidien | `discord_digest` | Résumé quotidien de l'activité | bool | `false` |
| Discord | Résumé quotidien | `discord_digest_hour` | Heure du résumé (heure du serveur) | number | `20` |
| Serveur | Mode de jeu | `game_mode` | Mode de jeu du serveur | select | `difficile` |
| Drogues & labos | Tablettes | `ib_tablets_required` | Tablettes obligatoires (blanchiment, Go Fast, dealers) | bool | `true` |

## Photo de profil Discord (en-tête du menu contextuel)
Pour afficher la photo Discord du joueur ciblé : crée un bot sur https://discord.com/developers, invite-le sur ton Discord, puis colle son token dans `resources/[script]/pickax_core/players/contextMenu/discord_token.lua` (fichier serveur uniquement) ou dans server.cfg : `set pickax_discord_bot_token "..."`. Sans token, l'en-tête affiche l'initiale du joueur. Ne mets jamais ce token dans un `config.lua` : ils sont envoyés aux joueurs.

## Atelier d'armes (illégal builder)
`/illegalbuilder` → Nouveau module → **Armes**. Le point « Établi d'armes » se place avec le mode placement. Deux usages à l'établi :
- **Fabriquer** : recettes réglables en jeu (onglet Recettes : matériaux, durée, animation, chance de raté, outil, produits : arme, munitions ou accessoire). Policiers requis et alerte police dans l'onglet Réglages.
- **Personnaliser** : le joueur choisit une arme de son inventaire, pose les accessoires qu'il possède (silencieux, lampe, viseur… compatibilité vérifiée avec l'arme), les retire (rendus dans l'inventaire) et change la teinte. Prix de pose et de teinte réglables (0 = gratuit).
Les accessoires sont les items « component » d'ox_inventory (`at_suppressor_light`, `at_flashlight`…) : pour qu'un joueur en obtienne, mets-les dans une recette ou une boutique. Nécessite ox_inventory pour la personnalisation.

## Police scientifique : douilles et balistique (`pickax_forensics`)
Réglages dans `resources/[dev]/pickax_forensics/config.lua` : métiers police, durée de vie des douilles, armes sans douille, calibres, positions du laboratoire (`/laboici` en admin donne les coordonnées à copier).
- **Tir** : chaque tir laisse une douille au sol (le serveur lit l'arme équipée, son n° de série et son propriétaire enregistré ; rafales limitées). Seule la police voit les repères.
- **Ramassage** : E sur la douille → item `evidence_casing` (scellé). `Config.Casings.BagItem = 'evidence_bag'` exige un sachet.
- **Analyse** : au laboratoire (E) → rapport : arme, calibre, signature balistique, n° de série, propriétaire enregistré, correspondances avec d'autres douilles déjà analysées (même arme).
- **Fichier** : onglet **Balistique** de la tablette de police (F6 → Tablette ; case « Fichier balistique » dans les réglages du job pour l’activer/désactiver) ou `/balistique` (dernières analyses) ou `/balistique <n° de série | BAL-xxxxxx>`.
Un propriétaire « enregistré » est celui noté par ox_inventory à la création de l'arme ; une arme sans n° de série (limée) reste non traçable.

## Décor des propriétés par l'agent immobilier (`pickax_jobbuilder`)
Dans une propriété **disponible** gérée par son agence, l'agent (touche F10 ou `/decorer`) peut poser meubles et **tableaux** (onglet Catalogue → « Tableaux & déco murale » : le tableau se colle au mur visé), et choisir le **style** de l'intérieur (onglet Style). Réglages : `Config.Real.Decor` (limite de l'agent, biens occupés ou non, propriétaire autorisé à changer le style, teintes).
**Couleur des murs / styles** : GTA ne repeint que les intérieurs qui exposent des « entity sets ». Ajoute-les dans `Config.Real.Interiors.<intérieur>.styles` ou, pour un MLO/shell, dans `Config.Real.Decor.CustomStyles` :
`{ id = 'moderne', label = 'Moderne', sets = { 'nom_entity_set' }, tintSets = { 'set_teintable' } }` (`tintSets` = sets qui prennent la couleur choisie). Les noms de sets se trouvent dans la documentation de l'intérieur (MLO) ou les listes d'IPL GTA. Les modèles de tableaux absents de ton serveur ne sont pas proposés.

### Police scientifique v2 : sang/ADN, empreintes, GSR, nettoyage (`pickax_forensics`)
Tout se règle dans `pickax_forensics/config.lua` (sections Blood, Prints, Gsr, Cleaning, Lab, Profile ; **change `Config.Salt`**).
- **Sang / ADN** : un joueur blessé laisse des traces (rouge sur la scène, visibles de la police). E → prélèvement scellé `evidence_blood`.
- **Empreintes** : monter dans un véhicule sans l'item `latex_gloves` laisse une empreinte. À côté du véhicule, E → **mini-jeu de poudrage** (il faut brosser uniquement l'empreinte) → scellé `evidence_print`.
- **Laboratoire** (E au labo, ou `/balistique` pour le fichier) : interface dédiée ; analyse = mini-jeu (**séquençage ADN** pour le sang, **comparaison d'empreintes** pour les empreintes, automatique pour les douilles). Un échec laisse 2 nouvelles chances, puis l'échantillon est dégradé.
- **Identifier quelqu'un** : seulement s'il a été prélevé avant → `/prelever [id]` (ADN + empreintes, sur un suspect proche). Sinon la trace reste « individu inconnu ».
- **Résidus de tir** : `/gsr [id]` → positif si la personne a tiré depuis moins de 30 min et ne s'est pas nettoyée (`gsr_wipes`).
- **Effacer ses traces** : `cleaning_kit` (mini-jeu de frottage ; efface sang, douilles et empreintes proches), `gsr_wipes` (mains), `latex_gloves` (aucune empreinte).
Items à ajouter dans les boutiques (ox_inventory/data/items.lua les définit) : `latex_gloves`, `cleaning_kit`, `gsr_wipes`, `evidence_bag`.

## Création de personnage : scène, caméra et lieux d'arrivée (`pickax_creator/config.lua`)
- `Config.Scene.Studio` : **où s'ouvrent les premiers menus** (identité puis apparence) — `vector4(x, y, z, cap)`. `LoadRadius`, `FadeOut`, `FadeIn`, `HideRadar` règlent le chargement et les fondus.
- `Config.Scene.Camera` : `Distance`, `Height`, `Rise`, `Fov`, `Angle` (0 face, 90 côté, 180 dos), `Side`, limites de zoom et vitesses de rotation / zoom.
- `Config.Destinations` : **les lieux d'arrivée proposés après la création** (un seul = arrivée directe). `esx_identity` les lit depuis ce fichier.
- Le tout premier point d'apparition technique du nouveau personnage (avant la scène) est `Config.DefaultSpawns` dans `es_extended/config.lua` ; il n'est visible qu'une fraction de seconde car la scène de création téléporte aussitôt au Studio.

## Mécanicien réaliste (`pickax_mechanic`)
Réglages dans `resources/[dev]/pickax_mechanic/config.lua` (qui est mécanicien : `Jobs` / `JobTypes`, outil, atelier obligatoire ou non, magasins, pièces, usure, effets, réparations).
- **Magasin de pièces** (`Config.Shops`, E sur le repère) : les mécaniciens y achètent leurs pièces. **Le stock est limité, partagé par tous les mécaniciens et se reconstitue lentement** (`every` / `amount` par pièce) : sans pièces, aucune réparation. Placer les magasins avec leurs coordonnées dans `Config.Shops`.
- **Diagnostic** : `/meca` (ou l'action « Réparer le véhicule » du Job Builder) près d'un véhicule : état de 7 composants (moteur, huile, boîte, freins, pneus, suspension, carrosserie) enregistré par plaque.
- **Usure** : rapportée par le conducteur et plausibilisée par le serveur (distance, vitesse élevée, freinages brusques, chocs). Un mauvais état a des effets : puissance réduite, calages, freins faibles, adhérence en baisse, pneus qui éclatent.
- **Réparation** : consomme les pièces de `Config.Repairs` + un mini-jeu (boulons, timing, gonflage, débosselage). Score trop bas = réparation ratée et pièces perdues ; abandonner ne coûte rien.
Items à ajouter (ox_inventory/data/items.lua les définit) : engine_block, spark_plugs, engine_oil, oil_filter, gearbox_kit, brake_pads, brake_fluid, tyre_set, suspension_kit, body_panel, welding_wire, toolbox.

## Pack gameplay : mini-jeux, EMS, illégal, métiers, justice
Toutes ces ressources sont dans `resources/[dev]` (démarrées avec `ensure [dev]`) et se règlent dans **leur** `config.lua`. Les items sont définis dans `ox_inventory/data/items.lua` (à ajouter aux boutiques / recettes).
- **`pickax_skillgames`** : bibliothèque de mini-jeux (crochetage, codes, câbles, RCR, suture, bandage, timing, jauge, faux papiers). Test en jeu : `/skillgame <pins|code|wires|cpr|suture|wrap|timing|hold|align>` (admin). Appel : `exports.pickax_skillgames:Play('pins', { difficulty = 3 })` → score 0-100.
- **`pickax_medical`** (EMS) : blessures par zone (tête, torse, bras, jambes) avec saignement, effets (boiterie, tremblement, vision trouble, malaise), `/ems [id]` examen (corps cliquable), soins **bandage / suture / attelle / chirurgie (hôpital)** avec mini-jeux, **radio** pour les lésions cachées, **prise de sang** (groupe sanguin, alcoolémie), **RCR** (mini-jeu au rythme) qui réanime via le Job Builder, **poches de sang et transfusion** (compatibilité ABO/Rh, réaction sinon), **triage** (`/triage`, étiquettes rouge/orange/vert/noir, score de précision). Groupe sanguin visible dans les analyses ADN de `pickax_forensics`. Change `Config.Blood.Salt`.
- **`pickax_crime`** : `/crocheter` (véhicules, difficulté selon la classe), **piratage** de terminaux (`Config.Hack.Terminals`), **faux papiers** (atelier, qualité = score), **désossage** `/desosser` (pièces à revendre au receleur, prix variables par jour). Alertes via le dispatch de la tablette police. Le blanchiment reste celui de `pickax_illegalbuilder`.
- **`pickax_life`** : permis (pêche / chasse), **pêche** `/pecher`, **chasse** `/depecer`, **cuisine** (postes + recettes, qualité), acheteurs aux prix du jour, **taxi / livraison** `/course` (tarif au km + pourboire selon la conduite).
- **`pickax_justice`** : **mandats** (`/mandat` juge, `/mandats`), **saisies** `/saisie` (journal, « contestable » sans mandat de perquisition, `/saisies`), **alcootest** `/alcootest` (alcoolémie suivie via `ox_inventory:usedItem`), **contrôle des papiers** `/papiers` (le contrôlé choisit vrai/faux ; un faux est détecté selon sa qualité).
Exports utiles : `pickax_justice:HasSearchWarrant(nom)`, `pickax_justice:LogSeizure(agent, cible, note)` (à appeler depuis les saisies de `pickax_illegalbuilder` si tu veux les journaliser).

### Où trouver chaque action (plus de commandes à retenir)
Les commandes sont **désactivées par défaut** (`Config.UseCommands = false` dans chaque ressource ; `true` pour les réactiver).
- **Menu contextuel (clic droit sur la cible)** — personne : *Contrôler les papiers, Alcootest, Enregistrer une saisie, Prélèvement ADN, Test de résidus* (police) · *Examiner le patient* (EMS). Véhicule : *Diagnostic du véhicule* (mécanicien) · *Crocheter la serrure* (avec un crochet) · *Désosser le véhicule* (dans la zone, avec les outils). Animal mort : *Dépecer l'animal*.
- **Menu F6 du job** — EMS : *Examiner un patient, Triage* · Police / gouvernement : *Mandats, Journal des saisies* · Gouvernement : *Délivrer un mandat* · Taxi / transporteur : *Service de courses* · Mécano : *Réparer le véhicule* (diagnostic) · Police : tablette → onglet *Balistique*.
- **Objets** — canne à pêche (pêcher), couteau de chasse (dépecer), crochet, kit de nettoyage, lingettes.
### Cuisine (pickax_life) et items en base

- **Cuisine** (`Config.Cooking` dans `pickax_life/config.lua`) : marché aux ingrédients (`Market`), postes par type (`Stations` : plan de travail, cuisinière, grill, four, poste complet), **12 recettes en plusieurs étapes** (découpe, cuisson, finition avec mini-jeux), **niveau de cuisinier** (`Levels`, `XP`, recettes débloquées par niveau, bonus de qualité par niveau), qualité du plat en métadonnée, plat brûlé si la cuisson est ratée, **commandes de clients** (`Orders` : livrer un plat de qualité minimale contre paiement + bonus). L'XP est enregistrée dans la table `pickax_cooking` (créée automatiquement).
- **Items en base** : au démarrage, `pickax_core` (`players/itemsync/server.lua`) crée dans la table `items` tout item défini dans `ox_inventory/data/items.lua` qui manque (sans toucher aux lignes existantes ; `Config.ItemSync = false` dans `config_sv.lua` pour désactiver). Le fichier `sql_items.sql` fait la même chose à la main.

- **Repères au sol (E)** — magasin de pièces, laboratoire, terminaux, atelier de faux papiers, receleur, acheteurs, postes de cuisine, bureau des permis.
Une ressource ajoute ses propres entrées au menu contextuel avec `exports.pickax_core:RegisterContextActions(GetCurrentResourceName(), { { id, label, target = 'player' | 'vehicle' | 'ped' | 'self' } })` et répond avec les exports `ContextCan(id, entité)` / `ContextDo(id, entité)`.

### Aucune interface ox_lib
Toutes les interfaces (menus, formulaires, confirmations, barres de progression, notifications, aide à l'écran) passent par celles du serveur : `pickax_skillgames` fournit les menus / formulaires / confirmations / progression (`ui.lua` remplace les appels `lib.notify`, `lib.progressBar`, `lib.registerContext` + `lib.showContext`, `lib.inputDialog`, `lib.alertDialog`) et `pickax_notify` les notifications. Les mini-jeux des builders utilisent `pickax_skillgames` au lieu du `skillCheck` d'ox_lib et `p_bridge` affiche son aide avec le texte d'aide du serveur (`Config.TextUI = 'pickax'`). ox_lib reste chargé uniquement comme bibliothèque technique (callbacks serveur d'`pickax_auction`, `pickax_bourse`, `pickax_basetools`, `ox_inventory`).
Pour une nouvelle ressource : copie `pickax_skillgames/ui.lua` dans son dossier et mets `shared_scripts { 'ui.lua', 'config.lua' }` pour garder la syntaxe `lib.*` sans ox_lib.

### Aucun point créé automatiquement

Les ressources `pickax_crime`, `pickax_life`, `pickax_forensics`, `pickax_medical`, `pickax_mechanic` n'ont plus aucune coordonnée par défaut : terminaux de piratage, ateliers, receleur, bureau des permis, postes de cuisine, marché, labo, hôpitaux, magasin de pièces, zones de pêche / chasse et points de course sont à renseigner dans leur `config.lua`. Le World Builder (`Preset.Auto`, `Preset.Casino.Auto`) et l'Illegal Builder (`Config.Seed.Auto`) ne créent plus rien au démarrage : `/wbseed` et `/ibseed` (admin) créent les points d'exemple à la demande.
