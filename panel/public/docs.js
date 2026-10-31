'use strict';
// ───────── Documentation : de l'installation à la configuration complète ─────────
// Contenu : tableau de sections { id, title, blocks }. Blocs : ['p', texte] ['h', titre] ['ul', [..]] ['ol', [..]] ['code', texte] ['note', texte] ['warn', texte] ['table', [en-têtes], [[lignes]]]
const DOCS = [
  { id: 'intro', title: 'Présentation', blocks: [
    ['p', 'La base AERO se compose de trois éléments qui travaillent ensemble :'],
    ['table', ['Élément', 'Rôle', 'Où'], [
      ['Panel web', 'Ce site : configuration du serveur, licences, images, textes, réglages, bans, sauvegardes.', 'Un VPS Linux (Node.js + SQLite), dossier panel/'],
      ['Serveur FiveM', 'Le jeu : ressources pickax_*, es_extended, ox_inventory, etc.', 'Ton serveur FXServer (dossier resources/)'],
      ['Base MySQL / MariaDB', 'Données des joueurs, véhicules, jobs, gangs, builders.', 'Ton hébergeur MySQL (chaîne mysql_connection_string)'],
    ]],
    ['p', 'Le serveur FiveM n\'ouvre aucun port vers le panel : la ressource pickax_panel appelle le panel toutes les 10 secondes avec la clé de licence, envoie l\'état du serveur et récupère les réglages modifiés. Les actions sont validées par le panel ET par la ressource (liste blanche).'],
    ['note', 'Ordre conseillé : 1) installer le panel, 2) installer la base FiveM, 3) relier les deux, 4) configurer depuis le panel.'],
  ] },
  { id: 'prerequis', title: 'Prérequis', blocks: [
    ['ul', [
      'Un VPS Linux (Ubuntu 24.04 recommandé) avec accès SSH pour le panel — environ 1 Go de RAM suffisent.',
      'Node.js 22 (installé à l\'étape 3 du panel), git, build-essential et python3 (pour compiler better-sqlite3).',
      'Un serveur FiveM (artefact récent), OneSync activé, une clé de licence Cfx.re (keymaster) dans sv_licenseKey.',
      'Une base MySQL / MariaDB (utilisateur, mot de passe, nom de base).',
      'Framework ESX Legacy (es_extended), oxmysql, ox_lib, ox_inventory, pma-voice : tous fournis dans resources/.',
      'Un navigateur récent pour le panel. En production, un nom de domaine avec HTTPS est fortement conseillé (obligatoire pour que les joueurs voient les images envoyées depuis le panel si le panel est en https).',
    ]],
  ] },
  { id: 'panel-install', title: '1. Installer le panel (VPS)', blocks: [
    ['ol', [
      'Connecte-toi : ssh ubuntu@IP_DU_VPS (ou root selon l\'hébergeur).',
      'Mets à jour : sudo apt update && sudo apt upgrade -y (redémarre si demandé).',
      'Pare-feu : sudo ufw allow OpenSSH && sudo ufw allow 3000 && sudo ufw --force enable (ouvre aussi le port 3000 dans le pare-feu de l\'hébergeur si besoin).',
      'Installe Node.js 22 : curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - puis sudo apt install -y nodejs git build-essential python3.',
      'Envoie le dossier panel/ sur le VPS (scp -r panel ubuntu@IP:/home/ubuntu/) ou dézippe panel.zip.',
      'Dans le dossier : npm install --omit=dev.',
      'cp .env.example .env puis édite .env (voir ci-dessous).',
      'Test : npm start — tu dois voir « [panel] http://localhost:3000 ». Ctrl+C pour arrêter.',
      'Lancement permanent : sudo npm install -g pm2 && pm2 start ecosystem.config.js && pm2 save && pm2 startup (copie la commande affichée puis refais pm2 save).',
    ]],
    ['h', 'Le fichier .env'],
    ['code', 'PORT=3000\nPUBLIC_URL=http://IP_DU_VPS:3000      # ou https://panel.mondomaine.fr\nSESSION_SECRET=<résultat de: openssl rand -hex 32>\nADMIN_EMAIL=ton@email.fr\nADMIN_PASSWORD=UnMotDePasseLong!\nALLOW_REGISTER=false                    # true = les visiteurs peuvent créer un compte\nTRIAL_DAYS=0                            # jours d\'essai à l\'inscription\nTRUST_PROXY=false                       # true derrière nginx / Cloudflare\nDATA_DIR=./data                         # dossier de la base du panel\nANTHROPIC_API_KEY=                      # facultatif : assistant IA'],
    ['warn', 'PUBLIC_URL doit correspondre à la façon dont tu ouvres le panel (http:// ou https://). Si tu es en http, écris http:// sinon la page s\'affiche sans style.'],
    ['h', 'HTTPS avec un nom de domaine (recommandé)'],
    ['code', 'sudo apt install -y nginx certbot python3-certbot-nginx\nsudo ufw allow 80 && sudo ufw allow 443\nsudo cp nginx.conf.example /etc/nginx/sites-available/panel\nsudo nano /etc/nginx/sites-available/panel     # remplace le nom de domaine\nsudo ln -s /etc/nginx/sites-available/panel /etc/nginx/sites-enabled/panel\nsudo nginx -t && sudo systemctl reload nginx\nsudo certbot --nginx -d TON_NOM'],
    ['p', 'Puis dans .env : PUBLIC_URL=https://TON_NOM et TRUST_PROXY=true, et pm2 restart aero-panel.'],
    ['h', 'Mettre à jour le panel'],
    ['p', 'Remplace les fichiers du dossier panel/ en gardant .env et data/, puis : npm install --omit=dev && pm2 restart aero-panel. Les erreurs se lisent avec pm2 logs aero-panel. La sauvegarde du panel = copier le dossier data/.'],
  ] },
  { id: 'licence', title: '2. Créer ta licence', blocks: [
    ['ol', [
      'Ouvre le panel et connecte-toi avec ADMIN_EMAIL / ADMIN_PASSWORD.',
      'Administration → Licences → Nouveau client + licence : crée-toi une licence (offre « Licence à vie », durée 0).',
      'Copie la clé AERO-XXXXXX-XXXXXX-XXXXXX-XXXXXX : elle sert à relier le serveur FiveM.',
    ]],
    ['p', 'Chez un client : il s\'inscrit (ALLOW_REGISTER=true) ou tu crées son compte, puis une licence lui est attribuée. La page « Clé AERO » lui affiche sa clé et les lignes à mettre dans son server.cfg. Une licence se lie à la première adresse IP qui l\'utilise ; elle peut être déliée depuis cette page (changement d\'hébergeur). Pour développer et tester sans toucher au serveur en ligne, un bouton de cette page permet d\'acheter une 2ᵉ clé dédiée au développement.'],
  ] },
  { id: 'base-install', title: '3. Installer la base FiveM', blocks: [
    ['h', 'a) Copier les ressources'],
    ['p', 'Copie le dossier resources/ de la base dans le dossier resources/ de ton serveur, avec la même arborescence :'],
    ['table', ['Dossier', 'Contenu'], [
      ['[essential]', 'es_extended, oxmysql, ox_lib'],
      ['[inventaire]', 'ox_inventory, p_bridge, p_itemclothes, p_outfits'],
      ['[script]', 'pickax_theme, pickax_core, pickax_ui, pickax_creator, esx_identity, pma-voice'],
      ['[dev]', 'Toutes les ressources pickax_* : notify, panel, settings, builders (job, gang, shop, world, event, illegal), builderhub, basetools, phone, anticheat, économie, bourse, enchères, carnet, HUD, boussole, tutoriel, etc.'],
      ['[system]', 'basicEvent, [builders]'],
      ['[mapping] / [vehicules]', 'Ta map et tes véhicules (à ajouter toi-même)'],
    ]],
    ['h', 'b) Importer la base de données'],
    ['ol', [
      'Crée une base vide dans MySQL / MariaDB (utf8mb4).',
      'Importe database.sql (installation propre : structure + données de référence). Les autres fichiers (economie.sql, sql_smartphone.sql, sql.sql) sont des compléments : importe sql_smartphone.sql si tu utilises le téléphone Aero et economie.sql pour l\'économie.',
      'Les tables des builders (jobbuilder_, gangbuilder_, worldbuilder_, shopbuilder_, illegalbuilder_) se créent automatiquement au premier démarrage des ressources.',
    ]],
    ['h', 'c) Le server.cfg'],
    ['code', 'endpoint_add_tcp "0.0.0.0:30120"\nendpoint_add_udp "0.0.0.0:30120"\nset mysql_connection_string "server=HOTE;port=3306;uid=UTILISATEUR;password=MOT_DE_PASSE;database=NOM_DE_LA_BASE"\nsv_licenseKey "TA_CLE_CFX"\nset onesync_enableInfinity 1\nsv_maxclients 48\n\n# Liaison avec le panel (set, jamais setr)\nset aero_panel_url "https://panel.mondomaine.fr"\nset aero_panel_key "AERO-XXXXXX-XXXXXX-XXXXXX-XXXXXX"\n\n# Autorisations d\'écriture pour que le panel modifie le thème et l\'écran de chargement\nadd_filesystem_permission pickax_basetools write pickax_core\nadd_filesystem_permission pickax_basetools write pickax_theme\nadd_filesystem_permission pickax_panel write pickax_core\n\n# Inventaire\nsetr inventory:framework "esx"\nsetr inventory:slots 50\nsetr inventory:weight 30000\n\nexec "resources.cfg"'],
    ['h', 'd) L\'ordre de démarrage (resources.cfg)'],
    ['p', 'L\'ordre compte. Celui fourni est le bon : pickax_theme en premier (couleur de toutes les interfaces), puis pickax_notify et pickax_creator, puis oxmysql, ox_lib, es_extended, l\'inventaire, esx_identity, pickax_ui, pickax_core, pma-voice, enfin [dev] (builders, panel, téléphone…), [mapping] et [vehicules].'],
    ['note', 'Si tu utilises LB Phone, ne le lance pas avec pickax_phone : les deux utilisent l\'objet « phone ».'],
    ['h', 'e) Premier démarrage'],
    ['ol', [
      'Lance le serveur et lis la console : aucune ressource ne doit afficher d\'erreur rouge.',
      'Connecte-toi : le parcours d\'arrivée (identité → apparence → point d\'apparition → bienvenue) se lance pour un nouveau joueur.',
      'Donne-toi les droits : mets ton groupe ESX sur superadmin (colonne group de la table users) pour accéder aux builders et aux menus staff.',
    ]],
  ] },
  { id: 'liaison', title: '4. Relier le serveur au panel', blocks: [
    ['ol', [
      'Vérifie que server.cfg contient aero_panel_url et aero_panel_key (étape 3c) et que la ressource pickax_panel est démarrée (elle fait partie de [dev]).',
      'Redémarre le serveur. La console affiche « [pickax_panel] Liaison avec le panel » et, en moins de 30 secondes, le Dashboard passe à EN LIGNE.',
    ]],
    ['table', ['Symptôme', 'Cause / solution'], [
      ['« Clé de licence inconnue »', 'La clé est mal copiée dans server.cfg.'],
      ['« Autre adresse IP »', 'Clé AERO → « Changer de machine » (délie l\'ancienne IP).'],
      ['Le panel reste « Hors ligne »', 'Vérifie PUBLIC_URL / le port 3000 ouvert, et que pickax_panel est bien démarré.'],
      ['« FiveM refuse d\'écrire dans … »', 'Ajoute la ligne add_filesystem_permission indiquée dans server.cfg puis redémarre.'],
    ]],
    ['p', 'Config.Enforce (pickax_panel/config.lua) : laisse false sur ton serveur ; mets true chez un client pour arrêter les ressources vendues si la licence expire.'],
  ] },
  { id: 'gestion-serveur', title: '4 bis. Gestion Serveur (l\'extérieur du serveur)', blocks: [
    ['p', 'Cette page règle ce que voient les joueurs AVANT d\'entrer dans le jeu : la fiche de ton serveur dans la liste FiveM et l\'écran de connexion. Un aperçu se met à jour pendant que tu tapes.'],
    ['ul', [
      'Nom du serveur dans la liste (avec codes couleur ^1 à ^7), nom complet (hostname), description courte, étiquettes (tags) et lien Discord : appliqués sur le serveur en quelques secondes.',
      'Nombre de places (slots) : modifie sv_maxclients dans le server.cfg ; pris en compte au prochain redémarrage. Au-delà de 48 places, l\'abonnement Element Club est nécessaire.',
      'Bannière de la liste (banner_detail) et bannière de connexion (banner_connecting) : lien https:// ou fichier .png / .jpg.',
      'Logo du serveur (icône de la liste) : FiveM impose un fichier logo.png de 96 × 96 à la racine du serveur avec load_server_icon dans le server.cfg ; il ne peut pas être changé à distance.',
    ]],
    ['note', 'Tout ce qui se passe DANS le jeu (couleur, logo principal, menus, scripts) se règle dans « Gestion Base ».'],
  ] },
  { id: 'config-general', title: '5. Gestion Base → Couleurs & logos', blocks: [
    ['p', 'Identité visuelle de tout le jeu (menu Gestion Base → Couleurs & logos), dans cet ordre : 1) couleur principale, 2) logo principal, 3) bannière du menu personnel F5, 4) couleur de l\'inventaire, 5) style, puis noms et Discord. Une modification enregistrée ici s\'applique à l\'écran de chargement, au menu pause, aux notifications, au créateur de personnage, à l\'inventaire, aux builders, au HUD, etc.'],
    ['ul', [
      'Couleur principale : une seule couleur pour toutes les interfaces. Tous les menus (y compris les nouveaux : créateur, notifications, menu Doré, inventaire) la suivent.',
      'Couleur de l\'inventaire : facultative (vide = couleur principale).',
      'Nom du serveur, nom court, slogan, lien Discord, logo.',
      'Style des interfaces : Arcade, Piñata ou Classique.',
      'Bannière du menu F5 et image de l\'écran de chargement.',
      'Markers (type, taille, transparence, couleur) et blips (taille, couleur) de tout le serveur.',
    ]],
    ['p', 'Un seul bouton « Enregistrer » enregistre toute la page et l\'applique ; les joueurs voient le changement après reconnexion.'],
  ] },
  { id: 'config-images', title: '6. Images : lien ou fichier', blocks: [
    ['p', 'Partout où une image est demandée (fonds, logos, bannières, photos de lieux, pochettes…), tu as deux choix :'],
    ['ul', [
      'Coller un lien : il doit commencer par https:// (un aperçu s\'affiche, un message rouge signale un lien invalide).',
      'Cliquer sur « Envoyer un fichier » : seuls les fichiers .png et .jpg sont acceptés, 1,5 Mo maximum chacun, 20 Mo au total dans le Drive. Le lien est rempli automatiquement.',
    ]],
    ['note', 'Les images envoyées sont servies par l\'adresse publique du panel : PUBLIC_URL doit être correcte (https:// en production) pour que les joueurs les voient en jeu.'],
    ['p', 'La musique (MP3 / OGG / WAV, 6 Mo) se règle de la même façon avec un lien https:// ou un envoi dans le Drive.'],
  ] },
  { id: 'config-loading', title: '7. Gestion Base → Écran d\'accueil (chargement)', blocks: [
    ['p', 'Tout ce que voit un joueur pendant la connexion :'],
    ['ul', [
      'Messages défilants du bandeau (12 maximum).',
      'Musique (lien ou Drive), volume de départ, lancement automatique.',
      'Boutons Règlement / Discord / Boutique : un bouton sans lien disparaît.',
      'Textes de progression sous la barre, équipe et mises à jour affichées à gauche.',
      'Apparence : image de fond (assombrissement, flou), logo, libellés, et possibilité de masquer le logo, le nom, les boutons, le bandeau ou la barre.',
    ]],
    ['p', 'Un seul bouton « Enregistrer » enregistre toute la page. Les nouveaux joueurs voient le changement dès que pickax_core redémarre (au prochain redémarrage du serveur, ou avec restart pickax_core dans la console). Cela nécessite add_filesystem_permission pickax_basetools write pickax_core.'],
  ] },
  { id: 'config-creator', title: '8. Gestion Base → Parcours d\'arrivée', blocks: [
    ['p', 'Ce que vit un nouveau joueur : création d\'identité, apparence, choix du point d\'apparition, message de bienvenue (et gestionnaire d\'animations). Tout est modifiable sans redémarrage — les joueurs reçoivent la nouvelle configuration en quelques secondes.'],
    ['ul', [
      'Images de fond : une par écran (identité, apparence/vêtements, point d\'apparition, bienvenue, animations) + assombrissement. Vide = on voit le jeu derrière.',
      'Points d\'apparition : nom, description, image, coordonnées X / Y / Z / cap. Tu peux ajouter ou retirer des lieux (3 recommandés pour une belle présentation). Sans lieu dans le panel, ceux de esx_identity/config.lua (Config.Destinations.Spots) sont utilisés.',
      'Carte de fond : image de la carte de Los Santos et bornes du monde (servent à placer les repères).',
      'Message de bienvenue : début du titre, mot en couleur, texte, durée (0 = jusqu\'au clic), logo.',
      'Musique : liste de titres (titre, artiste, fichier ou lien, pochette), volume, activée ou non.',
      'Décor de création (studio) : coordonnées où le joueur est placé pendant l\'identité et l\'apparence, distance et hauteur de caméra. Il est renvoyé à son point de départ ensuite.',
      'Tous les textes : une soixantaine de libellés (titres, descriptions, boutons) remplaçables ; laisse vide pour garder l\'original.',
    ]],
    ['p', 'Pour tester en jeu : /creatortest identity | skin | spawn | welcome | emotes | close (console F8 ou chat). Il faut que pickax_panel soit démarré pour que les réglages arrivent en jeu.'],
    ['note', 'Si le décor de création est transparent ou vide, change les coordonnées du studio pour un lieu dont la carte est chargée ; le jeu attend déjà le chargement complet du décor avant d\'afficher le menu.'],
  ] },
  { id: 'config-settings', title: '9. Gestion Base → réglages des scripts', blocks: [
    ['p', 'Une soixantaine de réglages rangés par catégorie, générés d\'après la ressource pickax_settings (ajouter un réglage = une ligne dans pickax_settings/config.lua).'],
    ['table', ['Catégorie', 'Contenu'], [
      ['Serveur', 'Maintenance, annonces automatiques, redémarrages programmés.'],
      ['Monde & PNJ', 'Population, circulation, police et transports automatiques de GTA.'],
      ['Météo & heure', 'Météo fixe ou dynamique, heure figée, panne de courant.'],
      ['Joueurs & combat', 'Dégâts, tir ami, santé, endurance.'],
      ['Nouveaux joueurs', 'Message de bienvenue et argent bonus à la création du personnage.'],
      ['Interface', 'Notifications, boussole, HUD, cartes d\'information, viseur.'],
      ['Voix', 'Distances de la voix (chuchoter, normal, crier).'],
      ['Économie', 'Gains et prix de l\'ensemble du serveur.'],
      ['Carnet', 'Série de connexion, objectifs du jour, défi de la ville.'],
      ['Gangs', 'Territoires, racket, affrontements, guerres, colis.'],
      ['Drogues & labos', 'Laboratoire, qualité, intoxication, vente aux PNJ.'],
      ['Discord', 'Statut affiché sur le profil Discord des joueurs.'],
      ['Performance', 'Mode économie de ressources pour les PC modestes.'],
    ]],
    ['ul', [
      'Chaque réglage modifié porte un badge « modifié » et un bouton « Par défaut ». Une barre en bas compte les modifications non enregistrées.',
      'Recherche dans tous les réglages, export / import JSON, réinitialisation par catégorie.',
      'Mode facile / difficile : préréglages appliqués d\'un coup sur plusieurs systèmes.',
      'Les valeurs enregistrées sont envoyées au serveur automatiquement (pas de redémarrage).',
    ]],
  ] },
  { id: 'config-boutiques', title: '10 bis. Boutique à coins et boutiques en jeu', blocks: [
    ['h', 'Gestion Base → Boutique à coins'],
    ['p', 'La boutique premium (monnaie « coins » achetée sur Tebex) : onglets Véhicules, Motos, Avions et bateaux, Armes, Caisses, Packs, VIP, Entreprises et Réglages. Chaque produit a un nom, un prix, une description et, selon le type, un modèle, des munitions ou un contenu.'],
    ['ul', [
      'Caisses mystère : le contenu de chaque caisse (véhicule, arme, coins, argent, objet) est réglé lot par lot, avec un niveau de rareté et les chances de chaque niveau.',
      'Packs et VIP : une liste de récompenses (objets, argent, armes, niveau VIP et durée).',
      'Boutons ↑ ↓ pour changer l\'ordre, ✕ pour supprimer, « Remettre les valeurs d\'origine » pour revenir au fichier de configuration.',
      'L\'enregistrement s\'applique en quelques secondes, sans redémarrage ; les prix sont revérifiés côté serveur à chaque achat.',
    ]],
    ['h', 'Gestion Base → Boutiques en jeu'],
    ['p', 'Toutes les boutiques créées avec /shopbuilder (supérettes, armureries, vêtements, pharmacies, marché noir…). Pour chacune : produits (objet, nom, prix, catégorie, stock, promo, actif), emplacements (coordonnées), horaires, moyens de paiement, réapprovisionnement automatique, vendeur (PNJ, animation, dialogue), icône sur la carte, remplissage des stocks, duplication et suppression.'],
    ['note', 'Il faut que le serveur soit en ligne et que pickax_shopbuilder soit démarré. Les modifications utilisent exactement les mêmes contrôles que le builder en jeu.'],
  ] },
  { id: 'config-avance', title: '10 ter. Tous les réglages des scripts', blocks: [
    ['p', 'Gestion Base → « Tous les réglages des scripts » ouvre le fichier de configuration de n\'importe quel script (plus de 80 fichiers) et affiche chacune de ses valeurs simples : prix et montants, durées et délais, activations (vrai / faux) et textes. Tu modifies la valeur, tu enregistres : seule cette valeur change dans le fichier.'],
    ['ul', [
      'Filtres : Prix et montants, Durées et délais, Activations, Textes ; recherche par mot (nom du produit, mot du commentaire).',
      'Chaque ligne affiche le commentaire du fichier pour expliquer à quoi elle sert, et un bouton ↺ pour remettre la valeur d\'origine.',
      'Les commentaires, la mise en forme et le reste du fichier ne sont jamais touchés ; chaque enregistrement crée une version restaurable (page Fichiers) et le fichier est refusé s\'il ne compile plus.',
      'Pour que le changement s\'applique, la ressource doit redémarrer : la case « Redémarrer … après » le fait pour toi (pour pickax_core, elle coupe les menus quelques secondes).',
    ]],
    ['note', 'Les listes de produits complexes ont aussi une page dédiée : Boutique à coins, Boutiques en jeu, Éditeur de base (métiers, salaires, objets) et les réglages par catégorie. Les tableaux en base de données (métiers, boutiques) ne passent pas par les fichiers de config.'],
    ['note', 'Après avoir ajouté ou modifié un script, mets la liste à jour avec : node tools/cfg/build-catalog.js (dans le dossier panel).'],
  ] },
  { id: 'config-ressources', title: '10. Ressources & base', blocks: [
    ['ul', [
      'Ressources (modules) : liste de toutes les ressources du serveur, démarrer / arrêter / redémarrer.',
      'Éditeur de base : métiers, grades et salaires (tables ESX jobs et job_grades, rechargés en jeu) et objets (ox_inventory/data/items.lua : nom, poids, empilable ; chaque enregistrement crée une version restaurable).',
      'Fichiers : explorateur et éditeur coloré des fichiers de resources/ avec historique de versions (30 par fichier), comparaison et restauration. Un fichier .lua qui ne compile pas est refusé. Tout est limité au dossier resources/.',
      'Assistant d\'installation : en 4 étapes (identité, profil du serveur, Discord, terminé) pour régler l\'essentiel d\'un coup.',
      'Historique des réglages : journal de chaque réglage modifié, avec restauration.',
    ]],
    ['warn', 'Modifie les fichiers avec prudence : une erreur dans un fichier de config peut empêcher une ressource de démarrer. Chaque enregistrement garde la version précédente, tu peux toujours restaurer.'],
  ] },
  { id: 'config-acces', title: '11. Accès & sauvegardes', blocks: [
    ['ul', [
      'Bans & whitelist : bannir / débannir par identifiant, liste blanche, message de bienvenue. Appliqués à la connexion.',
      'Sauvegardes : sauvegarde complète de la configuration (fichiers + réglages) et restauration en un clic.',
      'Sauvegardes de la base : export en lecture seule des tables de la base (préfixes jobbuilder_, gangbuilder_, worldbuilder_, illegalbuilder_, shopbuilder_, pickax_ + jobs et job_grades), 5 000 lignes max par table.',
    ]],
    ['note', 'Fais aussi une sauvegarde complète de ta base MySQL avec les outils de ton hébergeur, et copie régulièrement le dossier data/ du panel.'],
  ] },
  { id: 'enjeu', title: '12. Configurer en jeu (builders)', blocks: [
    ['p', 'La plupart des contenus (jobs, gangs, boutiques, garages, drogues, événements) se créent en jeu, sans redémarrer, depuis des « builders » réservés aux groupes ESX _dev (parfois admin / superadmin). Point d\'entrée commun : /builders (hub).'],
    ['table', ['Besoin', 'Ressource', 'Commande'], [
      ['Jobs, grades, garages, vestiaires, armureries, coffres, boss', 'pickax_jobbuilder', '/jobbuilder · menu job : F6'],
      ['Gangs (grades, coffre, garage, territoires, activités)', 'pickax_gangbuilder', '/gangbuilder · F7 (menu gang) · /gangtablet'],
      ['Boutiques (supérette, armurerie, vêtements, pharmacie, marché noir…)', 'pickax_shopbuilder', '/shopbuilder'],
      ['Garages, fourrières, locations, stations essence…', 'pickax_worldbuilder', '/worldbuilder'],
      ['Drogues, blanchiment, braquages', 'pickax_illegalbuilder', '/illegalbuilder'],
      ['Événements (fourgon blindé, largage, livraison illégale…)', 'pickax_eventbuilder', '/eventbuilder'],
      ['Mini-jeux (basket, courses, paintball…)', 'pickax_minigames', '/minigames'],
      ['Audit de santé de la base, sauvegardes des builders', 'pickax_basetools', '/aerotools'],
      ['Hôtel des ventes (joueurs)', 'pickax_auction', '/encheres'],
      ['Logs Discord par métier / gang / boutique', 'pickax_dlogs', 'réglable dans chaque builder'],
      ['Anti-cheat', 'pickax_anticheat', 'panneau en jeu'],
    ]],
    ['p', 'Le menu personnel (F5) permet à chaque joueur de choisir le style des menus, la taille, les couleurs, la forme des boutons et le bruitage.'],
  ] },
  { id: 'fichiers', title: '13. Fichiers de configuration importants', blocks: [
    ['table', ['Fichier', 'À quoi il sert'], [
      ['server.cfg', 'Connexion MySQL, clé de licence, liaison panel, autorisations d\'écriture, inventaire, nombre de places.'],
      ['resources.cfg', 'Ordre de démarrage des ressources.'],
      ['pickax_core/config.lua', 'Identité du serveur (couleur, noms, logo), permissions staff, salaires maximum, armes, heure réelle, neige…'],
      ['esx_identity/config.lua', 'Points d\'apparition par défaut (Config.Destinations).'],
      ['pickax_creator/config.lua', 'Valeurs par défaut du parcours d\'arrivée (musique, studio, carte, bienvenue) — le panel les remplace.'],
      ['pickax_settings/config.lua', 'Liste des réglages visibles dans « Gestion Base ».'],
      ['pickax_panel/config.lua', 'Fréquence d\'échange avec le panel, licence, console autorisée, plaintes (/plainte), sauvegarde de la base.'],
      ['ox_inventory/data/items.lua', 'Objets du serveur (modifiable depuis « Éditeur de base »).'],
    ]],
    ['note', 'Ce que tu règles dans le panel est prioritaire sur les fichiers de config. Si tu supprimes un réglage du panel, la valeur du fichier s\'applique de nouveau.'],
  ] },
  { id: 'explications', title: '13 bis. Explications (scripts et commandes)', blocks: [
    ['p', 'Le menu « Explications » contient deux pages. « Les scripts » explique chaque script de la base (même les petits et les inutiles) : ce qu\'il fait, ce qui se passe si on le retire, où le régler et ses commandes, avec un niveau d\'importance (Obligatoire, Utile, Facultatif, Inutile / test, Désactivé). « Les commandes » liste toutes les commandes avec qui peut les utiliser.'],
    ['note', 'Ces pages sont générées à partir du contenu réel de la base. Après avoir ajouté ou changé un script, lance dans le dossier panel : python3 tools/explications/extract_commands.py puis python3 tools/explications/build.py.'],
  ] },
  { id: 'maintenance', title: '14. Maintenance et mises à jour', blocks: [
    ['ul', [
      'Mettre à jour le panel : remplace les fichiers de panel/ (garde .env et data/), npm install --omit=dev, pm2 restart aero-panel.',
      'Mettre à jour une ressource FiveM : remplace son dossier puis restart nom_de_la_ressource dans la console (le panel permet aussi de redémarrer une ressource).',
      'Après avoir modifié un fichier html / css / js d\'une interface, vide le cache ou reconnecte-toi pour voir le changement.',
      'Sauvegardes : base MySQL (hébergeur), dossier data/ du panel, et « Sauvegardes » dans le panel.',
      'Logs du panel : pm2 logs aero-panel. Logs du serveur : console FiveM et page Logs du panel (si activée).',
    ]],
  ] },
  { id: 'depannage', title: '15. Dépannage', blocks: [
    ['table', ['Problème', 'Solution'], [
      ['http://IP:3000 ne répond pas', 'Port 3000 fermé (ufw status, pare-feu de l\'hébergeur) ou panel arrêté (pm2 status).'],
      ['npm install échoue sur better-sqlite3', 'sudo apt install -y build-essential python3 puis relance.'],
      ['Page du panel sans style', 'PUBLIC_URL ne correspond pas à http:// / https:// utilisé.'],
      ['Un menu garde l\'ancien design', 'restart de la ressource concernée + reconnexion (cache du jeu).'],
      ['Les images du panel ne s\'affichent pas en jeu', 'PUBLIC_URL doit être l\'adresse publique du panel ; en https, un certificat valide est nécessaire.'],
      ['Le thème / l\'écran de chargement ne s\'applique pas', 'Vérifie les lignes add_filesystem_permission du server.cfg, puis « Enregistrer et appliquer ».'],
      ['Inventaire flou', 'Réglages inventory:screenblur / inventory:blurstrength du server.cfg (0 = aucun flou).'],
      ['Le parcours d\'arrivée n\'a pas les nouveaux écrans', 'La ressource pickax_creator doit être démarrée avant esx_identity et pickax_core (resources.cfg).'],
      ['Le décor de création est vide', 'Change les coordonnées du studio dans « Parcours d\'arrivée ».'],
      ['Un réglage du panel n\'est pas pris en compte', 'Vérifie que pickax_panel est démarré et que le Dashboard est EN LIGNE.'],
    ]],
  ] },
  { id: 'audit', title: '17. État de la base (audit du 31/10/2026)', blocks: [
    ['p', 'Tout le dépôt a été contrôlé : serveur, resources, SQL, outils et panel. Aucune erreur de syntaxe, aucune ressource manquante, aucun secret dans le dépôt. Le rapport détaillé est dans docs/AUDIT.md.'],
    ['h', 'Corrigé'],
    ['ul', [
      'server.cfg remis au propre (sections, tags dédoublonnés, valeurs fictives du CDN et de l\'IP de listing mises en commentaire).',
      'Touche F1 : la boutique et le téléphone s\'ouvraient en même temps → le téléphone passe sur F12.',
      'Touche F9 : radio et « quitter un mini-jeu » → les mini-jeux passent sur FIN.',
      'Touche F11 : menu staff et portée de la voix → la voix passe sur ORIGINE (HOME) via setr voice_defaultCycle.',
      'Retirés : une archive Python de 29 Mo, une copie identique du thème Tebex et la ressource async inutilisée.',
    ]],
    ['h', 'À décider'],
    ['ul', [
      'Un ancien dump SQL avec des données réelles reste dans l\'historique git : change le mot de passe MySQL et rends le dépôt privé.',
      'Installe screenshot-basic si tu utilises la capture d\'écran du menu staff ou /clothshots.',
      'Deux systèmes de prison coexistent (ancien menu simple et nouveau système complet) : garde le nouveau.',
    ]],
  ] },
  { id: 'securite', title: '16. Sécurité et bonnes pratiques', blocks: [
    ['ul', [
      'Change ADMIN_PASSWORD dès le premier lancement et utilise un SESSION_SECRET long et aléatoire.',
      'Mets le panel derrière HTTPS et ferme le port 3000 une fois nginx en place.',
      'Ne donne l\'accès aux builders et aux menus staff qu\'aux groupes de confiance.',
      'Garde Config.AllowFiles = false dans pickax_panel/config.lua si tu ne veux pas d\'éditeur de fichiers sur un serveur.',
      'Le panel valide chaque action (liste blanche) : ne désactive pas ces contrôles.',
      'Pour protéger les ressources que tu vends, passe-les sous l\'escrow FiveM (Tebex / Keymaster).',
    ]],
  ] },
];

PAGES.docs = async function () {
  const search = el('input', { placeholder: 'Rechercher…', style: 'width:100%;margin-bottom:10px' });
  const toc = el('div'), body = el('div');
  const render = block => {
    const [t, a, b] = block;
    if (t === 'p') return el('p', { style: 'line-height:1.65;margin:8px 0' }, a);
    if (t === 'h') return el('h3', { style: 'margin:18px 0 6px;font-size:15px' }, a);
    if (t === 'ul') return el('ul', { style: 'line-height:1.65;margin:8px 0;padding-left:22px' }, a.map(x => el('li', { style: 'margin:3px 0' }, x)));
    if (t === 'ol') return el('ol', { style: 'line-height:1.65;margin:8px 0;padding-left:22px' }, a.map(x => el('li', { style: 'margin:3px 0' }, x)));
    if (t === 'code') { const pre = el('pre', { style: 'background:rgba(255,255,255,.05);border:1px solid rgba(255,255,255,.08);border-radius:8px;padding:12px;overflow:auto;font-size:12px;line-height:1.5;margin:10px 0;position:relative;user-select:text' }, el('code', {}, a)); return el('div', {}, pre, el('button', { class: 'btn s', style: 'margin:-4px 0 8px', onclick: () => { navigator.clipboard && navigator.clipboard.writeText(a).then(() => toast('Copié', 'ok')); } }, el('span', {}, 'Copier'))); }
    if (t === 'note' || t === 'warn') return el('div', { style: `border-left:3px solid ${t === 'warn' ? '#e5a23c' : '#4aa8ff'};background:rgba(255,255,255,.04);padding:10px 14px;border-radius:6px;margin:12px 0;line-height:1.55` }, el('b', {}, t === 'warn' ? 'Attention : ' : 'Bon à savoir : '), a);
    if (t === 'table') return el('div', { style: 'overflow:auto;margin:10px 0' }, el('table', { style: 'width:100%;border-collapse:collapse;font-size:13px' }, el('thead', {}, el('tr', {}, a.map(h => el('th', { style: 'text-align:left;padding:8px 10px;border-bottom:1px solid rgba(255,255,255,.15)' }, h)))), el('tbody', {}, b.map(r => el('tr', {}, r.map((c, i) => el('td', { style: 'padding:8px 10px;border-bottom:1px solid rgba(255,255,255,.07);vertical-align:top;' + (i === 0 ? 'font-weight:600;white-space:nowrap' : '') }, c)))))));
    return null;
  };
  const text = s => JSON.stringify(s.blocks).toLowerCase() + ' ' + s.title.toLowerCase();
  const draw = () => {
    const q = search.value.trim().toLowerCase(), list = DOCS.filter(s => !q || text(s).includes(q));
    toc.replaceChildren(...DOCS.map(s => el('a', { href: '#doc-' + s.id, style: 'display:block;padding:6px 8px;border-radius:6px;font-size:13px;opacity:' + (list.includes(s) ? 1 : .35), onclick: e => { e.preventDefault(); const t = document.getElementById('doc-' + s.id); if (t) t.scrollIntoView({ behavior: 'smooth', block: 'start' }); } }, s.title)));
    body.replaceChildren(...(list.length ? list.map(s => el('div', { class: 'card', id: 'doc-' + s.id, style: 'margin-bottom:14px;scroll-margin-top:70px' }, el('h2', {}, s.title), ...s.blocks.map(render))) : [el('div', { class: 'card empty' }, 'Aucun résultat.')]));
  };
  search.addEventListener('input', draw); draw();
  return el('div', {}, head('Documentation'),
    el('p', { class: 'muted', style: 'margin-bottom:12px' }, 'De l\'installation du panel et de la base FiveM jusqu\'à la configuration complète du serveur.'),
    el('div', { class: 'grid', style: 'grid-template-columns:240px 1fr;gap:16px;align-items:start' }, el('div', { class: 'card', style: 'position:sticky;top:70px;max-height:calc(100vh - 100px);overflow:auto' }, search, toc), body));
};
