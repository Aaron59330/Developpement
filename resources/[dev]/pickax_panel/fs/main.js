// Accès fichiers du panel web (Node.js intégré à FiveM). Limité au dossier resources/, sans sortie possible (chemins relatifs, liens symboliques résolus).
const fs = require('fs');
const path = require('path');

const SELF = GetCurrentResourceName();
function resourcesRoot() {
  let p = path.resolve(GetResourcePath(SELF));
  for (let i = 0; i < 6; i++) { if (path.basename(p) === 'resources') return p; p = path.dirname(p); }
  return null;
}
const ROOT = resourcesRoot();
const EXT = new Set(['.lua', '.json', '.cfg', '.meta', '.js', '.html', '.css', '.txt', '.md', '.sql', '.xml', '.yml', '.yaml', '.ini']);
const MAX = 1024 * 1024;
const HIDDEN = /(^|\/)(\.|node_modules(\/|$))/;

function safe(rel, mustExist) {
  if (!ROOT) throw new Error('dossier resources introuvable');
  if (typeof rel !== 'string' || rel.includes('..') || rel.startsWith('/') || rel.includes('\\') || HIDDEN.test(rel)) throw new Error('chemin refusé');
  const full = path.resolve(ROOT, rel);
  if (full !== ROOT && !full.startsWith(ROOT + path.sep)) throw new Error('chemin refusé');
  // la ressource du panel elle-même (clé de licence, logique) n'est pas modifiable depuis le panel
  const first = path.relative(ROOT, full).split(path.sep);
  const own = path.resolve(GetResourcePath(SELF));
  if (full === own || full.startsWith(own + path.sep)) throw new Error('la ressource pickax_panel est protégée');
  if (mustExist || fs.existsSync(full)) { const real = fs.realpathSync(mustExist || fs.existsSync(full) ? full : path.dirname(full)); const realRoot = fs.realpathSync(ROOT); if (real !== realRoot && !real.startsWith(realRoot + path.sep)) throw new Error('lien symbolique refusé'); }
  void first;
  return full;
}

exports('FsList', (rel) => {
  try {
    const dir = safe(rel || '', true);
    const st = fs.statSync(dir);
    if (!st.isDirectory()) return { error: 'ce n’est pas un dossier' };
    const entries = [];
    for (const d of fs.readdirSync(dir, { withFileTypes: true })) {
      if (d.name.startsWith('.') || d.name === 'node_modules') continue;
      const rp = path.relative(ROOT, path.join(dir, d.name)).split(path.sep).join('/');
      if (d.isDirectory()) { if (rp.split('/')[0] === SELF && rp === SELF) continue; entries.push({ name: d.name, type: 'dir' }); }
      else if (d.isFile() && EXT.has(path.extname(d.name).toLowerCase())) entries.push({ name: d.name, type: 'file', size: fs.statSync(path.join(dir, d.name)).size });
    }
    entries.sort((a, b) => (a.type === b.type ? a.name.localeCompare(b.name) : a.type === 'dir' ? -1 : 1));
    return { entries: entries.slice(0, 1500) };
  } catch (e) { return { error: e.message }; }
});

exports('FsRead', (rel) => {
  try {
    const f = safe(rel, true);
    if (!EXT.has(path.extname(f).toLowerCase())) return { error: 'type de fichier non modifiable' };
    const st = fs.statSync(f);
    if (!st.isFile()) return { error: 'ce n’est pas un fichier' };
    if (st.size > MAX) return { error: 'fichier trop gros (1 Mo max)' };
    return { content: fs.readFileSync(f, 'utf8') };
  } catch (e) { return { error: e.message }; }
});

exports('FsWrite', (rel, content, create) => {
  try {
    const f = safe(rel, false);
    if (!EXT.has(path.extname(f).toLowerCase())) return { error: 'type de fichier non modifiable' };
    if (typeof content !== 'string' || Buffer.byteLength(content) > MAX) return { error: 'contenu invalide ou trop gros' };
    const exists = fs.existsSync(f);
    if (create && exists) return { error: 'le fichier existe déjà' };
    if (!create && !exists) return { error: 'fichier introuvable' };
    if (create) { const parent = path.dirname(f); if (!fs.existsSync(parent)) return { error: 'dossier parent introuvable' }; }
    const tmp = f + '.aero-tmp';
    fs.writeFileSync(tmp, content, 'utf8');
    fs.renameSync(tmp, f);
    return { ok: true, message: create ? 'fichier créé' : 'fichier enregistré' };
  } catch (e) { return { error: e.message }; }
});

// Nombre de places (sv_maxclients) : n'est lu qu'au démarrage du serveur, donc on le met dans server.cfg (une seule ligne, rien d'autre n'est touché).
// server.cfg est cherché à côté du dossier resources/. Une copie de sauvegarde est faite avant chaque modification.
exports('SetMaxClients', (value) => {
  try {
    const n = Math.floor(Number(value));
    if (!Number.isFinite(n) || n < 1 || n > 2048) return { error: 'nombre de places invalide (1 à 2048)' };
    if (!ROOT) return { error: 'dossier resources introuvable' };
    const file = path.join(path.dirname(ROOT), 'server.cfg');
    if (!fs.existsSync(file)) return { error: 'server.cfg introuvable à côté du dossier resources' };
    const raw = fs.readFileSync(file, 'utf8');
    const eol = raw.includes('\r\n') ? '\r\n' : '\n';
    const lines = raw.split(/\r?\n/);
    const re = /^(\s*(?:set\s+)?sv_maxclients\s+)["']?(\d+)["']?(\s*(?:#.*)?)$/i;
    let idx = lines.findIndex(l => re.test(l) && !/^\s*#/.test(l));
    let previous = null;
    if (idx >= 0) {
      const m = lines[idx].match(re); previous = Number(m[2]);
      if (previous === n) return { ok: true, changed: false, previous };
      lines[idx] = m[1] + n + m[3];
    } else {
      while (lines.length && lines[lines.length - 1] === '') lines.pop();
      lines.push('sv_maxclients ' + n, '');
    }
    fs.writeFileSync(file + '.aero-backup', raw, 'utf8');
    const tmp = file + '.aero-tmp';
    fs.writeFileSync(tmp, lines.join(eol), 'utf8');
    fs.renameSync(tmp, file);
    return { ok: true, changed: true, previous };
  } catch (e) { return { error: e.message }; }
});
