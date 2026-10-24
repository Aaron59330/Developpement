# pickax_illegalbuilder — Builder Illégal

Un seul builder pour toutes les activités illégales du serveur (`/illegalbuilder`, ou via `/builders`).

| Module | Contenu |
|---|---|
| **Drogues & labos** | récolte, laboratoires (recettes), dealer, blanchiment, portes de labo |
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
