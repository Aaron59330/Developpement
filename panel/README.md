# Panel AERO (version allégée)

Site Node.js + SQLite : comptes, **boutique** (offres, commandes validées à la main), **licences**, **support** (tickets, suggestions, patch notes) et administration (clients, licences, offres, modules, journal).
Aucun réglage de la base n'est modifiable depuis ce panel : tout se règle dans les `config.lua`.

```bash
cd panel
cp .env.example .env   # PUBLIC_URL, SESSION_SECRET, ADMIN_EMAIL, ADMIN_PASSWORD
npm install && npm start   # http://localhost:3000
```
Production : `pm2 start ecosystem.config.js` + nginx (`nginx.conf.example`) + HTTPS. Sauvegarde : le dossier `data/` (`panel.db`).
L'ancien panel complet reste dans `_archive_panel/`.

## Personnalisation (couleur + logo)
Page « Personnalisation » : couleur principale et logo (.png / .jpg glissé-déposé, 2 Mo max) par licence.
Côté jeu, la ressource `resources/[dev]/pickax_panelsync` récupère ces réglages avec la clé de licence (toutes les 60 s) et les applique via `pickax_basetools` (`server.cfg` : `set aero_panel_url`, `set aero_panel_key`, `add_filesystem_permission pickax_panelsync write pickax_theme`).
