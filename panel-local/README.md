# Panel en local → serveur sur un VPS

1. Sur le **VPS** : dans `server.cfg` → `set pickax_panel_key "UneCleLongueEtSecrete123"` puis `restart pickax_panel` (le port 30120 doit être joignable).
2. Sur **ton PC** : double-clic sur `lancer-panel.bat` (ou `python serve.py`), ouvre http://localhost:8080.
3. Saisis `http://IP_DU_VPS:30120` et la clé. Chaque modification est écrite **sur le VPS** (fichiers + base de données du VPS).

Le serveur de jeu et la base ne bougent pas : seul l'écran du panel tourne chez toi. Le VPS doit avoir la ressource `pickax_panel` démarrée.
