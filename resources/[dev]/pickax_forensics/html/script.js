'use strict';
const $ = id => document.getElementById(id);
const esc = s => String(s == null ? '' : s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const post = (n, d) => fetch(`https://${typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'pickax_forensics'}/${n}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(d || {}) }).then(r => r.json()).catch(() => ({}));
const rng = seed => { let a = seed >>> 0; return () => { a = (a + 0x6D2B79F5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; };
const ICON = { casing: '⬮', blood: '💧', print: '☝' };
const KIND = { casing: 'Douille', blood: 'Sang (ADN)', print: 'Empreinte' };

let ST = { items: [], sel: null, lab: {}, busy: false };

/* ═════════════════ Laboratoire ═════════════════ */
function showLab(items, lab) { ST.items = items || []; ST.lab = lab || {}; $('lab').classList.remove('hidden'); setTab('items'); renderItems(); if (!ST.sel || !ST.items.some(i => i.slot === ST.sel)) ST.sel = null; renderDetail(); }
function setTab(t) { document.querySelectorAll('.tab').forEach(b => b.classList.toggle('on', b.dataset.tab === t)); $('tab-items').classList.toggle('hidden', t !== 'items'); $('tab-file').classList.toggle('hidden', t !== 'file'); $('labsub').textContent = t === 'items' ? 'Prélèvements scellés' : 'Fichier balistique'; if (t === 'file') search(''); }
document.querySelectorAll('.tab').forEach(b => b.onclick = () => setTab(b.dataset.tab));

function renderItems() {
  $('items').innerHTML = ST.items.length ? ST.items.map(i => `<div class="it ${i.kind} ${i.slot === ST.sel ? 'sel' : ''}" data-s="${i.slot}"><div class="ic">${ICON[i.kind]}</div><div><b>${esc(i.label)}</b><small>${KIND[i.kind]}</small></div><span class="tag ${i.analysed ? 'done' : ''}">${i.analysed ? 'Analysé' : 'À analyser'}</span></div>`).join('')
    : '<div class="empty">Aucun scellé dans ton inventaire.<br>Récupère douilles, sang et empreintes sur les scènes.</div>';
  $('items').querySelectorAll('.it').forEach(el => el.onclick = () => { ST.sel = Number(el.dataset.s); renderItems(); renderDetail(); });
}

function renderDetail(report) {
  const it = ST.items.find(i => i.slot === ST.sel);
  if (!it) return $('detail').innerHTML = '<div class="empty">Sélectionne un scellé à gauche.</div>';
  const how = { casing: 'Comparaison balistique automatique.', blood: 'Séquençage ADN : complète le brin avant la fin du temps.', print: 'Comparaison d\'empreintes : retrouve la bonne empreinte.' }[it.kind];
  $('detail').innerHTML = `<h3>${esc(it.label)}</h3><div class="sub">${KIND[it.kind]} — ${esc(how)}</div>
    ${it.tries ? `<p class="warn">Échecs précédents : ${it.tries} / ${ST.lab.retries || 2} — au-delà, l'échantillon est dégradé.</p>` : ''}
    ${report ? reportHtml(report) : (it.analysed ? '<p class="ok">Ce scellé a déjà été analysé.</p>' : `<button class="btn" id="analyse" ${ST.busy ? 'disabled' : ''}>Lancer l'analyse</button>`)}`;
  const b = $('analyse'); if (b) b.onclick = () => analyse(it);
}

function reportHtml(r) {
  if (r.degraded) return '<div class="rep"><h4>Résultat</h4><p class="bad">Échantillon dégradé : inexploitable.</p></div>';
  if (r.inconclusive) return `<div class="rep"><h4>Résultat</h4><p class="warn">Analyse non concluante. Il reste ${r.left} tentative(s) sur ce scellé.</p></div>`;
  const row = (a, b) => `<div class="row"><span>${a}</span><span>${b}</span></div>`;
  const matches = (r.matches || []).length ? `<h4>${r.kind === 'casing' ? 'Correspondance balistique' : 'Même individu'} (${r.matches.length})</h4><ul>${r.matches.map(m => `<li>#${m.id} — ${esc(m.at)} — ${esc(m.street || '')}</li>`).join('')}</ul>` : '<h4>Correspondances</h4><p class="hint" style="text-align:left">Aucune autre trace analysée pour le moment.</p>';
  if (r.kind === 'casing') return `<div class="rep"><h4>Rapport de balistique</h4>${row('Arme', esc(String(r.weapon).replace('WEAPON_', '').toLowerCase()))}${row('Calibre', esc(r.caliber))}${row('Signature', `<span class="chip">${esc(r.signature)}</span>`)}${row('Tir enregistré', esc(r.shotAt))}
    ${row('N° de série', r.serial ? esc(r.serial) : '<span class="bad">absent ou limé (non traçable)</span>')}${row('Propriétaire enregistré', r.owner ? esc(r.owner) : 'arme non enregistrée')}${matches}</div>`;
  const id = r.identified ? `<span class="ok">${esc(r.identified)}</span>` : '<span class="warn">individu inconnu — prélève des suspects (/prelever) pour comparer</span>';
  if (r.kind === 'blood') return `<div class="rep"><h4>Analyse ADN</h4>${row('Profil ADN', `<span class="chip">${esc(r.code)}</span>`)}${row('Identification', id)}${r.profiled ? row('Profil enregistré le', esc(r.profiled)) : ''}${row('Prélèvement', '#' + r.id)}${matches}</div>`;
  return `<div class="rep"><h4>Analyse d'empreinte</h4>${row('Empreinte', `<span class="chip">${esc(r.code)}</span>`)}${row('Identification', id)}${row('Véhicule', esc(r.plate || '—'))}${row('Qualité du relevé', (r.quality || 0) + ' %')}${matches}</div>`;
}

async function analyse(it) {
  ST.busy = true; renderDetail();
  const b = await post('labBegin', { slot: it.slot });
  if (!b || !b.ok) { ST.busy = false; renderDetail(); return alert2((b && b.error) || 'Impossible'); }
  let score = null;
  if (b.kind === 'casing') score = await runCasing();
  else if (b.kind === 'blood') score = await runDna(b.seed, ST.lab.dnaBases || 10, ST.lab.dnaSeconds || 30);
  else score = await runPrintMatch(b.seed, ST.lab.printRounds || 3, ST.lab.printSeconds || 20);
  if (score == null) { ST.busy = false; return renderDetail(); }
  const r = await post('labEnd', { score });
  ST.busy = false;
  if (!r || !r.ok) { renderDetail(); return alert2((r && r.error) || 'Analyse refusée'); }
  const l = await post('labList'); if (l && l.ok) { ST.items = l.items; ST.lab = l.lab || ST.lab; }
  renderItems(); renderDetail(r.report);
}
function alert2(m) { $('detail').insertAdjacentHTML('beforeend', `<p class="bad">${esc(m)}</p>`); }

/* ═════════════════ Fichier ═════════════════ */
async function search(q) {
  $('q').value = q || '';
  $('fileOut').innerHTML = '<p class="hint">Recherche…</p>';
  const r = await post('search', { q });
  if (!r || !r.ok) return $('fileOut').innerHTML = '<p class="bad">Indisponible.</p>';
  $('fileOut').innerHTML = r.rows.length ? `<table><thead><tr><th>#</th><th>Arme</th><th>Calibre</th><th>Signature</th><th>N° de série</th><th>Propriétaire</th><th>Lieu</th><th>Date</th></tr></thead><tbody>${r.rows.map(x => `<tr><td>${x.id}</td><td>${esc(String(x.weapon).replace('WEAPON_', '').toLowerCase())}</td><td>${esc(x.caliber)}</td><td><button class="sigb" data-s="${esc(x.signature)}">${esc(x.signature)}</button></td><td>${x.serial ? esc(x.serial) : '<span class="bad">limé</span>'}</td><td>${x.owner ? esc(x.owner) : '—'}</td><td>${esc(x.street || '')}</td><td>${esc(x.shotAt)}</td></tr>`).join('')}</tbody></table>` : '<p class="hint">Aucune douille analysée ne correspond.</p>';
  $('fileOut').querySelectorAll('.sigb').forEach(b => b.onclick = () => search(b.dataset.s));
}
$('go').onclick = () => search($('q').value.trim());
$('q').addEventListener('keydown', e => { if (e.key === 'Enter') search($('q').value.trim()); });
$('closeLab').onclick = () => post('close');

/* ═════════════════ Mini-jeux (overlay) ═════════════════ */
let MG = null;   // { resolve, timer, cleanup }
function mgOpen(title, sub, seconds, body, onFinish) {
  $('mg').classList.remove('hidden'); $('mgt').textContent = title; $('mgs').textContent = sub || ''; $('mgbody').innerHTML = body;
  const total = seconds * 1000, t0 = Date.now(); $('tb').style.width = '100%';
  return new Promise(resolve => {
    const fin = (score) => { clearInterval(MG.timer); document.removeEventListener('keydown', MG.key || (() => {})); $('mg').classList.add('hidden'); MG = null; resolve(score); };
    MG = { timer: setInterval(() => { const left = Math.max(0, total - (Date.now() - t0)); $('tb').style.width = (left / total * 100) + '%'; if (left <= 0) { const s = onFinish ? onFinish(true) : 0; fin(s); } }, 200), fin, onFinish };
    $('mgok').onclick = () => fin(onFinish ? onFinish(false) : 100);
    $('mgx').onclick = () => fin(null);
  });
}

/* — Comparaison balistique : simple barre de progression — */
function runCasing() {
  $('mgok').classList.add('hidden');
  const p = mgOpen('Comparaison balistique', 'Analyse automatique…', 7, '<div class="hint" style="padding:36px 0">Les stries de la douille sont comparées au fichier…</div>', () => 100);
  $('mgok').classList.add('hidden'); $('mgx').classList.add('hidden');
  const t = setTimeout(() => MG && MG.fin(100), 7000);
  return p.then(s => { clearTimeout(t); $('mgok').classList.remove('hidden'); $('mgx').classList.remove('hidden'); return s; });
}

/* — Séquençage ADN : compléter le brin (A-T, C-G) — */
function runDna(seed, n, seconds) {
  const r = rng(seed), B = ['A', 'T', 'C', 'G'], comp = { A: 'T', T: 'A', C: 'G', G: 'C' };
  const strand = Array.from({ length: n }, () => B[Math.floor(r() * 4)]);
  const blank = new Set(); while (blank.size < Math.max(4, Math.round(n * .6))) blank.add(Math.floor(r() * n));
  const answer = strand.map(b => comp[b]), fill = answer.map((a, i) => blank.has(i) ? null : a);
  const order = [...blank].sort((a, b) => a - b); let pos = 0, errors = 0, correct = 0;
  const draw = () => {
    $('mgbody').innerHTML = `<div class="dna"><div class="strand">${strand.map(b => `<div class="base b-${b}">${b}</div>`).join('')}</div>
      <div class="strand">${fill.map((b, i) => b ? `<div class="base b-${b}">${b}</div>` : `<div class="base slot ${order[pos] === i ? 'cur' : ''}" id="s${i}">?</div>`).join('')}</div>
      <div class="keys">${B.map(b => `<button data-b="${b}">${b}</button>`).join('')}</div><p class="hint">Complète le brin du bas : A↔T, C↔G (clavier A T C G ou clics). Erreurs : <b>${errors}</b></p></div>`;
    $('mgbody').querySelectorAll('.keys button').forEach(k => k.onclick = () => press(k.dataset.b));
  };
  const press = b => {
    if (!MG || pos >= order.length) return;
    const i = order[pos];
    if (answer[i] === b) { fill[i] = b; pos++; correct++; draw(); if (pos >= order.length) MG.fin(score()); }
    else { errors++; draw(); const el = $('s' + i); if (el) el.classList.add('err'); }
  };
  const score = () => Math.max(0, Math.round(100 * correct / order.length) - errors * 8);
  const p = mgOpen('Séquençage ADN', `Complète le brin — ${seconds} s`, seconds, '', () => score());
  $('mgok').classList.add('hidden');
  draw();
  MG.key = e => { const k = e.key.toUpperCase(); if (B.includes(k)) press(k); };
  document.addEventListener('keydown', MG.key);
  return p.then(s => { $('mgok').classList.remove('hidden'); return s; });
}

/* — Empreintes : génération déterministe d'un motif papillaire — */
function fpSvg(P, size) {
  const w = 170, h = 200, cx = w / 2 + P.ox, cy = h / 2 + P.oy; let out = '';
  for (let k = 1; k <= P.rings; k++) {
    const rx = 6 + k * P.sp, ry = (8 + k * P.sp) * P.ratio; let d = '';
    for (let a = 0; a <= 64; a++) {
      const t = a / 64 * Math.PI * 2, wob = 1 + P.amp * Math.sin(t * P.freq + P.ph + k * P.drift) * (k / P.rings);
      const x = cx + Math.cos(t) * rx * wob, y = cy + Math.sin(t) * ry * wob - (P.arch ? Math.max(0, Math.sin(t)) * k * P.arch : 0);
      d += (a ? 'L' : 'M') + x.toFixed(1) + ' ' + y.toFixed(1);
    }
    out += `<path d="${d}Z" fill="none" stroke="#d8d8de" stroke-width="${(1.2 + (k % 2) * .5).toFixed(1)}" opacity="${(.45 + k / P.rings * .5).toFixed(2)}"/>`;
  }
  return `<svg viewBox="0 0 ${w} ${h}" width="${size[0]}" height="${size[1]}" style="transform:rotate(${P.rot}deg)">${out}</svg>`;
}
function fpParams(r) { return { rings: 14 + Math.floor(r() * 5), sp: 4.2 + r() * 1.4, ratio: .9 + r() * .35, amp: .05 + r() * .09, freq: 2 + Math.floor(r() * 4), ph: r() * 6.28, drift: r() * .5, arch: Math.floor(r() * 3), ox: Math.round(r() * 8 - 4), oy: Math.round(r() * 8 - 4), rot: 0 }; }

function runPrintMatch(seed, rounds, seconds) {
  const r = rng(seed); let round = 0, good = 0;
  const next = () => {
    const P = fpParams(r), cands = [];
    const correct = Math.floor(r() * 6);
    for (let i = 0; i < 6; i++) {
      if (i === correct) cands.push({ ...P, rot: Math.round(r() * 10 - 5) });
      else cands.push({ ...P, freq: P.freq + (r() > .5 ? 1 : -1), ph: P.ph + 1 + r() * 2, rings: P.rings + Math.floor(r() * 3 - 1), arch: (P.arch + 1 + Math.floor(r() * 2)) % 3, amp: P.amp + .04 + r() * .05, rot: Math.round(r() * 10 - 5) });
    }
    $('mgs').textContent = `Manche ${round + 1} / ${rounds}`;
    $('mgbody').innerHTML = `<div class="fpref"><div><div class="hint" style="margin:0 0 6px">Empreinte relevée</div><div class="fpbig">${fpSvg(P, [170, 200])}</div></div>
      <div><div class="hint" style="margin:0 0 6px">Fichier : laquelle correspond ?</div><div class="fpgrid">${cands.map((c, i) => `<div class="fpc" data-i="${i}">${fpSvg(c, [90, 106])}</div>`).join('')}</div></div></div>`;
    $('mgbody').querySelectorAll('.fpc').forEach(el => el.onclick = () => {
      const i = Number(el.dataset.i); el.classList.add(i === correct ? 'good' : 'bad'); if (i === correct) good++;
      round++; setTimeout(() => { if (!MG) return; if (round >= rounds) MG.fin(Math.round(good / rounds * 100)); else next(); }, 450);
    });
  };
  const p = mgOpen('Comparaison d\'empreintes', '', seconds, '', () => Math.round(good / rounds * 100));
  $('mgok').classList.add('hidden');
  next();
  return p.then(s => { $('mgok').classList.remove('hidden'); return s; });
}

/* — Poudrage (scène) et frottage (nettoyage) : même moteur de brossage — */
function brushGame(mode, seed, seconds) {
  const W = 480, H = 300, r = rng(seed);
  const wrap = document.createElement('div');
  wrap.innerHTML = `<div class="canw"><canvas id="cv" width="${W}" height="${H}"></canvas></div><p class="hint">${mode === 'dust' ? 'Maintiens le clic et passe le pinceau UNIQUEMENT sur l\'empreinte pour la révéler.' : 'Maintiens le clic et frotte pour effacer toutes les traces.'}</p>`;
  const title = mode === 'dust' ? 'Poudrage de l\'empreinte' : 'Nettoyage de la scène';
  const p = mgOpen(title, mode === 'dust' ? 'Révèle l\'empreinte' : 'Efface les traces', seconds, wrap.innerHTML, () => scoreNow());
  const cv = $('cv'), ctx = cv.getContext('2d');
  // calque du fond + calque « poudre / taches »
  const base = document.createElement('canvas'); base.width = W; base.height = H; const bc = base.getContext('2d');
  const top = document.createElement('canvas'); top.width = W; top.height = H; const tc = top.getContext('2d');
  const P = fpParams(r); let ell = null, stains = [];
  bc.fillStyle = mode === 'dust' ? '#2a2a30' : '#8a8f96'; bc.fillRect(0, 0, W, H);
  for (let i = 0; i < 400; i++) { bc.fillStyle = `rgba(255,255,255,${r() * .04})`; bc.fillRect(r() * W, r() * H, 2 + r() * 8, 1 + r() * 3); }
  if (mode === 'dust') {
    ell = { x: W / 2 + (r() * 80 - 40), y: H / 2 + (r() * 30 - 15), rx: 58, ry: 78 };
    const svg = fpSvg({ ...P, ox: 0, oy: 0 }, [170, 200]).replace('<svg ', '<svg xmlns="http://www.w3.org/2000/svg" ');
    const img = new Image(); img.onload = () => { bc.globalAlpha = .95; bc.drawImage(img, ell.x - 85, ell.y - 100, 170, 200); bc.globalAlpha = 1; draw(); }; img.src = 'data:image/svg+xml;utf8,' + encodeURIComponent(svg);
    tc.fillStyle = '#9b9ba3'; tc.fillRect(0, 0, W, H);
  } else {
    for (let i = 0; i < 7; i++) stains.push({ x: 60 + r() * (W - 120), y: 50 + r() * (H - 100), rad: 26 + r() * 30 });
    tc.fillStyle = 'rgba(0,0,0,0)';
    stains.forEach(s => { const g = tc.createRadialGradient(s.x, s.y, 2, s.x, s.y, s.rad); g.addColorStop(0, 'rgba(150,20,25,.95)'); g.addColorStop(.7, 'rgba(120,15,20,.85)'); g.addColorStop(1, 'rgba(120,15,20,0)'); tc.fillStyle = g; tc.beginPath(); tc.arc(s.x, s.y, s.rad, 0, 7); tc.fill(); });
  }
  const orig = tc.getImageData(0, 0, W, H);
  function draw() { ctx.clearRect(0, 0, W, H); ctx.drawImage(base, 0, 0); ctx.drawImage(top, 0, 0); }
  draw();
  let down = false, outside = 0, strokes = 0;
  const pos = e => { const b = cv.getBoundingClientRect(); return [(e.clientX - b.left) * W / b.width, (e.clientY - b.top) * H / b.height]; };
  const brush = e => {
    const [x, y] = pos(e); tc.globalCompositeOperation = 'destination-out'; tc.beginPath(); tc.arc(x, y, mode === 'dust' ? 15 : 22, 0, 7); tc.fill(); tc.globalCompositeOperation = 'source-over';
    strokes++; if (ell && ((x - ell.x) / (ell.rx + 14)) ** 2 + ((y - ell.y) / (ell.ry + 14)) ** 2 > 1) outside++;
    draw();
  };
  cv.onmousedown = e => { down = true; brush(e); }; cv.onmousemove = e => { if (down) brush(e); }; window.onmouseup = () => { down = false; };
  function scoreNow() {
    const cur = tc.getImageData(0, 0, W, H).data, o = orig.data; let tot = 0, gone = 0;
    for (let y = 0; y < H; y += 4) for (let x = 0; x < W; x += 4) {
      if (ell && ((x - ell.x) / ell.rx) ** 2 + ((y - ell.y) / ell.ry) ** 2 > 1) continue;
      const i = (y * W + x) * 4; if (o[i + 3] < 30) continue; tot++; if (cur[i + 3] < o[i + 3] * .35) gone++;
    }
    let s = tot ? gone / tot * 100 : 0;
    if (mode === 'dust') s -= Math.min(40, outside / Math.max(1, strokes) * 80);
    return Math.max(0, Math.round(s));
  }
  if (mode === 'scrub') $('mgok').textContent = 'Terminer le nettoyage';
  if (mode === 'dust') $('mgok').textContent = 'Valider le relevé';
  return p;
}

/* ═════════════════ Messages du jeu ═════════════════ */
window.addEventListener('message', async e => {
  const d = e.data || {};
  if (d.action === 'lab') return showLab(d.items, d.lab);
  if (d.action === 'file') { $('lab').classList.remove('hidden'); setTab('file'); $('q').value = d.q || ''; return search(d.q || ''); }
  if (d.action === 'close') { $('lab').classList.add('hidden'); $('mg').classList.add('hidden'); if (MG) { clearInterval(MG.timer); MG = null; } return; }
  if (d.action === 'mg') {
    const cfg = d.cfg || {};
    const score = await (d.game === 'dust' ? brushGame('dust', cfg.seed || 7, cfg.seconds || 25) : brushGame('scrub', Date.now() % 100000, cfg.seconds || 22));
    post('mgDone', { score });
  }
});
document.addEventListener('keydown', e => { if (e.key === 'Escape' && !MG) post('close'); });
