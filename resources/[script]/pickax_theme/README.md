# pickax_theme — couleur principale commune

Pour changer le bleu (`#00a4ff`) de **toutes** les interfaces : ouvre `theme.js`, modifie la ligne

```js
window.PICKAX_ACCENT = '#00a4ff';
```

puis `restart pickax_theme` et relance les ressources voulues (ou reconnecte-toi).

- NUI (HUD, pause, CarPlay, builders, tablette, notifications, pickax_ui…) : chaque page charge `theme.js` et utilise les variables CSS `--pk-accent`, `--pk-accent-rgb`, `--pk-accent-light`, `--pk-accent-dark`.
- Lua (menu contextuel, notify, pickax_ui, menu personnel, builders) : `shared_script '@pickax_theme/theme.lua'` → `PickaxTheme.hex` / `PickaxTheme.rgb`.
- `ensure pickax_theme` doit être lancé **avant** les autres ressources (déjà en tête de `resources.cfg`).
- Nouvelle interface : ajoute `<script src="https://cfx-nui-pickax_theme/theme.js"></script>` dans le `<head>` et utilise `var(--pk-accent, #00a4ff)` / `rgba(var(--pk-accent-rgb, 0,164,255), .3)` dans le CSS.
- Exceptions : couleurs choisies par le joueur (menu personnel → Préférences) ou enregistrées en jeu dans un builder (Paramètres → Apparence) : elles priment sur le défaut.
