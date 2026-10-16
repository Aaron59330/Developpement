# CarPlay — autoradio de véhicule

Ouvrir : **menu contextuel du véhicule → « Ouvrir CarPlay »**, **F5/menu personnel → Véhicule → Multimédia → Ouvrir CarPlay**, la commande `/carplay`
ou `exports.pickax_carplay:OpenCarPlay()` (il faut être dans le véhicule).

- Lecture YouTube (liens `youtube.com`, `youtu.be`, `music.youtube.com`, shorts, lives) et liens directs / flux radio (`.mp3`, `.ogg`, Icecast…).
- File d'attente (lire maintenant, ajouter, retirer, vider, aléatoire, répéter tout / un titre), pause, suivant / précédent, curseur de position,
  volume du véhicule, volume personnel (ce que TU entends), favoris et historique enregistrés par joueur (base de données), radios préconfigurées.
- Le son est synchronisé pour tous les joueurs proches (horloge réelle) ; de l'extérieur il baisse avec la distance et s'étouffe portes / toit fermés ;
  « haut-parleurs extérieurs » désactivable. Les 3 véhicules les plus proches sont audibles en même temps.
- Recherche YouTube optionnelle : `set carplay_youtube_key "CLÉ_API_YOUTUBE_DATA_V3"` dans `server.cfg` (sans clé, on colle un lien).
- Réglages : `config.lua` (distance, sièges autorisés, domaines acceptés pour les liens directs, radios, durée avant arrêt d'un véhicule vide).

## Limites à connaître
- La lecture YouTube passe par le lecteur intégré (IFrame API) : une vidéo dont le propriétaire interdit l'intégration est refusée → passée automatiquement.
  Si TOUTES les vidéos YouTube sont refusées sur ton serveur (YouTube a durci l'exigence de « referrer » pour les pages d'application), les liens directs et
  les radios (SomaFM, Radio Paradise…) restent utilisables.
- Les serveurs de jeu et les joueurs doivent avoir accès à Internet.
- Tables créées automatiquement : `carplay_favorites`, `carplay_history`.
