'use strict';
// Page « Fichiers » : explorateur, éditeur avec coloration, historique + comparaison, assistant IA
function tokenize(text, lang) {
  const esc = s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  let re, kw;
  if (lang === 'lua') { re = /(--\[(=*)\[[\s\S]*?\]\2\]|--[^\n]*)|("(?:\\.|[^"\\\n])*"|'(?:\\.|[^'\\\n])*'|\[(=*)\[[\s\S]*?\]\4\]|`[^`\n]*`)|(\b\d+\.?\d*(?:e[+-]?\d+)?\b|\b0x[\da-f]+\b)|([A-Za-z_]\w*)/gi; kw = new Set('and break do else elseif end false for function goto if in local nil not or repeat return then true until while'.split(' ')); }
  else if (lang === 'json') { re = /()("(?:\\.|[^"\\\n])*")(?=\s*:)?|()()(-?\b\d+\.?\d*(?:e[+-]?\d+)?\b)|([A-Za-z_]\w*)/gi; kw = new Set(['true', 'false', 'null']); }
  else if (lang === 'js') { re = /(\/\/[^\n]*|\/\*[\s\S]*?\*\/)|("(?:\\.|[^"\\\n])*"|'(?:\\.|[^'\\\n])*'|`(?:\\.|[^`\\])*`)|(\b\d+\.?\d*\b)|([A-Za-z_$][\w$]*)/g; kw = new Set('const let var function return if else for while new class import export from true false null undefined await async'.split(' ')); }
  else if (lang === 'cfg') { re = /(#[^\n]*|\/\/[^\n]*)|("(?:\\.|[^"\\\n])*")|(\b\d+\b)|(\b(?:set|setr|sets|add_ace|add_principal|ensure|start|stop|exec|sv_[a-z]+)\b)/g; kw = null; }
  else return esc(text);
  let out = '', last = 0, m;
  while ((m = re.exec(text))) {
    if (m[0] === '') { re.lastIndex++; continue; }
    out += esc(text.slice(last, m.index)); last = m.index + m[0].length; const t = esc(m[0]);
    if (lang === 'lua') out += m[1] ? `<i class="c">${t}</i>` : m[3] ? `<i class="s">${t}</i>` : m[5] ? `<i class="n">${t}</i>` : m[6] ? (kw.has(m[6].toLowerCase()) ? `<i class="k">${t}</i>` : t) : t;
    else if (lang === 'json') out += m[2] ? `<i class="${/:\s*$/.test(text.slice(last, last + 4)) || text[last] === ':' ? 'k' : 's'}">${t}</i>` : m[5] ? `<i class="n">${t}</i>` : m[6] ? (kw.has(m[6]) ? `<i class="k">${t}</i>` : t) : t;
    else if (lang === 'js') out += m[1] ? `<i class="c">${t}</i>` : m[2] ? `<i class="s">${t}</i>` : m[3] ? `<i class="n">${t}</i>` : m[4] && kw.has(m[4]) ? `<i class="k">${t}</i>` : t;
    else out += m[1] ? `<i class="c">${t}</i>` : m[2] ? `<i class="s">${t}</i>` : m[3] ? `<i class="n">${t}</i>` : `<i class="k">${t}</i>`;
  }
  return out + esc(text.slice(last));
}
const langOf = p => { const e = (p.split('.').pop() || '').toLowerCase(); return { lua: 'lua', json: 'json', js: 'js', cfg: 'cfg', meta: 'plain' }[e] || 'plain'; };
// comparaison ligne à ligne (plus longue sous-séquence commune, avec rognage des extrémités)
function lineDiff(a, b) {
  const A = a.split('\n'), B = b.split('\n'); let s = 0; while (s < A.length && s < B.length && A[s] === B[s]) s++; let ea = A.length, eb = B.length; while (ea > s && eb > s && A[ea - 1] === B[eb - 1]) { ea--; eb--; }
  const x = A.slice(s, ea), y = B.slice(s, eb), out = []; for (let i = 0; i < s; i++) out.push([' ', A[i], i + 1]);
  if (x.length * y.length > 4e6) { x.forEach(l => out.push(['-', l])); y.forEach(l => out.push(['+', l])); }
  else { const n = x.length, m = y.length, dp = Array.from({ length: n + 1 }, () => new Uint16Array(m + 1)); for (let i = n - 1; i >= 0; i--) for (let j = m - 1; j >= 0; j--) dp[i][j] = x[i] === y[j] ? dp[i + 1][j + 1] + 1 : Math.max(dp[i + 1][j], dp[i][j + 1]); let i = 0, j = 0; while (i < n && j < m) { if (x[i] === y[j]) { out.push([' ', x[i]]); i++; j++; } else if (dp[i + 1][j] >= dp[i][j + 1]) out.push(['-', x[i++]]); else out.push(['+', y[j++]]); } while (i < n) out.push(['-', x[i++]]); while (j < m) out.push(['+', y[j++]]); }
  for (let i = ea; i < A.length; i++) out.push([' ', A[i]]); return out;
}
function diffView(oldT, newT) {
  const rows = lineDiff(oldT, newT); const keep = new Array(rows.length).fill(false); rows.forEach((r, i) => { if (r[0] !== ' ') for (let k = Math.max(0, i - 3); k <= Math.min(rows.length - 1, i + 3); k++) keep[k] = true; });
  const box = el('div', { class: 'diff' }); let skipped = 0; const flush = () => { if (skipped) { box.append(el('div', { class: 'dl sk' }, `… ${skipped} ligne(s) identiques …`)); skipped = 0; } };
  rows.forEach((r, i) => { if (!keep[i]) { skipped++; return; } flush(); box.append(el('div', { class: 'dl ' + ({ '+': 'add', '-': 'del', ' ': '' }[r[0]]) }, el('span', { class: 'sg' }, r[0]), r[1])); }); flush();
  const add = rows.filter(r => r[0] === '+').length, del = rows.filter(r => r[0] === '-').length; if (!add && !del) box.append(el('div', { class: 'empty' }, 'Aucune différence'));
  return { box, add, del };
}

PAGES.files = async function () {
  const s = curServer(); if (!s) return needServer();
  const open = []; let active = null, panel = 'history'; let aiInfo = (await api('GET', `/api/servers/${s.id}/ai/status`)) || {};
  const tree = el('div', { class: 'tree' }), tabs = el('div', { class: 'ftabs' }), main = el('div', { class: 'fmain' }), side = el('div', { class: 'fside' }), status = el('div', { class: 'fstat' });
  const q = el('input', { placeholder: 'Rechercher un fichier…', style: 'margin:8px 0' });
  const expanded = new Set(); const cache = {};
  async function loadDir(path, box, depth) {
    const r = cache[path] || (cache[path] = await api('GET', `/api/servers/${s.id}/fs/list?path=${encodeURIComponent(path)}`));
    if (!r.ok) { box.append(el('div', { class: 'muted', style: 'padding:6px 10px' }, r.error)); return; }
    for (const e of r.data.entries) {
      const full = path ? path + '/' + e.name : e.name; if (q.value && e.type === 'file' && !full.toLowerCase().includes(q.value.toLowerCase())) continue;
      if (e.type === 'dir') { const open_ = expanded.has(full); const row = el('div', { class: 'tr dir', style: `padding-left:${8 + depth * 14}px`, onclick: async () => { if (expanded.has(full)) expanded.delete(full); else expanded.add(full); await drawTree(); } }, (open_ ? '▾ ' : '▸ ') + e.name); box.append(row); if (open_) await loadDir(full, box, depth + 1); }
      else box.append(el('div', { class: 'tr file' + (active && active.path === full ? ' on' : ''), style: `padding-left:${8 + depth * 14}px`, onclick: () => openFile(full) }, e.name));
    }
  }
  async function drawTree() { const t = el('div'); await loadDir('', t, 0); tree.replaceChildren(t); }
  async function openFile(path) {
    let f = open.find(x => x.path === path);
    if (!f) { status.textContent = 'Chargement…'; const r = await api('GET', `/api/servers/${s.id}/fs/read?path=${encodeURIComponent(path)}`); status.textContent = ''; if (!r.ok) return toast(r.error, 'bad'); f = { path, text: r.content, orig: r.content, lang: langOf(path) }; open.push(f); }
    active = f; drawAll(); loadHistory();
  }
  const dirty = f => f.text !== f.orig;
  async function save(f, note) { const r = await post(`/api/servers/${s.id}/fs/write`, { path: f.path, content: f.text, note }); if (!r.ok) { toast(r.error, 'bad'); return false; } f.orig = f.text; toast('Enregistré sur le serveur', 'ok'); drawAll(); loadHistory(); return true; }
  function drawTabs() { tabs.replaceChildren(...open.map(f => el('div', { class: 'ftab' + (f === active ? ' on' : ''), onclick: () => { active = f; drawAll(); loadHistory(); } }, f.path.split('/').pop() + (dirty(f) ? ' ●' : ''), el('b', { onclick: e => { e.stopPropagation(); if (dirty(f) && !confirm('Fermer sans enregistrer ?')) return; open.splice(open.indexOf(f), 1); if (active === f) active = open[open.length - 1] || null; drawAll(); } }, '×'))), el('button', { class: 'btn s', style: 'margin:4px 8px', onclick: () => ask('Nouveau fichier', [{ name: 'path', label: 'Chemin (ex : pickax_core/mon_fichier.lua)' }], async v => { const r = await post(`/api/servers/${s.id}/fs/create`, { path: v.path.trim(), content: '' }); if (!r.ok) { toast(r.error, 'bad'); return false; } for (const k in cache) delete cache[k]; await drawTree(); openFile(v.path.trim()); }) }, el('span', {}, '+ Nouveau'))); }
  function editor(f) {
    const gut = el('div', { class: 'gut' }), hl = el('pre', { class: 'hl' }), ta = el('textarea', { spellcheck: false, wrap: 'off', value: f.text });
    const refresh = () => { f.text = ta.value; const n = f.text.split('\n').length; gut.textContent = Array.from({ length: n }, (_, i) => i + 1).join('\n'); hl.innerHTML = tokenize(f.text, f.lang) + '\n'; statusLine(); drawTabsLight(); };
    const sync = () => { hl.scrollTop = ta.scrollTop; hl.scrollLeft = ta.scrollLeft; gut.scrollTop = ta.scrollTop; };
    ta.addEventListener('input', refresh); ta.addEventListener('scroll', sync);
    ta.addEventListener('keydown', e => { if (e.key === 'Tab') { e.preventDefault(); const a = ta.selectionStart; ta.setRangeText('    ', a, ta.selectionEnd, 'end'); refresh(); } if ((e.ctrlKey || e.metaKey) && e.key === 's') { e.preventDefault(); if (dirty(f)) ask('Enregistrer', [{ name: 'note', label: 'Note (facultatif)' }], v => save(f, v.note)); } });
    ta.addEventListener('keyup', statusLine); ta.addEventListener('click', statusLine);
    const wrap = el('div', { class: 'ed' }, gut, el('div', { class: 'edin' }, hl, ta)); setTimeout(() => { refresh(); }, 0); return wrap;
    function statusLine() { const pos = ta.value.slice(0, ta.selectionStart).split('\n'); status.textContent = `${f.path} · Ligne ${pos.length}, col. ${pos[pos.length - 1].length + 1} · ${f.text.split('\n').length} lignes · ${f.text.length} car. · ${f.lang}`; }
    function drawTabsLight() { const t = tabs.querySelector('.ftab.on'); if (t) t.firstChild.textContent = f.path.split('/').pop() + (dirty(f) ? ' ●' : ''); }
  }
  function drawMain() {
    if (!active) { main.replaceChildren(el('div', { class: 'empty', style: 'margin:auto' }, el('h2', {}, 'Aucun fichier ouvert'), 'Sélectionne un fichier dans l’explorateur.')); return; }
    const f = active; main.replaceChildren(editor(f), el('div', { class: 'fbar' }, el('span', { class: 'muted' }, f.path), el('div', { class: 'grow' }),
      aiInfo.enabled ? el('button', { class: 'btn s', onclick: () => { panel = 'ai'; drawSide(); } }, el('span', {}, 'Assistant IA')) : null, el('button', { class: 'btn s', onclick: () => { panel = 'history'; drawSide(); } }, el('span', {}, 'Historique')),
      el('button', { class: 'btn s', disabled: !dirty(f), onclick: () => showDiff(f.orig, f.text, 'Modifications non enregistrées', null) }, el('span', {}, 'Voir les changements')),
      el('button', { class: 'btn s p', disabled: !dirty(f), onclick: () => ask('Enregistrer', [{ name: 'note', label: 'Note (facultatif)' }], v => save(f, v.note)) }, el('span', {}, 'Sauvegarder'))));
  }
  function showDiff(a, b, title, onApply, applyLabel) {
    const d = diffView(a, b); modalWide(title + `  (+${d.add} −${d.del})`, d.box, close => [el('button', { class: 'btn', onclick: close }, el('span', {}, 'Fermer')), onApply ? el('button', { class: 'btn p', onclick: async () => { if (await onApply() !== false) close(); } }, el('span', {}, applyLabel || 'Appliquer')) : null]);
  }
  function modalWide(title, body, actions) { const m = el('div', { class: 'modal', onclick: e => { if (e.target === m) m.remove(); } }, el('div', { class: 'box', style: 'width:min(1000px,100%)' }, el('h2', {}, title), body, el('div', { class: 'row', style: 'margin-top:14px;justify-content:flex-end' }, ...actions(() => m.remove())))); document.body.append(m); }
  async function loadHistory() { if (panel !== 'history') return; drawSide(); }
  async function drawSide() {
    if (!active) { side.replaceChildren(el('div', { class: 'muted', style: 'padding:14px' }, 'Ouvre un fichier pour voir son historique.')); return; }
    const f = active;
    if (panel === 'ai') {
      const inp = el('textarea', { rows: 4, placeholder: 'Décris la modification (ex : désactive les headshots)…' }); const out = el('div', { class: 'muted', style: 'margin-top:10px' }); const quota = `${aiInfo.used || 0}/${aiInfo.limit || 0} demandes aujourd’hui`;
      side.replaceChildren(el('div', { class: 'sh' }, el('b', {}, 'ASSISTANT IA'), el('button', { class: 'x', onclick: () => { panel = 'history'; drawSide(); } }, '×')), el('div', { style: 'padding:12px' }, el('p', { class: 'muted' }, 'Décris une modification en langage naturel : l’assistant propose un diff que tu valides avant application. Il travaille sur le fichier ouvert.'), inp, el('div', { class: 'row', style: 'margin-top:8px' }, el('span', { class: 'muted', style: 'font-size:12px' }, quota), el('div', { class: 'grow' }), el('button', { class: 'btn s p', onclick: async function () {
        if (!inp.value.trim()) return; out.textContent = 'Réflexion…'; this.disabled = true; const r = await post(`/api/servers/${s.id}/ai`, { path: f.path, instruction: inp.value, content: f.text }); this.disabled = false; aiInfo = await api('GET', `/api/servers/${s.id}/ai/status`);
        if (!r.ok) { out.textContent = r.error + (r.note ? ' — ' + r.note : ''); return; } out.replaceChildren(el('p', {}, r.note || 'Proposition prête.'));
        if (!r.changed) return; out.append(el('button', { class: 'btn s', onclick: () => showDiff(f.text, r.content, 'Proposition de l’assistant IA', async () => { f.text = r.content; return save(f, 'Assistant IA : ' + inp.value.slice(0, 80)); }, 'Appliquer et enregistrer') }, el('span', {}, 'Voir le diff')));
      } }, el('span', {}, 'Envoyer'))), out)); return;
    }
    side.replaceChildren(el('div', { class: 'sh' }, el('b', {}, 'HISTORIQUE'), el('span', { class: 'muted' }, '…')));
    const r = await api('GET', `/api/servers/${s.id}/fs/versions?path=${encodeURIComponent(f.path)}`); if (active !== f || panel !== 'history') return;
    side.replaceChildren(el('div', { class: 'sh' }, el('b', {}, 'HISTORIQUE'), el('span', { class: 'muted' }, (r.versions || []).length + ' versions')), ...(r.versions || []).map((v, i) => el('div', { class: 'ver' }, el('div', { class: 'row' }, el('b', {}, 'v' + ((r.versions.length) - i)), i === 0 ? el('span', { class: 'pill ok' }, 'actuelle') : null, el('div', { class: 'grow' }), el('span', { class: 'muted', style: 'font-size:12px' }, fmtDate(v.at))), el('div', { class: 'muted', style: 'font-size:12px' }, `${(v.size / 1024).toFixed(1)} Ko · ${v.by_name || '—'}${v.note ? ' · ' + v.note : ''}`),
      el('div', { class: 'row', style: 'margin-top:4px' }, el('button', { class: 'btn s', onclick: async () => { const x = await api('GET', `/api/servers/${s.id}/fs/version/${v.id}`); if (x.ok) showDiff(x.version.content, f.text, `Version v${r.versions.length - i} → éditeur`, null); } }, el('span', {}, 'Comparer')), i > 0 ? el('button', { class: 'btn s', onclick: () => confirmBox('Restaurer', 'Remettre cette version sur le serveur ?', async () => { const x = await post(`/api/servers/${s.id}/fs/restore`, { vid: v.id }); if (!x.ok) return toast(x.error, 'bad'); const y = await api('GET', `/api/servers/${s.id}/fs/version/${v.id}`); f.text = f.orig = y.version.content; toast('Version restaurée', 'ok'); drawAll(); loadHistory(); }) }, el('span', {}, 'Restaurer')) : null))));
  }
  function drawAll() { drawTabs(); drawMain(); if (!active) drawSide(); drawTree(); }
  q.addEventListener('input', () => drawTree());
  const page = el('div', { class: 'files' }, el('div', { class: 'top' }, el('div', {}, el('h1', {}, 'Fichiers'), el('div', { class: 'muted' }, 'Modifie les fichiers de configuration de ton serveur (dossier resources/). Chaque enregistrement crée une version restaurable.')), el('div', { class: 'grow' }), s.online ? null : el('span', { class: 'pill bad' }, 'Serveur hors ligne')),
    el('div', { class: 'fwrap' }, el('div', { class: 'fexp' }, el('div', { class: 'sh' }, el('b', {}, 'EXPLORATEUR'), el('button', { class: 'x', title: 'Actualiser', onclick: () => { for (const k in cache) delete cache[k]; drawTree(); } }, '⟳')), el('div', { style: 'padding:0 8px' }, q), tree), el('div', { class: 'fcenter' }, tabs, main, status), side));
  setTimeout(() => { drawAll(); }, 0); return page;
};
