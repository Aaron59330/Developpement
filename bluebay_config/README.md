# bluebay_config

Configuration centrale du serveur, éditée depuis une page locale.

## Utilisation
1. Ouvre `panel/index.html` dans ton navigateur (double-clic, aucun serveur nécessaire).
2. Règle : identité visuelle, serveur, markers, tailles des menus.
3. Clique **Télécharger config.json** et remplace le fichier de cette ressource.
4. Clique **Télécharger server.cfg** et reporte le bloc dans ton `server.cfg`.
5. `ensure bluebay_config` puis relance les ressources concernées.

`config.json` ne contient jamais ta clé cfx ni ta clé Steam (elles ne vont que dans le `server.cfg` généré).

## Utiliser la config dans un script
```lua
local accent = exports['bluebay_config']:GetAccent()        -- '#00a4ff'
local r, g, b = exports['bluebay_config']:GetAccentRGB()
local menu = exports['bluebay_config']:GetMenu('contextMenu') -- { width, itemHeight, ... }
local logo = exports['bluebay_config']:GetLogoUrl()          -- URL NUI du logo

-- Marker configuré (à appeler à chaque frame)
exports['bluebay_config']:DrawMarker('garage', vector3(0.0, 0.0, 70.0))
```
Dans une interface NUI : `<img src="https://cfx-nui-bluebay_config/logo.png">`.
