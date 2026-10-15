# pickax_panel — agent de liaison avec le panel web

Cette ressource relie le serveur de jeu au panel web (`panel-web/` à la racine du dépôt) avec **une seule ligne dans `server.cfg`** :

```
set pickax_panel_key "https://ton-panel|CLE_SECRETE"
```

La ligne (clé comprise) est générée par le panel : **Mes serveurs → Ajouter un serveur**. Sans clé valide, la ressource reste inactive.

* Le serveur appelle le panel toutes les 15 s (sortant, rien à ouvrir) : il envoie les réglages de tes scripts + leurs valeurs, et applique ceux enregistrés sur le site.
* **Groupes `live = true`** (notify, hud1, hud2, rageui, markers, connect) : appliqués **en direct, sans écrire de fichier**. Le serveur diffuse les valeurs (`GlobalState.pickaxPanel`) et les scripts les lisent via `exports.pickax_panel:Get('<groupe>')` (petit crochet déjà ajouté dans pickax_notify, pickax_ui, PickaxHud1/2, PickaxConnectUI et CorePickax/utils/panelHook). Fonctionne sur un hébergeur verrouillé.
* **Autres groupes** (écran de chargement) : écrits sur place dans les fichiers (`schema.lua` décrit les lignes, `lib/patcher.lua` fait le remplacement) ; verrouillés automatiquement si le serveur n'a pas le droit d'écrire.
* Section « Général » : variables du serveur (`sv_projectName`, `tags`, `locale`, bannières…) appliquées en direct.

## Ajouter un réglage

Dans `schema.lua`, copier une ligne `F { ... }` : `file` (chemin dans la ressource), `anchor` (texte qui précède, ex. `RageUIStyle = {`), `key` (nom de la valeur), `type` (`bool`, `number`, `color`, `rgba`, `text`, `css`, `url`, `items`). Il apparaît tout seul dans le panel à la prochaine synchronisation. Un réglage dont la ligne est introuvable est signalé en rouge.
