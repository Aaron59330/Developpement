# pickax_panel

Liaison avec le panel web AERO (dossier `panel/` du dépôt).

## Installation
1. Mets le dossier dans `resources/[dev]/`.
2. `server.cfg` :
```
set aero_panel_url "https://panel.mondomaine.fr"
set aero_panel_key "AERO-XXXXXX-XXXXXX-XXXXXX-XXXXXX"
ensure pickax_panel
```
3. Après `ensure pickax_basetools` (le thème est appliqué via `pickax_basetools`).

## Ce que la ressource fait
- envoie toutes les 10 s : joueurs (ESX), ressources, logs, statistiques ; reçoit les actions et réglages ;
- exécute uniquement une liste blanche d'actions (voir `server/main.lua`, table `H`) ;
- applique bans / whitelist à la connexion (cache dans `cache_*.json`), message de bienvenue, thème ;
- `Config.Enforce` : arrête certaines ressources si la licence est invalide ;
- exports serveur : `IsLicensed()`, `PanelLog(niveau, source, message)` (pour que tes scripts envoient des logs au panel), `GetLicenseInfo()`.
