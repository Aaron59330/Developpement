# Audit anti-backdoor

`node tools/audit-backdoor/scan.js` — analyse toutes les ressources (Lua / JS / HTML / JSON) et signale :
- **critique** : code exécuté depuis du texte reçu, exécution de commandes système, lecture de secrets (licence, MySQL, RCON), modification des droits ACE, requêtes vers un domaine inconnu, chaînes obfusquées ;
- **à vérifier** : écriture de fichiers de ressource, événements réseau au nom calculé, noms de variables illisibles, longues chaînes encodées, `eval` ;
- **info** : liens vers des domaines inconnus (lecture seule).

Options : `--min=high|medium|low`, `--json`, `--all` (affiche aussi les résultats déjà relus), `--update-baseline` (enregistre les résultats actuels comme relus dans `baseline.json`).

Utilisation conseillée : lance le scan **à chaque ajout ou mise à jour d'une ressource de tiers**. Seuls les nouveaux résultats s'affichent. Un résultat n'est pas une preuve : relis la ligne signalée avant de conclure. Un code vraiment obfusqué peut échapper à un scanner : compare les ressources de tiers avec leur version officielle.

Adapte la liste `OK_HOSTS` en tête de `scan.js` aux domaines que tu utilises réellement.
