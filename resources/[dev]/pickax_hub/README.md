# pickax_hub — menu central du serveur

Une touche (**F1** par défaut, modifiable dans les raccourcis FiveM) ouvre un seul menu :
- **Accueil** : identité (nom, ID, heures de jeu), stats du personnage, portefeuille (liquide, banque, points boutique), accès rapide, entreprises actives (disponible si au moins un employé en ligne).
- **Vos factures** : factures en attente (table `billing`) avec paiement.
- **Vos véhicules** : liste (`owned_vehicles`) + « Localiser ».
- **Activités** : braquage, mini-jeux, événements, avec point GPS.
- **Serveur** : joueurs, staff, durée de fonctionnement, Discord, règles.
- **Réglages** : masquer le HUD.

Réglages dans `config.lua` : touche, raccourcis (les commandes inexistantes sont masquées automatiquement), activités (coordonnées GPS à adapter), règles.
Le style vient de `pickax_theme/design.css` (système de design commun) et de la couleur du serveur (`pickax_core/config.lua` → `AccentColor`).
`ensure pickax_theme` doit démarrer avant (c'est déjà le cas dans `resources.cfg`).

Onglets : Accueil · Vos factures · Vos véhicules · Vos propriétés (masqué tant que `Config.PropertiesQuery` n'est pas renseigné) · Activités · Serveur · Paramètres · Boutique.
