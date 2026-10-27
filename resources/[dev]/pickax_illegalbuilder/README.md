# pickax_illegalbuilder — Builder Illégal

Un seul builder pour toutes les activités illégales du serveur (`/illegalbuilder`, ou via `/builders`).

| Module | Contenu |
|---|---|
| **Drogues** | récolte / plantations, dealer, blanchiment (tablette). Le traitement et l'intoxication se font dans les **laboratoires** (propriétés, Job Builder) |
| **Braquages** | supérettes, banques, bijouteries : cibles, gardes, alertes police |
| **Go Fast** | contact, sortie du véhicule, points de livraison tirés au sort, stock, délais, bonus selon l'état du véhicule, alerte police |

Le **Gang Builder** (`pickax_gangbuilder`) reste un builder à part.

## Installation
- `ensure pickax_illegalbuilder` (après `es_extended`, `oxmysql`).
- Les tables `illegalbuilder_*` sont créées au premier démarrage (`sql/install.sql`).
- Les drogues et braquages déjà créés dans l'ancien World Builder sont **repris automatiquement** (une seule fois) puis retirés de l'ancien builder.
- Le Go Fast qui était un simple fichier de config dans `pickax_core` est remplacé par le module « Go Fast » : crée-en un depuis le builder (modèle « Go Fast classique »).

## Droits
Groupes ESX `_dev`, `admin`, `superadmin` (`Config.AllowedGroups`) ou permission ACE `illegalbuilder.admin`.

## Laboratoires : tenue et intoxication
- La **tenue obligatoire** se règle sur le **poste de travail** (point « Laboratoire / traitement ») : rayon du laboratoire + tenue homme / femme. Les points de récolte « dans la nature » n'exigent aucune tenue.
- Sans la tenue dans le rayon d'un laboratoire, le joueur **s'intoxique** (niveau 0-100, affiché à l'écran). Symptômes : vision trouble, toux, chutes, perte de vie ; à 100 il **meurt**.
- **Un seul remède** : l'item `antidote` (`Config.Toxic.CureItem`). Rien d'autre ne guérit (ni kit de soin, ni réanimation). La mort remet le niveau à 0.
- Réglages : `Config.Toxic` (vitesse, dégâts, seuils d'alerte).

## Tablette vendeur (dealer à PNJ)
- Un point **Dealer** (vente de drogue à un PNJ) peut exiger une **tablette vendeur** : dans l'éditeur du point → carte *Tablette vendeur* → « Tablette obligatoire » (item par défaut `dealer_tablet`, modifiable).
- Sans la tablette, le joueur **ne voit pas** le dealer (PNJ absent, pas de blip) et le serveur refuse la vente (« Il te faut la tablette vendeur »). Quand il l'achète, le dealer apparaît sur sa carte (GPS posé).
- La tablette est en vente chez le marchand des tablettes (Shop Builder, catégorie *Accès*, 30 000 $), avec les tablettes Go Fast et blanchiment. Le PNJ (modèle, animation, position) se règle sur le point comme pour les autres points.
- Les nouveaux dealers créés depuis le builder ont la tablette activée par défaut ; les dealers déjà créés restent visibles par tous tant que tu n'actives pas l'option.
- Items : `dealer_tablet` est déclaré dans `ox_inventory/data/items.lua`.
