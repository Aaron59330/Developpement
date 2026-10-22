'use strict';
const $root = document.getElementById('root');
const $ = (s, r = document) => r.querySelector(s);
const $$ = (s, r = document) => Array.from(r.querySelectorAll(s));
const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const resName = () => (typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'pickax_staff');
const snd = n => { try { window.BBUI && BBUI.play({ tick: 'click', announce: 'success', hover: 'hover' }[n] || n); } catch (e) {} };

async function rpc(name, ...args) {
  const ctl = new AbortController();
  const timer = setTimeout(() => ctl.abort(), 10000);
  try {
    const r = await fetch(`https://${resName()}/rpc`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ name, args: args.map(a => (a === undefined || a === null ? 0 : a)) }), signal: ctl.signal });
    return await r.json();
  } catch (e) {
    return { ok: false, error: ctl.signal.aborted ? `Le serveur ne répond pas à « ${name} »` : 'Erreur de communication' };
  } finally { clearTimeout(timer); }
}
function toast(msg, type = '') {
  const el = document.createElement('div');
  el.className = 'toast ' + type;
  el.textContent = msg;
  document.getElementById('toasts').appendChild(el);
  setTimeout(() => el.remove(), 4200);
}
/* Fenêtre de saisie : fields = [{ name, label, type: text|number|select|textarea|list, options, value, placeholder, listId }] → { name: valeur } ou null */
function ask(title, text, fields = [], okLabel = 'Confirmer', danger = false, extraHtml = '') {
  return new Promise(resolve => {
    const c = document.getElementById('confirm');
    const f = fields.map((x, i) => {
      const id = 'ask-' + i;
      if (x.type === 'select') return `<label class="f"><span>${esc(x.label)}</span><select id="${id}">${x.options.map(o => { const v = typeof o === 'object' ? o.value : o, l = typeof o === 'object' ? o.label : o; return `<option value="${esc(v)}" ${String(v) === String(x.value) ? 'selected' : ''}>${esc(l)}</option>`; }).join('')}</select></label>`;
      if (x.type === 'textarea') return `<label class="f"><span>${esc(x.label)}</span><textarea id="${id}" maxlength="${x.max || 300}" placeholder="${esc(x.placeholder || '')}">${esc(x.value || '')}</textarea></label>`;
      return `<label class="f"><span>${esc(x.label)}</span><input id="${id}" type="${x.type === 'number' ? 'number' : 'text'}" ${x.type === 'list' ? `list="dl-${x.listId}"` : ''} value="${esc(x.value ?? '')}" placeholder="${esc(x.placeholder || '')}" maxlength="${x.max || 200}" autocomplete="off"></label>`;
    }).join('');
    c.innerHTML = `<div class="box"><h2>${esc(title)}</h2><p>${esc(text || '')}</p>${extraHtml}${f}<div class="row mt"><span class="spacer"></span><button id="c-no">Annuler</button><button class="${danger ? 'danger' : 'primary'}" id="c-yes">${esc(okLabel)}</button></div></div>`;
    c.classList.remove('hidden');
    const done = v => { c.classList.add('hidden'); c.innerHTML = ''; resolve(v); };
    $('#c-no', c).onclick = () => done(null);
    $('#c-yes', c).onclick = () => { const o = {}; fields.forEach((x, i) => { o[x.name] = $('#ask-' + i, c).value; }); done(o); };
    const first = $('#ask-0', c); if (first) first.focus();
    c._hooks = { done };
  });
}
const confirmBox = (t, x, ok, danger = true) => ask(t, x, [], ok, danger).then(v => v !== null);

/* ───── Icônes ───── */
const P = {
  home: '<path d="m3 11 9-8 9 8"/><path d="M5 10v10h14V10"/>', users: '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.9"/><path d="M16 3.1a4 4 0 0 1 0 7.8"/>',
  flag: '<path d="M5 21V4M5 4h13l-2.5 4L18 12H5"/>', car: '<path d="M5 16l1.6-5a2 2 0 012-1.4h7a2 2 0 012 1.4L19 16M3 16h18v3H3z"/><circle cx="7.5" cy="19" r="1.6"/><circle cx="16.5" cy="19" r="1.6"/>',
  globe: '<circle cx="12" cy="12" r="10"/><path d="M2 12h20M12 2a15 15 0 0 1 0 20M12 2a15 15 0 0 0 0 20"/>', gavel: '<path d="m14 13-8.4 8.4a2 2 0 0 1-2.8-2.8L11 10M16 16l6-6M8 8l6-6M9 7l8 8M21 11l-8-8"/>',
  shield: '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10Z"/>', list: '<path d="M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01"/>', tool: '<path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/>',
  x: '<path d="M18 6 6 18"/><path d="m6 6 12 12"/>', search: '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>', refresh: '<path d="M21 12a9 9 0 1 1-3-6.7L21 8"/><path d="M21 3v5h-5"/>',
  back: '<path d="m15 18-6-6 6-6"/>', plus: '<path d="M5 12h14"/><path d="M12 5v14"/>', trash: '<path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/>',
  pin: '<path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/>', eye: '<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
  chat: '<path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>', mega: '<path d="m3 11 18-5v12L3 14v-3z"/><path d="M11.6 16.8a3 3 0 1 1-5.8-1.6"/>',
};
const ic = (n, s) => `<svg class="ic" viewBox="0 0 24 24" ${s ? `style="width:${s}px;height:${s}px"` : ''}>${P[n] || P.home}</svg>`;
const chip = (t, cls = '') => `<span class="chip ${cls}">${esc(t)}</span>`;
const tile = (i, cls = '') => `<div class="tile ${cls}">${ic(i)}</div>`;
const empty = (i, t, x) => `<div class="empty">${tile(i)}<h2>${esc(t)}</h2><p>${esc(x)}</p></div>`;
const fmtDate = t => { if (!t) return '—'; const d = new Date(t * 1000), p = n => String(n).padStart(2, '0'); return `${p(d.getDate())}/${p(d.getMonth() + 1)} ${p(d.getHours())}:${p(d.getMinutes())}`; };
const fmtUp = s => { const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60); return h ? `${h} h ${m} min` : `${m} min`; };
const money = n => (Number(n) || 0).toLocaleString('fr-FR') + ' $';
const RANKS = { 1: 'Modérateur', 2: 'Admin', 3: 'Superadmin', 4: 'Développeur' };

/* ───── État ───── */
const S = { tab: 'dash', d: null, perms: {}, cfg: {}, state: {}, bookmarks: [], players: [], q: '', filter: 'all', sel: null, selId: null, reports: [], logF: { action: '', q: '', page: 0 }, warnPage: 0,
  chat: [], items: null, jobs: null, rtab: 'chat', timer: null, me: 0, theme: 'neon', clock: null, nstaff: [], nTimer: null };
const can = k => S.perms[k] === true;
const TABS = [['dash', 'Accueil', 'home'], ['players', 'Joueurs', 'users'], ['reports', 'Reports', 'flag'], ['vehicles', 'Véhicules', 'car'], ['world', 'Monde', 'globe'], ['sanctions', 'Sanctions', 'gavel'], ['team', 'Équipe', 'shield'], ['logs', 'Journal', 'list'], ['tools', 'Outils', 'tool']];

/* ───── Coque ───── */
const TOG = [['noclip', 'NoClip'], ['invisible', 'Invisible'], ['invincible', 'Invincible'], ['names', 'Afficher les noms'], ['hud', 'HUD staff']];
const QUICK = [['self_heal', 'Soin', 'shield', '#22c55e'], ['self_revive', 'Réanimer', 'shield', '#ef4444'], ['self_armor', 'Gilet', 'shield', '#3b82f6'], ['tp_waypoint', 'TP marqueur', 'pin', '#f59e0b'],
  ['tp_back', 'Retour', 'back', '#a855f7'], ['veh_repair', 'Réparer', 'car', '#06b6d4'], ['veh_fuel', 'Plein', 'car', '#84cc16'], ['veh_flip', 'Retourner', 'car', '#14b8a6'], ['announce', 'Annonce', 'mega', '#ec4899'], ['legacy', 'Ancien menu', 'tool', '#64748b']];
function sideNeon() {
  const st = S.state || {};
  const badge = S.reports.filter(r => !r.isTake).length;
  $('#ntabs').innerHTML = TABS.map(([k, l, i]) => `<div class="n-tab ${S.tab === k ? 'active' : ''}" data-a="tab" data-k="${k}">${ic(i, 16)}<span>${l}</span>${k === 'reports' && badge ? `<b class="n-badge">${badge}</b>` : ''}</div>`).join('');
  $('#side').innerHTML = `<div class="n-card"><div class="n-ct">Informations sur vous</div><div class="n-me"><div class="n-av">${esc((S.d.name || '?').slice(0, 1).toUpperCase())}</div><div><b>${esc(S.d.name)}</b><small>${esc(RANKS[S.d.rank] || 'Staff')}</small></div><span class="n-id">${S.d.id}</span></div>
    <div class="kv"><span>Rang</span><b>${esc(RANKS[S.d.rank] || 'Staff')}</b></div><div class="kv"><span>Mode administration</span><b>${st.service ? 'Actif' : 'Inactif'}</b></div></div>
    <div class="n-card"><div class="n-ct">Statut</div><div class="svc ${st.service ? 'on' : ''}" data-a="svc"><div class="grow"><div>Mode administration</div><small>${st.service ? 'Actif : tenue staff' : 'Désactivé'}</small></div><span class="sw"></span></div>
    ${TOG.map(([k, l]) => `<div class="tg ${st[k] ? 'on' : ''}" data-a="tog" data-k="${k}"><span>${l}</span><span class="sw"></span></div>`).join('')}</div>`;
  $('#nquick').innerHTML = `<div class="n-ct" style="margin:0 0 8px">Actions rapides</div><div class="n-qrow">${QUICK.filter(q => can(q[0]) || q[0] === 'announce' && can('announce')).map(q => `<div class="n-q" data-a="${q[0] === 'announce' ? 'announce' : 'me'}" data-k="${q[0]}"><i style="background:${q[3]}">${ic(q[2], 22)}</i><span>${q[1]}</span></div>`).join('')}</div>`;
  nright();
}
function nright() {
  const staff = (S.nstaff || []).map(s => `<div class="n-st"><span>${esc(s.name)} <small>#${s.id}</small></span><em class="${s.service ? 'on' : ''}">${esc(RANKS[s.rank] || 'Staff')}</em></div>`).join('') || '<div class="hint">Personne.</div>';
  $('#nright').innerHTML = `<div class="n-card"><div class="n-ct">Heure du serveur</div><div class="n-clock" id="nclock">${clockText()}</div></div><div class="n-card" style="flex:1;overflow:auto"><div class="n-ct">Staff en ligne (${(S.nstaff || []).length})</div>${staff}</div>`;
}
const clockText = () => { const d = new Date(), p = n => String(n).padStart(2, '0'); return `${p(d.getHours())}:${p(d.getMinutes())}:${p(d.getSeconds())}`; };
async function refreshStaff() {
  const r = await rpc('dash');
  if (r && r.ok) { S.nstaff = r.staff; if (S.theme === 'neon' && $('#nright')) nright(); }
}
function side() {
  if (S.theme === 'neon') return sideNeon();
  const st = S.state || {};
  const badge = S.reports.filter(r => !r.isTake).length;
  $('#side').innerHTML = `<div class="profile"><div class="avatar">${ic('shield', 20)}</div><div><b>${esc(S.d.name)}</b><small>${esc(RANKS[S.d.rank] || 'Staff')} · ID ${S.d.id}</small></div></div>
    <div class="nav"><div class="nav-label">Navigation</div>${TABS.map(([k, l, i]) => `<div class="nav-item ${S.tab === k ? 'active' : ''}" data-a="tab" data-k="${k}">${ic(i)}<span class="grow">${l}</span>${k === 'reports' && badge ? `<span class="badge">${badge}</span>` : ''}</div>`).join('')}</div>
    <div class="me"><div class="svc ${st.service ? 'on' : ''}" data-a="svc"><div class="grow"><div>Mode administration</div><small>${st.service ? 'Actif : tenue staff' : 'Désactivé'}</small></div><span class="sw"></span></div>
    ${TOG.map(([k, l]) => `<div class="tg ${st[k] ? 'on' : ''}" data-a="tog" data-k="${k}"><span>${l}</span><span class="sw"></span></div>`).join('')}</div>`;
}
function shell() {
  clearInterval(S.clock); clearInterval(S.nTimer);
  document.body.classList.toggle('neon', S.theme === 'neon');
  if (S.theme === 'neon') {
    $root.innerHTML = `<div class="shell neon"><div class="n-top"><div class="n-logo">${ic('shield', 22)}</div><div class="n-title"><b>ADMIN <span>MENU</span></b><small>Panel staff</small></div><div class="n-tabs" id="ntabs"></div><div class="grow"></div>
      <button class="sm" data-a="theme" title="Revenir à l'ancien style">Style classique</button><button class="icon" data-a="close" title="Fermer (Échap)">${ic('x', 16)}</button></div>
      <div class="n-mid"><div class="n-left" id="side"></div><div class="main"><div class="head" id="head"></div><div class="body" id="body"></div></div><div class="n-right" id="nright"></div></div><div class="n-quick" id="nquick"></div></div>`;
    $root.classList.remove('hidden');
    S.clock = setInterval(() => { const c = $('#nclock'); if (c) c.textContent = clockText(); }, 1000);
    S.nTimer = setInterval(refreshStaff, 15000);
    side(); refreshStaff();
    return;
  }
  $root.innerHTML = `<div class="shell"><div class="side" id="side"></div><div class="main"><div class="head" id="head"></div><div class="body" id="body"></div></div></div>`;
  $root.classList.remove('hidden');
  side();
}
function frame(inner, title, sub, acts = '', needSvc = false) {
  const t = TABS.find(x => x[0] === S.tab);
  $('#head').innerHTML = `${tile(t ? t[2] : 'home', 'lg')}<div class="ttl"><h1>${esc(title)}</h1><p>${esc(sub || '')}</p></div><div class="acts">${acts}${S.theme === 'neon' ? '' : `<button class="sm" data-a="theme" title="Style néon">Style néon</button>`}${S.theme === 'neon' ? '' : `<button class="icon" data-a="close" title="Fermer (Échap)">${ic('x', 16)}</button>`}</div>`;
  const banner = needSvc && !S.state.service ? `<div class="warnbox">${ic('shield', 18)}<span>Active le <b>mode administration</b> (colonne de gauche) pour utiliser ces actions.</span></div>` : '';
  $('#body').innerHTML = banner + inner;
  side();
}
const refreshBtn = `<button class="icon" data-a="refresh" title="Actualiser">${ic('refresh', 16)}</button>`;
const needSvc = () => { if (!S.state.service) { toast('Active d\'abord le mode administration', 'err'); return false; } return true; };

/* ═══════════ Accueil ═══════════ */
async function viewDash() {
  const r = await rpc('dash');
  if (!r.ok) return toast(r.error, 'err');
  S.dash = r;
  S.reports = (await rpc('reports')).reports || S.reports;
  const q = (k, l, i) => can(k) ? `<button data-a="me" data-k="${k}">${ic(i, 16)} ${l}</button>` : '';
  const staff = r.staff.map(s => `<div class="kv"><span>${esc(s.name)} <small class="muted">#${s.id}</small></span><span>${chip(RANKS[s.rank] || 'Staff', s.service ? 'ok' : 'mute')}</span></div>`).join('') || '<div class="hint">Personne.</div>';
  const rec = r.recent.length ? r.recent.map(l => `<div class="logline"><b>${esc(l.staff_name)}</b> · ${esc(actLabel(l.action))}${l.target_name ? ' → ' + esc(l.target_name) : ''} <span class="muted">${fmtDate(l.t)}</span></div>`).join('') : '<div class="hint">Aucune action récente.</div>';
  frame(`<div class="grid4"><div class="stat"><div class="eyebrow">Joueurs</div><div class="v">${r.online}<small class="muted" style="font-size:14px"> / ${r.maxClients}</small></div><div class="s">en ligne</div></div>
    <div class="stat"><div class="eyebrow">Staff</div><div class="v">${r.staff.length}</div><div class="s">${r.service} en service</div></div>
    <div class="stat"><div class="eyebrow">Reports</div><div class="v">${r.reports}</div><div class="s">${r.waiting} en attente</div></div>
    <div class="stat"><div class="eyebrow">Bans actifs</div><div class="v">${r.bans}</div><div class="s">${r.warns24} avertissement(s) / 24 h</div></div></div>
    <div class="card"><div class="card-h"><div class="t">Actions rapides</div></div><div class="row wrap">${q('self_heal', 'Me soigner', 'shield')}${q('self_revive', 'Me réanimer', 'shield')}${q('self_armor', 'Gilet', 'shield')}${q('tp_waypoint', 'TP marqueur', 'pin')}${q('tp_back', 'Retour', 'back')}${q('veh_repair', 'Réparer le véhicule', 'car')}${can('announce') ? `<button data-a="announce">${ic('mega', 16)} Annonce serveur</button>` : ''}</div></div>
    <div class="grid2"><div class="card"><div class="card-h"><div class="t">Équipe en ligne</div></div>${staff}</div><div class="card"><div class="card-h"><div class="t">Dernières actions staff</div></div>${rec}<div class="hint mt-s">Serveur actif depuis ${fmtUp(r.uptime)}</div></div></div>`,
    'Accueil', 'Vue d\'ensemble du serveur', refreshBtn);
}

/* ═══════════ Joueurs ═══════════ */
function filtered() {
  const q = S.q.toLowerCase();
  return S.players.filter(p => {
    if (S.filter === 'staff' && !p.rank) return false;
    if (S.filter === 'players' && p.rank) return false;
    if (S.filter === 'near' && p.dist > 100) return false;
    if (S.filter === 'warned' && !p.warns) return false;
    return !q || String(p.id) === q || p.name.toLowerCase().includes(q) || (p.rp || '').toLowerCase().includes(q) || (p.job || '').toLowerCase().includes(q);
  });
}
function listHtml() {
  const l = filtered();
  if (!l.length) return empty('users', 'Aucun joueur', 'Aucun joueur ne correspond.');
  return `<div class="pl2 hd"><span>ID</span><span>Joueur</span><span>Métier</span><span>Ping</span><span>Dist.</span><span>Avert.</span><span></span></div>` + l.map(p => `<div class="pl2" data-a="player" data-id="${p.id}">
    <span class="mono">${p.id}</span><span class="nm">${esc(p.name)}${p.rp ? ` <small>${esc(p.rp)}</small>` : ''}</span><span><small>${esc(p.job || '—')}${p.job2 ? ' · ' + esc(p.job2) : ''}</small></span><span>${p.ping}</span><span>${p.dist} m</span>
    <span>${p.warns ? chip(String(p.warns), 'warn') : '<small>—</small>'}</span><span class="row">${p.rank ? chip(RANKS[p.rank] || 'Staff', p.service ? 'ok' : 'mute') : ''}${p.frozen ? chip('gelé', 'info') : ''}</span></div>`).join('');
}
async function viewPlayers(keep) {
  const r = await rpc('players');
  if (!r.ok) return toast(r.error, 'err');
  S.players = r.players; S.me = r.me;
  if (keep && $('#plist')) { $('#plist').innerHTML = listHtml(); return; }
  const F = [['all', 'Tous'], ['players', 'Joueurs'], ['staff', 'Staff'], ['near', 'Proches (100 m)'], ['warned', 'Avertis']];
  frame(`<div class="row" style="margin-bottom:12px"><div style="width:340px"><input id="pq" placeholder="Rechercher (nom, ID, métier)" value="${esc(S.q)}"></div><span class="hint">${r.players.length} joueur(s) · actualisation toutes les 5 s</span></div>
    <div class="chips">${F.map(([k, l]) => `<span class="chip ${S.filter === k ? 'on' : ''}" data-a="filter" data-k="${k}">${l}</span>`).join('')}</div><div id="plist">${listHtml()}</div>`, 'Joueurs', 'Choisis un joueur pour voir sa fiche et agir', refreshBtn);
}

/* ───── Actions sur un joueur (définies une fois : libellé, droit, champs) ───── */
const reasonOpts = () => (S.cfg.reasons || []).map(x => x);
const ACTS = [
  ['Téléportation', [
    { k: 'gotoPlayer', l: 'Aller sur lui' }, { k: 'bringPlayer', l: 'L\'amener' }, { k: 'sendback', l: 'Le renvoyer' },
    { k: 'tpquick', l: 'Envoyer à un lieu rapide', quick: true, perm: 'tpcoords' },
    { k: 'tpcoords', l: 'Téléporter à…', fields: () => [{ name: 'x', label: 'X', type: 'number' }, { name: 'y', label: 'Y', type: 'number' }, { name: 'z', label: 'Z', type: 'number' }] } ]],
  ['Santé', [
    { k: 'heal', l: 'Soigner' }, { k: 'revive', l: 'Réanimer' }, { k: 'armor', l: 'Gilet' },
    { k: 'freeze', l: 'Geler / libérer', toggle: true }, { k: 'kill', l: 'Tuer', danger: true, confirm: 'Tuer ce joueur ?' } ]],
  ['Communication & sanctions', [
    { k: 'message', l: 'Envoyer un message', fields: () => [{ name: 'text', label: 'Message', type: 'textarea', max: 200 }], ok: 'Envoyer' },
    { k: 'warn', l: 'Avertir', fields: () => [{ name: 'preset', label: 'Motif rapide', type: 'select', options: ['—', ...reasonOpts()] }, { name: 'reason', label: 'Précisions (remplace le motif rapide)', type: 'text', max: 250 }], ok: 'Avertir', prep: v => ({ reason: v.reason || (v.preset !== '—' ? v.preset : '') }) },
    { k: 'spectate', l: 'Spectate' },
    { k: 'screenshot', l: 'Capture d\'écran', core: true },
    { k: 'jail', l: 'Prison', fields: () => [{ name: 'minutes', label: 'Minutes', type: 'select', options: S.cfg.jailPresets || [10] }], ok: 'Envoyer en prison', danger: true },
    { k: 'unjail', l: 'Sortir de prison' },
    { k: 'kick', l: 'Expulser', danger: true, fields: () => [{ name: 'preset', label: 'Motif rapide', type: 'select', options: ['—', ...reasonOpts()] }, { name: 'reason', label: 'Précisions', type: 'text' }], ok: 'Expulser', prep: v => ({ reason: v.reason || (v.preset !== '—' ? v.preset : '') }) },
    { k: 'ban', l: 'Bannir', danger: true, fields: () => [{ name: 'duration', label: 'Durée', type: 'select', options: S.cfg.banDurations || ['1d', 'perm'], value: '1d' }, { name: 'preset', label: 'Motif rapide', type: 'select', options: ['—', ...reasonOpts()] }, { name: 'reason', label: 'Précisions', type: 'text' }], ok: 'Bannir', prep: v => ({ duration: v.duration, reason: v.reason || (v.preset !== '—' ? v.preset : 'Infraction au règlement') }) } ]],
  ['Économie & inventaire', [
    { k: 'giveMoney', l: 'Donner de l\'argent', fields: () => [{ name: 'account', label: 'Compte', type: 'select', options: [{ value: 'cash', label: 'Espèces' }, { value: 'bank', label: 'Banque' }, { value: 'black', label: 'Argent sale' }] }, { name: 'amount', label: 'Montant', type: 'number' }], ok: 'Donner' },
    { k: 'takeMoney', l: 'Retirer de l\'argent', danger: true, fields: () => [{ name: 'account', label: 'Compte', type: 'select', options: [{ value: 'cash', label: 'Espèces' }, { value: 'bank', label: 'Banque' }, { value: 'black', label: 'Argent sale' }] }, { name: 'amount', label: 'Montant', type: 'number' }], ok: 'Retirer' },
    { k: 'giveItem', l: 'Donner un objet', items: true, fields: () => [{ name: 'item', label: 'Objet (nom)', type: 'list', listId: 'items' }, { name: 'count', label: 'Quantité', type: 'number', value: 1 }], ok: 'Donner' },
    { k: 'takeItem', l: 'Retirer un objet', danger: true, items: true, fields: () => [{ name: 'item', label: 'Objet (nom)', type: 'list', listId: 'items' }, { name: 'count', label: 'Quantité', type: 'number', value: 1 }], ok: 'Retirer' },
    { k: 'giveWeapon', l: 'Donner une arme', items: true, fields: () => [{ name: 'weapon', label: 'Arme', type: 'list', listId: 'weapons', placeholder: 'WEAPON_PISTOL' }], ok: 'Donner' },
    { k: 'clearInventory', l: 'Vider l\'inventaire', danger: true, confirm: 'Vider tout l\'inventaire de ce joueur ? Action irréversible.' } ]],
  ['Identité & métier', [
    { k: 'setJob', l: 'Changer le métier', job: 'jobs' }, { k: 'setJob2', l: 'Changer le gang / l\'orga', job: 'jobs2' },
    { k: 'resetIdentity', l: 'Réinitialiser l\'identité', danger: true, confirm: 'Demander la réinitialisation de l\'identité ?' }, { k: 'setGrade', l: 'Grade staff', grade: true },
    { k: 'wipe', l: 'Wipe le joueur', danger: true, core: true, typed: true } ]],
];
async function ensureItems() {
  if (S.items) return;
  const r = await rpc('items');
  S.items = r.ok ? r.items : [];
}
function datalists() {
  const items = (S.items || []);
  return `<datalist id="dl-items">${items.filter(i => !i.weapon).map(i => `<option value="${esc(i.name)}">${esc(i.label)}</option>`).join('')}</datalist><datalist id="dl-weapons">${items.filter(i => i.weapon).map(i => `<option value="${esc(i.name)}">${esc(i.label)}</option>`).join('')}</datalist>`;
}
async function runAct(def, p) {
  if (!needSvc()) return;
  let args = {};
  if (def.toggle) args.state = !p.frozen;
  if (def.confirm && !(await confirmBox(def.confirm, p.name, 'Confirmer', true))) return;
  if (def.items) await ensureItems();
  if (def.core) {
    if (def.typed) {
      const v = await ask('Wipe de ' + p.name, 'Action IRRÉVERSIBLE : le personnage est effacé. Tape OUI pour confirmer.', [{ name: 'c', label: 'Confirmation', type: 'text', max: 3 }], 'Wiper', true);
      if (!v || v.c.trim().toLowerCase() !== 'oui') return toast('Annulé', '');
    }
    const r = await rpc('coreAction', def.k, p.id);
    return toast(r.ok ? 'Demande envoyée' : r.error, r.ok ? 'ok' : 'err');
  }
  if (def.quick) {
    const q = S.cfg.quickTp || [];
    if (!q.length) return toast('Aucun lieu rapide configuré', 'err');
    const v = await ask('Lieu rapide', `Envoyer ${p.name} :`, [{ name: 'i', label: 'Lieu', type: 'select', options: q.map((x, i) => ({ value: i, label: x.label })) }], 'Envoyer');
    if (!v) return;
    const t = q[+v.i];
    const r = await rpc('act', 'tpcoords', p.id, { x: t.x, y: t.y, z: t.z });
    toast(r.ok ? r.msg : r.error, r.ok ? 'ok' : 'err');
    return viewPlayer(p.id, true);
  }
  if (def.job) {
    if (!S.jobs) { const r = await rpc('jobs'); S.jobs = r.ok ? r : { jobs: [], jobs2: [] }; }
    const list = S.jobs[def.job] || [];
    if (!list.length) return toast('Aucun élément trouvé en base', 'err');
    const v = await ask(def.l, `Joueur : ${p.name}`, [{ name: 'job', label: 'Choix', type: 'select', options: list.map(j => ({ value: j.name, label: j.label })) }], 'Suivant', false);
    if (!v) return;
    const j = list.find(x => x.name === v.job) || list[0];
    const g = await ask(def.l, `${j.label} : choisis le grade`, [{ name: 'grade', label: 'Grade', type: 'select', options: (j.grades || []).map(x => ({ value: x.grade, label: `${x.label} (${x.grade})` })) }], 'Appliquer');
    if (!g) return;
    args = { job: j.name, grade: Number(g.grade) };
  } else if (def.grade) {
    const r = await rpc('grades');
    if (!r.ok) return toast(r.error, 'err');
    const v = await ask('Grade staff', `Joueur : ${p.name}`, [{ name: 'group', label: 'Grade', type: 'select', options: r.grades.map(g => ({ value: g.name, label: g.label })), value: p.group }], 'Appliquer');
    if (!v) return;
    args = { group: v.group };
  } else if (def.fields) {
    const v = await ask(def.l, `Joueur : ${p.name}`, def.fields(), def.ok || 'Valider', !!def.danger, def.items ? datalists() : '');
    if (!v) return;
    args = def.prep ? def.prep(v) : v;
    for (const k of Object.keys(args)) if (/^(x|y|z|amount|count|minutes)$/.test(k)) args[k] = Number(args[k]);
  }
  const r = await rpc('act', def.k, p.id, args);
  toast(r.ok ? (r.msg || 'Fait') : r.error, r.ok ? 'ok' : 'err');
  if (r.ok && def.k !== 'spectate') return viewPlayer(p.id, true);
}

/* Fiche joueur */
async function viewPlayer(id, quiet) {
  S.selId = id;
  const r = await rpc('player', id);
  if (!r.ok) { toast(r.error, 'err'); S.selId = null; return show('players'); }
  S.sel = r;
  const ids = Object.entries(r.identifiers || {}).map(([k, v]) => `<div class="kv"><span>${esc(k)}</span><span class="mono">${esc(v)}</span></div>`).join('');
  const acc = r.accounts;
  const act = ACTS.map(([g, list]) => {
    const btns = list.filter(a => can(a.perm || a.k)).map(a => `<button class="${a.danger ? 'danger' : ''}" data-a="act" data-k="${a.k}">${esc(a.k === 'freeze' ? (r.frozen ? 'Libérer' : 'Geler') : a.l)}</button>`).join('');
    return btns ? `<div class="grp-t">${g}</div><div class="acts-grid">${btns}</div>` : '';
  }).join('');
  const warns = r.warns.length ? r.warns.map(w => `<div class="logline"><b>${esc(w.reason)}</b> · ${esc(w.staff_name)} <span class="muted">${fmtDate(w.t)}</span>${can('warnDelete') ? ` <button class="sm danger" data-a="delEntry" data-kind="warn" data-eid="${w.id}">${ic('trash', 12)}</button>` : ''}</div>`).join('') : '<div class="hint">Aucun avertissement.</div>';
  const notes = r.notes.length ? r.notes.map(n => `<div class="logline">${esc(n.note)} · <b>${esc(n.staff_name)}</b> <span class="muted">${fmtDate(n.t)}</span>${can('warnDelete') ? ` <button class="sm danger" data-a="delEntry" data-kind="note" data-eid="${n.id}">${ic('trash', 12)}</button>` : ''}</div>`).join('') : '<div class="hint">Aucune note.</div>';
  const hist = r.history.length ? r.history.map(h => `<div class="logline"><b>${esc(actLabel(h.action))}</b> par ${esc(h.staff_name)} <span class="muted">${fmtDate(h.t)}</span></div>`).join('') : '<div class="hint">Aucune action staff sur ce joueur.</div>';
  const bans = r.bans.length ? r.bans.map(b => `<div class="logline"><b>${esc(b.reason)}</b> · ${esc(b.sourceName)} <span class="muted">${fmtDate(b.timeat)}${b.permanent == 1 ? ' · permanent' : ''}</span></div>`).join('') : '<div class="hint">Aucun ban antérieur.</div>';
  frame(`<div class="split"><div>
      <div class="card">${act || '<div class="hint">Tu n\'as accès à aucune action.</div>'}${!r.canPunish ? '<p class="hint mt-s">Ce membre du staff a un rang égal ou supérieur : les sanctions sont bloquées.</p>' : ''}</div>
      <div class="card"><div class="card-h"><div class="t">Avertissements (${r.warns.length})</div></div>${warns}</div>
      <div class="card"><div class="card-h"><div class="t">Notes staff</div>${can('notes') ? '<button class="sm" data-a="addNote">Ajouter</button>' : ''}</div>${notes}</div>
      <div class="card"><div class="card-h"><div class="t">Historique des actions</div></div>${hist}<div class="card-h mt"><div class="t">Bans précédents</div></div>${bans}</div></div>
    <div><div class="card"><div class="card-h"><div class="t">Informations</div></div>
      <div class="kv"><span>Groupe</span><b>${esc(r.groupLabel || r.group)}</b></div><div class="kv"><span>Métier</span><b>${r.job ? esc(r.job.label) + ' · ' + esc(r.job.gradeLabel || '') : '—'}</b></div>
      <div class="kv"><span>Gang / orga</span><b>${r.job2 && r.job2.name !== 'unemployed2' ? esc(r.job2.label) : '—'}</b></div>
      <div class="kv"><span>Santé / armure</span><b>${r.health} / ${r.armor}</b></div><div class="kv"><span>Ping</span><b>${r.ping} ms</b></div>
      <div class="kv"><span>Position</span><span class="mono">${r.coords.x}, ${r.coords.y}, ${r.coords.z}</span></div>${r.frozen ? '<div class="kv"><span>État</span><b>Gelé</b></div>' : ''}</div>
      <div class="card"><div class="card-h"><div class="t">Argent</div></div><div class="kv"><span>Espèces</span><b>${money(acc.cash)}</b></div><div class="kv"><span>Banque</span><b>${money(acc.bank)}</b></div><div class="kv"><span>Argent sale</span><b>${money(acc.black)}</b></div>
      ${can('viewinv') ? '<button class="sm mt-s" data-a="inv">Voir l\'inventaire</button><div id="invbox" class="mt-s"></div>' : ''}</div>
      <div class="card"><div class="card-h"><div class="t">Identifiants</div></div>${ids}</div></div></div>`,
    `${r.name} (#${r.id})`, r.rp ? `Personnage : ${r.rp}` : '', `<button data-a="players-back">${ic('back', 16)} Retour</button>${refreshBtn}`, true);
}

/* ═══════════ Reports ═══════════ */
async function viewReports() {
  const r = await rpc('reports');
  if (!r.ok) return toast(r.error, 'err');
  S.reports = r.reports;
  const mine = n => r.reports.filter(x => n ? x.isTake : !x.isTake);
  const row = x => `<div class="item"><div class="grow"><b>${esc(x.nom)} ${chip('#' + x.id, 'mute')} ${x.isTake ? chip('pris par ' + (x.staff || '?'), 'info') : chip('en attente', 'warn')}</b><small>${esc(x.args)} · ${esc(x.created || '')}</small></div>
    ${!x.isTake ? `<button class="sm primary" data-a="rtake" data-id="${x.id}">Prendre</button>` : ''}
    <button class="sm" data-a="rgoto" data-id="${x.id}">Aller sur lui</button><button class="sm" data-a="rbring" data-id="${x.id}">L'amener</button>
    <button class="sm" data-a="rreply" data-id="${x.id}">Répondre</button><button class="sm" data-a="player" data-id="${x.id}">Fiche</button><button class="sm danger" data-a="rclose" data-id="${x.id}">Fermer</button></div>`;
  frame((r.reports.length ? `${mine(false).length ? '<div class="grp-t">En attente</div>' + mine(false).map(row).join('') : ''}${mine(true).length ? '<div class="grp-t">En cours</div>' + mine(true).map(row).join('') : ''}` : empty('flag', 'Aucun report', 'Les joueurs t\'écrivent avec /report. Tout est calme.')),
    'Reports', 'Demandes d\'aide des joueurs (/report)', refreshBtn, true);
}

/* ═══════════ Véhicules ═══════════ */
const FAV_VEH = ['adder', 'zentorno', 'sultan', 'kuruma', 'sanchez', 'buzzard2', 'dinghy', 'police', 'ambulance', 'firetruk'];
function viewVehicles() {
  const B = (k, l, extra = '') => can(k) ? `<button data-a="me" data-k="${k}" ${extra}>${l}</button>` : '';
  frame(`${can('veh_spawn') ? `<div class="card"><div class="card-h"><div class="t">Faire apparaître un véhicule</div></div><div class="row"><div style="width:280px"><input id="vmodel" placeholder="Nom du modèle (ex : adder)" maxlength="40"></div><button class="primary" data-a="vspawn">Faire apparaître</button></div>
      <div class="chips mt-s">${FAV_VEH.map(m => `<span class="chip" data-a="vfav" data-m="${m}">${m}</span>`).join('')}</div><p class="hint">Le véhicule apparaît sous toi et tu y montes. Les plaques commencent par STAFF.</p></div>` : ''}
    <div class="card"><div class="card-h"><div class="t">Véhicule actuel (ou le plus proche, 8 m)</div></div><div class="acts-grid">
      ${B('veh_repair', 'Réparer')}${B('veh_clean', 'Nettoyer')}${B('veh_flip', 'Retourner')}${B('veh_fuel', 'Faire le plein')}${B('veh_unlock', 'Déverrouiller')}${B('veh_max', 'Custom au maximum')}${can('veh_delete') ? '<button class="danger" data-a="me" data-k="veh_delete">Supprimer</button>' : ''}</div></div>
    ${can('veh_give') ? `<div class="card"><div class="card-h"><div class="t">Donner un véhicule (garage + clé)</div></div><div class="row"><div style="width:280px"><input id="vgive" placeholder="Nom du modèle (ex : sultan)" maxlength="40"></div><button data-a="vgive">Ajouter à mon garage</button></div><p class="hint">Le véhicule est créé, ajouté à ton garage avec sa clé et ta plaque est générée.</p></div>` : ''}
    ${can('veh_plate') ? `<div class="card"><div class="card-h"><div class="t">Plaque</div></div><div class="row"><div style="width:200px"><input id="vplate" placeholder="8 caractères max" maxlength="8"></div><button data-a="vplate">Changer la plaque</button></div></div>` : ''}
    ${can('veh_neon') ? `<div class="card"><div class="card-h"><div class="t">Néons</div></div><div class="row"><input type="color" id="vneon" value="#00a4ff" style="width:80px;padding:3px"><button data-a="vneon">Appliquer la couleur</button><button data-a="vneonoff">Éteindre</button></div></div>` : ''}`,
    'Véhicules', 'Actions sur ton véhicule', '', true);
}

/* ═══════════ Monde ═══════════ */
function viewWorld() {
  const w = (S.cfg.weather || []).map(k => `<button data-a="weather" data-k="${k}">${k}</button>`).join('');
  const times = [['Matin', 8, 0], ['Midi', 12, 0], ['Soir', 19, 0], ['Nuit', 0, 0]];
  frame(`${can('weather') ? `<div class="card"><div class="card-h"><div class="t">Météo</div></div><div class="wgrid">${w}</div></div>` : ''}
    ${can('time') ? `<div class="card"><div class="card-h"><div class="t">Heure</div></div><div class="row wrap">${times.map(t => `<button data-a="time" data-h="${t[1]}" data-m="${t[2]}">${t[0]}</button>`).join('')}<div style="width:70px"><input id="th" type="number" min="0" max="23" placeholder="h"></div><div style="width:70px"><input id="tm" type="number" min="0" max="59" placeholder="min"></div><button data-a="timeset">Régler</button></div></div>` : ''}
    ${can('announce') ? `<div class="card"><div class="card-h"><div class="t">Annonce à tous les joueurs</div></div><textarea id="ann" maxlength="${S.cfg.announceMax || 160}" placeholder="Texte de l'annonce…"></textarea><div class="row mt-s"><button class="primary" data-a="annsend">${ic('mega', 16)} Envoyer</button></div></div>` : ''}
    ${can('cleanup') ? `<div class="card"><div class="card-h"><div class="t">Nettoyer autour de moi</div></div><div class="row wrap"><div style="width:140px"><input id="crad" type="number" min="5" max="${S.cfg.cleanupMax || 300}" value="50"></div><span class="hint">rayon en mètres</span><button data-a="clean" data-k="vehicles">Supprimer les véhicules vides</button><button data-a="clean" data-k="peds">Supprimer les PNJ</button></div></div>` : ''}
    ${can('reviveAll') || can('healAll') ? `<div class="card"><div class="card-h"><div class="t">Tout le serveur</div></div><div class="row">${can('reviveAll') ? '<button class="danger" data-a="all" data-k="reviveAll">Réanimer tout le monde</button>' : ''}${can('healAll') ? '<button class="danger" data-a="all" data-k="healAll">Soigner tout le monde</button>' : ''}</div></div>` : ''}`,
    'Monde', 'Météo, heure, annonces et nettoyage', '', true);
}

/* ═══════════ Sanctions ═══════════ */
async function viewSanctions() {
  const r = await rpc('warns', S.warnPage);
  if (!r.ok) return toast(r.error, 'err');
  const rows = r.warns.length ? r.warns.map(w => `<div class="lgr" style="grid-template-columns:100px 160px 150px 1fr"><span>${fmtDate(w.t)}</span><span class="nm">${esc(w.name)}</span><span>${esc(w.staff_name)}</span><span class="d">${esc(w.reason)}</span></div>`).join('') : empty('gavel', 'Aucun avertissement', 'Rien pour le moment.');
  frame(`<div class="row wrap" style="margin-bottom:14px"><button data-a="openPanel" data-k="anticheat">${ic('shield', 16)} Bannissements & anti-cheat</button><span class="hint">Bans, débans et bans hors ligne : panel anti-cheat (/anticheat).</span></div>
    <div class="card" style="padding:4px 0"><div class="lgr" style="font-size:10px;text-transform:uppercase;letter-spacing:.12em;color:var(--muted);font-weight:700"><span>Date</span><span>Joueur</span><span>Staff</span><span>Motif</span></div>${rows}</div>
    <div class="row mt"><button data-a="wpage" data-d="-1" ${S.warnPage <= 0 ? 'disabled' : ''}>Précédent</button><span class="muted sm-t">Page ${S.warnPage + 1}</span><button data-a="wpage" data-d="1" ${r.more ? '' : 'disabled'}>Suivant</button></div>`,
    'Sanctions', 'Avertissements donnés sur le serveur', refreshBtn);
}

/* ═══════════ Équipe ═══════════ */
async function viewTeam() {
  const R = [['chat', 'Chat staff'], ['perms', 'Droits du panel'], ['grades', 'Grades staff'], ['legacy', 'Droits ancien menu']];
  const seg = `<div class="seg">${R.filter(x => x[0] === 'chat' || can('perms')).map(([k, l]) => `<button class="${S.rtab === k ? 'active' : ''}" data-a="rtab" data-k="${k}">${l}</button>`).join('')}</div>`;
  let body = '';
  if (S.rtab === 'grades' && can('perms')) body = await gradesHtml();
  else if (S.rtab === 'legacy' && can('perms')) body = await legacyHtml();
  else if (S.rtab === 'perms' && can('perms')) {
    const r = await rpc('permsGet');
    if (!r.ok) return toast(r.error, 'err');
    S.permList = r.perms;
    let g = '';
    body = `<p class="hint" style="margin-bottom:12px">Rang minimum pour chaque action. Le rang <b>Développeur</b> peut toujours tout faire. Les valeurs enregistrées ici remplacent celles de <b>config.lua</b>.</p><div class="card" style="padding:4px 0">${r.perms.map(p => {
      const h = p.group !== g ? `<div class="grp-t" style="padding:12px 14px 0;margin:0">${esc(p.group)}</div>` : ''; g = p.group;
      return `${h}<div class="perm"><span>${esc(p.label)}</span><select data-perm="${p.key}" ${p.locked ? 'disabled' : ''}>${[1, 2, 3, 4].map(n => `<option value="${n}" ${p.value === n ? 'selected' : ''}>${RANKS[n]}</option>`).join('')}</select></div>`;
    }).join('')}</div><div class="row mt"><button class="primary" data-a="permsave">Enregistrer les droits</button><button class="danger" data-a="permreset">Revenir à config.lua</button></div>`;
  } else {
    S.rtab = 'chat';
    const r = await rpc('chatList');
    S.chat = r.ok ? r.messages : [];
    body = `<div class="chatbox" id="chatbox">${chatHtml()}</div><div class="row"><input id="chatin" placeholder="Écrire à l'équipe…" maxlength="220"><button class="primary" data-a="chatsend">Envoyer</button></div>`;
  }
  frame(seg + body, 'Équipe', 'Chat privé du staff et gestion des droits', '');
  const cb = $('#chatbox'); if (cb) cb.scrollTop = cb.scrollHeight;
}
const COLORS = [['~s~', 'Blanc'], ['~r~', 'Rouge'], ['~g~', 'Vert'], ['~b~', 'Bleu'], ['~y~', 'Jaune'], ['~p~', 'Violet'], ['~o~', 'Orange'], ['~c~', 'Gris'], ['~m~', 'Gris foncé']];
async function gradesHtml() {
  const r = await rpc('grades');
  if (!r.ok) return `<div class="warnbox">${esc(r.error)}</div>`;
  S.gradeList = r.grades;
  const rows = r.grades.map(g => `<div class="item"><div class="grow"><b>${esc(g.label)} ${g.custom ? chip('personnalisé', 'info') : ''} ${g.protected ? chip('protégé', 'mute') : ''}</b><small>${esc(g.name)}${g.rank ? ' · rang ' + g.rank : ''}</small></div>
    <select data-gcolor="${esc(g.name)}" style="width:130px">${COLORS.map(c => `<option value="${esc(c[0])}" ${g.color === c[0] ? 'selected' : ''}>${c[1]}</option>`).join('')}</select>
    ${g.protected ? '' : `<button class="sm danger" data-a="gdel" data-n="${esc(g.name)}">${ic('trash', 13)}</button>`}</div>`).join('');
  return `<div class="row" style="margin-bottom:12px"><button class="primary" data-a="gnew">${ic('plus', 16)} Créer un grade</button><span class="hint">Un grade personnalisé hérite des droits d'un rang (1 à 3) puis se règle séparément.</span></div>${rows}`;
}
async function legacyHtml() {
  const r = await rpc('permMatrix');
  if (!r.ok) return `<div class="warnbox">${esc(r.error)}</div>`;
  S.mx = r;
  const targets = [['1', 'Modérateur'], ['2', 'Admin'], ['3', 'Superadmin'], ...r.grades.filter(g => g.custom).map(g => [g.name, g.label])];
  if (!S.mxT || !targets.some(t => t[0] === S.mxT)) S.mxT = '1';
  const m = (r.matrix[S.mxT]) || {};
  const sec = [['section_self', 'Section : moi'], ['section_players', 'Section : joueurs'], ['section_reports', 'Section : reports'], ['section_vehicle', 'Section : véhicules'], ['setjob', 'Changer le métier'], ['setjob2', 'Changer le gang / orga'], ['take_screen', 'Capture d\'écran']];
  const cb = (k, l) => `<label class="chk perm"><input type="checkbox" data-mx="${esc(k)}" ${m[k] ? 'checked' : ''}> <span>${esc(l)}</span></label>`;
  return `<p class="hint" style="margin-bottom:12px">Droits de l'<b>ancien menu RageUI</b> (le panel moderne utilise l'onglet « Droits du panel »). Chaque case est enregistrée tout de suite.</p>
    <div class="row" style="margin-bottom:12px"><div style="width:260px"><select id="mxt">${targets.map(t => `<option value="${esc(t[0])}" ${t[0] === S.mxT ? 'selected' : ''}>${esc(t[1])}</option>`).join('')}</select></div></div>
    <div class="card"><div class="grp-t">Sections</div><div class="grid2" style="gap:6px">${sec.map(x => cb(x[0], x[1])).join('')}</div><div class="grp-t">Actions</div><div class="grid2" style="gap:6px">${r.funcs.map(f => cb('func_' + f.id, `${f.label} (${f.cat})`)).join('')}</div></div>`;
}
const chatHtml = () => S.chat.length ? S.chat.map(m => `<div class="msg"><b>${esc(m.name)}</b> ${chip(RANKS[m.rank] || 'Staff', 'mute')}<small>${fmtDate(m.t)}</small><br>${esc(m.text)}</div>`).join('') : '<div class="hint">Aucun message.</div>';

/* ═══════════ Journal ═══════════ */
const ACT_LABEL = { gotoPlayer: 'Téléportation sur un joueur', bringPlayer: 'Joueur amené', sendback: 'Joueur renvoyé', tpcoords: 'TP coordonnées', heal: 'Soin', revive: 'Réanimation', armor: 'Gilet', freeze: 'Gel', kill: 'Mort',
  message: 'Message', warn: 'Avertissement', spectate: 'Spectate', jail: 'Prison', unjail: 'Sortie de prison', kick: 'Expulsion', ban: 'Bannissement', giveMoney: 'Argent donné', takeMoney: 'Argent retiré',
  giveItem: 'Objet donné', takeItem: 'Objet retiré', giveWeapon: 'Arme donnée', clearInventory: 'Inventaire vidé', setJob: 'Métier changé', setJob2: 'Gang changé', resetIdentity: 'Identité réinitialisée',
  setGrade: 'Grade staff', notes: 'Note ajoutée', viewinv: 'Inventaire consulté', weather: 'Météo', time: 'Heure', announce: 'Annonce', cleanup: 'Nettoyage', reviveAll: 'Réanimation générale', healAll: 'Soin général',
  report_take: 'Report pris', report_close: 'Report fermé', report_reply: 'Réponse report', delete_warn: 'Avertissement supprimé', delete_note: 'Note supprimée', perms_save: 'Droits modifiés', perms_reset: 'Droits réinitialisés',
  bookmark_add: 'Favori ajouté', core_wipe: 'Wipe', core_screenshot: 'Capture d\'écran', veh_spawn: 'Véhicule apparu', veh_delete: 'Véhicule supprimé', veh_max: 'Véhicule custom', veh_plate: 'Plaque changée', veh_neon: 'Néons', self_heal: 'Auto-soin', self_revive: 'Auto-réanimation', self_armor: 'Auto-gilet', tp_coords: 'TP coordonnées (moi)', veh_give: 'Véhicule donné (garage)' };
const actLabel = a => ACT_LABEL[a] || a;
async function viewLogs() {
  const f = S.logF;
  const r = await rpc('logs', f.action, f.q, f.page);
  if (!r.ok) return toast(r.error, 'err');
  const rows = r.logs.length ? r.logs.map(l => `<div class="lgr"><span>${fmtDate(l.t)}</span><span class="nm">${esc(l.staff_name)}</span><span>${esc(actLabel(l.action))}${l.target_name ? ' → ' + esc(l.target_name) : ''}</span><span class="d" title="${esc(l.details)}">${esc(l.details || '')}</span></div>`).join('') : empty('list', 'Journal vide', 'Aucune action ne correspond.');
  frame(`<div class="row wrap" style="margin-bottom:14px"><div style="width:240px"><select id="lf-a"><option value="">Toutes les actions</option>${r.actions.map(a => `<option value="${esc(a)}" ${f.action === a ? 'selected' : ''}>${esc(actLabel(a))}</option>`).join('')}</select></div><div style="width:260px"><input id="lf-q" placeholder="Staff, joueur, détail (Entrée)" value="${esc(f.q)}"></div></div>
    <div class="card" style="padding:4px 0">${rows}</div><div class="row mt"><button data-a="lpage" data-d="-1" ${f.page <= 0 ? 'disabled' : ''}>Précédent</button><span class="muted sm-t">Page ${f.page + 1}</span><button data-a="lpage" data-d="1" ${r.more ? '' : 'disabled'}>Suivant</button></div>`,
    'Journal', 'Toutes les actions du staff (90 jours)', refreshBtn);
}

/* ═══════════ Outils ═══════════ */
async function viewTools() {
  const c = await rpc('coords');
  S.coords = c;
  const quick = (S.cfg.quickTp || []).map((q, i) => `<div class="item"><div class="grow"><b>${esc(q.label)}</b><small class="mono">${q.x}, ${q.y}, ${q.z}</small></div>${can('tp_coords') ? `<button class="sm" data-a="tpq" data-x="${q.x}" data-y="${q.y}" data-z="${q.z}">Y aller</button>` : ''}</div>`).join('');
  const fav = S.bookmarks.map((q, i) => `<div class="item"><div class="grow"><b>${esc(q.label)}</b><small class="mono">${q.x}, ${q.y}, ${q.z}</small></div>${can('tp_coords') ? `<button class="sm" data-a="tpq" data-x="${q.x}" data-y="${q.y}" data-z="${q.z}">Y aller</button>` : ''}${can('bookmarks') ? `<button class="sm danger" data-a="bmdel" data-i="${i + 1}">${ic('trash', 13)}</button>` : ''}</div>`).join('');
  frame(`<div class="grid2"><div><div class="card"><div class="card-h"><div class="t">Ma position</div></div><div class="kv"><span>Coordonnées</span><span class="mono" id="cx">${c.x}, ${c.y}, ${c.z}</span></div><div class="kv"><span>Orientation</span><span class="mono">${c.h}</span></div>
      <div class="row mt-s wrap"><button class="sm" data-a="copy" data-f="v3">Copier vector3</button><button class="sm" data-a="copy" data-f="v4">Copier vector4</button><button class="sm" data-a="copy" data-f="xyz">Copier x, y, z</button><button class="sm" data-a="copy" data-f="tbl">Copier {x, y, z}</button></div>
      ${can('bookmarks') ? '<div class="row mt-s"><button class="sm primary" data-a="bmadd">Ajouter ma position aux favoris</button></div>' : ''}</div>
      ${can('tp_coords') ? `<div class="card"><div class="card-h"><div class="t">Téléportation par coordonnées</div></div><div class="row"><input id="tx" placeholder="X"><input id="ty" placeholder="Y"><input id="tz" placeholder="Z"><button data-a="tpxyz">Aller</button></div></div>` : ''}
      ${can('devtools') ? `<div class="card"><div class="card-h"><div class="t">Outils développeur</div></div><div class="row wrap"><button class="sm" data-a="dev" data-k="interiorInfo">Info intérieur (affichage)</button><button class="sm" data-a="dev" data-k="pedMenu">Menu PNJ</button></div>
        ${[['cutscene', 'Cutscenes'], ['animation', 'Animations'], ['interior', 'Intérieurs']].map(([k, l]) => `<div class="grp-t">${l}</div><div class="row"><div style="width:260px"><input id="dq-${k}" data-dq="${k}" placeholder="Rechercher (Entrée)"></div></div><div id="dr-${k}" class="mt-s"></div>`).join('')}</div>` : ''}
      <div class="card"><div class="card-h"><div class="t">Builders</div></div><div class="row wrap">${[['builders', 'Panel builders'], ['jobbuilder', 'Job'], ['gangbuilder', 'Gang'], ['shopbuilder', 'Shop'], ['worldbuilder', 'World'], ['eventbuilder', 'Event'], ['minigames', 'Mini-jeux']].map(([k, l]) => `<button class="sm" data-a="openPanel" data-k="${k}">${l}</button>`).join('')}</div></div>
      <div class="card"><div class="card-h"><div class="t">Autres panels</div></div><div class="row wrap"><button data-a="openPanel" data-k="builders">Panel builders</button><button data-a="openPanel" data-k="anticheat">Anti-cheat</button>${can('legacy') ? '<button data-a="me" data-k="legacy">Ancien menu (wipe, cutscenes, permissions…)</button>' : ''}</div></div></div>
    <div><div class="card"><div class="card-h"><div class="t">Favoris</div></div>${fav || '<div class="hint">Aucun favori.</div>'}</div><div class="card"><div class="card-h"><div class="t">Lieux rapides</div></div>${quick}</div></div></div>`, 'Outils', 'Coordonnées, favoris et accès rapides', refreshBtn);
}

/* ═══════════ Navigation ═══════════ */
function stopTimer() { clearInterval(S.timer); S.timer = null; }
async function show(tab) {
  S.tab = tab; stopTimer();
  if (tab === 'dash') await viewDash();
  else if (tab === 'players') { S.selId ? await viewPlayer(S.selId) : await viewPlayers(); S.timer = setInterval(() => { if (S.tab === 'players' && !S.selId && !$('#pq:focus')) viewPlayers(true); }, 5000); }
  else if (tab === 'reports') { await viewReports(); S.timer = setInterval(() => { if (S.tab === 'reports') viewReports(); }, 6000); }
  else if (tab === 'vehicles') viewVehicles();
  else if (tab === 'world') viewWorld();
  else if (tab === 'sanctions') await viewSanctions();
  else if (tab === 'team') await viewTeam();
  else if (tab === 'logs') await viewLogs();
  else if (tab === 'tools') await viewTools();
}
const reload = () => show(S.tab);
const sendMe = async (k, args = {}) => { if (k !== 'legacy' && !needSvc()) return; const r = await rpc('me', k, args); toast(r.ok ? 'Fait' : r.error, r.ok ? 'ok' : 'err'); return r; };

async function act(a, el) {
  const d = el.dataset;
  if (a === 'theme') { S.theme = S.theme === 'neon' ? 'classic' : 'neon'; try { localStorage.setItem('pkstaff.theme', S.theme); } catch (e) {} shell(); return show(S.tab); }
  if (a === 'close') return rpc('close');
  if (a === 'tab') { S.selId = null; return show(d.k); }
  if (a === 'refresh') return reload();
  if (a === 'svc') { const r = await rpc('toggle', 'service', !S.state.service); if (r.state) S.state = r.state; if (!r.ok) toast(r.error, 'err'); else snd('announce'); return reload(); }
  if (a === 'tog') { if (!needSvc()) return; const r = await rpc('toggle', d.k, !S.state[d.k]); if (r.state) S.state = r.state; if (!r.ok) toast(r.error, 'err'); return side(); }
  if (a === 'filter') { S.filter = d.k; return viewPlayers(); }
  if (a === 'player') { S.tab = 'players'; return viewPlayer(+d.id); }
  if (a === 'players-back') { S.selId = null; return show('players'); }
  if (a === 'me') return sendMe(d.k);
  if (a === 'announce') { S.tab = 'world'; return show('world'); }
  if (a === 'act') { const def = ACTS.flatMap(g => g[1]).find(x => x.k === d.k); if (def && S.sel) return runAct(def, S.sel); return; }
  if (a === 'inv') { const r = await rpc('inventory', S.sel.id); $('#invbox').innerHTML = r.ok ? (r.items.length ? `<div class="inv">${r.items.map(i => `<div><span>${esc(i.label)}</span><b>${i.count}</b></div>`).join('')}</div>` : '<span class="hint">Inventaire vide.</span>') : `<span class="hint">${esc(r.error)}</span>`; return; }
  if (a === 'addNote') { const v = await ask('Note staff', S.sel.name, [{ name: 'text', label: 'Note (visible par le staff uniquement)', type: 'textarea', max: 500 }], 'Ajouter'); if (!v) return; const r = await rpc('act', 'notes', S.sel.id, v); toast(r.ok ? 'Note ajoutée' : r.error, r.ok ? 'ok' : 'err'); return viewPlayer(S.sel.id); }
  if (a === 'delEntry') { if (!(await confirmBox('Supprimer ?', 'Cette entrée sera définitivement supprimée.', 'Supprimer'))) return; const r = await rpc('deleteEntry', d.kind, +d.eid); toast(r.ok ? 'Supprimé' : r.error, r.ok ? 'ok' : 'err'); return viewPlayer(S.sel.id); }
  // reports
  if (a === 'rtake') { const r = await rpc('reportTake', +d.id); toast(r.ok ? r.msg : r.error, r.ok ? 'ok' : 'err'); return viewReports(); }
  if (a === 'rclose') { if (!(await confirmBox('Fermer le report ?', 'Le joueur pourra en refaire un après le délai.', 'Fermer', false))) return; const r = await rpc('reportClose', +d.id); toast(r.ok ? r.msg : r.error, r.ok ? 'ok' : 'err'); return viewReports(); }
  if (a === 'rreply') { const v = await ask('Répondre au report', '', [{ name: 'text', label: 'Réponse', type: 'textarea', max: 200 }], 'Envoyer', false); if (!v) return; const r = await rpc('reportReply', +d.id, v.text); toast(r.ok ? r.msg : r.error, r.ok ? 'ok' : 'err'); return; }
  if (a === 'rgoto' || a === 'rbring') { if (!needSvc()) return; const r = await rpc('act', a === 'rgoto' ? 'gotoPlayer' : 'bringPlayer', +d.id, {}); toast(r.ok ? r.msg : r.error, r.ok ? 'ok' : 'err'); return; }
  // véhicules
  if (a === 'vfav') { $('#vmodel').value = d.m; return; }
  if (a === 'vspawn') { const m = $('#vmodel').value.trim(); if (!m) return toast('Indique un modèle', 'err'); return sendMe('veh_spawn', { model: m }); }
  if (a === 'vgive') { const m = $('#vgive').value.trim(); if (!m) return toast('Indique un modèle', 'err'); return sendMe('veh_give', { model: m }); }
  if (a === 'vplate') return sendMe('veh_plate', { plate: $('#vplate').value });
  if (a === 'vneon') { const h = $('#vneon').value; return sendMe('veh_neon', { r: parseInt(h.slice(1, 3), 16), g: parseInt(h.slice(3, 5), 16), b: parseInt(h.slice(5, 7), 16) }); }
  if (a === 'vneonoff') return sendMe('veh_neon', { off: true });
  // monde
  if (a === 'weather') { const r = await rpc('weather', d.k); toast(r.ok ? r.msg : r.error, r.ok ? 'ok' : 'err'); return; }
  if (a === 'time') { const r = await rpc('time', +d.h, +d.m); toast(r.ok ? r.msg : r.error, r.ok ? 'ok' : 'err'); return; }
  if (a === 'timeset') { const r = await rpc('time', +$('#th').value, +($('#tm').value || 0)); toast(r.ok ? r.msg : r.error, r.ok ? 'ok' : 'err'); return; }
  if (a === 'annsend') { const t = $('#ann').value.trim(); if (!t) return; if (!(await confirmBox('Envoyer l\'annonce ?', t, 'Envoyer', false))) return; const r = await rpc('announce', t); toast(r.ok ? r.msg : r.error, r.ok ? 'ok' : 'err'); if (r.ok) $('#ann').value = ''; return; }
  if (a === 'clean') { if (!needSvc()) return; if (!(await confirmBox('Nettoyer la zone ?', `Supprime ${d.k === 'vehicles' ? 'les véhicules vides' : 'les PNJ'} dans un rayon de ${$('#crad').value} m.`, 'Nettoyer'))) return; const r = await rpc('cleanup', d.k, +$('#crad').value); toast(r.ok ? r.msg : r.error, r.ok ? 'ok' : 'err'); return; }
  if (a === 'all') { if (!(await confirmBox(d.k === 'reviveAll' ? 'Réanimer tout le monde ?' : 'Soigner tout le monde ?', 'Tous les joueurs connectés seront concernés.', 'Confirmer'))) return; const r = await rpc(d.k); toast(r.ok ? r.msg : r.error, r.ok ? 'ok' : 'err'); return; }
  // sanctions / journal
  if (a === 'wpage') { S.warnPage = Math.max(0, S.warnPage + +d.d); return viewSanctions(); }
  if (a === 'lpage') { S.logF.page = Math.max(0, S.logF.page + +d.d); return viewLogs(); }
  if (a === 'openPanel') return rpc('openPanel', d.k);
  // équipe
  if (a === 'rtab') { S.rtab = d.k; return viewTeam(); }
  if (a === 'chatsend') { const i = $('#chatin'); const t = i.value.trim(); if (!t) return; const r = await rpc('chatSend', t); if (!r.ok) return toast(r.error, 'err'); S.chat.push(r.message); i.value = ''; $('#chatbox').innerHTML = chatHtml(); $('#chatbox').scrollTop = 1e6; return; }
  if (a === 'gnew') {
    const v = await ask('Nouveau grade staff', 'Nom interne en minuscules, sans espace.', [{ name: 'n', label: 'Nom interne', type: 'text', max: 24, placeholder: 'helper' }, { name: 'l', label: 'Nom affiché', type: 'text', max: 32, placeholder: 'Helper' }, { name: 'r', label: 'Droits hérités de', type: 'select', options: [{ value: 1, label: 'Modérateur' }, { value: 2, label: 'Admin' }, { value: 3, label: 'Superadmin' }] }], 'Créer', false);
    if (!v) return;
    await rpc('gradeOp', 'create', v.n, v.l, +v.r); setTimeout(viewTeam, 700); return;
  }
  if (a === 'gdel') { if (!(await confirmBox('Supprimer ce grade ?', `Les joueurs ayant « ${d.n} » repassent joueur.`, 'Supprimer'))) return; await rpc('gradeOp', 'delete', d.n); setTimeout(viewTeam, 700); return; }
  if (a === 'permsave') { const m = {}; $$('[data-perm]').forEach(s => { m[s.dataset.perm] = +s.value; }); const r = await rpc('permsSave', m); toast(r.ok ? 'Droits enregistrés' : r.error, r.ok ? 'ok' : 'err'); return; }
  if (a === 'permreset') { if (!(await confirmBox('Revenir à config.lua ?', 'Les droits modifiés en jeu seront effacés.', 'Réinitialiser'))) return; const r = await rpc('permsReset'); toast(r.ok ? 'Droits réinitialisés' : r.error, r.ok ? 'ok' : 'err'); return viewTeam(); }
  // outils
  if (a === 'copy') { const c = await rpc('coords'); const f = { v3: `vector3(${c.x}, ${c.y}, ${c.z})`, v4: `vector4(${c.x}, ${c.y}, ${c.z}, ${c.h})`, xyz: `${c.x}, ${c.y}, ${c.z}`, tbl: `{x = ${c.x}, y = ${c.y}, z = ${c.z}}` }[d.f]; copyText(f); return toast('Copié : ' + f, 'ok'); }
  if (a === 'bmadd') { const v = await ask('Nouveau favori', 'Ta position actuelle sera enregistrée.', [{ name: 'label', label: 'Nom', type: 'text', max: 40 }], 'Ajouter', false); if (!v) return; const c = await rpc('coords'); const r = await rpc('bookmarkSave', v.label, c.x, c.y, c.z); if (!r.ok) return toast(r.error, 'err'); S.bookmarks = r.bookmarks; return viewTools(); }
  if (a === 'bmdel') { const r = await rpc('bookmarkDelete', +d.i); if (!r.ok) return toast(r.error, 'err'); S.bookmarks = r.bookmarks; return viewTools(); }
  if (a === 'dev') { const r = await rpc('devRun', d.k); if (!r.ok) toast(r.error || 'Impossible', 'err'); else if (d.k === 'interiorInfo') toast('Affichage basculé', 'ok'); return; }
  if (a === 'devrun') { const r = await rpc('devRun', d.kind, +d.i); if (!r.ok) toast(r.error || 'Impossible', 'err'); return; }
  if (a === 'tpq') return sendMe('tp_coords', { x: +d.x, y: +d.y, z: +d.z });
  if (a === 'tpxyz') return sendMe('tp_coords', { x: +$('#tx').value, y: +$('#ty').value, z: +$('#tz').value });
}
async function devSearch(kind, q) {
  const r = await rpc('devSearch', kind, q);
  const box = $('#dr-' + kind);
  if (!box) return;
  box.innerHTML = r.list && r.list.length ? r.list.map(x => `<div class="item"><div class="grow"><b>${esc(x.label)}</b>${x.sub ? `<small>${esc(x.sub)}</small>` : ''}</div><button class="sm" data-a="devrun" data-kind="${kind}" data-i="${x.index}">Lancer</button></div>`).join('') + `<div class="hint">${r.list.length} résultat(s) affiché(s) sur ${r.total}</div>` : '<div class="hint">Aucun résultat.</div>';
}
function copyText(t) {
  try { const ta = document.createElement('textarea'); ta.value = t; ta.style.position = 'fixed'; ta.style.opacity = '0'; document.body.appendChild(ta); ta.select(); document.execCommand('copy'); ta.remove(); } catch (e) {}
}

document.addEventListener('click', e => { const el = e.target.closest('[data-a]'); if (!el || el.disabled) return; snd('tick'); act(el.dataset.a, el); });
document.addEventListener('input', e => { if (e.target.id === 'pq') { S.q = e.target.value; const l = $('#plist'); if (l) l.innerHTML = listHtml(); } });
document.addEventListener('change', e => {
  if (e.target.id === 'lf-a') { S.logF.action = e.target.value; S.logF.page = 0; viewLogs(); }
  if (e.target.dataset && e.target.dataset.gcolor) { rpc('gradeOp', 'color', e.target.dataset.gcolor, e.target.value); toast('Couleur enregistrée', 'ok'); }
  if (e.target.id === 'mxt') { S.mxT = e.target.value; viewTeam(); }
  if (e.target.dataset && e.target.dataset.mx) { const key = S.mxT; const k = e.target.dataset.mx; const num = ['1', '2', '3'].includes(key) ? +key : key; rpc('gradeOp', 'perm', num, k, e.target.checked); (S.mx.matrix[key] = S.mx.matrix[key] || {})[k] = e.target.checked; }
});
document.addEventListener('keydown', e => {
  if (e.key === 'Enter' && e.target.id === 'lf-q') { S.logF.q = e.target.value; S.logF.page = 0; viewLogs(); }
  if (e.key === 'Enter' && e.target.dataset && e.target.dataset.dq) devSearch(e.target.dataset.dq, e.target.value);
  if (e.key === 'Enter' && e.target.id === 'chatin') act('chatsend', e.target);
  if (e.key === 'Escape') { const c = document.getElementById('confirm'); if (!c.classList.contains('hidden')) { $('#c-no', c) && $('#c-no', c).click(); return; } rpc('close'); }
});

window.addEventListener('message', ev => {
  const m = ev.data || {};
  if (m.action === 'open') {
    let saved = null; try { saved = localStorage.getItem('pkstaff.theme'); } catch (e) {}
    S.theme = saved === 'classic' || saved === 'neon' ? saved : (m.data.theme === 'classic' ? 'classic' : 'neon');
    S.d = m.data; S.perms = m.data.perms || {}; S.cfg = m.data.cfg || {}; S.bookmarks = m.data.bookmarks || []; S.state = m.state || {}; S.selId = null; S.tab = 'dash'; S.items = null; S.jobs = null;
    shell(); show('dash');
  }
  if (m.action === 'close') { stopTimer(); clearInterval(S.clock); clearInterval(S.nTimer); $root.classList.add('hidden'); $root.innerHTML = ''; document.getElementById('confirm').classList.add('hidden'); }
  if (m.action === 'chat') { S.chat.push(m.message); const cb = $('#chatbox'); if (cb && S.tab === 'team') { cb.innerHTML = chatHtml(); cb.scrollTop = cb.scrollHeight; } else toast(`[Staff] ${m.message.name} : ${m.message.text}`); }
});
