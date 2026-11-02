'use strict';
const $ = id => document.getElementById(id);
const esc = s => String(s == null ? '' : s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const post = (n, d) => fetch(`https://${typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'pickax_mechanic'}/${n}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(d || {}) }).then(r => r.json()).catch(() => ({}));
const rng = seed => { let a = seed >>> 0; return () => { a = (a + 0x6D2B79F5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; };
const col = p => p >= 70 ? '#7bd88f' : p >= 40 ? '#f1c40f' : p >= 20 ? '#f39c4a' : '#f28b82';
let D = null, busy = false;
const toast = (m, bad) => { const t = $('toast'); t.textContent = m; t.style.borderColor = bad ? 'var(--bad)' : 'var(--ok)'; t.classList.remove('hidden'); clearTimeout(toast.t); toast.t = setTimeout(() => t.classList.add('hidden'), 3500); };

/* ═════════════════ Diagnostic ═════════════════ */
function renderDiag() {
  const d = D.data, tool = d.tool;
  $('ttl').textContent = `Diagnostic — ${D.name}`; $('sub').textContent = `Plaque ${d.plate} · ${d.km} km au compteur`; $('logo').textContent = '🔧';
  const avg = Math.round(d.order.reduce((s, k) => s + d.cond[k], 0) / d.order.length);
  $('body').innerHTML = `<div class="top"><span class="chip">État général : ${avg} %</span>${tool ? `<span class="chip" style="${tool.have ? '' : 'color:var(--bad)'}">Outil : ${esc(tool.item)} ${tool.have ? '✓' : '✗ manquant'}</span>` : ''}<span class="mut" style="align-self:center">Les pièces s'achètent au magasin de pièces — stock limité.</span></div>
  <div class="grid">${d.order.map(k => { const c = d.components[k], p = d.cond[k], rep = d.repairs[k]; return `<div class="card"><h4><span class="ic">${c.icon}</span>${esc(c.label)}<span style="margin-left:auto;color:${col(p)}">${p} %</span></h4>
    <div class="pbar"><i style="width:${p}%;background:${col(p)}"></i></div>
    ${rep ? `<div class="parts">${rep.parts.map(x => `<div><span>${esc(x.label)} ×${x.need}</span><span class="${x.have >= x.need ? 'ok' : 'bad'}">${x.have} en poche</span></div>`).join('')}</div>
    <button class="btn sm" data-c="${k}" ${rep.can && (!tool || tool.have) ? '' : 'disabled'}>${esc(rep.label)}</button>` : ''}</div>`; }).join('')}</div>`;
  $('body').querySelectorAll('button[data-c]').forEach(b => b.onclick = () => repair(b.dataset.c));
}
async function repair(comp) {
  if (busy) return; busy = true;
  const r = await post('repairBegin', { comp });
  if (!r || !r.ok) { busy = false; return toast((r && r.error) || 'Impossible', true); }
  const score = await ({ bolts: () => runBolts(r.seed, r.bolts || 6, r.seconds, r.label), timing: () => runTiming(r.seed, r.rounds || 3, r.seconds, r.label), inflate: () => runInflate(r.seed, r.rounds || 4, r.seconds, r.label), dents: () => runDents(r.seed, r.bolts || 8, r.seconds, r.label) }[r.game] || (() => Promise.resolve(0)))();
  if (score == null) { busy = false; post('repairCancel'); return toast('Réparation abandonnée : aucune pièce consommée.'); }
  const e = await post('repairEnd', { score });
  busy = false;
  if (!e || !e.ok) return toast((e && e.error) || 'Erreur', true);
  toast(e.msg, !!e.failed);
}
function updateDiag(data) { if (D && D.kind === 'diag') { D.data = data; renderDiag(); } }

/* ═════════════════ Magasin de pièces ═════════════════ */
function fmtT(s) { return s >= 60 ? Math.ceil(s / 60) + ' min' : s + ' s'; }
function renderShop() {
  const d = D.data;
  $('ttl').textContent = d.label; $('sub').textContent = `Solde ${d.account === 'bank' ? 'banque' : 'espèces'} : ${d.balance.toLocaleString('fr-FR')} $ — stock partagé entre tous les mécaniciens`; $('logo').textContent = '📦';
  $('body').innerHTML = `<div class="shop">${d.parts.map(p => `<div class="part ${p.stock <= 0 ? 'out' : ''}"><div><b>${esc(p.label)}</b><div class="mut">${p.price.toLocaleString('fr-FR')} $ l'unité · tu en as ${p.have}</div></div>
    <div><div class="mut">Stock ${p.stock} / ${p.max}</div><div class="stk"><i style="width:${p.stock / p.max * 100}%;background:${p.stock <= 0 ? '#f28b82' : p.stock / p.max < .3 ? '#f1c40f' : 'var(--a)'}"></i></div></div>
    <div class="mut">${p.stock <= 0 ? '<span class="bad">Rupture</span><br>' : ''}${p.nextIn != null ? `+${p.amount} dans ${fmtT(p.nextIn)}` : 'stock plein'}</div>
    <div class="row"><input type="number" min="1" max="${Math.min(d.maxPerOrder, p.stock)}" value="1" id="q_${p.item}" ${p.stock <= 0 ? 'disabled' : ''}><button class="btn sm" data-i="${p.item}" ${p.stock <= 0 ? 'disabled' : ''}>Acheter</button></div></div>`).join('')}</div>`;
  $('body').querySelectorAll('button[data-i]').forEach(b => b.onclick = async () => {
    const q = Number($('q_' + b.dataset.i).value) || 1;
    const r = await post('shopBuy', { item: b.dataset.i, qty: q });
    toast(r && r.ok ? r.msg : ((r && r.error) || 'Erreur'), !(r && r.ok));
    const l = await post('shopList'); if (l && l.ok) { D.data = l; renderShop(); }
  });
}

/* ═════════════════ Mini-jeux ═════════════════ */
let MG = null;
function mgOpen(title, sub, seconds, body) {
  $('mg').classList.remove('hidden'); $('mgt').textContent = title; $('mgs').textContent = sub || ''; $('mgbody').innerHTML = body;
  const total = seconds * 1000, t0 = Date.now(); $('tb').style.width = '100%';
  return new Promise(resolve => {
    const fin = s => { clearInterval(MG.timer); if (MG.cleanup) MG.cleanup(); $('mg').classList.add('hidden'); MG = null; resolve(s); };
    MG = { fin, timer: setInterval(() => { const left = Math.max(0, total - (Date.now() - t0)); $('tb').style.width = (left / total * 100) + '%'; if (left <= 0) fin(MG.score ? MG.score(true) : 0); }, 200) };
    $('mgx').onclick = () => fin(null);
  });
}

/* — Serrage des boulons dans l'ordre (moteur, boîte, suspension) — */
function runBolts(seed, n, seconds, label) {
  const r = rng(seed), W = 560, H = 360, cx = W / 2, cy = H / 2, R = 130;
  const order = Array.from({ length: n }, (_, i) => i).sort(() => r() - .5);   // order[k] = indice du boulon à serrer en k-ième
  const rank = []; order.forEach((b, k) => rank[b] = k + 1);
  const done = new Set(); let next = 1, errors = 0;
  const p = mgOpen(label, 'Serre les boulons dans l\'ordre 1 → ' + n, seconds, `<canvas id="cv" width="${W}" height="${H}"></canvas><p class="hint">Clique les boulons dans l'ordre des numéros (serrage en étoile). Erreurs : <b id="er">0</b></p>`);
  const cv = $('cv'), ctx = cv.getContext('2d');
  const pos = i => { const a = i / n * Math.PI * 2 - Math.PI / 2; return [cx + Math.cos(a) * R, cy + Math.sin(a) * R]; };
  const rot = {};
  function draw() {
    ctx.clearRect(0, 0, W, H);
    ctx.fillStyle = '#26262b'; ctx.beginPath(); ctx.arc(cx, cy, R + 38, 0, 7); ctx.fill();
    ctx.fillStyle = '#17171a'; ctx.beginPath(); ctx.arc(cx, cy, R - 40, 0, 7); ctx.fill();
    for (let i = 0; i < n; i++) {
      const [x, y] = pos(i), ok = done.has(i);
      ctx.save(); ctx.translate(x, y); ctx.rotate(rot[i] || 0);
      ctx.fillStyle = ok ? '#4a8f5c' : '#8a8f98'; ctx.beginPath();
      for (let k = 0; k < 6; k++) { const a = k / 6 * Math.PI * 2; ctx.lineTo(Math.cos(a) * 24, Math.sin(a) * 24); } ctx.closePath(); ctx.fill();
      ctx.fillStyle = '#222'; ctx.beginPath(); ctx.arc(0, 0, 9, 0, 7); ctx.fill(); ctx.restore();
      ctx.fillStyle = ok ? '#bff0c9' : '#fdc27d'; ctx.font = '700 15px Inter,sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.fillText(String(rank[i]), x, y - 36);
    }
  }
  draw();
  const score = () => Math.max(0, Math.round(done.size / n * 100) - errors * 10);
  MG.score = () => score();
  cv.onclick = e => {
    const b = cv.getBoundingClientRect(), mx = (e.clientX - b.left) * W / b.width, my = (e.clientY - b.top) * H / b.height;
    for (let i = 0; i < n; i++) {
      const [x, y] = pos(i); if (Math.hypot(mx - x, my - y) < 28 && !done.has(i)) {
        if (rank[i] === next) { done.add(i); next++; rot[i] = (rot[i] || 0) + 1.6; if (done.size === n) { draw(); return setTimeout(() => MG && MG.fin(score()), 250); } }
        else { errors++; $('er').textContent = errors; }
        draw(); return;
      }
    }
  };
  return p;
}

/* — Arrêt sur la zone (freins, huile) — */
function runTiming(seed, rounds, seconds, label) {
  const r = rng(seed); let round = 0, good = 0, raf = 0, pos = 0, dir = 1, speed = 0.9, zone = [0, 0];
  const res = [];
  const p = mgOpen(label, '', seconds, `<div class="gauge"><div class="zone" id="zn"></div><div class="cursor" id="cs"></div></div><button class="bigbtn" id="stop">STOP (espace)</button><div class="rounds" id="rds"></div><p class="hint">Arrête le curseur dans la zone verte.</p>`);
  MG.score = () => Math.round(good / rounds * 100);
  const newRound = () => { const w = .22 - round * .04, s = .1 + r() * (.8 - w); zone = [s, s + w]; $('zn').style.left = s * 100 + '%'; $('zn').style.width = w * 100 + '%'; speed = .9 + round * .35; pos = 0; dir = 1; $('mgs').textContent = `Manche ${round + 1} / ${rounds}`; $('rds').innerHTML = Array.from({ length: rounds }, (_, i) => `<span class="rd ${res[i] === true ? 'ok' : res[i] === false ? 'no' : ''}"></span>`).join(''); };
  let last = performance.now();
  const loop = t => { const dt = (t - last) / 1000; last = t; pos += dir * speed * dt; if (pos >= 1) { pos = 1; dir = -1; } if (pos <= 0) { pos = 0; dir = 1; } const c = $('cs'); if (c) c.style.left = `calc(${pos * 100}% - 2px)`; raf = requestAnimationFrame(loop); };
  MG.cleanup = () => cancelAnimationFrame(raf);
  const stop = () => { const hit = pos >= zone[0] && pos <= zone[1]; res[round] = hit; if (hit) good++; round++; if (round >= rounds) return MG.fin(Math.round(good / rounds * 100)); newRound(); };
  $('stop').onclick = stop;
  const key = e => { if (e.code === 'Space') { e.preventDefault(); stop(); } }; document.addEventListener('keydown', key);
  const cl = MG.cleanup; MG.cleanup = () => { cl(); document.removeEventListener('keydown', key); };
  newRound(); raf = requestAnimationFrame(loop);
  return p;
}

/* — Gonflage des pneus : maintenir pour monter la pression, relâcher dans la zone — */
function runInflate(seed, rounds, seconds, label) {
  const r = rng(seed); let round = 0, pts = 0, level = 0, holding = false, raf = 0, zone = [0, 0], locked = false;
  const p = mgOpen(label, '', seconds, `<div class="gauge"><div class="zone" id="zn"></div><div class="cursor" id="cs"></div></div><button class="bigbtn" id="pump">MAINTIENS pour gonfler</button><div class="rounds" id="rds"></div><p class="hint">Relâche quand l'aiguille est dans la zone verte (pression correcte). Un pneu par manche.</p>`);
  MG.score = () => Math.round(pts / rounds * 100);
  const res = [];
  const newRound = () => { const w = .14, s = .35 + r() * .45 - w; zone = [s, s + w]; $('zn').style.left = s * 100 + '%'; $('zn').style.width = w * 100 + '%'; level = 0; locked = false; $('mgs').textContent = `Pneu ${round + 1} / ${rounds}`; $('rds').innerHTML = Array.from({ length: rounds }, (_, i) => `<span class="rd ${res[i] === true ? 'ok' : res[i] === false ? 'no' : ''}"></span>`).join(''); };
  let last = performance.now();
  const loop = t => { const dt = (t - last) / 1000; last = t; if (holding && !locked) level = Math.min(1, level + dt * .38); else if (!locked) level = Math.max(0, level - dt * .03); const c = $('cs'); if (c) c.style.left = `calc(${level * 100}% - 2px)`; if (level >= 1 && !locked) release(); raf = requestAnimationFrame(loop); };
  const release = () => { if (locked || level < .02) return; locked = true; const hit = level >= zone[0] && level <= zone[1]; const near = Math.abs(level - (zone[0] + zone[1]) / 2) < .12; res[round] = hit; pts += hit ? 1 : near ? .5 : 0; round++; setTimeout(() => { if (!MG) return; if (round >= rounds) MG.fin(Math.round(pts / rounds * 100)); else newRound(); }, 450); };
  const b = $('pump'); b.onmousedown = () => { holding = true; }; window.onmouseup = () => { if (holding) { holding = false; release(); } };
  MG.cleanup = () => { cancelAnimationFrame(raf); window.onmouseup = null; };
  newRound(); raf = requestAnimationFrame(loop);
  return p;
}

/* — Débosselage : frapper chaque bosse au bon moment — */
function runDents(seed, n, seconds, label) {
  const r = rng(seed), W = 560, H = 340;
  const dents = Array.from({ length: n }, () => ({ x: 60 + r() * (W - 120), y: 50 + r() * (H - 100), rad: 22 + r() * 14, done: false }));
  let cur = 0, hits = 0, t0 = performance.now(), raf = 0, miss = 0;
  const p = mgOpen(label, 'Frappe chaque bosse quand l\'anneau est sur le cercle', seconds, `<canvas id="cv" width="${W}" height="${H}"></canvas><p class="hint">Clique sur la bosse numérotée quand l'anneau se resserre sur son contour. Ratés : <b id="er">0</b></p>`);
  MG.score = () => Math.max(0, Math.round(hits / n * 100) - miss * 4);
  const cv = $('cv'), ctx = cv.getContext('2d');
  const CYCLE = 1500;
  function draw(now) {
    ctx.clearRect(0, 0, W, H);
    const g = ctx.createLinearGradient(0, 0, W, H); g.addColorStop(0, '#4a5a78'); g.addColorStop(1, '#2d3748'); ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
    dents.forEach((d, i) => {
      const grad = ctx.createRadialGradient(d.x - 6, d.y - 6, 2, d.x, d.y, d.rad);
      grad.addColorStop(0, d.done ? 'rgba(255,255,255,.08)' : 'rgba(0,0,0,.55)'); grad.addColorStop(1, 'rgba(0,0,0,0)');
      ctx.fillStyle = grad; ctx.beginPath(); ctx.arc(d.x, d.y, d.rad, 0, 7); ctx.fill();
      if (i === cur && !d.done) {
        ctx.strokeStyle = '#fdc27d'; ctx.lineWidth = 2.5; ctx.beginPath(); ctx.arc(d.x, d.y, d.rad + 2, 0, 7); ctx.stroke();
        const ph = ((now - t0) % CYCLE) / CYCLE, rr = d.rad + 2 + (1 - ph) * 46;
        ctx.strokeStyle = 'rgba(253,194,125,.8)'; ctx.lineWidth = 3; ctx.beginPath(); ctx.arc(d.x, d.y, rr, 0, 7); ctx.stroke();
        ctx.fillStyle = '#fdc27d'; ctx.font = '700 15px Inter'; ctx.textAlign = 'center'; ctx.fillText(String(i + 1), d.x, d.y - d.rad - 10);
      }
    });
    raf = requestAnimationFrame(draw);
  }
  raf = requestAnimationFrame(draw);
  MG.cleanup = () => cancelAnimationFrame(raf);
  cv.onclick = e => {
    const d = dents[cur]; if (!d) return;
    const b = cv.getBoundingClientRect(), mx = (e.clientX - b.left) * W / b.width, my = (e.clientY - b.top) * H / b.height;
    if (Math.hypot(mx - d.x, my - d.y) > d.rad + 10) { miss++; $('er').textContent = miss; return; }
    const ph = ((performance.now() - t0) % CYCLE) / CYCLE;
    if (ph > .8) { d.done = true; hits++; } else { miss++; $('er').textContent = miss; d.done = true; }
    cur++; t0 = performance.now();
    if (cur >= n) setTimeout(() => MG && MG.fin(MG.score()), 250);
  };
  return p;
}

/* ═════════════════ Messages du jeu ═════════════════ */
window.addEventListener('message', e => {
  const d = e.data || {};
  if (d.action === 'diag') { D = { kind: 'diag', data: d.data, name: d.name }; $('win').classList.remove('hidden'); renderDiag(); }
  else if (d.action === 'diagUpdate') updateDiag(d.data);
  else if (d.action === 'shop') { D = { kind: 'shop', data: d.data }; $('win').classList.remove('hidden'); renderShop(); }
  else if (d.action === 'close') { $('win').classList.add('hidden'); $('mg').classList.add('hidden'); if (MG) { clearInterval(MG.timer); if (MG.cleanup) MG.cleanup(); MG = null; } busy = false; }
});
$('closeBtn').onclick = () => post('close');
document.addEventListener('keydown', e => { if (e.key === 'Escape' && !MG) post('close'); });
