# Optimisation de la base

## Ce qui est automatique (`pickax_optimize`, démarre après oxmysql)
- **Index SQL** : au démarrage, crée les index manquants sur les colonnes les plus interrogées (véhicules, factures, journaux des builders, téléphone…). Aucune donnée modifiée ; ignoré si la table ou la colonne n'existe pas ou si un index existe déjà. Liste : `Config.Indexes`.
- **Purge des journaux** : supprime les journaux de plus de 60 à 90 jours (builders, mini-jeux, carplay…). Jamais touchés : historiques financiers (boutique, casino), sanctions, véhicules, comptes. Liste : `Config.Purge`.
- **Cache mémoire partagé** : `exports.pickax_optimize:Remember('cle', ttlSecondes, function() … end)` ; `:Get`, `:Set`, `:Invalidate`, `:InvalidatePrefix`. À utiliser pour toute donnée lue souvent et modifiée rarement ; invalide la clé quand tu la modifies.
- **`/pickaxdoctor`** (console serveur ou admin) : ressources non démarrées, état du cache, résumé des index. `/pickaxdoctor run` relance les index et la purge.
- **server.cfg** : `mysql_slow_query_warning 150` affiche en console les requêtes SQL plus lentes que 150 ms.

## Trouver ce qui ralentit (à faire en jeu)
1. Client : F8 → `resmon 1` : repère les ressources au-dessus de 0,05 ms au repos.
2. Serveur : `profiler record 500` puis `profiler view` (txAdmin → Profiler).
3. SQL : surveille les alertes « slow query » de la console.

## Vérifications faites sur le dépôt
- Syntaxe de tous les fichiers Lua (880) et JavaScript (84), validité des 90 JSON : 0 erreur.
- Fichiers référencés par les `fxmanifest` : tous présents (seuls des motifs `*` sans correspondance, sans conséquence).
- Exports `pickax_*` appelés : tous définis.
- Tests automatiques : `for f in tools/tests/*_test.lua; do lua5.4 $f; done` (29 suites).
