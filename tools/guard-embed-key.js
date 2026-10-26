#!/usr/bin/env node
// Écrit la clé publique du panel dans pickax_guard et dans les ressources qui vérifient la licence elles-mêmes.
// Usage : node tools/guard-embed-key.js <clé publique base64>   (affichée sur la page « Protection de la base » du panel)
// À lancer AVANT d'obfusquer les fichiers Lua. La clé publique n'est pas secrète : on peut la committer.
const fs = require('fs'), path = require('path');
const key = (process.argv[2] || '').trim();
if (!/^[A-Za-z0-9+/=]{40,}$/.test(key)) { console.error('Clé publique invalide.\nUsage : node tools/guard-embed-key.js <clé publique base64>'); process.exit(1); }
const root = path.join(__dirname, '..', 'resources');
let n = 0;
(function walk(d) {
  for (const e of fs.readdirSync(d, { withFileTypes: true })) {
    const p = path.join(d, e.name);
    if (e.isDirectory()) { if (e.name !== 'node_modules') walk(p); continue; }
    if (!e.name.endsWith('.lua')) continue;
    const t = fs.readFileSync(p, 'utf8');
    let o = t;
    if (e.name === 'config.lua' && p.includes('pickax_guard')) o = o.replace(/Config\.PublicKey\s*=\s*'[^']*'/, `Config.PublicKey = '${key}'`);
    if (o.includes('-- [AERO:LIC]')) o = o.replace(/local AERO_PK = '[^']*'/, `local AERO_PK = '${key}'`);
    if (o !== t) { fs.writeFileSync(p, o); n++; console.log('  ✔', path.relative(root, p)); }
  }
})(root);
console.log(n ? `${n} fichier(s) mis à jour.` : 'Rien à mettre à jour (clé déjà en place ?).');
