# pickax_theme — identité commune du serveur

Tout se règle en haut de `pickax_core/config.lua` :

```lua
AccentColor = '#00a4ff',            -- couleur principale
ServerName = 'Bluebay Roleplay',    -- nom complet
ServerShortName = 'BLUEBAY',        -- nom court (HUD, connexion, Discord…)
ServerTagline = 'RP sérieux · Free-Access',
ServerDiscord = 'discord.gg/bluebayrp',
ServerLogo = 'logo.png',            -- fichier dans pickax_theme/logo/ (ou lien https://…)
```

Logo : remplace `logo/logo.png` (PNG transparent, idéalement carré 500×500) ou dépose ton image dans `logo/` et mets son nom dans `ServerLogo`.

Après modification : `restart pickax_theme`, puis relance les ressources voulues (ou reconnecte-toi).

- NUI : chaque page charge `theme.js` (variables CSS `--pk-accent*`, `--pk-logo`, attributs `data-pk="name|short|tagline|discord"`, `data-pk-logo`).
- Lua : `shared_script '@pickax_theme/theme.lua'` → `PickaxTheme.hex/.rgb/.name/.short/.tagline/.discord/.logo`.
- `theme.js` contient des valeurs de secours si `pickax_core/config.lua` est illisible.
- `server.cfg` (`sv_projectName`, `sets discord`…) reste à modifier à la main : ce fichier n'est pas lisible par les scripts.
- Les choix faits en jeu par les joueurs (menu personnel) ou enregistrés dans un builder priment sur la couleur par défaut.
