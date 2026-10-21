'use strict';
const res = () => (typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'pickax_minigames');
const rpc = (name, ...args) => fetch(`https://${res()}/rpc`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ name, args: args.map(a => (a === undefined || a === null ? 0 : a)) }) })
  .then(r => r.json()).catch(() => ({ ok: false, error: 'Aucune réponse' }));
const $ = (s, r = document) => r.querySelector(s);
const $$ = (s, r = document) => [...r.querySelectorAll(s)];
const esc = s => String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const snd = n => { try { window.PKSND && PKSND.play(n); } catch (e) {} };

// ── Icônes ────────────────────────────────────────────────────────────────────
const IC = {
  basket: '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3v18M5.6 5.6c3 3 3 9.8 0 12.8M18.4 5.6c-3 3-3 9.8 0 12.8"/>',
  football: '<circle cx="12" cy="12" r="9"/><path d="M12 8l3.5 2.5-1.3 4h-4.4l-1.3-4zM12 8V3M15.5 10.5l4.7-1.6M14.2 14.5l3 4M9.8 14.5l-3 4M8.5 10.5L3.8 8.9"/>',
  tennis: '<circle cx="12" cy="12" r="9"/><path d="M5 5.5c4 3 4 10 0 13M19 5.5c-4 3-4 10 0 13"/>',
  boxing: '<path d="M7 11V8a4 4 0 014-4h2a4 4 0 014 4v4a5 5 0 01-5 5H9a2 2 0 01-2-2zM7 14H5a1 1 0 01-1-1v-2a1 1 0 011-1h2M9 20.5h6"/>',
  paintball: '<circle cx="12" cy="12" r="3"/><circle cx="12" cy="12" r="8"/><path d="M12 1.5v3M12 19.5v3M1.5 12h3M19.5 12h3"/>',
  laser: '<path d="M13 2L5 14h6l-1 8 8-12h-6z"/>',
  race: '<path d="M5 21V4M5 4h13l-2.5 4L18 12H5"/>',
  bowling: '<circle cx="9" cy="15" r="6"/><path d="M7 13.5h.01M10 13h.01M9.5 16.2h.01M17 3c1.2 2 .6 3.2-.2 4.6S16.6 10 17.4 11.2 17.4 14 15.4 14.5"/>',
  darts: '<circle cx="12" cy="12" r="8"/><circle cx="12" cy="12" r="4"/><path d="M12 12L21 3M17 3h4v4"/>',
  brawl: '<path d="M7 20v-5l-2-3V8l2-1 2 2 2-3 2 1 2-2 2 1v9l-3 4z"/>',
  padel: '<ellipse cx="10" cy="9.5" rx="6" ry="7" transform="rotate(-35 10 9.5)"/><path d="M14.5 15L20.5 21M8 6.5l3 3M6.5 9l3 3"/>',
  volley: '<circle cx="12" cy="12" r="9"/><path d="M12 3c-3 4-3 8 0 9s6 5 6 8M3.5 9c5 0 8 2 8.5 3M20.5 10c-4 1-6 4-6 8"/>',
  kart: '<path d="M3 16l2-5h9l3 3h4v2M3 16v2h18v-2"/><circle cx="7" cy="18" r="1.8"/><circle cx="17" cy="18" r="1.8"/>',
  car: '<path d="M5 16l1.6-5a2 2 0 012-1.4h7a2 2 0 012 1.4L19 16M3 16h18v3H3z"/><circle cx="7.5" cy="19" r="1.6"/><circle cx="16.5" cy="19" r="1.6"/>',
  moto: '<circle cx="6" cy="16" r="3"/><circle cx="18" cy="16" r="3"/><path d="M6 16l4-6h5l3 6M10 10L9 7H7"/>',
  quad: '<circle cx="6" cy="17" r="2.6"/><circle cx="18" cy="17" r="2.6"/><path d="M6 17h12M8.5 17l2.5-6h4l2 6M11 11V8h3"/>',
  boat: '<path d="M3 15h18l-3 5H6zM12 15V4l6 9z"/>',
  golf: '<path d="M8 21V4l8 4-8 4M5 21h8"/><circle cx="17" cy="19" r="1.6"/>',
  drag: '<path d="M3 17h18M5 17l1.5-5h8l3 3.5M3 8h5M2 11h4"/><circle cx="8" cy="17.5" r="1.7"/><circle cx="16" cy="17.5" r="1.7"/>',
  parkour: '<circle cx="14" cy="5" r="1.8"/><path d="M8 21l3-6-2-3 4-3 3 2 3 1M11 15l4 1 1 5M9 12l-3 1"/>',
  sparkle: '<path d="M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8zM19 16l.7 2 2 .7-2 .7-.7 2-.7-2-2-.7 2-.7z"/>',
  user: '<circle cx="12" cy="8" r="4"/><path d="M4 21c1-4 4-6 8-6s7 2 8 6"/>',
  search: '<circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/>',
  plus: '<path d="M12 5v14M5 12h14"/>',
  trash: '<path d="M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3"/>',
  copy: '<rect x="8" y="8" width="12" height="12" rx="2"/><path d="M16 8V6a2 2 0 00-2-2H6a2 2 0 00-2 2v8a2 2 0 002 2h2"/>',
  pin: '<path d="M12 21s7-6.2 7-11.5A7 7 0 005 9.5C5 14.8 12 21 12 21z"/><circle cx="12" cy="9.5" r="2.5"/>',
  aim: '<circle cx="12" cy="12" r="8"/><circle cx="12" cy="12" r="2"/><path d="M12 2v4M12 18v4M2 12h4M18 12h4"/>',
  go: '<path d="M5 12h14M13 6l6 6-6 6"/>',
  x: '<path d="M6 6l12 12M18 6L6 18"/>',
  check: '<path d="M5 12.5l4.5 4.5L19 7.5"/>',
  warn: '<path d="M12 3l10 18H2zM12 10v5M12 18.5v.01"/>',
  list: '<path d="M8 6h13M8 12h13M8 18h13M3.5 6h.01M3.5 12h.01M3.5 18h.01"/>',
  trophy: '<path d="M8 21h8M12 17v4M7 4h10v5a5 5 0 01-10 0zM17 5h3v2a3 3 0 01-3 3M7 5H4v2a3 3 0 003 3"/>',
};
const ic = n => `<svg class="ic" viewBox="0 0 24 24">${IC[n] || ''}</svg>`;
const TCOL = { basket: ['#ff9f0a', '#ff6a00'], football: ['#34c759', '#1f9d45'], tennis: ['#c8e61f', '#8fb300'], boxing: ['#ff453a', '#c9211a'], paintball: ['#ff375f', '#c4113a'], laser: ['#7d7aff', '#4a46d6'], race: ['#0a84ff', '#0558c4'], bowling: ['#5e5ce6', '#3634a3'], darts: ['#ff6482', '#c93a5a'], brawl: ['#ff9500', '#b85c00'], padel: ['#40c8e0', '#1a8fa8'], volley: ['#ffd60a', '#c79a00'], kart: ['#ff3b30', '#b0150d'], car: ['#64d2ff', '#2a8fbf'], moto: ['#bf5af2', '#7d2ea8'], quad: ['#a2845e', '#6b5236'], boat: ['#32ade6', '#1b6f99'], golf: ['#30d158', '#1b8a3a'], drag: ['#ff9f0a', '#b86a00'], parkour: ['#ac8e68', '#6e5a3c'] };
const ICON_OF = { lasertag: 'laser', karting: 'kart' };
const tile = (type, cls = '') => { const t = ICON_OF[type] || type; const c = TCOL[type] || TCOL[t] || ['#8e8e93', '#636366']; return `<div class="tile ${cls}" style="background:linear-gradient(160deg,${c[0]},${c[1]})">${ic(t)}</div>`; };
const fmtT = s => { s = Math.max(0, Math.floor(s)); return Math.floor(s / 60) + ':' + String(s % 60).padStart(2, '0'); };
const fmtMs = ms => { ms = Math.max(0, Math.floor(ms)); const m = Math.floor(ms / 60000), s = Math.floor(ms / 1000) % 60, c = Math.floor((ms % 1000) / 10); return m + ':' + String(s).padStart(2, '0') + '.' + String(c).padStart(2, '0'); };

function toast(msg, kind = 'ok') {
  const t = document.createElement('div');
  t.className = 'toast ' + kind;
  t.innerHTML = ic(kind === 'err' ? 'warn' : 'check') + esc(msg);
  $('#toasts').appendChild(t);
  snd(kind === 'err' ? 'error' : 'success');
  setTimeout(() => t.remove(), 3200);
}

// ── Feuilles modales ──────────────────────────────────────────────────────────
function sheet(title, sub, bodyHtml, buttons, wide) {
  const m = $('#modal');
  m.innerHTML = `<div class="sheet ${wide ? 'wide' : ''}"><div class="sheet-h">${esc(title)}</div>${sub ? `<div class="sheet-s">${esc(sub)}</div>` : ''}<div class="sheet-body">${bodyHtml || ''}</div><div class="sheet-f">${(buttons || []).map((b, i) => `<button class="btn ${b.cls || ''}" data-b="${i}">${esc(b.label)}</button>`).join('')}</div></div>`;
  m.classList.remove('hidden');
  snd('open');
  $$('[data-b]', m).forEach(el => el.onclick = () => { const b = buttons[+el.dataset.b]; if (!b.keep) closeSheet(); if (b.fn) b.fn(); });
  m.onclick = e => { if (e.target === m) closeSheet(); };
}
function closeSheet() { $('#modal').classList.add('hidden'); $('#modal').innerHTML = ''; }
function askConfirm(title, text, label, fn, danger) {
  sheet(title, text, '', [{ label: 'Annuler' }, { label, cls: danger ? 'red' : 'pri', fn }]);
}

// ══════════════════════════════════════════════════════════════════════════════
//  BUILDER
// ══════════════════════════════════════════════════════════════════════════════
const S = { mode: 'games', prog: null, pt: 'xp', pgames: [], pfeat: null, catalog: null, list: [], cur: null, curId: null, dirty: false, tab: 'general', q: '', stats: null };
const typeOf = k => (S.catalog ? S.catalog.types.find(t => t.key === k) : null);

const getP = (o, p) => p.split('.').reduce((a, k) => (a == null ? a : a[k]), o);
const setP = (o, p, v) => { const ks = p.split('.'); const last = ks.pop(); const t = ks.reduce((a, k) => a[k], o); t[last] = v; };

function localProblems(d) {
  const T = typeOf(d.type); if (!T) return [];
  const out = [];
  T.points.forEach(pt => {
    const v = d.points[pt.key];
    if (pt.single ? !v : (!v || !v.length)) out.push('Point manquant : ' + pt.label);
  });
  if (T.engine === 'tag' && String(d.settings.teams) === '2') {
    const sp = d.points.spawns || []; if (!sp.some(s => s.team === 1 || !s.team) || !sp.some(s => s.team === 2)) out.push('Mode équipes : place des points d\'apparition pour chaque équipe');
  }
  if (T.engine === 'fight' && (d.points.spawns || []).length < 2) out.push('Boxe : 2 coins de ring sont nécessaires');
  return out;
}

async function loadBuilder() {
  const [c, l] = await Promise.all([rpc('catalog'), rpc('list')]);
  if (!c.ok) { toast(c.error || 'Erreur', 'err'); return; }
  S.catalog = c; S.list = l.list || []; S.cur = null; S.curId = null; S.dirty = false;
  renderBuilder();
}
async function refreshList() { const l = await rpc('list'); if (l.ok) S.list = l.list; }

function renderBuilder() {
  const cur = S.cur;
  const list = S.list.filter(g => !S.q || g.name.toLowerCase().includes(S.q.toLowerCase()));
  const items = list.map(g => {
    const T = typeOf(g.type) || {};
    const st = g.state && g.state !== 'idle' ? 'live' : (g.enabled ? 'on' : (g.problems && g.problems.length ? 'warn' : ''));
    const lbl = g.state && g.state !== 'idle' ? `En jeu · ${g.players}` : (g.enabled ? 'Actif' : (g.problems && g.problems.length ? 'Incomplet' : 'Désactivé'));
    return `<div class="item ${S.mode !== 'prog' && S.curId === g.id ? 'on' : ''}" data-open="${esc(g.id)}">${tile(g.type)}<div><div class="nm">${esc(g.name)}</div><div class="sb"><span class="dot ${st}"></span>${esc(T.label || g.type)} · ${lbl}</div></div></div>`;
  }).join('') || '<div class="empty" style="padding:30px 10px">Aucun mini-jeu.<br>Crée-en un avec le bouton ci-dessous.</div>';

  $('#builder').innerHTML = `<div class="window">
    <div class="titlebar"><div class="lights"><button class="light r" data-act="close" title="Fermer"></button><button class="light y" data-act="hub" title="Retour au panel builders"></button><span class="light g"></span></div>
      <div class="tt">Mini-jeux<small>Builder</small></div><div class="spacer"></div></div>
    <div class="body">
      <div class="side"><div class="search">${ic('search')}<input id="q" placeholder="Rechercher" value="${esc(S.q)}"></div>
        <div class="list">${items}</div>
        <div class="sidefoot"><button class="btn pri" style="flex:1" data-act="new">${ic('plus')}Nouveau mini-jeu</button><button class="btn ${S.mode === 'prog' ? 'on' : ''}" data-act="prog" title="Progression (XP, défis, succès, saison)">${ic('sparkle')}</button><button class="btn" data-act="logs" title="Journal">${ic('list')}</button></div></div>
      <div class="main">${S.mode === 'prog' && S.prog ? progHtml() : (cur ? editorHtml() : homeHtml())}</div>
    </div></div>`;
  bindBuilder();
}

function homeHtml() {
  const card = t => `<div class="card" data-new="${t.key}">${tile(t.key, 'xl')}<div><h3>${esc(t.label)}</h3><p>${esc(t.desc)}</p></div>
    <div class="tpls">${(t.templates || []).map(x => `<span class="chip btnlike" data-newtpl="${t.key}|${x.id}">${esc(x.label)}</span>`).join('')}</div></div>`;
  const cats = [...new Set(S.catalog.types.map(t => t.cat || 'Autres'))];
  const groups = cats.map(c => `<div class="grp-t" style="margin:26px 0 0 4px">${esc(c)}</div><div class="cards" style="margin-top:10px">${S.catalog.types.filter(t => (t.cat || 'Autres') === c).map(card).join('')}</div>`).join('');
  return `<div class="pane"><div class="hero"><h1>Crée ton mini-jeu</h1><p>${S.catalog.types.length} types disponibles : choisis-en un, place les points sur la carte, règle les règles et les récompenses. Le lobby, les scores et le classement sont gérés automatiquement.</p></div>${groups}</div>`;
}

const TABS = [['general', 'Général'], ['rules', 'Règles'], ['rewards', 'Récompenses'], ['settings', 'Réglages'], ['points', 'Emplacements'], ['top', 'Classement']];

function editorHtml() {
  const d = S.cur, T = typeOf(d.type);
  const probs = localProblems(d);
  const status = !S.curId ? '<span class="pill warn">Non enregistré</span>' : (d.enabled ? '<span class="pill on">Actif</span>' : '<span class="pill">Désactivé</span>');
  let body = '';
  if (S.tab === 'general') body = tabGeneral(d, T, probs);
  else if (S.tab === 'rules' || S.tab === 'rewards') body = fieldsGroup(S.catalog.common.filter(f => f.tab === S.tab), 'settings.');
  else if (S.tab === 'settings') body = T.fields.length ? fieldsGroup(T.fields, 'settings.') : '<div class="empty">Aucun réglage supplémentaire.</div>';
  else if (S.tab === 'points') body = tabPoints(d, T);
  else if (S.tab === 'top') body = tabTop();
  return `<div class="head">${tile(d.type, 'xl')}<div class="ttl"><input class="big" data-p="name" maxlength="40" value="${esc(d.name)}" placeholder="Nom du mini-jeu"><div class="meta">${esc(T.label)} ${status}${probs.length ? `<span class="pill warn">${ic('warn')}${probs.length} point(s) à compléter</span>` : ''}</div></div>
      <div style="display:flex;align-items:center;gap:12px"><span style="color:var(--sub);font-size:13px;font-weight:600">Actif</span><div class="sw ${d.enabled ? 'on' : ''}" data-sw="enabled"></div></div></div>
    <div class="seg">${TABS.map(([k, l]) => `<button class="${S.tab === k ? 'on' : ''}" data-tab="${k}">${l}</button>`).join('')}</div>
    <div class="pane">${body}</div>
    <div class="foot">${S.curId ? `<button class="btn red" data-act="del">${ic('trash')}Supprimer</button><button class="btn" data-act="dup">${ic('copy')}Dupliquer</button>` : ''}<span class="note">${S.dirty ? 'Modifications non enregistrées' : ''}</span><div class="spacer"></div><button class="btn" data-act="back">Fermer</button><button class="btn pri" data-act="save">${ic('check')}Enregistrer</button></div>`;
}

function tabGeneral(d, T, probs) {
  const tpls = (T.templates || []).map(x => `<span class="chip btnlike" data-apply="${x.id}">${esc(x.label)}</span>`).join(' ');
  return `${probs.length ? `<div class="banner"><b>Ce mini-jeu n'est pas encore jouable</b>${probs.map(p => '• ' + esc(p)).join('<br>')}</div>` : '<div class="banner ok"><b>Prêt à jouer</b>Tous les emplacements sont placés. Enregistre puis active le mini-jeu.</div>'}
    <div class="grp-t">Informations</div><div class="grp">
      <div class="row"><div class="l"><b>Description</b><small>Affichée dans le lobby. Vide = description du type.</small><textarea data-p="description" maxlength="220" style="margin-top:8px">${esc(d.description)}</textarea></div></div></div>
    <div class="grp-t">Carte</div><div class="grp">
      <div class="row"><div class="l"><b>Afficher un blip</b><small>Icône sur la carte à l'entrée du lobby.</small></div><div class="sw ${d.blip.enabled ? 'on' : ''}" data-sw="blip.enabled"></div></div>
      <div class="row"><div class="l"><b>Icône du blip</b><small>Numéro de sprite GTA (0 = automatique).</small></div><input type="number" data-p="blip.sprite" min="0" max="900" value="${esc(d.blip.sprite)}"></div>
      <div class="row"><div class="l"><b>Couleur du blip</b><small>Numéro de couleur GTA.</small></div><input type="number" data-p="blip.color" min="0" max="85" value="${esc(d.blip.color)}"></div></div>
    ${tpls ? `<div class="grp-t">Modèles</div><div class="grp"><div class="row"><div class="l"><b>Appliquer un modèle</b><small>Remplace les règles et récompenses par un préréglage. Les emplacements sont conservés.</small></div><div style="display:flex;gap:6px;flex-wrap:wrap;justify-content:flex-end">${tpls}</div></div></div>` : ''}`;
}

function fieldRow(f, prefix) {
  const p = prefix + f.key, v = getP(S.cur, p);
  let ctl = '';
  if (f.kind === 'bool') ctl = `<div class="sw ${v ? 'on' : ''}" data-sw="${p}"></div>`;
  else if (f.kind === 'number') ctl = `<input type="number" data-p="${p}" data-num="1" ${f.min != null ? `min="${f.min}"` : ''} ${f.max != null ? `max="${f.max}"` : ''} step="${f.step || 1}" value="${esc(v)}">`;
  else if (f.kind === 'select') ctl = `<select data-p="${p}">${f.options.map(o => `<option value="${esc(o[0])}" ${String(v) === String(o[0]) ? 'selected' : ''}>${esc(o[1])}</option>`).join('')}</select>`;
  else if (f.kind === 'weapon') ctl = `<select data-p="${p}">${S.catalog.weapons.map(o => `<option value="${esc(o[0])}" ${v === o[0] ? 'selected' : ''}>${esc(o[1])}</option>`).join('')}${S.catalog.weapons.some(o => o[0] === v) ? '' : `<option value="${esc(v)}" selected>${esc(v)}</option>`}</select>`;
  else ctl = `<input type="text" data-p="${p}" value="${esc(v)}" placeholder="${f.kind === 'model' ? 'nom du modèle' : ''}">`;
  const money = /Gain|Prix|mises/i.test(f.label) && f.kind === 'number' ? ` <span style="color:var(--sub)">${esc(S.catalog.currency)}</span>` : '';
  return `<div class="row"><div class="l"><b>${esc(f.label)}</b>${f.hint ? `<small>${esc(f.hint)}</small>` : ''}</div>${ctl}${money}</div>`;
}
const fieldsGroup = (fields, prefix) => `<div class="grp">${fields.map(f => fieldRow(f, prefix)).join('')}</div>`;

const xyz = (c, path) => ['x', 'y', 'z'].map(k => `<input type="number" step="0.01" data-p="${path}.${k}" data-num="1" value="${esc(Math.round(c[k] * 100) / 100)}">`).join('');
function pointBtns(path) {
  return `<button class="ibtn" title="Ma position" data-here="${path}">${ic('pin')}</button><button class="ibtn" title="Point visé par la caméra" data-aim="${path}">${ic('aim')}</button><button class="ibtn" title="Y aller" data-tp="${path}">${ic('go')}</button>`;
}
function tabPoints(d, T) {
  return T.points.map(spec => {
    const v = d.points[spec.key];
    if (spec.single) {
      return `<div class="grp-t">${esc(spec.label)}</div><div class="grp"><div class="pt">${v ? `<span class="n">${ic('check')}</span><div class="xyz grow">${xyz(v, 'points.' + spec.key)}</div>` : `<span class="n" style="background:#48484a">–</span><div class="grow coord">Non placé</div>`}${pointBtns('points.' + spec.key)}${v ? `<button class="ibtn red" data-clear="points.${spec.key}">${ic('trash')}</button>` : ''}</div></div>`;
    }
    const list = v || [];
    const rows = list.map((c, i) => {
      const p = `points.${spec.key}.${i}`;
      return `<div class="pt"><span class="n ${spec.team ? 't' + (c.team || 1) : ''}">${i + 1}</span><div class="xyz grow">${xyz(c, p)}</div>
        ${spec.team ? `<div class="teamsw"><button class="t1 ${(c.team || 1) === 1 ? 'on' : ''}" data-team="${p}|1">B</button><button class="t2 ${c.team === 2 ? 'on' : ''}" data-team="${p}|2">R</button></div>` : ''}
        ${spec.radius ? `<label class="mini">Rayon<input type="number" step="0.1" min="0.3" data-p="${p}.r" data-num="1" value="${esc(c.r != null ? c.r : 3)}"></label>` : ''}
        ${spec.pts ? `<label class="mini">Points<input type="number" min="0" data-p="${p}.pts" data-num="1" value="${esc(c.pts != null ? c.pts : 10)}"></label>` : ''}
        ${pointBtns(p)}<button class="ibtn red" data-del="${p}">${ic('trash')}</button></div>`;
    }).join('') || '<div class="empty" style="padding:18px">Aucun point placé</div>';
    const full = list.length >= (spec.max || 12);
    return `<div class="grp-t">${esc(spec.label)} <span style="text-transform:none;letter-spacing:0">· ${list.length}/${spec.max || 12}</span></div><div class="grp">${rows}<div class="ptbar"><button class="btn sm" data-add="${spec.key}|here" ${full ? 'disabled' : ''}>${ic('pin')}Ajouter ma position</button><button class="btn sm" data-add="${spec.key}|aim" ${full ? 'disabled' : ''}>${ic('aim')}Ajouter le point visé</button></div></div>`;
  }).join('') + `<div class="grp-t">Astuce</div><div style="color:var(--sub);font-size:12.5px;line-height:1.5;padding:0 16px">Le builder reste ouvert pendant que tu te déplaces : place-toi à l'endroit voulu puis clique sur « Ma position », ou vise un point (panier, but) et clique sur « point visé ».</div>`;
}

function tabTop() {
  if (!S.curId) return '<div class="empty">Enregistre le mini-jeu pour voir son classement.</div>';
  if (!S.stats) { rpc('stats', S.curId).then(r => { S.stats = r.ok ? r.top : []; if (S.tab === 'top') renderBuilder(); }); return '<div class="empty">Chargement…</div>'; }
  const race = typeOf(S.cur.type).engine === 'race';
  const rows = S.stats.map((r, i) => `<tr><td><span class="rk p${i + 1}">${i + 1}</span></td><td>${esc(r.name)}</td><td class="r">${race ? fmtMs(r.best_time) : r.best}</td><td class="r">${r.wins}</td><td class="r">${r.plays}</td></tr>`).join('');
  return `<div class="grp"><table class="tbl"><tr><th style="width:50px">#</th><th>Joueur</th><th class="r">${race ? 'Meilleur temps' : 'Meilleur score'}</th><th class="r">Victoires</th><th class="r">Parties</th></tr>${rows || '<tr><td colspan="5" class="empty">Aucune partie jouée</td></tr>'}</table></div>
    <div style="margin-top:16px"><button class="btn red" data-act="reset">${ic('trash')}Réinitialiser le classement</button></div>`;
}

// ── Actions du builder ────────────────────────────────────────────────────────
function guard(fn) {
  if (S.dirty) askConfirm('Modifications non enregistrées', 'Elles seront perdues si tu continues.', 'Continuer', fn, true); else fn();
}
async function openGame(id) {
  const r = await rpc('get', id);
  if (!r.ok) return toast(r.error || 'Erreur', 'err');
  S.cur = r.def; S.curId = id; S.dirty = false; S.tab = 'general'; S.stats = null;
  renderBuilder();
}
async function newGame(type, tpl) {
  const r = await rpc('draft', type, tpl || 0);
  if (!r.ok) return toast(r.error || 'Erreur', 'err');
  S.cur = r.def; S.curId = null; S.dirty = true; S.tab = 'general'; S.stats = null;
  renderBuilder();
}
function newPicker() {
  const body = `<div class="cards" style="grid-template-columns:repeat(2,1fr);margin-top:0">${S.catalog.types.map(t => `<div class="card" style="padding:14px;flex-direction:row;align-items:center" data-pick="${t.key}">${tile(t.key)}<div><h3 style="font-size:15px">${esc(t.label)}</h3></div></div>`).join('')}</div>`;
  sheet('Nouveau mini-jeu', 'Choisis le type de jeu à créer.', body, [{ label: 'Annuler' }], true);
  $$('[data-pick]', $('#modal')).forEach(el => el.onclick = () => { closeSheet(); guard(() => newGame(el.dataset.pick)); });
}
async function save() {
  const d = S.cur;
  if (!d.name || d.name.trim().length < 2) { toast('Donne un nom au mini-jeu', 'err'); return; }
  const wantsOn = d.enabled;
  const r = await rpc('save', d, S.curId || 0);
  if (!r.ok) return toast(r.error || 'Erreur', 'err');
  S.curId = r.id; S.dirty = false;
  const g = await rpc('get', r.id); if (g.ok) S.cur = g.def;
  await refreshList();
  S.stats = null;
  renderBuilder();
  if (wantsOn && !r.enabled) toast('Enregistré, mais non activé : ' + ((r.problems && r.problems[0]) || 'incomplet'), 'err');
  else toast('Mini-jeu enregistré');
}

async function placeAt(path, mode, push) {
  const r = await rpc(mode === 'aim' ? 'aimCoords' : 'getCoords');
  if (!r || r.ok === false) return toast('Aucun point visé : regarde une surface', 'err');
  const c = { x: r.x, y: r.y, z: r.z, h: r.h || 0 };
  if (push) {
    const T = typeOf(S.cur.type), spec = T.points.find(p => p.key === path);
    if (spec.radius) c.r = 3; if (spec.pts) c.pts = 10; if (spec.team) c.team = 1;
    S.cur.points[path] = (S.cur.points[path] || []).concat([c]);
  } else {
    const old = getP(S.cur, path);
    setP(S.cur, path, Object.assign({}, old && typeof old === 'object' ? old : {}, c));
  }
  S.dirty = true; renderBuilder(); snd('click');
}

function bindBuilder() {
  const root = $('#builder');
  const q = $('#q', root);
  if (q) q.oninput = () => { S.q = q.value; const pos = q.selectionStart; renderBuilder(); const n = $('#q'); n.focus(); n.setSelectionRange(pos, pos); };
  root.onclick = async e => {
    const t = e.target.closest('[data-ptab],[data-psw],[data-padd],[data-pdel],[data-act],[data-open],[data-tab],[data-sw],[data-new],[data-newtpl],[data-apply],[data-here],[data-aim],[data-tp],[data-clear],[data-del],[data-add],[data-team]');
    if (!t) return;
    const ds = t.dataset;
    if (ds.ptab || ds.psw || ds.padd || ds.pdel) return progClick(ds);
    if (ds.act === 'close') return rpc('close');
    if (ds.act === 'hub') return rpc('bbHub');
    if (ds.act === 'new') return guard(() => { S.mode = 'games'; newPicker(); });
    if (ds.act === 'prog') return guard(loadProg);
    if (ds.act === 'logs') return showLogs();
    if (ds.act === 'back') return guard(() => { S.cur = null; S.curId = null; S.dirty = false; renderBuilder(); });
    if (ds.act === 'save') return S.mode === 'prog' ? progSave() : save();
    if (ds.act === 'progReset') return askConfirm('Réinitialiser la progression ?', 'Tous les réglages XP, niveaux, défis, succès et saison reviennent aux valeurs par défaut du serveur.', 'Réinitialiser', async () => { const r = await rpc('progReset'); if (!r.ok) return toast(r.error, 'err'); S.prog = r.cfg; S.dirty = false; renderBuilder(); toast('Valeurs par défaut restaurées'); }, true);
    if (ds.act === 'seasonEnd') return askConfirm('Terminer la saison maintenant ?', 'Les récompenses du top sont versées et les classements de saison repartent à zéro.', 'Terminer la saison', async () => { await rpc('seasonEnd'); toast('Saison terminée'); loadProg(); }, true);
    if (ds.act === 'del') return askConfirm('Supprimer ce mini-jeu ?', 'Sa définition et son classement seront définitivement effacés.', 'Supprimer', async () => { const r = await rpc('delete', S.curId); if (!r.ok) return toast(r.error, 'err'); S.cur = null; S.curId = null; S.dirty = false; await refreshList(); renderBuilder(); toast('Mini-jeu supprimé'); }, true);
    if (ds.act === 'dup') { const r = await rpc('duplicate', S.curId); if (!r.ok) return toast(r.error, 'err'); await refreshList(); await openGame(r.id); return toast('Copie créée (désactivée)'); }
    if (ds.act === 'reset') return askConfirm('Réinitialiser le classement ?', 'Toutes les statistiques de ce mini-jeu seront effacées.', 'Réinitialiser', async () => { await rpc('resetStats', S.curId); S.stats = []; renderBuilder(); toast('Classement réinitialisé'); }, true);
    if (ds.open) return guard(() => { S.mode = 'games'; return openGame(ds.open); });
    if (ds.tab) { S.tab = ds.tab; snd('tab'); return renderBuilder(); }
    if (ds.sw) { const p = ds.sw; setP(S.cur, p, !getP(S.cur, p)); S.dirty = true; snd(getP(S.cur, p) ? 'on' : 'off'); return renderBuilder(); }
    if (ds.new) return guard(() => newGame(ds.new));
    if (ds.newtpl) { const [ty, id] = ds.newtpl.split('|'); return guard(() => newGame(ty, id)); }
    if (ds.apply) {
      const T = typeOf(S.cur.type), tp = T.templates.find(x => x.id === ds.apply);
      Object.assign(S.cur.settings, tp.settings); if (!S.cur.description) S.cur.description = tp.desc;
      S.dirty = true; toast('Modèle « ' + tp.label + ' » appliqué'); return renderBuilder();
    }
    if (ds.here) return placeAt(ds.here, 'here', false);
    if (ds.aim) return placeAt(ds.aim, 'aim', false);
    if (ds.add) { const [k, m] = ds.add.split('|'); return placeAt(k, m, true); }
    if (ds.tp) { const c = getP(S.cur, ds.tp); if (c) { await rpc('teleport', c); toast('Téléporté'); } return; }
    if (ds.clear) { setP(S.cur, ds.clear, false); S.dirty = true; return renderBuilder(); }
    if (ds.del) { const ks = ds.del.split('.'); const idx = +ks.pop(); const arr = getP(S.cur, ks.join('.')); arr.splice(idx, 1); S.dirty = true; return renderBuilder(); }
    if (ds.team) { const [p, v] = ds.team.split('|'); setP(S.cur, p + '.team', +v); S.dirty = true; return renderBuilder(); }
  };
  root.oninput = e => {
    const el = e.target;
    if (el.dataset && el.dataset.pp) return progInput(el);
    const p = el.dataset && el.dataset.p; if (!p || !S.cur) return;
    let v = el.value;
    if (el.dataset.num) { v = parseFloat(v); if (isNaN(v)) return; }
    setP(S.cur, p, v);
    if (!S.dirty) { S.dirty = true; const n = $('.foot .note'); if (n) n.textContent = 'Modifications non enregistrées'; }
  };
  root.onchange = e => { if (e.target.tagName === 'SELECT' || e.target.dataset.num) { /* valeur déjà appliquée */ } };
}

async function showLogs() {
  const r = await rpc('logs');
  const rows = (r.logs || []).map(l => `<tr><td style="color:var(--sub);white-space:nowrap">${new Date(l.t * 1000).toLocaleString('fr-FR', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' })}</td><td>${esc(l.actor)}</td><td>${esc(l.action)}</td><td style="color:var(--sub)">${esc(l.game_id)} ${esc(l.details || '')}</td></tr>`).join('');
  sheet('Journal', 'Dernières actions et parties.', `<div class="grp"><table class="tbl">${rows || '<tr><td class="empty">Rien pour le moment</td></tr>'}</table></div>`, [{ label: 'Fermer', cls: 'pri' }], true);
}


// ══════════════════════════════════════════════════════════════════════════════
//  PROGRESSION (admin) : XP, niveaux, défis, succès, saison — tout est modifiable ici
// ══════════════════════════════════════════════════════════════════════════════
const PTABS = [['xp', 'XP & coins'], ['levels', 'Niveaux'], ['challenges', 'Défis'], ['ach', 'Succès'], ['season', 'Semaine & saison']];
const CKINDS = [['plays', 'Parties jouées'], ['wins', 'Victoires'], ['points', 'Points marqués'], ['kills', 'Touches (paintball / laser)']];
const AKINDS = [['plays_total', 'Parties jouées (total)'], ['wins_total', 'Victoires (total)'], ['points_total', 'Points (total)'], ['best_streak', 'Série de victoires'], ['level', 'Niveau atteint']];

async function loadProg() {
  const r = await rpc('progGet');
  if (!r.ok) return toast(r.error || 'Erreur', 'err');
  S.mode = 'prog'; S.prog = r.cfg; S.pgames = r.games || []; S.pfeat = r.featured; S.dirty = false;
  renderBuilder();
}
async function progSave() {
  const r = await rpc('progSave', S.prog);
  if (!r.ok) return toast(r.error || 'Erreur', 'err');
  S.prog = r.cfg; S.dirty = false; renderBuilder(); toast('Progression enregistrée');
}
const pn = (path, label, hint, min, max, step) => `<div class="row"><div class="l"><b>${esc(label)}</b>${hint ? `<small>${esc(hint)}</small>` : ''}</div><input type="number" data-pp="${path}" data-num="1" min="${min}" max="${max}" step="${step || 1}" value="${esc(getP(S.prog, path))}"></div>`;
const pb = (path, label, hint) => `<div class="row"><div class="l"><b>${esc(label)}</b>${hint ? `<small>${esc(hint)}</small>` : ''}</div><div class="sw ${getP(S.prog, path) ? 'on' : ''}" data-psw="${path}"></div></div>`;
const sel = (path, opts, v) => `<select data-pp="${path}">${opts.map(o => `<option value="${esc(o[0])}" ${String(v) === String(o[0]) ? 'selected' : ''}>${esc(o[1])}</option>`).join('')}</select>`;
const mini = (label, inner) => `<label class="mini">${label}${inner}</label>`;
const mnum = (path, w, min, max) => `<input type="number" data-pp="${path}" data-num="1" min="${min}" max="${max}" style="width:${w}px" value="${esc(getP(S.prog, path))}">`;
const gameOpts = () => [['any', 'Tous les jeux']].concat(S.catalog.types.map(t => [t.key, t.label])).concat(S.pgames.map(g => [g.id, '↳ ' + g.name]));

function progHtml() {
  const c = S.prog, st = c.settings;
  let body = '';
  if (S.pt === 'xp') {
    body = `<div class="grp-t">Gain d'XP par partie</div><div class="grp">
      ${pb('settings.xp.enabled', 'XP activée', 'Désactive pour couper toute la progression.')}
      ${pn('settings.xp.perGame', 'XP de participation', 'Gagnée à chaque partie terminée.', 0, 10000)}
      ${pn('settings.xp.win', 'XP bonus de victoire', '', 0, 10000)}
      ${pn('settings.xp.perPoint', 'XP par point marqué', '', 0, 1000, .5)}
      ${pn('settings.xp.maxPerGame', 'XP maximum par partie', 'Plafond avant bonus.', 0, 100000)}
      ${pn('settings.xp.streakPct', 'Bonus par victoire consécutive (%)', 'S\'applique à l\'XP et aux gains d\'argent.', 0, 200)}
      ${pn('settings.xp.streakMax', 'Série maximale prise en compte', '', 0, 20)}</div>
    <div class="grp-t">Courbe de niveaux</div><div class="grp">
      ${pn('settings.curve.base', 'XP du niveau 1 → 2', '', 10, 1000000)}
      ${pn('settings.curve.growth', 'Multiplicateur par niveau', '1.25 = chaque niveau demande 25 % de plus.', 1, 3, .01)}
      ${pn('settings.curve.maxLevel', 'Niveau maximum', '', 1, 200)}</div>
    <div class="grp-t">Palier d'XP → coins boutique</div><div class="grp">
      ${pb('settings.milestone.enabled', 'Paliers activés', 'Tous les X points d\'XP cumulés, le joueur reçoit des coins boutique.')}
      ${pn('settings.milestone.xp', 'XP nécessaire par palier', '', 100, 10000000)}
      ${pn('settings.milestone.coins', 'Coins boutique par palier', 'Crédités directement sur la boutique du joueur.', 0, 100000)}
      ${pn('settings.milestone.money', 'Argent par palier', '', 0, 100000000)}</div>`;
  } else if (S.pt === 'levels') {
    body = `<div class="grp-t">Récompenses par niveau</div><div class="grp">${c.levels.map((l, i) => `<div class="pt"><span class="n">${i + 1}</span>
      ${mini('Niveau', mnum(`levels.${i}.level`, 64, 1, 200))}
      <label class="mini grow">Titre<input type="text" data-pp="levels.${i}.title" maxlength="24" style="width:100%;text-align:left;padding:0 8px" value="${esc(l.title)}"></label>
      ${mini('Argent', mnum(`levels.${i}.money`, 90, 0, 100000000))}${mini('Coins', mnum(`levels.${i}.coins`, 70, 0, 100000))}
      <button class="ibtn red" data-pdel="levels.${i}">${ic('trash')}</button></div>`).join('') || '<div class="empty" style="padding:18px">Aucun palier de niveau</div>'}
      <div class="ptbar"><button class="btn sm" data-padd="levels">${ic('plus')}Ajouter un palier</button></div></div>
      <div style="color:var(--sub);font-size:12.5px;line-height:1.5;padding:12px 16px">Le titre s'affiche dans le profil et le lobby. Il est conservé jusqu'au palier suivant.</div>`;
  } else if (S.pt === 'challenges') {
    const row = (e, i) => `<div class="pt"><span class="n ${e.scope === 'weekly' ? 't2' : ''}">${e.scope === 'weekly' ? 'S' : 'J'}</span>
      <label class="mini grow">Nom<input type="text" data-pp="challenges.${i}.name" maxlength="50" style="width:100%;text-align:left;padding:0 8px" value="${esc(e.name)}"></label>
      ${mini('Période', sel(`challenges.${i}.scope`, [['daily', 'Quotidien'], ['weekly', 'Hebdo']], e.scope))}
      ${mini('Type', sel(`challenges.${i}.kind`, CKINDS, e.kind))}
      ${mini('Jeu', sel(`challenges.${i}.game`, gameOpts(), e.game))}
      ${mini('Objectif', mnum(`challenges.${i}.target`, 76, 1, 1000000))}
      ${mini('XP', mnum(`challenges.${i}.xp`, 66, 0, 100000))}${mini('Argent', mnum(`challenges.${i}.money`, 80, 0, 100000000))}${mini('Coins', mnum(`challenges.${i}.coins`, 60, 0, 100000))}
      <div class="sw ${e.enabled ? 'on' : ''}" data-psw="challenges.${i}.enabled" style="transform:scale(.8)"></div>
      <button class="ibtn red" data-pdel="challenges.${i}">${ic('trash')}</button></div>`;
    body = `<div class="grp-t">Défis (chaque joueur reçoit 3 défis quotidiens et 2 hebdo tirés dans cette liste)</div><div class="grp">${c.challenges.map(row).join('') || '<div class="empty" style="padding:18px">Aucun défi</div>'}
      <div class="ptbar"><button class="btn sm" data-padd="challenges">${ic('plus')}Ajouter un défi</button></div></div>`;
  } else if (S.pt === 'ach') {
    const row = (e, i) => `<div class="pt"><span class="n">${ic('trophy').replace('class="ic"', 'class="ic" style="width:14px;height:14px"')}</span>
      <label class="mini grow">Nom<input type="text" data-pp="achievements.${i}.name" maxlength="50" style="width:100%;text-align:left;padding:0 8px" value="${esc(e.name)}"></label>
      <label class="mini grow">Description<input type="text" data-pp="achievements.${i}.desc" maxlength="80" style="width:100%;text-align:left;padding:0 8px" value="${esc(e.desc || '')}"></label>
      ${mini('Condition', sel(`achievements.${i}.kind`, AKINDS, e.kind))}${mini('Valeur', mnum(`achievements.${i}.target`, 76, 1, 1000000))}
      ${mini('XP', mnum(`achievements.${i}.xp`, 66, 0, 100000))}${mini('Argent', mnum(`achievements.${i}.money`, 80, 0, 100000000))}${mini('Coins', mnum(`achievements.${i}.coins`, 60, 0, 100000))}
      <div class="sw ${e.enabled ? 'on' : ''}" data-psw="achievements.${i}.enabled" style="transform:scale(.8)"></div>
      <button class="ibtn red" data-pdel="achievements.${i}">${ic('trash')}</button></div>`;
    body = `<div class="grp-t">Succès débloquables</div><div class="grp">${c.achievements.map(row).join('') || '<div class="empty" style="padding:18px">Aucun succès</div>'}
      <div class="ptbar"><button class="btn sm" data-padd="achievements">${ic('plus')}Ajouter un succès</button></div></div>`;
  } else {
    const w = st.weekly;
    body = `<div class="grp-t">Mini-jeu de la semaine</div><div class="grp">
      ${pb('settings.weekly.enabled', 'Activé', 'Les gains et l\'XP du jeu choisi sont multipliés toute la semaine.')}
      <div class="row"><div class="l"><b>Choix du jeu</b><small>Aléatoire : tiré chaque semaine parmi les mini-jeux actifs.</small></div>${sel('settings.weekly.mode', [['random', 'Aléatoire'], ['fixed', 'Fixe']], w.mode)}</div>
      ${w.mode === 'fixed' ? `<div class="row"><div class="l"><b>Mini-jeu</b></div>${sel('settings.weekly.gameId', [['', '—']].concat(S.pgames.map(g => [g.id, g.name])), w.gameId)}</div>` : ''}
      ${pn('settings.weekly.mult', 'Multiplicateur', 'Ex : 2 = gains et XP doublés.', 1, 10, .5)}</div>
    ${S.pfeat ? `<div style="color:var(--sub);font-size:12.5px;padding:8px 16px">Cette semaine : <b style="color:var(--txt)">${esc((S.pgames.find(g => g.id === S.pfeat) || {}).name || S.pfeat)}</b></div>` : ''}
    <div class="grp-t">Saison</div><div class="grp">
      ${pb('settings.season.enabled', 'Saisons activées', 'Classement général remis à zéro à chaque fin de saison, avec récompenses au podium.')}
      ${pn('settings.season.days', 'Durée d\'une saison (jours)', '', 1, 365)}
      ${c.settings.season.rewards.map((r, i) => `<div class="pt"><span class="n">${esc(r.rank)}</span>${mini('Rang', mnum(`settings.season.rewards.${i}.rank`, 60, 1, 100))}${mini('Argent', mnum(`settings.season.rewards.${i}.money`, 100, 0, 100000000))}${mini('Coins', mnum(`settings.season.rewards.${i}.coins`, 70, 0, 100000))}<div class="grow"></div><button class="ibtn red" data-pdel="settings.season.rewards.${i}">${ic('trash')}</button></div>`).join('')}
      <div class="ptbar"><button class="btn sm" data-padd="settings.season.rewards">${ic('plus')}Ajouter une récompense de rang</button><button class="btn sm red" data-act="seasonEnd">Terminer la saison maintenant</button></div></div>
    <div class="grp-t">Annonces serveur</div><div class="grp">
      ${pb('settings.announce.records', 'Annoncer les records battus', 'Notification à tous les joueurs.')}
      ${pb('settings.announce.levels', 'Annoncer les niveaux ronds (5, 10, 15…)', '')}</div>`;
  }
  return `<div class="head"><div class="tile xl" style="background:linear-gradient(160deg,#ffd60a,#ff9f0a)">${ic('sparkle')}</div><div class="ttl"><div style="font-size:26px;font-weight:700;letter-spacing:-.02em">Progression</div><div class="meta">XP, niveaux, coins boutique, défis, succès, saisons — réglages en direct</div></div></div>
    <div class="seg">${PTABS.map(([k, l]) => `<button class="${S.pt === k ? 'on' : ''}" data-ptab="${k}">${l}</button>`).join('')}</div>
    <div class="pane">${body}</div>
    <div class="foot"><button class="btn red" data-act="progReset">Valeurs par défaut</button><span class="note">${S.dirty ? 'Modifications non enregistrées' : ''}</span><div class="spacer"></div><button class="btn pri" data-act="save">${ic('check')}Enregistrer</button></div>`;
}

function progClick(ds) {
  if (ds.ptab) { S.pt = ds.ptab; snd('tab'); return renderBuilder(); }
  if (ds.psw) { setP(S.prog, ds.psw, !getP(S.prog, ds.psw)); S.dirty = true; snd('click'); return renderBuilder(); }
  if (ds.pdel) { const ks = ds.pdel.split('.'); const i = +ks.pop(); getP(S.prog, ks.join('.')).splice(i, 1); S.dirty = true; return renderBuilder(); }
  if (ds.padd) {
    const defs = {
      levels: { level: 2, title: '', money: 0, coins: 0 },
      challenges: { id: '', name: 'Nouveau défi', scope: 'daily', kind: 'plays', game: 'any', target: 3, xp: 50, money: 200, coins: 0, enabled: true },
      achievements: { id: '', name: 'Nouveau succès', desc: '', kind: 'wins_total', target: 10, xp: 100, money: 500, coins: 0, enabled: true },
      'settings.season.rewards': { rank: 4, money: 500, coins: 0 },
    };
    getP(S.prog, ds.padd).push(Object.assign({}, defs[ds.padd])); S.dirty = true; return renderBuilder();
  }
}
function progInput(el) {
  let v = el.value;
  if (el.dataset.num) { v = parseFloat(v); if (isNaN(v)) return; }
  setP(S.prog, el.dataset.pp, v);
  if (!S.dirty) { S.dirty = true; const n = $('.foot .note'); if (n) n.textContent = 'Modifications non enregistrées'; }
  if (/weekly\.mode$/.test(el.dataset.pp)) renderBuilder();
}

// ══════════════════════════════════════════════════════════════════════════════
//  LOBBY
// ══════════════════════════════════════════════════════════════════════════════
const L = { data: null, joined: false, tab: 'game', prof: null };
function statusText() {
  const d = L.data; if (!d) return '';
  if (d.state === 'running' || d.state === 'countdown') return '<b>Partie en cours</b> — patiente quelques instants';
  const n = d.players.length, min = d.settings.minPlayers;
  if (d.state === 'waiting' && d.left != null) return `Départ dans <b>${fmtT(d.left)}</b> · ${n}/${d.settings.maxPlayers} joueur(s)`;
  if (d.state === 'waiting') return `En attente de joueurs · <b>${n}/${min}</b> minimum`;
  return 'Le lobby est libre';
}
function renderLobby() {
  if (L.tab === 'profile') return renderProfile();
  const d = L.data, st = d.settings, cur = d.currency || '$', race = d.engine === 'race';
  const fmtB = m => (m && (race ? m.best_time : m.best)) ? (race ? fmtMs(m.best_time) : m.best) : '–';
  const top = (d.top || []).slice(0, 6).map((r, i) => `<div class="row"><span class="rk p${i + 1}">${i + 1}</span><div class="l"><b>${esc(r.name)}</b></div><span class="coord ok">${race ? fmtMs(r.best_time) : r.best + ' pts'}</span></div>`).join('') || '<div class="row"><div class="l" style="color:var(--sub)">Personne n\'a encore joué</div></div>';
  const pl = d.players.map(p => `<div class="row"><span class="av">${esc((p.name || '?')[0].toUpperCase())}</span><div class="l"><b>${esc(p.name)}</b></div>${p.team ? `<span class="tdot t${p.team}"></span>` : ''}</div>`).join('') || '<div class="row"><div class="l" style="color:var(--sub)">Aucun joueur dans le lobby</div></div>';
  const full = d.players.length >= st.maxPlayers, busy = d.state === 'running' || d.state === 'countdown';
  const act = L.joined ? `<button class="btn red block" style="width:auto;padding:0 28px" data-l="leave">Quitter la file</button>` : `<button class="btn pri block" style="width:auto;padding:0 28px" data-l="join" ${(full || busy || d.cooldown > 0) ? 'disabled' : ''}>Rejoindre${st.entryFee > 0 ? ` · ${cur}${st.entryFee}` : ''}</button>`;
  $('#lobby').innerHTML = `<div class="lob"><div class="lob-top">${tile(d.type, 'xl')}<div><h2>${esc(d.name)}</h2><p>${esc(d.desc)}</p></div><div class="seg" style="margin:0 0 0 auto"><button class="on" data-l="tab" data-t="game">Mini-jeu</button><button data-l="tab" data-t="profile">Mon profil</button></div><button class="ibtn lob-x" style="margin-left:10px" data-l="close">${ic('x')}</button></div>
    ${d.featured ? `<div class="banner ok" style="margin:0 28px 14px"><b>Mini-jeu de la semaine ×${d.featured}</b>Gains et XP multipliés sur ce jeu.</div>` : ''}${d.me ? `<div style="padding:0 28px 14px"><div style="display:flex;gap:10px;align-items:center;margin-bottom:6px"><span class="pill on">Niv. ${d.me.level}</span><span style="color:var(--sub);font-size:12.5px">${esc(d.me.title || '')}</span><span style="margin-left:auto;color:var(--sub);font-size:12.5px">${d.me.need ? d.me.cur + ' / ' + d.me.need + ' XP' : 'Niveau max'}</span></div>${bar(d.me.cur, d.me.need)}</div>` : ''}
    <div class="stats"><div class="stat"><small>Joueurs</small><b>${st.minPlayers === st.maxPlayers ? st.maxPlayers : st.minPlayers + '–' + st.maxPlayers}</b></div><div class="stat"><small>Durée</small><b>${race ? 'Au temps' : fmtT(d.engine === 'fight' ? st.rounds * st.roundTime : st.duration)}</b></div><div class="stat"><small>${st.entryFee > 0 ? 'Mise' : 'Entrée'}</small><b>${st.entryFee > 0 ? cur + st.entryFee : 'Gratuite'}</b></div></div>
    <div class="lob-body"><div><div class="grp-t">Dans le lobby</div><div class="grp plist">${pl}</div></div><div><div class="grp-t">Classement</div><div class="grp plist">${top}</div><div class="grp-t">Ton record</div><div class="grp"><div class="row"><div class="l"><b>${fmtB(d.mine)}</b><small>${d.mine ? d.mine.wins + ' victoire(s) · ' + d.mine.plays + ' partie(s)' : 'Jamais joué'}</small></div></div></div></div></div>
    <div class="lob-foot"><div class="st">${d.cooldown > 0 ? `Patiente <b>${d.cooldown}s</b> avant de rejouer` : statusText()}</div>${act}</div></div>`;
  $('#lobby').onclick = lobbyClick;
}

// ══════════════════════════════════════════════════════════════════════════════
//  JEU (HUD / compte à rebours / résultats)
// ══════════════════════════════════════════════════════════════════════════════
const GS = { playing: false, engine: null, name: '', hud: null, hint: '', wait: null, waitName: '', down: null, myName: '', res: null };
const TEAMN = ['', 'Bleus', 'Rouges'];

function drawGame() {
  const g = $('#game');
  const visible = GS.playing || GS.wait || GS.res;
  g.classList.toggle('hidden', !visible);
  if (!$('#g-hud')) g.innerHTML = '<div id="g-hud"></div><div id="g-meter" class="hidden"><div class="meter"><div class="sweet"></div><div class="cur"></div></div></div><div id="g-over"></div>';
  if (!visible) { $('#g-hud').innerHTML = ''; return; }
  let h = '';
  if (!GS.playing && GS.wait && !GS.res) {
    const w = GS.wait;
    h += `<div class="wait"><span class="dot live"></span>${esc(GS.waitName)} · ${w.count}/${w.max} joueur(s)${w.left != null ? ' · départ ' + fmtT(w.left) : (w.count < w.min ? ' · en attente (' + w.min + ' min.)' : '')}<span style="color:var(--sub);font-weight:500">F9 pour quitter</span></div>`;
  }
  if (GS.playing && GS.hud) {
    const H = GS.hud, x = H.extra || {}, rows = H.rows || [];
    const me = rows.find(r => r.src === H.me);
    GS.myName = me ? me.name : GS.myName;
    const low = H.left <= 10 && GS.engine !== 'race';
    h += `<div class="hud-time ${low ? 'low' : ''}"><small>${GS.engine === 'fight' ? 'Round ' + (x.round || 1) + '/' + (x.rounds || 1) : esc(GS.name)}</small>${fmtT(H.left)}</div>`;
    if (GS.engine === 'fight') {
      const opp = rows.find(r => r.src !== H.me);
      const bar = r => r ? `<div class="fb"><div class="t"><span>${esc(r.name)}</span><span>${r.score} ◆</span></div><div class="hp ${r.hp / x.maxHp < .3 ? 'low' : ''}"><i style="width:${Math.max(0, Math.min(100, r.hp / x.maxHp * 100))}%"></i></div></div>` : '<div class="fb"></div>';
      h += `<div class="fight">${bar(me)}<div class="rd">VS</div>${bar(opp)}</div>`;
    } else {
      let b = `<h4>${GS.engine === 'race' ? 'Course' : 'Scores'}</h4>`;
      if (GS.engine === 'tag' && x.teams) b += `<div class="teams"><div class="t1">${x.teamScore[0]}</div><div class="t2">${x.teamScore[1]}</div></div>`;
      b += rows.slice(0, 8).map((r, i) => {
        let val = r.score;
        if (GS.engine === 'race') val = r.finished ? fmtMs(r.time) : `${r.cp || 0}/${x.total}`;
        return `<div class="brow ${r.src === H.me ? 'me' : ''}">${r.team ? `<span class="tdot t${r.team}"></span>` : `<span style="color:var(--sub);width:14px;font-size:12px">${i + 1}</span>`}<span class="nm">${esc(r.name)}</span><span class="sc">${val}</span></div>`;
      }).join('');
      if (GS.engine === 'tag' && x.limit) b += `<div style="color:var(--sub);font-size:11.5px;padding:6px 10px">Limite : ${x.limit} touches</div>`;
      h += `<div class="board">${b}</div>`;
    }
  }
  if (GS.playing && GS.hint) h += `<div class="hintbar">${esc(GS.hint)}</div>`;
  if (GS.down) h += `<div class="down"><div><b>Touché !</b><small>par ${esc(GS.down.by)} · retour dans <span id="dn">${GS.down.secs}</span>s</small></div></div>`;
  if (GS.res) h += resultsHtml();
  $('#g-hud').innerHTML = h;
}

function resultsHtml() {
  const r = GS.res, race = r.engine === 'race', fight = r.engine === 'fight';
  const win = r.rows.find(x => x.name === GS.myName);
  const you = win ? win.won : false;
  const title = !win ? 'Partie terminée' : (you ? 'Victoire !' : 'Partie terminée');
  const head = race ? 'Temps' : (fight ? 'Rounds' : 'Score');
  const rows = r.rows.map(x => `<tr class="${x.name === GS.myName ? 'you' : ''}"><td><span class="rk p${x.pos}">${x.pos}</span></td><td>${x.team ? `<span class="tdot t${x.team}" style="display:inline-block;margin-right:8px"></span>` : ''}${esc(x.name)}</td><td class="r">${race ? (x.finished ? fmtMs(x.time) : 'Abandon') : x.score}</td><td class="r gain">${x.gain > 0 ? '+' + (S.catalog ? S.catalog.currency : '$') + x.gain : ''}</td></tr>`).join('');
  const t2 = r.teams ? ` · ${r.teamScore[0]} – ${r.teamScore[1]}` : '';
  return `<div class="res"><div class="resc"><div class="top"><h2>${title}</h2><p>${esc(r.name)}${t2} · ${esc(r.why || '')}</p></div><table class="tbl"><tr><th style="width:44px">#</th><th>Joueur</th><th class="r">${head}</th><th class="r">Gain</th></tr>${rows}</table>${progResHtml(win)}<div class="foot2">Retour au lobby dans quelques secondes</div></div></div>`;
}

function overlay(html, ms) {
  const o = $('#g-over'); if (!o) return;
  const d = document.createElement('div'); d.innerHTML = html; const el = d.firstElementChild;
  o.appendChild(el);
  setTimeout(() => el.remove(), ms);
}

let tickTimer = null;
function startTick() {
  if (tickTimer) return;
  tickTimer = setInterval(() => {
    let again = false;
    if (L.data && L.data.left != null && L.data.left > 0) { L.data.left--; again = true; if (!$('#lobby').classList.contains('hidden')) { const s = $('#lobby .st'); if (s) s.innerHTML = statusText(); } }
    if (GS.wait && GS.wait.left != null && GS.wait.left > 0) { GS.wait.left--; again = true; if (!GS.playing) drawGame(); }
    if (GS.down) { GS.down.secs--; const n = $('#dn'); if (n) n.textContent = Math.max(0, GS.down.secs); again = true; }
    if (!again) { clearInterval(tickTimer); tickTimer = null; }
  }, 1000);
}

// ── Messages du jeu ───────────────────────────────────────────────────────────
function hideAll() { $('#builder').classList.add('hidden'); $('#lobby').classList.add('hidden'); closeSheet(); }
window.addEventListener('message', e => {
  const m = e.data || {};
  switch (m.action) {
    case 'open':
      hideAll();
      if (m.mode === 'builder') { $('#builder').classList.remove('hidden'); snd('open'); loadBuilder(); }
      else if (m.mode === 'lobby') { L.data = m.data; L.tab = m.data.profileOnly ? 'profile' : 'game'; L.prof = null; if (L.tab === 'profile') loadProfile(); L.joined = !!m.data.joined; if (L.joined) GS.waitName = m.data.name; $('#lobby').classList.remove('hidden'); renderLobby(); startTick(); snd('open'); }
      break;
    case 'close': hideAll(); snd('close'); break;
    case 'lobbyState': {
      const d = m.data;
      GS.wait = { count: d.count, min: d.min, max: d.max, left: d.left };
      if (L.data && L.data.id === d.id) { L.data.players = d.players; L.data.state = d.state; L.data.left = d.left; L.joined = true; if (!$('#lobby').classList.contains('hidden')) renderLobby(); }
      if (d.state === 'waiting' || d.state === 'idle') drawGame();
      startTick();
      break;
    }
    case 'kicked': GS.wait = null; GS.playing = false; GS.res = null; GS.down = null; L.joined = false; drawGame(); if (m.text) toast(m.text, 'err'); break;
    case 'begin': GS.playing = true; GS.engine = m.engine; GS.name = m.name; GS.hud = null; GS.hint = ''; GS.wait = null; GS.res = null; GS.down = null; hideAll(); drawGame(); break;
    case 'count': overlay(`<div class="count"><span>${m.n}</span></div>`, 950); snd('tick'); break;
    case 'go': overlay(`<div class="count"><span style="color:var(--green);font-size:140px">GO !</span></div>`, 950); snd('confirm'); break;
    case 'hud': GS.hud = m.data; drawGame(); break;
    case 'hint': GS.hint = m.text; drawGame(); setTimeout(() => { if (GS.hint === m.text) { GS.hint = ''; drawGame(); } }, 7000); break;
    case 'meter': {
      const w = $('#g-meter'); if (!w) break;
      if (!m.show) { w.classList.add('hidden'); break; }
      w.classList.remove('hidden');
      const sw = $('.sweet', w), cur = $('.cur', w), s = m.sweet || .15;
      sw.style.left = ((.5 - s / 2) * 100) + '%'; sw.style.width = (s * 100) + '%'; cur.style.left = (m.v * 100) + '%';
      break;
    }
    case 'scored': overlay(`<div class="pop">${m.pts > 0 ? '+' + m.pts : '✓'}</div>`, 1000); snd('success'); break;
    case 'down': GS.down = { by: m.by, secs: m.secs }; drawGame(); startTick(); snd('error'); break;
    case 'respawn': GS.down = null; drawGame(); snd('confirm'); break;
    case 'hurt': snd('warn'); break;
    case 'round': overlay(`<div class="banner-c"><b>${m.data.winner ? 'Round ' + m.data.round + ' : ' + esc(m.data.winner) : 'Round ' + m.data.round + ' : égalité'}</b>${m.data.ko ? '<small>K.O. !</small>' : ''}</div>`, 3600); snd('announce'); break;
    case 'end':
      if (m.data.you) GS.myName = m.data.you; GS.res = m.data; GS.playing = true; drawGame(); snd('announce');
      setTimeout(() => { GS.res = null; GS.playing = false; GS.hud = null; GS.wait = null; L.joined = false; drawGame(); }, ((m.data.ret || 6) + 0.5) * 1000);
      break;
    case 'pkSound': break;
  }
});
document.addEventListener('keydown', e => {
  if (e.key === 'Escape') {
    if (!$('#modal').classList.contains('hidden')) return closeSheet();
    if (!$('#builder').classList.contains('hidden') || !$('#lobby').classList.contains('hidden')) rpc('close');
  }
});

async function lobbyClick(e) {
  const b = e.target.closest('[data-l]');
  const d = L.data;
  if (!b) { if (e.target.id === 'lobby') rpc('close'); return; }
  const a = b.dataset.l;
  if (a === 'close') return rpc('close');
  if (a === 'tab') { L.tab = b.dataset.t; if (L.tab === 'profile' && !L.prof) { loadProfile(); } return renderLobby(); }
  if (a === 'join') {
    const r = await rpc('join', d.id);
    if (!r.ok) return toast(r.error || 'Impossible de rejoindre', 'err');
    L.joined = true; GS.waitName = d.name; snd('confirm'); renderLobby();
  }
  if (a === 'leave') { await rpc('leave'); L.joined = false; GS.wait = null; drawGame(); renderLobby(); snd('close'); }
}

// ══════════════════════════════════════════════════════════════════════════════
//  PROFIL JOUEUR : niveau, XP, défis, succès, classements
// ══════════════════════════════════════════════════════════════════════════════
async function loadProfile() {
  const r = await rpc('profile');
  if (!r.ok) return toast('Profil indisponible', 'err');
  L.prof = r;
  if (L.tab === 'profile') renderLobby();
}
const bar = (v, max, cls = '') => `<div class="xbar ${cls}"><i style="width:${max > 0 ? Math.min(100, v / max * 100) : 100}%"></i></div>`;
const rewTxt = (o, cur) => [o.xp > 0 ? '+' + o.xp + ' XP' : '', o.money > 0 ? '+' + cur + o.money : '', o.coins > 0 ? '+' + o.coins + ' coins' : ''].filter(Boolean).join(' · ') || '—';
const fmtLeft = s => { const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600); return d > 0 ? d + ' j ' + h + ' h' : h + ' h'; };

function profileHtml(P) {
  const cur = P.currency || '$';
  const ch = (c, j) => `<div class="row"><div class="l"><b>${esc(c.name)}</b>${bar(c.progress, c.target, c.done ? 'ok' : '')}<small>${c.progress}/${c.target} · ${esc(rewTxt(c, cur))}</small></div>${c.done ? `<span class="pill on">${ic('check')}Fait</span>` : ''}</div>`;
  const ach = P.achievements.map(a => `<div class="ach ${a.unlocked ? 'on' : ''}"><div class="tile sm" style="background:${a.unlocked ? 'linear-gradient(160deg,#ffd60a,#ff9f0a)' : '#3a3a3c'}">${ic('trophy')}</div><div><b>${esc(a.name)}</b><small>${esc(a.desc || '')}</small><small>${esc(rewTxt(a, cur))}</small></div></div>`).join('');
  const lv = P.levels.map(l => `<div class="row" style="${l.reached ? '' : 'opacity:.55'}"><span class="rk ${l.reached ? 'p1' : ''}">${l.level}</span><div class="l"><b>${esc(l.title || 'Niveau ' + l.level)}</b></div><span class="coord ok">${esc(rewTxt(l, cur))}</span></div>`).join('');
  const topRow = (r, i, v) => `<div class="row"><span class="rk p${i + 1}">${i + 1}</span><div class="l"><b>${esc(r.name)}</b></div><span class="coord ok">${v}</span></div>`;
  const seasonTop = P.season ? P.season.top.map((r, i) => topRow(r, i, r.season_xp + ' XP')).join('') || '<div class="row"><div class="l" style="color:var(--sub)">Personne pour le moment</div></div>' : '';
  const gTop = P.globalTop.map((r, i) => topRow(r, i, r.xp + ' XP')).join('') || '<div class="row"><div class="l" style="color:var(--sub)">Aucun joueur classé</div></div>';
  return `<div class="prof-h"><div class="lvl"><b>${P.level}</b><small>NIV.</small></div><div style="flex:1;min-width:0"><div style="font-size:24px;font-weight:700;letter-spacing:-.02em">${esc(P.name || 'Joueur')}</div>
      <div style="color:var(--sub);margin:2px 0 8px">${esc(P.title || 'Sans titre')} · ${P.xp} XP au total${P.streak > 1 ? ` · série de ${P.streak} 🔥` : ''}</div>
      ${P.level >= P.maxLevel ? bar(1, 1, 'ok') + '<small style="color:var(--sub)">Niveau maximum atteint</small>' : bar(P.cur, P.need) + `<small style="color:var(--sub)">${P.cur} / ${P.need} XP vers le niveau ${P.level + 1}</small>`}</div></div>
    <div class="stats" style="padding:0 28px 14px"><div class="stat"><small>Parties</small><b>${P.plays}</b></div><div class="stat"><small>Victoires</small><b>${P.wins}</b></div><div class="stat"><small>Points</small><b>${P.points}</b></div></div>
    <div class="lob-body" style="grid-template-columns:1fr 1fr;align-items:start">
      <div>${P.featured ? `<div class="banner ok" style="margin-bottom:14px"><b>Mini-jeu de la semaine : ${esc(P.featured.name)}</b>Gains et XP ×${P.featured.mult} jusqu'à la fin de la semaine.</div>` : ''}
        ${P.milestone ? `<div class="grp-t">Prochain palier de coins</div><div class="grp"><div class="row"><div class="l"><b>+${P.milestone.coins} coins boutique${P.milestone.money ? ' · +' + cur + P.milestone.money : ''}</b>${bar(P.milestone.into, P.milestone.xp)}<small>${P.milestone.into} / ${P.milestone.xp} XP · ${P.milestone.claimed} palier(s) déjà obtenu(s)</small></div></div></div>` : ''}
        <div class="grp-t">Défis du jour</div><div class="grp">${P.daily.map(ch).join('') || '<div class="row"><div class="l" style="color:var(--sub)">Aucun défi</div></div>'}</div>
        <div class="grp-t">Défis de la semaine</div><div class="grp">${P.weekly.map(ch).join('') || '<div class="row"><div class="l" style="color:var(--sub)">Aucun défi</div></div>'}</div>
        <div class="grp-t">Paliers de niveau</div><div class="grp">${lv || '<div class="row"><div class="l" style="color:var(--sub)">Aucun palier</div></div>'}</div></div>
      <div>${P.season ? `<div class="grp-t">Saison ${P.season.id} · fin dans ${fmtLeft(P.season.endsIn)}</div><div class="grp plist">${seasonTop}</div><div style="color:var(--sub);font-size:12px;padding:6px 14px 0">Tes points de saison : <b style="color:var(--txt)">${P.season.xp} XP</b> · Récompenses : ${P.season.rewards.map(r => '#' + r.rank + ' ' + (r.coins ? r.coins + ' coins' : '') + (r.money ? ' ' + cur + r.money : '')).join(' · ')}</div>` : ''}
        <div class="grp-t">Classement général</div><div class="grp plist">${gTop}</div>
        <div class="grp-t">Succès</div><div class="achs">${ach || '<div style="color:var(--sub)">Aucun succès</div>'}</div></div></div>`;
}

function renderProfile() {
  const P = L.prof;
  const only = L.data && L.data.profileOnly;
  const tabs = only ? '' : `<div class="seg" style="margin:0 0 0 auto"><button data-l="tab" data-t="game">Mini-jeu</button><button class="on" data-l="tab" data-t="profile">Mon profil</button></div>`;
  $('#lobby').innerHTML = `<div class="lob"><div class="lob-top" style="padding-bottom:10px"><div class="tile xl" style="background:linear-gradient(160deg,#ffd60a,#ff9f0a)">${ic('user')}</div><div><h2>Mon profil</h2><p>Niveau, défis, succès et classements.</p></div>${tabs}<button class="ibtn lob-x" data-l="close" ${tabs ? 'style="margin-left:10px"' : ''}>${ic('x')}</button></div>
    <div style="overflow-y:auto">${P ? profileHtml(P) : '<div class="empty">Chargement…</div>'}</div></div>`;
  $('#lobby').onclick = lobbyClick;
}

function progResHtml(me) {
  const p = me && me.prog; if (!p) return '';
  const cur = S.catalog ? S.catalog.currency : '$';
  const lines = [];
  if (p.levelUp) lines.push(`<div class="pr-l up"><b>Niveau ${p.level} !</b>${p.title ? ' · ' + esc(p.title) : ''}</div>`);
  (p.levelUps || []).filter(l => l.money > 0 || l.coins > 0).forEach(l => lines.push(`<div class="pr-l">Palier niveau ${l.level} : ${esc(rewTxt({ money: l.money, coins: l.coins }, cur))}</div>`));
  (p.done || []).forEach(n => lines.push(`<div class="pr-l">Défi terminé : <b>${esc(n)}</b></div>`));
  (p.ach || []).forEach(n => lines.push(`<div class="pr-l">Succès débloqué : <b>${esc(n)}</b></div>`));
  if (p.milestoneCount) lines.push(`<div class="pr-l up">Palier d'XP atteint : coins boutique reçus !</div>`);
  if (me.mult && me.mult > 1) lines.push(`<div class="pr-l">Bonus ×${me.mult.toFixed(2).replace(/\.?0+$/, '')} (série / mini-jeu de la semaine)</div>`);
  return `<div class="prog-res"><div style="display:flex;align-items:center;gap:12px"><span class="pill on">+${p.xp} XP</span><span style="font-weight:600">Niveau ${p.level}</span><div style="flex:1">${bar(p.cur, p.need)}</div><small style="color:var(--sub)">${p.need ? p.cur + '/' + p.need : 'MAX'}</small></div>${lines.join('')}</div>`;
}
