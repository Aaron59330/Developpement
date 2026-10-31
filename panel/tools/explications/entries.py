# -*- coding: utf-8 -*-
# Textes d'explication de chaque script de la base (écrits à la main). Régénérer la page : python3 tools/explications/build.py
# E(id, nom, catégorie, niveau, en_une_phrase, ce_que_ça_fait, si_on_le_retire, où_le_régler, page_du_panel, dépendances)
# niveaux : essentiel · utile · facultatif · inutile · desactive
ENTRIES = []
def E(id, name, cat, level, short, what, without='', config='', panel='', deps=''):
    ENTRIES.append(dict(id=id, name=name, cat=cat, level=level, short=short, what=what, without=without, config=config, panel=panel, deps=deps))

F='Fondations (le serveur ne démarre pas sans)'
I='Interface et ressenti du joueur'
S='Outils du staff et gestion du serveur'
B='Builders : tout créer en jeu'
G='Gameplay et vie du serveur'
T='Téléphone, économie et boutique'
C='Modules internes de pickax_core'
D='Désactivés, tests et inutiles'

# ───────── Fondations ─────────
E('[essential]/es_extended','es_extended (ESX)',F,'essentiel','Le framework du serveur : joueurs, argent, métiers, inventaires, commandes de base.',
  'ESX Legacy est la « boîte à outils » sur laquelle tous les scripts s\'appuient : il gère le personnage (argent liquide, banque, argent sale), le métier et le grade, le groupe staff (user, admin, superadmin), la sauvegarde en base et les commandes de base (/clear, /coords, /noclip, /job, /info…).',
  'Rien ne fonctionne : tous les scripts de la base en dépendent.','es_extended/config.lua (comptes, sauvegarde, logs)','','oxmysql, ox_lib')
E('[essential]/oxmysql','oxmysql',F,'essentiel','Le pont entre le serveur et ta base de données MySQL / MariaDB.',
  'Chaque script qui lit ou écrit en base (personnages, véhicules, gangs, carnet…) passe par oxmysql. Il utilise la ligne mysql_connection_string du server.cfg.',
  'Plus aucune sauvegarde : le serveur ne peut même pas charger les personnages.','server.cfg → set mysql_connection_string "…"','')
E('[essential]/ox_lib','ox_lib',F,'essentiel','Bibliothèque d\'outils partagée (menus, notifications, barres de progression, zones, callbacks).',
  'Fournit des fonctions que plusieurs scripts utilisent : lib.callback (appeler le serveur depuis le client), les zones, les menus contextuels, les barres de progression, les commandes (lib.addCommand).',
  'ox_inventory et plusieurs builders ne démarrent plus.','server.cfg → setr ox:locale "fr"','')
E('[inventaire]/ox_inventory','ox_inventory',F,'essentiel','L\'inventaire : objets, armes, coffres, sol, boutiques, tenue complète.',
  'Gère tout ce que le joueur porte : cases, poids, objets empilables, armes, coffres de véhicules, coffres de jobs, ramassage au sol. Son interface a été refaite dans le style de la base (cases, filtres, glisser la tenue sur le personnage). Commandes staff : /additem, /removeitem, /setitem, /clearinv, /viewinv…',
  'Plus d\'inventaire ni d\'objets : le serveur est injouable.','server.cfg (inventory:slots, inventory:weight, flou) · ox_inventory/data/items.lua','Gestion Base → réglages Interface (flou) · Éditeur de base (objets)','ox_lib, oxmysql, es_extended')
E('[inventaire]/p_bridge','p_bridge (pScripts Bridge)',F,'utile','Pont de compatibilité utilisé par les scripts de vêtements d\'inventaire.',
  'Bibliothèque commerciale pScripts : elle fait le lien entre p_itemclothes / p_outfits et le framework (ESX), l\'inventaire, les notifications et les menus de vêtements. Aucune fonction visible seule (juste /setup réservé au staff pour placer un PNJ).',
  'p_itemclothes et p_outfits ne démarrent plus.','p_bridge/config.lua','','')
E('[inventaire]/p_itemclothes','p_itemclothes (vêtements en objets)',F,'utile','Transforme les vêtements en objets d\'inventaire.',
  'Chaque pièce (haut, bas, chaussures, accessoires…) devient un objet que tu peux ranger, prêter, donner ou équiper depuis l\'inventaire. Commande /pedfix pour réparer l\'apparence si le personnage bug.',
  'Les vêtements ne sont plus des objets : la case Tenue de l\'inventaire cesse de marcher.','p_itemclothes/config.lua','','p_bridge, ox_inventory')
E('[inventaire]/p_outfits','p_outfits (tenues complètes)',F,'utile','Un objet « Tenue » contient un look entier ; on le glisse sur le personnage pour s\'habiller d\'un coup.',
  'Dans l\'inventaire, tu glisses l\'objet Tenue sur ton personnage : les 14 emplacements de vêtements prennent toutes les pièces de la tenue. Glisser de nouveau retire tout.',
  'Plus de tenues complètes ; les pièces séparées restent utilisables.','p_outfits/config.lua','','ox_inventory, p_itemclothes, ox_lib')
E('[script]/pma-voice','pma-voice',F,'essentiel','Le chat vocal de proximité et les radios.',
  'Les joueurs parlent avec le micro : la voix porte jusqu\'à une certaine distance (chuchoter, normal, crier). Commandes : /cycleproximity (changer la portée), /vol (volume), /setvoiceintent. Les distances se règlent dans Gestion Base → Voix.',
  'Plus de voix en jeu.','pma-voice/shared.lua','Gestion Base → Voix','')
E('[script]/pickax_theme','pickax_theme',F,'essentiel','L\'identité commune : couleur principale, logo, nom du serveur et style des interfaces.',
  'Chaque interface charge ce petit script pour connaître la couleur principale et le logo du serveur. Quand tu changes la couleur dans le panel, c\'est lui qui la distribue à tous les menus. Il contient aussi les polices et le style Piñata. Il doit démarrer AVANT les autres ressources.',
  'Les menus perdent la couleur du serveur et le logo.','pickax_core/config.lua (AccentColor, ServerName, ServerLogo…)','Gestion Base → Couleurs & logos','')
E('[script]/pickax_core','pickax_core (le cœur de la base)',F,'essentiel','La plus grosse ressource : une centaine de petits systèmes (menus staff, émotes, boutique, prison, portes…).',
  'Regroupe en un seul endroit tous les systèmes « de base » du serveur. Ils sont détaillés plus bas, un par un, dans la catégorie « Modules internes de pickax_core ». Elle contient aussi l\'écran de chargement et la configuration d\'identité du serveur (config.lua).',
  'La moitié des fonctions de la base disparaît (menus, émotes, bans, prison, chargement…).','pickax_core/config.lua et config_sv.lua','Gestion Base (presque tout)','es_extended, oxmysql, ox_lib')
E('[script]/pickax_ui','pickax_ui',F,'essentiel','Affiche tous les menus (F5, menus de jobs, de gangs…) dans le style de la base.',
  'Remplace l\'affichage d\'origine des menus par une interface moderne : style Doré, Noir, Verre, Clair, Néon… Le joueur choisit son style dans le menu personnel (F5).',
  'Les menus reviennent à l\'ancien rendu ou ne s\'affichent plus.','Menu personnel (F5) de chaque joueur','Gestion Base → Couleurs & logos (style par défaut)','pickax_theme')
E('[script]/esx_identity','esx_identity',F,'essentiel','La création du personnage : prénom, nom, date de naissance, taille, point d\'arrivée.',
  'Quand un nouveau joueur arrive, ouvre l\'écran d\'identité (via pickax_creator), enregistre le personnage en base, puis propose les points d\'apparition. Commande /register pour refaire son identité si autorisé.',
  'Plus de création de personnage : un joueur sans identité ne peut pas jouer.','esx_identity/config.lua (Destinations = points d\'apparition par défaut)','Gestion Base → Parcours d\'arrivée','es_extended, pickax_creator')
E('[script]/pickax_creator','pickax_creator',F,'essentiel','Les écrans plein format de l\'arrivée : identité, apparence, point d\'apparition, bienvenue, animations.',
  'Chaque écran est un grand menu avec musique, images de fond et décor. Tout se règle dans le panel : textes, images, lieux d\'apparition, musique, coordonnées du studio. Commande /creatortest pour les prévisualiser en jeu.',
  'Retour aux anciens menus de création.','pickax_creator/config.lua (valeurs par défaut)','Gestion Base → Parcours d\'arrivée','pickax_theme, esx_identity, pickax_panel (pour la config du panel)')
E('[system]/basicEvent','basicEvent',F,'essentiel','Gère le chat, l\'apparition du joueur et la protection d\'hôte (spawnmanager).',
  'Reprend les ressources de base de FiveM (chat, spawnmanager, hostlock) en une seule : le chat affiche les messages, le joueur apparaît à la caméra de départ (config.lua : Spawncam), et le blocage d\'hôte empêche qu\'un joueur devienne hôte. Il garde l\'écran de chargement actif jusqu\'à ce que le serveur le ferme.',
  'Plus de chat ni d\'apparition correcte du joueur.','basicEvent/config.lua (Spawncam)','','')
E('[system]/[builders]','[builders] (webpack, yarn)',F,'utile','Outils de compilation pour les ressources qui contiennent du JavaScript.',
  'FiveM a besoin de « yarn » et « webpack » pour construire certaines ressources (oxmysql, interfaces React). Ce sont les builders officiels, sans aucune fonction visible en jeu.',
  'Les ressources qui se compilent (ex : compteur de vitesse) peuvent ne plus se construire.','','')

# ───────── Interface ─────────
E('[dev]/pickax_notify','pickax_notify',I,'essentiel','Les petites notifications à l\'écran.',
  'Remplace les notifications d\'ESX : cartes sombres avec barre de temps. Compatible ShowNotification, ShowAdvancedNotification et ShowHelpNotification. Commandes de test : /testnotif, /testadvancednotif, /testhelpnotif.',
  'Plus de messages à l\'écran.','pickax_notify/config.lua','Gestion Base → Interface (position)','pickax_theme')
E('[dev]/pickax_hud1','pickax_hud1 (jauges)',I,'utile','Les jauges de vie, faim, soif et armure.',
  'Affiche les petits cercles de faim et de soif et la barre de vie en bas à gauche, le bandeau staff quand tu es en mode administration, et le message « Zone safe ».',
  'Le joueur ne voit plus sa santé ni sa faim.','pickax_hud1/config.lua','Gestion Base → Interface (HUD)','es_extended')
E('[dev]/pickax_hud2','pickax_hud2 (cartes en haut à droite)',I,'utile','Les cartes d\'information : serveur, métier, argent.',
  'En haut à droite : le nom du serveur et le nombre de joueurs, ton métier, et ton argent liquide / sale / banque. Commandes : /progress (barre de progression de test), /smsg (message du staff).',
  'Plus de cartes d\'information.','pickax_hud2/html','Gestion Base → Interface (cartes)','pickax_theme')
E('[dev]/pickax_compass','pickax_compass',I,'utile','La boussole : cap, rue et quartier.',
  'Une bande avec les points cardinaux, le cap en degrés, le nom de la rue et du quartier. Deux formats : compacte (en bas à gauche) ou grande bande en haut. Commande /boussole pour la masquer ou l\'afficher.',
  'Plus de boussole.','pickax_compass/config.lua','Gestion Base → Interface (Boussole)','')
E('[dev]/pickax_speedometer','pickax_speedometer',I,'utile','Le compteur de vitesse du véhicule.',
  'Affiche vitesse, carburant, état du moteur et des phares quand tu conduis. Se cache automatiquement quand l\'inventaire ou le menu pause est ouvert.',
  'Plus de compteur dans les véhicules.','pickax_speedometer/web','','')
E('[dev]/pickax_dialog','pickax_dialog',I,'utile','Le dialogue avec un PNJ avant d\'ouvrir un service.',
  'Quand tu t\'approches d\'un PNJ (fourrière, location…), il se tourne vers toi et affiche un texte avec « Accepter / Refuser » avant d\'ouvrir le service. Utilisé par les builders.',
  'Les PNJ de services ouvrent directement le menu sans dialogue.','pickax_dialog/config.lua','','')
E('[dev]/pickax_keybinds','pickax_keybinds',I,'facultatif','« Mes touches » : la liste des raccourcis de la base.',
  'Affiche en direct toutes les touches du serveur avec celle réellement attribuée au joueur, détecte les conflits et explique comment les changer. Commande /touches.',
  'Le joueur n\'a plus cette aide ; les touches fonctionnent toujours.','pickax_keybinds/config.lua','','')
E('[dev]/pickax_tutorial','pickax_tutorial',I,'facultatif','Le tutoriel d\'arrivée.',
  'Un guide en plusieurs étapes (touches, téléphone, métiers, règles) montré une seule fois à un nouveau joueur, avec une récompense à la fin. Commandes : /tutoriel (le revoir), /tutorielreset <id> (staff : le remettre à zéro).',
  'Les nouveaux joueurs n\'ont plus de guide.','pickax_tutorial/config.lua','','')
E('[dev]/pickax_carnet','pickax_carnet (touche F3)',I,'facultatif','Le carnet du joueur : série de connexion, objectifs du jour, défi de la ville.',
  'Chaque jour : une série de connexion avec récompense croissante (jusqu\'au jour 7), 3 objectifs (facile, moyen, difficile), un objectif de la semaine et un défi collectif pour toute la ville, avec bonus si la ville réussit. Mis à jour en direct. Commande /carnet (staff : /carnetreset pour tester).',
  'Plus de récompenses quotidiennes.','pickax_carnet/config.lua','Gestion Base → Carnet','oxmysql, es_extended')
E('[dev]/pickax_casino','pickax_casino',G,'facultatif','Le casino : caisse de jetons, machines à sous, blackjack et roulette.',
  'Les joueurs achètent des jetons à la caisse (prix configurable, rachat à 95 % par défaut : la caisse garde 5 %), puis jouent aux machines à sous (3 gammes, 5 lignes, retour d\'environ 95 %), au blackjack (paie 3 pour 2, le croupier tire jusqu\'à 17, doubler possible) et à la roulette européenne (plein, rouge/noir, pair/impair, douzaines, colonnes). Tout le hasard et tous les gains sont calculés côté serveur, avec vérification de la distance et une seule action à la fois par joueur. Les postes (caisse, machines, tables) se placent dans le World Builder, type « Casinos » : position, PNJ, blip, repère au sol, gamme de chaque poste, prix des jetons. /casinortp affiche le retour théorique des machines et /casinostats le bénéfice de la maison (staff). Webhook Discord optionnel pour les gros gains.',
  'Plus de casino ; les jetons déjà achetés restent en base (table casino_wallets).','pickax_casino/config.lua (rouleaux, gains, limites de mise par gamme) et World Builder → Casinos (prix des jetons, emplacements)','Gestion Base → Tous les réglages des scripts','oxmysql, es_extended, pickax_worldbuilder')
E('[dev]/pickax_weaponcarry','pickax_weaponcarry',I,'facultatif','Les armes portées sont visibles sur le personnage.',
  'Dos, ceinture, cuisse, poitrine, cheville ou cachée : le joueur choisit où chaque arme est portée et le style de visée (menu contextuel ALT → clic sur soi). /wctune est un outil de réglage pour développeur.',
  'Les armes sont invisibles quand elles ne sont pas en main.','pickax_weaponcarry/config.lua','','ox_inventory')
E('[dev]/pickax_carplay','pickax_carplay',I,'facultatif','L\'autoradio de véhicule.',
  'Écoute de YouTube, de liens directs ou de radios dans un véhicule, avec file d\'attente et son synchronisé pour les passagers. Commande /carplay ; /carplaydebug pour diagnostiquer.',
  'Plus d\'autoradio.','pickax_carplay/config.lua','','')
E('[dev]/pickax_boutique','pickax_boutique',T,'utile','La boutique à coins (véhicules, armes, caisses, packs).',
  'L\'interface moderne de la boutique en jeu : le joueur dépense ses coins (achetés via Tebex) pour des véhicules, motos, armes, caisses mystère, packs et entreprises, utilise des codes promo et de parrainage, et tourne chaque jour la Roulette du jour (petits gains : coins, argent, objets). L\'achat lui-même est géré dans pickax_core (players/boutique).',
  'Plus de boutique à coins (les achats Tebex ne servent plus).','pickax_core/config.lua (TebexStore)','','pickax_core')

# ───────── Staff ─────────
E('[dev]/pickax_panel','pickax_panel',S,'essentiel','La liaison entre ton serveur et le panel web.',
  'Toutes les 10 secondes, envoie l\'état du serveur (joueurs, ressources, logs) et reçoit ce que tu as réglé dans le panel (thème, réglages, bans, whitelist, parcours d\'arrivée…). Contient aussi l\'éditeur de fichiers et la console du panel. Commande joueur : /plainte <id> <message>.',
  'Le panel ne contrôle plus le serveur (rien n\'est perdu, mais plus rien ne se règle à distance).','pickax_panel/config.lua · server.cfg (aero_panel_url, aero_panel_key)','Clé AERO','oxmysql')
E('[dev]/pickax_settings','pickax_settings',S,'essentiel','Les réglages du serveur modifiables depuis le panel.',
  'Définit environ 230 réglages (maintenance, annonces, météo, combat, voix, économie, gangs, drogues…). Un réglage ne change rien tant qu\'il n\'est pas modifié dans le panel.',
  'La page « Gestion Base » n\'a plus de réglages à afficher.','pickax_settings/config.lua','Gestion Base (toutes les catégories)','pickax_panel')
E('[dev]/pickax_basetools','pickax_basetools (/aerotools)',S,'utile','Les outils de la base : diagnostic de santé, sauvegarde des builders, thème et chargement.',
  'Audit de santé (ressources, SQL, objets manquants), sauvegarde / restauration de la configuration des builders, écriture du thème et de l\'écran de chargement. Commande /aerotools (staff).',
  'Plus d\'audit ; le panel ne peut plus appliquer le thème.','pickax_basetools/config.lua · server.cfg (add_filesystem_permission …)','Gestion Base → Couleurs & logos','pickax_core')
E('[dev]/pickax_builderhub','pickax_builderhub (/builders)',S,'utile','Le tableau de bord qui regroupe tous les builders.',
  'Une seule porte d\'entrée (/builders) pour ouvrir les builders de jobs, gangs, boutiques, monde, événements, mini-jeux, avec leur état et leurs statistiques.',
  'Il faut ouvrir chaque builder avec sa propre commande.','pickax_builderhub/config.lua','','')
E('[dev]/pickax_anticheat','pickax_anticheat',S,'utile','L\'anti-triche : détections côté serveur et panneau de gestion.',
  'Détecte des comportements suspects (vitesse, téléportation, armes, explosions…), donne un score par module et permet au staff de voir les détections et gérer les bans depuis un panneau. Commandes /ac et /anticheat.',
  'Plus de détection automatique de triche.','pickax_anticheat/config.lua','','')
E('[dev]/pickax_dlogs','pickax_dlogs',S,'facultatif','Les logs Discord par métier, gang, boutique et événement.',
  'Envoie des messages dans ton Discord (webhook) quand un événement important se produit. Le webhook et les informations envoyées se règlent dans chaque builder.',
  'Plus de logs Discord (rien d\'autre ne change).','Chaque builder → onglet Logs','Gestion Base → Discord')
E('[dev]/pickax_economy','pickax_economy',T,'utile','L\'économie dynamique : les prix bougent selon l\'offre et la demande.',
  'Les prix et les gains varient selon l\'activité du serveur, puis reviennent peu à peu à la normale. Possibilité de déclencher des événements économiques depuis le panel, et de choisir un type d\'économie (équilibrée, réaliste, abusée).',
  'Les prix restent fixes.','pickax_economy/config.lua','Gestion Base → Économie','')

# ───────── Builders ─────────
E('[dev]/pickax_jobbuilder','pickax_jobbuilder (/jobbuilder)',B,'essentiel','Crée n\'importe quel métier en jeu : grades, garages, vestiaires, coffres, boss, boutiques.',
  'Le plus gros builder : tu définis un job (police, EMS, mécanicien…), ses grades et salaires, ses points (garage, vestiaire, armurerie, coffre, gestion boss) et ses actions. Le menu métier s\'ouvre avec F6 (/jobmenu). Contient aussi les services publics (/revive, /appel, /panic), les annonces d\'entreprise et plusieurs mini-missions.',
  'Plus de métiers créés en jeu.','pickax_jobbuilder/config.lua','Gestion Base → réglages','es_extended, oxmysql, ox_lib')
E('[dev]/pickax_gangbuilder','pickax_gangbuilder (/gangbuilder)',B,'essentiel','Crée des gangs complets : grades, coffre, garage, territoires, guerres.',
  'Un gang a ses grades, sa trésorerie (argent propre et sale), ses points, ses territoires à capturer, sa tablette (/gangtablet), son menu (F7), ses guerres, ses saisons, son QG, ses tags, ses convois.',
  'Plus de gangs.','pickax_gangbuilder/config.lua','Gestion Base → Gangs & territoires','es_extended, oxmysql')
E('[dev]/pickax_shopbuilder','pickax_shopbuilder (/shopbuilder)',B,'essentiel','Crée n\'importe quelle boutique : supérette, armurerie, vêtements, pharmacie, marché noir.',
  'Tu poses un PNJ et tu choisis ce qu\'il vend et à quel prix. /clothshots est un outil de développeur pour photographier les vêtements.',
  'Plus de boutiques créées en jeu.','pickax_shopbuilder/config.lua','Gestion Base → Boutiques en jeu (produits, prix, stocks, emplacements, vendeur, carte)','es_extended, ox_inventory')
E('[dev]/pickax_worldbuilder','pickax_worldbuilder (/worldbuilder)',B,'essentiel','Crée le monde : garages, fourrières, locations, stations essence, portes, assurances.',
  'Le builder du décor interactif : garages publics et privés, fourrières, locations de véhicules, stations essence, portes verrouillables (/wbdoor), assurance véhicule (/assurance, /assurer) et plus de 10 grands menus.',
  'Plus de garages ni de fourrières créés en jeu.','pickax_worldbuilder/config.lua','','es_extended, oxmysql')
E('[dev]/pickax_illegalbuilder','pickax_illegalbuilder (/illegalbuilder)',B,'essentiel','Le monde illégal : drogues, blanchiment, braquages, police, justice, prison.',
  'Filières de drogue complètes (récolte, laboratoire, vente), blanchiment, braquages, et tout ce qui répond : perquisitions, saisies, prison, caution, évasion, procès, avocats, informateurs, planques, marché noir à rotation, contrats de livraison.',
  'Plus de filières illégales ni de système judiciaire.','pickax_illegalbuilder/config.lua','Gestion Base → Drogues & labos','es_extended, oxmysql')
E('[dev]/pickax_eventbuilder','pickax_eventbuilder (/eventbuilder)',B,'utile','Crée et lance des événements : fourgon blindé, largage, livraison illégale.',
  'Tu configures un événement, tu le lances pour tous ou à heure fixe. /eventstop (staff) arrête tous les événements en cours.',
  'Plus d\'événements automatiques.','pickax_eventbuilder/config.lua','','')
E('[dev]/pickax_minigames','pickax_minigames (/minigames)',B,'facultatif','Crée des mini-jeux : basket, football, tennis, boxe, paintball, courses.',
  'Chaque mini-jeu a un lobby, des scores et des récompenses. /minigames_leave (touche END par défaut, modifiable) pour quitter une partie ; /mgprofil montre ton profil ; /mgseed (staff) crée les mini-jeux d\'exemple.',
  'Plus de mini-jeux.','pickax_minigames/config.lua','','')
E('[dev]/pickax_auction','pickax_auction (/encheres)',T,'facultatif','L\'hôtel des ventes : enchères entre joueurs.',
  'Les joueurs mettent en vente objets et véhicules ; l\'argent et l\'objet sont mis en dépôt sécurisé jusqu\'à la fin, avec achat immédiat possible.',
  'Plus d\'enchères entre joueurs.','pickax_auction/config.lua','','oxmysql')
E('[dev]/pickax_bourse','pickax_bourse (/bourse)',T,'facultatif','La bourse : des actions fictives dont le prix évolue.',
  'Les prix montent et baissent (marche aléatoire + actualités), le joueur achète, vend et suit son portefeuille et ses plus-values.',
  'Plus de bourse.','pickax_bourse/config.lua','','oxmysql')
E('[dev]/pickax_phone','pickax_phone (téléphone Aero)',T,'utile','Le smartphone : appels, messages, réseaux, banque, crypto.',
  'Un téléphone complet avec appels vocaux, messages, réseaux sociaux, banque, crypto, loto, groupes de discussion. Commande /phone ; staff : /phone_give, /phone_number, /phone_reset, /phone_verify, /phone_lotodraw, /phone_dclog, /phone_dcclose. Peut se plier en grand écran.',
  'Plus de téléphone (ne pas lancer avec LB Phone).','pickax_phone/config.lua (touche par défaut : F12)','','oxmysql, es_extended')

# ───────── Désactivés ─────────
E('[disabled]/surge_puff','surge_puff (Puff Bar)',D,'desactive','Un objet « puff » (cigarette électronique) avec animations et fumée.',
  'Ressource désactivée : le serveur est obfusqué (illisible), donc impossible à auditer. Elle ne démarre pas. À ne réactiver que si le code source clair est fourni.',
  'Rien : elle n\'est pas lancée.','[disabled]/LISEZMOI.txt','')
E('[dev]/pickax_hud2/ruidebdv','pickax_hud2 / ruidebdv.lua',D,'inutile','Petit fichier annexe du HUD (décor de la carte d\'information).',
  'Fichier inclus dans pickax_hud2 : il n\'a pas de commande propre et ne sert qu\'au rendu des cartes. Tu n\'as pas à y toucher.','','')

# ───────── Modules internes de pickax_core ─────────
PC='pickax_core/'
def P(sub, name, level, short, what, without='', config=''): E(PC+sub, name, C, level, short, what, without, config or 'pickax_core/'+sub+'/config.lua')
P('modules/connectui','Écran de connexion','utile','L\'écran affiché pendant la connexion d\'un joueur.','Gère les messages de connexion (file d\'attente, vérifications) avant l\'arrivée en jeu. Désactivable avec set pickax:disable_modules "connectui".','Les joueurs voient l\'écran FiveM par défaut.')
P('loading','Écran de chargement','essentiel','L\'écran vu pendant le chargement du jeu.','Fond, musique, boutons Règlement / Discord / Boutique, équipe, mises à jour, barre de progression. Entièrement réglable depuis le panel.','Écran de chargement FiveM par défaut.','pickax_core/loading/loading.json')
P('menu/RageUI','RageUI (moteur de menus)','utile','L\'ancien moteur de menus utilisé par de nombreux menus.','Bibliothèque qui dessine les menus à listes (menu staff, menu personnel, émotes…). pickax_ui la remplace par un rendu moderne.','Les menus qui s\'en servent ne s\'affichent plus.','')
P('functions','Fonctions communes','utile','Fonctions partagées : carburant, chargement d\'animations…','Contient SetFuel / GetFuel (compatible ox_fuel / LegacyFuel) et des aides utilisées par les autres modules.','Plusieurs modules affichent des erreurs.')
P('init','Initialisation','essentiel','Prépare le joueur, ESX et les événements sécurisés.','Définit les outils partagés par tous les modules : classe du joueur (ped, véhicule), envoi d\'événements sécurisés, expulsion en cas d\'action suspecte.','Aucun module ne démarre.','')
P('compat','Compatibilité ox_inventory','essentiel','Relie les anciens menus de coffre aux inventaires ox.','Remplace le coffre de véhicule historique par le coffre natif d\'ox_inventory.','Les coffres de véhicule ne s\'ouvrent plus.','')
P('hudmap','Minimap et inventaire','facultatif','Masque la minimap quand l\'inventaire est ouvert.','Petit confort visuel.','La minimap reste visible sous l\'inventaire.','')
P('chat','Thème du chat','facultatif','Les couleurs du chat aux couleurs du serveur.','Feuille de style du chat.','Le chat garde ses couleurs d\'origine.','')
P('stream','Ressources de streaming','utile','Cartes, props et textures chargés dans le jeu.','Contient les minimaps personnalisées, les props d\'ATM, les émotes personnalisées et des textures de menu.','Textures ou props manquants.','')
P('dlc/bob74_ipl','Intérieurs (bob74_ipl)','utile','Active des lieux cachés du jeu (intérieurs, yacht, casino…).','Charge les IPL de GTA (intérieurs et décors) pour qu\'ils soient visibles.','Certains intérieurs restent fermés.','')
P('system/ban','Bans','essentiel','Le système de bannissement en base de données.','Commandes /sqlban (bannir), /sqlbanoffline (bannir quelqu\'un de déconnecté), /sqlunban (débannir). Réservé superadmin / dev.','Plus de bans par commande.')
P('system/cron','Tâches planifiées','utile','Exécute des actions à heure précise.','Petite horloge utilisée par d\'autres modules pour lancer des actions à une heure donnée.','Les actions planifiées ne se déclenchent plus.')
P('system/hardcap','Limite de joueurs','utile','Empêche de dépasser le nombre de places.','Refuse les connexions quand le serveur est plein, même si FiveM en laisse passer.','Plus de limite stricte.')
P('system/vsync','Météo et heure synchronisées','utile','Même heure et même météo pour tout le monde.','Commandes staff : /weather, /time, /morning, /noon, /evening, /night, /freezetime, /freezeweather, /blackout (panne de courant), /realtime (heure réelle), /meteoinfo (diagnostic).','Chacun voit une météo différente.')
P('utils/admin','Outils admin','utile','Fonctions du menu staff : téléportation, soin…','Fournit les actions de base du menu staff (téléportation au marqueur, soigner, etc.).','Certaines actions du menu staff ne marchent plus.')
P('utils/blips','Blips','utile','Les icônes sur la carte.','Crée les blips des lieux du serveur avec les réglages globaux (taille, couleur).','Plus de blips.')
P('utils/chattheme','Couleur du chat','facultatif','Applique la couleur du serveur aux messages du chat.','Les messages du serveur prennent la couleur principale.','Messages du chat sans couleur du serveur.','')
P('utils/discord','Statut Discord','facultatif','Le statut sur le profil Discord des joueurs.','Affiche « Joue à … » avec le nombre de joueurs et les boutons Discord / Connexion.','Plus de statut Discord.')
P('utils/gifMenu','Bannière des menus','facultatif','La bannière animée en haut des menus.','Affiche l\'image / GIF d\'en-tête des anciens menus.','Les menus perdent leur bannière.')
P('utils/globalstyle','Style global','utile','Expose la couleur, les markers et les blips à toutes les ressources.','Les builders lisent ici la couleur principale et le type de marker.','Les builders perdent la couleur du serveur.','')
P('utils/holograms','Textes 3D','facultatif','Des textes flottants dans le monde.','Affiche des écriteaux 3D à des coordonnées définies.','Plus de textes flottants.')
P('utils/livetheme','Thème en direct','utile','Applique le thème du panel sans redémarrage.','Lit les réglages faits dans le panel et les applique à la configuration en mémoire.','Le thème du panel ne s\'applique plus en direct.','')
P('utils/npc','Réglages des PNJ','utile','Calme les PNJ (pas de récompenses, pas d\'armes lâchées).','Désactive la radio de police de GTA, les récompenses des véhicules et les armes lâchées.','PNJ plus agressifs et drops d\'armes.')
P('utils/vehicle','Véhicules','utile','Plaques uniques et confort de conduite.','Génère des plaques « ABC 123 » vérifiées en base, désactive le changement de place automatique.','Plaques en doublon.')
P('utils/weapon','Armes (weapons.meta)','utile','Réglages des armes du jeu.','Fichier de données qui modifie les armes.','Armes aux valeurs d\'origine.','')
P('esx/addonaccount','Comptes de société','utile','L\'argent des entreprises.','Compte bancaire partagé d\'un métier (trésorerie).','Plus de compte de société.')
P('esx/addoninventory','Inventaires de société','utile','Les objets stockés par un métier.','Coffre d\'objets partagés d\'une entreprise.','Plus de coffre de société.')
P('esx/basicneeds','Faim et soif','utile','Boire et manger.','Les objets consommables (pain, eau…) remplissent les jauges ; tout est décrit dans ConfigBasicNeeds.Consumables.','Plus de besoins vitaux.')
P('esx/billing','Factures','utile','Les factures entre joueurs et avec les métiers.','Un métier peut facturer un joueur, qui accepte et paie.','Plus de factures.')
P('esx/datastore','Magasins de données','utile','Stockage de données partagées.','Sert aux coffres et aux sociétés pour enregistrer des objets.','Coffres de sociétés cassés.')
P('esx/instance','Instances','utile','Isole un groupe de joueurs dans une bulle.','Permet à des joueurs d\'être seuls dans une zone (activités privées).','Certaines activités ne s\'isolent plus.')
P('esx/license','Licences','utile','Permis (conduite, armes).','Enregistre les permis des joueurs.','Plus de permis.')
P('esx/notify','Notifications ESX','essentiel','Branche ESX sur pickax_notify.','Redirige les notifications d\'ESX vers l\'affichage de la base.','Notifications cassées.','')
P('esx/optionalneeds','Besoins optionnels','facultatif','Besoins en plus de la faim et de la soif.','Réglages complémentaires d\'ESX pour d\'autres besoins.','Rien de visible.')
P('esx/rpchat','Chat RP','facultatif','Commandes de chat en rôle play.','Messages /me et /do au-dessus de la tête.','Plus de messages RP.')
P('esx/service','Prise de service','utile','Entrer / sortir de service.','Compte les joueurs en service dans un métier.','Plus de gestion de service.')
P('esx/skinchanger','Apparence et vêtements','essentiel','Change le visage, les vêtements et la coiffure.','Applique et sauvegarde l\'apparence. Commandes : /skin (staff), /tenueinfo (diagnostic).','Plus de personnalisation.')
P('esx/society','Sociétés','utile','Entreprises et leur gestion.','Trésorerie, coffre et gestion boss d\'une société.','Plus de gestion boss.')
P('esx/status','Statut du joueur','essentiel','Les états : faim, soif, stress, drogue…','Base des jauges. Commande /heal (staff).','Plus d\'états.')
P('players/ancre','Ancre de bateau','facultatif','Ancrer un bateau à l\'arrêt.','Quand tu conduis un bateau à faible vitesse, tu peux jeter l\'ancre.','Plus d\'ancre.')
P('players/anticarkill','Anti écrasement','utile','Un véhicule ne blesse plus un joueur à pied.','Supprime les dégâts de collision des véhicules sur les joueurs (anti « car kill »). Un réglage Collision permet aussi de retirer complètement la collision entre véhicules et joueurs.','Les joueurs peuvent être tués en étant renversés.')
P('players/armesperm','Armes permanentes','utile','Des armes rangées dans un coffre à ne pas perdre.','Coffre spécial pour garder des armes entre deux connexions.','Plus de coffre d\'armes permanent.')
P('players/ascenseur','Ascenseurs','facultatif','Des ascenseurs avec markers.','Téléporte entre étages à des coordonnées définies.','Plus d\'ascenseurs.')
P('players/boiteagant','Boîte à gants','utile','Le rangement de la boîte à gants.','Stocke des objets dans le véhicule, sauvegardés en cache.','Plus de boîte à gants.')
P('players/boutique','Boutique à coins','utile','Le système d\'achat avec coins.','Achat de véhicules, armes, caisses et packs avec la monnaie premium. Commandes staff : /giveboutiqueid, /giveid, /RemoveCoins, /menuboutique.','Plus de boutique à coins.')
P('players/camera','Caméra libre','facultatif','Une caméra mobile pour filmer ou observer.','Une caméra que l\'on déplace avec des touches (pivot, vitesse, distance maximale). Réservée au staff (permission AllowCam.Staff) et, si AllowPlayerAndStaff est vrai, aux joueurs.','Plus de caméra libre.')
P('players/cayoperico','Cayo Perico','utile','Charge l\'île de Cayo Perico.','Active les décors et la carte de l\'île. Commande /id.','L\'île est invisible.')
P('players/chargeur','Chargeurs','utile','L\'objet « chargeur ».','Utiliser un chargeur recharge l\'arme en main.','Plus de rechargement par objet.')
P('players/chasseautresor','Chasse au trésor','facultatif','Un événement de chasse au trésor.','Un trésor est caché ; le premier qui le trouve reçoit de l\'argent.','Plus de chasse au trésor.')
P('players/contextMenu','Menu contextuel (ALT)','essentiel','Le menu qui s\'ouvre en maintenant ALT et en cliquant.','Interagir avec un joueur, un véhicule ou un objet : donner, fouiller, vendre dans la rue, gérer ses armes… C\'est la plus grosse partie du jeu au quotidien.','Plus d\'interactions au clic.')
P('players/coords','Coordonnées','facultatif','Affiche tes coordonnées (staff).','/coords active l\'affichage de X, Y, Z et du cap pour placer des points.','Plus d\'affichage.')
P('players/craft','Craft','utile','Fabriquer des objets avec des ingrédients.','Récolte et fabrication à des points définis.','Plus de fabrication.')
P('players/deco','Joueur déconnecté','facultatif','Affiche qui vient de se déconnecter.','Un texte reste quelques secondes à l\'endroit où un joueur quitte.','Plus d\'affichage.')
P('players/distributeur','Distributeurs','facultatif','Les distributeurs (eau, soin).','Des distributeurs où le joueur paie quelques dollars (en liquide ou par la banque) pour boire ou se soigner.','Plus de distributeurs.')
P('players/doorsbuilders','Portes verrouillables','utile','Créer et verrouiller des portes.','Commandes staff /createdoor, /deletedoor ; /lockdoor (touche E) pour fermer / ouvrir.','Plus de portes verrouillées.')
P('players/douche','Douches','facultatif','Prendre une douche.','Des points de douche avec animation.','Plus de douches.')
P('players/drag','Traîner un joueur','utile','Emmener un joueur menotté ou blessé.','Le joueur est tiré par un autre en suivant ses mouvements.','Plus de traînage.')
P('players/gtao','HUD GTA Online','facultatif','Reprend le HUD de GTA Online (désactivé par défaut).','Le réglage Allow (config.lua) est sur false : le HUD GTA Online n\'est pas affiché. La commande /hidehud masque ou affiche le HUD d\'origine du jeu.','Rien de visible.')
P('players/gyropharePolice','Gyrophare police','utile','Gyrophares et sirènes.','Active les lumières et la sirène des véhicules d\'urgence avec les touches d\'aide à l\'écran.','Plus de gyrophares.')
P('players/jail','Prison (ancien)','utile','Envoyer un joueur en prison.','Menu de prison avec durée de peine (le nouveau système complet est dans illegalbuilder).','Plus de prison simple.')
P('players/jsfour-idcard','Carte d\'identité','utile','Montrer sa carte d\'identité.','Affiche la carte avec photo du personnage à un joueur proche, et gère permis de conduire et de port d\'arme.','Plus de cartes.')
P('players/ko','K.O. au combat','facultatif','Le coup de poing peut mettre K.O.','Un joueur frappé trop souvent s\'effondre quelques secondes.','Plus de K.O.')
P('players/logs','Logs de connexion','facultatif','Journal des connexions et morts.','Enregistre qui se connecte, se déconnecte et meurt.','Plus de journal.')
P('players/loteries','Loteries','facultatif','Des tickets de loterie.','Un tirage au sort avec gain ; message de félicitations.','Plus de loterie.')
P('players/me','Commande /me','facultatif','Texte d\'action au-dessus de la tête.','/me ouvre une phrase d\'action visible par les joueurs proches.','Plus de /me.')
P('players/menuadmin','Menu staff','essentiel','Le menu de l\'équipe d\'administration.','Gérer les joueurs (kick, spect, soin, TP), voir les reports, tchat staff. Commandes : /kick, /sc (chat staff), /spect, /repair, /setadmin (console). Gros fichier : c\'est la trousse à outils du staff.','Le staff perd ses outils.')
P('players/menuemote','Animations et émotes','utile','Le menu d\'animations (F3 / commande).','Des centaines d\'animations, favoris et raccourcis. Commandes : /e, /emote, /emotes, /emotemenu, /emoteui, /emotebind(s), /emotefav, /emotecancel, /nearby, /walk(s), /mood(s), /crouch, /crawl, /ragdoll, /handsup, /pointing.','Plus d\'animations.')
P('players/menupersonnel','Menu personnel (F5)','essentiel','Le menu personnel du joueur.','Inventaire, factures, préférences (style, couleur, taille, forme des boutons), documents, téléphone…','Le joueur n\'a plus de menu.')
P('players/needbag','Armes dans le dos','facultatif','Distingue armes grandes, petites et mêlée.','Aide le système d\'armes portées et le sac.','Armes mal affichées.')
P('players/nemplayerhud','Protection nouveau joueur','utile','Protège les nouveaux joueurs.','Un nouveau est invulnérable aux armes pendant un moment.','Plus de protection.')
P('players/porterOtage','Porter et prendre en otage','utile','Porter un joueur ou le prendre en otage.','Commandes /porter et /otage (interdites en zone safe).','Plus de porter.')
P('players/radio','Radio','utile','La radio de communication.','Choisir une fréquence ; bascule avec la voix.','Plus de radio.')
P('players/ragdoll','Ragdoll','facultatif','Se mettre à terre sur commande.','La commande /ragdoll fait tomber le personnage.','Plus de ragdoll volontaire.')
P('players/safezone','Zones safe','utile','Zones où on ne peut pas se battre.','À l\'intérieur, impossible de sortir une arme ou de frapper. Les zones sont des coordonnées (hôpital, poste…).','Plus de zones safe.')
P('players/tacle','Plaquage','facultatif','Plaquer un joueur.','Tackle comme au rugby (touche configurable).','Plus de plaquage.')
P('players/tattoo','Tatoueur','facultatif','Tatouages.','Un menu de tatouages à acheter chez le tatoueur.','Plus de tatouages.')
P('players/telescopes','Télescopes','facultatif','Les télescopes du monde.','Regarder dans un télescope avec zoom aux points définis.','Plus de télescopes.')
P('players/token','Jeton de sécurité','essentiel','Un jeton qui protège les commandes sensibles.','Chaque joueur reçoit un jeton à la connexion ; les commandes staff le vérifient pour éviter les triches. Commande /NewToken.','Les commandes staff deviennent vulnérables.')
P('players/vehiclecoffre','Coffre de véhicule','utile','Le coffre des véhicules.','Ouvrir le coffre avec la touche L (commande /coffre).','Plus de coffre de voiture.')
P('players/vip','VIP','utile','Les niveaux VIP (bronze, argent, or).','Commandes staff /givevip, /removevip : le niveau est enregistré en base.','Plus de VIP.')
P('players/wipe','Remise à zéro','utile','Effacer un joueur ou le serveur.','Commande /Wipe réservée au staff haut gradé : supprime les données d\'un joueur.','Plus de wipe par commande.')
E('pickax_core/hidden','Autres fichiers de pickax_core','Modules internes de pickax_core','utile','Configuration et JSON de permissions.','config.lua (identité), config_sv.lua (serveur), maintenance.lua (mode maintenance), admin_permissions.json et admin_grade_styles.json (droits et styles des grades du staff), custom_admin_grades.json.','Droits staff perdus.','')
E('pickax_core/players/menuadmin_old','/menuadmin_old','Désactivés, tests et inutiles','inutile','Ancien menu staff conservé pour compatibilité.','La commande /menuadmin_old ouvre l\'ancienne version du menu staff. Le menu actuel est « menuadmin ».','Rien : tu peux l\'ignorer.','')
E('[dev]/pickax_notify/tests','Commandes de test des notifications','Désactivés, tests et inutiles','inutile','/testnotif, /testadvancednotif, /testhelpnotif.','Trois commandes pour vérifier l\'affichage des notifications. Elles ne servent qu\'à tester le design.','Rien.','')
E('pickax_core/system/hardcap-note','Commandes de diagnostic','Désactivés, tests et inutiles','inutile','/gbcheck, /jbcheck, /gbdebug, /jbdebug, /gbreset, /jbreset, /sbreset, /wbreset, /carplaydebug, /meteoinfo…','Ce sont des commandes de dépannage pour les développeurs : elles affichent des informations ou débloquent une interface bloquée. Un joueur normal n\'en a jamais besoin.','Rien.','')
E('[script]/pickax_creator/test','/creatortest','Désactivés, tests et inutiles','inutile','Prévisualiser les écrans de création en jeu.','/creatortest identity | skin | spawn | welcome | emotes | close permet de voir chaque écran sans créer un nouveau personnage.','Rien.','')
E('[dev]/pickax_tutorial/reset','/tutorielreset','Désactivés, tests et inutiles','inutile','Remettre le tutoriel d\'un joueur à zéro (staff).','Utile seulement pour tester le tutoriel.','Rien.','')
E('[dev]/pickax_carnet/reset','/carnetreset','Désactivés, tests et inutiles','inutile','Remettre à zéro sa série et ses objectifs du jour (staff).','Utile seulement pour tester le carnet.','Rien.','')
E('[dev]/pickax_weaponcarry/tune','/wctune','Désactivés, tests et inutiles','inutile','Outil de réglage des positions d\'armes.','Pour développeur : permet d\'ajuster à la main où une arme est portée.','Rien.','')
E('[dev]/pickax_worldbuilder/seed','Commandes /…seed et /…reset','Désactivés, tests et inutiles','inutile','/wbseed, /ibseed, /mgseed, /sbseed et /wbreset…','Les « seed » créent des exemples (modules, points, mini-jeux) pour démarrer ; les « reset » ferment une interface bloquée. Utiles une fois à l\'installation, ensuite inutiles.','Rien.','')
E('[dev]/pickax_hud2/smsg','/progress et /smsg','Désactivés, tests et inutiles','inutile','/progress : test de barre de progression ; /smsg : message du staff à un joueur.','/progress est un test de développeur ; /smsg envoie un message privé affiché à l\'écran.','Rien.','')
E('[essential]/ox_lib/zone','Commandes ox_lib','Désactivés, tests et inutiles','inutile','/zone, /ox_lib, /cancelprogress.','Outils de diagnostic d\'ox_lib. /cancelprogress annule une barre de progression bloquée.','Rien.','')
E('[inventaire]/p_bridge/setup','/setup (p_bridge)','Désactivés, tests et inutiles','inutile','Outil de configuration du pont pScripts.','Permet de placer un PNJ ou un point pour les scripts pScripts. Non utilisé ici.','Rien.','')
E('[dev]/pickax_casino/staff','/casinortp, /casinostats','Outils du staff et gestion du serveur','utile','Contrôler la rentabilité du casino (staff).','/casinortp affiche le taux de retour théorique des machines à sous ; /casinostats donne le nombre de parties et le bénéfice de la maison. Les postes se placent dans le World Builder.','Rien : le casino fonctionne sans.','')
