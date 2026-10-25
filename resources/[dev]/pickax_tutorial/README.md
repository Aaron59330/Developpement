# pickax_tutorial — tutoriel d'arrivée

S'ouvre une seule fois pour un nouveau personnage (après la fin de la création (identité, apparence, choix de la destination)), puis à la demande avec `/tutoriel`.
Étapes, textes, touches et récompense : tout se règle dans `config.lua` (`{server}`, `{discord}` et `{command}` sont remplacés automatiquement).
La récompense (`Config.Reward`) est versée une seule fois, côté serveur, uniquement si le joueur va jusqu'au bout (pas s'il passe).
`/tutorielreset <id>` (admin ou console) remet le tutoriel à zéro pour un joueur. Table créée automatiquement : `pickax_tutorial`.
