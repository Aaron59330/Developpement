# Aero — téléphone pickax_phone

Smartphone complet pour ESX (interface type smartphone moderne, marque « Aero »). 100 % français, sans dépendance payante.

## Config prête (préréglage ESX)
`config.lua` est déjà réglé pour ta base : ESX + ox_inventory + pma-voice + pickax_core + Job Builder.
- Groupes admin `_dev / superadmin / admin`, notifications via `pickax_notify`, faim / soif via l'`esx_status` de pickax_core.
- Comptes `bank` / `money`, société : Job Builder puis `esx_addonaccount` de pickax_core.
- Véhicules : colonne `state` d'`owned_vehicles` (1 garage, 0 sorti, 2 fourrière).
- Métiers joignables : ceux du Job Builder ; liste de secours avec tes jobs `lspd`, `ambulance`, `pillboxhopital`, `bennys`, `LsCustoms`, `pdm`, `banque`.
- Couleur par défaut = couleur du serveur (`pickax_core/config.lua` → `AccentColor`), adresses mail en `@aero.mail`.
- Objets : `phone` et `powerbank` existent déjà dans ton `ox_inventory`.
- **Reste à renseigner** : `Config.Camera.webhook` (webhook Discord pour les photos) et installer `screenshot-basic`.

## Compatibilité : ESX · QBCore · Qbox · standalone
Le téléphone détecte tout seul ce qui tourne sur ton serveur (`config.lua`, section « COMPATIBILITÉ »). Il n'appelle jamais ESX ou QBCore directement : tout passe par `bridge/server.lua` et `bridge/client.lua`.

| Élément | Pris en charge | Réglage |
|---|---|---|
| Framework | ESX (legacy), QBCore, Qbox, standalone (sans framework : pas de métiers ni d'argent) | `Config.Framework` |
| Inventaire | ox_inventory, qb-inventory / ps / lj, qs-inventory, inventaire ESX natif, aucun | `Config.Inventory` |
| Voix des appels | pma-voice, mumble-voip, saltychat, ou fonctions perso (`custom`) | `Config.Voice` |
| Notifications | ox_lib, ESX, QBCore, Qbox, natives, ou fonction perso | `Config.Notify` |
| Comptes société | Job Builder, esx_addonaccount, qb-banking, qb-management, Renewed-Banking, okokBanking, ou fonctions perso | `Config.Society` |
| Faim / soif | esx_status, métadonnées QBCore, ou fonction perso | `Config.Status` |
| Véhicules possédés | `owned_vehicles` (ESX), `player_vehicles` (QBCore / Qbox), ou tes propres tables | `Config.Database.vehicles` |
| Métiers joignables | Job Builder, métiers du framework, ou liste fixe | `Config.JobLines.source` |

**Objet téléphone** : crée l'objet `phone` dans ton inventaire (ox_inventory : `data/items.lua`, qb-core : `shared/items.lua`, ESX : table `items`). Le nom se change dans `Config.Item`. Pour essayer sans objet : `Config.RequireItem = false`.

**Qbox / QBCore** : les métiers (`jobs`), grades et le compte `bank` / `cash` sont lus automatiquement. Si ton serveur utilise d'autres noms de comptes, règle `Config.Accounts`.

**Autre voix, autre inventaire, autre banque** : renseigne les fonctions de `Config.Hooks` (voiceStart, societyAdd, hasItem…).

## Installation
1. Dépendances : `oxmysql` et `ox_lib` (obligatoires). Selon ton serveur : un framework (ESX / QBCore / Qbox), un inventaire et une ressource vocale (pma-voice…) : détectés automatiquement.
2. Les tables `aura_*` sont créées automatiquement au premier démarrage (aucun SQL à importer).
3. `ensure pickax_phone` **après** ton framework, ton inventaire et ta voix (déjà le cas avec `ensure [dev]` ici). **Ne pas lancer lb-phone en même temps.**
4. Photos / Appareil photo : installer `screenshot-basic` et renseigner `Config.Camera` (webhook Discord ou FiveManage).
5. Réglages : `config.lua` (numéros, applications, banque, crypto, services, batterie, radios…).

## Utilisation
- Touche **F1** (modifiable dans les paramètres FiveM), commande `/phone` ou utilisation de l'objet `phone`.
- **Échap** : retour / accueil / fermer. Flèche haut / bas : décrocher / raccrocher quand le téléphone est rangé.
- Appui long (clic droit) sur une conversation, un message ou une icône de l'accueil pour les options.

## Applications
Téléphone (clavier, récents, favoris, numéro masqué `*31#`, appels vocaux) · Messages (privé, groupes, photos, position, contact, réactions, réponses, lu/distribué, écriture en cours) · Contacts · Appareil photo (arrière / selfie, zoom) · Photos · Aero Bank (virements, factures, historique) · Crypto · Wallet · Plans (GPS, lieux) · Localiser · Garage · Mail · Notes · Calendrier (rappels) · Horloge (réveils, chrono, minuteur) · Calculette · Météo · Services (police, SAMU, dépanneur, taxi…) · Musique · AirShare · App Store · Réglages · Pulse (micro-blog) · Snapgram (photos & stories) · Match (rencontres) · Annonces (petites annonces).

Système : écran verrouillé avec code, centre de contrôle, notifications, Ne pas déranger, mode avion, thèmes clair/sombre, couleur d'accentuation, fonds d'écran (galerie / lien), batterie (recharge en véhicule ou batterie externe), multitâche.

## Nouveautés : Shadow (darkchat) et apps en plus
- **Shadow** (darkchat) : pseudo anonyme aléatoire (modifiable), salons publics ou privés (code + mot de passe), messages et images, effacement automatique selon la durée du salon, salons publics créés au démarrage (`Config.Darkchat.publicRooms`). Accès en option avec un objet (`Config.Darkchat.item`, ex. `'usb_key'`). Modération : `/phone_dclog <salon> [n]` (affiche pseudo + identifiant réel, admin/console) et `/phone_dcclose <salon>`.
- **Entreprise** (jobs du Job Builder) : facturer un client proche (la facture arrive dans sa Banque et l'argent va au compte société du job), recruter, changer le grade, licencier (direction), solde de la société.
- **Clés** : verrouiller / déverrouiller, démarrer le moteur, klaxon, phares, coffre sur ses véhicules possédés (150 m).
- **Rappels**, **Boussole** (cap, rue), **Santé** (vie, armure, faim, soif), **Jeux** (Snake avec record, morpion).

## Encore plus d'apps
- **Jeux** : Snake, 2048, Démineur, Puissance 4 (contre l'ordinateur), Flappy, Mémoire, Morpion, dés / pile ou face, avec **classements du serveur** (top 10 par jeu).
- **Taxi** : choisir une destination (point GPS ou lieu), voir distance et prix estimé, commander une course aux chauffeurs d'un job de type taxi du Job Builder (`Config.Taxi` pour le tarif).
- **Actualités** : articles du serveur, photo, « information urgente » qui notifie tout le monde. Publient : les jobs de `Config.News.jobs` (ex. `weazel`) et les admins.
- **Loto** : tickets (choix des numéros ou ticket flash), tirage régulier, cagnotte qui grossit, gains crédités sur le compte bancaire (`Config.Loto`). Commande admin : `/phone_lotodraw`.
- **Convertisseur** : longueur, poids, volume, vitesse, température, durée.

## Appeler les jobs du Job Builder
- Tous les jobs créés dans le **Job Builder** sont des lignes joignables dans l'application **Services** (lus en direct : un job créé ou modifié apparaît **tout de suite**, sans redémarrage).
- Réglages par job : Job Builder → job → carte **« Téléphone des joueurs (Aero) »** : joignable ou non, numéro d'appel court (ex. 17, 555123), nom affiché, mode (appel + alerte / appel seul / alerte seule), grade minimum pour recevoir, alerte anonyme, aide affichée.
- **Appel vocal** : sonne chez tous les employés en ligne (grade suffisant) ; le premier qui décroche prend l'appel (pma-voice), les autres arrêtent de sonner. Appel manqué si personne ne répond.
- **Alerte** : message + position envoyés aux employés ; la **tablette police** reçoit un appel citoyen, les **EMS** un appel d'urgence, les autres jobs une notification téléphone avec bouton GPS.
- Numéros par défaut : 17 au premier job de type police, 15 au premier job de type EMS (modifiable dans le job). Un numéro court se compose aussi au clavier.
- Si `pickax_jobbuilder` n'est pas démarré, la liste fixe `Config.Services` sert de secours (`Config.JobLines`).

## Exports serveur
```lua
exports.pickax_phone:GetPhoneNumber(source)
exports.pickax_phone:GetPhoneNumberByIdentifier(identifier)
exports.pickax_phone:GetSourceByNumber(number)
exports.pickax_phone:Notify(source, titre, texte, app)
exports.pickax_phone:SendMail(identifier, expediteur, objet, texte)
exports.pickax_phone:SendMessage(numeroExpediteur, numeroDestinataire, texte)
exports.pickax_phone:CreateBill(identifier, emetteur, montant, motif, societe)   -- facture payable dans Aero Bank
exports.pickax_phone:Dispatch('job:lspd', message, vector3, label)               -- alerte aux employés d'un job (ou id d'un service fixe)
exports.pickax_phone:AddPhoto(identifier, url)
exports.pickax_phone:SetBattery(source, 0-100)
exports.pickax_phone:HasPhone(source)
```
Exports client : `Open`, `Close`, `IsOpen`, `HasPhone`.

## Commandes admin
`/phone_number [id]` · `/phone_give [id]` · `/phone_reset [id]` · `/phone_verify <app> <pseudo> [0]` · `/phone_dclog <salon> [n]` · `/phone_dcclose <salon>`
