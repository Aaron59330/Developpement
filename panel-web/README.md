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

Le serveur **appelle** le panel toutes les 15 secondes (connexion sortante : aucun port à ouvrir côté jeu, le serveur de jeu peut être sur un VPS et le panel n'importe où, y compris sur ton PC si le VPS peut l'atteindre).

## Fonctionnement

* À chaque appel, le serveur envoie la liste des réglages de **tes scripts** (lus dans tes fichiers existants : `config.lua`, `style.css`, `index.html`…) avec leur valeur actuelle : le panel s'adapte donc à ta configuration, sans rien modifier dans tes scripts.
* Quand tu enregistres, le panel garde la valeur ; le serveur la reçoit, la remplace **sur place** dans le fichier (commentaires conservés) et affiche « appliqué ».
* « Enregistrer et appliquer » redémarre aussi les ressources modifiées ; « Enregistrer » seul les met en attente (bandeau jaune avec bouton **Redémarrer**).
* Serveur hors ligne : les modifications sont gardées et appliquées à sa reconnexion.
* Les réglages sont **réappliqués à chaque démarrage** : un `git pull` qui écrase un config ne fait rien perdre.
* La section **Général** (nom, description, tags, locale, bannières…) s'applique en direct, sans redémarrage.
* Le serveur de jeu ne peut écrire que dans les lignes déclarées dans `resources/[dev]/pickax_panel/schema.lua` : même si le panel était compromis, il ne peut pas faire exécuter de code ni écrire ailleurs.

## Sécurité

Mots de passe hachés (scrypt), session par cookie signé (HttpOnly, SameSite=Strict), en-tête anti-CSRF, blocage 10 min après 8 échecs, clés de liaison stockées sous forme de hash (affichées une seule fois ; « Régénérer » en crée une nouvelle).
