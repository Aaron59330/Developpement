# Audit de la base AERO (31/10/2026)

Contrôles faits sur tout le dépôt : `server.cfg`, `resources.cfg`, les 48 ressources, les fichiers SQL, les outils et le panel.

## Résultat en une phrase
La base est cohérente : aucune erreur de syntaxe, aucune ressource manquante au démarrage, aucun secret dans le dépôt. Quelques éléments en trop ont été retirés et deux conflits de touches ont été réglés. Il reste des points à décider (ci-dessous).

## Ce qui a été vérifié (et est correct)
| Contrôle | Résultat |
|---|---|
| Syntaxe Lua des 643 fichiers du code maison (les fichiers des ressources tierces ESX / ox ont des extensions Lua propres à FiveM) | Aucune erreur |
| Syntaxe JavaScript des 84 fichiers d'interface | Aucune erreur |
| `fxmanifest.lua` : fichiers déclarés, `ui_page`, dépendances | Tout existe (seuls des motifs `*` vides sur des dossiers d'images facultatifs) |
| Ordre de démarrage (`resources.cfg`) : thème → chat → notifications → créateur → base de données → ESX → inventaire → identité → menus → core → voix → `[dev]` | Correct ; ESX dépend de `basicEvent` qui démarre avant |
| Tables SQL : `database.sql` (117 tables) + tables créées par le code (`CREATE TABLE IF NOT EXISTS`, `illegalbuilder/sql/install.sql`) | Aucune table manquante |
| Objets d'inventaire référencés par les configs | Tous définis dans `ox_inventory/data/items.lua` |
| Scan anti-backdoor (`tools/audit-backdoor`) | 1 alerte « critique » = `load()` du panel qui vérifie qu'un fichier Lua compile avant de l'enregistrer (légitime) ; 11 « à vérifier » = écritures de fichiers faites volontairement par le panel et les outils. Référence mise à jour. |
| Secrets (clés Discord, API, licences, mots de passe) dans le dépôt | Aucun |
| Pages du panel (client et admin) | Aucune erreur JavaScript, aucune page en doublon |

## Ce qui a été corrigé
1. **`server.cfg` remis au propre** : sections numérotées et commentées, étiquettes (tags) dédoublonnées (60 → 45), ligne `setr sv_type "FA"` retirée (utilisée par aucun script), valeurs fictives du CDN et de `sv_listingIpOverride` mises en commentaire (laissées actives, elles cassent la liste ou le CDN), exemple d'ajout d'un compte staff, `exec "resources.cfg"` placé en dernier.
2. **`resources.cfg`** : commentaires corrigés (le thème se règle dans le panel, `[mapping]` et `[vehicules]` sont à toi).
3. **Conflit de touche F1** : la boutique et le téléphone s'ouvraient en même temps. Le téléphone passe sur **F12** (`pickax_phone/config.lua`).
4. **Conflit de touche F9** : la radio et « quitter un mini-jeu ». Les mini-jeux passent sur **FIN** (`pickax_minigames/config.lua`).
5. **Conflit de touche F11** : le menu staff et le changement de portée de la voix. La voix passe sur **ORIGINE / HOME** (`setr voice_defaultCycle "HOME"` dans `server.cfg`).
6. **Retiré du dépôt** : `imageio_ffmpeg-…whl` (29 Mo, outil de montage vidéo), `tebex-theme.zip` (copie identique du dossier `tebex-theme/`), `resources/[essential]/async` (utilisé uniquement dans un bloc de code commenté). `*.whl` et `*.zip` sont maintenant ignorés par git.

> Les nouvelles touches ne s'appliquent qu'aux joueurs qui n'avaient pas déjà enregistré la touche d'origine (réglage FiveM propre à chaque joueur).

## À décider / à savoir (rien n'a été supprimé sans ton accord)
| Sujet | Détail | Conseil |
|---|---|---|
| **Données réelles dans l'historique git** | Le dump `sql.sql` (adresse du serveur MySQL, identifiants de joueurs) a été commité dans la première version (commit `24b401d`) avant d'être retiré. Il reste dans l'historique et sur GitHub. Le fichier local `sql.sql` est ignoré et jamais poussé. | Change le mot de passe MySQL (et idéalement purge l'historique ou rends le dépôt privé). |
| **Adresse IP du panel** | `server.cfg` contient `http://5.196.4.165:3000`. | Normal si le dépôt est privé ; sinon passe par un nom de domaine en https. |
| **`screenshot-basic` absent** | Le menu staff (capture d'écran vers Discord) et `/clothshots` en ont besoin. | Installe la ressource gratuite `screenshot-basic` si tu utilises ces fonctions ; sinon ignore l'erreur. |
| **`/coords` en double** | ESX et `pickax_core` déclarent tous deux cette commande. | Sans gravité (staff uniquement). |
| **Deux systèmes de prison** | `pickax_core/players/jail` (ancien menu simple) et `pickax_illegalbuilder` (nouveau : procès, caution, évasion, bracelets). | Garde le nouveau ; l'ancien reste utile pour une simple mise en cellule. |
| **Plusieurs bannissements** | `system/ban` (commandes SQL), bans du panel, anti-triche. | Normal : chacun a son rôle ; les bans du panel sont les plus simples à gérer. |
| **Quatre feuilles de style d'inventaire empilées** | `ui.css`, `ui-refonte.css`, `arcade.css`, `glass.css`. | Fonctionne ; à fusionner un jour pour alléger. |
| **Interrogation toutes les 4 s** | Chaque interface demande la forme des boutons choisie par le joueur (`pickax_ui/getShape`). | Négligeable, mais à surveiller si tu as beaucoup d'interfaces ouvertes. |
| **`docs/video` et `docs/apercu`** | 20 Mo d'images et d'une vidéo de présentation. | Utiles pour ta promotion, inutiles au serveur : à déplacer hors du dépôt si tu veux l'alléger. |
| **`surge_puff`** | Ressource désactivée dont le serveur est obfusqué (illisible). | Supprime-la tant que tu n'as pas le code source clair. |
| **`p_bridge`** | Pont multi-frameworks très volumineux pour seulement ESX + ox. | Sans danger ; ne le touche pas (il est sous licence pScripts). |
