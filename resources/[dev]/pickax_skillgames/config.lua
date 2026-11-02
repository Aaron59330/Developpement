Config = {}
-- Bibliothèque de mini-jeux. Les ressources l'appellent ainsi (côté client) :
--   local score = exports.pickax_skillgames:Play('pins', { pins = 5, difficulty = 3, seconds = 30 })   -- 0-100, ou nil si abandonné
-- Jeux : pins (crochetage) · code (piratage, mémoire) · wires (piratage, câbles) · cpr (rythme) · suture · wrap (bandage) · timing · hold (cuisson, pêche) · align (faux papiers)
Config.Debug = false   -- true : /skillgame <nom> (admin) pour tester un mini-jeu en jeu
Config.AllowTest = { _dev = true, superadmin = true, admin = true }
