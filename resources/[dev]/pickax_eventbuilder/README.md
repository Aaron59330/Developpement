# pickax_eventbuilder — Event Builder

Crée et lance des événements en jeu : `/eventbuilder` (ou depuis `/builders`). Réservé aux groupes `Config.AllowedGroups`.

| Type | Contenu |
|---|---|
| Fourgon blindé (Brinks) | fourgon (qui peut rouler), gardes armés, perçage des portes (objet requis optionnel), sacs de billets à ramasser derrière |
| Largage | caisses verrouillées quelques secondes, mercenaires, objets en butin |
| Commerce | menacer le vendeur (viser) → il vide la caisse, police prévenue |
| Épave | épave en flammes, caisses à fouiller, gardes |
| Livraison illégale | véhicule à récupérer puis livrer avant la fin du temps |
| Contrôle de zone | tenir une zone seul(e) assez longtemps |

Déclenchement : **Automatique** (planifié par `Config.Auto`), **Manuel** (bouton Lancer / onglet « En cours ») ou **Interaction** (commerce).
Chaque événement : lieux (tirés au hasard), policiers requis, délai de relance, récompense (argent / objets), alerte police, blip, annonces.
Tout est contrôlé côté serveur (distances, durées, objets, récompenses) ; table `eventbuilder_events` + historique `eventbuilder_logs` créés automatiquement.
Commande console : `eventstop` arrête tous les événements en cours.
