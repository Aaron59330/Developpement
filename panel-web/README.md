# Pickax Panel (panel web)

Panel centralisé pour configurer tes serveurs : **connexion → Mes serveurs → licence → Configuration**.
Aucune dépendance : il faut seulement **Node.js 18+** (https://nodejs.org).

## Lancer le panel

* Windows : double-clic sur `lancer-panel.bat`
* Linux / VPS : `node server.js` (ou `PORT=3000 node server.js`, à garder lancé avec pm2 / systemd)

Ouvre http://localhost:3000. Au **premier lancement**, la page te demande de créer ton compte administrateur.
Les données (comptes, serveurs, réglages, historique) sont dans `data/panel.json` — à sauvegarder.

Variables optionnelles : `PORT` (3000), `HOST` (0.0.0.0), `DATA_DIR`, `PUBLIC_URL` (adresse publique du panel, ex. `https://panel.monsite.fr`, utilisée dans la clé de liaison).

> Pour un panel accessible depuis Internet, place-le derrière un reverse proxy HTTPS (nginx / Caddy) et renseigne `PUBLIC_URL`.

## Relier un serveur de jeu (une seule ligne dans server.cfg)

1. Panel → **Mes serveurs** → **Ajouter un serveur** → copie la ligne affichée.
2. Colle-la dans le `server.cfg` du serveur de jeu :
   ```
   set pickax_panel_key "https://ton-panel|CLE_SECRETE"
   ```
3. Redémarre le serveur (la ressource `pickax_panel` est lancée par `ensure [dev]`). Il passe « en ligne » dans le panel.

**L'adresse dans la clé doit être joignable depuis le serveur de jeu.** `localhost` = la machine du serveur lui-même : si le panel est sur ton PC et le jeu sur un VPS, ça ne marche pas. Deux solutions : héberger le panel sur le VPS (adresse `http://IP_DU_VPS:3000`, port 3000 ouvert dans le pare-feu) ou l'exposer avec un nom de domaine / reverse proxy. L'adresse est modifiable dans la fenêtre de la clé avant de copier la ligne.

Le serveur **appelle** le panel toutes les 15 secondes (connexion sortante : aucun port à ouvrir côté jeu, le serveur de jeu peut être sur un VPS et le panel n'importe où, y compris sur ton PC si le VPS peut l'atteindre).

## Panel sur ton PC + serveur de jeu chez un hébergeur (VibeGames…)

Le serveur de jeu doit pouvoir **joindre** le panel. Ton PC est derrière ta box : il faut le rendre accessible avec un **tunnel** gratuit (Cloudflare) :

1. Lance le panel : `lancer-panel.bat`.
2. Télécharge `cloudflared` pour Windows (https://github.com/cloudflare/cloudflared/releases/latest → `cloudflared-windows-amd64.exe`), renomme-le `cloudflared.exe` et place-le dans le dossier `panel-web`.
3. Lance `lancer-tunnel.bat` : repère l'adresse `https://xxxx.trycloudflare.com` affichée.
4. Dans le panel (http://localhost:3000) → Mes serveurs → Ajouter / Régénérer la clé : **remplace l'adresse par celle du tunnel**, copie la ligne dans le `server.cfg`, redémarre le serveur.

Limites : le PC et le tunnel doivent rester allumés (sinon le serveur apparaît « hors ligne », ses réglages déjà appliqués restent en place), et cette adresse **change à chaque lancement du tunnel** : il faut alors régénérer la clé. Pour une adresse fixe : tunnel Cloudflare nommé (nom de domaine) ou ngrok avec domaine statique, puis écris l'adresse dans `public-url.txt` (lue par `lancer-panel.bat`). Solution durable : héberger le panel sur un petit VPS allumé en permanence.

## Fonctionnement

* À chaque appel, le serveur envoie la liste des réglages de **tes scripts** avec leur valeur actuelle (lue dans tes fichiers) : le panel s'adapte à ta configuration.
* **Réglages « en direct »** (notifications, HUD, menus RageUI, markers, file d'attente) : le serveur ne touche **à aucun fichier**. La valeur du panel est diffusée aux joueurs (`GlobalState.pickaxPanel`) et lue par les scripts via `exports.pickax_panel:Get('<groupe>')`. Ça marche sur un hébergeur qui interdit l'écriture (VibeGames…) et sans redémarrage. Le fichier garde la valeur par défaut ; « ↶ » ou « Restaurer » la rétablit. Le serveur garde un cache local : si le panel est hors ligne au démarrage, les derniers réglages restent appliqués.
* **Section Général** (nom, description, tags, locale, bannières…) : variables du serveur appliquées en direct.
* **Réglages « fichiers »** (écran de chargement, page web chargée avant le jeu) : écrits dans les fichiers de la ressource. Le serveur teste au démarrage s'il a le droit d'écrire ; sinon la section est affichée « verrouillée ».
* Les joueurs gardent leurs préférences personnelles (menu personnel) ; le panel règle les valeurs par défaut.
* Serveur hors ligne : les modifications sont gardées et appliquées à sa reconnexion.
* Le serveur de jeu ne peut appliquer que les réglages déclarés dans `resources/[dev]/pickax_panel/schema.lua` : même si le panel était compromis, il ne peut ni exécuter de code ni écrire ailleurs.

## Sécurité

Mots de passe hachés (scrypt), session par cookie signé (HttpOnly, SameSite=Strict), en-tête anti-CSRF, blocage 10 min après 8 échecs, clés de liaison stockées sous forme de hash (affichées une seule fois ; « Régénérer » en crée une nouvelle).
