'use strict';
const $root = document.getElementById('root'), $modal = document.getElementById('modal'), $toasts = document.getElementById('toasts');
const res = () => (typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'pickax_eventbuilder');
const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const rpc = (name, ...args) => fetch(`https://${res()}/rpc`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ name, args }) })
  .then(r => r.json()).catch(() => ({ ok: false, error: 'Pas de réponse' }));

const IC = {
  truck: '<path d="M3 7h11v9H3z"/><path d="M14 10h4l3 3v3h-7z"/><circle cx="7" cy="17.5" r="1.8"/><circle cx="17" cy="17.5" r="1.8"/>',
  box: '<path d="M3 8l9-5 9 5v8l-9 5-9-5z"/><path d="M3 8l9 5 9-5M12 13v8"/>',
  store: '<path d="M4 9l1.5-5h13L20 9"/><path d="M4 9v11h16V9"/><path d="M9 20v-6h6v6"/>',
  plane: '<path d="M21 4l-6 17-3-7-7-3z"/><path d="M12 14l9-10"/>',
  car: '<path d="M5 16l1.5-6h11L19 16"/><path d="M3 16h18v3H3z"/><circle cx="7.5" cy="19" r="1.5"/><circle cx="16.5" cy="19" r="1.5"/>',
  flag: '<path d="M5 21V4"/><path d="M5 5h12l-2 4 2 4H5"/>',
  plus: '<path d="M12 5v14M5 12h14"/>', x: '<path d="M6 6l12 12M18 6L6 18"/>', play: '<polygon points="6 4 20 12 6 20 6 4"/>',
  stop: '<rect x="6" y="6" width="12" height="12" rx="1"/>', edit: '<path d="M12 20h9"/><path d="M16.5 3.5l4 4L8 20l-5 1 1-5z"/>',
  copy: '<rect x="9" y="9" width="11" height="11" rx="2"/><path d="M5 15V5a2 2 0 0 1 2-2h10"/>', trash: '<path d="M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3"/>',
  pin: '<path d="M12 21s7-6.2 7-11a7 7 0 0 0-14 0c0 4.8 7 11 7 11z"/><circle cx="12" cy="10" r="2.5"/>', tp: '<path d="M12 3v6M12 15v6M3 12h6M15 12h6"/><circle cx="12" cy="12" r="2"/>',
  grid: '<rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/>',
  zap: '<path d="M13 2L4 14h7l-1 8 9-12h-7z"/>', clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
};
const ic = (n, s) => `<svg class="ic" viewBox="0 0 24 24"${s ? ` style="width:${s}px;height:${s}px"` : ''}>${IC[n] || IC.zap}</svg>`;

const S = { tab: 'events', list: [], active: [], logs: [], cat: null, cur: null, curId: null, isNew: false, q: '', timer: null };

function toast(msg, kind) {
  const t = document.createElement('div');
  t.className = 'toast ' + (kind || '');
  t.textContent = msg;
  $toasts.appendChild(t);
  setTimeout(() => t.remove(), 3200);
}
const ok = (r, msg) => { if (!r || !r.ok) { toast((r && r.error) || 'Erreur', 'bad'); return false; } if (msg) toast(msg, 'ok'); return true; };

const getPath = (o, p) => p.split('.').reduce((a, k) => (a == null ? a : a[k]), o);
function setPath(o, p, v) {
  const ks = p.split('.'); const last = ks.pop();
  const t = ks.reduce((a, k) => { if (a[k] == null) a[k] = {}; return a[k]; }, o);
  t[last] = v;
}

/* ─────────────── chargement ─────────────── */
async function loadAll() {
  const [c, l, a] = await Promise.all([rpc('catalog'), rpc('list'), rpc('active')]);
  if (!ok(c)) return;
  S.cat = c;
  S.list = (l && l.list) || [];
  S.active = (a && a.list) || [];
  render();
}
const refreshList = async () => { const l = await rpc('list'); if (ok(l)) S.list = l.list; };

/* ─────────────── rendu ─────────────── */
function shell(inner) {
  const tabs = [['events', 'Événements'], ['active', 'En cours'], ['logs', 'Historique']];
  return `<div class="top"><div class="tile">${ic('zap')}</div><div><h1>Event Builder</h1><p>Braquages, largages, livraisons, zones… créés et lancés directement en jeu</p></div><div class="sp"></div>
    <button data-a="hub">${ic('grid')} Panel builders</button><button class="icon" data-a="close" title="Fermer (Échap)">${ic('x')}</button></div>
    <div class="tabs">${tabs.map(t => `<button class="tab ${S.tab === t[0] && !S.cur ? 'on' : ''}" data-a="tab" data-v="${t[0]}">${t[1]}${t[0] === 'active' && S.active.length ? ` <span class="chip acc">${S.active.length}</span>` : ''}</button>`).join('')}</div>
    <div class="body">${inner}</div>`;
}

function trigLabel(t) { return t === 'auto' ? 'Automatique' : t === 'interact' ? 'Interaction' : 'Manuel'; }

function renderList() {
  const q = S.q.toLowerCase();
  const rows = S.list.filter(e => !q || e.label.toLowerCase().includes(q) || (e.typeLabel || '').toLowerCase().includes(q));
  return `<div class="bar"><input id="q" placeholder="Rechercher un événement…" value="${esc(S.q)}"><div class="grow"></div><button class="pri" data-a="new">${ic('plus')} Nouvel événement</button></div>` +
    (rows.length ? rows.map(e => `<div class="ev"><div class="tile">${ic(e.icon)}</div><div class="grow"><div class="nm">${esc(e.label)}</div>
      <div class="sb"><span class="chip acc">${esc(e.typeLabel || e.type)}</span><span class="chip ${e.enabled ? 'ok' : 'bad'}">${e.enabled ? 'Actif' : 'Désactivé'}</span><span class="chip">${trigLabel(e.trigger)}</span>
      <span class="chip">${ic('pin', 12)} ${e.locations} lieu(x)</span><span class="chip">${ic('clock', 12)} délai ${e.cooldown} min</span>${e.minPolice ? `<span class="chip warn">${e.minPolice} policier(s)</span>` : ''}
      ${e.running ? '<span class="chip ok">En cours</span>' : (e.cooldownLeft > 0 ? `<span class="chip warn">attente ${Math.ceil(e.cooldownLeft / 60)} min</span>` : '')}</div></div>
      <div class="acts"><button class="sm pri" data-a="start" data-id="${e.id}" ${e.running ? 'disabled' : ''}>${ic('play', 14)} Lancer</button><button class="sm" data-a="edit" data-id="${e.id}">${ic('edit', 14)} Modifier</button>
      <button class="sm" data-a="dup" data-id="${e.id}">${ic('copy', 14)}</button><button class="sm" data-a="toggle" data-id="${e.id}">${e.enabled ? 'Désactiver' : 'Activer'}</button><button class="sm bad" data-a="del" data-id="${e.id}">${ic('trash', 14)}</button></div></div>`).join('')
      : `<div class="empty">${S.list.length ? 'Aucun résultat.' : 'Aucun événement : clique sur « Nouvel événement » et choisis un modèle (fourgon Brinks, largage, braquage…).'}</div>`);
}

function renderActive() {
  if (!S.active.length) return '<div class="empty">Aucun événement en cours.</div>';
  return `<table><tr><th>Événement</th><th>Étape</th><th>Butin restant</th><th>Gardes</th><th>Fin dans</th><th></th></tr>` +
    S.active.map(a => `<tr><td><b>${esc(a.label)}</b><br><span class="chip acc">${esc(a.type)}</span></td><td>${esc(a.stage)}</td><td>${a.loot}</td><td>${a.guards}</td><td>${Math.floor(a.endsIn / 60)}:${String(a.endsIn % 60).padStart(2, '0')}</td>
      <td style="text-align:right"><button class="sm" data-a="tp" data-i="${S.active.indexOf(a)}">${ic('tp', 14)} Aller sur place</button> <button class="sm bad" data-a="stop" data-rid="${a.rid}">${ic('stop', 14)} Arrêter</button></td></tr>`).join('') + '</table>';
}

function renderLogs() {
  if (!S.logs.length) return '<div class="empty">Historique vide.</div>';
  return `<table><tr><th>Date</th><th>Événement</th><th>Joueur</th><th>Action</th><th>Détail</th><th>Montant</th></tr>` + S.logs.map(l => `<tr><td>${new Date(l.ts * 1000).toLocaleString('fr-FR')}</td><td>${esc(l.event_label)}</td>
    <td>${esc(l.player_name)}</td><td><span class="chip">${esc(l.action)}</span></td><td>${esc(l.detail || '')}</td><td>${l.amount ? l.amount + ' ' + esc(S.cat.currency) : ''}</td></tr>`).join('') + '</table>';
}

const fld = (label, inner) => `<label class="f"><span>${esc(label)}</span>${inner}</label>`;
const inp = (path, type, extra) => `<input data-p="${path}" data-t="${type === 'number' ? 'n' : 's'}" type="${type}" value="${esc(getPath(S.cur, path) ?? '')}" ${extra || ''}>`;
const chk = (path, label) => `<label class="chk"><input type="checkbox" data-p="${path}" data-t="b" ${getPath(S.cur, path) ? 'checked' : ''}> ${esc(label)}</label>`;

function paramField(f) {
  const p = 'params.' + f.key, v = getPath(S.cur, p);
  if (f.kind === 'bool') return chk(p, f.label);
  if (f.kind === 'select') return fld(f.label, `<select data-p="${p}" data-t="s">${(f.options || []).map(o => `<option value="${esc(o[0])}" ${v === o[0] ? 'selected' : ''}>${esc(o[1])}</option>`).join('')}</select>`);
  if (f.kind === 'number') return fld(f.label, inp(p, 'number', `min="${f.min ?? ''}" max="${f.max ?? ''}" step="${f.step ?? 1}"`));
  return fld(f.label, inp(p, 'text', 'maxlength="80"'));
}

function renderEditor() {
  const e = S.cur, T = S.cat.types[e.type], r = e.reward;
  const locs = e.locations.map((l, i) => `<div class="loc">${fld('Nom du lieu', `<input data-p="locations.${i}.label" data-t="s" value="${esc(l.label || '')}" maxlength="40" placeholder="Ex : Pacific Bank">`)}
    ${['x', 'y', 'z', 'h'].map(k => fld(k.toUpperCase(), `<input data-p="locations.${i}.${k}" data-t="n" type="number" step="0.01" value="${Number(l[k] ?? 0).toFixed(2)}">`)).join('')}
    <div class="row"><button class="sm" data-a="here" data-i="${i}" title="Prendre ma position">${ic('pin', 14)}</button><button class="sm" data-a="gotoLoc" data-i="${i}" title="Se téléporter">${ic('tp', 14)}</button><button class="sm bad" data-a="delLoc" data-i="${i}">${ic('x', 14)}</button></div></div>`).join('');
  const items = (r.items || []).map((it, i) => `<div class="grid g4" style="margin-bottom:8px;align-items:end">${fld('Objet (nom ox_inventory / ESX)', `<input data-p="reward.items.${i}.name" data-t="s" value="${esc(it.name)}">`)}
    ${fld('Min', `<input data-p="reward.items.${i}.min" data-t="n" type="number" min="1" value="${it.min}">`)}${fld('Max', `<input data-p="reward.items.${i}.max" data-t="n" type="number" min="1" value="${it.max}">`)}
    <div class="row">${fld('Chance %', `<input data-p="reward.items.${i}.chance" data-t="n" type="number" min="1" max="100" value="${it.chance}">`)}<button class="sm bad" data-a="delItem" data-i="${i}" style="margin-top:18px">${ic('x', 14)}</button></div></div>`).join('');
  const dest = T.needsDest ? `<div class="card"><h3>${ic('flag')} Destination de livraison</h3><div class="row">
      <div class="grow">${fld('X', inp('params.destX', 'number', 'step="0.01"'))}</div><div class="grow">${fld('Y', inp('params.destY', 'number', 'step="0.01"'))}</div><div class="grow">${fld('Z', inp('params.destZ', 'number', 'step="0.01"'))}</div>
      <button data-a="hereDest" style="margin-top:18px">${ic('pin', 14)} Ma position</button><button data-a="gotoDest" style="margin-top:18px">${ic('tp', 14)}</button></div></div>` : '';
  const fields = T.fields.filter(f => !(T.needsDest && /^dest[XYZ]$/.test(f.key)));
  return `<div class="bar"><button data-a="back">← Retour</button><div class="grow"></div><span class="chip acc">${ic(T.icon, 12)} ${esc(T.label)}</span></div>
    <div class="card"><h3>${ic('zap')} Général</h3><div class="grid g3">
      ${fld('Nom de l\'événement', inp('label', 'text', 'maxlength="60"'))}
      ${S.isNew ? fld('Identifiant (a-z, 0-9, _)', inp('name', 'text', 'maxlength="40" placeholder="auto"')) : fld('Identifiant', `<input value="${esc(e.name)}" disabled>`)}
      ${fld('Déclenchement', `<select data-p="trigger" data-t="s"><option value="auto" ${e.trigger === 'auto' ? 'selected' : ''}>Automatique (planifié)</option><option value="manual" ${e.trigger === 'manual' ? 'selected' : ''}>Manuel (admin)</option><option value="interact" ${e.trigger === 'interact' ? 'selected' : ''}>Interaction (joueur)</option></select>`)}
      ${fld('Délai avant relance (min)', inp('cooldown', 'number', 'min="0" max="1440"'))}
      ${fld('Durée maximale (min)', inp('duration', 'number', 'min="1" max="240"'))}
      ${fld('Policiers requis', inp('minPolice', 'number', 'min="0" max="30"'))}
      ${fld('Joueurs connectés minimum', inp('minPlayers', 'number', 'min="0" max="200"'))}</div>
      ${chk('enabled', 'Événement actif')}
      <p class="hint">${esc(T.desc)} Auto = lancé au hasard par le serveur ; Manuel = bouton « Lancer » ; Interaction = le joueur le déclenche sur place (commerce).</p></div>
    <div class="card"><h3>${ic('pin')} Lieux</h3>${locs}<button data-a="addLoc">${ic('plus', 14)} Ajouter un lieu (ma position)</button>
      <p class="hint">À chaque lancement automatique ou manuel, un lieu est tiré au hasard. Place-toi à l'endroit voulu puis « Ma position » (l'orientation sert pour le fourgon / le véhicule).</p></div>
    ${dest}
    <div class="card"><h3>${ic('box')} Paramètres de l'événement</h3><div class="grid g3">${fields.map(paramField).join('')}</div></div>
    <div class="card"><h3>${ic('zap')} Récompense</h3>
      ${fld('Type', `<select data-p="reward.kind" data-t="s" data-re="1"><option value="account" ${r.kind === 'account' ? 'selected' : ''}>Argent</option><option value="items" ${r.kind === 'items' ? 'selected' : ''}>Objets</option></select>`)}
      ${r.kind === 'account' ? `<div class="grid g3" style="margin-top:10px">${fld('Compte', `<select data-p="reward.account" data-t="s">${['black_money', 'money', 'bank'].map(a => `<option value="${a}" ${r.account === a ? 'selected' : ''}>${a === 'black_money' ? 'Argent sale' : a === 'money' ? 'Liquide' : 'Banque'}</option>`).join('')}</select>`)}
        ${fld('Minimum', inp('reward.min', 'number', 'min="0"'))}${fld('Maximum', inp('reward.max', 'number', 'min="0"'))}</div>`
      : `<div style="margin-top:10px">${items}<button data-a="addItem">${ic('plus', 14)} Ajouter un objet</button></div>`}
      <p class="hint">${e.type === 'truck' ? 'Récompense versée par sac ramassé.' : (e.type === 'drop' || e.type === 'crash') ? 'Récompense versée par caisse ouverte.' : 'Versée au joueur qui réussit l\'événement.'} Tout est vérifié et versé côté serveur.</p></div>
    <div class="card"><h3>${ic('flag')} Police, blip et annonces</h3><div class="grid g3">
      <div>${chk('alert.enabled', 'Alerter la police')}${fld('Délai d\'alerte (s)', inp('alert.delay', 'number', 'min="0" max="300"'))}</div>
      <div style="grid-column: span 2">${fld('Message d\'alerte', inp('alert.message', 'text', 'maxlength="100"'))}</div>
      <div>${chk('blip.enabled', 'Afficher un blip à tous')}${chk('blip.flash', 'Blip clignotant')}</div>
      ${fld('Sprite du blip', inp('blip.sprite', 'number', 'min="0" max="900"'))}${fld('Couleur du blip', inp('blip.color', 'number', 'min="0" max="85"'))}
      ${fld('Rayon de la zone (m, 0 = aucun)', inp('blip.radius', 'number', 'min="0" max="500"'))}${fld('Taille du blip', inp('blip.scale', 'number', 'min="0.3" max="2" step="0.1"'))}
      <div></div>
      ${fld('Annonce au début (tous les joueurs, vide = aucune)', inp('announce.start', 'text', 'maxlength="140"'))}${fld('Annonce à la fin (vide = aucune)', inp('announce.finish', 'text', 'maxlength="140"'))}</div></div>
    <div class="save"><button data-a="back">Annuler</button><button class="pri" data-a="save">${S.isNew ? 'Créer l\'événement' : 'Enregistrer'}</button></div>`;
}

function render() {
  if (S.timer) { clearInterval(S.timer); S.timer = null; }
  let inner;
  if (S.cur) inner = renderEditor();
  else if (S.tab === 'active') inner = renderActive();
  else if (S.tab === 'logs') inner = renderLogs();
  else inner = renderList();
  const body = $root.querySelector('.body');
  const scroll = body ? body.scrollTop : 0;
  $root.innerHTML = shell(inner);
  const nb = $root.querySelector('.body'); if (nb) nb.scrollTop = scroll;
  if (!S.cur && S.tab === 'active') S.timer = setInterval(async () => { const a = await rpc('active'); if (a && a.ok) { S.active = a.list; if (S.tab === 'active' && !S.cur) { const b = $root.querySelector('.body'); const y = b.scrollTop; b.innerHTML = renderActive(); b.scrollTop = y; } } }, 2000);
}

/* ─────────────── actions ─────────────── */
function openTemplates() {
  const byType = {};
  S.cat.templates.forEach(t => { (byType[t.type] = byType[t.type] || []).push(t); });
  $modal.innerHTML = `<div class="box"><h2>Nouvel événement</h2><p>Choisis un modèle : tout reste modifiable ensuite (lieux, butin, gardes, police…).</p>
    ${Object.keys(byType).map(ty => `<h3 style="margin:14px 0 8px;color:var(--muted);font-size:12px;letter-spacing:.08em;text-transform:uppercase">${esc(S.cat.types[ty].label)}</h3><div class="tpls">${byType[ty].map(t => `<button class="tpl" data-a="tpl" data-id="${t.id}"><div class="tile">${ic(S.cat.types[t.type].icon)}</div><div><b>${esc(t.label)}</b><small>${esc(t.desc)}</small></div></button>`).join('')}</div>`).join('')}
    <div style="text-align:right;margin-top:16px"><button data-a="closeModal">Fermer</button></div></div>`;
  $modal.classList.remove('hidden');
}
const closeModal = () => { $modal.classList.add('hidden'); $modal.innerHTML = ''; };

async function hereCoords() { return await rpc('getCoords'); }

document.addEventListener('click', async e => {
  const el = e.target.closest('[data-a]'); if (!el) return;
  const a = el.dataset.a, id = Number(el.dataset.id), i = Number(el.dataset.i);
  switch (a) {
    case 'close': return rpc('close');
    case 'hub': return rpc('bbHub');
    case 'tab': S.tab = el.dataset.v; S.cur = null; if (S.tab === 'logs') { const l = await rpc('logs'); if (ok(l)) S.logs = l.logs; } if (S.tab === 'active') { const x = await rpc('active'); if (ok(x)) S.active = x.list; } if (S.tab === 'events') await refreshList(); return render();
    case 'new': return openTemplates();
    case 'closeModal': return closeModal();
    case 'tpl': { closeModal(); const r = await rpc('draft', el.dataset.id); if (!ok(r)) return; S.cur = r.event; S.isNew = true; S.curId = null; return render(); }
    case 'edit': { const r = await rpc('get', id); if (!ok(r)) return; S.cur = r.event; S.curId = id; S.isNew = false; return render(); }
    case 'back': S.cur = null; await refreshList(); return render();
    case 'dup': { const r = await rpc('duplicate', id); if (ok(r, 'Événement dupliqué (désactivé)')) { await refreshList(); render(); } return; }
    case 'toggle': { const r = await rpc('toggle', id); if (ok(r)) { await refreshList(); render(); } return; }
    case 'del': { if (!confirm('Supprimer définitivement cet événement ?')) return; const r = await rpc('delete', id); if (ok(r, 'Supprimé')) { await refreshList(); render(); } return; }
    case 'start': { const ev = S.list.find(x => x.id === id); const r = await rpc('start', id); if (ok(r, `« ${ev ? ev.label : 'Événement'} » lancé`)) { const x = await rpc('active'); if (x.ok) S.active = x.list; await refreshList(); render(); } return; }
    case 'stop': { const r = await rpc('stop', Number(el.dataset.rid)); if (ok(r, 'Événement arrêté')) { const x = await rpc('active'); if (x.ok) S.active = x.list; await refreshList(); render(); } return; }
    case 'tp': { const ev = S.active[i]; if (ev) { await rpc('teleport', ev.coords); toast('Téléportation…', 'ok'); } return; }
    case 'here': { const c = await hereCoords(); Object.assign(S.cur.locations[i], { x: c.x, y: c.y, z: c.z, h: c.h }); return render(); }
    case 'gotoLoc': { const l = S.cur.locations[i]; await rpc('teleport', l); return; }
    case 'addLoc': { const c = await hereCoords(); S.cur.locations.push({ x: c.x, y: c.y, z: c.z, h: c.h, label: '' }); return render(); }
    case 'delLoc': S.cur.locations.splice(i, 1); return render();
    case 'hereDest': { const c = await hereCoords(); S.cur.params.destX = c.x; S.cur.params.destY = c.y; S.cur.params.destZ = c.z; return render(); }
    case 'gotoDest': return rpc('teleport', { x: S.cur.params.destX, y: S.cur.params.destY, z: S.cur.params.destZ });
    case 'addItem': S.cur.reward.items = S.cur.reward.items || []; S.cur.reward.items.push({ name: '', min: 1, max: 1, chance: 100 }); return render();
    case 'delItem': S.cur.reward.items.splice(i, 1); return render();
    case 'save': {
      const r = S.isNew ? await rpc('create', S.cur) : await rpc('save', S.curId, S.cur);
      if (!ok(r, S.isNew ? 'Événement créé' : 'Enregistré')) return;
      S.cur = null; await refreshList(); return render();
    }
  }
});

document.addEventListener('input', e => {
  const el = e.target;
  if (el.id === 'q') { S.q = el.value; const b = $root.querySelector('.body'); const keep = el.selectionStart; b.innerHTML = renderList(); const q = document.getElementById('q'); q.focus(); q.setSelectionRange(keep, keep); return; }
  if (!el.dataset.p || !S.cur) return;
  let v = el.value;
  if (el.dataset.t === 'n') v = v === '' ? 0 : Number(v);
  else if (el.dataset.t === 'b') v = el.checked;
  setPath(S.cur, el.dataset.p, v);
});
document.addEventListener('change', e => {
  const el = e.target;
  if (el.dataset && el.dataset.re && S.cur) { // changement de type de récompense : réaffiche le bloc
    if (el.value === 'items' && !(S.cur.reward.items && S.cur.reward.items.length)) S.cur.reward.items = [{ name: '', min: 1, max: 1, chance: 100 }];
    render();
  }
});

window.addEventListener('message', e => {
  const d = e.data || {};
  if (d.action === 'open') { $root.classList.remove('hidden'); S.cur = null; S.tab = 'events'; loadAll(); }
  else if (d.action === 'close') { $root.classList.add('hidden'); closeModal(); if (S.timer) { clearInterval(S.timer); S.timer = null; } }
});
document.addEventListener('keydown', e => {
  if ($root.classList.contains('hidden')) return;
  if (e.key === 'Escape') { if (!$modal.classList.contains('hidden')) closeModal(); else rpc('close'); }
});
