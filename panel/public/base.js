'use strict';
// ───────── Carte live · Éditeur de base · Événements programmés · Assistant IA ─────────
const SRV = () => curServer();
const needSrv = () => needServer();

// ═══════════════ CARTE LIVE ═══════════════
// Repères connus de Los Santos (coordonnées du jeu) : servent à s'orienter, même sans image de fond
const LANDMARKS = [['Aéroport', -1037, -2737], ['Legion Square', 195, -934], ['Vespucci', -1300, -1500], ['Maze Bank', -75, -818], ['Vinewood', 710, 1200], ['Sandy Shores', 1850, 3700], ['Mont Chiliad', 450, 5570], ['Paleto Bay', -120, 6250], ['Port', 1000, -3000], ['Prison', 1700, 2600]];
const MAP_DEF = { minX: -4100, maxX: 4500, minY: -4400, maxY: 8400 };
const jobColor = j => { if (!j) return '#9aa3b2'; if (/police|lspd|sheriff|gendarm/i.test(j)) return '#5aa9ff'; if (/ambul|ems|medic/i.test(j)) return '#ff6b6b'; if (/unemployed|chomeur/i.test(j)) return '#9aa3b2'; let h = 0; for (const c of j) h = (h * 31 + c.charCodeAt(0)) % 360; return `hsl(${h} 70% 62%)`; };
async function pMap() {
  const s = SRV(); if (!s) return needSrv();
  const key = 'aero_map_' + s.id; let cfgM = { ...MAP_DEF, img: '' }; try { cfgM = { ...cfgM, ...JSON.parse(localStorage.getItem(key) || '{}') }; } catch (e) {}
  const saveCfg = () => { try { localStorage.setItem(key, JSON.stringify(cfgM)); } catch (e) {} };
  let players = [], sel = null, tpMode = false, hover = null; const view = { cx: 0, cy: 0, z: 1 }; const img = new Image(); let imgOk = false; const loadImg = () => { imgOk = false; if (cfgM.img) { img.onload = () => { imgOk = true; draw(); }; img.onerror = () => { imgOk = false; }; img.src = cfgM.img; } };
  const cv = el('canvas', { class: 'mapcv' }), info = el('div', { class: 'mapinfo' }), tip = el('div', { class: 'maptip', hidden: true }); const ctx = cv.getContext('2d');
  const W = () => cv.width, Hh = () => cv.height;
  const fit = () => { const w = cfgM.maxX - cfgM.minX, h = cfgM.maxY - cfgM.minY; view.z = Math.min(W() / w, Hh() / h) * 0.96; view.cx = (cfgM.minX + cfgM.maxX) / 2; view.cy = (cfgM.minY + cfgM.maxY) / 2; };
  const toS = (x, y) => [W() / 2 + (x - view.cx) * view.z, Hh() / 2 - (y - view.cy) * view.z], toW = (px, py) => [view.cx + (px - W() / 2) / view.z, view.cy - (py - Hh() / 2) / view.z];
  function draw() {
    ctx.clearRect(0, 0, W(), Hh()); const dark = getTheme() !== 'clair'; ctx.fillStyle = dark ? '#0b0d12' : '#e9edf3'; ctx.fillRect(0, 0, W(), Hh());
    const [x0, y0] = toS(cfgM.minX, cfgM.maxY), [x1, y1] = toS(cfgM.maxX, cfgM.minY);
    if (imgOk) { ctx.globalAlpha = 0.95; ctx.drawImage(img, x0, y0, x1 - x0, y1 - y0); ctx.globalAlpha = 1; } else { const g = ctx.createLinearGradient(x0, y0, x1, y1); g.addColorStop(0, dark ? '#171b26' : '#dfe5ee'); g.addColorStop(1, dark ? '#0f121a' : '#cfd8e6'); ctx.fillStyle = g; ctx.fillRect(x0, y0, x1 - x0, y1 - y0); }
    ctx.strokeStyle = dark ? 'rgba(255,255,255,.07)' : 'rgba(0,0,0,.08)'; ctx.lineWidth = 1; ctx.font = '10px system-ui'; ctx.fillStyle = dark ? 'rgba(255,255,255,.28)' : 'rgba(0,0,0,.35)';
    const step = view.z > 0.18 ? 500 : view.z > 0.08 ? 1000 : 2000; const lab = view.z > 0.025; for (let gx = Math.ceil(cfgM.minX / step) * step; gx <= cfgM.maxX; gx += step) { const [px] = toS(gx, 0); ctx.beginPath(); ctx.moveTo(px, y0); ctx.lineTo(px, y1); ctx.stroke(); if (lab) ctx.fillText(gx, px + 2, y0 + 10); }
    for (let gy = Math.ceil(cfgM.minY / step) * step; gy <= cfgM.maxY; gy += step) { const [, py] = toS(0, gy); ctx.beginPath(); ctx.moveTo(x0, py); ctx.lineTo(x1, py); ctx.stroke(); if (lab) ctx.fillText(gy, x0 + 2, py - 2); }
    ctx.strokeStyle = 'rgba(253,194,125,.5)'; ctx.strokeRect(x0, y0, x1 - x0, y1 - y0);
    ctx.font = '600 11px system-ui'; for (const [n, lx, ly] of LANDMARKS) { const [px, py] = toS(lx, ly); ctx.fillStyle = dark ? 'rgba(255,255,255,.4)' : 'rgba(0,0,0,.45)'; ctx.beginPath(); ctx.arc(px, py, 2.5, 0, 7); ctx.fill(); ctx.fillText(n, px + 6, py + 4); }
    for (const p of players) { if (p.x == null) continue; const [px, py] = toS(p.x, p.y), c = jobColor(p.job), on = sel && sel.id === p.id;
      if (on) { ctx.strokeStyle = '#fff'; ctx.lineWidth = 2; ctx.beginPath(); ctx.arc(px, py, 13, 0, 7); ctx.stroke(); }
      ctx.save(); ctx.translate(px, py); ctx.rotate(-(p.h || 0) * Math.PI / 180); ctx.fillStyle = c; ctx.strokeStyle = 'rgba(0,0,0,.65)'; ctx.lineWidth = 1.5; ctx.beginPath(); if (p.veh) { ctx.rect(-5, -5, 10, 10); } else { ctx.moveTo(0, -8); ctx.lineTo(6, 6); ctx.lineTo(0, 3); ctx.lineTo(-6, 6); ctx.closePath(); } ctx.fill(); ctx.stroke(); ctx.restore();
      if (view.z > 0.12 || on || hover === p) { ctx.font = '600 11px system-ui'; const t = p.name; const tw = ctx.measureText(t).width; ctx.fillStyle = 'rgba(0,0,0,.65)'; ctx.fillRect(px + 9, py - 8, tw + 8, 16); ctx.fillStyle = '#fff'; ctx.fillText(t, px + 13, py + 4); } }
    if (tpMode) { ctx.fillStyle = 'rgba(253,194,125,.12)'; ctx.fillRect(0, 0, W(), Hh()); }
  }
  const nearest = (mx, my) => { let best = null, bd = 16 * 16; for (const p of players) { if (p.x == null) continue; const [px, py] = toS(p.x, p.y), d = (px - mx) ** 2 + (py - my) ** 2; if (d < bd) { bd = d; best = p; } } return best; };
  const renderInfo = () => {
    const withPos = players.filter(p => p.x != null).length;
    const list = el('div', { class: 'maplist' }, players.slice().sort((a, b) => a.name.localeCompare(b.name)).map(p => el('div', { class: 'mapp' + (sel && sel.id === p.id ? ' on' : ''), onclick: () => { sel = p; if (p.x != null) { view.cx = p.x; view.cy = p.y; if (view.z < 0.3) view.z = 0.5; } renderInfo(); draw(); } }, el('i', { style: 'background:' + jobColor(p.job) }), el('span', {}, p.name), el('small', {}, p.job || ''))));
    const cur = sel && players.find(p => p.id === sel.id); if (!cur) sel = null; else sel = cur;
    info.replaceChildren(...[el('div', { class: 'card' }, el('h2', {}, 'Joueurs (' + withPos + '/' + players.length + ' localisés)'), players.length ? list : el('p', { class: 'muted' }, s.online ? 'Aucun joueur en ligne' : 'Serveur hors ligne')),
      sel ? el('div', { class: 'card' }, el('h2', {}, sel.name), el('p', { class: 'muted' }, `ID ${sel.id} · ${sel.job || '—'} (${sel.grade}) · ${sel.ping} ms`), el('p', { class: 'muted' }, `Liquide ${money(sel.money)} · Banque ${money(sel.bank)}`), sel.x != null ? el('p', { class: 'muted mono' }, `x ${sel.x} · y ${sel.y}${sel.veh ? ' · en véhicule' : ''}`) : null,
        el('div', { class: 'row', style: 'margin-top:8px' },
          el('button', { class: 'btn s' + (tpMode ? ' p' : ''), onclick: () => { tpMode = !tpMode; cv.style.cursor = tpMode ? 'crosshair' : 'grab'; renderInfo(); draw(); if (tpMode) toast('Clique sur la carte pour envoyer ' + sel.name + ' à cet endroit', 'ok'); } }, el('span', {}, tpMode ? 'Annuler la téléportation' : 'Téléporter sur la carte')),
          el('button', { class: 'btn s', onclick: () => ask('Message à ' + sel.name, [{ name: 'message', label: 'Message' }], v => sendCmd('message', { id: sel.id, message: v.message })) }, el('span', {}, 'Message')),
          el('button', { class: 'btn s', onclick: () => sendCmd('revive', { id: sel.id }) }, el('span', {}, 'Réanimer')),
          el('button', { class: 'btn s d', onclick: () => ask('Expulser ' + sel.name, [{ name: 'reason', label: 'Raison', value: 'Expulsé par le staff' }], v => sendCmd('kick', { id: sel.id, reason: v.reason }), 'Expulser') }, el('span', {}, 'Expulser')))) : null,
      el('div', { class: 'card' }, el('h2', {}, 'Légende'), el('p', { class: 'muted' }, '▲ à pied · ■ en véhicule · couleur = métier. Molette : zoom · glisser : déplacer.'),
        el('button', { class: 'btn s', onclick: configMap }, el('span', {}, 'Image de fond…')))].filter(Boolean));
  };
  const configMap = () => ask('Image de fond de la carte', [{ name: 'img', label: 'Adresse (https) de l’image — envoie-la d’abord dans Personnalisation → Drive', value: cfgM.img || '' }, { name: 'minX', label: 'X minimum du jeu', type: 'number', value: cfgM.minX }, { name: 'maxX', label: 'X maximum du jeu', type: 'number', value: cfgM.maxX }, { name: 'minY', label: 'Y minimum du jeu', type: 'number', value: cfgM.minY }, { name: 'maxY', label: 'Y maximum du jeu', type: 'number', value: cfgM.maxY }],
    v => { const num = (x, d) => Number.isFinite(+x) && x !== '' ? +x : d; cfgM = { img: String(v.img || '').trim(), minX: num(v.minX, MAP_DEF.minX), maxX: num(v.maxX, MAP_DEF.maxX), minY: num(v.minY, MAP_DEF.minY), maxY: num(v.maxY, MAP_DEF.maxY) }; if (cfgM.img && !/^https:\/\//.test(cfgM.img)) { toast('L’adresse doit commencer par https://', 'bad'); return false; } saveCfg(); loadImg(); fit(); draw(); });
  let drag = null;
  cv.addEventListener('mousedown', e => { drag = { x: e.offsetX, y: e.offsetY, cx: view.cx, cy: view.cy, moved: false }; });
  window.addEventListener('mouseup', () => { drag = null; }, { once: false });
  cv.addEventListener('mousemove', e => { if (drag) { const dx = e.offsetX - drag.x, dy = e.offsetY - drag.y; if (Math.abs(dx) + Math.abs(dy) > 3) drag.moved = true; if (drag.moved) { view.cx = drag.cx - dx / view.z; view.cy = drag.cy + dy / view.z; draw(); } return; }
    const h = nearest(e.offsetX, e.offsetY); if (h !== hover) { hover = h; draw(); } const [wx, wy] = toW(e.offsetX, e.offsetY); tip.hidden = false; tip.textContent = h ? `${h.name} · ${h.job || ''}` : `x ${Math.round(wx)} · y ${Math.round(wy)}`; });
  cv.addEventListener('mouseleave', () => { tip.hidden = true; });
  cv.addEventListener('click', async e => { if (drag && drag.moved) return; const [wx, wy] = toW(e.offsetX, e.offsetY);
    if (tpMode && sel) { const r = await sendCmd('teleport', { id: sel.id, x: Math.round(wx * 10) / 10, y: Math.round(wy * 10) / 10 }, sel.name + ' va être téléporté'); if (r.ok) { tpMode = false; cv.style.cursor = 'grab'; renderInfo(); draw(); } return; }
    const h = nearest(e.offsetX, e.offsetY); sel = h || null; renderInfo(); draw(); });
  cv.addEventListener('wheel', e => { e.preventDefault(); const [wx, wy] = toW(e.offsetX, e.offsetY); view.z = Math.min(3, Math.max(0.03, view.z * (e.deltaY < 0 ? 1.2 : 1 / 1.2))); view.cx = wx - (e.offsetX - W() / 2) / view.z; view.cy = wy + (e.offsetY - Hh() / 2) / view.z; draw(); }, { passive: false });
  const resize = () => { const r = cv.parentElement.getBoundingClientRect(); if (!r.width) return; cv.width = Math.round(r.width); cv.height = Math.round(Math.max(420, Math.min(760, window.innerHeight - 190))); draw(); };
  const refresh = async () => { const r = await api('GET', `/api/servers/${s.id}/players`); if (r.ok) { players = r.players || []; renderInfo(); draw(); } };
  const wrap = el('div', { class: 'mapwrap' }, cv, tip);
  requestAnimationFrame(() => { resize(); fit(); loadImg(); refresh(); });
  window.addEventListener('resize', resize, { once: true });
  state.timer = setInterval(() => { if (!document.querySelector('.modal') && document.querySelector('.mapcv')) refresh(); }, 4000);
  return el('div', {}, head('Carte live', el('span', { class: 'pill ' + (s.online ? 'ok' : 'bad') }, s.online ? 'Serveur en ligne' : 'Serveur hors ligne'), el('button', { class: 'btn s', onclick: () => { fit(); draw(); } }, el('span', {}, 'Recentrer'))),
    el('div', { class: 'maplayout' }, wrap, info), el('p', { class: 'muted', style: 'margin-top:8px' }, 'Les positions sont mises à jour toutes les 10 secondes environ (cadence d’échange avec le serveur de jeu).'));
}

// ═══════════════ ÉDITEUR DE BASE ═══════════════
async function pEditor() {
  const s = SRV(); if (!s) return needSrv(); let tab = (sessionStorage.getItem('aero_edtab') || 'jobs'); const body = el('div', {});
  const tabs = el('div', { class: 'tabs' }); const draw = () => { sessionStorage.setItem('aero_edtab', tab); tabs.replaceChildren(...[['jobs', 'Métiers & salaires'], ['items', 'Objets']].map(([k, l]) => el('button', { class: 'btn' + (tab === k ? ' on' : ''), onclick: () => { tab = k; draw(); } }, el('span', {}, l)))); body.replaceChildren(el('div', { class: 'card empty' }, 'Chargement…')); (tab === 'jobs' ? edJobs : edItems)(s, body); };
  draw(); return el('div', {}, head('Éditeur de base'), el('p', { class: 'muted', style: 'margin-bottom:12px' }, 'Modifie les métiers, salaires et objets de ton serveur sans ouvrir de fichier. Les modifications des objets sont enregistrées avec historique (restaurables dans Fichiers).'), tabs, body);
}
async function edJobs(s, box) {
  const r = await api('GET', `/api/servers/${s.id}/base/jobs`); if (!r.ok) { box.replaceChildren(el('div', { class: 'card empty' }, r.error || 'Impossible de lire les métiers (serveur hors ligne ?)')); return; }
  let jobs = r.jobs || [], q = '';
  const search = el('input', { placeholder: 'Rechercher un métier…', style: 'max-width:320px', oninput: e => { q = e.target.value.toLowerCase(); list(); } }); const holder = el('div', {});
  const edit = (job, isNew) => {
    const j = JSON.parse(JSON.stringify(job)); const name = el('input', { value: j.name, disabled: !isNew, placeholder: 'ex. mecano (a-z, 0-9, _)' }), label = el('input', { value: j.label }), wl = el('input', { type: 'checkbox', checked: j.whitelisted, style: 'width:auto' }); const gb = el('tbody');
    const row = (g, i) => { const gn = el('input', { type: 'number', value: g.grade, style: 'width:64px' }), nm = el('input', { value: g.name, style: 'min-width:130px' }), lb = el('input', { value: g.label, style: 'min-width:170px' }), sa = el('input', { type: 'number', value: g.salary, style: 'width:100px' });
      const tr = el('tr', {}, el('td', {}, gn), el('td', {}, nm), el('td', {}, lb), el('td', {}, sa), el('td', {}, el('button', { class: 'btn s d', onclick: () => { if (j.grades.length <= 1) return toast('Un métier garde au moins un grade', 'bad'); sync(); j.grades.splice(i, 1); redraw(); } }, el('span', {}, '×')))); tr._g = { gn, nm, lb, sa }; return tr; };
    const rows = []; const sync = () => { j.grades = rows.map(r => ({ grade: +r._g.gn.value, name: r._g.nm.value.trim(), label: r._g.lb.value.trim(), salary: +r._g.sa.value })); };
    const redraw = () => { rows.length = 0; gb.replaceChildren(...j.grades.map((g, i) => { const tr = row(g, i); rows.push(tr); return tr; })); };
    redraw();
    modal(isNew ? 'Nouveau métier' : 'Métier : ' + job.label, el('div', {}, el('label', {}, 'Identifiant (non modifiable après création)'), name, el('label', {}, 'Nom affiché'), label, el('label', { style: 'display:flex;gap:8px;align-items:center;text-transform:none;letter-spacing:0' }, wl, 'Métier sur whitelist (recrutement par le staff)'),
      el('label', {}, 'Grades et salaires (par paie)'), el('div', { class: 'tw' }, el('table', {}, el('thead', {}, el('tr', {}, ['N°', 'Identifiant', 'Libellé', 'Salaire $', ''].map(h => el('th', {}, h)))), gb)),
      el('button', { class: 'btn s', style: 'margin-top:8px', onclick: () => { sync(); const next = (Math.max(-1, ...j.grades.map(g => g.grade)) + 1); j.grades.push({ grade: next, name: 'grade' + next, label: 'Nouveau grade', salary: 0 }); redraw(); } }, el('span', {}, '+ Ajouter un grade'))),
      close => [el('button', { class: 'btn', onclick: close }, el('span', {}, 'Annuler')), el('button', { class: 'btn p', onclick: async () => { sync(); const res = await api('POST', `/api/servers/${s.id}/base/jobs`, { job: { name: name.value.trim(), label: label.value.trim(), whitelisted: wl.checked, grades: j.grades } }); if (!res.ok) { toast(res.error, 'bad'); return; } toast('Métier enregistré et rechargé en jeu', 'ok'); close(); edJobs(s, box); } }, el('span', {}, 'Enregistrer'))]);
  };
  const list = () => { const rows = jobs.filter(j => !q || (j.name + ' ' + j.label).toLowerCase().includes(q));
    holder.replaceChildren(el('div', { class: 'grid g3' }, rows.map(j => el('div', { class: 'card', style: 'margin:0;cursor:pointer', onclick: () => edit(j, false) }, el('h2', {}, j.label), el('p', { class: 'muted mono' }, j.name + (j.whitelisted ? ' · whitelist' : '')), el('p', { class: 'muted' }, j.grades.length + ' grade(s) · salaires de ' + money(Math.min(...j.grades.map(g => g.salary))) + ' à ' + money(Math.max(...j.grades.map(g => g.salary)))))), rows.length ? null : el('div', { class: 'empty' }, 'Aucun métier')) ); };
  list(); box.replaceChildren(el('div', { class: 'row', style: 'margin-bottom:12px' }, search, el('div', { class: 'grow' }), el('button', { class: 'btn p', onclick: () => edit({ name: '', label: '', whitelisted: false, grades: [{ grade: 0, name: 'recrue', label: 'Recrue', salary: 300 }] }, true) }, el('span', {}, 'Nouveau métier'))), holder);
}
async function edItems(s, box) {
  const r = await api('GET', `/api/servers/${s.id}/base/items`); if (!r.ok) { box.replaceChildren(el('div', { class: 'card empty' }, r.error || 'Impossible de lire les objets (serveur hors ligne ?)')); return; }
  const orig = new Map((r.items || []).map(i => [i.name, { ...i }])); const cur = new Map((r.items || []).map(i => [i.name, { ...i }])); let q = '';
  const tb = el('tbody'), saveBtn = el('button', { class: 'btn p', onclick: save }, el('span', {})), count = () => [...cur.values()].filter(i => { const o = orig.get(i.name); return o && (o.label !== i.label || +o.weight !== +i.weight || o.stack !== i.stack || o.close !== i.close); });
  const upd = () => { const n = count().length; saveBtn.firstChild.textContent = n ? `Enregistrer (${n})` : 'Aucune modification'; saveBtn.disabled = !n; };
  const draw = () => { const rows = [...cur.values()].filter(i => !q || (i.name + ' ' + i.label).toLowerCase().includes(q)); tb.replaceChildren(...rows.slice(0, 400).map(i => { const lb = el('input', { value: i.label, oninput: e => { i.label = e.target.value; upd(); } }), wt = el('input', { type: 'number', value: i.weight, style: 'width:100px', oninput: e => { i.weight = +e.target.value; upd(); } }), st = el('input', { type: 'checkbox', checked: i.stack, style: 'width:auto', onchange: e => { i.stack = e.target.checked; upd(); } }), cl = el('input', { type: 'checkbox', checked: i.close, style: 'width:auto', onchange: e => { i.close = e.target.checked; upd(); } });
    return el('tr', {}, el('td', { class: 'mono muted' }, i.name), el('td', {}, lb), el('td', {}, wt), el('td', {}, st), el('td', {}, cl)); }), rows.length > 400 ? el('tr', {}, el('td', { colspan: 5, class: 'muted' }, 'Affine la recherche : 400 objets affichés au maximum')) : null); };
  async function save() { const changes = count().map(i => ({ name: i.name, label: i.label, weight: i.weight, stack: i.stack, close: i.close })); const x = await api('POST', `/api/servers/${s.id}/base/items`, { changes }); if (!x.ok) return toast(x.error, 'bad'); toast(x.changed + ' objet(s) enregistré(s)', 'ok'); afterSave(); edItems(s, box); }
  const afterSave = () => confirmBox('Appliquer en jeu ?', 'Les nouveaux noms et poids ne sont pris en compte qu’après le redémarrage de l’inventaire (ox_inventory). Les joueurs connectés seront brièvement déconnectés de leur inventaire. Le faire maintenant ?', async () => { await sendCmd('restart_resource', { resource: 'ox_inventory' }, 'Redémarrage de l’inventaire lancé'); });
  const addItem = () => ask('Nouvel objet', [{ name: 'name', label: 'Identifiant (a-z, 0-9, _)' }, { name: 'label', label: 'Nom affiché' }, { name: 'weight', label: 'Poids (en grammes)', type: 'number', value: 100 }], async v => { const x = await api('POST', `/api/servers/${s.id}/base/items`, { add: [{ name: v.name.trim(), label: v.label.trim(), weight: +v.weight }] }); if (!x.ok) { toast(x.error, 'bad'); return false; } toast('Objet ajouté', 'ok'); afterSave(); edItems(s, box); }, 'Ajouter');
  const search = el('input', { placeholder: 'Rechercher (nom ou identifiant)…', style: 'max-width:320px', oninput: e => { q = e.target.value.toLowerCase(); draw(); } });
  draw(); upd();
  box.replaceChildren(el('div', { class: 'row', style: 'margin-bottom:12px' }, search, el('span', { class: 'pill acc' }, cur.size + ' objets'), r.other ? el('span', { class: 'muted' }, r.other + ' objet(s) complexe(s) à modifier dans Fichiers') : null, el('div', { class: 'grow' }), saveBtn, el('button', { class: 'btn', onclick: addItem }, el('span', {}, 'Nouvel objet'))),
    el('div', { class: 'card tw' }, el('table', {}, el('thead', {}, el('tr', {}, ['Identifiant', 'Nom affiché', 'Poids (g)', 'Empilable', 'Ferme l’inventaire'].map(h => el('th', {}, h)))), tb)));
}

// ═══════════════ ÉVÉNEMENTS PROGRAMMÉS ═══════════════
const SCH_TYPES = { announce: 'Annonce aux joueurs', server_restart: 'Redémarrage du serveur', restart_resource: 'Redémarrage d’une ressource', economy_event: 'Événement d’économie', economy_reset: 'Fin des événements d’économie' };
const EVERY = { none: 'Une seule fois', daily: 'Tous les jours', weekly: 'Toutes les semaines' };
const schSummary = x => { const p = x.payload || {}; return x.type === 'announce' ? '« ' + p.message + ' »' : x.type === 'restart_resource' ? p.resource : x.type === 'economy_event' ? `gains ${p.swing >= 0 ? '+' : ''}${Math.round(p.swing * 100)} % pendant ${p.hours} h` : x.type === 'economy_reset' ? 'retour à la normale' : 'préavis aux joueurs puis redémarrage'; };
const toLocalInput = t => { const d = new Date(t * 1000), p = n => String(n).padStart(2, '0'); return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}T${p(d.getHours())}:${p(d.getMinutes())}`; };
async function pPlanner() {
  const s = SRV(); if (!s) return needSrv(); const r = await api('GET', `/api/servers/${s.id}/schedules`); const rows = r.schedules || [];
  const open = (x, edit) => {
    const e = x || {}; const nm = el('input', { value: e.name || '', placeholder: 'ex. Double paie du samedi' }), ty = el('select', {}, Object.entries(SCH_TYPES).map(([k, l]) => el('option', { value: k, selected: k === (e.type || 'announce') }, l))), at = el('input', { type: 'datetime-local', value: toLocalInput(e.run_at || (Date.now() / 1000 + 3600)) }),
      ev = el('select', {}, Object.entries(EVERY).map(([k, l]) => el('option', { value: k, selected: k === (e.every || 'none') }, l))), wn = el('select', {}, [0, 5, 10, 15, 30, 60].map(m => el('option', { value: m, selected: m === (e.warn_min || 0) }, m ? m + ' min avant' : 'Aucun préavis')));
    const p = e.payload || {}; const msg = el('input', { value: p.message || '', placeholder: 'Message affiché aux joueurs' }), res = el('input', { value: p.resource || '', placeholder: 'ex. ox_inventory' }), sw = el('input', { type: 'number', step: '0.05', value: p.swing != null ? p.swing : 1 }), hr = el('input', { type: 'number', value: p.hours || 4 }), key = el('input', { value: p.key || 'all', placeholder: 'all = toute l’économie' });
    const dyn = el('div', {}); const showF = () => { const t = ty.value; dyn.replaceChildren(...(t === 'announce' ? [el('label', {}, 'Message'), msg] : t === 'restart_resource' ? [el('label', {}, 'Ressource'), res] : t === 'economy_event' ? [el('label', {}, 'Cible (all ou une clé d’économie)'), key, el('label', {}, 'Variation des gains (1 = +100 %, -0.3 = -30 %)'), sw, el('label', {}, 'Durée (heures)'), hr] : t === 'economy_reset' ? [el('p', { class: 'muted' }, 'Annule tous les événements d’économie en cours.')] : [el('p', { class: 'muted' }, 'Les joueurs sont prévenus avant le redémarrage (délai réglé dans pickax_panel).')])); }; ty.addEventListener('change', showF); showF();
    modal(edit ? 'Modifier l’événement' : 'Nouvel événement', el('div', {}, el('label', {}, 'Nom'), nm, el('label', {}, 'Action'), ty, dyn, el('label', {}, 'Date et heure (ton fuseau horaire)'), at, el('label', {}, 'Répétition'), ev, el('label', {}, 'Préavis aux joueurs'), wn),
      close => [el('button', { class: 'btn', onclick: close }, el('span', {}, 'Annuler')), el('button', { class: 'btn p', onclick: async () => { const t = ty.value; const payload = t === 'announce' ? { message: msg.value } : t === 'restart_resource' ? { resource: res.value.trim() } : t === 'economy_event' ? { key: key.value.trim() || 'all', swing: +sw.value, hours: +hr.value } : t === 'economy_reset' ? { key: '' } : {};
        const body = { name: nm.value, type: t, payload, run_at: Math.floor(new Date(at.value).getTime() / 1000), every: ev.value, warn_min: +wn.value }; const res2 = edit ? await api('PATCH', `/api/servers/${s.id}/schedules/${x.id}`, body) : await api('POST', `/api/servers/${s.id}/schedules`, body); if (!res2.ok) { toast(res2.error, 'bad'); return; } toast('Événement enregistré', 'ok'); close(); render(); } }, el('span', {}, 'Enregistrer'))]);
  };
  const tpl = (name, type, payload, every) => ({ name, type, payload, run_at: Math.floor(Date.now() / 1000) + 3600, every: every || 'none', warn_min: 0 });
  const quick = [['Double paie 4 h', tpl('Double paie', 'economy_event', { key: 'all', swing: 1, hours: 4 })], ['Redémarrage quotidien', tpl('Redémarrage quotidien', 'server_restart', {}, 'daily')], ['Annonce récurrente', tpl('Rappel règlement', 'announce', { message: 'Pensez à lire le règlement !' }, 'daily')]];
  return el('div', {}, head('Événements programmés', el('button', { class: 'btn p', onclick: () => open(null, false) }, el('span', {}, 'Nouvel événement'))),
    el('p', { class: 'muted', style: 'margin-bottom:12px' }, 'Planifie annonces, redémarrages et événements d’économie : ils partent tout seuls à l’heure choisie (le serveur doit être en ligne, tolérance 15 minutes).'),
    el('div', { class: 'row', style: 'margin-bottom:12px' }, el('span', { class: 'muted' }, 'Modèles :'), quick.map(([l, t]) => el('button', { class: 'btn s', onclick: () => open(t, false) }, el('span', {}, l)))),
    el('div', { class: 'card tw' }, rows.length ? el('table', {}, el('thead', {}, el('tr', {}, ['Événement', 'Action', 'Prochaine exécution', 'Répétition', 'Dernier résultat', ''].map(h => el('th', {}, h)))), el('tbody', {}, rows.map(x => el('tr', { style: x.enabled ? '' : 'opacity:.55' },
      el('td', {}, el('b', {}, x.name), x.warn_min ? el('div', { class: 'muted' }, 'préavis ' + x.warn_min + ' min') : null), el('td', {}, SCH_TYPES[x.type], el('div', { class: 'muted' }, schSummary(x))), el('td', {}, x.enabled || x.every !== 'none' ? fmtDate(x.run_at) : el('span', { class: 'muted' }, 'terminé')), el('td', {}, EVERY[x.every]), el('td', { class: 'muted' }, x.last_run ? fmtDate(x.last_run) + ' · ' + x.last_status : '—'),
      el('td', {}, el('div', { class: 'row' }, el('button', { class: 'btn s', onclick: () => open(x, true) }, el('span', {}, 'Modifier')), el('button', { class: 'btn s', onclick: async () => { const y = await api('PATCH', `/api/servers/${s.id}/schedules/${x.id}`, { enabled: !x.enabled }); if (!y.ok) toast(y.error, 'bad'); render(); } }, el('span', {}, x.enabled ? 'Mettre en pause' : 'Réactiver')), el('button', { class: 'btn s d', onclick: () => confirmBox('Supprimer', `Supprimer « ${x.name} » ?`, async () => { await api('DELETE', `/api/servers/${s.id}/schedules/${x.id}`, {}); render(); }, true) }, el('span', {}, '×'))))))))
      : el('div', { class: 'empty' }, 'Aucun événement programmé')));
}

// ═══════════════ ASSISTANT IA ═══════════════
async function pAssistant() {
  const s = SRV(); if (!s) return needSrv(); const st = await api('GET', `/api/servers/${s.id}/assistant/status`);
  const log = el('div', { class: 'chat' }), input = el('textarea', { rows: 2, placeholder: 'Ex. « Lance une double paie samedi à 20h pendant 4 heures et préviens les joueurs 15 minutes avant »', style: 'resize:vertical' }); let history = [];
  const bubble = (who, text, extra) => { const b = el('div', { class: 'bub ' + who }, el('div', {}, text), extra || null); log.append(b); log.scrollTop = log.scrollHeight; return b; };
  const actionCard = a => { const btn = el('button', { class: 'btn s p' }, el('span', {}, 'Appliquer')); btn.onclick = async () => { btn.disabled = true; const r = await api('POST', `/api/servers/${s.id}/assistant/apply`, { type: a.type, payload: a.payload }); if (r.ok) { btn.firstChild.textContent = 'Appliqué ✓'; toast('Action appliquée', 'ok'); } else { btn.disabled = false; toast(r.error, 'bad'); } };
    return el('div', { class: 'act' }, el('div', {}, el('b', {}, a.label), el('div', { class: 'muted mono' }, a.type === 'schedule' ? `${SCH_TYPES[a.payload.type]} · ${fmtDate(a.payload.run_at)} · ${EVERY[a.payload.every]}` : a.type === 'set_setting' ? `${a.payload.key} = ${JSON.stringify(a.payload.value)}` : JSON.stringify(a.payload))), btn); };
  const send = async () => { const m = input.value.trim(); if (!m) return; input.value = ''; bubble('me', m); const wait = bubble('ai', 'Je réfléchis…'); const d = new Date(), p = n => String(n).padStart(2, '0');
    const r = await api('POST', `/api/servers/${s.id}/assistant`, { message: m, history, tz: d.getTimezoneOffset(), local_now: `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}` }); wait.remove();
    if (!r.ok) { bubble('ai bad', r.error || 'Erreur'); return; } history.push({ role: 'user', text: m }, { role: 'assistant', text: r.reply || '' });
    const acts = r.actions || []; const all = acts.length > 1 ? el('button', { class: 'btn s', onclick: async e => { for (const a of acts) { const x = await api('POST', `/api/servers/${s.id}/assistant/apply`, { type: a.type, payload: a.payload }); if (!x.ok) { toast(x.error, 'bad'); return; } } e.target.closest('button').firstChild.textContent = 'Tout appliqué ✓'; toast('Actions appliquées', 'ok'); } }, el('span', {}, 'Tout appliquer')) : null;
    bubble('ai', r.reply || 'Voici ce que je propose :', acts.length ? el('div', { class: 'acts' }, acts.map(actionCard), all) : null); if ((r.dropped || []).length) bubble('ai warn', 'Une partie de ma proposition a été écartée car non autorisée ou invalide : ' + r.dropped.join(' · ')); };
  input.addEventListener('keydown', e => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); send(); } });
  bubble('ai', 'Bonjour ! Dis-moi ce que tu veux faire sur ton serveur : annonces, événements d’économie, redémarrages, réglages, planification. Je te propose des actions précises que tu valides d’un clic, je ne fais rien sans ton accord.');
  const examples = ['Annonce que le serveur redémarre dans 10 minutes', 'Programme un redémarrage tous les jours à 5h avec préavis de 10 minutes', 'Lance une double paie ce week-end', 'Quels réglages puis-je modifier ?'];
  return el('div', {}, head('Assistant IA', st.enabled ? el('span', { class: 'pill acc' }, `${st.used}/${st.limit} demandes aujourd’hui`) : el('span', { class: 'pill bad' }, 'Non configuré')),
    st.enabled ? null : el('div', { class: 'card' }, el('p', {}, 'L’assistant n’est pas activé sur ce panel : la clé ', el('span', { class: 'mono' }, 'ANTHROPIC_API_KEY'), ' manque dans le fichier .env du panel.')),
    el('div', { class: 'card' }, log, el('div', { class: 'row', style: 'margin-top:10px' }, examples.map(x => el('button', { class: 'btn s', onclick: () => { input.value = x; input.focus(); } }, el('span', {}, x)))), el('div', { style: 'margin-top:10px' }, input), el('div', { style: 'margin-top:8px' }, el('button', { class: 'btn p', onclick: send }, el('span', {}, 'Envoyer')))));
}
Object.assign(window.PAGES, { map: pMap, editor: pEditor, planner: pPlanner, assistant: pAssistant });
