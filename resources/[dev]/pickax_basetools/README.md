# pickax_basetools — outils de la base

`/aerotools` (réservé aux groupes admin / superadmin / owner, ou à l'ACE `pickax.basetools`).

- **Santé** : ressources indispensables, tables SQL, objets ox_inventory, points sans position, métiers vides, concessions sans point Catalogue, `server.cfg` (licence, MySQL). Score sur 100.
- **Sauvegardes** : sauvegarde / restauration de la configuration des builders (fichiers dans `backups/`, jamais versionnés). Une sauvegarde de sécurité est créée avant chaque restauration, puis les builders redémarrent.
- **Nouveautés** : journal des modifications (`changelog.lua`, à compléter à chaque mise à jour).
- **Guide** : raccourcis et bonnes pratiques.

Listes à adapter dans `config.lua` : `Required`, `Tables`, `Items`, `BackupTables`, `Webhook` (Discord, optionnel).
Les sauvegardes ne contiennent ni logs ni données joueurs ; les colonnes de date reprennent leur valeur par défaut à la restauration.
