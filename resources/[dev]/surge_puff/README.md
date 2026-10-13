# Puff Bar : surge_puff 1.0.0

## Utilisation

1. Utiliser **Puff Bar** dans l’inventaire, ou saisir `/puff` en possédant cet objet : la puff se place dans la main, en position basse.
2. Appuyer sur **E** pour prendre une taffe. Le geste dure environ 6 secondes, puis la main revient en bas et la puff reste équipée.
3. Appuyer de nouveau sur **E** pour recommencer autant de fois que souhaité.
4. Réutiliser l’objet, saisir `/puff` ou `/puffstop` pour la ranger, y compris pendant une taffe.

Aucune charge, usure, consommation ni limite de taffes. Une pression déclenche un seul geste ; maintenir E ou appuyer pendant le geste ne met pas de taffes en attente. La seule attente est la fin du geste en cours.

Le personnage doit être un personnage multijoueur homme ou femme, vivant, à pied et sans arme en main. E est ignoré dans les menus et l’inventaire. La touche est modifiable dans les paramètres FiveM sous « Puff Bar : prendre une taffe ».

## Contenu et installation

La ressource est installée dans `surge_puff`. Elle contient la puff et son socle lumineux, les animations d’inhalation homme/femme et deux poses de tenue. La LED verte accompagne l’inhalation.

`surge_puff_facial.ycd` isole les pistes de mâchoire et de lèvres, lancées avec `PlayFacialAnim`. La lecture démarre à la même phase que le geste, y compris pour un spectateur arrivant en cours d’animation. Un court clip de repos referme la bouche au retour en tenue ou en cas d’interruption.

La fumée est un **seul** effet particulaire loopé sur l’os bouche (module local dans `client/main.lua`), actif entre `Smoke.startPhase` et `Smoke.endPhase`. Pas de rafales ni d’UI de réglage. `asset` / `effect` dans `shared/config.lua` sont interchangeables (placeholder actuel : expiration cigarette ; à remplacer par un `.ypt` custom).

L’identifiant de l’objet reste **puff** ; son nom affiché est **Puff Bar**. Il est défini dans `resources/[gameplay]/[inventaire]/ox_inventory/data/items.lua`, avec `consume = 0` et l’export `surge_puff.usePuff`. L’icône est servie par cette ressource.

`ensure surge_puff` est placé après `ensure ox_inventory` dans `server_resources.cfg`. Ne pas démarrer en parallèle les anciennes ressources de test Puff_FiveM : leurs modèles et dictionnaires portent les mêmes noms.

## Synchronisation et nettoyage

Le serveur vérifie la possession de l’objet et l’état du joueur à l’équipement et à chaque demande de taffe. Il empêche la superposition des gestes. Chaque session d’équipement possède un identifiant vérifié ; un joueur ne peut pas arrêter la session d’un autre.

Les spectateurs du même routing bucket affichent localement les props à moins de 35 mètres, en suivant la progression de l’animation répliquée. Le serveur ne lance pas d’animation sur les personnages d’autres clients.

La puff est rangée à la mort, en véhicule, en ragdoll, lors d’une prise d’arme, d’un changement de personnage ou de bucket du porteur, à la perte de l’objet, à l’interruption de la pose par une autre animation, à la déconnexion ou à l’arrêt de la ressource.

## Coût d’exécution

La touche utilise le système de raccourcis ox_lib. Aucun thread de suivi ne subsiste quand aucune puff n’est équipée. Un seul suivi serveur contrôle les sessions actives chaque seconde. Les clients espacent leurs vérifications de 150 ms en tenue visible à 500 ms hors zone ; le suivi par image est réservé au geste du porteur et à la LED.

## Vérification

`/puffdiag` reste disponible pour un diagnostic manuel. Valider en jeu homme/femme, sync spectateur, LED et contact embout.

## Réglages

`shared/config.lua` contient la touche, les commandes, les modèles, la distance, la fixation, la LED et la fumée (`Smoke`).

- [Objets ox_inventory](https://overextended.dev/docs/ox_inventory/Guides/creatingItems)
- [Raccourcis ox_lib](https://github.com/overextended/ox_lib/blob/main/imports/addKeybind/client.lua)


## Items a mettre dans le ox_inventory :

['puff'] = {
        label = 'Puff 60K',
        weight = 40,
        stack = false,
        close = true,
        consume = 0,
        description = 'Puff Bar. Utiliser pour la tenir, E pour une taffe, réutiliser ou /puffstop pour ranger.',
        client = {
            export = 'surge_puff.usePuff',
            image = 'nui://surge_puff/images/puff.png',
        },