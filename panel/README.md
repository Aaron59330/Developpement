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
