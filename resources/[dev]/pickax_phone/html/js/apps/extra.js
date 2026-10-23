/* ═══════════ Darkchat, Entreprise, Clés, Rappels, Boussole, Santé, Jeux ═══════════ */

/* ───────────── Darkchat ───────────── */
const Dark = {
  me: null, room: null, rooms: [], unread: 0,
  async open(ctx) {
    this.ctx = ctx;
    const pg = Page({ title: 'Shadow', right: [{ icon: 'plus', onclick: () => this.create() }], left: [{ icon: 'key', onclick: () => this.joinCode() }] });
    pg.el.classList.add('dc'); this.pg = pg; ctx.root(pg); pg.body.appendChild(Spinner());
    const a = await rpc2('dcAccess');
    if (!a[0]) { clear(pg.body); pg.body.appendChild(Empty('lock', 'Accès refusé', a[1] || 'Réseau indisponible')); return; }
    this.me = a[0]; this.unread = 0; OS.setBadge('darkchat', 0); await this.draw();
  },
  async draw() {
    const pg = this.pg; this.rooms = (await rpc('dcRooms')) || []; clear(pg.body);
    pg.body.appendChild(h('div.dcme', { onclick: () => this.alias() }, h('div.dcav', { style: `background:${this.me.color}`, html: icon('ghost', 24) }), h('div', h('b', this.me.alias), h('small', 'Votre pseudo anonyme · toucher pour changer')), h('span', { html: icon('chevR', 16) })));
    pg.body.appendChild(h('div', { style: 'padding:0 20px 10px;color:var(--fg2);font-size:13px;line-height:1.4' }, 'Personne ne voit votre nom ni votre numéro. Les messages s\'effacent selon la durée du salon.'));
    const mine = this.rooms.filter(r => r.joined), others = this.rooms.filter(r => !r.joined);
    const row = r => ({ icon: r.locked ? 'lock' : 'hash', color: '#5e5ce6', title: r.name, sub: (r.preview || 'Aucun message').slice(0, 44), value: r.members + ' 👤', chev: true, onclick: () => r.joined ? this.openRoom(r) : this.join(r) });
    if (mine.length) pg.body.appendChild(Group('Mes salons', mine.map(row)));
    pg.body.appendChild(Group('Salons publics', others.length ? others.map(row) : [{ title: 'Aucun autre salon' }]));
  },
  async alias() {
    const v = await Prompt('Changer de pseudo', 'Laissez vide pour un pseudo aléatoire', { placeholder: this.me.alias }); if (v === null) return;
    const r = await rpc2('dcAlias', v); if (!r[0]) { Toast(r[1] || 'Impossible', 'warning'); return; }
    this.me.alias = r[0]; this.draw();
  },
  async join(r) {
    let pass = ''; if (r.locked) { pass = await Prompt('Salon protégé', 'Mot de passe', { type: 'password' }); if (pass === null) return; }
    const res = await rpc2('dcJoin', r.id, pass); if (!res[0]) { Toast(res[1] || 'Impossible', 'warning'); return; }
    r.joined = true; this.openRoom(r);
  },
  async joinCode() {
    const code = await Prompt('Rejoindre un salon', 'Code du salon (donné par son créateur)', { placeholder: 'r12345123' }); if (!code) return;
    const pass = await Prompt('Mot de passe', 'Laissez vide si aucun', { type: 'password' }); if (pass === null) return;
    const res = await rpc2('dcJoin', code.trim(), pass); if (!res[0]) { Toast(res[1] || 'Impossible', 'warning'); return; }
    Toast('Salon rejoint', 'check'); this.draw();
  },
  create() {
    const v = { name: '', public: true, pass: '', ttl: 24 };
    const pg = Page({ title: 'Nouveau salon', large: false, modal: true, left: [{ label: 'Annuler', onclick: () => this.ctx.pop() }], right: [{ label: 'Créer', bold: true, onclick: async () => {
      const r = await rpc2('dcCreate', v.name, v.public, v.pass, v.ttl); if (!r[0]) { Toast(r[1] || 'Impossible', 'warning'); return; }
      this.ctx.pop(); Toast('Salon créé — code : ' + r[0], 'check'); this.draw();
    } }] });
    pg.el.classList.add('dc');
    pg.body.appendChild(Group(null, [{ label: 'Nom', input: true, left: true, placeholder: 'Nom du salon', maxlength: 40, onInput: x => v.name = x }, { label: 'Mot de passe', input: true, left: true, type: 'password', placeholder: 'Facultatif', onInput: x => v.pass = x }]));
    pg.body.appendChild(Group(null, [{ title: 'Salon public', toggle: { on: true, onchange: x => v.public = x } }], 'Un salon privé n\'est visible que par ceux qui connaissent son code.'));
    pg.body.appendChild(Group('Les messages s\'effacent après', [{ el: h('select', { style: 'flex:1;font-size:17px;background:none;color:var(--fg)', onchange: e => v.ttl = parseInt(e.target.value) }, (this.me.ttl || [24]).map(t => h('option', { value: t, selected: t === 24, style: 'color:#000' }, t === 0 ? 'Jamais' : t < 24 ? t + ' heure' + (t > 1 ? 's' : '') : (t / 24) + ' jour' + (t > 24 ? 's' : '')))) }]));
    this.ctx.push(pg);
  },
  async openRoom(r) {
    const pg = Page({ title: r.name, large: false, back: 'Salons', right: [{ icon: 'info', onclick: () => ActionSheet(r.name + ' · code ' + r.id, [{ label: 'Copier le code du salon', onclick: () => Contacts.copy(r.id) }, { label: 'Quitter le salon', red: true, onclick: async () => { await rpc('dcLeave', r.id); this.ctx.pop(); this.draw(); } }]) }], onClose: () => { this.room = null; this.draw(); } });
    pg.el.classList.add('dc'); pg.nav.classList.add('conv-nav');
    pg.body.classList.add('nopad'); pg.body.style.cssText = 'display:flex;flex-direction:column;overflow:hidden';
    const scroll = h('div.conv-scroll'); const input = h('textarea', { rows: 1, placeholder: 'Message anonyme', maxlength: this.me.max || 500 });
    const send = async (img) => { const t = input.value.trim(); if (!t && !img) return; input.value = ''; const r2 = await rpc2('dcSend', r.id, t, img); if (!r2[0]) Toast(r2[1] || 'Échec', 'warning'); };
    const bar = h('div.inputbar', h('button.attachbtn', { html: icon('image', 20), onclick: async () => { const u = await Prompt('Lien de l\'image', null, { placeholder: 'https://…' }); if (u && /^https?:/.test(u)) send(u); } }), h('div.inputwrap', input, h('button.sendbtn', { html: icon('send', 18), onclick: () => send() })));
    input.addEventListener('keydown', e => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); send(); } });
    pg.body.appendChild(scroll); pg.body.appendChild(bar); this.ctx.push(pg); this.room = r;
    const add = (m) => { const mine = m.mine; scroll.appendChild(h('div.dcm' + (mine ? '.me' : ''), { oncontextmenu: (e) => { e.preventDefault(); if (mine || S.me.admin) ActionSheet(null, [{ label: 'Supprimer', red: true, onclick: async () => { await rpc('dcDelete', m.id); load(); } }]); } }, h('b', { style: `color:${m.color}` }, mine ? 'Vous · ' + m.alias : m.alias), m.body ? h('div.dct', { html: linkify(m.body) }) : null, m.image ? h('img', { src: m.image, onclick: () => viewImage(m.image) }) : null, h('small', fmtTime(m.created)))); };
    const load = async () => { const ms = (await rpc('dcMessages', r.id)) || []; clear(scroll); if (!ms.length) scroll.appendChild(h('div', { style: 'text-align:center;color:var(--fg2);margin:40px' }, 'Aucun message. Lancez la discussion.')); ms.forEach(add); scroll.scrollTop = scroll.scrollHeight; };
    await load(); r.unsub && r.unsub();
    r.unsub = Bus.on('push:dcMessage', d => { if (d.room !== r.id || this.room !== r) return; if (scroll.querySelector('div[style*="margin:40px"]')) clear(scroll); add(d.msg); scroll.scrollTop = scroll.scrollHeight; });
    setTimeout(() => input.focus(), 450);
  },
};
Bus.on('push:dcMessage', d => {
  if (Dark.room && Dark.room.id === d.room && S.open && OS.current && OS.current.id === 'darkchat') return;
  if (d.silent || (d.msg && d.msg.mine)) return;
  Dark.unread++; OS.setBadge('darkchat', Dark.unread);
  OS.notify({ app: 'darkchat', title: 'Shadow', body: (d.msg.alias || '?') + ' : ' + (d.msg.body || '📷 Image'), icon: 'ghost' });
});
registerApp({ id: 'darkchat', name: 'Shadow', icon: 'ghost', grad: ['#3a1c71', '#0b0b12'], dark: true, open: ctx => Dark.open(ctx) });

/* ───────────── Entreprise ───────────── */
const Biz = {
  async open(ctx) {
    this.ctx = ctx;
    const pg = Page({ title: 'Entreprise' }); this.pg = pg; ctx.root(pg); await this.draw();
  },
  async draw() {
    const pg = this.pg; pg.body.appendChild(Spinner());
    const d = await rpc('biz'); clear(pg.body); this.d = d;
    if (!d || d.none) { pg.body.appendChild(Empty('briefcase', 'Pas d\'entreprise', 'Votre métier actuel n\'est pas géré par le Job Builder, ou vous êtes sans emploi.')); return; }
    pg.body.appendChild(h('div.bankcard', { style: 'background:linear-gradient(135deg,#232526,#414345)' }, h('small', d.gradeLabel), h('div.amount', { style: 'font-size:30px' }, d.label), d.money != null ? h('div', { style: 'margin-top:12px;opacity:.9' }, 'Compte société : ', h('b', money(d.money))) : h('div', { style: 'margin-top:12px;opacity:.7;font-size:14px' }, d.team.length + ' collègue' + (d.team.length > 1 ? 's' : '') + ' en ligne')));
    pg.body.appendChild(Group(null, [
      d.canBill ? { icon: 'receipt', color: '#ff9f0a', title: 'Facturer un client', sub: 'Facture payable dans l\'app Banque du client', chev: true, onclick: () => this.bill() } : null,
      d.isBoss ? { icon: 'userPlus', color: '#30d158', title: 'Recruter', sub: 'Personne à proximité', chev: true, onclick: () => this.hire() } : null,
    ].filter(Boolean)));
    pg.body.appendChild(Group('Équipe en ligne', d.team.map(m => ({ left: avatar(m.name, 36), title: m.name + (m.me ? ' (vous)' : ''), sub: m.gradeLabel, chev: d.isBoss && !m.me, onclick: () => d.isBoss && !m.me && this.member(m) }))));
  },
  async pickNearby(title) {
    const near = (await rpc('bizNearby')) || [];
    return new Promise(res => { if (!near.length) { Alert(title, 'Personne à proximité.', [{ label: 'OK', bold: true, onclick: () => res(null) }]); return; } let done = false; Sheet({ title, onClose: () => { if (!done) res(null); }, render: (b, close) => { b.appendChild(Group('À proximité', near.map(n => ({ left: avatar(n.name, 34), title: n.name, sub: n.job, onclick: () => { done = true; close(); res(n); } })))); } }); });
  },
  async bill() {
    const t = await this.pickNearby('Facturer'); if (!t) return;
    const v = { amount: '', reason: '' };
    const pg = Page({ title: 'Facture', large: false, modal: true, left: [{ label: 'Annuler', onclick: () => this.ctx.pop() }], right: [{ label: 'Envoyer', bold: true, onclick: async () => {
      const r = await rpc2('bizBill', t.src, v.amount, v.reason); if (!r[0]) { Toast(r[1] || 'Facture refusée', 'warning'); return; } Toast('Facture envoyée à ' + t.name, 'check'); this.ctx.pop();
    } }] });
    pg.body.appendChild(Group('Client', [{ left: avatar(t.name, 34), title: t.name }]));
    pg.body.appendChild(Group('Montant', [{ label: '$', input: true, left: true, type: 'number', placeholder: '0', onInput: x => v.amount = x }], 'Maximum : ' + money(this.d.maxBill)));
    pg.body.appendChild(Group('Motif', [{ input: true, multiline: true, left: true, rows: 3, maxlength: 120, placeholder: 'Prestation, réparation…', onInput: x => v.reason = x }]));
    this.ctx.push(pg);
  },
  async hire() {
    const t = await this.pickNearby('Recruter'); if (!t) return;
    ActionSheet('Grade de ' + t.name, this.d.grades.map(g => ({ label: g.label, onclick: async () => { const r = await rpc2('bizHire', t.src, g.grade); Toast(r[0] ? t.name + ' a été recruté(e)' : (r[1] || 'Impossible'), r[0] ? 'check' : 'warning'); this.draw(); } })));
  },
  member(m) {
    ActionSheet(m.name + ' — ' + m.gradeLabel, [
      { label: 'Changer le grade', onclick: () => ActionSheet('Nouveau grade', this.d.grades.map(g => ({ label: g.label + (g.grade === m.grade ? ' ✓' : ''), onclick: async () => { const r = await rpc2('bizGrade', m.src, g.grade); Toast(r[0] ? 'Grade modifié' : (r[1] || 'Impossible'), r[0] ? 'check' : 'warning'); this.draw(); } }))) },
      { label: 'Licencier', red: true, onclick: async () => { if (await Confirm('Licencier ' + m.name + ' ?', null, 'Licencier', true)) { const r = await rpc2('bizFire', m.src); Toast(r[0] ? 'Employé licencié' : (r[1] || 'Impossible'), r[0] ? 'check' : 'warning'); this.draw(); } } },
    ]);
  },
};
registerApp({ id: 'business', name: 'Entreprise', icon: 'briefcase', grad: ['#636366', '#2c2c2e'], dark: true, open: ctx => Biz.open(ctx) });

/* ───────────── Clés ───────────── */
const Keys = {
  async open(ctx) {
    const pg = Page({ title: 'Clés' }); ctx.root(pg); pg.body.appendChild(Spinner());
    const rows = (await rpc('garage')) || []; clear(pg.body);
    if (!rows.length) { pg.body.appendChild(Empty('key', 'Aucune clé', 'Les véhicules que vous possédez apparaîtront ici.')); return; }
    const named = await Promise.all(rows.map(async r => { const n = await post('vehicleName', { model: r.model }); return Object.assign(r, { name: (n && n.name) || 'Véhicule' }); }));
    named.forEach(v => {
      const act = (ic, label, a) => h('button.bact', { onclick: async () => { const r = await post('vehControl', { plate: v.plate, action: a }); if (!r || !r.ok) { Toast((r && r.error) || 'Impossible', 'warning'); return; } Toast(a === 'lock' ? 'Véhicule verrouillé' : a === 'unlock' ? 'Véhicule déverrouillé' : a === 'engine' ? (r.engine ? 'Moteur démarré' : 'Moteur coupé') : label + ' · ' + r.distance + ' m', ic); } }, h('span', { html: icon(ic, 22) }), label);
      pg.body.appendChild(h('div.group', h('div.rows', h('div', { style: 'padding:14px 16px' }, h('div', { style: 'display:flex;gap:12px;align-items:center;margin-bottom:12px' }, h('div.rico', { style: 'width:44px;height:44px;border-radius:12px;background:#636366;display:grid;place-items:center;color:#fff', html: icon('car', 24) }), h('div', h('b', { style: 'font-size:18px' }, v.name), h('div', { style: 'color:var(--fg2);font-size:13px' }, v.plate + ' · ' + (v.stored ? 'Au garage' : 'Dehors')))),
        h('div', { style: 'display:grid;grid-template-columns:repeat(3,1fr);gap:8px' }, act('lock', 'Verrouiller', 'lock'), act('unlock', 'Ouvrir', 'unlock'), act('lightning', 'Moteur', 'engine'), act('bell', 'Klaxon', 'horn'), act('sun', 'Phares', 'lights'), act('car', 'Coffre', 'trunk'))))));
    });
    pg.body.appendChild(h('div', { style: 'text-align:center;color:var(--fg2);font-size:13px;padding:0 30px' }, 'Portée : 150 m. Les commandes ne fonctionnent que sur vos véhicules.'));
  },
};
registerApp({ id: 'keys', name: 'Clés', icon: 'key', grad: ['#ffd60a', '#ff9f0a'], open: ctx => Keys.open(ctx) });

/* ───────────── Rappels ───────────── */
const Todo = {
  list: [],
  async open(ctx) {
    this.ctx = ctx; this.list = (await rpc('kvGet', 'todos')) || [];
    const pg = Page({ title: 'Rappels', right: [{ icon: 'plus', onclick: () => this.add() }] }); this.pg = pg; ctx.root(pg); this.draw();
  },
  save() { rpc('kvSet', 'todos', this.list); },
  async add() { const t = await Prompt('Nouveau rappel', null, { placeholder: 'À faire…' }); if (!t) return; this.list.unshift({ id: Date.now(), text: t.slice(0, 120), done: false }); this.save(); this.draw(); },
  draw() {
    const pg = this.pg; clear(pg.body);
    const open = this.list.filter(t => !t.done), done = this.list.filter(t => t.done);
    const row = t => ({ left: h('span', { style: 'color:' + (t.done ? 'var(--accent)' : 'var(--fg3)'), html: icon(t.done ? 'checkCircle' : 'circle', 26), onclick: (e) => { e.stopPropagation(); t.done = !t.done; this.save(); this.draw(); } }), title: h('span', { style: t.done ? 'text-decoration:line-through;color:var(--fg2)' : '' }, t.text), onlong: () => ActionSheet(t.text, [{ label: 'Supprimer', red: true, onclick: () => { this.list = this.list.filter(x => x !== t); this.save(); this.draw(); } }]) });
    if (!this.list.length) { pg.body.appendChild(Empty('list', 'Aucun rappel', 'Touchez + pour en ajouter.')); return; }
    if (open.length) pg.body.appendChild(Group('À faire', open.map(row)));
    if (done.length) pg.body.appendChild(Group('Terminés', done.map(row)));
  },
};
registerApp({ id: 'reminders', name: 'Rappels', icon: 'list', grad: ['#ff9f0a', '#ff6b00'], open: ctx => Todo.open(ctx) });

/* ───────────── Boussole ───────────── */
const Compass = {
  async open(ctx) {
    const pg = Page({ noNav: true, nopad: true }); pg.el.style.background = '#000'; ctx.root(pg);
    const dial = h('div.cmp-dial'); ['N', 'E', 'S', 'O'].forEach((l, i) => dial.appendChild(h('b', { style: `transform:rotate(${i * 90}deg) translateY(-118px);color:${l === 'N' ? 'var(--red)' : '#fff'}` }, l)));
    for (let a = 0; a < 360; a += 15) dial.appendChild(h('i', { style: `transform:rotate(${a}deg) translateY(-138px);height:${a % 90 === 0 ? 0 : a % 45 === 0 ? 14 : 8}px` }));
    const info = h('div', { style: 'text-align:center;color:#fff;margin-top:30px' });
    pg.body.appendChild(h('div.cmp', h('div', { style: 'height:120px' }), h('div.cmp-wrap', dial, h('div.cmp-pin')), info));
    const tick = async () => {
      if (!ctx.alive || !pg.el.isConnected) return;
      const p = await post('position');
      if (p) { const hd = (360 - (p.heading || 0)) % 360; dial.style.transform = `rotate(${hd}deg)`; const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SO', 'O', 'NO']; info.innerHTML = `<div style="font-size:54px;font-weight:200">${Math.round(p.heading || 0)}° ${dirs[Math.round((p.heading || 0) / 45) % 8]}</div><div style="opacity:.8;margin-top:6px">${esc(p.street || '')}</div><div style="opacity:.55;font-size:14px">${esc(p.zone || '')}</div><div style="opacity:.55;font-size:13px;margin-top:10px">X ${Math.round(p.x)} · Y ${Math.round(p.y)} · Z ${Math.round(p.z)}</div>`; }
      setTimeout(tick, 350);
    };
    tick();
  },
};
registerApp({ id: 'compass', name: 'Boussole', icon: 'compass', grad: ['#2c2c2e', '#000'], dark: true, open: ctx => Compass.open(ctx) });

/* ───────────── Santé ───────────── */
const Health = {
  async open(ctx) {
    const pg = Page({ title: 'Santé' }); ctx.root(pg);
    const box = h('div'); pg.body.appendChild(box);
    const bar = (label, v, color, ic) => h('div.hbar', h('div', { style: 'display:flex;justify-content:space-between;margin-bottom:8px' }, h('span', { html: icon(ic, 18) + ' ' + label }), h('b', v == null ? '—' : v + ' %')), h('div.hb', h('i', { style: `width:${v == null ? 0 : v}%;background:${color}` })));
    const tick = async () => {
      if (!ctx.alive || !pg.el.isConnected) return;
      const d = (await post('vitals')) || {}; clear(box);
      box.appendChild(h('div', { style: 'text-align:center;padding:10px 0 20px' }, h('div', { style: `width:130px;height:130px;border-radius:50%;margin:auto;display:grid;place-items:center;background:conic-gradient(${d.health > 50 ? '#30d158' : d.health > 25 ? '#ff9f0a' : '#ff453a'} ${d.health || 0}%, var(--card2) 0)` }, h('div', { style: 'width:104px;height:104px;border-radius:50%;background:var(--bg);display:grid;place-items:center' }, h('div', h('div', { style: 'font-size:36px;font-weight:700' }, (d.health || 0) + '%'), h('small', { style: 'color:var(--fg2)' }, 'Santé'))))));
      box.appendChild(h('div.group', h('div.rows', h('div', { style: 'padding:14px 16px;display:grid;gap:16px' }, bar('Armure', d.armor, '#0a84ff', 'shield'), bar('Faim', d.hunger, '#ff9f0a', 'utensils'), bar('Soif', d.thirst, '#64d2ff', 'rain'), bar('Endurance', d.stamina, '#30d158', 'lightning')))));
      setTimeout(tick, 2000);
    };
    tick();
  },
};
registerApp({ id: 'health', name: 'Santé', icon: 'heartbeat', grad: ['#ff6b81', '#ff2d55'], open: ctx => Health.open(ctx) });

/* ───────────── Jeux ───────────── */
const Games = {
  scores: {},
  async open(ctx) {
    this.ctx = ctx; this.scores = (await rpc('kvGet', 'scores')) || {};
    const pg = Page({ title: 'Jeux' }); pg.el.classList.add('dark'); ctx.root(pg);
    pg.body.appendChild(Group(null, [
      { icon: 'swipe', color: '#30d158', title: 'Snake', sub: 'Record : ' + (this.scores.snake || 0), chev: true, onclick: () => this.snake() },
      { icon: 'x', color: '#5e5ce6', title: 'Morpion', sub: 'Victoires : ' + (this.scores.ttt || 0), chev: true, onclick: () => this.ttt() },
    ]));
  },
  save() { rpc('kvSet', 'scores', this.scores); },
  snake() {
    const pg = Page({ title: 'Snake', large: false, back: 'Jeux' }); pg.el.classList.add('dark');
    const N = 18, cell = 19, cv = h('canvas', { width: N * cell, height: N * cell, style: 'display:block;margin:16px auto;border-radius:14px;background:#0d1117' });
    const score = h('div', { style: 'text-align:center;font-size:20px;font-weight:600' }, 'Score : 0');
    const msg = h('div', { style: 'text-align:center;color:var(--fg2);margin-top:8px' }, 'Flèches / ZQSD ou boutons');
    const pad = h('div', { style: 'display:grid;grid-template-columns:repeat(3,64px);gap:8px;justify-content:center;margin-top:16px' });
    let snake, dir, nd, food, sc, timer, alive;
    const ctx2 = cv.getContext('2d');
    const reset = () => { snake = [{ x: 9, y: 9 }, { x: 8, y: 9 }, { x: 7, y: 9 }]; dir = nd = { x: 1, y: 0 }; sc = 0; alive = true; place(); score.textContent = 'Score : 0'; msg.textContent = 'Bonne chance !'; clearInterval(timer); timer = setInterval(step, 120); };
    const place = () => { do { food = { x: Math.floor(Math.random() * N), y: Math.floor(Math.random() * N) }; } while (snake.some(s => s.x === food.x && s.y === food.y)); };
    const draw = () => { ctx2.fillStyle = '#0d1117'; ctx2.fillRect(0, 0, cv.width, cv.height); ctx2.fillStyle = '#ff453a'; ctx2.beginPath(); ctx2.arc(food.x * cell + cell / 2, food.y * cell + cell / 2, cell / 2 - 3, 0, 7); ctx2.fill(); snake.forEach((s, i) => { ctx2.fillStyle = i ? '#30d158' : '#7dff9a'; ctx2.fillRect(s.x * cell + 1, s.y * cell + 1, cell - 2, cell - 2); }); };
    const step = () => {
      if (!alive) return; dir = nd; const hd = { x: snake[0].x + dir.x, y: snake[0].y + dir.y };
      if (hd.x < 0 || hd.y < 0 || hd.x >= N || hd.y >= N || snake.some(s => s.x === hd.x && s.y === hd.y)) { alive = false; clearInterval(timer); msg.textContent = 'Perdu ! Touchez Rejouer'; if (sc > (this.scores.snake || 0)) { this.scores.snake = sc; this.save(); msg.textContent = 'Nouveau record : ' + sc + ' !'; } return; }
      snake.unshift(hd); if (hd.x === food.x && hd.y === food.y) { sc++; score.textContent = 'Score : ' + sc; place(); } else snake.pop(); draw();
    };
    const go = (x, y) => { if (x === -dir.x && y === -dir.y) return; nd = { x, y }; };
    const key = e => { if (!$('canvas', pg.el)) { document.removeEventListener('keydown', key); return; } const m = { ArrowUp: [0, -1], z: [0, -1], w: [0, -1], ArrowDown: [0, 1], s: [0, 1], ArrowLeft: [-1, 0], q: [-1, 0], a: [-1, 0], ArrowRight: [1, 0], d: [1, 0] }[e.key]; if (m && e.target.tagName !== 'INPUT') { e.preventDefault(); go(m[0], m[1]); } };
    document.addEventListener('keydown', key);
    [['', ''], ['↑', [0, -1]], ['', ''], ['←', [-1, 0]], ['↓', [0, 1]], ['→', [1, 0]]].forEach(b => pad.appendChild(b[0] ? h('button.btn.sec', { style: 'height:54px', onclick: () => go(b[1][0], b[1][1]) }, b[0]) : h('div')));
    pg.body.appendChild(score); pg.body.appendChild(cv); pg.body.appendChild(msg); pg.body.appendChild(pad);
    pg.body.appendChild(h('div', { style: 'padding:16px' }, h('button.btn.block', { onclick: reset }, 'Rejouer')));
    pg.opts.onClose = () => clearInterval(timer);
    this.ctx.push(pg); reset(); draw();
  },
  ttt() {
    const pg = Page({ title: 'Morpion', large: false, back: 'Jeux' }); pg.el.classList.add('dark');
    let b, over; const msg = h('div', { style: 'text-align:center;font-size:20px;margin:18px 0 8px' }, 'À vous (X)'); const grid = h('div', { style: 'display:grid;grid-template-columns:repeat(3,96px);gap:8px;justify-content:center' });
    const L = [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]];
    const win = (p) => L.some(l => l.every(i => b[i] === p));
    const draw = () => { clear(grid); b.forEach((v, i) => grid.appendChild(h('button', { style: `height:96px;border-radius:14px;background:var(--card2);font-size:44px;font-weight:700;color:${v === 'X' ? '#0a84ff' : '#ff453a'}`, onclick: () => play(i) }, v || ''))); };
    const ai = () => { const free = b.map((v, i) => v ? null : i).filter(x => x != null); if (!free.length) return; const pick = (p) => free.find(i => { b[i] = p; const w = win(p); b[i] = null; return w; }); const i = pick('O') ?? pick('X') ?? (b[4] ? null : 4) ?? free[Math.floor(Math.random() * free.length)]; b[i == null ? free[0] : i] = 'O'; };
    const play = (i) => { if (over || b[i]) return; b[i] = 'X'; if (win('X')) { over = true; msg.textContent = 'Vous gagnez ! 🎉'; this.scores.ttt = (this.scores.ttt || 0) + 1; this.save(); } else if (b.every(Boolean)) { over = true; msg.textContent = 'Égalité'; } else { ai(); if (win('O')) { over = true; msg.textContent = 'L\'IA gagne'; } else if (b.every(Boolean)) { over = true; msg.textContent = 'Égalité'; } } draw(); };
    const reset = () => { b = Array(9).fill(null); over = false; msg.textContent = 'À vous (X)'; draw(); };
    pg.body.appendChild(msg); pg.body.appendChild(grid); pg.body.appendChild(h('div', { style: 'padding:20px 16px' }, h('button.btn.block', { onclick: reset }, 'Rejouer')));
    this.ctx.push(pg); reset();
  },
};
registerApp({ id: 'games', name: 'Jeux', icon: 'gamepad', grad: ['#5e5ce6', '#2f2ca8'], dark: true, open: ctx => Games.open(ctx) });
