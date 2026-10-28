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

## Activer / désactiver la vente de drogue aux PNJ
- **Interrupteur général** : builder illégal → *Paramètres* → **Vente de drogue aux PNJ** (case « Activée », enregistrée en base, sans redémarrage). Désactivé : tous les dealers à PNJ disparaissent (PNJ et blips retirés chez tous les joueurs) et le serveur refuse toute vente. Valeur par défaut au premier démarrage : `Config.PedSales.Enabled`.
- **Par dealer** : dans l'éditeur du point, case **Vente active (ce dealer)** (activée par défaut) ; la vente peut ainsi être coupée sur un seul dealer.
- Cumulable avec la tablette vendeur (section précédente).

## Vente dans la rue (menu contextuel)
Le joueur clique sur un **PNJ de la rue** avec le menu contextuel (pickax_core) → **Vendre de la drogue** → choisit l'article (seuls ceux qu'il possède sont proposés).
- Tout est décidé **côté serveur** (`server/street.lua`) : interrupteur général (`Config.PedSales`) et `Config.StreetSales.Enabled`, tablette vendeur (`RequireTablet`, item `dealer_tablet`), policiers requis, délai entre deux ventes, limite par heure, **acceptation du PNJ** (`AcceptChance`), quantité (`QtyMin`–`QtyMax`), prix (prix du dealer du catalogue × `PriceFactor`, ou liste `Items` à toi), paiement (`Account`, par défaut argent sale).
- Le PNJ peut refuser (alerte police possible : `RefuseAlertChance`) ; une vente réussie peut alerter la police (`AlertChance`), paie le racket au propriétaire du territoire, compte pour les affrontements de gang et le carnet.
- Un même PNJ n'est sollicité qu'une fois. Impossible en véhicule.
- Tous ces réglages sont modifiables depuis le panel web : *Réglages du serveur → Drogues & labos → Vente dans la rue*.
- **pickax_core** : `players/contextMenu/function.lua` utilise ce système à la place de l'ancienne vente (qui faisait confiance au client) dès que `pickax_illegalbuilder` est démarré ; sans lui, l'ancien comportement reste.
- Tests : `ROOT=. lua tools/tests/street_test.lua`.

## Pureté → prix de vente (`Config.Purity`)
Le produit fabriqué dans un laboratoire interactif porte une **pureté** (métadonnée du pochon, 0-100 %). Chez les dealers du builder et dans la rue, le prix tiré est multiplié par un facteur : `MinFactor` (×0,6) à 0 %, `MaxFactor` (×1,4) à 100 %, ×1 à 50 %. Un produit sans pureté (récolte, ancien stock) compte pour `Default` %.
Le joueur vend d'abord ses unités **les plus pures** ; le message de vente affiche la pureté moyenne. Réglable dans le panel : *Réglages du serveur → Drogues & labos → Pureté du produit*. Test : `ROOT=. lua tools/tests/purity_test.lua`.

## Réputation de dealer et quartiers (vente de rue)
- **Réputation** (`Config.StreetRep`, table `illegalbuilder_dealer_rep`) : chaque unité vendue dans la rue rapporte 1 point. 5 paliers (Petit revendeur → Baron : 0 / 40 / 120 / 300 / 700). Chaque niveau au-dessus du 1 : **+4 % d'acceptation** des PNJ et **+4 % de prix**. Commande joueur : **`/dealer`** (niveau, réputation, état du secteur). Export : `exports.pickax_illegalbuilder:GetDealerRep(src)`.
- **Quartiers** (`Config.StreetZones`) : la ville est découpée en secteurs de 300 m (ou en zones nommées `Named`, avec une `demand` qui multiplie le prix). Chaque vente **sature** le secteur (jusqu'à −40 % de prix) et le **chauffe** (plus d'alertes police, moins d'acceptation) ; saturation et chaleur retombent avec le temps (−3 et −2 par minute) : il faut **changer de quartier**.
- Tout est réglable dans le panel : *Réglages du serveur → Drogues & labos → Réputation de dealer / Quartiers*. Test : `ROOT=. lua tools/tests/street_test.lua` (26 vérifications).

## Perquisitions et saisies (police)
- Un **policier** (`Config.PoliceJobs`) clique sur un joueur avec le menu contextuel → **Perquisition (drogue)** : *Inspecter le suspect* (affiche ce qu'il porte d'illégal : drogues du catalogue — récolte, pochons, graines —, objets de `Config.Seizure.Items`, argent sale) ou *Saisir drogue et argent sale*.
- Contrôlé côté serveur : métier de police, distance (3 m), délai entre deux saisies. Les objets saisis, **avec leur pureté**, vont dans le **casier de preuves** (`/preuves`, police) ; l'argent sale est retiré et reversé à la **société de police** (`Society`, `SocietyShare`). Le suspect est prévenu.
- Chaque saisie est enregistrée (table `illegalbuilder_seizures` et journal du builder) ; `/saisies` affiche les dernières.
- Réglable dans le panel : *Réglages du serveur → Drogues & labos → Perquisitions et saisies (police)*. Tests : `ROOT=. lua tools/tests/seizure_test.lua` (14 vérifications).
- **pickax_core** : `players/contextMenu/function.lua` ajoute l'entrée « Perquisition (drogue) » au menu d'un joueur (visible seulement pour la police).
