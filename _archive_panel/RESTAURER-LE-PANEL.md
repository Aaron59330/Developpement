# Panel web AERO — archivé

Le système de panel (site web + ressource `pickax_panel`) a été **retiré de la base** à la demande du propriétaire : tous les réglages importants se font maintenant dans le `config.lua` de chaque script (voir `docs/CONFIGURATION.md`).

Rien n'est perdu :

- `panel/` : le site (Node/Express/SQLite : comptes, licences, clients, configuration, éditeur de fichiers, journal…).
- `pickax_panel/` : la ressource FiveM qui relie le serveur de jeu au site (synchronisation, licence, applications des réglages).
- Le dépôt Git garde l'historique complet : `git checkout 1ec433c` (dernier commit avec le panel ; l'étiquette locale `panel-v1` pointe dessus) donne la base exactement comme elle était avec le panel.

## Pour remettre le panel (demande-le simplement à Claude : « remets le panel »)

1. Remettre le site : copier `_archive_panel/panel/` à la racine du dépôt (`panel/`), puis sur le VPS : `npm install` et `pm2 start ecosystem.config.js` (voir `panel/INSTALL-OVH.md`).
2. Remettre la ressource : copier `_archive_panel/pickax_panel/` dans `resources/[dev]/pickax_panel/`.
3. Dans `server.cfg`, remettre :
   ```
   set aero_panel_url "https://panel.aerofivem.site"
   set aero_panel_key "AERO-XXXXXX-XXXXXX-XXXXXX-XXXXXX"
   add_filesystem_permission pickax_basetools write pickax_core
   add_filesystem_permission pickax_basetools write pickax_theme
   add_filesystem_permission pickax_panel write pickax_core
   add_ace resource.pickax_panel command allow
   ```
4. Redémarrer le serveur. Les scripts relisent automatiquement les réglages du panel (`pickax_panel/cache_*.json`) en plus de leur `config.lua`, rien d'autre à brancher : le code qui les lit est resté en place (désactivé tant que la ressource est absente).
