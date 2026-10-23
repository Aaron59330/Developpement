/* ═══════════ Jeux (suite), Taxi, Actualités, Loto, Convertisseur ═══════════ */

/* ───────────── Jeux : menu, classements et nouveaux jeux ───────────── */
const GAME_LIST = [
  { id: 'snake', name: 'Snake', ic: 'swipe', color: '#30d158', fn: 'snake', unit: 'pts' },
  { id: '2048', name: '2048', ic: 'grid', color: '#ff9f0a', fn: 'g2048', unit: 'pts' },
  { id: 'mines', name: 'Démineur', ic: 'flag', color: '#ff453a', fn: 'mines', unit: 'pts' },
  { id: 'c4', name: 'Puissance 4', ic: 'circle', color: '#0a84ff', fn: 'c4', unit: 'victoires' },
  { id: 'flappy', name: 'Flappy', ic: 'plane', color: '#64d2ff', fn: 'flappy', unit: 'pts' },
  { id: 'memory', name: 'Mémoire', ic: 'star', color: '#bf5af2', fn: 'memory', unit: 'pts' },
  { id: 'ttt', name: 'Morpion', ic: 'x', color: '#5e5ce6', fn: 'ttt', unit: 'victoires' },
];
Games.submit = function (game, score) { if (score > 0) rpc('scoreSubmit', game, Math.floor(score)); };
Games.open = async function (ctx) {
  this.ctx = ctx; this.scores = (await rpc('kvGet', 'scores')) || {};
  const pg = Page({ title: 'Jeux' }); pg.el.classList.add('dark'); ctx.root(pg);
  const grid = h('div', { style: 'display:grid;grid-template-columns:1fr 1fr;gap:12px;padding:0 16px 16px' });
  GAME_LIST.forEach(g => grid.appendChild(h('button.gcard', { style: `background:linear-gradient(145deg, ${g.color}, #111)`, onclick: () => this[g.fn]() }, h('span', { html: icon(g.ic, 34) }), h('b', g.name), h('small', 'Record : ' + (this.scores[g.id] || 0)))));
  pg.body.appendChild(grid);
  pg.body.appendChild(Group(null, [{ icon: 'dice', color: '#ff9f0a', title: 'Dés et pile ou face', chev: true, onclick: () => this.dice() }, { icon: 'trophy', color: '#ffd60a', title: 'Classements du serveur', chev: true, onclick: () => this.board() }]));
};
Games.board = function (gid) {
  const pg = Page({ title: 'Classements', back: 'Jeux' }); pg.el.classList.add('dark');
  const cur = gid || 'snake';
  pg.body.appendChild(h('div', { style: 'display:flex;gap:8px;overflow:auto;padding:0 16px 12px' }, GAME_LIST.map(g => h('button.chip', { style: g.id === cur ? 'background:var(--accent);color:#fff' : '', onclick: () => { this.ctx.pop(); this.board(g.id); } }, g.name))));
  const wrap = h('div', Spinner()); pg.body.appendChild(wrap);
  rpc('scoreTop', cur).then(rows => { clear(wrap); rows = rows || []; wrap.appendChild(rows.length ? Group(null, rows.map((r, i) => ({ left: h('b', { style: 'width:26px;text-align:center;color:' + (i === 0 ? '#ffd60a' : i === 1 ? '#c0c0c0' : i === 2 ? '#cd7f32' : 'var(--fg2)') }, i + 1), title: h('span', { style: r.me ? 'color:var(--accent);font-weight:600' : '' }, r.name + (r.me ? ' (vous)' : '')), value: String(r.score) }))) : Empty('trophy', 'Aucun score', 'Soyez le premier !')); });
  this.ctx.push(pg);
};
Games.page = function (title, build, onClose) {
  const pg = Page({ title, large: false, back: 'Jeux', right: [{ icon: 'trophy', onclick: () => { const g = GAME_LIST.find(x => x.name === title); this.board(g && g.id); } }], onClose }); pg.el.classList.add('dark');
  build(pg); this.ctx.push(pg); return pg;
};
Games.best = function (id, score) { if (score > (this.scores[id] || 0)) { this.scores[id] = score; this.save(); } this.submit(id, score); };

/* 2048 */
Games.g2048 = function () {
  let g, score, over, won;
  const board = h('div.g2048'), sc = h('div', { style: 'text-align:center;font-size:20px;font-weight:700;margin:6px 0' });
  const COL = { 0: '#2a2a2e', 2: '#eee4da', 4: '#ede0c8', 8: '#f2b179', 16: '#f59563', 32: '#f67c5f', 64: '#f65e3b', 128: '#edcf72', 256: '#edcc61', 512: '#edc850', 1024: '#edc53f', 2048: '#edc22e' };
  const spawn = () => { const e = []; g.forEach((r, y) => r.forEach((v, x) => !v && e.push([y, x]))); if (!e.length) return; const [y, x] = e[Math.floor(Math.random() * e.length)]; g[y][x] = Math.random() < .9 ? 2 : 4; };
  const draw = () => { clear(board); g.forEach(r => r.forEach(v => board.appendChild(h('div', { style: `background:${COL[v] || '#3c3a32'};color:${v <= 4 ? '#776e65' : '#fff'};font-size:${v > 999 ? 20 : v > 99 ? 26 : 32}px` }, v || '')))); sc.textContent = 'Score : ' + score + (over ? ' — Partie terminée' : won ? ' — 2048 !' : ''); };
  const slide = (row) => { const a = row.filter(Boolean), out = []; for (let i = 0; i < a.length; i++) { if (a[i] === a[i + 1]) { out.push(a[i] * 2); score += a[i] * 2; if (a[i] * 2 === 2048) won = true; i++; } else out.push(a[i]); } while (out.length < 4) out.push(0); return out; };
  const move = (d) => {
    if (over) return; const before = JSON.stringify(g);
    const rot = (m) => m[0].map((_, i) => m.map(r => r[i]).reverse());
    let m = g; const times = { left: 0, up: 3, right: 2, down: 1 }[d]; for (let i = 0; i < times; i++) m = rot(m);
    m = m.map(slide); for (let i = 0; i < (4 - times) % 4; i++) m = rot(m); g = m;
    if (JSON.stringify(g) !== before) { spawn(); }
    const full = g.every(r => r.every(Boolean)); const can = g.some((r, y) => r.some((v, x) => (r[x + 1] === v) || (g[y + 1] && g[y + 1][x] === v)));
    if (full && !can) { over = true; this.best('2048', score); }
    draw();
  };
  const reset = () => { g = Array.from({ length: 4 }, () => Array(4).fill(0)); score = 0; over = false; won = false; spawn(); spawn(); draw(); };
  const pad = h('div', { style: 'display:grid;grid-template-columns:repeat(3,64px);gap:8px;justify-content:center;margin-top:14px' });
  [['', ''], ['↑', 'up'], ['', ''], ['←', 'left'], ['↓', 'down'], ['→', 'right']].forEach(b => pad.appendChild(b[0] ? h('button.btn.sec', { style: 'height:54px', onclick: () => move(b[1]) }, b[0]) : h('div')));
  const pg = this.page('2048', p => { p.body.appendChild(sc); p.body.appendChild(board); p.body.appendChild(pad); p.body.appendChild(h('div', { style: 'padding:14px 16px' }, h('button.btn.block', { onclick: reset }, 'Nouvelle partie'))); });
  const key = e => { if (!$('.g2048')) { document.removeEventListener('keydown', key); return; } const m = { ArrowUp: 'up', z: 'up', ArrowDown: 'down', s: 'down', ArrowLeft: 'left', q: 'left', ArrowRight: 'right', d: 'right' }[e.key]; if (m && e.target.tagName !== 'INPUT') { e.preventDefault(); move(m); } };
  document.addEventListener('keydown', key);
  let sx, sy; board.addEventListener('pointerdown', e => { sx = e.clientX; sy = e.clientY; }); board.addEventListener('pointerup', e => { const dx = e.clientX - sx, dy = e.clientY - sy; if (Math.max(Math.abs(dx), Math.abs(dy)) < 20) return; move(Math.abs(dx) > Math.abs(dy) ? (dx > 0 ? 'right' : 'left') : (dy > 0 ? 'down' : 'up')); });
  reset();
};

/* Démineur */
Games.mines = function () {
  const W = 9, H = 9, M = 10; let cells, over, flagMode = false, left, t0, timer, started;
  const grid = h('div.mines'), info = h('div', { style: 'text-align:center;margin:8px 0;font-size:18px' });
  const near = (x, y, f) => { for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) { if (dx || dy) { const c = cells[y + dy] && cells[y + dy][x + dx]; if (c) f(c); } } };
  const reset = () => { clearInterval(timer); started = false; over = false; left = M; cells = Array.from({ length: H }, (_, y) => Array.from({ length: W }, (_, x) => ({ x, y, mine: false, open: false, flag: false, n: 0 }))); draw(); };
  const plant = (sx, sy) => { let k = 0; while (k < M) { const x = Math.floor(Math.random() * W), y = Math.floor(Math.random() * H); const c = cells[y][x]; if (!c.mine && !(Math.abs(x - sx) <= 1 && Math.abs(y - sy) <= 1)) { c.mine = true; k++; } } cells.flat().forEach(c => near(c.x, c.y, n => { if (n.mine) c.n++; })); started = true; t0 = Date.now(); timer = setInterval(draw, 1000); };
  const reveal = (c) => { if (c.open || c.flag) return; c.open = true; if (c.mine) return; if (!c.n) near(c.x, c.y, reveal); };
  const click = (c) => {
    if (over) return; if (!started) plant(c.x, c.y);
    if (flagMode) { if (!c.open) { c.flag = !c.flag; left += c.flag ? -1 : 1; } draw(); return; }
    if (c.flag) return; reveal(c);
    if (c.mine) { over = 'lose'; cells.flat().forEach(x => { if (x.mine) x.open = true; }); clearInterval(timer); }
    else if (cells.flat().filter(x => !x.mine && !x.open).length === 0) { over = 'win'; clearInterval(timer); const s = Math.max(10, 1000 - Math.floor((Date.now() - t0) / 1000) * 5); this.best('mines', s); }
    draw();
  };
  const draw = () => {
    clear(grid); const COLS = ['', '#0a84ff', '#30d158', '#ff453a', '#5e5ce6', '#ff9f0a', '#64d2ff', '#fff', '#888'];
    cells.flat().forEach(c => { const el = h('div' + (c.open ? '.op' : ''), { style: c.open && c.n && !c.mine ? `color:${COLS[c.n]}` : '', onclick: () => click(c), oncontextmenu: (e) => { e.preventDefault(); if (!c.open && !over) { c.flag = !c.flag; left += c.flag ? -1 : 1; draw(); } } }, c.open ? (c.mine ? '💣' : (c.n || '')) : (c.flag ? '🚩' : '')); grid.appendChild(el); });
    info.textContent = '💣 ' + left + '   ⏱ ' + (started && !over ? Math.floor((Date.now() - t0) / 1000) : started ? Math.floor((Date.now() - t0) / 1000) : 0) + ' s' + (over === 'win' ? '   🎉 Gagné !' : over === 'lose' ? '   Perdu' : '');
  };
  this.page('Démineur', p => {
    p.body.appendChild(info); p.body.appendChild(grid);
    p.body.appendChild(h('div', { style: 'display:flex;gap:10px;padding:14px 16px' }, h('button.btn.sec', { style: 'flex:1', onclick: (e) => { flagMode = !flagMode; e.target.textContent = flagMode ? '🚩 Drapeau : ON' : '🚩 Drapeau : OFF'; } }, '🚩 Drapeau : OFF'), h('button.btn', { style: 'flex:1', onclick: reset }, 'Rejouer')));
    p.body.appendChild(h('div', { style: 'text-align:center;color:var(--fg2);font-size:13px' }, 'Clic droit ou mode drapeau pour marquer une mine'));
  }, () => clearInterval(timer));
  reset();
};

/* Puissance 4 (contre l'ordinateur) */
Games.c4 = function () {
  const R = 6, C = 7; let b, turn, over; const grid = h('div.c4'), msg = h('div', { style: 'text-align:center;font-size:19px;margin:12px 0' });
  const lines = []; for (let r = 0; r < R; r++) for (let c = 0; c < C; c++) for (const [dr, dc] of [[0, 1], [1, 0], [1, 1], [1, -1]]) { const l = []; for (let k = 0; k < 4; k++) { const rr = r + dr * k, cc = c + dc * k; if (rr < 0 || rr >= R || cc < 0 || cc >= C) break; l.push([rr, cc]); } if (l.length === 4) lines.push(l); }
  const win = (p) => lines.some(l => l.every(([r, c]) => b[r][c] === p));
  const drop = (c, p) => { for (let r = R - 1; r >= 0; r--) if (!b[r][c]) { b[r][c] = p; return r; } return -1; };
  const undo = (c) => { for (let r = 0; r < R; r++) if (b[r][c]) { b[r][c] = 0; return; } };
  const draw = () => { clear(grid); for (let r = 0; r < R; r++) for (let c = 0; c < C; c++) grid.appendChild(h('div', { onclick: () => play(c) }, h('i', { style: 'background:' + (b[r][c] === 1 ? '#ffd60a' : b[r][c] === 2 ? '#ff453a' : '#0a0f1f') }))); };
  const ai = () => { const ok = [...Array(C).keys()].filter(c => !b[0][c]); const test = (p) => ok.find(c => { drop(c, p); const w = win(p); undo(c); return w; }); let c = test(2); if (c == null) c = test(1); if (c == null) c = ok.sort((a, z) => Math.abs(a - 3) - Math.abs(z - 3) + (Math.random() - .5))[0]; drop(c, 2); };
  const play = (c) => { if (over || b[0][c]) return; drop(c, 1); if (win(1)) { over = true; msg.textContent = 'Vous gagnez ! 🎉'; Games.scores.c4 = (Games.scores.c4 || 0) + 1; Games.save(); Games.submit('c4', Games.scores.c4); } else if (b[0].every(Boolean)) { over = true; msg.textContent = 'Égalité'; } else { ai(); if (win(2)) { over = true; msg.textContent = 'L\'ordinateur gagne'; } } draw(); };
  const reset = () => { b = Array.from({ length: R }, () => Array(C).fill(0)); over = false; msg.textContent = 'À vous (jaune)'; draw(); };
  this.page('Puissance 4', p => { p.body.appendChild(msg); p.body.appendChild(grid); p.body.appendChild(h('div', { style: 'padding:18px 16px' }, h('button.btn.block', { onclick: reset }, 'Rejouer'))); });
  reset();
};

/* Flappy */
Games.flappy = function () {
  const W = 340, Hh = 460, cv = h('canvas', { width: W, height: Hh, style: 'display:block;margin:10px auto;border-radius:16px;background:linear-gradient(#4ec0ca,#a8e6ef);touch-action:none' });
  const c = cv.getContext('2d'); let y, vy, pipes, sc, alive, raf, started, f;
  const reset = () => { y = Hh / 2; vy = 0; pipes = []; sc = 0; alive = true; started = false; f = 0; cancelAnimationFrame(raf); loop(); };
  const flap = () => { if (!alive) return reset(); started = true; vy = -6.2; };
  const loop = () => {
    c.clearRect(0, 0, W, Hh);
    if (started && alive) { vy += .38; y += vy; f++; if (f % 85 === 1) pipes.push({ x: W, gap: 90 + Math.random() * (Hh - 260), got: false }); pipes.forEach(p => p.x -= 2.4); pipes = pipes.filter(p => p.x > -60);
      pipes.forEach(p => { if (60 + 14 > p.x && 60 - 14 < p.x + 50 && (y - 14 < p.gap || y + 14 > p.gap + 130)) alive = false; if (!p.got && p.x + 50 < 60) { p.got = true; sc++; } });
      if (y > Hh - 14 || y < 0) alive = false; if (!alive) Games.best('flappy', sc); }
    pipes.forEach(p => { c.fillStyle = '#5cb85c'; c.fillRect(p.x, 0, 50, p.gap); c.fillRect(p.x, p.gap + 130, 50, Hh); c.fillStyle = '#3d8f3d'; c.fillRect(p.x - 3, p.gap - 18, 56, 18); c.fillRect(p.x - 3, p.gap + 130, 56, 18); });
    c.fillStyle = '#ffd60a'; c.beginPath(); c.arc(60, y, 14, 0, 7); c.fill(); c.fillStyle = '#000'; c.beginPath(); c.arc(66, y - 4, 3, 0, 7); c.fill();
    c.fillStyle = '#fff'; c.font = 'bold 34px sans-serif'; c.textAlign = 'center'; c.strokeStyle = '#000'; c.lineWidth = 4; c.strokeText(sc, W / 2, 56); c.fillText(sc, W / 2, 56);
    if (!started) { c.font = '18px sans-serif'; c.fillText('Touchez pour voler', W / 2, Hh / 2 + 60); }
    if (!alive) { c.font = 'bold 26px sans-serif'; c.strokeText('Perdu — touchez', W / 2, Hh / 2); c.fillText('Perdu — touchez', W / 2, Hh / 2); }
    raf = requestAnimationFrame(loop);
  };
  cv.addEventListener('pointerdown', flap);
  const key = e => { if (!$('canvas', document.body)) { document.removeEventListener('keydown', key); return; } if ((e.key === ' ' || e.key === 'ArrowUp') && e.target.tagName !== 'INPUT') { e.preventDefault(); flap(); } };
  document.addEventListener('keydown', key);
  this.page('Flappy', p => { p.body.appendChild(cv); p.body.appendChild(h('div', { style: 'text-align:center;color:var(--fg2)' }, 'Touchez ou Espace pour voler')); }, () => cancelAnimationFrame(raf));
  reset();
};

/* Mémoire */
Games.memory = function () {
  const E = ['🍎', '🚗', '⭐', '🎵', '🔥', '🍕', '🐶', '💎']; let cards, open, moves, matched, lock; const grid = h('div.memg'), info = h('div', { style: 'text-align:center;font-size:18px;margin:10px' });
  const draw = () => { clear(grid); cards.forEach((v, i) => grid.appendChild(h('div' + (open.includes(i) || matched.has(i) ? '.up' : ''), { onclick: () => pick(i) }, open.includes(i) || matched.has(i) ? v : ''))); info.textContent = 'Coups : ' + moves + ' · Paires : ' + matched.size / 2 + '/8'; };
  const pick = (i) => { if (lock || open.includes(i) || matched.has(i)) return; open.push(i); if (open.length === 2) { moves++; lock = true; const [a, b] = open; if (cards[a] === cards[b]) { matched.add(a); matched.add(b); open = []; lock = false; if (matched.size === 16) { const s = Math.max(5, 100 - moves * 4); info.textContent = 'Bravo ! Score : ' + s; Games.best('memory', s); } } else setTimeout(() => { open = []; lock = false; draw(); }, 800); } draw(); };
  const reset = () => { cards = [...E, ...E].sort(() => Math.random() - .5); open = []; matched = new Set(); moves = 0; lock = false; draw(); };
  this.page('Mémoire', p => { p.body.appendChild(info); p.body.appendChild(grid); p.body.appendChild(h('div', { style: 'padding:14px 16px' }, h('button.btn.block', { onclick: reset }, 'Rejouer'))); });
  reset();
};

/* Dés et pile ou face */
Games.dice = function () {
  const pg = Page({ title: 'Hasard', back: 'Jeux' }); pg.el.classList.add('dark');
  const out = h('div', { style: 'text-align:center;font-size:90px;height:130px;line-height:130px' }, '🎲'); let n = 1;
  const res = (txt) => { out.textContent = txt; Sound.click(); };
  pg.body.appendChild(out);
  pg.body.appendChild(h('div', { style: 'display:flex;gap:8px;justify-content:center;margin-bottom:14px' }, [1, 2, 3].map(k => h('button.chip', { style: k === 1 ? 'background:var(--accent);color:#fff' : '', onclick: (e) => { n = k; $$('.chip', e.target.parentNode).forEach(c => c.style.cssText = ''); e.target.style.cssText = 'background:var(--accent);color:#fff'; } }, k + ' dé' + (k > 1 ? 's' : '')))));
  pg.body.appendChild(h('div', { style: 'padding:0 16px;display:grid;gap:12px' },
    h('button.btn.block', { onclick: () => { const f = '⚀⚁⚂⚃⚄⚅'; const r = [...Array(n)].map(() => Math.floor(Math.random() * 6)); res(r.map(x => f[x]).join(' ')); out.title = r.reduce((a, x) => a + x + 1, 0); out.style.fontSize = n > 1 ? '60px' : '90px'; } }, 'Lancer'),
    h('button.btn.sec.block', { onclick: () => { out.style.fontSize = '90px'; res(Math.random() < .5 ? '🪙 Pile' : '🪙 Face'); out.style.fontSize = '54px'; } }, 'Pile ou face'),
    h('button.btn.sec.block', { onclick: async () => { const nn = await Prompt('Nombre aléatoire', 'Entre 1 et…', { type: 'number', value: 100 }); if (nn) { out.style.fontSize = '70px'; res(1 + Math.floor(Math.random() * Math.max(1, parseInt(nn)))); } } }, 'Nombre aléatoire')));
  this.ctx.push(pg);
};

/* ───────────── Taxi ───────────── */
const Taxi = {
  async open(ctx) {
    this.ctx = ctx; const pg = Page({ title: 'Taxi' }); this.pg = pg; ctx.root(pg); pg.body.appendChild(Spinner());
    const lines = ((await rpc('serviceLines')) || []).filter(l => l.type === 'taxi' && l.alert);
    clear(pg.body); this.line = lines.sort((a, b) => b.online - a.online)[0];
    if (!this.line) { pg.body.appendChild(Empty('car', 'Aucun taxi', 'Aucune société de taxi n\'est disponible sur le serveur.')); return; }
    const cfg = S.config.taxi || { base: 15, ratePerKm: 45 };
    const v = { dest: null };
    pg.body.appendChild(h('div.bankcard', { style: 'background:linear-gradient(135deg,#f6d365,#fda085);color:#222' }, h('small', { style: 'color:#333' }, this.line.label), h('div.amount', { style: 'font-size:30px' }, 'Où allez-vous ?'), h('div', { style: 'margin-top:8px;opacity:.8' }, this.line.online + ' chauffeur' + (this.line.online > 1 ? 's' : '') + ' disponible' + (this.line.online > 1 ? 's' : ''))));
    const out = h('div'); pg.body.appendChild(out);
    const render = () => {
      clear(out);
      const list = [{ icon: 'pin', color: '#ff375f', title: 'Point GPS actuel', sub: 'Utilise la destination placée sur votre carte', chev: true, onclick: async () => { const w = await post('getWaypoint'); if (!w || !w.active) { Toast('Placez d\'abord un point sur la carte', 'warning'); return; } v.dest = { name: 'Point GPS', x: w.x, y: w.y, distance: w.distance }; render(); } }];
      PLACES.slice(0, 8).forEach(p => list.push({ icon: p[3], color: p[4], title: p[0], chev: true, onclick: async () => { const pos = await post('position'); v.dest = { name: p[0], x: p[1], y: p[2], distance: Math.hypot(pos.x - p[1], pos.y - p[2]) }; render(); } }));
      out.appendChild(Group('Destination', list));
      if (v.dest) {
        const km = Math.max(0.1, v.dest.distance * 1.3 / 1000), price = Math.round(cfg.base + km * cfg.ratePerKm);
        out.appendChild(Group('Votre course', [{ title: v.dest.name, sub: km.toFixed(1) + ' km environ' }, { title: 'Prix estimé', value: money(price) }]));
        out.appendChild(h('div', { style: 'padding:0 16px' }, h('button.btn.block', { onclick: async () => { const pos = await post('position'); const r = await rpc2('serviceCall', this.line.id, `Course vers ${v.dest.name} (${km.toFixed(1)} km, ~${price} $) — départ ${pos.street || ''}`, false); if (!r[0] || !r[0].ok) { Toast((r[0] && r[0].error) || r[1] || 'Aucun chauffeur disponible', 'warning'); return; } Toast('Course demandée à ' + r[0].count + ' chauffeur' + (r[0].count > 1 ? 's' : ''), 'check'); } }, 'Commander le taxi')));
      }
    };
    render();
  },
};
registerApp({ id: 'taxi', name: 'Taxi', icon: 'car', grad: ['#ffd60a', '#f5a300'], open: ctx => Taxi.open(ctx) });

/* ───────────── Actualités ───────────── */
const News = {
  async open(ctx) {
    this.ctx = ctx; this.pg = Page({ title: 'Actualités' }); ctx.root(this.pg); await this.draw();
    Bus.on('push:notify', d => { if (d.app === 'news' && ctx.alive && ctx.stack[0] === this.pg) this.draw(); });
  },
  async draw() {
    const pg = this.pg; pg.body.appendChild(Spinner()); const r = await rpc('newsList'); clear(pg.body);
    if (!r) return; this.r = r;
    pg.setRight(r.canPost ? [{ icon: 'edit', onclick: () => this.compose() }] : []);
    if (!r.list.length) { pg.body.appendChild(Empty('newspaper', 'Aucune actualité', 'Les journalistes publieront bientôt.')); return; }
    const [first, ...rest] = r.list;
    pg.body.appendChild(this.hero(first));
    pg.body.appendChild(Group(null, rest.map(n => ({ left: n.image ? h('div', { style: `width:64px;height:64px;border-radius:10px;background:url("${n.image}") center/cover;flex:none` }) : h('div.rico', { style: 'width:64px;height:64px;border-radius:10px;background:var(--card2);display:grid;place-items:center;color:var(--fg2)', html: icon('newspaper', 26) }), title: (n.breaking ? '🔴 ' : '') + n.title, sub: (n.source || '') + ' · ' + ago(n.created), chev: true, onclick: () => this.read(n) }))));
  },
  hero(n) {
    return h('div.newshero', { style: n.image ? `background-image:linear-gradient(transparent 30%, rgba(0,0,0,.85)),url("${n.image}")` : 'background:linear-gradient(135deg,#232526,#414345)', onclick: () => this.read(n) }, h('small', (n.breaking ? '🔴 URGENT · ' : '') + (n.source || '').toUpperCase()), h('b', n.title), h('span', n.author + ' · ' + ago(n.created)));
  },
  read(n) {
    const pg = Page({ title: n.source || 'Actualités', large: false, back: 'Retour', right: (this.r.admin || this.r.canPost) ? [{ icon: 'trash', onclick: async () => { if (await Confirm('Supprimer cet article ?', null, 'Supprimer', true)) { await rpc('newsDelete', n.id); this.ctx.pop(); this.draw(); } } }] : [] });
    if (n.image) pg.body.appendChild(h('img', { src: n.image, style: 'width:100%;max-height:260px;object-fit:cover', onclick: () => viewImage(n.image) }));
    pg.body.appendChild(h('div', { style: 'padding:16px 20px' }, n.breaking ? h('span.chip', { style: 'background:var(--red);color:#fff;margin-bottom:8px' }, 'URGENT') : null, h('div', { style: 'font-size:26px;font-weight:700;line-height:1.2;margin:6px 0' }, n.title), h('div', { style: 'color:var(--fg2);font-size:14px' }, 'Par ' + n.author + ' · ' + fmtLong(n.created)), h('div', { style: 'margin-top:16px;font-size:17px;line-height:1.5;white-space:pre-wrap;user-select:text' }, n.body || '')));
    this.ctx.push(pg);
  },
  compose() {
    const v = { title: '', body: '', image: '', breaking: false };
    const pg = Page({ title: 'Nouvel article', large: false, modal: true, left: [{ label: 'Annuler', onclick: () => this.ctx.pop() }], right: [{ label: 'Publier', bold: true, onclick: async () => { const r = await rpc2('newsPost', v); if (!r[0]) { Toast(r[1] || 'Publication impossible', 'warning'); return; } Toast('Article publié', 'check'); this.ctx.pop(); this.draw(); } }] });
    pg.body.appendChild(Group(null, [{ label: 'Titre', input: true, left: true, maxlength: 100, placeholder: 'Titre accrocheur', onInput: x => v.title = x }, { label: 'Image', input: true, left: true, placeholder: 'Lien (facultatif)', onInput: x => v.image = x }]));
    pg.body.appendChild(Group('Article', [{ input: true, multiline: true, left: true, rows: 9, maxlength: 2000, placeholder: 'Rédigez votre article…', onInput: x => v.body = x }]));
    pg.body.appendChild(Group(null, [{ title: 'Information urgente', toggle: { on: false, onchange: x => v.breaking = x } }], 'Une information urgente envoie une notification à tous les joueurs.'));
    this.ctx.push(pg);
  },
};
registerApp({ id: 'news', name: 'Actualités', icon: 'newspaper', grad: ['#ff3b30', '#a50d05'], open: ctx => News.open(ctx) });

/* ───────────── Loto ───────────── */
const Loto = {
  async open(ctx) {
    this.ctx = ctx; this.pg = Page({ title: 'Loto' }); ctx.root(this.pg); await this.draw();
    this.iv = setInterval(() => { if (!ctx.alive || !this.pg.el.isConnected) return clearInterval(this.iv); const c = $('.lt-count', this.pg.body); if (c && this.info) c.textContent = this.left(); }, 1000);
  },
  left() { const s = Math.max(0, Math.round((this.info.next - this.info.now - (Date.now() - this.t0)) / 1000)); return Math.floor(s / 60) + ' min ' + pad(s % 60) + ' s'; },
  async draw() {
    const pg = this.pg; pg.body.appendChild(Spinner()); const i = await rpc('lotoInfo'); clear(pg.body);
    if (!i) { pg.body.appendChild(Empty('ticket', 'Loto indisponible')); return; } this.info = i; this.t0 = Date.now();
    pg.body.appendChild(h('div.bankcard', { style: 'background:linear-gradient(135deg,#8e2de2,#4a00e0);text-align:center' }, h('small', 'Cagnotte'), h('div.amount', { style: 'font-size:46px' }, money(i.pool)), h('div', { style: 'opacity:.9;margin-top:8px' }, 'Prochain tirage dans ', h('b.lt-count', this.left()))));
    pg.body.appendChild(h('div', { style: 'padding:0 16px 14px;display:grid;grid-template-columns:1fr 1fr;gap:10px' }, h('button.btn', { onclick: () => this.pick() }, 'Choisir mes numéros'), h('button.btn.sec', { onclick: () => this.buy(null) }, 'Ticket flash · ' + money(i.price))));
    if (i.last) pg.body.appendChild(Group('Dernier tirage (n°' + i.last.draw + ')', [{ el: h('div', { style: 'display:flex;gap:8px;padding:12px 0;flex-wrap:wrap' }, i.last.nums.map(n => this.ball(n))) }, { title: 'Tickets joués', value: String(i.last.tickets) }, { title: 'Gagnants', value: String(i.last.winners) }, i.last.jackpot ? { title: 'Cagnotte remportée', value: money(i.last.jackpot) } : null].filter(Boolean)));
    pg.body.appendChild(Group('Mes tickets', i.tickets.length ? i.tickets.map(t => ({ el: h('div', { style: 'display:flex;gap:6px;padding:10px 0;flex:1;flex-wrap:wrap' }, t.nums.split(' ').map(n => this.ball(n, i.last && t.draw === i.last.draw && i.last.nums.includes(+n)))), value: t.draw === i.draw ? 'En jeu' : (t.won ? '+' + money(t.won) : t.matches + ' bon' + (t.matches > 1 ? 's' : '')) })) : [{ title: 'Aucun ticket' }], 'Mise : ' + money(i.price) + ' · 3 bons numéros = x' + (i.payouts[3] || '?') + ' · 4 = x' + (i.payouts[4] || '?') + ' · ' + i.pick + ' = la cagnotte'));
  },
  ball(n, hit) { return h('span.lball' + (hit ? '.hit' : ''), n); },
  pick() {
    const i = this.info, sel = new Set();
    Sheet({ title: 'Choisissez ' + i.pick + ' numéros', full: true, render: (b, close) => {
      const grid = h('div.lgrid'); const btn = h('button.btn.block', { disabled: true, style: 'margin:0 16px', onclick: async () => { close(); this.buy([...sel]); } }, 'Valider');
      for (let n = 1; n <= i.max; n++) grid.appendChild(h('div', { onclick: (e) => { if (sel.has(n)) sel.delete(n); else if (sel.size < i.pick) sel.add(n); e.target.classList.toggle('on', sel.has(n)); btn.disabled = sel.size !== i.pick; btn.textContent = sel.size === i.pick ? 'Valider · ' + money(i.price) : 'Encore ' + (i.pick - sel.size); } }, n));
      b.appendChild(grid); b.appendChild(btn);
    } });
  },
  async buy(nums) { const r = await rpc2('lotoBuy', nums); if (!r[0]) { Toast(r[1] || 'Achat impossible', 'warning'); return; } Toast('Ticket : ' + r[0].nums.join(' – '), 'ticket'); this.draw(); },
};
registerApp({ id: 'loto', name: 'Loto', icon: 'ticket', grad: ['#8e2de2', '#4a00e0'], dark: true, open: ctx => Loto.open(ctx), onQuit: () => clearInterval(Loto.iv) });

/* ───────────── Convertisseur ───────────── */
const Conv = {
  open(ctx) {
    const U = {
      'Longueur': { m: 1, km: 1000, cm: .01, mm: .001, 'mile': 1609.344, 'pied': .3048, 'pouce': .0254, 'yard': .9144 },
      'Poids': { kg: 1, g: .001, mg: 1e-6, 'tonne': 1000, 'livre': .45359237, 'once': .0283495 },
      'Volume': { L: 1, mL: .001, 'gallon US': 3.785411784, 'cl': .01, 'm³': 1000 },
      'Vitesse': { 'km/h': 1, 'mph': 1.609344, 'm/s': 3.6, 'nœud': 1.852 },
      'Température': { '°C': 'c', '°F': 'f', 'K': 'k' },
      'Durée': { s: 1, min: 60, h: 3600, jour: 86400, semaine: 604800 },
    };
    const st = { cat: 'Longueur', from: 'm', to: 'km', v: '1' };
    const pg = Page({ title: 'Convertisseur' }); ctx.root(pg);
    const draw = () => {
      clear(pg.body); const u = U[st.cat]; const keys = Object.keys(u);
      if (!keys.includes(st.from)) st.from = keys[0]; if (!keys.includes(st.to)) st.to = keys[1];
      pg.body.appendChild(h('div', { style: 'display:flex;gap:8px;overflow:auto;padding:0 16px 12px' }, Object.keys(U).map(c => h('button.chip', { style: c === st.cat ? 'background:var(--accent);color:#fff' : '', onclick: () => { st.cat = c; draw(); } }, c))));
      const conv = () => { const v = parseFloat(String(st.v).replace(',', '.')); if (isNaN(v)) return '—'; let r; if (st.cat === 'Température') { const c = st.from === '°C' ? v : st.from === '°F' ? (v - 32) * 5 / 9 : v - 273.15; r = st.to === '°C' ? c : st.to === '°F' ? c * 9 / 5 + 32 : c + 273.15; } else r = v * u[st.from] / u[st.to]; return Number(r.toPrecision(8)).toString().replace('.', ','); };
      const out = h('div', { style: 'font-size:40px;font-weight:300;text-align:center;padding:20px 10px;word-break:break-all' }, conv() + ' ' + st.to);
      const sel = (k) => h('select', { style: 'flex:1;text-align:right;font-size:17px;background:none;color:var(--fg)', onchange: e => { st[k] = e.target.value; out.textContent = conv() + ' ' + st.to; } }, keys.map(x => h('option', { value: x, selected: x === st[k], style: 'color:#000' }, x)));
      pg.body.appendChild(Group(null, [{ label: 'Valeur', input: true, left: true, type: 'text', value: st.v, onInput: x => { st.v = x; out.textContent = conv() + ' ' + st.to; } }, { label: 'De', el: sel('from') }, { label: 'Vers', el: sel('to') }]));
      pg.body.appendChild(out);
      pg.body.appendChild(h('div', { style: 'padding:0 16px' }, h('button.btn.sec.block', { onclick: () => { [st.from, st.to] = [st.to, st.from]; draw(); } }, '⇅ Inverser')));
    };
    draw();
  },
};
registerApp({ id: 'converter', name: 'Convertisseur', icon: 'convert', grad: ['#34c759', '#248a3d'], open: ctx => Conv.open(ctx) });
