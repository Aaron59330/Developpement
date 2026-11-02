// Éditeur de configuration : lecture des valeurs et remplacement ciblé (aucun autre octet du fichier ne change)
const L = require('../lib/luaconfig'); const fs = require('fs'), path = require('path'); let ok = 0; const t = (n, c) => { if (!c) { console.error('✗', n); process.exit(1); } ok++; console.log('  ✓', n); };
const src = "Config = {\n  Price = 100, -- prix\n  Name = 'Test', On = true,\n  Rows = {\n    { name = 'Pain', price = 5, f = function() return 3 end },\n    { name = \"Eau\", price = -2.5, v = vector3(1.0, 2.0, 3.0) },\n  },\n}\nConfig.Other = 55\n";
const e = L.parse(src);
t('valeurs simples lues (nombres, textes, booléens, négatifs)', e.length === 8 && e.find(x => x.path.join('.') === 'Config.Rows.2.price').value === -2.5);
t('les fonctions et appels (vector3) sont ignorés sans casser la lecture', !e.some(x => x.path.includes('f')) && !e.some(x => x.path.includes('v')));
t('commentaire de fin de ligne associé', e[0].comment === 'prix');
t('nom de ligne associé aux prix des tableaux', e.find(x => x.path.join('.') === 'Config.Rows.1.price').rowLabel.text === 'Pain');
const o = L.apply(src, [{ start: e[0].start, end: e[0].end, old: e[0].raw, value: 250 }, { start: e[1].start, end: e[1].end, old: e[1].raw, value: "L'été" }, { start: e[2].start, end: e[2].end, old: e[2].raw, value: false }]);
t('remplacement ciblé : nombre, texte avec apostrophe, booléen', o.includes('Price = 250, -- prix') && o.includes("Name = 'L\\'été'") && o.includes('On = false'));
t('le reste du fichier est identique', o.replace('250', '100').replace("'L\\'été'", "'Test'").replace('false', 'true') === src);
let refused = false; try { L.apply(src, [{ start: e[0].start, end: e[0].end, old: '999', value: 1 }]); } catch (x) { refused = true; }
t('modification refusée si le fichier a changé entre-temps', refused);
let bad = false; try { L.apply(src, [{ start: e[0].start, end: e[0].end, old: e[0].raw, value: 'abc' }]); } catch (x) { bad = true; }
t('valeur invalide refusée (texte dans un nombre)', bad);
const R = path.join(__dirname, '..', '..', 'resources'); let files = 0, vals = 0;
(function walk(d) { for (const f of fs.readdirSync(d, { withFileTypes: true })) { const p = path.join(d, f.name); if (f.isDirectory()) { if (!['node_modules', 'html', 'stream', 'web', 'dist'].includes(f.name)) walk(p); } else if (/^config.*\.lua$/i.test(f.name)) { const s = fs.readFileSync(p, 'utf8'), en = L.parse(s); files++; vals += en.length; const n = en.find(x => x.kind === 'number'); if (n && L.apply(s, [{ start: n.start, end: n.end, old: n.raw, value: n.value }]) !== s) { console.error('écart sur', p); process.exit(1); } } } })(R);
t(`aller-retour sans changement sur ${files} fichiers de config réels (${vals} valeurs)`, files > 50 && vals > 10000);
console.log(`\n${ok} vérifications OK`);
