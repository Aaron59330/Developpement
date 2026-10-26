'use strict';
const $root = document.getElementById('root');
const $ = (s, r = document) => r.querySelector(s);
const $$ = (s, r = document) => Array.from(r.querySelectorAll(s));
const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const resName = () => (typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'pickax_anticheat');
const clone = o => JSON.parse(JSON.stringify(o));
const snd = n => { try { window.BBUI && BBUI.play({ tick: 'click', announce: 'success', hover: 'hover' }[n] || n); } catch (e) {} };

async function rpc(name, ...args) {
  const ctl = new AbortController();
  const timer = setTimeout(() => ctl.abort(), 10000);
  try {
    const r = await fetch(`https://${resName()}/rpc`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ name, args: args.map(a => (a === undefined || a === null ? 0 : a)) }), signal: ctl.signal });
    return await r.json();
  } catch (e) {
    return { ok: false, error: ctl.signal.aborted ? `Le serveur ne répond pas à « ${name} » : restart ${resName()}` : 'Erreur de communication' };
  } finally { clearTimeout(timer); }
}
function toast(msg, type = '') {
  const el = document.createElement('div');
  el.className = 'toast ' + type;
  el.textContent = msg;
  document.getElementById('toasts').appendChild(el);
  setTimeout(() => el.remove(), 4200);
}
function ask(title, text, fields = [], okLabel = 'Confirmer', danger = true) {
  return new Promise(resolve => {
    const c = document.getElementById('confirm');
    const f = fields.map((x, i) => x.type === 'select'
      ? `<label class="f mt-s"><span>${esc(x.label)}</span><select id="ask-${i}">${x.options.map(o => `<option value="${esc(o)}" ${o === x.value ? 'selected' : ''}>${esc(o)}</option>`).join('')}</select></label>`
      : `<label class="f mt-s"><span>${esc(x.label)}</span><input id="ask-${i}" value="${esc(x.value || '')}" placeholder="${esc(x.placeholder || '')}" maxlength="${x.max || 200}"></label>`).join('');
    c.innerHTML = `<div class="box"><h2>${esc(title)}</h2><p>${esc(text)}</p>${f}<div class="row mt"><span class="spacer"></span><button id="c-no">Annuler</button><button class="${danger ? 'danger' : 'primary'}" id="c-yes">${esc(okLabel)}</button></div></div>`;
    c.classList.remove('hidden');
    const done = v => { c.classList.add('hidden'); c.innerHTML = ''; resolve(v); };
    $('#c-no', c).onclick = () => done(null);
    $('#c-yes', c).onclick = () => done(fields.map((_, i) => $('#ask-' + i, c).value));
    const first = $('#ask-0', c); if (first) first.focus();
  });
}
const confirmBox = (t, x, ok, danger) => ask(t, x, [], ok, danger).then(v => v !== null);

const P = {
  shield: '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10Z"/>', x: '<path d="M18 6 6 18"/><path d="m6 6 12 12"/>',
  users: '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.9"/><path d="M16 3.1a4 4 0 0 1 0 7.8"/>',
  list: '<path d="M8 6h13"/><path d="M8 12h13"/><path d="M8 18h13"/><path d="M3 6h.01"/><path d="M3 12h.01"/><path d="M3 18h.01"/>',
  ban: '<circle cx="12" cy="12" r="10"/><path d="m4.9 4.9 14.2 14.2"/>', sliders: '<path d="M4 21v-7M4 10V3M12 21v-9M12 8V3M20 21v-5M20 12V3M1 14h6M9 8h6M17 16h6"/>',
  chart: '<path d="M3 3v18h18"/><path d="M18 17V9"/><path d="M13 17V5"/><path d="M8 17v-3"/>', refresh: '<path d="M21 12a9 9 0 1 1-3-6.7L21 8"/><path d="M21 3v5h-5"/>',
  search: '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>', plus: '<path d="M5 12h14"/><path d="M12 5v14"/>', check: '<path d="M20 6 9 17l-5-5"/>',
  trash: '<path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/>', back: '<path d="m15 18-6-6 6-6"/>',
  grid: '<rect width="7" height="7" x="3" y="3" rx="1"/><rect width="7" height="7" x="14" y="3" rx="1"/><rect width="7" height="7" x="14" y="14" rx="1"/><rect width="7" height="7" x="3" y="14" rx="1"/>',
};
const ic = (n, s) => `<svg class="ic" viewBox="0 0 24 24" ${s ? `style="width:${s}px;height:${s}px"` : ''}>${P[n] || P.grid}</svg>`;
const tile = (icon, cls = '') => `<div class="tile ${cls}">${ic(icon)}</div>`;
const chip = (text, cls = '') => `<span class="chip ${cls}">${esc(text)}</span>`;
const closeBtn = `<button class="icon" data-a="close" title="Fermer">${ic('x', 16)}</button>`;
const empty = (icon, title, text) => `<div class="empty">${tile(icon)}<h2>${esc(title)}</h2><p>${esc(text)}</p></div>`;
const getPath = (o, p) => p.split('.').reduce((a, k) => (a == null ? a : a[k]), o);
function setPath(o, p, v) { const k = p.split('.'); for (let i = 0; i < k.length - 1; i++) { if (o[k[i]] == null || typeof o[k[i]] !== 'object') o[k[i]] = {}; o = o[k[i]]; } o[k[k.length - 1]] = v; }
const fmtDate = t => { if (!t) return '—'; const d = new Date(t * 1000); const p = n => String(n).padStart(2, '0'); return `${p(d.getDate())}/${p(d.getMonth() + 1)} ${p(d.getHours())}:${p(d.getMinutes())}`; };
const fmtDur = s => { s = Math.max(0, Math.floor(s)); const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60); return d ? `${d} j ${h} h` : h ? `${h} h ${m} min` : `${Math.max(1, m)} min`; };

const MODNAME = { admin: 'Staff', ban: 'Bannissement', kick: 'Expulsion' };
const S = { tab: 'dash', canBan: false, info: {}, ov: null, players: [], q: '', sel: null, selId: null, bans: null, banQ: '', banPage: 0, logs: null, logF: { module: '', q: '', actions: false, hideFp: false, page: 0 },
  cfg: null, defaults: null, knownWeapons: [], rtab: 'modules', dirty: false, timer: null };
const modLabel = m => (S.info[m] && S.info[m][0]) || MODNAME[m] || m;

const TABS = [['dash', 'Tableau de bord', 'chart'], ['players', 'Joueurs', 'users'], ['logs', 'Détections', 'list'], ['bans', 'Bannissements', 'ban'], ['rules', 'Règles', 'sliders']];

function frame(inner, title, sub, acts = '') {
  const nav = TABS.map(([k, l, i]) => `<div class="nav-item ${S.tab === k ? 'active' : ''}" data-a="tab" data-k="${k}">${ic(i)}<span class="grow">${l}</span>${k === 'rules' && S.dirty ? '<span class="badge">modifié</span>' : ''}</div>`).join('');
  const mode = S.cfg ? S.cfg.mode : (S.ov && S.ov.mode);
  $root.innerHTML = `<div class="shell"><div class="side"><div class="profile pl"><img class="plogo" data-pk-logo src="${window.PICKAX_LOGO || 'https://cfx-nui-pickax_theme/logo/logo.png'}" alt="" onerror="this.style.visibility='hidden'"><div class="avatar">${ic('shield', 20)}</div><div><b>Anti-cheat</b><small>Pickax · panel staff</small></div></div>
    <div class="nav"><div class="nav-label">Gestion</div>${nav}</div>
    <div class="side-foot"><span class="mode-pill ${mode === 'observe' ? 'observe' : 'protect'}">${mode === 'observe' ? 'Mode observation' : 'Mode protection'}</span>
    <small>${mode === 'observe' ? 'Les sanctions sont seulement simulées dans les journaux.' : 'Les sanctions sont appliquées automatiquement.'}</small></div></div>
    <div class="main"><div class="head">${tile(TABS.find(t => t[0] === S.tab)[2], 'lg')}<div class="ttl"><h1>${esc(title)}</h1><p>${esc(sub)}</p></div><div class="acts">${acts}${closeBtn}</div></div>
    <div class="body" id="body">${inner}</div></div></div>`;
  $root.classList.remove('hidden');
}

/* ═══════════ Tableau de bord ═══════════ */
async function viewDash() {
  const r = await rpc('overview');
  if (!r.ok) return toast(r.error || 'Erreur', 'err');
  S.ov = r;
  const mods = r.modules.length ? r.modules.map(m => `<div class="kv"><span>${esc(modLabel(m.module))}</span><b>${m.n}</b></div>`).join('') : '<div class="hint">Aucune détection sur 24 h.</div>';
  const top = r.top.length ? r.top.map(t => `<div class="kv"><span>${esc(t.name)}</span><b>${t.n}</b></div>`).join('') : '<div class="hint">Personne de suspect.</div>';
  const rec = r.recent.length ? r.recent.map(l => `<div class="logline"><b>${esc(l.name || '—')}</b> · ${esc(modLabel(l.module))} · ${esc(l.action)} <span class="muted">(${fmtDate(l.t)})</span></div>`).join('') : '<div class="hint">Journal vide.</div>';
  frame(`<div class="grid4"><div class="stat"><div class="eyebrow">En ligne</div><div class="v">${r.online}</div><div class="s">joueurs connectés</div></div>
    <div class="stat"><div class="eyebrow">Expulsions 24 h</div><div class="v">${r.kicks}</div><div class="s">par l'anti-cheat</div></div>
    <div class="stat"><div class="eyebrow">Bannissements 24 h</div><div class="v">${r.bans}</div><div class="s">par l'anti-cheat</div></div>
    <div class="stat"><div class="eyebrow">Bans actifs</div><div class="v">${r.activeBans}</div><div class="s">${r.sims ? r.sims + ' sanctions simulées / 24 h' : 'liste de bannissement'}</div></div></div>
    <div class="grid3"><div class="card"><div class="card-h"><div class="t">Détections par module (24 h)</div></div>${mods}</div>
    <div class="card"><div class="card-h"><div class="t">Joueurs les plus signalés (24 h)</div></div>${top}</div>
    <div class="card"><div class="card-h"><div class="t">Derniers événements</div></div>${rec}</div></div>`,
    'Tableau de bord', 'Vue d\'ensemble des dernières 24 heures', `<button class="icon" data-a="refresh" title="Actualiser">${ic('refresh', 16)}</button>`);
}

/* ═══════════ Joueurs ═══════════ */
function scoreBar(v) { const p = Math.min(100, v * 10); return `<div class="bar ${v >= 6 ? 'hi' : v >= 3 ? 'mid' : ''}"><i style="width:${p}%"></i></div>`; }
function playersHtml() {
  const q = S.q.toLowerCase();
  const list = S.players.filter(p => !q || String(p.id) === q || p.name.toLowerCase().includes(q) || p.license.toLowerCase().includes(q));
  if (!list.length) return empty('users', 'Aucun joueur', 'Aucun joueur ne correspond.');
  return `<div class="pl head-row"><span>ID</span><span>Nom</span><span>Groupe</span><span>Métier</span><span>Ping</span><span>Suspicion</span><span></span></div>` + list.map(p => `<div class="pl" data-a="player" data-id="${p.id}">
    <span class="mono">${p.id}</span><span class="nm">${esc(p.name)}</span><span>${esc(p.group)}</span><span><small>${esc(p.job || '—')}</small></span><span>${p.ping}</span>
    <span class="row">${scoreBar(p.score)}<small>${p.score}</small></span><span>${p.hb > 90 ? chip('silencieux', 'warn') : ''}</span></div>`).join('');
}
async function viewPlayers(keep) {
  const r = await rpc('players');
  if (!r.ok) return toast(r.error || 'Erreur', 'err');
  S.players = r.players;
  if (keep && $('#plist')) { $('#plist').innerHTML = playersHtml(); return; }
  frame(`<div class="row mt-s" style="margin-bottom:14px"><div style="width:340px;position:relative"><input id="pq" placeholder="Rechercher (nom, ID, licence)" value="${esc(S.q)}"></div><span class="hint">${r.players.length} joueur(s) · se met à jour toutes les 5 s</span></div><div id="plist">${playersHtml()}</div>`,
    'Joueurs', 'Joueurs connectés, triés par suspicion', `<button class="icon" data-a="refresh" title="Actualiser">${ic('refresh', 16)}</button>`);
}
async function viewPlayer(id) {
  S.selId = id;
  const r = await rpc('player', id);
  if (!r.ok) { toast(r.error || 'Erreur', 'err'); S.selId = null; return viewPlayers(); }
  S.sel = r;
  const ids = Object.entries(r.identifiers || {}).map(([k, v]) => `<div class="kv"><span>${esc(k)}</span><span class="mono">${esc(v)}</span></div>`).join('');
  const sc = Object.entries(r.scores).filter(([, v]) => v > 0.4).map(([k, v]) => chip(`${modLabel(k)} ${v}`, v >= 6 ? 'bad' : 'warn')).join(' ') || '<span class="hint">Aucun score en cours.</span>';
  const logs = r.logs.length ? r.logs.map(l => `<div class="logline ${l.fp ? 'muted' : ''}"><b>${esc(modLabel(l.module))}</b> · ${esc(l.action)} <span class="muted">${fmtDate(l.t)}</span><br>${esc(l.details)}</div>`).join('') : '<div class="hint">Aucune détection enregistrée.</div>';
  const bans = r.bans.length ? r.bans.map(b => `<div class="logline"><b>${esc(b.reason)}</b> · par ${esc(b.sourceName)} · ${fmtDate(b.timeat)} ${b.permanent == 1 ? '(permanent)' : ''}</div>`).join('') : '<div class="hint">Aucun ban antérieur.</div>';
  const ban = S.canBan;
  frame(`<div class="split"><div><div class="card"><div class="card-h"><div class="t">Détections récentes</div></div>${logs}</div><div class="card"><div class="card-h"><div class="t">Historique de bans</div></div>${bans}</div></div>
    <div><div class="card"><div class="card-h"><div class="t">Actions</div></div><div class="row wrap">
      <button data-a="warn">Avertir</button><button data-a="kick">Expulser</button>${ban ? '<button class="danger" data-a="ban">Bannir</button>' : ''}${ban ? `<button data-a="exemptSel">${r.exempted ? 'Retirer l\'exemption' : 'Exempter'}</button>` : ''}</div>
      ${ban ? '' : '<p class="hint mt-s">Le bannissement est réservé aux groupes autorisés.</p>'}</div>
    <div class="card"><div class="card-h"><div class="t">Suspicion</div></div><div class="sc">${sc}</div></div>
    <div class="card"><div class="card-h"><div class="t">Identifiants</div></div><div class="kv"><span>Groupe</span><b>${esc(r.group)}</b></div><div class="kv"><span>Ping</span><b>${r.ping} ms</b></div>${ids}</div></div></div>`,
    `${r.name} (#${r.id})`, r.license || '', `<button data-a="players-back">${ic('back', 16)} Retour</button>`);
}

/* ═══════════ Détections (journal) ═══════════ */
async function viewLogs() {
  const f = S.logF;
  const r = await rpc('logs', f.module, f.q, f.actions, f.hideFp, f.page);
  if (!r.ok) return toast(r.error || 'Erreur', 'err');
  const mods = Object.keys(S.info).map(m => `<option value="${m}" ${f.module === m ? 'selected' : ''}>${esc(modLabel(m))}</option>`).join('');
  const rows = r.logs.length ? r.logs.map(l => `<div class="lg-row ${l.fp ? 'fp' : ''}"><span>${fmtDate(l.t)}</span><span class="nm">${esc(l.name || '—')}</span><span>${esc(modLabel(l.module))}</span><span>${esc(l.action)}</span><span class="det" title="${esc(l.details)}">${esc(l.details)}</span>
    <span>${l.module !== 'admin' ? `<button class="sm" data-a="fp" data-id="${l.id}" data-v="${l.fp ? 0 : 1}">${l.fp ? 'Retirer faux positif' : 'Faux positif'}</button>` : ''}</span></div>`).join('') : empty('list', 'Aucune détection', 'Rien ne correspond à ces filtres.');
  frame(`<div class="row wrap" style="margin-bottom:14px"><div style="width:220px"><select id="lf-m"><option value="">Tous les modules</option>${mods}</select></div><div style="width:260px"><input id="lf-q" placeholder="Nom ou licence" value="${esc(f.q)}"></div>
    <label class="chk"><input type="checkbox" id="lf-a" ${f.actions ? 'checked' : ''}> Sanctions uniquement</label><label class="chk"><input type="checkbox" id="lf-f" ${f.hideFp ? 'checked' : ''}> Masquer les faux positifs</label></div>
    <div class="card" style="padding:4px 0">${rows}</div>
    <div class="row mt"><button data-a="lpage" data-d="-1" ${f.page <= 0 ? 'disabled' : ''}>Précédent</button><span class="muted sm-t">Page ${f.page + 1}</span><button data-a="lpage" data-d="1" ${r.more ? '' : 'disabled'}>Suivant</button></div>`,
    'Détections', 'Journal de toutes les alertes et sanctions (60 jours)', `<button class="icon" data-a="refresh" title="Actualiser">${ic('refresh', 16)}</button>`);
}

/* ═══════════ Bannissements ═══════════ */
async function viewBans() {
  const r = await rpc('bans', S.banQ, S.banPage);
  if (!r.ok) return toast(r.error || 'Erreur', 'err');
  const rows = r.bans.length ? r.bans.map(b => `<div class="item"><div class="grow"><b>${esc(b.targetName)} ${b.active ? chip('actif', 'bad') : chip('expiré', 'mute')}</b><small>${esc(b.reason)} · par ${esc(b.sourceName)} · ${fmtDate(b.timeat)} · ${b.permanent == 1 ? 'permanent' : 'jusqu\'au ' + fmtDate(b.expiration)} · ID ${esc(b.banid)}</small><small class="mono">${esc(b.licenseid)}</small></div>
    ${S.canBan ? `<button class="sm danger" data-a="unban" data-id="${esc(b.banid)}" data-n="${esc(b.targetName)}">Débannir</button>` : ''}</div>`).join('') : empty('ban', 'Aucun bannissement', 'La liste est vide.');
  frame(`<div class="row wrap" style="margin-bottom:14px"><div style="width:340px"><input id="bq" placeholder="Rechercher (nom, licence, ID de ban, raison)" value="${esc(S.banQ)}"></div>${S.canBan ? '<button class="primary" data-a="banoff">Bannir hors ligne</button>' : ''}</div>${rows}
    <div class="row mt"><button data-a="bpage" data-d="-1" ${S.banPage <= 0 ? 'disabled' : ''}>Précédent</button><span class="muted sm-t">Page ${S.banPage + 1}</span><button data-a="bpage" data-d="1" ${r.more ? '' : 'disabled'}>Suivant</button></div>`,
    'Bannissements', 'Même liste que le système de bannissement du serveur', `<button class="icon" data-a="refresh" title="Actualiser">${ic('refresh', 16)}</button>`);
}

/* ═══════════ Règles ═══════════ */
const RTABS = [['modules', 'Modules'], ['weapons', 'Armes'], ['models', 'Modèles'], ['events', 'Événements'], ['exempt', 'Exemptions'], ['general', 'Général']];
const lines = v => (v || []).join('\n');
function numIn(path, label, step = 1) { const v = getPath(S.cfg, path); return `<label class="f"><span>${label}</span><input type="number" step="${step}" data-path="${path}" data-t="num" value="${esc(v)}"></label>`; }
function listBox(path, title, hint) { return `<div class="card"><div class="card-h"><div class="t">${title}</div></div><textarea data-path="${path}" data-t="lines" spellcheck="false">${esc(lines(getPath(S.cfg, path)))}</textarea><p class="hint mt-s">${hint}</p></div>`; }
const EXTRA = { movement: [['maxSpeed', 'Vitesse max (m/s)'], ['samples', 'Mesures']], teleport: [['distance', 'Distance à pied (m)'], ['vehicleDistance', 'Distance véhicule (m)']], health: [['maxHealth', 'Santé max'], ['maxArmor', 'Armure max']],
  entities: [['vehicles', 'Véhicules'], ['peds', 'PNJ'], ['objects', 'Objets'], ['window', 'Fenêtre (s)']], explosions: [['max', 'Max'], ['window', 'Fenêtre (s)']], heartbeat: [['timeout', 'Silence max (s)']] };
function rulesBody() {
  const c = S.cfg, t = S.rtab;
  if (t === 'modules') {
    const rows = Object.keys(c.modules).map(k => {
      const m = c.modules[k], inf = S.info[k] || [k, ''];
      const ex = (EXTRA[k] || []).map(([f, l]) => numIn(`modules.${k}.${f}`, l)).join('') + (k === 'explosions' ? `<label class="chk" style="align-self:end"><input type="checkbox" data-path="modules.${k}.blockInvisible" data-t="bool" ${m.blockInvisible ? 'checked' : ''}> Bloquer les invisibles</label>` : '');
      return `<div class="mod ${m.enabled ? '' : 'off'}"><input type="checkbox" data-path="modules.${k}.enabled" data-t="bool" ${m.enabled ? 'checked' : ''}><div><b>${esc(inf[0])}</b><small>${esc(inf[1])}</small></div>
        <label class="f"><span>Poids</span><input type="number" step="0.5" data-path="modules.${k}.weight" data-t="num" value="${m.weight}"></label>
        <label class="f"><span>Expulsion</span><input type="number" data-path="modules.${k}.kick" data-t="num" value="${m.kick}"></label>
        <label class="f"><span>Ban</span><input type="number" data-path="modules.${k}.ban" data-t="num" value="${m.ban}"></label>${ex ? `<div class="mod-extra">${ex}</div>` : ''}</div>`;
    }).join('');
    return `<p class="hint" style="margin-bottom:12px"><b>Poids</b> = points ajoutés à chaque détection. Le score diminue avec le temps. <b>Expulsion / Ban</b> = score à atteindre (0 = jamais).</p><div class="card" style="padding:4px 0">${rows}</div>`;
  }
  if (t === 'weapons') {
    const jobs = Object.entries(c.weapons.jobs || {}).map(([j, l]) => `${j}: ${l.join(', ')}`).join('\n');
    const opts = S.knownWeapons.map(w => `<option>${w}</option>`).join('');
    return `<div class="grid2">${listBox('weapons.whitelist', 'Liste blanche (jamais sanctionnées)', 'Une arme par ligne, ex : <b>WEAPON_BAT</b>. Autorisée même hors inventaire.')}${listBox('weapons.blacklist', 'Liste noire (armes interdites)', 'Une arme par ligne. Tenue ou utilisée = sanction du module « Armes interdites ».')}</div>
      <div class="card"><div class="card-h"><div class="t">Armes autorisées par métier</div></div><textarea data-path="weapons.jobs" data-t="jobs" spellcheck="false">${esc(jobs)}</textarea><p class="hint mt-s">Une ligne par métier : <b>police: WEAPON_STUNGUN, WEAPON_NIGHTSTICK</b></p></div>
      <div class="card"><label class="chk"><input type="checkbox" data-path="weapons.checkInventory" data-t="bool" ${c.weapons.checkInventory ? 'checked' : ''}> Vérifier que l'arme en main vient de l'inventaire</label>
      <div class="row mt-s"><div style="width:280px"><select id="wk"><option value="">Ajouter une arme connue…</option>${opts}</select></div><button class="sm" data-a="wk-wl">Liste blanche</button><button class="sm" data-a="wk-bl">Liste noire</button></div></div>`;
  }
  if (t === 'models') return `<div class="grid3">${listBox('models.vehicles', 'Véhicules interdits', 'Nom de modèle par ligne, ex : <b>rhino</b>')}${listBox('models.peds', 'PNJ interdits', 'ex : <b>s_m_y_swat_01</b>')}${listBox('models.objects', 'Objets interdits', 'ex : <b>prop_gascyl_ignite</b>')}</div>`;
  if (t === 'events') {
    const lim = (c.events.limits || []).map((l, i) => `<div class="evrow"><input data-lim="${i}" data-f="event" value="${esc(l.event)}"><input type="number" data-lim="${i}" data-f="max" value="${l.max}"><input type="number" data-lim="${i}" data-f="window" value="${l.window}"><input type="number" step="0.5" data-lim="${i}" data-f="weight" value="${l.weight}"><button class="icon" data-a="limdel" data-i="${i}">${ic('trash', 14)}</button></div>`).join('');
    return `${listBox('events.honeypots', 'Événements pièges (honeypots)', 'Un nom par ligne. <b>Aucun script légitime ne doit envoyer ces événements</b> : celui qui les envoie utilise un outil de triche. Ne mets ici que des noms que tu es sûr de ne pas utiliser.')}
      <div class="card"><div class="card-h"><div class="t">Limites de fréquence</div><button class="sm" data-a="limadd">${ic('plus', 14)} Ajouter</button></div>
      <div class="evrow" style="font-size:10px;color:var(--muted);text-transform:uppercase;letter-spacing:.1em"><span>Événement</span><span>Max</span><span>Fenêtre (s)</span><span>Poids</span><span></span></div>${lim || '<p class="hint">Aucune limite.</p>'}
      <p class="hint mt-s">Si un joueur envoie l'événement plus de <b>Max</b> fois en <b>Fenêtre</b> secondes, l'événement est annulé et le module « Fréquence des événements » monte de <b>Poids</b>.</p></div>`;
  }
  if (t === 'exempt') {
    const am = Object.keys(c.modules).map(k => `<label class="chk"><input type="checkbox" data-am="${k}" ${c.exempt.adminModules.includes(k) ? 'checked' : ''}> ${esc(modLabel(k))}</label>`).join('');
    return `<div class="grid2">${listBox('exempt.groups', 'Groupes staff exemptés', 'ex : <b>admin</b>, <b>superadmin</b>, <b>_dev</b>')}${listBox('exempt.jobs', 'Métiers exemptés', 'ex : <b>police</b>. Exemptés de tous les modules.')}</div>
      <div class="grid2">${listBox('exempt.states', 'Statebags d\'exemption', 'Un script qui met ce statebag à <b>true</b> sur le joueur le rend exempt (ex : <b>inMinigame</b>).')}${listBox('exempt.licenses', 'Licences exemptées', 'Une licence par ligne (<b>license:…</b>). Exemptées de tout.')}</div>
      <div class="card"><div class="card-h"><div class="t">Modules ignorés pour le staff</div></div><div class="grid3" style="gap:8px">${am}</div></div>`;
  }
  const dur = (c.banDurations || []).join('\n');
  return `<div class="grid2"><div class="card"><div class="card-h"><div class="t">Mode</div></div><div class="seg" style="margin-bottom:10px"><button class="${c.mode === 'protect' ? 'active' : ''}" data-a="mode" data-m="protect">Protection</button><button class="${c.mode === 'observe' ? 'active' : ''}" data-a="mode" data-m="observe">Observation</button></div>
    <p class="hint"><b>Observation</b> : rien n'est sanctionné, tout est écrit dans le journal (« simulé : ban »). Recommandé pour la première semaine. <b>Protection</b> : kick et ban automatiques.</p></div>
    <div class="card"><div class="card-h"><div class="t">Général</div></div><div class="grid2">${numIn('scoreDecay', 'Retombée du score (s)')}${numIn('grace.join', 'Grâce connexion (s)')}${numIn('grace.spawn', 'Grâce apparition (s)')}${numIn('grace.exempt', 'Grâce exemption (s)')}</div></div></div>
    <div class="grid2"><div class="card"><div class="card-h"><div class="t">Journal Discord</div></div><label class="f"><span>URL du webhook</span><input data-path="webhook" data-t="str" value="${esc(c.webhook)}" placeholder="https://discord.com/api/webhooks/…"></label></div>
    <div class="card"><div class="card-h"><div class="t">Message d'appel</div></div><label class="f"><span>Affiché aux joueurs sanctionnés</span><input data-path="appeal" data-t="str" value="${esc(c.appeal)}"></label></div></div>
    <div class="grid2"><div class="card"><div class="card-h"><div class="t">Durées de ban proposées</div></div><textarea data-path="banDurations" data-t="lines" spellcheck="false" style="min-height:110px">${esc(dur)}</textarea><p class="hint mt-s">Format : <b>30m</b>, <b>12h</b>, <b>3d</b>, <b>perm</b></p></div>
    <div class="card"><div class="card-h"><div class="t">Double compte</div></div>${Object.keys(c.evasion).map(k => `<label class="chk" style="margin-bottom:8px"><input type="checkbox" data-path="evasion.${k}" data-t="bool" ${c.evasion[k] ? 'checked' : ''}> ${esc(k)}</label>`).join('')}</div></div>
    <div class="card"><button class="danger" data-a="reset">Réinitialiser toutes les règles</button></div>`;
}
async function viewRules(first) {
  if (first || !S.cfg) {
    const r = await rpc('settingsGet');
    if (!r.ok) return toast(r.error || 'Erreur', 'err');
    S.cfg = clone(r.cfg); S.defaults = r.defaults; S.knownWeapons = r.weapons || []; S.info = r.info || S.info; S.dirty = false;
  }
  const seg = RTABS.map(([k, l]) => `<button class="${S.rtab === k ? 'active' : ''}" data-a="rtab" data-k="${k}">${l}</button>`).join('');
  const acts = S.canBan ? `<button class="primary" data-a="save" ${S.dirty ? '' : 'disabled'}>${ic('check', 16)} Enregistrer</button>` : '';
  frame(`<div class="seg">${seg}</div>${S.canBan ? '' : '<div class="warnbox" style="margin-bottom:14px">Lecture seule : seuls les groupes autorisés peuvent modifier les règles.</div>'}${rulesBody()}`, 'Règles', 'Modules, listes et exemptions : tout est modifiable ici, sans redémarrage', acts);
  if (!S.canBan) $$('#body input, #body textarea, #body select, #body button').forEach(e => { if (!e.dataset.a || e.dataset.a !== 'rtab') e.disabled = true; });
}
function markDirty() { if (!S.dirty) { S.dirty = true; const b = $('[data-a=save]'); if (b) b.disabled = false; } }
function parseJobs(txt) { const o = {}; txt.split('\n').forEach(l => { const m = l.split(':'); if (m.length >= 2) { const j = m[0].trim(); const w = m.slice(1).join(':').split(/[,\s]+/).map(s => s.trim()).filter(Boolean); if (j) o[j] = w; } }); return o; }
function onField(el) {
  if (!S.cfg) return;
  if (el.dataset.am) { const a = S.cfg.exempt.adminModules, k = el.dataset.am; const i = a.indexOf(k); if (el.checked && i < 0) a.push(k); if (!el.checked && i >= 0) a.splice(i, 1); return markDirty(); }
  if (el.dataset.lim != null) { const l = S.cfg.events.limits[+el.dataset.lim]; if (l) l[el.dataset.f] = el.dataset.f === 'event' ? el.value.trim() : Number(el.value); return markDirty(); }
  const p = el.dataset.path; if (!p) return;
  const t = el.dataset.t; let v;
  if (t === 'num') v = Number(el.value); else if (t === 'bool') v = el.checked; else if (t === 'lines') v = el.value.split('\n').map(s => s.trim()).filter(Boolean);
  else if (t === 'jobs') v = parseJobs(el.value); else v = el.value;
  setPath(S.cfg, p, v);
  if (t === 'bool' && /\.enabled$/.test(p)) el.closest('.mod')?.classList.toggle('off', !v);
  markDirty();
}

/* ═══════════ Navigation / actions ═══════════ */
function stopTimer() { clearInterval(S.timer); S.timer = null; }
async function show(tab, opts) {
  S.tab = tab;
  stopTimer();
  if (tab === 'dash') await viewDash();
  else if (tab === 'players') { if (S.selId) await viewPlayer(S.selId); else await viewPlayers(); S.timer = setInterval(() => { if (S.tab === 'players' && !S.selId && !$('#pq:focus')) viewPlayers(true); }, 5000); }
  else if (tab === 'logs') await viewLogs();
  else if (tab === 'bans') await viewBans();
  else if (tab === 'rules') await viewRules(opts && opts.first);
}
const reload = () => show(S.tab);

async function act(a, el) {
  const d = el.dataset;
  if (a === 'close') { return rpc('close'); }
  if (a === 'tab') { if (S.tab === 'rules' && S.dirty && d.k !== 'rules' && !(await confirmBox('Modifications non enregistrées', 'Quitter les règles sans enregistrer ?', 'Quitter'))) return; if (S.tab === 'rules' && d.k !== 'rules') { S.cfg = null; S.dirty = false; } S.selId = null; return show(d.k, { first: d.k === 'rules' && !S.cfg }); }
  if (a === 'refresh') return reload();
  if (a === 'player') return viewPlayer(+d.id);
  if (a === 'players-back') { S.selId = null; return show('players'); }
  const sel = S.sel;
  if (a === 'warn') { const v = await ask('Avertir ' + sel.name, 'Le joueur reçoit une notification à l\'écran.', [{ label: 'Message', value: 'Comportement suspect : merci de respecter le règlement.' }], 'Envoyer', false); if (!v) return; const r = await rpc('warn', sel.id, v[0]); toast(r.ok ? 'Avertissement envoyé' : r.error, r.ok ? 'ok' : 'err'); return viewPlayer(sel.id); }
  if (a === 'kick') { const v = await ask('Expulser ' + sel.name, 'Le joueur sera déconnecté.', [{ label: 'Raison', value: 'Expulsé par le staff' }], 'Expulser'); if (!v) return; const r = await rpc('kick', sel.id, v[0]); toast(r.ok ? 'Joueur expulsé' : r.error, r.ok ? 'ok' : 'err'); if (r.ok) { S.selId = null; show('players'); } return; }
  if (a === 'ban') { const v = await ask('Bannir ' + sel.name, 'Le bannissement est appliqué immédiatement.', [{ label: 'Durée', type: 'select', options: (S.cfg ? S.cfg.banDurations : S.durs) || ['1h', '1d', '7d', 'perm'], value: '1d' }, { label: 'Raison', value: 'Triche' }], 'Bannir'); if (!v) return; const r = await rpc('ban', sel.id, v[0], v[1]); toast(r.ok ? 'Joueur banni' : r.error, r.ok ? 'ok' : 'err'); if (r.ok) { S.selId = null; show('players'); } return; }
  if (a === 'exemptSel') { const add = !sel.exempted; if (!(await confirmBox(add ? 'Exempter ce joueur ?' : 'Retirer l\'exemption ?', add ? 'Aucun module ne le sanctionnera plus.' : 'Il sera de nouveau surveillé.', 'Confirmer', add))) return; const r = await rpc('exempt', sel.license, add); toast(r.ok ? 'Mis à jour' : r.error, r.ok ? 'ok' : 'err'); return viewPlayer(sel.id); }
  if (a === 'lpage') { S.logF.page = Math.max(0, S.logF.page + +d.d); return viewLogs(); }
  if (a === 'fp') { const r = await rpc('markFp', +d.id, d.v === '1'); toast(r.ok ? 'Mis à jour' : r.error, r.ok ? 'ok' : 'err'); return viewLogs(); }
  if (a === 'bpage') { S.banPage = Math.max(0, S.banPage + +d.d); return viewBans(); }
  if (a === 'unban') { if (!(await confirmBox('Débannir ' + d.n + ' ?', 'Le joueur pourra se reconnecter immédiatement.', 'Débannir', false))) return; const r = await rpc('unban', d.id); toast(r.ok ? 'Joueur débanni' : r.error, r.ok ? 'ok' : 'err'); return viewBans(); }
  if (a === 'banoff') { const v = await ask('Bannir hors ligne', 'Pour un joueur déconnecté, avec sa licence.', [{ label: 'Licence', placeholder: 'license:…' }, { label: 'Nom', value: 'Inconnu' }, { label: 'Durée', type: 'select', options: (S.cfg ? S.cfg.banDurations : S.durs) || ['1d', 'perm'], value: '1d' }, { label: 'Raison', value: 'Triche' }], 'Bannir'); if (!v) return; const r = await rpc('banOffline', v[0], v[1], v[2], v[3]); toast(r.ok ? 'Bannissement enregistré' : r.error, r.ok ? 'ok' : 'err'); return viewBans(); }
  if (a === 'rtab') { S.rtab = d.k; return viewRules(); }
  if (a === 'save') { const r = await rpc('settingsSave', S.cfg); if (!r.ok) return toast(r.error || 'Erreur', 'err'); S.cfg = clone(r.cfg); S.dirty = false; toast('Règles enregistrées et appliquées', 'ok'); snd('announce'); return viewRules(); }
  if (a === 'reset') { if (!(await confirmBox('Réinitialiser ?', 'Toutes les règles reviennent aux valeurs du fichier config.lua.', 'Réinitialiser'))) return; const r = await rpc('settingsReset'); if (!r.ok) return toast(r.error, 'err'); S.cfg = clone(r.cfg); S.dirty = false; toast('Règles réinitialisées', 'ok'); return viewRules(); }
  if (a === 'mode') { if (S.canBan) { const r = await rpc('setMode', d.m); if (!r.ok) return toast(r.error, 'err'); S.cfg.mode = r.mode; toast(r.mode === 'observe' ? 'Mode observation' : 'Mode protection', 'ok'); } return viewRules(); }
  if (a === 'limadd') { S.cfg.events.limits.push({ event: '', max: 10, window: 5, weight: 1 }); markDirty(); return viewRules(); }
  if (a === 'limdel') { S.cfg.events.limits.splice(+d.i, 1); markDirty(); return viewRules(); }
  if (a === 'wk-wl' || a === 'wk-bl') { const w = $('#wk').value; if (!w) return; const p = a === 'wk-wl' ? 'weapons.whitelist' : 'weapons.blacklist'; const l = getPath(S.cfg, p); if (!l.includes(w)) l.push(w); markDirty(); return viewRules(); }
}

document.addEventListener('click', e => { const el = e.target.closest('[data-a]'); if (!el || el.disabled) return; snd('tick'); act(el.dataset.a, el); });
document.addEventListener('change', e => {
  const t = e.target;
  if (t.id === 'lf-m') { S.logF.module = t.value; S.logF.page = 0; return viewLogs(); }
  if (t.id === 'lf-a') { S.logF.actions = t.checked; S.logF.page = 0; return viewLogs(); }
  if (t.id === 'lf-f') { S.logF.hideFp = t.checked; S.logF.page = 0; return viewLogs(); }
  onField(t);
});
document.addEventListener('input', e => {
  const t = e.target;
  if (t.id === 'pq') { S.q = t.value; const l = $('#plist'); if (l) l.innerHTML = playersHtml(); }
  else if (t.dataset && (t.dataset.lim != null || (t.tagName === 'TEXTAREA') || t.type === 'text' || t.type === 'number' || (t.dataset.path && t.dataset.t === 'str'))) onField(t);
});
document.addEventListener('keydown', e => {
  if (e.key === 'Enter' && e.target.id === 'lf-q') { S.logF.q = e.target.value; S.logF.page = 0; viewLogs(); }
  if (e.key === 'Enter' && e.target.id === 'bq') { S.banQ = e.target.value; S.banPage = 0; viewBans(); }
  if (e.key === 'Escape') { const c = document.getElementById('confirm'); if (!c.classList.contains('hidden')) { $('#c-no', c)?.click(); return; } rpc('close'); }
});

window.addEventListener('message', ev => {
  const m = ev.data || {};
  if (m.action === 'open') { S.canBan = !!m.canBan; S.selId = null; S.cfg = null; S.dirty = false; S.tab = 'dash'; rpc('settingsGet').then(r => { if (r.ok) { S.info = r.info || {}; S.durs = r.cfg.banDurations; S.cfg = clone(r.cfg); S.defaults = r.defaults; S.knownWeapons = r.weapons || []; S.cfg.mode; } show('dash'); }); }
  if (m.action === 'close') { stopTimer(); $root.classList.add('hidden'); $root.innerHTML = ''; S.cfg = null; S.dirty = false; document.getElementById('confirm').classList.add('hidden'); }
});
