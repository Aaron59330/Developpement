# Protection de la base (pickax_guard)

Sans clé de licence valide dans le `server.cfg`, **la base ne démarre pas**.

## Ce qui est en place
- `resources/[dev]/pickax_guard` démarre **en premier** (`resources.cfg`, tout en haut). Il contacte ton panel (`set aero_panel_url` + `set aero_panel_key`) et n'autorise le démarrage des ressources `pickax_*` que si la réponse est valide.
- La réponse du panel est **signée (Ed25519)** et liée à un nonce aléatoire et à l'empreinte de la clé : un faux panel, une réponse rejouée ou modifiée sont refusés. La clé privée reste sur ton VPS (`panel/data/guard-ed25519.json`, jamais dans Git) ; seule la clé publique est dans la base.
- Une clé révoquée, suspendue ou expirée arrête la base en moins de 10 minutes. Une clé utilisée depuis une autre adresse IP est refusée (liaison à la première IP ; « Délier » dans le panel pour un changement d'hébergeur).
- Panel en panne : les serveurs déjà vérifiés continuent **24 h** (mémoire signée), puis la base s'arrête.
- Chaque ressource de la base déclare `dependency 'pickax_guard'` (elle ne démarre pas sans lui) et contient un **point de contrôle** qui l'arrête si la licence n'est plus valide ou si le guard a disparu. Retirer le guard ne suffit donc pas.
- Panel → Administration → **Protection de la base** : clé publique à copier, dernière vérification et IP vue pour chaque licence.

## Mise en route (dans cet ordre, sinon TA base ne démarre plus non plus)
1. **Mets à jour le panel sur le VPS** (zip + `pm2 restart aero-panel`). Au premier démarrage, il crée la paire de clés.
2. Panel → **Administration → Protection de la base** → copie la ligne `Config.PublicKey = '…'`.
3. Colle-la dans `resources/[dev]/pickax_guard/config.lua` (remplace `Config.PublicKey = ''`), puis `git add`, `git commit`, `git push`.
4. Sur le serveur de jeu : `set aero_panel_url "https://…"` et `set aero_panel_key "AERO-…"` dans le `server.cfg` (ta propre licence : Administration → Licences), puis `git pull` et redémarre le serveur.
5. Console au démarrage : `[AERO] Licence valide (…) — démarrage de la base.`

**Retour arrière** si besoin : `git checkout bc12856 -- .` (dernier état avant la protection), puis redémarre.

## Ce qu'il faut savoir (honnêteté)
Les fichiers Lua d'un serveur sont lisibles et modifiables par son propriétaire : quelqu'un de très motivé peut, en théorie, supprimer les points de contrôle et le guard dans **chaque** ressource. Ce système empêche le vol « simple » (copier le dossier et le lancer, garder une clé révoquée, partager une clé, faux panel) et rend le vol long et traçable. Pour une protection forte :
- **Escrow Cfx.re** (via Tebex) : chiffre les scripts livrés ; c'est la seule protection que FiveM applique réellement. Les fichiers à personnaliser par le client se déclarent avec `escrow_ignore`.
- **Obfuscation** des fichiers du guard et des points de contrôle avant livraison.
- Ne livre pas `pickax_panel/config.lua` modifié ni de `server.cfg` contenant tes clés.
- Surveille Administration → Protection de la base : une IP ou un nom de serveur inattendu pour une licence = clé partagée → révoque-la.

## Tests
`node tools/tests/guard_test.js` (25 vérifications : signature, faux panel, rejeu, IP, expiration, révocation en cours de route, cache de 24 h).
