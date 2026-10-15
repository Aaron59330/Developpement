# pickax_panel — agent de liaison avec le panel web

Cette ressource relie le serveur de jeu au panel web (`panel-web/` à la racine du dépôt) avec **une seule ligne dans `server.cfg`** :

```
set pickax_panel_key "https://ton-panel|CLE_SECRETE"
```

La ligne (clé comprise) est générée par le panel : **Mes serveurs → Ajouter un serveur**. Sans clé valide, la ressource reste inactive.

* Le serveur appelle le panel toutes les 15 s (sortant, rien à ouvrir) : il envoie les réglages de tes scripts + leurs valeurs, et applique ceux enregistrés sur le site.
* Les valeurs sont écrites **sur place** dans tes fichiers existants (`schema.lua` décrit les lignes concernées, `lib/patcher.lua` fait le remplacement). Rien à modifier dans tes scripts.
* Réappliqué à chaque démarrage (un `git pull` qui écrase un config ne fait rien perdre) ; la ressource concernée est alors redémarrée automatiquement.
* Section « Général » : variables du serveur (`sv_projectName`, `tags`, `locale`, bannières…) appliquées en direct.

## Ajouter un réglage

Dans `schema.lua`, copier une ligne `F { ... }` : `file` (chemin dans la ressource), `anchor` (texte qui précède, ex. `RageUIStyle = {`), `key` (nom de la valeur), `type` (`bool`, `number`, `color`, `rgba`, `text`, `css`, `url`, `items`). Il apparaît tout seul dans le panel à la prochaine synchronisation. Un réglage dont la ligne est introuvable est signalé en rouge.
