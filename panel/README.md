# AERO Panel : espace client + gestion des serveurs FiveM

Site web (Node.js + SQLite, aucun service externe) où tes clients :
- créent un compte et retrouvent leur(s) **licence(s)** ;
- suivent leur serveur (en ligne, joueurs, graphique 24 h, uptime) ;
- **agissent à distance** : expulser, bannir, réanimer, message privé, changer métier/groupe, donner argent/objet, annonce, redémarrer une ressource, événement économique ;
- modifient le **thème** (couleur, nom, logo, Discord), les **bans**, la **whitelist** et le message de bienvenue ;
- lisent la **console / logs** et voient la liste des ressources.

Toi (compte admin) : clients, licences (créer, prolonger, suspendre, délier l'IP, supprimer), offres/prix, chiffres, journal d'audit.

## Comment ça marche
Le serveur FiveM du client n'ouvre **aucun port**. La ressource `pickax_panel` (dans `resources/[dev]/`) appelle le panel toutes les 10 s avec la clé de licence : elle envoie l'état (joueurs, ressources, logs) et récupère les actions à exécuter et les réglages modifiés. Les actions sont validées par le panel **et** par la ressource (liste blanche).

```
Navigateur ─► Panel (Node + SQLite) ◄── pickax_panel (serveur FiveM du client, requêtes sortantes HTTPS)
```

## Installation du panel (VPS Linux)
```bash
cd panel
cp .env.example .env     # édite PUBLIC_URL, SESSION_SECRET, ADMIN_EMAIL, ADMIN_PASSWORD
npm install
npm start                # http://localhost:3000
```
En production : `pm2 start ecosystem.config.js` + nginx (`nginx.conf.example`) + HTTPS (`certbot --nginx`). Docker : `docker build -t aero-panel . && docker run -d -p 3000:3000 -v aero-data:/data --env-file .env aero-panel`.
Sauvegarde : copie le dossier `data/` (fichier `panel.db`).

Hébergeur sans Node (mutualisé OVH, etc.) : non compatible, il faut un VPS ou un hébergeur Node (Railway, Render, etc.).

## Donner un serveur à un client
1. Admin → **Licences** → *Nouvelle licence* (client + offre). Ou laisse le client s'inscrire (`ALLOW_REGISTER=true`, `TRIAL_DAYS=7` pour un essai automatique).
2. Le client ouvre **Licence & installation** : il y trouve sa clé et les 2 lignes à mettre dans son `server.cfg` :
```
set aero_panel_url "https://panel.mondomaine.fr"
set aero_panel_key "AERO-XXXXXX-XXXXXX-XXXXXX-XXXXXX"
ensure pickax_panel
```
3. Une licence est liée à la **première adresse IP** qui l'utilise (anti-partage). Le client peut la délier lui-même (changement d'hébergeur).
4. `Config.Enforce = true` dans `pickax_panel/config.lua` (chez le client) : si la licence est expirée/suspendue, les ressources listées dans `StopResources` sont arrêtées (tolérance `GraceHours` si le panel est injoignable).

## Sécurité (déjà en place)
Mots de passe bcrypt, sessions en cookie httpOnly/SameSite, protection CSRF (Origin + JSON), en-têtes Helmet + CSP, limitation de débit (connexion, agent), requêtes SQL préparées, actions serveur en liste blanche, un client ne voit que ses licences.
Limite à connaître : le Lua d'une ressource non « escrow » peut être modifié par le client ; pour que la vérification de licence soit difficile à contourner, passe `pickax_panel` (et les ressources vendues) sous l'escrow FiveM (Tebex/Keymaster).

## Tests
```bash
npm test                      # 30 vérifications de l'API
node tools/agent-e2e.js       # panel réel + ressource Lua simulée (lua5.4 + curl requis)
node tools/demo-seed.js       # base de démo (DATA_DIR=./data-demo)
```

## Pas encore inclus
Paiement en ligne (Stripe/PayPal) : les offres et la facturation sont gérées à la main par l'admin ; e-mails automatiques (mot de passe oublié) ; éditeurs de jobs / boutiques / items à distance (à brancher sur les builders dans une 2ᵉ étape).
