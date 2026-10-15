# pickax_panel — panel web de configuration

Modifie depuis un site : écran de chargement, couleurs / bannière des menus RageUI, markers, HUD, notifications, file d'attente.

## Installation (1 ligne dans `server.cfg`)

```
set pickax_panel_key "UneCleLongueEtSecrete123"
```

La ressource est lancée par `ensure [dev]` (déjà présent dans `resources.cfg`). Clé : **12 caractères minimum**, sinon le panel reste désactivé.

Ouvrir ensuite : `http://IP_DU_SERVEUR:30120/pickax_panel/` puis saisir la clé.
(Le panel utilise le port du serveur de jeu, aucun autre port à ouvrir. Pour du HTTPS, le placer derrière un reverse proxy.)

## Comment ça marche

* Le panel **lit directement tes fichiers existants** (`CorePickax/config.lua`, `pickax_notify/config.lua`, `PickaxLoading/style.css`, `PickaxHud2/html/css/css.css`...). Aucun script n'est à modifier.
* À l'enregistrement, la valeur est remplacée **sur place** dans le fichier (commentaires et mise en forme conservés) **et** sauvegardée dans la base (`pickax_panel_settings`).
* Au démarrage du serveur, les réglages de la base sont **réappliqués** : un `git pull` qui écrase un config ne fait donc rien perdre. Si un fichier a été écrasé, la ressource concernée est redémarrée automatiquement.
* « Enregistrer et appliquer » redémarre les ressources modifiées ; « Enregistrer » seul les met en attente (bandeau jaune).
* L'icône ↶ à côté d'un réglage restaure la valeur d'origine du script. L'historique liste toutes les modifications (`pickax_panel_log`).

## Ajouter un réglage

Dans `schema.lua`, copier une ligne `F { ... }` : `file` (chemin dans la ressource), `anchor` (texte qui précède, ex. `RageUIStyle = {`), `key` (nom de la valeur) et `type` (`bool`, `number`, `color`, `rgba`, `text`, `css`, `url`, `items`).
Un réglage dont la ligne est introuvable est affiché en rouge dans le panel (le fichier a changé de forme).

## Sécurité

* Toutes les routes `/api/*` exigent la clé (en-tête `X-Panel-Key`), comparaison en temps constant, blocage 10 min après 6 essais ratés.
* Le panel ne peut écrire que dans les fichiers / lignes déclarés dans `schema.lua`, avec valeurs validées par type (pas de code, pas de caractères de contrôle).
