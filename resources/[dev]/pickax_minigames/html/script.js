'use strict';
/* ════════════════════════════ Utilitaires (même base que les autres builders) ════════════════════════════ */
const $root = document.getElementById('root');
const $ = (s, r = document) => r.querySelector(s);
const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const r2 = n => Math.round(n * 100) / 100;
const resName = () => (typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'pickax_minigames');
const clone = o => JSON.parse(JSON.stringify(o));
const snd = n => { try { window.BBUI && BBUI.play({ tick: 'click', announce: 'success', hover: 'hover' }[n] || n); } catch (e) {} };

async function rpc(name, ...args) {
  const ctl = new AbortController();
  const timer = setTimeout(() => ctl.abort(), 10000);
  try {
    const r = await fetch(`https://${resName()}/rpc`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ name, args: args.map(a => (a === undefined || a === null ? 0 : a)) }), signal: ctl.signal });
    return await r.json();
  } catch (e) {
    return { ok: false, error: ctl.signal.aborted ? `Le serveur ne répond pas à « ${name} » : refresh + restart ${resName()}` : 'Erreur de communication' };
  } finally { clearTimeout(timer); }
}

function toast(msg, type = '') {
  const el = document.createElement('div');
  el.className = 'toast ' + type;
  el.textContent = msg;
  document.getElementById('toasts').appendChild(el);
  setTimeout(() => el.remove(), 4200);
}

function confirmBox(title, text, okLabel = 'Confirmer', danger = true) {
  return new Promise(resolve => {
    const c = document.getElementById('confirm');
    c.innerHTML = `<div class="box"><h2>${esc(title)}</h2><p>${esc(text)}</p><div class="row"><span class="spacer"></span><button id="c-no">Annuler</button><button class="${danger ? 'danger' : 'primary'}" id="c-yes">${esc(okLabel)}</button></div></div>`;
    c.classList.remove('hidden');
    const done = v => { c.classList.add('hidden'); c.innerHTML = ''; resolve(v); };
    document.getElementById('c-no').onclick = () => done(false);
    document.getElementById('c-yes').onclick = () => done(true);
  });
}

function setPath(obj, path, val) {
  const keys = path.split('.');
  let o = obj;
  for (let i = 0; i < keys.length - 1; i++) {
    if (o[keys[i]] == null || typeof o[keys[i]] !== 'object') o[keys[i]] = {};
    o = o[keys[i]];
  }
  if (val === undefined) delete o[keys[keys.length - 1]]; else o[keys[keys.length - 1]] = val;
}
const getPath = (obj, path) => path.split('.').reduce((o, k) => (o == null ? o : o[k]), obj);
const fmtT = s => { s = Math.max(0, Math.floor(s)); return Math.floor(s / 60) + ':' + String(s % 60).padStart(2, '0'); };
const fmtMs = ms => { ms = Math.max(0, Math.floor(ms)); const m = Math.floor(ms / 60000), s = Math.floor(ms / 1000) % 60, c = Math.floor((ms % 1000) / 10); return m + ':' + String(s).padStart(2, '0') + '.' + String(c).padStart(2, '0'); };
const fmtLeft = s => { const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600); return d > 0 ? d + ' j ' + h + ' h' : h + ' h'; };

/* ── Icônes (trait fin) ── */
const P = {
  x: '<path d="M18 6 6 18"/><path d="m6 6 12 12"/>', plus: '<path d="M5 12h14"/><path d="M12 5v14"/>',
  search: '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>',
  pin: '<path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/>',
  trash: '<path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/>',
  check: '<path d="M20 6 9 17l-5-5"/>', target: '<circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="6"/><circle cx="12" cy="12" r="2"/>',
  copy: '<rect width="14" height="14" x="8" y="8" rx="2"/><path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2"/>',
  list: '<path d="M8 6h13"/><path d="M8 12h13"/><path d="M8 18h13"/><path d="M3 6h.01"/><path d="M3 12h.01"/><path d="M3 18h.01"/>',
  grid: '<rect width="7" height="7" x="3" y="3" rx="1"/><rect width="7" height="7" x="14" y="3" rx="1"/><rect width="7" height="7" x="14" y="14" rx="1"/><rect width="7" height="7" x="3" y="14" rx="1"/>',
  bolt: '<path d="M13 2L4 14h7l-1 8 9-12h-7z"/>', user: '<path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>',
  trophy: '<path d="M8 21h8M12 17v4M7 4h10v5a5 5 0 01-10 0zM17 5h3v2a3 3 0 01-3 3M7 5H4v2a3 3 0 003 3"/>',
  go: '<path d="M5 12h14M13 6l6 6-6 6"/>', box: '<path d="m7.5 4.27 9 5.15"/><path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z"/><path d="m3.3 7 8.7 5 8.7-5"/><path d="M12 22V12"/>',
  eye: '<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
  chart: '<path d="M3 3v18h18"/><path d="M18 17V9"/><path d="M13 17V5"/><path d="M8 17v-3"/>',
  basket: '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3v18M5.6 5.6c3 3 3 9.8 0 12.8M18.4 5.6c-3 3-3 9.8 0 12.8"/>',
  football: '<circle cx="12" cy="12" r="9"/><path d="M12 8l3.5 2.5-1.3 4h-4.4l-1.3-4zM12 8V3M15.5 10.5l4.7-1.6M14.2 14.5l3 4M9.8 14.5l-3 4M8.5 10.5L3.8 8.9"/>',
  tennis: '<circle cx="12" cy="12" r="9"/><path d="M5 5.5c4 3 4 10 0 13M19 5.5c-4 3-4 10 0 13"/>',
  boxing: '<path d="M7 11V8a4 4 0 014-4h2a4 4 0 014 4v4a5 5 0 01-5 5H9a2 2 0 01-2-2zM7 14H5a1 1 0 01-1-1v-2a1 1 0 011-1h2M9 20.5h6"/>',
  paintball: '<circle cx="12" cy="12" r="3"/><circle cx="12" cy="12" r="8"/><path d="M12 1.5v3M12 19.5v3M1.5 12h3M19.5 12h3"/>',
  laser: '<path d="M13 2L5 14h6l-1 8 8-12h-6z"/>', race: '<path d="M5 21V4M5 4h13l-2.5 4L18 12H5"/>',
  bowling: '<circle cx="9" cy="15" r="6"/><path d="M7 13.5h.01M10 13h.01M9.5 16.2h.01M17 3c1.2 2 .6 3.2-.2 4.6S16.6 10 17.4 11.2 17.4 14 15.4 14.5"/>',
  darts: '<circle cx="12" cy="12" r="8"/><circle cx="12" cy="12" r="4"/><path d="M12 12L21 3M17 3h4v4"/>',
  brawl: '<path d="M7 20v-5l-2-3V8l2-1 2 2 2-3 2 1 2-2 2 1v9l-3 4z"/>',
  padel: '<ellipse cx="10" cy="9.5" rx="6" ry="7" transform="rotate(-35 10 9.5)"/><path d="M14.5 15L20.5 21M8 6.5l3 3M6.5 9l3 3"/>',
  volley: '<circle cx="12" cy="12" r="9"/><path d="M12 3c-3 4-3 8 0 9s6 5 6 8M3.5 9c5 0 8 2 8.5 3M20.5 10c-4 1-6 4-6 8"/>',
  kart: '<path d="M3 16l2-5h9l3 3h4v2M3 16v2h18v-2"/><circle cx="7" cy="18" r="1.8"/><circle cx="17" cy="18" r="1.8"/>',
  car: '<path d="M5 16l1.6-5a2 2 0 012-1.4h7a2 2 0 012 1.4L19 16M3 16h18v3H3z"/><circle cx="7.5" cy="19" r="1.6"/><circle cx="16.5" cy="19" r="1.6"/>',
  moto: '<circle cx="6" cy="16" r="3"/><circle cx="18" cy="16" r="3"/><path d="M6 16l4-6h5l3 6M10 10L9 7H7"/>',
  quad: '<circle cx="6" cy="17" r="2.6"/><circle cx="18" cy="17" r="2.6"/><path d="M6 17h12M8.5 17l2.5-6h4l2 6M11 11V8h3"/>',
  boat: '<path d="M3 15h18l-3 5H6zM12 15V4l6 9z"/>', golf: '<path d="M8 21V4l8 4-8 4M5 21h8"/><circle cx="17" cy="19" r="1.6"/>',
  drag: '<path d="M3 17h18M5 17l1.5-5h8l3 3.5M3 8h5M2 11h4"/><circle cx="8" cy="17.5" r="1.7"/><circle cx="16" cy="17.5" r="1.7"/>',
  parkour: '<circle cx="14" cy="5" r="1.8"/><path d="M8 21l3-6-2-3 4-3 3 2 3 1M11 15l4 1 1 5M9 12l-3 1"/>',
};
const ICON_OF = { lasertag: 'laser', karting: 'kart' };
const ic = (n, s) => `<svg class="ic" viewBox="0 0 24 24" ${s ? `style="width:${s}px;height:${s}px"` : ''}>${P[ICON_OF[n] || n] || P.grid}</svg>`;
const tile = (icon, cls = '') => `<div class="tile ${cls}">${ic(icon)}</div>`;
const fld = (label, input, extra = '') => `<label class="f" ${extra}><span>${label}</span>${input}</label>`;
const chip = (text, cls = '') => `<span class="chip ${cls}">${esc(text)}</span>`;
const closeBtn = `<button class="icon" data-a="close" title="Fermer">${ic('x', 16)}</button>`;
const emptyState = (icon, title, text) => `<div class="empty">${tile(icon)}<h2>${esc(title)}</h2><p>${esc(text)}</p></div>`;
const header = ({ icon, title, sub, acts = '' }) => `<div class="head">${tile(icon, 'lg')}<div class="ttl"><h1>${esc(title)}</h1>${sub ? `<p>${esc(sub)}</p>` : ''}</div><div class="acts">${acts}${closeBtn}</div></div>`;

/* ════════════════════════════ État du builder ════════════════════════════ */
const S = { cat: null, list: [], cur: null, curId: null, dirty: false, tab: 'general', view: 'home', stats: null, prog: null, pt: 'xp', pgames: [], pfeat: null, logs: null, propSel: '', propCat: 0 };
const typeOf = k => (S.cat ? S.cat.types.find(t => t.key === k) : null);
const mark = () => { S.dirty = true; };

function localProblems(d) {
  const T = typeOf(d.type); if (!T) return [];
  const out = [];
  T.points.forEach(pt => {
    const v = d.points[pt.key];
    if (pt.single ? !(v && v.x != null) : (!v || !v.filter(c => c.x != null).length)) out.push('Point manquant : ' + pt.label);
  });
  if (T.engine === 'tag' && String(d.settings.teams) === '2') {
    const sp = d.points.spawns || []; if (!sp.some(s => s.team !== 2) || !sp.some(s => s.team === 2)) out.push('Mode équipes : un point d\'apparition par équipe minimum');
  }
  if (T.engine === 'fight' && (d.points.spawns || []).length < 2) out.push('2 coins de ring sont nécessaires');
  return out;
}

async function load() {
  const [c, l] = await Promise.all([rpc('catalog'), rpc('list')]);
  if (!c.ok) { toast(c.error || 'Erreur', 'err'); return; }
  S.cat = c; S.list = l.list || []; S.cur = null; S.curId = null; S.dirty = false; S.view = 'home';
  render();
}
async function refreshList() { const l = await rpc('list'); if (l.ok) S.list = l.list; }

/* ── Gabarit principal ── */
function render() {
  try { renderInner(); } catch (err) {
    console.error(err);
    toast('Erreur d\'affichage : ' + err.message, 'err');
    try { S.view = S.view === 'game' ? 'home' : S.view; S.cur = S.view === 'home' ? null : S.cur; renderInner(); } catch (e2) { $root.innerHTML = '<div class="shell"><section class="main"><div class="body"><div class="empty"><h2>Erreur d\'affichage</h2><p>' + esc(err.message) + '</p><button data-a="close">Fermer</button></div></div></section></div>'; }
  }
}
function renderInner() {
  const items = S.list.map(g => {
    const live = g.state && g.state !== 'idle';
    const lbl = live ? `en jeu · ${g.players}` : (g.enabled ? 'actif' : (g.problems && g.problems.length ? 'incomplet' : 'off'));
    return { id: 'g:' + g.id, icon: g.type, label: g.name, count: lbl };
  });
  const nav = [
    { label: 'Mini-jeux', items: items.length ? items : [{ id: 'home', icon: 'grid', label: 'Aucun mini-jeu' }] },
    { label: 'Gérer', items: [{ id: 'new', icon: 'plus', label: 'Nouveau mini-jeu' }, { id: 'prog', icon: 'bolt', label: 'Progression & défis' }, { id: 'logs', icon: 'list', label: 'Journal' }] },
  ];
  const active = S.view === 'game' ? 'g:' + S.curId : (S.view === 'prog' ? 'prog' : (S.view === 'logs' ? 'logs' : (S.view === 'home' ? 'new' : '')));
  const n = S.list.length, on = S.list.filter(g => g.enabled).length;
  let head, body, bodyAttr = '';
  if (S.view === 'prog' && S.prog) { head = { icon: 'bolt', title: 'Progression & défis', sub: 'XP, niveaux, coins boutique, défis, succès, saisons', acts: `<button data-a="progReset">Valeurs par défaut</button><button class="primary" data-a="progSave">${ic('check', 15)} Enregistrer</button>` }; body = progBody(); bodyAttr = 'data-root="prog"'; }
  else if (S.view === 'logs') { head = { icon: 'list', title: 'Journal', sub: 'Dernières actions et parties' }; body = logsBody(); }
  else if (S.view === 'game' && S.cur) {
    const d = S.cur, T = typeOf(d.type);
    head = { icon: d.type, title: d.name || 'Nouveau mini-jeu', sub: `${T.label}${S.curId ? '' : ' · non enregistré'}`,
      acts: `<label class="chk" style="margin-right:6px"><input type="checkbox" data-path="enabled" data-t="b" ${d.enabled ? 'checked' : ''}> Actif</label>${S.curId ? `<button data-a="dup">${ic('copy', 15)} Dupliquer</button><button class="danger" data-a="del">${ic('trash', 15)}</button>` : ''}<button class="primary" data-a="save">${ic('check', 15)} Enregistrer</button>` };
    body = gameBody(); bodyAttr = 'data-root="cur"';
  } else { head = { icon: 'grid', title: 'Mini-jeux Builder', sub: `${S.cat.types.length} types disponibles` }; body = homeBody(); }
  const html = `<div class="shell"><aside class="side">
    <div class="profile logo-only" title="Mini-jeux"><img class="plogo" data-pk-logo src="${esc(window.PICKAX_LOGO || 'https://cfx-nui-pickax_theme/logo/logo.png')}" alt="" onerror="this.style.visibility='hidden'"><b class="pname">Mini-jeux</b></div>
    <div class="nav">${nav.map(sec => `<div class="nav-label">${esc(sec.label)}</div>${sec.items.map(it => `<div class="nav-item ${it.id === active ? 'active' : ''}" data-a="nav" data-v="${esc(it.id)}">${ic(it.icon)}<span class="grow">${esc(it.label)}</span>${it.count ? `<span class="count">${esc(it.count)}</span>` : ''}</div>`).join('')}`).join('')}</div>
    <div class="side-foot"><small>Place les points avec le <b>mode placement</b> : tu te déplaces en jeu, <b>Entrée</b> enregistre ta position.</small></div></aside>
    <section class="main">${header(head)}<div class="body" ${bodyAttr}>${body}</div></section></div>`;
  const keep = $('.body', $root) ? $('.body', $root).scrollTop : 0;
  $root.innerHTML = html;
  const b = $('.body', $root); if (b && keep) b.scrollTop = keep;
}

/* ── Accueil : choix du type ── */
function homeBody() {
  const cats = [...new Set(S.cat.types.map(t => t.cat || 'Autres'))];
  return `<div class="hint" style="margin-bottom:16px">Choisis un type de mini-jeu : il est créé <b>désactivé</b>. Place ses points, ajuste les règles et les récompenses puis active-le. Le lobby, les scores et le classement sont gérés automatiquement.</div>` +
    cats.map(c => `<div class="eyebrow" style="margin:6px 0 12px">${esc(c)}</div><div class="grid3" style="margin-bottom:22px">${S.cat.types.filter(t => (t.cat || 'Autres') === c).map(t => `
      <div class="tpl" data-a="new" data-v="${t.key}|0" style="align-items:flex-start;text-align:left;cursor:pointer">${tile(t.key, 'lg')}<div><b style="font-size:14px">${esc(t.label)}</b><div class="hint" style="margin-top:4px;min-height:54px">${esc(t.desc)}</div></div>
      <div class="row wrap" style="gap:6px">${(t.templates || []).map(x => `<span class="chip info" data-a="new" data-v="${t.key}|${x.id}">${esc(x.label)}</span>`).join('')}</div></div>`).join('')}</div>`).join('');
}

/* ── Éditeur d'un mini-jeu ── */
const TABS = [['general', 'Général', 'grid'], ['rules', 'Règles', 'list'], ['rewards', 'Récompenses', 'trophy'], ['settings', 'Réglages', 'bolt'], ['props', 'Props', 'box'], ['points', 'Emplacements', 'pin'], ['map', 'Personnaliser', 'sliders'], ['top', 'Classement', 'chart']];
function gameBody() {
  const d = S.cur, T = typeOf(d.type), probs = localProblems(d);
  const tabs = `<div class="seg">${TABS.map(([k, l]) => `<button class="${S.tab === k ? 'active' : ''}" data-a="tab" data-v="${k}">${l}</button>`).join('')}</div>`;
  let h = '';
  if (S.tab === 'general') h = tabGeneral(d, T, probs);
  else if (S.tab === 'rules' || S.tab === 'rewards') h = `<div class="card"><div class="grid3">${S.cat.common.filter(f => f.tab === S.tab).map(f => fieldHtml(f, 'settings.')).join('')}</div></div>`;
  else if (S.tab === 'settings') h = `<div class="card"><div class="card-h"><div class="t">${ic(d.type, 17)} Réglages ${esc(T.label)}</div></div><div class="grid3">${T.fields.map(f => fieldHtml(f, 'settings.')).join('')}</div></div>`;
  else if (S.tab === 'props') h = tabProps(d);
  else if (S.tab === 'points') h = tabPoints(d, T);
  else if (S.tab === 'map') h = tabMap(d);
  else h = tabTop();
  return tabs + h + datalists();
}

function datalists() {
  return `<datalist id="dl-models">${S.cat.models.map(m => `<option value="${esc(m[0])}">${esc(m[1])}</option>`).join('')}</datalist>
    <datalist id="dl-props">${S.cat.props.flatMap(c => c[1]).map(m => `<option value="${esc(m[0])}">${esc(m[1])}</option>`).join('')}</datalist>`;
}

function tabGeneral(d, T, probs) {
  const tpls = (T.templates || []).map(x => `<span class="chip info" data-a="applyTpl" data-v="${x.id}">${esc(x.label)}</span>`).join(' ');
  return `${probs.length ? `<div class="card" style="border-color:rgba(251,191,36,.4)"><div class="card-h"><div class="t">${ic('pin', 17)} Ce mini-jeu n'est pas encore jouable</div>${chip('à compléter', 'warn')}</div>${probs.map(p => `<div class="hint">• ${esc(p)}</div>`).join('')}<button class="primary mt" data-a="tab" data-v="points">${ic('pin', 15)} Aller aux emplacements</button></div>` : `<div class="card" style="border-color:rgba(74,222,128,.35)"><div class="card-h"><div class="t">${ic('check', 17)} Prêt à jouer</div>${chip('ok', 'ok')}</div><div class="hint">Tous les emplacements sont placés. Enregistre puis coche « Actif ».</div></div>`}
    <div class="card"><div class="card-h"><div class="t">${ic('list', 17)} Informations</div></div>
      <div class="grid2">${fld('Nom du mini-jeu', `<input data-path="name" maxlength="40" value="${esc(d.name)}">`)}${fld('Type', `<input value="${esc(T.label)}" disabled>`)}</div>
      <div class="mt">${fld('Description (affichée dans le lobby)', `<textarea data-path="description" maxlength="220" rows="3">${esc(d.description || '')}</textarea>`)}</div></div>
    ${tpls ? `<div class="card"><div class="card-h"><div class="t">${ic('bolt', 17)} Modèles</div></div><div class="row wrap">${tpls}</div><div class="hint mt-s">Applique un préréglage de règles et récompenses. Les emplacements et props sont conservés.</div></div>` : ''}`;
}

function fieldHtml(f, prefix) {
  const p = prefix + f.key, v = getPath(S.cur, p), hint = f.hint ? `<div class="hint" style="margin-top:4px">${esc(f.hint)}</div>` : '';
  if (f.kind === 'bool') return `<div><label class="chk"><input type="checkbox" data-path="${p}" data-t="b" ${v ? 'checked' : ''}> ${esc(f.label)}</label>${hint}</div>`;
  if (f.kind === 'number') return `<div>${fld(esc(f.label), `<input type="number" data-path="${p}" data-t="n" step="${f.step || 1}" ${f.min != null ? `min="${f.min}"` : ''} ${f.max != null ? `max="${f.max}"` : ''} value="${esc(v ?? '')}">`)}${hint}</div>`;
  if (f.kind === 'select') return `<div>${fld(esc(f.label), `<select data-path="${p}">${f.options.map(o => `<option value="${esc(o[0])}" ${String(v) === String(o[0]) ? 'selected' : ''}>${esc(o[1])}</option>`).join('')}</select>`)}${hint}</div>`;
  if (f.kind === 'weapon') {
    const known = S.cat.weapons.some(o => o[0] === v);
    return `<div style="grid-column:span 2">${fld(esc(f.label), `<div class="row"><select data-path="${p}" style="flex:1">${S.cat.weapons.map(o => `<option value="${esc(o[0])}" ${v === o[0] ? 'selected' : ''}>${esc(o[1])}</option>`).join('')}${known ? '' : `<option value="${esc(v)}" selected>${esc(v)}</option>`}</select><input data-path="${p}" data-ne="1" placeholder="ou WEAPON_…" value="${known ? '' : esc(v)}" style="width:190px"></div>`)}</div>`;
  }
  if (f.kind === 'model') return `<div>${fld(esc(f.label), `<div class="row"><input list="dl-models" data-path="${p}" value="${esc(v ?? '')}" placeholder="vide = aucun"><button class="sm" data-a="testModel" data-v="${esc(p)}">Tester</button></div>`)}${hint}</div>`;
  return `<div>${fld(esc(f.label), `<input data-path="${p}" value="${esc(v ?? '')}">`)}</div>`;
}

/* ── Props ── */
function tabProps(d) {
  const list = d.props || [];
  const cats = S.cat.props;
  const items = cats[S.propCat] ? cats[S.propCat][1] : [];
  const rows = list.map((p, i) => `<div class="card" style="padding:14px"><div class="row" style="margin-bottom:10px"><div class="tile" style="width:34px;height:34px">${ic('box', 17)}</div><b style="flex:1">${i + 1}. ${esc((S.cat.props.flatMap(c => c[1]).find(m => m[0] === p.model) || [])[1] || p.model)}</b>
      <button class="sm" data-a="testModel" data-v="props.${i}.model">${ic('eye', 14)} Tester</button><button class="sm" data-a="propHere" data-v="${i}">${ic('pin', 14)} Ici</button><button class="icon" data-a="propDel" data-v="${i}">${ic('trash', 15)}</button></div>
    <div class="grid4">${fld('Modèle', `<input list="dl-props" data-path="props.${i}.model" value="${esc(p.model)}">`)}${fld('Affichage', `<select data-path="props.${i}.mode"><option value="match" ${p.mode !== 'always' ? 'selected' : ''}>Seulement pendant la partie</option><option value="always" ${p.mode === 'always' ? 'selected' : ''}>Toujours visible</option></select>`)}
      ${fld('Pivot X°', `<input type="number" data-path="props.${i}.rx" data-t="n" value="${p.rx ?? 0}">`)}${fld('Pivot Y°', `<input type="number" data-path="props.${i}.ry" data-t="n" value="${p.ry ?? 0}">`)}</div>
    <div class="grid4 mt">${['x', 'y', 'z', 'h'].map(k => fld(k === 'h' ? 'Cap' : k.toUpperCase(), `<input type="number" step="0.01" data-path="props.${i}.${k}" data-t="n" value="${p[k] ?? ''}">`)).join('')}</div>
    <div class="row mt" style="gap:22px"><label class="chk"><input type="checkbox" data-path="props.${i}.freeze" data-t="b" ${p.freeze !== false ? 'checked' : ''}> Figé</label><label class="chk"><input type="checkbox" data-path="props.${i}.collision" data-t="b" ${p.collision !== false ? 'checked' : ''}> Collision</label></div></div>`).join('');
  return `<div class="card"><div class="card-h"><div class="t">${ic('box', 17)} Ajouter un prop</div>${chip(list.length + ' / 150', 'mute')}</div>
    <div class="grid3">${fld('Catégorie', `<select data-a="propCat">${cats.map((c, i) => `<option value="${i}" ${S.propCat === i ? 'selected' : ''}>${esc(c[0])}</option>`).join('')}</select>`)}
      ${fld('Prop', `<select id="propSel">${items.map(m => `<option value="${esc(m[0])}" ${S.propSel === m[0] ? 'selected' : ''}>${esc(m[1])} · ${esc(m[0])}</option>`).join('')}</select>`)}
      ${fld('Ou modèle libre', `<input id="propFree" list="dl-props" placeholder="ex : prop_barrier_work05">`)}</div>
    <div class="row mt"><button class="primary" data-a="propAdd">${ic('plus', 15)} Ajouter à ma position</button><button data-a="propAddAim">${ic('target', 15)} Ajouter au point visé</button><button data-a="placeStart" ${list.length ? '' : 'disabled'}>${ic('pin', 15)} Mode placement</button></div>
    <div class="hint mt-s">« Seulement pendant la partie » : les props apparaissent au début du match et disparaissent à la fin. « Toujours visible » : visibles en permanence près du lobby (décor de terrain). Le bouton <b>Tester</b> fait apparaître le modèle devant toi 8 secondes (et signale s'il n'existe pas).</div></div>${rows}`;
}

/* ── Emplacements ── */
function coordRow(path, c, spec) {
  c = c || {};
  const f = (k, l) => fld(l, `<input type="number" step="0.01" data-path="${path}.${k}" data-t="n" value="${c[k] ?? ''}">`);
  return `<div class="coord tp">${f('x', 'X')}${f('y', 'Y')}${f('z', 'Z')}${f('h', 'Cap')}<button data-a="coords" data-v="${path}">${ic('pin', 15)} Ma position</button><button data-a="aim" data-v="${path}">${ic('target', 15)} Visé</button><button data-a="tp" data-v="${path}" ${c.x == null ? 'disabled' : ''}>TP</button></div>`;
}
function tabPoints(d, T) {
  const nTargets = placementTargets().length;
  return `<div class="card"><div class="row"><div class="grow-i" style="flex:1"><b>Mode placement</b><div class="hint">Marche librement en jeu : <kbd>Entrée</kbd> enregistre ta position pour la cible suivante, <kbd>←</kbd><kbd>→</kbd> change de cible, <kbd>Retour</kbd> revient ici.</div></div><button class="primary" data-a="placeStart" ${nTargets ? '' : 'disabled'}>${ic('pin', 16)} Mode placement</button></div></div>` +
    T.points.map(spec => {
      const v = d.points[spec.key];
      if (spec.single) return `<div class="card"><div class="card-h"><div class="t">${ic('pin', 17)} ${esc(spec.label)}</div>${v && v.x != null ? chip('placé', 'ok') : chip('à placer', 'warn')}</div>${coordRow('points.' + spec.key, v, spec)}</div>`;
      const list = v || [];
      const rows = list.map((c, i) => {
        const p = `points.${spec.key}.${i}`;
        return `<div class="cat-row" style="grid-template-columns:30px 1fr"><div class="tile" style="width:28px;height:28px;border-radius:8px;font-weight:700;font-size:12px">${i + 1}</div><div>${coordRow(p, c, spec)}
          <div class="row wrap mt-s" style="gap:16px">${spec.team ? `<label class="f" style="flex-direction:row;align-items:center;gap:8px"><span>Équipe</span><select data-path="${p}.team" data-t="n" style="width:120px"><option value="1" ${(c.team || 1) === 1 ? 'selected' : ''}>1 · Bleue</option><option value="2" ${c.team === 2 ? 'selected' : ''}>2 · Rouge</option></select></label>` : ''}
          ${spec.radius ? fld('Rayon (m)', `<input type="number" step="0.1" min="0.3" data-path="${p}.r" data-t="n" value="${c.r ?? 3}" style="width:100px">`) : ''}${spec.pts ? fld('Points', `<input type="number" min="0" data-path="${p}.pts" data-t="n" value="${c.pts ?? 10}" style="width:100px">`) : ''}
          <span class="spacer"></span><button class="danger sm" data-a="ptDel" data-v="${spec.key}|${i}">${ic('trash', 14)} Retirer</button></div></div></div>`;
      }).join('') || '<div class="hint">Aucun point placé.</div>';
      const full = list.length >= (spec.max || 12);
      return `<div class="card"><div class="card-h"><div class="t">${ic('pin', 17)} ${esc(spec.label)}</div>${chip(list.length + ' / ' + (spec.max || 12), 'mute')}</div>${rows}
        <div class="row mt-s"><button class="sm" data-a="ptAdd" data-v="${spec.key}|here" ${full ? 'disabled' : ''}>${ic('plus', 14)} Ajouter ma position</button><button class="sm" data-a="ptAdd" data-v="${spec.key}|aim" ${full ? 'disabled' : ''}>${ic('target', 14)} Ajouter le point visé</button><button class="sm" data-a="ptAdd" data-v="${spec.key}|empty" ${full ? 'disabled' : ''}>${ic('plus', 14)} Ajouter (vide, pour le mode placement)</button></div></div>`;
    }).join('');
}

/* ── Carte, blip & marker (même éditeur que les autres builders) ── */
function tabMap(d) {
  const mk = d.marker || {}, ui = d.uiColor;
  const hexOf = c => '#' + c.map(n => Math.max(0, Math.min(255, n | 0)).toString(16).padStart(2, '0')).join('');
  const col = Array.isArray(mk.color) ? hexOf(mk.color) : '#fdc27d';
  return BBMap.customizeTab({ noun: 'de ce mini-jeu',
    blip: BBMap.blipCard({ base: 'blip', b: d.blip || {}, hint: 'Blip placé à l\'entrée du lobby. Champs vides = style commun du serveur.' }),
    marker: BBMap.markerCard({ base: 'marker', m: d.marker || {}, typeKey: 'type', colorHtml: fld('Couleur du marker', `<div class="row"><input type="color" data-path="__color" value="${col}" style="width:60px"><span class="muted sm-t">${mk.color ? 'personnalisée' : 'couleur du serveur'}</span>${mk.color ? '<button class="sm" data-a="colorReset">Réinitialiser</button>' : ''}</div>`) }),
    menu: `<div class="row"><input type="color" data-path="__ui" value="${ui ? hexOf(ui) : '#fdc27d'}" style="width:60px"><span class="muted sm-t">${ui ? 'personnalisée' : 'couleur du serveur'}</span></div>`,
    menuSet: !!ui, menuReset: 'uiReset', menuHint: "Couleur de l'interface en partie (compte à rebours, score, résultats). Par défaut : la couleur du serveur." });
}

function tabTop() {
  if (!S.curId) return emptyState('chart', 'Aucun classement', 'Enregistre le mini-jeu pour voir son classement.');
  if (!S.stats) { rpc('stats', S.curId).then(r => { S.stats = r.ok ? r.top : []; if (S.tab === 'top') render(); }); return '<div class="empty">Chargement…</div>'; }
  const race = typeOf(S.cur.type).engine === 'race';
  return `<div class="card"><table><tr><th>#</th><th>Joueur</th><th>${race ? 'Meilleur temps' : 'Meilleur score'}</th><th>Victoires</th><th>Parties</th></tr>${S.stats.map((r, i) => `<tr><td>${i + 1}</td><td>${esc(r.name)}</td><td>${race ? fmtMs(r.best_time) : r.best}</td><td>${r.wins}</td><td>${r.plays}</td></tr>`).join('') || '<tr><td colspan="5" class="muted">Aucune partie jouée</td></tr>'}</table></div>
    <button class="danger" data-a="resetStats">${ic('trash', 15)} Réinitialiser le classement</button>`;
}

function logsBody() {
  if (!S.logs) { rpc('logs').then(r => { S.logs = r.logs || []; if (S.view === 'logs') render(); }); return '<div class="empty">Chargement…</div>'; }
  return `<div class="card">${S.logs.map(l => `<div class="logline"><b>${esc(l.actor)}</b> · ${esc(l.action)} ${esc(l.game_id)} <span class="muted">${esc(l.details || '')}</span><div>${new Date(l.t * 1000).toLocaleString('fr-FR', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' })}</div></div>`).join('') || '<div class="muted">Rien pour le moment</div>'}</div>`;
}

/* ════════════════════════════ Actions du builder ════════════════════════════ */
const rootObj = el => (el.closest('[data-root]') && el.closest('[data-root]').dataset.root === 'prog' ? S.prog : S.cur);

async function openGame(id) {
  const r = await rpc('get', id);
  if (!r.ok) return toast(r.error || 'Erreur', 'err');
  S.cur = r.def; S.curId = id; S.dirty = false; S.tab = 'general'; S.stats = null; S.view = 'game';
  render();
}
async function newGame(type, tpl) {
  const r = await rpc('draft', type, tpl || 0);
  if (!r.ok) return toast(r.error || 'Erreur', 'err');
  S.cur = r.def; S.curId = null; S.dirty = true; S.tab = 'general'; S.stats = null; S.view = 'game';
  render();
}
async function guard() { return !S.dirty || await confirmBox('Modifications non enregistrées', 'Elles seront perdues si tu continues.', 'Continuer', true); }

let saving = false;
async function save() {
  if (saving) return;
  const d = S.cur;
  if (!d.name || d.name.trim().length < 2) return toast('Donne un nom au mini-jeu (2 caractères minimum)', 'err');
  const wantsOn = d.enabled;
  saving = true;
  let r;
  try { r = await rpc('save', d, S.curId || 0); } finally { saving = false; }
  if (!r.ok) return toast(r.error || 'Enregistrement impossible', 'err');
  S.curId = r.id; S.dirty = false; S.stats = null;
  const g = await rpc('get', r.id); if (g.ok) S.cur = g.def;
  await refreshList(); render();
  if (wantsOn && !r.enabled) toast('Enregistré, mais non activé : ' + ((r.problems && r.problems[0]) || 'incomplet'), 'err');
  else toast('Mini-jeu enregistré', 'ok');
}

function placementTargets() {
  const d = S.cur, out = [];
  if (!d) return out;
  if (S.tab === 'props') { (d.props || []).forEach((p, i) => out.push({ label: `Prop ${i + 1} · ${p.model}`, root: d, path: `props.${i}` })); return out; }
  const T = typeOf(d.type);
  T.points.forEach(spec => {
    if (spec.single) out.push({ label: spec.label, root: d, path: 'points.' + spec.key });
    else (d.points[spec.key] || []).forEach((c, i) => out.push({ label: `${spec.label} · ${i + 1}`, root: d, path: `points.${spec.key}.${i}` }));
  });
  return out;
}

const Placement = {
  on: false, targets: [], i: 0,
  async start() {
    const t = placementTargets();
    if (!t.length) return toast('Rien à placer : ajoute d\'abord un emplacement', 'err');
    this.targets = t; this.on = true;
    const first = t.findIndex(x => { const c = getPath(x.root, x.path); return !c || c.x == null; });
    this.i = first >= 0 ? first : 0;
    $root.classList.add('hidden');
    this.render();
    await rpc('placement', true);
  },
  render() {
    const el = document.getElementById('placement'), t = this.targets[this.i], c = getPath(t.root, t.path), has = c && c.x != null;
    el.innerHTML = `<div class="eyebrow">Mode placement · ${this.i + 1}/${this.targets.length}</div><b>${esc(t.label)}</b>
      <div class="coords ${has ? 'ok' : ''}">${has ? `✔ ${c.x}, ${c.y}, ${c.z}` : '⚠ position non définie'}</div>
      <div class="dots">${this.targets.map((x, k) => { const cc = getPath(x.root, x.path); return `<i class="${cc && cc.x != null ? 'set' : ''} ${k === this.i ? 'cur' : ''}"></i>`; }).join('')}</div>
      <div class="keys"><span><kbd>Entrée</kbd> Enregistrer ma position ici</span><span><kbd>←</kbd><kbd>→</kbd> Changer de cible</span><span><kbd>Retour</kbd> Revenir au menu</span></div>`;
    el.classList.remove('hidden');
  },
  save(c) {
    if (!this.on) return;
    const t = this.targets[this.i];
    setPath(t.root, t.path, Object.assign({}, getPath(t.root, t.path) || {}, { x: r2(c.x), y: r2(c.y), z: r2(c.z), h: r2(c.h) }));
    mark(); toast(`${t.label} : position enregistrée`, 'ok');
    if (this.i < this.targets.length - 1) this.i++;
    this.render();
  },
  nav(d) { if (!this.on) return; this.i = (this.i + d + this.targets.length) % this.targets.length; this.render(); },
  end() { this.on = false; document.getElementById('placement').classList.add('hidden'); $root.classList.remove('hidden'); render(); },
};

async function placeCoords(path, mode) {
  const r = await rpc(mode === 'aim' ? 'aimCoords' : 'getCoords');
  if (!r || r.ok === false) { toast('Aucun point visé : regarde une surface', 'err'); return null; }
  return { x: r2(r.x), y: r2(r.y), z: r2(r.z), h: r2(r.h || 0) };
}

const ACTIONS = {
  async close() { await rpc('close'); },
  async nav(v) {
    if (v === 'new') { if (!await guard()) return; S.view = 'home'; S.cur = null; S.curId = null; S.dirty = false; return render(); }
    if (v === 'home') return;
    if (v === 'prog') { if (!await guard()) return; return loadProg(); }
    if (v === 'logs') { if (!await guard()) return; S.logs = null; S.view = 'logs'; return render(); }
    if (v.startsWith('g:')) { if (!await guard()) return; return openGame(v.slice(2)); }
  },
  async new(v) { const [t, tpl] = v.split('|'); if (!await guard()) return; return newGame(t, tpl === '0' ? 0 : tpl); },
  tab(v) { S.tab = v; render(); },
  applyTpl(v) {
    const tp = typeOf(S.cur.type).templates.find(x => x.id === v);
    Object.assign(S.cur.settings, tp.settings); if (!S.cur.description) S.cur.description = tp.desc;
    mark(); toast(`Modèle « ${tp.label} » appliqué`, 'ok'); render();
  },
  save, placeStart: () => Placement.start(),
  async del() { if (!await confirmBox('Supprimer ce mini-jeu ?', 'Sa définition et son classement seront définitivement effacés.', 'Supprimer')) return; const r = await rpc('delete', S.curId); if (!r.ok) return toast(r.error, 'err'); S.cur = null; S.curId = null; S.dirty = false; S.view = 'home'; await refreshList(); render(); toast('Mini-jeu supprimé', 'ok'); },
  async dup() { const r = await rpc('duplicate', S.curId); if (!r.ok) return toast(r.error, 'err'); await refreshList(); await openGame(r.id); toast('Copie créée (désactivée)', 'ok'); },
  async resetStats() { if (!await confirmBox('Réinitialiser le classement ?', 'Toutes les statistiques de ce mini-jeu seront effacées.', 'Réinitialiser')) return; await rpc('resetStats', S.curId); S.stats = []; render(); toast('Classement réinitialisé', 'ok'); },
  async coords(path) { const c = await placeCoords(path, 'here'); if (c) { setPath(S.cur, path, Object.assign({}, getPath(S.cur, path) || {}, c)); mark(); toast('Position enregistrée', 'ok'); render(); } },
  async aim(path) { const c = await placeCoords(path, 'aim'); if (c) { setPath(S.cur, path, Object.assign({}, getPath(S.cur, path) || {}, c)); mark(); toast('Point visé enregistré', 'ok'); render(); } },
  async tp(path) { const c = getPath(S.cur, path); if (c) { await rpc('teleport', c); toast('Téléporté', 'ok'); } },
  async ptAdd(v) {
    const [k, m] = v.split('|'), spec = typeOf(S.cur.type).points.find(p => p.key === k);
    let c = {};
    if (m !== 'empty') { c = await placeCoords(k, m); if (!c) return; }
    if (spec.radius) c.r = 3; if (spec.pts) c.pts = 10; if (spec.team) c.team = 1;
    S.cur.points[k] = (S.cur.points[k] || []).concat([c]); mark(); render();
  },
  ptDel(v) { const [k, i] = v.split('|'); S.cur.points[k].splice(+i, 1); mark(); render(); },
  async propAdd() { return addProp('here'); }, async propAddAim() { return addProp('aim'); },
  async propHere(i) { const c = await placeCoords('', 'here'); if (c) { Object.assign(S.cur.props[+i], c); mark(); render(); } },
  propDel(i) { S.cur.props.splice(+i, 1); mark(); render(); },
  async testModel(path) {
    const model = getPath(S.cur, path);
    if (!model) return toast('Aucun modèle renseigné', 'err');
    const r = await rpc('previewProp', model);
    toast(r && r.ok ? `« ${model} » apparaît devant toi pendant 8 secondes` : `Modèle introuvable : ${model}`, r && r.ok ? 'ok' : 'err');
  },
  async bbPreview(path) { await rpc('bbPreview', getPath(S.cur, path) || {}); toast('Aperçu du marker devant toi', 'ok'); },
  uiReset() { delete S.cur.uiColor; mark(); render(); },
  colorReset() { if (S.cur.marker) delete S.cur.marker.color; mark(); render(); },
};
async function addProp(mode) {
  const free = $('#propFree') ? $('#propFree').value.trim() : '';
  const model = free || ($('#propSel') ? $('#propSel').value : '');
  if (!model || !/^[\w]+$/.test(model)) return toast('Choisis ou saisis un modèle valide', 'err');
  const c = await placeCoords('', mode); if (!c) return;
  const D = S.cat.propDefaults || {};
  S.cur.props = (S.cur.props || []).concat([Object.assign({ model, rx: 0, ry: 0, freeze: D.freeze !== false, collision: D.collision !== false, mode: D.mode || 'match' }, c)]);
  S.propSel = model; mark(); render();
}

document.addEventListener('click', e => {
  const t = e.target.closest('[data-a]');
  if (!t || t.tagName === 'SELECT') return;
  const a = t.dataset.a, v = t.dataset.v;
  if (PROG_ACTIONS[a]) return PROG_ACTIONS[a](v);
  if (LOBBY_ACTIONS[a]) return LOBBY_ACTIONS[a](t);
  if (ACTIONS[a]) return ACTIONS[a](v);
});

function onInput(el, change) {
  const p = el.dataset.path;
  if (!p) return;
  const root = rootObj(el);
  if (!root) return;
  if (p === '__ui') { const h = el.value; setPath(root, 'uiColor', [1, 3, 5].map(i => parseInt(h.slice(i, i + 2), 16))); mark(); if (change) render(); return; }
  if (p === '__color') {
    const h = el.value, rgb = [1, 3, 5].map(i => parseInt(h.slice(i, i + 2), 16));
    setPath(root, 'marker.color', rgb); mark(); if (change) render(); return;
  }
  let val;
  if (el.type === 'checkbox') val = el.checked;
  else if (el.dataset.t === 'n') val = el.value === '' ? undefined : Number(el.value);
  else { val = el.value; if (el.dataset.ne && val === '') return; }
  setPath(root, p, val);
  mark();
  // re-rendu différé (jamais pendant que la liste déroulante native est ouverte : ça fait planter / figer le menu)
  if (change && (el.dataset.r || el.dataset.path === 'enabled' || /^marker\.enabled$|^blip\.enabled$|weekly\.mode$/.test(p))) setTimeout(render, 60);
}
document.addEventListener('input', e => { if (e.target.dataset && e.target.dataset.path) onInput(e.target, false); });
document.addEventListener('change', e => {
  const el = e.target;
  if (el.dataset && el.dataset.a === 'propCat') { S.propCat = Number(el.value); S.propSel = ''; return setTimeout(render, 60); }
  if (el.dataset && el.dataset.path) onInput(el, true);
});

/* ════════════════════════════ Progression (admin) ════════════════════════════ */
const PTABS = [['xp', 'XP & coins'], ['levels', 'Niveaux'], ['challenges', 'Défis'], ['ach', 'Succès'], ['season', 'Semaine & saison']];
const CKINDS = [['plays', 'Parties jouées'], ['wins', 'Victoires'], ['points', 'Points marqués'], ['kills', 'Touches (paintball / laser)']];
const AKINDS = [['plays_total', 'Parties jouées (total)'], ['wins_total', 'Victoires (total)'], ['points_total', 'Points (total)'], ['best_streak', 'Série de victoires'], ['level', 'Niveau atteint']];

async function loadProg() {
  const r = await rpc('progGet');
  if (!r.ok) return toast(r.error || 'Erreur', 'err');
  S.prog = r.cfg; S.pgames = r.games || []; S.pfeat = r.featured; S.dirty = false; S.view = 'prog'; render();
}
const pv = path => getPath(S.prog, path);
const pN = (label, path, hint, min, max, step) => `<div>${fld(esc(label), `<input type="number" data-path="${path}" data-t="n" min="${min}" max="${max}" step="${step || 1}" value="${esc(pv(path) ?? '')}">`)}${hint ? `<div class="hint" style="margin-top:4px">${esc(hint)}</div>` : ''}</div>`;
const pB = (label, path, hint) => `<div><label class="chk"><input type="checkbox" data-path="${path}" data-t="b" ${pv(path) ? 'checked' : ''}> ${esc(label)}</label>${hint ? `<div class="hint" style="margin-top:2px">${esc(hint)}</div>` : ''}</div>`;
const pSel = (label, path, opts) => fld(esc(label), `<select data-path="${path}">${opts.map(o => `<option value="${esc(o[0])}" ${String(pv(path)) === String(o[0]) ? 'selected' : ''}>${esc(o[1])}</option>`).join('')}</select>`);
const pI = (label, path, w, min, max) => fld(esc(label), `<input type="number" data-path="${path}" data-t="n" min="${min}" max="${max}" value="${esc(pv(path) ?? '')}" ${w ? `style="width:${w}px"` : ''}>`);
const pT = (label, path, len) => fld(esc(label), `<input data-path="${path}" maxlength="${len}" value="${esc(pv(path) ?? '')}">`);
const gameOpts = () => [['any', 'Tous les jeux']].concat(S.cat.types.map(t => [t.key, t.label])).concat(S.pgames.map(g => [g.id, '↳ ' + g.name]));
const rowDel = path => `<button class="icon" data-a="pDel" data-v="${path}">${ic('trash', 15)}</button>`;

function progBody() {
  const c = S.prog, st = c.settings;
  const tabs = `<div class="seg">${PTABS.map(([k, l]) => `<button class="${S.pt === k ? 'active' : ''}" data-a="pTab" data-v="${k}">${l}</button>`).join('')}</div>`;
  let h = '';
  if (S.pt === 'xp') {
    h = `<div class="card"><div class="card-h"><div class="t">${ic('bolt', 17)} Gain d'XP par partie</div>${pB('XP activée', 'settings.xp.enabled')}</div><div class="grid4">
        ${pN('XP de participation', 'settings.xp.perGame', '', 0, 10000)}${pN('XP bonus de victoire', 'settings.xp.win', '', 0, 10000)}${pN('XP par point marqué', 'settings.xp.perPoint', '', 0, 1000, .5)}${pN('XP maximum par partie', 'settings.xp.maxPerGame', 'Plafond avant bonus', 0, 100000)}
        ${pN('Bonus par victoire consécutive (%)', 'settings.xp.streakPct', 'XP et gains d\'argent', 0, 200)}${pN('Série maximale prise en compte', 'settings.xp.streakMax', '', 0, 20)}</div></div>
      <div class="card"><div class="card-h"><div class="t">${ic('chart', 17)} Courbe de niveaux</div></div><div class="grid3">${pN('XP du niveau 1 → 2', 'settings.curve.base', '', 10, 1000000)}${pN('Multiplicateur par niveau', 'settings.curve.growth', '1.25 = 25 % de plus à chaque niveau', 1, 3, .01)}${pN('Niveau maximum', 'settings.curve.maxLevel', '', 1, 200)}</div></div>
      <div class="card"><div class="card-h"><div class="t">${ic('trophy', 17)} Palier d'XP → coins boutique</div>${pB('Activé', 'settings.milestone.enabled')}</div><div class="grid3">${pN('XP par palier', 'settings.milestone.xp', 'Tous les X points d\'XP cumulés', 100, 10000000)}${pN('Coins boutique par palier', 'settings.milestone.coins', 'Crédités sur la boutique du joueur', 0, 100000)}${pN('Argent par palier', 'settings.milestone.money', '', 0, 100000000)}</div></div>`;
  } else if (S.pt === 'levels') {
    h = `<div class="card"><div class="card-h"><div class="t">${ic('trophy', 17)} Récompenses par niveau</div><button class="sm" data-a="pAdd" data-v="levels">${ic('plus', 14)} Ajouter</button></div>${c.levels.map((l, i) => `<div class="cat-row" style="grid-template-columns:90px 1fr 120px 100px auto;align-items:end">${pI('Niveau', `levels.${i}.level`, 0, 1, 200)}${pT('Titre', `levels.${i}.title`, 24)}${pI('Argent', `levels.${i}.money`, 0, 0, 100000000)}${pI('Coins', `levels.${i}.coins`, 0, 0, 100000)}${rowDel('levels.' + i)}</div>`).join('') || '<div class="hint">Aucun palier</div>'}<div class="hint mt-s">Le titre s'affiche dans le profil et le lobby, jusqu'au palier suivant.</div></div>`;
  } else if (S.pt === 'challenges') {
    h = `<div class="card"><div class="card-h"><div class="t">${ic('list', 17)} Défis</div><button class="sm" data-a="pAdd" data-v="challenges">${ic('plus', 14)} Ajouter</button></div><div class="hint" style="margin-bottom:10px">Chaque joueur reçoit 3 défis quotidiens et 2 hebdomadaires tirés dans cette liste.</div>${c.challenges.map((e, i) => `<div class="cat-row ${e.enabled ? '' : 'off'}" style="grid-template-columns:1.5fr 110px 160px 150px 90px 80px 100px 80px 28px auto;align-items:end">${pT('Nom', `challenges.${i}.name`, 50)}${pSel('Période', `challenges.${i}.scope`, [['daily', 'Quotidien'], ['weekly', 'Hebdo']])}${pSel('Type', `challenges.${i}.kind`, CKINDS)}${pSel('Jeu', `challenges.${i}.game`, gameOpts())}${pI('Objectif', `challenges.${i}.target`, 0, 1, 1000000)}${pI('XP', `challenges.${i}.xp`, 0, 0, 100000)}${pI('Argent', `challenges.${i}.money`, 0, 0, 100000000)}${pI('Coins', `challenges.${i}.coins`, 0, 0, 100000)}<input type="checkbox" data-path="challenges.${i}.enabled" data-t="b" ${e.enabled ? 'checked' : ''} title="Actif">${rowDel('challenges.' + i)}</div>`).join('') || '<div class="hint">Aucun défi</div>'}</div>`;
  } else if (S.pt === 'ach') {
    h = `<div class="card"><div class="card-h"><div class="t">${ic('trophy', 17)} Succès</div><button class="sm" data-a="pAdd" data-v="achievements">${ic('plus', 14)} Ajouter</button></div>${c.achievements.map((e, i) => `<div class="cat-row ${e.enabled ? '' : 'off'}" style="grid-template-columns:1fr 1.2fr 170px 90px 80px 100px 80px 28px auto;align-items:end">${pT('Nom', `achievements.${i}.name`, 50)}${pT('Description', `achievements.${i}.desc`, 80)}${pSel('Condition', `achievements.${i}.kind`, AKINDS)}${pI('Valeur', `achievements.${i}.target`, 0, 1, 1000000)}${pI('XP', `achievements.${i}.xp`, 0, 0, 100000)}${pI('Argent', `achievements.${i}.money`, 0, 0, 100000000)}${pI('Coins', `achievements.${i}.coins`, 0, 0, 100000)}<input type="checkbox" data-path="achievements.${i}.enabled" data-t="b" ${e.enabled ? 'checked' : ''} title="Actif">${rowDel('achievements.' + i)}</div>`).join('') || '<div class="hint">Aucun succès</div>'}</div>`;
  } else {
    const w = st.weekly;
    h = `<div class="card"><div class="card-h"><div class="t">${ic('bolt', 17)} Mini-jeu de la semaine</div>${pB('Activé', 'settings.weekly.enabled')}</div><div class="grid3">${pSel('Choix du jeu', 'settings.weekly.mode', [['random', 'Aléatoire (chaque semaine)'], ['fixed', 'Fixe']])}${w.mode === 'fixed' ? pSel('Mini-jeu', 'settings.weekly.gameId', [['', '—']].concat(S.pgames.map(g => [g.id, g.name]))) : '<div></div>'}${pN('Multiplicateur de gains et d\'XP', 'settings.weekly.mult', '', 1, 10, .5)}</div>${S.pfeat ? `<div class="hint mt-s">Cette semaine : <b>${esc((S.pgames.find(g => g.id === S.pfeat) || {}).name || S.pfeat)}</b></div>` : ''}</div>
      <div class="card"><div class="card-h"><div class="t">${ic('trophy', 17)} Saison</div>${pB('Saisons activées', 'settings.season.enabled')}</div><div class="grid3">${pN('Durée d\'une saison (jours)', 'settings.season.days', '', 1, 365)}</div>
        <div class="eyebrow mt" style="margin-bottom:10px">Récompenses du podium</div>${st.season.rewards.map((r, i) => `<div class="cat-row" style="grid-template-columns:90px 140px 110px auto;align-items:end">${pI('Rang', `settings.season.rewards.${i}.rank`, 0, 1, 100)}${pI('Argent', `settings.season.rewards.${i}.money`, 0, 0, 100000000)}${pI('Coins', `settings.season.rewards.${i}.coins`, 0, 0, 100000)}${rowDel('settings.season.rewards.' + i)}</div>`).join('')}
        <div class="row mt-s"><button class="sm" data-a="pAdd" data-v="settings.season.rewards">${ic('plus', 14)} Ajouter un rang</button><button class="sm danger" data-a="seasonEnd">Terminer la saison maintenant</button></div></div>
      <div class="card"><div class="card-h"><div class="t">${ic('eye', 17)} Annonces serveur</div></div><div class="grid2">${pB('Annoncer les records battus', 'settings.announce.records')}${pB('Annoncer les niveaux ronds (5, 10, 15…)', 'settings.announce.levels')}</div></div>`;
  }
  return tabs + h;
}
const PROG_ACTIONS = {
  pTab(v) { S.pt = v; render(); },
  pDel(path) { const ks = path.split('.'); const i = +ks.pop(); getPath(S.prog, ks.join('.')).splice(i, 1); mark(); render(); },
  pAdd(path) {
    const defs = { levels: { level: 2, title: '', money: 0, coins: 0 }, challenges: { id: '', name: 'Nouveau défi', scope: 'daily', kind: 'plays', game: 'any', target: 3, xp: 50, money: 200, coins: 0, enabled: true },
      achievements: { id: '', name: 'Nouveau succès', desc: '', kind: 'wins_total', target: 10, xp: 100, money: 500, coins: 0, enabled: true }, 'settings.season.rewards': { rank: 4, money: 500, coins: 0 } };
    getPath(S.prog, path).push(Object.assign({}, defs[path])); mark(); render();
  },
  async progSave() { const r = await rpc('progSave', S.prog); if (!r.ok) return toast(r.error || 'Erreur', 'err'); S.prog = r.cfg; S.dirty = false; render(); toast('Progression enregistrée', 'ok'); },
  async progReset() { if (!await confirmBox('Valeurs par défaut ?', 'XP, niveaux, défis, succès et saison reviennent aux valeurs par défaut du serveur.', 'Réinitialiser')) return; const r = await rpc('progReset'); if (!r.ok) return toast(r.error, 'err'); S.prog = r.cfg; S.dirty = false; render(); toast('Valeurs par défaut restaurées', 'ok'); },
  async seasonEnd() { if (!await confirmBox('Terminer la saison maintenant ?', 'Les récompenses du podium sont versées et les classements de saison repartent à zéro.', 'Terminer la saison')) return; await rpc('seasonEnd'); toast('Saison terminée', 'ok'); loadProg(); },
};

/* ════════════════════════════ Lobby & profil joueur ════════════════════════════ */
const L = { data: null, joined: false, tab: 'game', prof: null };
const bar = (v, max, cls = '') => `<div class="xbar ${cls}"><i style="width:${max > 0 ? Math.min(100, v / max * 100) : 100}%"></i></div>`;
const rewTxt = (o, cur) => [o.xp > 0 ? '+' + o.xp + ' XP' : '', o.money > 0 ? '+' + cur + o.money : '', o.coins > 0 ? '+' + o.coins + ' coins' : ''].filter(Boolean).join(' · ') || '—';

function statusText() {
  const d = L.data; if (!d) return '';
  if (d.cooldown > 0) return `Patiente <b>${d.cooldown}s</b> avant de rejouer`;
  if (d.state === 'running' || d.state === 'countdown') return '<b>Partie en cours</b> — patiente quelques instants';
  const n = d.players.length, min = d.settings.minPlayers;
  if (d.state === 'waiting' && d.left != null) return `Départ dans <b>${fmtT(d.left)}</b> · ${n}/${d.settings.maxPlayers} joueur(s)`;
  if (d.state === 'waiting') return `En attente de joueurs · <b>${n}/${min}</b> minimum`;
  return 'Le lobby est libre';
}
const tabsSeg = (tab, only) => only ? '' : `<div class="seg" style="margin:0 8px 0 0"><button class="${tab === 'game' ? 'active' : ''}" data-a="lTab" data-v="game">Mini-jeu</button><button class="${tab === 'profile' ? 'active' : ''}" data-a="lTab" data-v="profile">Mon profil</button></div>`;

function renderLobby() {
  const el = document.getElementById('lobby');
  if (L.tab === 'profile') {
    el.innerHTML = `<div class="panel lobp" style="width:min(1000px,95vw)">${header({ icon: 'user', title: 'Mon profil', sub: 'Niveau, défis, succès et classements', acts: tabsSeg('profile', L.data && L.data.profileOnly) })}<div class="pb">${L.prof ? profileHtml(L.prof) : '<div class="empty">Chargement…</div>'}</div></div>`;
    return;
  }
  const d = L.data, st = d.settings, cur = d.currency || '$', race = d.engine === 'race';
  const best = m => (m && (race ? m.best_time : m.best)) ? (race ? fmtMs(m.best_time) : m.best) : '–';
  const top = (d.top || []).slice(0, 6).map((r, i) => `<div class="item"><span class="rk p${i + 1}">${i + 1}</span><div class="grow"><b>${esc(r.name)}</b></div><b>${race ? fmtMs(r.best_time) : r.best + ' pts'}</b></div>`).join('') || '<div class="hint">Personne n\'a encore joué.</div>';
  const pl = d.players.map(p => `<div class="item"><div class="avatar" style="width:30px;height:30px;border-radius:9px;font-size:12px">${esc((p.name || '?')[0].toUpperCase())}</div><div class="grow"><b>${esc(p.name)}</b></div>${p.team ? `<span class="tdot t${p.team}"></span>` : ''}</div>`).join('') || '<div class="hint">Aucun joueur dans le lobby.</div>';
  const full = d.players.length >= st.maxPlayers, busy = d.state === 'running' || d.state === 'countdown';
  const act = L.joined ? `<button class="danger" data-a="lLeave">Quitter la file</button>` : `<button class="primary" data-a="lJoin" ${(full || busy || d.cooldown > 0) ? 'disabled' : ''}>Rejoindre${st.entryFee > 0 ? ` · ${cur}${st.entryFee}` : ''}</button>`;
  el.innerHTML = `<div class="panel lobp">${header({ icon: d.type, title: d.name, sub: d.desc, acts: tabsSeg('game') })}
    <div class="pb">
      ${d.featured ? `<div class="banner"><b>Mini-jeu de la semaine ×${d.featured}</b>Gains et XP multipliés sur ce jeu.</div>` : ''}
      ${d.me ? `<div class="card" style="padding:14px"><div class="row"><span class="chip info">Niv. ${d.me.level}</span><span class="muted sm-t">${esc(d.me.title || '')}</span><span class="spacer"></span><span class="muted sm-t">${d.me.need ? d.me.cur + ' / ' + d.me.need + ' XP' : 'Niveau max'}</span></div>${bar(d.me.cur, d.me.need)}</div>` : ''}
      <div class="stats3"><div class="stat"><div class="lbl">Joueurs</div><div class="v">${st.minPlayers === st.maxPlayers ? st.maxPlayers : st.minPlayers + '–' + st.maxPlayers}</div></div>
        <div class="stat"><div class="lbl">Durée</div><div class="v">${race ? 'Au temps' : fmtT(d.engine === 'fight' ? st.rounds * st.roundTime : st.duration)}</div></div>
        <div class="stat"><div class="lbl">${st.entryFee > 0 ? 'Mise' : 'Entrée'}</div><div class="v">${st.entryFee > 0 ? cur + st.entryFee : 'Gratuite'}</div></div></div>
      <div class="lobgrid"><div><div class="eyebrow" style="margin-bottom:10px">Dans le lobby</div>${pl}</div>
        <div><div class="eyebrow" style="margin-bottom:10px">Classement</div>${top}<div class="eyebrow" style="margin:14px 0 10px">Ton record</div><div class="item"><div class="grow"><b>${best(d.mine)}</b><small>${d.mine ? d.mine.wins + ' victoire(s) · ' + d.mine.plays + ' partie(s)' : 'Jamais joué'}</small></div></div></div></div></div>
    <div class="lobfoot"><div class="st">${statusText()}</div>${act}</div></div>`;
}

const LOBBY_ACTIONS = {
  lTab(t) { L.tab = t.dataset.v; if (L.tab === 'profile' && !L.prof) loadProfile(); renderLobby(); },
  async lJoin() {
    const r = await rpc('join', L.data.id);
    if (!r.ok) return toast(r.error || 'Impossible de rejoindre', 'err');
    L.joined = true; GS.waitName = L.data.name; renderLobby();
  },
  async lLeave() { await rpc('leave'); L.joined = false; GS.wait = null; hideProgress(); drawGame(); renderLobby(); },
};

async function loadProfile() {
  const r = await rpc('profile');
  if (!r.ok) return toast('Profil indisponible', 'err');
  L.prof = r; if (L.tab === 'profile') renderLobby();
}

function profileHtml(P) {
  const cur = P.currency || '$';
  const ch = c => `<div class="item"><div class="grow"><b>${esc(c.name)}</b>${bar(c.progress, c.target, c.done ? 'ok' : '')}<small>${c.progress}/${c.target} · ${esc(rewTxt(c, cur))}</small></div>${c.done ? chip('fait', 'ok') : ''}</div>`;
  const ach = P.achievements.map(a => `<div class="ach ${a.unlocked ? 'on' : ''}"><div class="tile" style="width:34px;height:34px">${ic('trophy', 16)}</div><div><b>${esc(a.name)}</b><small>${esc(a.desc || '')}</small><small>${esc(rewTxt(a, cur))}</small></div></div>`).join('');
  const lv = P.levels.map(l => `<div class="item" style="${l.reached ? '' : 'opacity:.5'}"><span class="rk ${l.reached ? 'p1' : ''}">${l.level}</span><div class="grow"><b>${esc(l.title || 'Niveau ' + l.level)}</b></div><small class="muted">${esc(rewTxt(l, cur))}</small></div>`).join('');
  const topRow = (r, i, v) => `<div class="item"><span class="rk p${i + 1}">${i + 1}</span><div class="grow"><b>${esc(r.name)}</b></div><b>${v}</b></div>`;
  const seasonTop = P.season ? P.season.top.map((r, i) => topRow(r, i, r.season_xp + ' XP')).join('') || '<div class="hint">Personne pour le moment.</div>' : '';
  const gTop = P.globalTop.map((r, i) => topRow(r, i, r.xp + ' XP')).join('') || '<div class="hint">Aucun joueur classé.</div>';
  return `<div class="card"><div class="prof-h"><div class="lvl"><b>${P.level}</b><small>NIV.</small></div><div style="flex:1;min-width:0"><div style="font-size:22px;font-weight:700;letter-spacing:-.02em">${esc(P.name || 'Joueur')}</div>
      <div class="muted sm-t" style="margin:2px 0 4px">${esc(P.title || 'Sans titre')} · ${P.xp} XP au total${P.streak > 1 ? ` · série de ${P.streak}` : ''}</div>
      ${P.level >= P.maxLevel ? bar(1, 1, 'ok') + '<small class="muted">Niveau maximum atteint</small>' : bar(P.cur, P.need) + `<small class="muted">${P.cur} / ${P.need} XP vers le niveau ${P.level + 1}</small>`}</div></div></div>
    <div class="stats3"><div class="stat"><div class="lbl">Parties</div><div class="v">${P.plays}</div></div><div class="stat"><div class="lbl">Victoires</div><div class="v">${P.wins}</div></div><div class="stat"><div class="lbl">Points</div><div class="v">${P.points}</div></div></div>
    <div class="lobgrid" style="align-items:start"><div>
        ${P.featured ? `<div class="banner" style="margin-bottom:14px"><b>Mini-jeu de la semaine : ${esc(P.featured.name)}</b>Gains et XP ×${P.featured.mult}.</div>` : ''}
        ${P.milestone ? `<div class="eyebrow" style="margin-bottom:10px">Prochain palier de coins</div><div class="item"><div class="grow"><b>+${P.milestone.coins} coins boutique${P.milestone.money ? ' · +' + cur + P.milestone.money : ''}</b>${bar(P.milestone.into, P.milestone.xp)}<small>${P.milestone.into} / ${P.milestone.xp} XP · ${P.milestone.claimed} palier(s) obtenu(s)</small></div></div>` : ''}
        <div class="eyebrow" style="margin:14px 0 10px">Défis du jour</div>${P.daily.map(ch).join('') || '<div class="hint">Aucun défi.</div>'}
        <div class="eyebrow" style="margin:14px 0 10px">Défis de la semaine</div>${P.weekly.map(ch).join('') || '<div class="hint">Aucun défi.</div>'}
        <div class="eyebrow" style="margin:14px 0 10px">Paliers de niveau</div>${lv || '<div class="hint">Aucun palier.</div>'}</div>
      <div>${P.season ? `<div class="eyebrow" style="margin-bottom:10px">Saison ${P.season.id} · fin dans ${fmtLeft(P.season.endsIn)}</div>${seasonTop}<div class="hint" style="margin:6px 0 0">Tes points de saison : <b>${P.season.xp} XP</b> · ${P.season.rewards.map(r => '#' + r.rank + ' ' + (r.coins ? r.coins + ' coins' : '') + (r.money ? ' ' + cur + r.money : '')).join(' · ')}</div>` : ''}
        <div class="eyebrow" style="margin:14px 0 10px">Classement général</div>${gTop}
        <div class="eyebrow" style="margin:14px 0 10px">Succès</div><div class="achs">${ach || '<div class="hint">Aucun succès.</div>'}</div></div></div>`;
}

/* ════════════════════════════ Partie : HUD, compte à rebours, résultats ════════════════════════════ */
const GS = { playing: false, engine: null, name: '', hud: null, hint: '', wait: null, waitName: '', down: null, myName: '', res: null, progKey: 0 };

function showProgress(label, ms, hint) {
  const el = document.getElementById('progress');
  el.innerHTML = `<div class="plabel"><b>${esc(label)}</b><small>${esc(hint || '')}</small></div><div class="pbar"><i style="animation-duration:${ms}ms"></i></div>`;
  el.classList.remove('hidden');
}
const hideProgress = () => { GS.progKey = 0; document.getElementById('progress').classList.add('hidden'); };

function drawGame() {
  const g = document.getElementById('game');
  const visible = GS.playing || GS.wait || GS.res;
  g.classList.toggle('hidden', !visible);
  if (!$('#g-hud')) g.innerHTML = '<div id="g-hud"></div><div id="g-meter" class="hidden"><div class="meter"><div class="sweet"></div><div class="cur"></div></div></div><div id="g-over"></div>';
  if (!visible) { $('#g-hud').innerHTML = ''; return; }
  let h = '';
  if (!GS.playing && GS.wait && !GS.res) {
    const w = GS.wait;
    h += `<div class="wait"><span class="dot live"></span>${esc(GS.waitName)} · ${w.count}/${w.max} joueur(s)${w.left != null ? ' · départ ' + fmtT(w.left) : (w.count < w.min ? ' · en attente (' + w.min + ' min.)' : '')}<span class="muted" style="font-weight:500"><kbd>F9</kbd> quitter</span></div>`;
  }
  if (GS.playing && GS.hud) {
    const H = GS.hud, x = H.extra || {}, rows = H.rows || [];
    const me = rows.find(r => r.src === H.me);
    GS.myName = me ? me.name : GS.myName;
    h += `<div class="hud-time ${H.left <= 10 && GS.engine !== 'race' ? 'low' : ''}"><small>${GS.engine === 'fight' ? 'Round ' + (x.round || 1) + '/' + (x.rounds || 1) : esc(GS.name)}</small>${fmtT(H.left)}</div>`;
    if (GS.engine === 'fight') {
      const opp = rows.find(r => r.src !== H.me);
      const hb = r => r ? `<div class="fb"><div class="t"><span>${esc(r.name)}</span><span>${r.score} ◆</span></div><div class="hp ${r.hp / x.maxHp < .3 ? 'low' : ''}"><i style="width:${Math.max(0, Math.min(100, r.hp / x.maxHp * 100))}%"></i></div></div>` : '<div class="fb"></div>';
      h += `<div class="fight">${hb(me)}<div class="rd">VS</div>${hb(opp)}</div>`;
    } else {
      let b = `<h4>${GS.engine === 'race' ? 'Course' : 'Scores'}</h4>`;
      if (GS.engine === 'tag' && x.teams) b += `<div class="teams"><div class="t1">${x.teamScore[0]}</div><div class="t2">${x.teamScore[1]}</div></div>`;
      b += rows.slice(0, 8).map((r, i) => `<div class="brow ${r.src === H.me ? 'me' : ''}">${r.team ? `<span class="tdot t${r.team}"></span>` : `<span class="muted" style="width:14px;font-size:12px">${i + 1}</span>`}<span class="nm">${esc(r.name)}</span><span class="sc">${GS.engine === 'race' ? (r.finished ? fmtMs(r.time) : `${r.cp || 0}/${x.total}`) : r.score}</span></div>`).join('');
      if (GS.engine === 'tag' && x.limit) b += `<div class="muted" style="font-size:11.5px;padding:6px 10px">Limite : ${x.limit} touches</div>`;
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
  const me = r.rows.find(x => x.name === GS.myName);
  const title = !me ? 'Partie terminée' : (me.won ? 'Victoire !' : 'Partie terminée');
  const rows = r.rows.map(x => `<tr class="${x.name === GS.myName ? 'you' : ''}"><td>${x.pos}</td><td>${x.team ? `<span class="tdot t${x.team}" style="display:inline-block;margin-right:8px"></span>` : ''}${esc(x.name)}</td><td>${race ? (x.finished ? fmtMs(x.time) : 'Abandon') : x.score}</td><td class="gain">${x.gain > 0 ? '+' + (S.cat ? S.cat.currency : '$') + x.gain : ''}</td></tr>`).join('');
  return `<div class="res"><div class="resc"><div class="top"><h2>${title}</h2><p>${esc(r.name)}${r.teams ? ` · ${r.teamScore[0]} – ${r.teamScore[1]}` : ''} · ${esc(r.why || '')}</p></div><table><tr><th>#</th><th>Joueur</th><th>${race ? 'Temps' : (fight ? 'Rounds' : 'Score')}</th><th>Gain</th></tr>${rows}</table>${progResHtml(me)}<div class="foot2">Retour au lobby dans quelques secondes</div></div></div>`;
}
function progResHtml(me) {
  const p = me && me.prog; if (!p) return '';
  const cur = S.cat ? S.cat.currency : '$', lines = [];
  if (p.levelUp) lines.push(`<div class="pr-l up"><b>Niveau ${p.level} !</b>${p.title ? ' · ' + esc(p.title) : ''}</div>`);
  (p.levelUps || []).filter(l => l.money > 0 || l.coins > 0).forEach(l => lines.push(`<div class="pr-l">Palier niveau ${l.level} : ${esc(rewTxt({ money: l.money, coins: l.coins }, cur))}</div>`));
  (p.done || []).forEach(n => lines.push(`<div class="pr-l">Défi terminé : <b>${esc(n)}</b></div>`));
  (p.ach || []).forEach(n => lines.push(`<div class="pr-l">Succès débloqué : <b>${esc(n)}</b></div>`));
  if (p.milestoneCount) lines.push(`<div class="pr-l up">Palier d'XP atteint : coins boutique reçus !</div>`);
  if (me.mult && me.mult > 1) lines.push(`<div class="pr-l">Bonus ×${me.mult.toFixed(2).replace(/\.?0+$/, '')} (série / mini-jeu de la semaine)</div>`);
  return `<div class="prog-res"><div class="row"><span class="chip ok">+${p.xp} XP</span><b>Niveau ${p.level}</b><div style="flex:1">${bar(p.cur, p.need)}</div><small class="muted">${p.need ? p.cur + '/' + p.need : 'MAX'}</small></div>${lines.join('')}</div>`;
}

function overlay(html, ms) {
  const o = $('#g-over'); if (!o) return;
  const d = document.createElement('div'); d.innerHTML = html; const el = d.firstElementChild;
  o.appendChild(el); setTimeout(() => el.remove(), ms);
}
let tickTimer = null;
function startTick() {
  if (tickTimer) return;
  tickTimer = setInterval(() => {
    let again = false;
    if (L.data && L.data.left != null && L.data.left > 0) { L.data.left--; again = true; if (!$('#lobby').classList.contains('hidden') && L.tab === 'game') { const s = $('#lobby .st'); if (s) s.innerHTML = statusText(); } }
    if (GS.wait && GS.wait.left != null && GS.wait.left > 0) { GS.wait.left--; again = true; if (!GS.playing) drawGame(); }
    if (GS.down) { GS.down.secs--; const n = $('#dn'); if (n) n.textContent = Math.max(0, GS.down.secs); again = true; }
    if (!again) { clearInterval(tickTimer); tickTimer = null; }
  }, 1000);
}

/* ════════════════════════════ Messages du jeu ════════════════════════════ */
function hideUIs() { $root.classList.add('hidden'); $('#lobby').classList.add('hidden'); document.getElementById('confirm').classList.add('hidden'); }
window.addEventListener('message', e => {
  const m = e.data || {};
  switch (m.action) {
    case 'open':
      hideUIs();
      if (m.mode === 'builder') { $root.classList.remove('hidden'); load(); }
      else if (m.mode === 'lobby') {
        L.data = m.data; L.tab = m.data.profileOnly ? 'profile' : 'game'; L.prof = null; if (L.tab === 'profile') loadProfile();
        L.joined = !!m.data.joined; if (L.joined) GS.waitName = m.data.name;
        $('#lobby').classList.remove('hidden'); renderLobby(); startTick(); snd('open');
      }
      break;
    case 'close': hideUIs(); document.getElementById('placement').classList.add('hidden'); if (GS.wait && GS.wait.left > 0 && !GS.playing) { showProgress(`${GS.waitName || 'Mini-jeu'} · départ de la partie`, GS.wait.left * 1000, 'Appuie sur F9 pour quitter'); GS.progKey = GS.wait.left; } break;
    case 'placementSave': Placement.save(m.coords); break;
    case 'placementNav': Placement.nav(m.dir); break;
    case 'placementEnd': Placement.end(); break;
    case 'lobbyState': {
      const d = m.data;
      GS.wait = { count: d.count, min: d.min, max: d.max, left: d.left };
      if (L.data && L.data.id === d.id) { L.data.players = d.players; L.data.state = d.state; L.data.left = d.left; L.joined = true; if (!$('#lobby').classList.contains('hidden') && L.tab === 'game') renderLobby(); }
      if (d.state === 'waiting' || d.state === 'idle') {
        drawGame();
        const lobbyOpen = !$('#lobby').classList.contains('hidden');
        if (lobbyOpen) hideProgress();
        else if (d.left != null && d.left > 0 && (!GS.progKey || d.left > GS.progKey)) { showProgress(`${GS.waitName || 'Mini-jeu'} · départ de la partie`, d.left * 1000, 'Appuie sur F9 pour quitter'); }
        if (d.left == null) hideProgress(); else if (!lobbyOpen) GS.progKey = d.left;
      }
      startTick();
      break;
    }
    case 'kicked': GS.wait = null; GS.playing = false; GS.res = null; GS.down = null; L.joined = false; hideProgress(); drawGame(); if (m.text) toast(m.text, 'err'); break;
    case 'begin': if (Array.isArray(m.theme) && m.theme.length === 3) { const st = document.documentElement.style; st.setProperty('--accent', `rgb(${m.theme.join(',')})`); st.setProperty('--accent-rgb', m.theme.join(',')); st.setProperty('--pk-accent', `rgb(${m.theme.join(',')})`); st.setProperty('--pk-accent-rgb', m.theme.join(',')); } GS.playing = true; GS.engine = m.engine; GS.name = m.name; GS.hud = null; GS.hint = ''; GS.wait = null; GS.res = null; GS.down = null; hideProgress(); hideUIs(); drawGame(); break;
    case 'count': overlay(`<div class="cd"><span>${m.n}</span></div>`, 950); snd('tick'); break;
    case 'go': overlay(`<div class="cd"><span style="color:var(--ok);font-size:140px">GO !</span></div>`, 950); snd('confirm'); break;
    case 'hud': GS.hud = m.data; drawGame(); break;
    case 'hint': GS.hint = m.text; drawGame(); setTimeout(() => { if (GS.hint === m.text) { GS.hint = ''; drawGame(); } }, 7000); break;
    case 'meter': {
      const w = $('#g-meter'); if (!w) break;
      if (!m.show) { w.classList.add('hidden'); break; }
      w.classList.remove('hidden');
      const s = m.sweet || .15;
      $('.sweet', w).style.left = ((.5 - s / 2) * 100) + '%'; $('.sweet', w).style.width = (s * 100) + '%'; $('.cur', w).style.left = (m.v * 100) + '%';
      break;
    }
    case 'scored': overlay(`<div class="pop">${m.pts > 0 ? '+' + m.pts : '✓'}</div>`, 1000); snd('success'); break;
    case 'down': GS.down = { by: m.by, secs: m.secs }; drawGame(); startTick(); snd('error'); break;
    case 'respawn': GS.down = null; drawGame(); snd('confirm'); break;
    case 'hurt': snd('warn'); break;
    case 'round': overlay(`<div class="banner-c"><b>${m.data.winner ? 'Round ' + m.data.round + ' : ' + esc(m.data.winner) : 'Round ' + m.data.round + ' : égalité'}</b>${m.data.ko ? '<small>K.O. !</small>' : ''}</div>`, 3600); snd('success'); break;
    case 'end':
      if (m.data.you) GS.myName = m.data.you;
      GS.res = m.data; GS.playing = true; hideProgress(); drawGame(); snd('success');
      setTimeout(() => { GS.res = null; GS.playing = false; GS.hud = null; GS.wait = null; L.joined = false; ['--accent', '--accent-rgb', '--pk-accent', '--pk-accent-rgb'].forEach(k => document.documentElement.style.removeProperty(k)); drawGame(); }, ((m.data.ret || 6) + 0.5) * 1000);
      break;
  }
});
document.addEventListener('keydown', e => {
  if (e.key !== 'Escape') return;
  if (!document.getElementById('confirm').classList.contains('hidden')) return;
  if (Placement.on) return;
  if (!$root.classList.contains('hidden') || !$('#lobby').classList.contains('hidden')) rpc('close');
});

window.addEventListener('error', e => { if (e && e.message && e.message !== 'Script error.') toast('Erreur : ' + e.message, 'err'); });
window.addEventListener('unhandledrejection', e => { toast('Erreur : ' + ((e.reason && e.reason.message) || e.reason), 'err'); });
