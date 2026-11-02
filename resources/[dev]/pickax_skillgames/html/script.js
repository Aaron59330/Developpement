'use strict';
const $ = id => document.getElementById(id);
const post = (n, d) => fetch(`https://${typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'pickax_skillgames'}/${n}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(d || {}) }).then(r => r.json()).catch(() => ({}));
const rng = seed => { let a = (seed || (Date.now() % 2147483000)) >>> 0; return () => { a = (a + 0x6D2B79F5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; };
let G = null;   // jeu en cours

function open(title, sub, seconds, body) {
  $('mg').classList.remove('hidden'); $('t').textContent = title; $('s').textContent = sub || ''; $('body').innerHTML = body;
  const total = seconds * 1000, t0 = Date.now(); $('tb').style.width = '100%';
  return new Promise(resolve => {
    const fin = s => { clearInterval(G.timer); if (G.cleanup) G.cleanup(); $('mg').classList.add('hidden'); const sc = s; G = null; resolve(sc); };
    G = { fin, timer: setInterval(() => { const left = Math.max(0, total - (Date.now() - t0)); $('tb').style.width = (left / total * 100) + '%'; if (left <= 0) fin(G.score ? Math.round(G.score(true)) : 0); }, 200) };
    $('cancel').onclick = () => fin(null);
  });
}
const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
const rounds = (n, res) => `<div class="rounds">${Array.from({ length: n }, (_, i) => `<span class="rd ${res[i] === true ? 'ok' : res[i] === false ? 'no' : ''}"></span>`).join('')}</div>`;

/* ── pins : crochetage à goupilles ── */
function gamePins(c) {
  const n = c.pins || 4, dif = clamp(c.difficulty || 3, 1, 5), r = rng(c.seed), set = [], fails = []; let cur = 0, fail = 0;
  const zones = Array.from({ length: n }, () => { const h = .2 - dif * .028, s = .1 + r() * (.8 - h); return [s, s + h]; });
  const sp = Array.from({ length: n }, (_, i) => .8 + dif * .3 + i * .1 + r() * .3);
  const p = open(c.title || 'Crochetage', `Difficulté ${dif} / 5`, c.seconds || 30, `<div class="pins">${zones.map((z, i) => `<div class="pin" id="p${i}"><div class="z" style="top:${z[0] * 100}%;height:${(z[1] - z[0]) * 100}%"></div><div class="c" id="c${i}"></div></div>`).join('')}</div><button class="big" id="go">BLOQUER LA GOUPILLE (espace)</button><p class="hint">Bloque chaque goupille dans la zone verte. 3 erreurs et le crochet casse. Erreurs : <b id="f">0</b></p>`);
  G.score = () => Math.max(0, Math.round(set.filter(Boolean).length / n * 100) - fail * 8);
  let pos = 0, dir = 1, raf = 0, last = performance.now(); const el = i => $('p' + i);
  const mark = () => { for (let i = 0; i < n; i++) el(i).className = 'pin' + (set[i] ? ' set' : '') + (i === cur ? ' cur' : ''); };
  const loop = t => { const dt = (t - last) / 1000; last = t; pos += dir * sp[cur] * dt; if (pos > 1) { pos = 1; dir = -1; } if (pos < 0) { pos = 0; dir = 1; } const ce = $('c' + cur); if (ce) ce.style.top = `calc(${pos * 100}% - 5px)`; raf = requestAnimationFrame(loop); };
  const press = () => { if (cur >= n) return; const z = zones[cur]; if (pos >= z[0] && pos <= z[1]) { set[cur] = true; cur++; pos = 0; dir = 1; mark(); if (cur >= n) return setTimeout(() => G && G.fin(G.score()), 300); } else { fail++; $('f').textContent = fail; if (fail >= 3) return G.fin(G.score()); } };
  $('go').onclick = press; const key = e => { if (e.code === 'Space') { e.preventDefault(); press(); } }; document.addEventListener('keydown', key);
  G.cleanup = () => { cancelAnimationFrame(raf); document.removeEventListener('keydown', key); };
  mark(); raf = requestAnimationFrame(loop); return p;
}

/* ── code : mémoriser puis saisir (piratage) ── */
function gameCode(c) {
  const len = clamp(c.length || 5, 3, 9), r = rng(c.seed), code = Array.from({ length: len }, () => Math.floor(r() * 10)); let typed = [], showing = true;
  const showMs = (c.showSeconds || 3) * 1000;
  const p = open(c.title || 'Piratage', 'Mémorise le code', c.seconds || 25, `<div class="digits" id="dg"></div><div class="pad" id="pad">${[1, 2, 3, 4, 5, 6, 7, 8, 9, '⌫', 0, '✔'].map(k => `<button data-k="${k}">${k}</button>`).join('')}</div><p class="hint" id="hh"></p>`);
  G.score = () => { let ok = 0; typed.forEach((d, i) => { if (d === code[i]) ok++; }); return Math.round(ok / len * 100); };
  const draw = () => { $('dg').innerHTML = code.map((d, i) => `<div class="dg">${showing ? d : (typed[i] != null ? typed[i] : '•')}</div>`).join(''); $('hh').textContent = showing ? 'Mémorise…' : 'Saisis le code'; };
  const me = G; draw(); setTimeout(() => { showing = false; if (G === me) { $('s').textContent = 'Saisis le code'; draw(); } }, showMs);
  $('pad').querySelectorAll('button').forEach(b => b.onclick = () => { if (showing || !G) return; const k = b.dataset.k; if (k === '⌫') typed.pop(); else if (k === '✔') return G.fin(G.score()); else if (typed.length < len) typed.push(Number(k)); draw(); if (typed.length === len && k !== '⌫') setTimeout(() => G && G.fin(G.score()), 250); });
  return p;
}

/* ── wires : relier les câbles de même couleur ── */
function gameWires(c) {
  const n = clamp(c.wires || 5, 3, 7), r = rng(c.seed), COL = ['#e5453b', '#3fa7e8', '#6fd26f', '#f1c40f', '#b06bdc', '#f08a35', '#e8e8e8'].slice(0, n);
  const left = COL.map((x, i) => ({ c: x, i })), right = [...left].sort(() => r() - .5); let sel = null, done = 0, errors = 0;
  const p = open(c.title || 'Piratage', 'Relie les câbles de même couleur', c.seconds || 25, `<div class="wires"><div class="col" id="L"></div><div class="col" id="R"></div></div><p class="hint">Clique un câble à gauche puis son jumeau à droite. Erreurs : <b id="er">0</b></p>`);
  G.score = () => Math.max(0, Math.round(done / n * 100) - errors * 10);
  const draw = () => { $('L').innerHTML = left.map(x => `<div class="node ${x.done ? 'done' : ''} ${sel === x.i ? 'sel' : ''}" data-s="L" data-i="${x.i}" style="background:${x.c}"></div>`).join(''); $('R').innerHTML = right.map(x => `<div class="node ${x.done ? 'done' : ''}" data-s="R" data-i="${x.i}" style="background:${x.c}"></div>`).join(''); document.querySelectorAll('.node').forEach(e => e.onclick = () => click(e.dataset.s, Number(e.dataset.i))); };
  const click = (s, i) => { if (s === 'L') { sel = i; return draw(); } if (sel == null) return; if (sel === i) { left[sel].done = right.find(x => x.i === i).done = true; done++; sel = null; draw(); if (done >= n) setTimeout(() => G && G.fin(G.score()), 250); } else { errors++; $('er').textContent = errors; sel = null; draw(); } };
  draw(); return p;
}

/* ── cpr : compressions au rythme ── */
function gameCpr(c) {
  const bpm = c.bpm || 110, beats = c.beats || 30, iv = 60000 / bpm; let hit = 0, tries = 0, raf = 0; const t0 = performance.now() + 1200; const marks = [];
  const p = open(c.title || 'Massage cardiaque', `${bpm} compressions / min`, (beats * iv) / 1000 + 4, `<canvas id="cv" width="560" height="260"></canvas><button class="big" id="pump" style="margin-top:14px">COMPRESSER (espace)</button><p class="hint">Appuie en rythme quand l'anneau se referme sur le cœur. Compressions réussies : <b id="h">0</b> / ${beats}</p>`);
  G.score = () => Math.round(hit / beats * 100);
  const cv = $('cv'), ctx = cv.getContext('2d');
  const draw = now => { ctx.clearRect(0, 0, 560, 260); const k = (now - t0) / iv; const ph = k - Math.floor(k); const idx = Math.floor(k);
    ctx.fillStyle = '#e5453b'; const s = 1 + (ph < .15 ? (.15 - ph) * 1.5 : 0); ctx.save(); ctx.translate(280, 120); ctx.scale(s, s); ctx.beginPath(); ctx.moveTo(0, 30); ctx.bezierCurveTo(-60, -10, -30, -60, 0, -22); ctx.bezierCurveTo(30, -60, 60, -10, 0, 30); ctx.fill(); ctx.restore();
    if (k >= 0) { const rr = 28 + (1 - ph) * 80; ctx.strokeStyle = 'rgba(253,194,125,.85)'; ctx.lineWidth = 3; ctx.beginPath(); ctx.arc(280, 120, rr, 0, 7); ctx.stroke(); }
    ctx.fillStyle = '#9a9aa5'; ctx.font = '13px Inter'; ctx.textAlign = 'center'; ctx.fillText(`${Math.min(beats, Math.max(0, idx + 1))} / ${beats}`, 280, 235);
    if (idx >= beats + 1) return G.fin(G.score());
    raf = requestAnimationFrame(draw); };
  const press = () => { const now = performance.now(), k = (now - t0) / iv; if (k < -.3) return; const near = Math.abs(k - Math.round(k)) * iv; const b = Math.round(k); if (b < 1 || b > beats || marks[b]) return; marks[b] = true; tries++; if (near < 140) { hit++; $('h').textContent = hit; } };
  $('pump').onclick = press; const key = e => { if (e.code === 'Space') { e.preventDefault(); press(); } }; document.addEventListener('keydown', key);
  G.cleanup = () => { cancelAnimationFrame(raf); document.removeEventListener('keydown', key); };
  raf = requestAnimationFrame(draw); return p;
}

/* ── suture : placer les points le long de la plaie ── */
function gameSuture(c) {
  const n = clamp(c.stitches || 6, 3, 10), r = rng(c.seed), W = 560, H = 300, ph = r() * 6, amp = 25 + r() * 25;
  const pts = Array.from({ length: n }, (_, i) => { const x = 70 + i * (W - 140) / (n - 1); return { x, y: H / 2 + Math.sin(x / 60 + ph) * amp, hit: null }; });
  let cur = 0, miss = 0;
  const p = open(c.title || 'Suture', 'Referme la plaie', c.seconds || 35, `<canvas id="cv" width="${W}" height="${H}"></canvas><p class="hint">Clique chaque point de suture dans l'ordre, le plus près possible du repère. Précision moyenne : <b id="q">—</b></p>`);
  const cv = $('cv'), ctx = cv.getContext('2d'); let sum = 0;
  G.score = () => { const done = pts.filter(x => x.hit != null).length; return Math.max(0, Math.round(sum / n)); };
  const draw = () => { ctx.fillStyle = '#d9a089'; ctx.fillRect(0, 0, W, H); ctx.strokeStyle = '#7a1f1f'; ctx.lineWidth = 12; ctx.lineCap = 'round'; ctx.beginPath(); pts.forEach((q, i) => { if (!i) ctx.moveTo(q.x, q.y); else ctx.lineTo(q.x, q.y); }); ctx.stroke(); ctx.strokeStyle = '#4a0d0d'; ctx.lineWidth = 6; ctx.stroke();
    pts.forEach((q, i) => { if (q.hit) { ctx.strokeStyle = '#1b1b1f'; ctx.lineWidth = 3; ctx.beginPath(); ctx.moveTo(q.hit.x - 9, q.hit.y - 14); ctx.lineTo(q.hit.x + 9, q.hit.y + 14); ctx.moveTo(q.hit.x + 9, q.hit.y - 14); ctx.lineTo(q.hit.x - 9, q.hit.y + 14); ctx.stroke(); } else if (i === cur) { ctx.strokeStyle = '#fdc27d'; ctx.lineWidth = 3; ctx.beginPath(); ctx.arc(q.x, q.y, 13, 0, 7); ctx.stroke(); ctx.fillStyle = '#fdc27d'; ctx.beginPath(); ctx.arc(q.x, q.y, 3, 0, 7); ctx.fill(); } }); };
  cv.onclick = e => { const b = cv.getBoundingClientRect(), mx = (e.clientX - b.left) * W / b.width, my = (e.clientY - b.top) * H / b.height, q = pts[cur]; if (!q) return; const d = Math.hypot(mx - q.x, my - q.y); q.hit = { x: mx, y: my }; sum += clamp(100 - d * 3.2, 0, 100); cur++; $('q').textContent = Math.round(sum / cur) + ' %'; draw(); if (cur >= n) setTimeout(() => G && G.fin(G.score()), 350); };
  draw(); return p;
}

/* ── wrap : bandage (tourner autour du membre à bonne vitesse) ── */
function gameWrap(c) {
  const turns = c.turns || 5, W = 560, H = 300; let acc = 0, last = null, speedOk = 0, samples = 0, down = false;
  const p = open(c.title || 'Bandage', 'Enroule la bande', c.seconds || 25, `<canvas id="cv" width="${W}" height="${H}"></canvas><p class="hint">Maintiens le clic et tourne autour du bras, régulièrement (ni trop vite, ni trop lent). Tours : <b id="tn">0</b> / ${turns}</p>`);
  const cv = $('cv'), ctx = cv.getContext('2d'); const cx = W / 2, cy = H / 2; let t = performance.now();
  G.score = () => Math.round(clamp(acc / (turns * 2 * Math.PI), 0, 1) * 70 + (samples ? speedOk / samples : 0) * 30);
  const draw = () => { ctx.clearRect(0, 0, W, H); ctx.fillStyle = '#d9a089'; ctx.fillRect(cx - 70, 0, 140, H); const prog = clamp(acc / (turns * 2 * Math.PI), 0, 1); ctx.fillStyle = '#f2f2f2'; for (let i = 0; i < Math.floor(prog * 14); i++) { ctx.save(); ctx.translate(cx, 25 + i * 18); ctx.transform(1, .25, 0, 1, 0, 0); ctx.fillRect(-70, -7, 140, 14); ctx.restore(); } ctx.strokeStyle = 'rgba(253,194,125,.35)'; ctx.setLineDash([6, 8]); ctx.beginPath(); ctx.arc(cx, cy, 110, 0, 7); ctx.stroke(); ctx.setLineDash([]); };
  cv.onmousedown = () => { down = true; last = null; }; window.onmouseup = () => { down = false; };
  cv.onmousemove = e => { if (!down) return; const b = cv.getBoundingClientRect(), mx = (e.clientX - b.left) * W / b.width - cx, my = (e.clientY - b.top) * H / b.height - cy; const a = Math.atan2(my, mx), now = performance.now(); if (last != null) { let d = a - last.a; if (d > Math.PI) d -= 2 * Math.PI; if (d < -Math.PI) d += 2 * Math.PI; if (d > 0) { acc += d; const v = d / ((now - last.t) / 1000); samples++; if (v > 1.2 && v < 6) speedOk++; $('tn').textContent = Math.min(turns, Math.floor(acc / (2 * Math.PI))); draw(); if (acc >= turns * 2 * Math.PI) setTimeout(() => G && G.fin(G.score()), 250); } } last = { a, t: now }; };
  G.cleanup = () => { window.onmouseup = null; }; draw(); return p;
}

/* ── timing : arrêter le curseur dans la zone ── */
function gameTiming(c) {
  const n = c.rounds || 3, r = rng(c.seed); let round = 0, good = 0, pos = 0, dir = 1, raf = 0, zone = [0, 0], speed = 1; const res = [];
  const p = open(c.title || 'Précision', '', c.seconds || 25, `<div class="gauge"><div class="zone" id="zn"></div><div class="cursor" id="cs"></div></div><button class="big" id="stop">STOP (espace)</button><div id="rds"></div><p class="hint">Arrête le curseur dans la zone verte.</p>`);
  G.score = () => Math.round(good / n * 100);
  const nr = () => { const w = .22 - round * .03, s = .1 + r() * (.8 - w); zone = [s, s + w]; $('zn').style.left = s * 100 + '%'; $('zn').style.width = w * 100 + '%'; speed = .9 + round * .3 + (c.difficulty || 0) * .15; pos = 0; dir = 1; $('s').textContent = `Manche ${round + 1} / ${n}`; $('rds').innerHTML = rounds(n, res); };
  let last = performance.now(); const loop = t => { const dt = (t - last) / 1000; last = t; pos += dir * speed * dt; if (pos > 1) { pos = 1; dir = -1; } if (pos < 0) { pos = 0; dir = 1; } const e = $('cs'); if (e) e.style.left = `calc(${pos * 100}% - 2px)`; raf = requestAnimationFrame(loop); };
  const stop = () => { const hit = pos >= zone[0] && pos <= zone[1]; res[round] = hit; if (hit) good++; round++; if (round >= n) return G.fin(G.score()); nr(); };
  $('stop').onclick = stop; const key = e => { if (e.code === 'Space') { e.preventDefault(); stop(); } }; document.addEventListener('keydown', key);
  G.cleanup = () => { cancelAnimationFrame(raf); document.removeEventListener('keydown', key); }; nr(); raf = requestAnimationFrame(loop); return p;
}

/* ── hold : garder la jauge sur la cible (cuisson, pêche) ── */
function gameHold(c) {
  const r = rng(c.seed), size = c.size || .22, spd = c.speed || 1; let bar = .3, tgt = .5, tv = 0, prog = 0, holding = false, raf = 0, last = performance.now();
  const p = open(c.title || 'Maîtrise', c.sub || 'Garde la jauge sur la cible', c.seconds || 25, `<canvas id="cv" width="120" height="300" style="margin:0 auto"></canvas><div class="tbar" style="margin-top:12px"><i id="pg" style="width:0"></i></div><p class="hint">Maintiens le clic pour monter, relâche pour descendre. Reste dans la zone pour remplir la jauge.</p>`);
  G.score = () => Math.round(clamp(prog, 0, 1) * 100);
  const cv = $('cv'), ctx = cv.getContext('2d');
  const loop = t => { const dt = Math.min(.05, (t - last) / 1000); last = t; tv += (r() - .5) * 2.4 * spd * dt; tv = clamp(tv, -.5, .5) * .99; tgt = clamp(tgt + tv * dt * 1.6, size / 2, 1 - size / 2); bar = clamp(bar + (holding ? 1 : -.9) * dt * .9, 0, 1);
    const inside = Math.abs(bar - tgt) < size / 2; prog = clamp(prog + (inside ? .16 : -.07) * dt, 0, 1); $('pg').style.width = prog * 100 + '%';
    ctx.clearRect(0, 0, 120, 300); ctx.fillStyle = '#17171a'; ctx.fillRect(30, 0, 60, 300); ctx.fillStyle = 'rgba(123,216,143,.4)'; ctx.fillRect(30, (1 - tgt - size / 2) * 300, 60, size * 300); ctx.fillStyle = '#fdc27d'; ctx.fillRect(22, (1 - bar) * 300 - 4, 76, 8);
    if (prog >= 1) return G.fin(100); raf = requestAnimationFrame(loop); };
  cv.onmousedown = () => { holding = true; }; window.onmouseup = () => { holding = false; }; const key = e => { if (e.code === 'Space') holding = e.type === 'keydown'; }; document.addEventListener('keydown', key); document.addEventListener('keyup', key);
  G.cleanup = () => { cancelAnimationFrame(raf); window.onmouseup = null; document.removeEventListener('keydown', key); document.removeEventListener('keyup', key); };
  raf = requestAnimationFrame(loop); return p;
}

/* ── align : placer le tampon / la photo dans le cadre (faux papiers) ── */
function gameAlign(c) {
  const n = c.rounds || 3, r = rng(c.seed), W = 560, H = 300; let round = 0, sum = 0, tx, ty, mx = 0, my = 0;
  const p = open(c.title || 'Contrefaçon', '', c.seconds || 30, `<canvas id="cv" width="${W}" height="${H}"></canvas><p class="hint">Place le tampon exactement dans le cadre pointillé, puis clique. Précision : <b id="q">—</b></p>`);
  G.score = () => Math.round(sum / n);
  const cv = $('cv'), ctx = cv.getContext('2d');
  const nr = () => { tx = 120 + r() * (W - 240); ty = 70 + r() * (H - 140); $('s').textContent = `Document ${round + 1} / ${n}`; };
  const draw = () => { ctx.clearRect(0, 0, W, H); ctx.fillStyle = '#e8e3d3'; ctx.fillRect(40, 20, W - 80, H - 40); ctx.fillStyle = '#c9c3ad'; for (let i = 0; i < 6; i++) ctx.fillRect(70, 50 + i * 12, 200 - i * 10, 4); ctx.setLineDash([6, 6]); ctx.strokeStyle = '#b3261e'; ctx.lineWidth = 2; ctx.strokeRect(tx - 36, ty - 36, 72, 72); ctx.setLineDash([]); ctx.strokeStyle = 'rgba(40,60,160,.8)'; ctx.lineWidth = 4; ctx.beginPath(); ctx.arc(mx, my, 30, 0, 7); ctx.stroke(); ctx.beginPath(); ctx.moveTo(mx - 14, my); ctx.lineTo(mx + 14, my); ctx.moveTo(mx, my - 14); ctx.lineTo(mx, my + 14); ctx.stroke(); };
  cv.onmousemove = e => { const b = cv.getBoundingClientRect(); mx = (e.clientX - b.left) * W / b.width; my = (e.clientY - b.top) * H / b.height; draw(); };
  cv.onclick = () => { const d = Math.hypot(mx - tx, my - ty); sum += clamp(100 - d * 2.6, 0, 100); round++; $('q').textContent = Math.round(sum / round) + ' %'; if (round >= n) return G.fin(G.score()); nr(); draw(); };
  nr(); draw(); return p;
}

const GAMES = { pins: gamePins, code: gameCode, wires: gameWires, cpr: gameCpr, suture: gameSuture, wrap: gameWrap, timing: gameTiming, hold: gameHold, align: gameAlign };
window.addEventListener('message', async e => {
  const d = e.data || {};
  if (d.action === 'close') { $('mg').classList.add('hidden'); if (G) { clearInterval(G.timer); if (G.cleanup) G.cleanup(); G = null; } return; }
  if (d.action !== 'play') return;
  const f = GAMES[d.game]; if (!f) return post('done', { score: null });
  const score = await f(d.cfg || {});
  post('done', { score });
});
document.addEventListener('keydown', e => { if (e.key === 'Escape' && G) G.fin(null); });
