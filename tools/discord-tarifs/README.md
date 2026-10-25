# Message « Tarifs » pour Discord

1. Modifie `config.json` : nom, prix, lignes, lien du salon tickets.
2. `npm i playwright` puis `node build-images.js` (génère les bannières et prix dans `images/`).
3. Discord : paramètres du salon → Intégrations → Webhooks → Nouveau webhook → copier l'URL.
4. `WEBHOOK_URL="<url>" node send.js` poste le message.

Pour modifier ensuite : supprime le message, change `config.json`, relance les étapes 2 et 4.
