# Aura — téléphone pickax_phone

Smartphone complet pour ESX (interface type smartphone moderne, marque « Aura »). 100 % français, sans dépendance payante.

## Installation
1. Dépendances : `es_extended`, `oxmysql`, `ox_lib`, `ox_inventory` (objet `phone`), `pma-voice` (appels vocaux).
2. Les tables `aura_*` sont créées automatiquement au premier démarrage (aucun SQL à importer).
3. `ensure pickax_phone` (déjà couvert par `ensure [dev]`). **Ne pas lancer lb-phone en même temps.**
4. Photos / Appareil photo : installer `screenshot-basic` et renseigner `Config.Camera` (webhook Discord ou FiveManage).
5. Réglages : `config.lua` (numéros, applications, banque, crypto, services, batterie, radios…).

## Utilisation
- Touche **F1** (modifiable dans les paramètres FiveM), commande `/phone` ou utilisation de l'objet `phone`.
- **Échap** : retour / accueil / fermer. Flèche haut / bas : décrocher / raccrocher quand le téléphone est rangé.
- Appui long (clic droit) sur une conversation, un message ou une icône de l'accueil pour les options.

## Applications
Téléphone (clavier, récents, favoris, numéro masqué `*31#`, appels vocaux) · Messages (privé, groupes, photos, position, contact, réactions, réponses, lu/distribué, écriture en cours) · Contacts · Appareil photo (arrière / selfie, zoom) · Photos · Aura Bank (virements, factures, historique) · Crypto · Wallet · Plans (GPS, lieux) · Localiser · Garage · Mail · Notes · Calendrier (rappels) · Horloge (réveils, chrono, minuteur) · Calculette · Météo · Services (police, SAMU, dépanneur, taxi…) · Musique · AirShare · App Store · Réglages · Pulse (micro-blog) · Snapgram (photos & stories) · Match (rencontres) · Annonces (petites annonces).

Système : écran verrouillé avec code, centre de contrôle, notifications, Ne pas déranger, mode avion, thèmes clair/sombre, couleur d'accentuation, fonds d'écran (galerie / lien), batterie (recharge en véhicule ou batterie externe), multitâche.

## Nouveautés : Shadow (darkchat) et apps en plus
- **Shadow** (darkchat) : pseudo anonyme aléatoire (modifiable), salons publics ou privés (code + mot de passe), messages et images, effacement automatique selon la durée du salon, salons publics créés au démarrage (`Config.Darkchat.publicRooms`). Accès en option avec un objet (`Config.Darkchat.item`, ex. `'usb_key'`). Modération : `/phone_dclog <salon> [n]` (affiche pseudo + identifiant réel, admin/console) et `/phone_dcclose <salon>`.
- **Entreprise** (jobs du Job Builder) : facturer un client proche (la facture arrive dans sa Banque et l'argent va au compte société du job), recruter, changer le grade, licencier (direction), solde de la société.
- **Clés** : verrouiller / déverrouiller, démarrer le moteur, klaxon, phares, coffre sur ses véhicules possédés (150 m).
- **Rappels**, **Boussole** (cap, rue), **Santé** (vie, armure, faim, soif), **Jeux** (Snake avec record, morpion).

## Appeler les jobs du Job Builder
- Tous les jobs créés dans le **Job Builder** sont des lignes joignables dans l'application **Services** (lus en direct : un job créé ou modifié apparaît **tout de suite**, sans redémarrage).
- Réglages par job : Job Builder → job → carte **« Téléphone des joueurs (Aura) »** : joignable ou non, numéro d'appel court (ex. 17, 555123), nom affiché, mode (appel + alerte / appel seul / alerte seule), grade minimum pour recevoir, alerte anonyme, aide affichée.
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
exports.pickax_phone:CreateBill(identifier, emetteur, montant, motif, societe)   -- facture payable dans Aura Bank
exports.pickax_phone:Dispatch('job:lspd', message, vector3, label)               -- alerte aux employés d'un job (ou id d'un service fixe)
exports.pickax_phone:AddPhoto(identifier, url)
exports.pickax_phone:SetBattery(source, 0-100)
exports.pickax_phone:HasPhone(source)
```
Exports client : `Open`, `Close`, `IsOpen`, `HasPhone`.

## Commandes admin
`/phone_number [id]` · `/phone_give [id]` · `/phone_reset [id]` · `/phone_verify <app> <pseudo> [0]` · `/phone_dclog <salon> [n]` · `/phone_dcclose <salon>`
