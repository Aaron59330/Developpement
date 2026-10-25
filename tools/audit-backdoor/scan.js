#!/usr/bin/env node
// Scanner anti-backdoor FiveM : cherche dans les ressources le code qui télécharge/exécute du code, exfiltre des secrets,
// donne des droits, ou est obfusqué. Usage : node scan.js [dossier-resources] [--json] [--min=high|medium|low]
// C'est un détecteur d'indices (pas une preuve) : chaque résultat est à relire. Fichiers analysés : .lua .js .ts .html .json (hors node_modules / dist).
const fs = require('fs'), path = require('path');
const root = path.resolve(process.argv.find((a, i) => i > 1 && !a.startsWith('--')) || path.join(__dirname, '..', '..', 'resources'));
const asJson = process.argv.includes('--json');
const minArg = (process.argv.find(a => a.startsWith('--min=')) || '--min=low').split('=')[1];
const LV = { low: 1, medium: 2, high: 3 }, min = LV[minArg] || 1;
const SKIP_DIR = /(^|[\\/])(node_modules|\.git|dist|\.yarn|stream|backups)([\\/]|$)/;
const EXT = /\.(lua|js|ts|html|json|cfg)$/i;
// domaines dont l'accès est considéré normal (ajoute les tiens)
const OK_HOSTS = ['discord.com', 'discordapp.com', 'fivem.net', 'cfx.re', 'github.com', 'githubusercontent.com', 'jsdelivr.net', 'cdnjs.cloudflare.com', 'unpkg.com', 'googleapis.com', 'gstatic.com', 'fivemanage.com', 'tebex.io', 'localhost', '127.0.0.1', 'w3.org', 'schema.org', 'cfx-nui-'];

const RULES = [
  { id: 'remote-exec', lvl: 'high', re: /(?<![\w.])(load|loadstring|assert\s*\(\s*load)\s*\(\s*[^)]*\b(body|data|res|response|result|text|resp|content)\b/i, why: 'exécute du texte reçu (probablement téléchargé) comme du code' },
  { id: 'http-then-load', lvl: 'high', re: /PerformHttpRequest[\s\S]{0,400}\b(load|loadstring)\s*\(/, why: 'requête HTTP dont la réponse est exécutée' },
  { id: 'os-exec', lvl: 'high', re: /\b(os\.execute|io\.popen|os\.remove|os\.rename)\s*\(/, why: 'exécution de commandes système / suppression de fichiers' },
  { id: 'node-exec', lvl: 'high', re: /\b(child_process|execSync|spawnSync|require\(['"]child_process['"]\))/, why: 'exécution de processus système (Node)' },
  { id: 'eval-js', lvl: 'medium', re: /\beval\s*\(|new\s+Function\s*\(/, why: 'exécution dynamique de JS' },
  { id: 'acl-grant', lvl: 'high', re: /ExecuteCommand\s*\(\s*['"`][^'"`]*(add_ace|add_principal|remove_ace|exec |set\s+sv_|setr?\s+rcon)/i, why: 'modification des droits ACE / de la configuration depuis un script' },
  { id: 'secret-read', lvl: 'high', re: /GetConvar(Int)?\s*\(\s*['"`](sv_licenseKey|rcon_password|mysql_connection_string|steam_webApiKey|sv_tebexSecret)['"`]/i, why: 'lecture d\'un secret du serveur (licence, mot de passe, base de données)' },
  { id: 'cfg-read', lvl: 'high', re: /LoadResourceFile\s*\(\s*['"`][^'"`]*['"`]\s*,\s*['"`][^'"`]*(server\.cfg|\.env|config\.json|resources\.cfg)['"`]/i, why: 'lecture d\'un fichier de configuration sensible' },
  { id: 'save-res', lvl: 'medium', re: /SaveResourceFile\s*\(/, why: 'écriture de fichiers de ressource (peut modifier d\'autres scripts)' },
  { id: 'obf-escapes', lvl: 'high', re: /(\\x[0-9a-fA-F]{2}){12,}|(\\\d{3}){12,}/, why: 'chaîne en séquences d\'échappement (obfuscation)' },
  { id: 'obf-char', lvl: 'high', re: /(string\.char\s*\(\s*\d+\s*(,\s*\d+\s*){8,}\))|(String\.fromCharCode\s*\(\s*\d+\s*(,\s*\d+\s*){8,}\))/, why: 'texte reconstruit caractère par caractère (obfuscation)' },
  { id: 'obf-b64', lvl: 'medium', re: /['"`][A-Za-z0-9+\/]{200,}={0,2}['"`]/, why: 'très longue chaîne encodée (base64 ?)' },
  { id: 'obf-names', lvl: 'medium', re: /\b(_0x[a-f0-9]{4,}|[Il1]{8,})\b/, why: 'noms de variables illisibles (obfuscation)' },
  { id: 'dyn-global', lvl: 'medium', re: /_G\s*\[\s*['"`]?(load|loadstring|PerformHttpRequest|os|io)['"`]?\s*\]|_ENV\s*\[/, why: 'accès dynamique à des fonctions sensibles' },
  { id: 'dyn-event', lvl: 'medium', re: /RegisterNetEvent\s*\(\s*[^'"`)\s][^)]*\)/, why: 'événement réseau au nom calculé (difficile à auditer)' },
  { id: 'give-admin', lvl: 'medium', re: /(setGroup|\.setGroup)\s*\(\s*['"`](admin|superadmin|owner|god)['"`]/, why: 'attribution d\'un groupe admin dans le code' },
  { id: 'give-money', lvl: 'low', re: /RegisterNetEvent\s*\(\s*['"`][^'"`]*(give|add)(Money|Account|Item|Cash)[^'"`]*['"`]/i, why: 'événement réseau qui donne argent/objet : vérifier qu\'il contrôle le joueur' },
];
const URL_RE = /https?:\/\/([a-z0-9.-]+\.[a-z]{2,}|\d{1,3}(?:\.\d{1,3}){3})(?::\d+)?[^\s'"`)<>]*/gi;

const BASE_FILE = path.join(__dirname, 'baseline.json');
const showAll = process.argv.includes('--all'), updateBase = process.argv.includes('--update-baseline');
let baseline = {}; try { baseline = JSON.parse(fs.readFileSync(BASE_FILE, 'utf8')).reviewed || {}; } catch {}
const keyOf = f => `${f.file}|${f.rule}|${f.code}`;
const findings = []; let nFiles = 0;
function walk(d) {
  let es; try { es = fs.readdirSync(d, { withFileTypes: true }); } catch { return; }
  for (const e of es) {
    const p = path.join(d, e.name);
    if (SKIP_DIR.test(p)) continue;
    if (e.isDirectory()) walk(p); else if (EXT.test(e.name)) scanFile(p);
  }
}
function lineOf(txt, idx) { let n = 1; for (let i = 0; i < idx; i++) if (txt.charCodeAt(i) === 10) n++; return n; }
function scanFile(p) {
  let txt; try { const st = fs.statSync(p); if (st.size > 3e6) return; txt = fs.readFileSync(p, 'utf8'); } catch { return; }
  nFiles++;
  const rel = path.relative(root, p).replace(/\\/g, '/');
  const isHtmlish = /\.(html|js|ts)$/i.test(p) && /\/(html|ui|web|nui)\//i.test(rel);
  for (const r of RULES) {
    if (LV[r.lvl] < min) continue;
    if (isHtmlish && /^(os-exec|acl-grant|secret-read|cfg-read|save-res|dyn-event|give-)/.test(r.id)) continue;   // règles propres au code serveur
    const re = new RegExp(r.re.source, r.re.flags.includes('g') ? r.re.flags : r.re.flags + 'g');
    let m; let guard = 0;
    while ((m = re.exec(txt)) && guard++ < 20) {
      const ln = lineOf(txt, m.index);
      const line = txt.split('\n')[ln - 1] || '';
      if (/^\s*(--|\/\/)/.test(line)) continue;   // commentaire
      findings.push({ file: rel, line: ln, level: r.lvl, rule: r.id, why: r.why, code: line.trim().slice(0, 160) });
    }
  }
  // URLs sortantes dans le code serveur
  if (!isHtmlish && /\.(lua|js|ts)$/i.test(p) && LV.medium >= min) {
    let m; const seen = new Set();
    URL_RE.lastIndex = 0;
    while ((m = URL_RE.exec(txt))) {
      const host = m[1].toLowerCase();
      if (OK_HOSTS.some(h => host === h || host.endsWith('.' + h) || host.startsWith(h))) continue;
      if (/^\d{1,3}(\.\d{1,3}){3}$/.test(host) && /^(127\.|10\.|192\.168\.)/.test(host)) continue;
      const ln = lineOf(txt, m.index); const line = txt.split('\n')[ln - 1] || '';
      if (/^\s*(--|\/\/|\*)/.test(line) || seen.has(host + ln)) continue;
      seen.add(host + ln);
      const net = /PerformHttpRequest|fetch\(|axios|XMLHttpRequest|http\.request|https\.request|\.get\(|\.post\(/.test(txt.slice(Math.max(0, m.index - 300), m.index + 300));
      findings.push({ file: rel, line: ln, level: net ? 'high' : 'low', rule: 'unknown-host', why: net ? `requête sortante vers un domaine inconnu : ${host}` : `URL vers un domaine inconnu : ${host}`, code: line.trim().slice(0, 160) });
    }
  }
}
walk(root);
if (updateBase) {
  const reviewed = {}; findings.forEach(f => { reviewed[keyOf(f)] = f.level; });
  fs.writeFileSync(BASE_FILE, JSON.stringify({ note: 'Résultats relus et jugés normaux. Ne regénère ce fichier (--update-baseline) qu\'après avoir relu les nouveaux résultats.', at: new Date().toISOString(), reviewed }, null, 1));
  console.log(`Référence enregistrée : ${findings.length} résultat(s) marqués comme relus.`); process.exit(0);
}
const hidden = showAll ? 0 : findings.filter(f => baseline[keyOf(f)]).length;
if (!showAll) for (let i = findings.length - 1; i >= 0; i--) if (baseline[keyOf(findings[i])]) findings.splice(i, 1);
const order = { high: 0, medium: 1, low: 2 };
findings.sort((a, b) => order[a.level] - order[b.level] || a.file.localeCompare(b.file) || a.line - b.line);
const count = l => findings.filter(f => f.level === l).length;
if (asJson) { console.log(JSON.stringify({ root, files: nFiles, high: count('high'), medium: count('medium'), low: count('low'), findings }, null, 2)); process.exit(0); }
console.log(`Analyse de ${nFiles} fichiers dans ${root}${hidden ? ` (${hidden} résultat(s) déjà relus masqués, --all pour tout voir)` : ''}\n  critique(s): ${count('high')}   à vérifier: ${count('medium')}   info: ${count('low')}\n`);
const icon = { high: '[CRITIQUE]', medium: '[A VERIFIER]', low: '[INFO]' };
for (const f of findings) console.log(`${icon[f.level]} ${f.file}:${f.line}  (${f.rule}) ${f.why}\n      ${f.code}`);
