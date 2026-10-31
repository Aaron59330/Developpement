// Lecture et modification ciblée des valeurs simples (nombres, textes, vrai/faux) d'un fichier de configuration Lua.
// Seul le texte de la valeur est remplacé : commentaires, mise en forme et reste du fichier ne sont jamais touchés.
'use strict';
const KW_OPEN = new Set(['function', 'if', 'do', 'repeat']), KW_CLOSE = new Set(['end', 'until']);

function lex(src) {
  const toks = []; const comments = []; let i = 0; const n = src.length; let line = 1;
  const lineAt = []; // offset -> numéro de ligne via tableau des débuts de lignes
  const starts = [0]; for (let k = 0; k < n; k++) if (src[k] === '\n') starts.push(k + 1);
  const lineOf = off => { let lo = 0, hi = starts.length - 1; while (lo < hi) { const m = (lo + hi + 1) >> 1; if (starts[m] <= off) lo = m; else hi = m - 1; } return lo + 1; };
  const longEnd = (s, from) => { const m = /^\[(=*)\[/.exec(src.slice(from, from + 40)); if (!m) return -1; const close = ']' + m[1] + ']'; const e = src.indexOf(close, from + m[0].length); return e < 0 ? n : e + close.length; };
  while (i < n) {
    const c = src[i];
    if (c === '-' && src[i + 1] === '-') {
      const st = i; const le = longEnd(src, i + 2);
      if (le > 0) { comments.push({ start: st, end: le, line: lineOf(st), endLine: lineOf(le - 1), text: src.slice(st + 2, le), long: true }); i = le; continue; }
      let e = src.indexOf('\n', i); if (e < 0) e = n; comments.push({ start: st, end: e, line: lineOf(st), endLine: lineOf(st), text: src.slice(st + 2, e), long: false }); i = e; continue;
    }
    if (c === '\n' || c === ' ' || c === '\t' || c === '\r') { i++; continue; }
    if (c === '"' || c === "'") {
      const st = i; i++; while (i < n && src[i] !== c && src[i] !== '\n') { if (src[i] === '\\') i++; i++; }
      i++; toks.push({ t: 'str', s: st, e: i, v: src.slice(st + 1, i - 1), q: c }); continue;
    }
    if (c === '[') { const le = longEnd(src, i); if (le > 0) { toks.push({ t: 'lstr', s: i, e: le }); i = le; continue; } toks.push({ t: 'p', s: i, e: i + 1, v: '[' }); i++; continue; }
    if (/[0-9]/.test(c) || (c === '.' && /[0-9]/.test(src[i + 1] || ''))) { const m = /^(0[xX][0-9a-fA-F]+|\d+\.?\d*(?:[eE][+-]?\d+)?|\.\d+(?:[eE][+-]?\d+)?)/.exec(src.slice(i, i + 40)); toks.push({ t: 'num', s: i, e: i + m[0].length, v: m[0] }); i += m[0].length; continue; }
    if (/[A-Za-z_]/.test(c)) { const m = /^[A-Za-z_][A-Za-z0-9_]*/.exec(src.slice(i, i + 80)); toks.push({ t: 'id', s: i, e: i + m[0].length, v: m[0] }); i += m[0].length; continue; }
    if (c === '.' && src[i + 1] === '.') { const l = src[i + 2] === '.' ? 3 : 2; toks.push({ t: 'p', s: i, e: i + l, v: src.slice(i, i + l) }); i += l; continue; }
    const two = src.slice(i, i + 2); if (['==', '~=', '<=', '>=', '//', '<<', '>>', '::'].includes(two)) { toks.push({ t: 'p', s: i, e: i + 2, v: two }); i += 2; continue; }
    toks.push({ t: 'p', s: i, e: i + 1, v: c }); i++;
  }
  return { toks, comments, lineOf };
}

function parse(src) {
  const { toks, comments, lineOf } = lex(src); const out = []; let p = 0;
  const byLine = new Map(); for (const c of comments) if (!c.long) byLine.set(c.line, c.text.trim());
  const codeLines = new Set(); for (const t of toks) { codeLines.add(lineOf(t.s)); }
  const commentFor = (line, endLine) => { // commentaire sur la même ligne (après la valeur) sinon ligne(s) juste au-dessus
    if (byLine.has(endLine)) { const t = byLine.get(endLine); if (t && !/^[-=─_*#\s]+$/.test(t)) return t; }
    const above = []; for (let l = line - 1; l >= 1 && byLine.has(l) && !codeLines.has(l) && above.length < 3; l--) { const t = byLine.get(l); if (/^[-=─_*#\s]*$/.test(t)) break; above.unshift(t); }
    return above.join(' ');
  };
  const peek = k => toks[p + (k || 0)];
  const isP = (t, v) => t && t.t === 'p' && t.v === v;
  function skipExpr() { // saute une expression complexe jusqu'au séparateur de même niveau
    let depth = 0, blocks = 0;
    while (p < toks.length) {
      const t = toks[p];
      if (t.t === 'p') { if ('([{'.includes(t.v)) depth++; else if (')]}'.includes(t.v)) { if (depth === 0) break; depth--; } else if ((t.v === ',' || t.v === ';') && depth === 0 && blocks === 0) break; }
      else if (t.t === 'id') { if (KW_OPEN.has(t.v)) blocks++; else if (KW_CLOSE.has(t.v)) blocks--; }
      p++;
    }
  }
  function parseTable(path) {
    // p est juste après « { »
    let idx = 0; const rowStart = out.length;
    while (p < toks.length) {
      const t = peek(); if (!t) break;
      if (isP(t, '}')) { p++; break; }
      if (isP(t, ',') || isP(t, ';')) { p++; continue; }
      let key = null, mark = p;
      if (t.t === 'id' && isP(peek(1), '=') ) { key = t.v; p += 2; }
      else if (isP(t, '[') && (peek(1).t === 'str' || peek(1).t === 'num') && isP(peek(2), ']') && isP(peek(3), '=')) { key = peek(1).t === 'str' ? peek(1).v : Number(peek(1).v); p += 4; }
      const seg = key === null ? ++idx : key; const here = path.concat([seg]);
      const v = peek(); if (!v) break;
      if (isP(v, '{')) { p++; parseTable(here); continue; }
      let sign = '', first = v;
      if (isP(v, '-') && peek(1) && peek(1).t === 'num') { sign = '-'; first = peek(1); }
      const after = toks[p + (sign ? 2 : 1)];
      const ends = !after || isP(after, ',') || isP(after, ';') || isP(after, '}');
      if (ends && (first.t === 'num' || first.t === 'str' || (first.t === 'id' && (first.v === 'true' || first.v === 'false')))) {
        const s = sign ? v.s : first.s, e = first.e; const ln = lineOf(s), le = lineOf(e - 1);
        const ent = { path: here, kind: first.t === 'num' ? 'number' : first.t === 'str' ? 'string' : 'boolean', raw: src.slice(s, e), start: s, end: e, line: ln, comment: commentFor(ln, le) };
        if (ent.kind === 'string') ent.quote = first.q;
        if (ent.kind === 'number') ent.value = Number(sign + first.v); else if (ent.kind === 'boolean') ent.value = first.v === 'true'; else ent.value = first.v.replace(/\\(["'\\])/g, '$1').replace(/\\n/g, '\n');
        out.push(ent); p += sign ? 2 : 1; continue;
      }
      skipExpr();
    }
    // étiquette de ligne : valeur de name / label de la ligne (ex : { name = "Pistolet", price = 500 })
    let lab = null; if (typeof path[path.length - 1] === 'number') for (let k = rowStart; k < out.length; k++) { const e = out[k]; if (e.path.length === path.length + 1 && e.kind === 'string' && ['name', 'label', 'Name', 'Label', 'nom'].includes(e.path[e.path.length - 1])) { lab = e.value; break; } }
    if (lab) for (let k = rowStart; k < out.length; k++) if (out[k].path.length > path.length && !out[k].rowLabel) out[k].rowLabel = { depth: path.length, text: lab };
  }
  while (p < toks.length) {
    const t = peek();
    if (t.t === 'id' && t.v === 'local') { p++; continue; }
    if (t.t === 'id' && !KW_OPEN.has(t.v) && !KW_CLOSE.has(t.v)) {
      // Nom(.Nom)* = valeur
      let q = p, name = [t.v]; q++;
      while (isP(toks[q], '.') && toks[q + 1] && toks[q + 1].t === 'id') { name.push(toks[q + 1].v); q += 2; }
      if (isP(toks[q], '=') ) { p = q + 1; const v = peek(); if (!v) break; if (isP(v, '{')) { p++; parseTable(name); } else { const before = p; const sign = isP(v, '-') ? 1 : 0; const f = toks[p + sign]; const after = toks[p + sign + 1]; const lineEnd = !after || after.s > f.e && src.slice(f.e, after.s).includes('\n') || isP(after, ';');
        if (f && (f.t === 'num' || f.t === 'str' || (f.t === 'id' && (f.v === 'true' || f.v === 'false'))) && lineEnd) { const s = sign ? v.s : f.s; const ln = lineOf(s); const ent = { path: name, kind: f.t === 'num' ? 'number' : f.t === 'str' ? 'string' : 'boolean', raw: src.slice(s, f.e), start: s, end: f.e, line: ln, comment: commentFor(ln, lineOf(f.e - 1)) }; if (ent.kind === 'string') ent.quote = f.q; ent.value = ent.kind === 'number' ? Number((sign ? '-' : '') + f.v) : ent.kind === 'boolean' ? f.v === 'true' : f.v; out.push(ent); p = p + sign + 1; }
        else { p = before; skipExpr(); } }
        continue; }
      p++; continue;
    }
    if (t.t === 'id' && KW_OPEN.has(t.v)) { // bloc de code (fonction, if…) : on le saute entièrement
      let depth = 0; while (p < toks.length) { const x = toks[p]; if (x.t === 'id') { if (KW_OPEN.has(x.v)) depth++; else if (KW_CLOSE.has(x.v)) { depth--; if (depth === 0) { p++; break; } } } p++; } continue;
    }
    p++;
  }
  return out;
}

const luaStr = (s, q) => { q = q === '"' ? '"' : "'"; return q + String(s).replace(/\\/g, '\\\\').replace(/\r?\n/g, '\\n').split(q).join('\\' + q) + q; };
function rawFor(ent, value) {
  if (ent.kind === 'number') { const n = Number(value); if (!Number.isFinite(n) || Math.abs(n) > 1e12) throw new Error('nombre invalide'); return String(n); }
  if (ent.kind === 'boolean') { if (value !== true && value !== false) throw new Error('vrai / faux attendu'); return value ? 'true' : 'false'; }
  const s = String(value); if (s.length > 500 || /[\u0000-\u0008\u000b\u000c\u000e-\u001f]/.test(s)) throw new Error('texte invalide'); return luaStr(s, ent.quote);
}
// edits : [{ start, end, old, value }] — chaque modification est vérifiée contre le texte actuel (refusée si le fichier a changé entre-temps)
function apply(src, edits) {
  const ents = parse(src); const by = new Map(ents.map(e => [e.start + ':' + e.end, e])); const list = [];
  for (const ed of edits) {
    const e = by.get(ed.start + ':' + ed.end); if (!e || e.raw !== ed.old) throw new Error('Le fichier a changé depuis son ouverture : recharge la page');
    const raw = rawFor(e, ed.value); if (e.kind === 'number' ? Number(ed.value) === e.value : ed.value === e.value) continue;   // valeur inchangée : on garde l'écriture d'origine (1.0, 0x10…)
    list.push({ e, raw });
  }
  list.sort((a, b) => b.e.start - a.e.start); let out = src; for (const x of list) out = out.slice(0, x.e.start) + x.raw + out.slice(x.e.end);
  if (parse(out).length !== ents.length) throw new Error('Modification refusée : la structure du fichier serait altérée');
  return out;
}
module.exports = { parse, apply, lex };
