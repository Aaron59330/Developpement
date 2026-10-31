// Génère public/cfg-catalog.js : la liste de tous les fichiers de configuration (config*.lua) des ressources, avec leur nombre de valeurs modifiables.
// Utilisation (depuis le dossier panel) : node tools/cfg/build-catalog.js
const fs = require('fs'), path = require('path'), vm = require('vm'); const L = require('../../lib/luaconfig');
const R = path.join(__dirname, '..', '..', '..', 'resources');
const ex = {}; try { vm.runInNewContext(fs.readFileSync(path.join(__dirname, '..', '..', 'public', 'explications-data.js'), 'utf8'), { window: ex }); } catch (e) {}
const entries = (ex.EXPL && ex.EXPL.entries) || []; const byId = Object.fromEntries(entries.map(e => [e.id, e]));
const SKIP = new Set(['node_modules', 'html', 'stream', 'web', 'dist', 'ox_lib', 'oxmysql', 'pma-voice', 'p_bridge', '[disabled]', 'yarn', 'vendor', 'install', 'locales']);
const PRICE = /price|prix|cost|cout|coût|amount|montant|salary|salaire|reward|recompense|récompense|fee|amende|fine|tax|taxe|money|argent|cash|bonus|gain|pay|paie|caution|bail|rent|loyer|commission|fare|tarif|buy|sell|vente|achat|stock|cap/i;
const files = [];
(function walk(d) { for (const f of fs.readdirSync(d, { withFileTypes: true })) { const p = path.join(d, f.name); if (f.isDirectory()) { if (!SKIP.has(f.name)) walk(p); } else if (/^config[A-Za-z0-9_\-.]*\.lua$/i.test(f.name)) files.push(p); } })(R);
const out = [];
for (const f of files) {
  const rel = path.relative(R, f).split(path.sep).join('/'); const txt = fs.readFileSync(f, 'utf8'); let ents; try { ents = L.parse(txt); } catch (e) { continue; } if (!ents.length) continue;
  const m = rel.match(/^(\[[^\]]+\])\/([^\/]+)\/(.*)$/); const folder = m ? m[1] : '', res = m ? m[2] : rel.split('/')[0], sub = m ? m[3] : rel;
  const dir = sub.includes('/') ? sub.slice(0, sub.lastIndexOf('/')) : '';
  const e = byId[folder + '/' + res + (dir ? '' : '')] || (dir && byId[res + '/' + dir]) || byId[folder + '/' + res] || null;
  const e2 = dir ? (byId[res + '/' + dir] || null) : null; const info = e2 || e;
  out.push({ path: rel, res, sub: dir || '', name: (info ? info.name : (dir ? res + ' · ' + dir : res)) + (path.basename(rel) !== 'config.lua' ? ' — ' + path.basename(rel).replace(/\.lua$/, '') : ''), cat: info ? info.cat : 'Autres', n: ents.length, price: ents.filter(x => x.kind === 'number' && PRICE.test(x.path.join('.'))).length, kb: Math.round(Buffer.byteLength(txt) / 1024) });
}
out.sort((a, b) => a.cat.localeCompare(b.cat, 'fr') || a.name.localeCompare(b.name, 'fr'));
fs.writeFileSync(path.join(__dirname, '..', '..', 'public', 'cfg-catalog.js'), '// Généré par tools/cfg/build-catalog.js : ne pas modifier à la main\nwindow.CFG_CATALOG = ' + JSON.stringify(out) + ';\n');
console.log(out.length, 'fichiers,', out.reduce((s, x) => s + x.n, 0), 'valeurs,', out.reduce((s, x) => s + x.price, 0), 'prix / montants');
