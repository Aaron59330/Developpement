# pickax_hub — menu central du serveur

Une touche (**F1** par défaut, modifiable dans les raccourcis FiveM) ouvre un seul menu :
- **Accueil** : salutation, banque, espèces, joueurs en ligne, accès rapide (téléphone, menu métier, gang, animations, CarPlay, boutique).
- **Métier** : métier, grade, salaire, bouton vers le menu métier.
- **Véhicules** : véhicules du joueur (table `owned_vehicles`), bouton « Localiser » (GPS sur le véhicule s'il est sorti).
- **Activités** : braquage, mini-jeux, événements, avec point GPS.
- **Serveur** : joueurs, staff, durée de fonctionnement, Discord, règles.
- **Réglages** : masquer le HUD.

Réglages dans `config.lua` : touche, raccourcis (les commandes inexistantes sont masquées automatiquement), activités (coordonnées GPS à adapter), règles.
Le style vient de `pickax_theme/design.css` (système de design commun) et de la couleur du serveur (`pickax_core/config.lua` → `AccentColor`).
`ensure pickax_theme` doit démarrer avant (c'est déjà le cas dans `resources.cfg`).
