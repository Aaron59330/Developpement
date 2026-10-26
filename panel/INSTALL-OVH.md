# Installer le panel sur un VPS OVH (Ubuntu 24.04), de A à Z

Version « accès par IP » (sans nom de domaine). Pour passer en HTTPS plus tard, voir l'étape 13.

## 1. Récupérer tes accès OVH
Dans l'e-mail d'OVH ou l'espace client (rubrique VPS) : l'**adresse IP**, l'**utilisateur** (`ubuntu`, parfois `root`) et le **mot de passe**.

## 2. Se connecter (PowerShell sur Windows)
```
ssh ubuntu@IP_DU_VPS
```
Réponds `yes`, colle le mot de passe (il ne s'affiche pas). Si OVH te fait changer le mot de passe, fais-le.

## 3. Mettre à jour
```
sudo apt update && sudo apt upgrade -y
```
Si ça propose de redémarrer : `sudo reboot`, attends 1 minute et reconnecte-toi (étape 2).

## 4. Pare-feu
```
sudo ufw allow OpenSSH
sudo ufw allow 3000
sudo ufw --force enable
```
Si tu as activé le Firewall réseau dans l'espace client OVH, ouvre aussi le port TCP 3000 là-bas.

## 5. Installer Node.js 22 et les outils
```
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs git build-essential python3
node -v
```
`node -v` doit afficher v22.

## 6. Envoyer le panel sur le VPS
Depuis **ton PC** (nouveau PowerShell, dans le dossier du dépôt cloné, là où se trouve le dossier `panel`) :
```
scp -r panel ubuntu@IP_DU_VPS:/home/ubuntu/
```
(ou, sur le VPS, `git clone -b claude/tender-meitner-obo2m4 https://github.com/aaron59330/developpement.git` avec un token GitHub si le dépôt est privé, puis `cd developpement/panel`).

## 7. Installer les dépendances
```
cd /home/ubuntu/panel
npm install --omit=dev
```

## 8. Configurer
```
cp .env.example .env
openssl rand -hex 32
nano .env
```
Dans `.env` :
```
PORT=3000
PUBLIC_URL=http://IP_DU_VPS:3000
SESSION_SECRET=<colle le résultat de openssl>
ADMIN_EMAIL=ton@email.fr
ADMIN_PASSWORD=UnMotDePasseLong!
ALLOW_REGISTER=false
TRUST_PROXY=false
```
Enregistre : `Ctrl+O`, `Entrée`, `Ctrl+X`.

## 9. Test
```
npm start
```
Tu dois voir `[panel] http://localhost:3000`. Dans ton navigateur : `http://IP_DU_VPS:3000` → page de connexion AERO. `Ctrl+C` pour arrêter.

## 10. Lancement permanent (pm2)
```
sudo npm install -g pm2
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```
`pm2 startup` affiche une commande `sudo env PATH=...` : copie-la et exécute-la, puis refais `pm2 save`. Vérifie : `pm2 status` (aero-panel = online).

## 11. Première connexion
1. `http://IP_DU_VPS:3000`, connecte-toi avec ADMIN_EMAIL / ADMIN_PASSWORD.
2. **Administration → Licences → Nouveau client + licence** : crée-toi une licence (toi, offre « Licence à vie », durée 0).
3. Copie la clé `AERO-…`.

## 12. Relier ton serveur FiveM
Dans `server.cfg` (après `ensure es_extended` et `ensure pickax_basetools`) :
```
set aero_panel_url "http://IP_DU_VPS:3000"
set aero_panel_key "AERO-XXXXXX-XXXXXX-XXXXXX-XXXXXX"
ensure pickax_panel
```
`set`, jamais `setr`. Redémarre le serveur : la console affiche « [pickax_panel] Liaison avec le panel », et le panel passe à EN LIGNE en moins de 30 s.

## 12 bis. Si l'éditeur de fichiers ou le thème est refusé (sandbox FiveM)
FiveM interdit à une ressource d'écrire dans une autre. Si le panel affiche « FiveM refuse d'écrire dans … », ajoute dans `server.cfg` la ligne indiquée, par exemple :
```
add_filesystem_permission pickax_panel write pickax_core
```
(une ligne par ressource que tu veux modifier depuis le panel), puis redémarre le serveur. Le thème, lui, n'a besoin d'aucune autorisation : il est écrit dans `pickax_basetools`.
Si le message est « Access to this API has been restricted. Use --allow-fs-read », le Node intégré à ton FXServer n'a pas le droit de lire le disque : la ressource bascule alors toute seule sur les fonctions natives de FiveM (explorateur limité aux fichiers déclarés dans les `fxmanifest`).

## 13. (Plus tard) HTTPS avec un nom de domaine ou DuckDNS
```
sudo apt install -y nginx certbot python3-certbot-nginx
sudo ufw allow 80 && sudo ufw allow 443
sudo cp nginx.conf.example /etc/nginx/sites-available/panel
sudo nano /etc/nginx/sites-available/panel      # remplace panel.mondomaine.fr par ton nom
sudo ln -s /etc/nginx/sites-available/panel /etc/nginx/sites-enabled/panel
sudo nginx -t && sudo systemctl reload nginx
sudo certbot --nginx -d TON_NOM
```
Puis dans `.env` : `PUBLIC_URL=https://TON_NOM`, `TRUST_PROXY=true`, puis `pm2 restart aero-panel`, et mets l'adresse https dans le `server.cfg` (et chez tes clients). Tu peux ensuite fermer le port 3000 : `sudo ufw delete allow 3000`.

## Maintenance
- Mettre à jour le panel : renvoyer le dossier `panel` (étape 6, en gardant ton `.env` et le dossier `data/`), puis `cd /home/ubuntu/panel && npm install --omit=dev && pm2 restart aero-panel`.
- Voir les erreurs : `pm2 logs aero-panel`.
- Sauvegarde : `/home/ubuntu/panel/data/` (toute ta base).

## Problèmes fréquents
| Symptôme | Solution |
|---|---|
| `http://IP:3000` ne répond pas | Port 3000 fermé : `sudo ufw status`, Firewall OVH, ou `pm2 status`. |
| `npm install` échoue sur better-sqlite3 | `sudo apt install -y build-essential python3` puis relancer. |
| Page blanche / CSS cassé | Tu es en HTTP : `PUBLIC_URL` doit commencer par `http://` (pas `https://`). |
| FiveM : « Clé de licence inconnue » | Clé mal copiée dans `server.cfg`. |
| FiveM : « autre adresse » | Panel → Licence & installation → Changer de machine. |
