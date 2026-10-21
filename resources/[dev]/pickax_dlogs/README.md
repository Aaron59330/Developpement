# pickax_dlogs — logs Discord par métier / gang / boutique / événement

Chaque élément créé dans un builder peut envoyer ses logs dans **son propre salon Discord**, avec les informations que tu choisis.

## Installation
```
ensure pickax_dlogs        # avant les builders (ou n'importe quand : ils détectent la ressource)
```
La table `pickax_dlogs` se crée seule.

## Utilisation (en jeu)
Ouvre un **métier**, un **gang**, une **boutique** ou un **événement** dans son builder → onglet **« Logs Discord »** (pour l'événement : carte en bas de la page d'édition) :
1. Colle le lien d'un webhook Discord (Paramètres du salon → Intégrations → Webhooks).
2. Choisis le nom du bot, la couleur, une mention éventuelle (`@here` / `@everyone`).
3. Coche les **informations** envoyées : joueur, identifiant, détail, montant, nom de l'élément, date.
4. Coche les **événements** envoyés (recrutement, retrait coffre, vente, capture de territoire…), par groupe, avec « Tout cocher ».
5. **Enregistrer**, puis **Envoyer un message de test**.

Un élément doit être enregistré avant d'avoir ses logs (le lien est lié à son identifiant). Supprimer l'élément supprime sa configuration.

## Ajouter un événement à la liste
Dans `catalog.lua`, ajoute une ligne `{ 'cle', 'Libellé' }` dans le bon groupe. `cle` = l'action enregistrée par le builder (`JB.log(..., 'cle', ...)`). Une clé finissant par `*` couvre toute une famille (`bank_*`). Rien d'autre à modifier.

## Sécurité
- Seuls les liens `https://discord.com/api/webhooks/…` sont acceptés.
- Le lien n'est **jamais renvoyé** à l'interface après enregistrement (affiché masqué).
- Les messages passent par une file d'attente (1 message / 0,7 s par webhook, 60 max en attente, gestion du « retry-after » de Discord) : un afflux de logs ne bloque pas le serveur.
- Les logs internes (clés commençant par `_`) ne sont jamais envoyés.

## Depuis un autre script
```lua
exports.pickax_dlogs:Send('shop', shopId, 'Ma boutique', 'buy', { name = 'Jean', identifier = 'license:…' }, 'détail', montant)
```
`kind` : `job`, `gang`, `shop`, `event`.

## Remarque
`pickax_worldbuilder`, `pickax_minigames` et `pickax_boutique` gardent leur `Config.Webhook` global (non concernés).
