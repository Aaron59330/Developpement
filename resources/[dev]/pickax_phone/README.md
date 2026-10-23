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

## Exports serveur
```lua
exports.pickax_phone:GetPhoneNumber(source)
exports.pickax_phone:GetPhoneNumberByIdentifier(identifier)
exports.pickax_phone:GetSourceByNumber(number)
exports.pickax_phone:Notify(source, titre, texte, app)
exports.pickax_phone:SendMail(identifier, expediteur, objet, texte)
exports.pickax_phone:SendMessage(numeroExpediteur, numeroDestinataire, texte)
exports.pickax_phone:CreateBill(identifier, emetteur, montant, motif, societe)   -- facture payable dans Aura Bank
exports.pickax_phone:Dispatch('police', message, vector3, label)                 -- alerte aux agents en service
exports.pickax_phone:AddPhoto(identifier, url)
exports.pickax_phone:SetBattery(source, 0-100)
exports.pickax_phone:HasPhone(source)
```
Exports client : `Open`, `Close`, `IsOpen`, `HasPhone`.

## Commandes admin
`/phone_number [id]` · `/phone_give [id]` · `/phone_reset [id]` · `/phone_verify <app> <pseudo> [0]`
