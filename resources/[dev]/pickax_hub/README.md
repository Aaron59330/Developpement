# pickax_hub — menu personnel central (F5)

Remplace le menu RageUI de base (touche **F5**) par une interface moderne, **avec uniquement les fonctions du menu d'origine** :
- **Informations** : profil, ID, métier, portefeuille (liquide / banque / argent sale) et **factures** (paiement).
- **Documents** : carte d'identité, permis de conduire, port d'armes — montrer au joueur proche ou regarder.
- **Véhicule** : nom, plaque, état moteur, CarPlay, moteur, capot, coffre, portes, fenêtres, limitateur.
- **Préférences** : apparence des menus (pickax_ui), HUD (pickax_hud2 + boussole), performances (FPS), jeu (crosse, radar, HUD), Rockstar Editor.
- **Touches** et **Commandes** du serveur (listes lues dans la config réelle).
- **Liens** : Discord et boutique.

Fonctionnement : `pickax_core/players/menupersonnel` redirige F5 vers `exports['pickax_hub']:Open()` si la ressource est démarrée
(`ConfigMenuF5.UseHub = false` pour revenir à l'ancien menu). Les données passent par les exports de `pickax_ui`, `pickax_hud2`, `pickax_compass`, `pickax_notify`
et par de nouveaux exports de `pickax_core` (`HubKeys`, `HubCommands`, `HubPerf`, `HubPerfSet`).

Réglages : `config.lua` (couleur `Config.Accent`, liens, vitesses du limitateur). Le style vient de `pickax_theme/design.css`.
