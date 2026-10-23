/* ═══════════ Notes, Calendrier, Horloge, Calculette, Météo, Mail, Wallet, AirShare ═══════════ */

/* ───────────── Notes ───────────── */
const Notes = {
  list: [],
  async open(ctx) {
    this.ctx = ctx; this.list = (await rpc('kvGet', 'notes')) || [];
    const pg = Page({ title: 'Notes', right: [{ icon: 'edit', onclick: () => this.edit(null) }] });
    this.pg = pg; ctx.root(pg); this.draw();
  },
  save() { clearTimeout(this.st); this.st = setTimeout(() => rpc('kvSet', 'notes', this.list), 500); },
  draw() {
    const pg = this.pg; clear(pg.body);
    pg.body.appendChild(SearchBar({ onInput: q => drawList(q) }));
    const wrap = h('div'); pg.body.appendChild(wrap);
    const drawList = (q) => {
      clear(wrap); q = (q || '').toLowerCase();
      const ns = this.list.filter(n => !q || (n.title + n.body).toLowerCase().includes(q)).sort((a, b) => (b.pinned ? 1 : 0) - (a.pinned ? 1 : 0) || b.at - a.at);
      if (!ns.length) { wrap.appendChild(Empty('note', 'Aucune note', 'Touchez le crayon pour en créer une.')); return; }
      const mk = (arr, title) => arr.length && wrap.appendChild(Group(title, arr.map(n => ({ title: n.title || 'Nouvelle note', sub: fmtDay(n.at) + '  ' + (n.body || '').split('\n')[0].slice(0, 40), onclick: () => this.edit(n), onlong: () => this.menu(n) }))));
      mk(ns.filter(n => n.pinned), 'Épinglées'); mk(ns.filter(n => !n.pinned), ns.some(n => n.pinned) ? 'Notes' : null);
      wrap.appendChild(h('div', { style: 'text-align:center;color:var(--fg2);padding:8px' }, ns.length + ' note' + (ns.length > 1 ? 's' : '')));
    };
    drawList('');
  },
  menu(n) {
    ActionSheet(n.title, [
      { label: n.pinned ? 'Désépingler' : 'Épingler', onclick: () => { n.pinned = !n.pinned; this.save(); this.draw(); } },
      { label: 'Partager par AirShare', onclick: () => AirShare.send('note', { title: n.title, body: n.body }) },
      { label: 'Envoyer par message', onclick: async () => { const num = await pickContactNumber(); if (num) { const r = await rpc('msgSend', { to: num, body: (n.title ? n.title + '\n' : '') + n.body }); Toast(r && r.ok ? 'Envoyée' : 'Échec', 'message'); } } },
      { label: 'Supprimer', red: true, onclick: () => { this.list = this.list.filter(x => x !== n); this.save(); this.draw(); } },
    ]);
  },
  edit(n) {
    const isNew = !n;
    if (isNew) { n = { id: Date.now(), title: '', body: '', at: Date.now() }; }
    const pg = Page({ title: 'Note', large: false, back: 'Notes', right: [{ icon: 'share', onclick: () => this.menu(n) }], onClose: () => { if (!n.body.trim() && !n.title.trim()) this.list = this.list.filter(x => x !== n); this.save(); this.draw(); } });
    const ta = h('textarea.note-ed', { placeholder: 'Écrivez ici…', value: n.title ? n.title + (n.body ? '\n' + n.body : '') : '' });
    ta.addEventListener('input', () => { const lines = ta.value.split('\n'); n.title = (lines[0] || '').slice(0, 80); n.body = lines.slice(1).join('\n'); n.at = Date.now(); if (isNew && !this.list.includes(n)) this.list.unshift(n); this.save(); });
    pg.body.appendChild(ta); pg.body.style.padding = '0';
    this.ctx.push(pg); setTimeout(() => ta.focus(), 420);
  },
};
registerApp({ id: 'notes', name: 'Notes', icon: 'note', grad: ['#ffe066', '#f5b800'], open: ctx => Notes.open(ctx) });

/* ───────────── Calendrier ───────────── */
const Calendar = {
  events: [], cur: null, sel: null,
  async open(ctx) {
    this.ctx = ctx; this.events = (await rpc('kvGet', 'events')) || [];
    const d = clockDate(); this.cur = new Date(d.getFullYear(), d.getMonth(), 1); this.sel = d.toISOString().slice(0, 10);
    const pg = Page({ title: 'Calendrier', large: false, right: [{ icon: 'plus', onclick: () => this.edit({ date: this.sel }) }], left: [{ label: 'Aujourd\'hui', onclick: () => { const t = clockDate(); this.cur = new Date(t.getFullYear(), t.getMonth(), 1); this.sel = ymd(t); this.draw(); } }] });
    this.pg = pg; ctx.root(pg); this.draw();
  },
  save() { rpc('kvSet', 'events', this.events); },
  draw() {
    const pg = this.pg, c = this.cur; clear(pg.body);
    pg.setTitle(MONTHS[c.getMonth()][0].toUpperCase() + MONTHS[c.getMonth()].slice(1) + ' ' + c.getFullYear());
    const head = h('div', { style: 'display:flex;justify-content:space-between;padding:6px 16px' }, h('button', { html: icon('chevL', 24), style: 'color:var(--accent)', onclick: () => { this.cur = new Date(c.getFullYear(), c.getMonth() - 1, 1); this.draw(); } }), h('button', { html: icon('chevR', 24), style: 'color:var(--accent)', onclick: () => { this.cur = new Date(c.getFullYear(), c.getMonth() + 1, 1); this.draw(); } }));
    pg.body.appendChild(head);
    const grid = h('div.calgrid');
    ['L', 'M', 'M', 'J', 'V', 'S', 'D'].forEach(x => grid.appendChild(h('div.dow', x)));
    const first = (c.getDay() + 6) % 7, days = new Date(c.getFullYear(), c.getMonth() + 1, 0).getDate(), today = ymd(clockDate());
    for (let i = 0; i < first; i++) grid.appendChild(h('div'));
    for (let d = 1; d <= days; d++) {
      const key = c.getFullYear() + '-' + pad(c.getMonth() + 1) + '-' + pad(d);
      const has = this.events.some(e => e.date === key);
      grid.appendChild(h('div.day' + (key === this.sel ? '.sel' : '') + (key === today ? '.today' : ''), { onclick: () => { this.sel = key; this.draw(); } }, h('span', d), has ? h('i') : null));
    }
    pg.body.appendChild(grid);
    const evs = this.events.filter(e => e.date === this.sel).sort((a, b) => (a.time || '').localeCompare(b.time || ''));
    const dt = new Date(this.sel + 'T12:00:00');
    pg.body.appendChild(h('div', { style: 'padding:14px 20px 6px;font-weight:600;text-transform:capitalize' }, fmtLong(dt.getTime())));
    pg.body.appendChild(evs.length ? Group(null, evs.map(e => ({ left: h('div', { style: 'width:4px;height:36px;border-radius:2px;background:' + (e.color || 'var(--accent)') }), title: e.title, sub: e.allDay ? 'Toute la journée' : (e.time || '') + (e.alert != null && e.alert >= 0 ? ' · rappel ' + (e.alert ? e.alert + ' min avant' : 'à l\'heure') : ''), onclick: () => this.edit(e) }))) : h('div', { style: 'padding:20px;text-align:center;color:var(--fg2)' }, 'Aucun événement'));
  },
  edit(e) {
    const isNew = !e.id; const ev = Object.assign({ id: Date.now(), title: '', date: this.sel, time: '12:00', allDay: false, alert: 10, note: '', color: '#0a84ff' }, e);
    const pg = Page({ title: isNew ? 'Nouvel événement' : 'Événement', large: false, modal: true, left: [{ label: 'Annuler', onclick: () => this.ctx.pop() }], right: [{ label: 'OK', bold: true, onclick: () => { if (!ev.title.trim()) { Toast('Titre requis', 'warning'); return; } if (isNew) this.events.push(ev); else Object.assign(e, ev); this.save(); this.ctx.pop(); this.draw(); } }] });
    const colors = ['#0a84ff', '#30d158', '#ff9f0a', '#ff375f', '#bf5af2', '#64d2ff'];
    pg.body.appendChild(Group(null, [{ label: 'Titre', input: true, left: true, placeholder: 'Titre', value: ev.title, onInput: v => ev.title = v }, { label: 'Date', input: true, left: true, type: 'date', value: ev.date, onInput: v => ev.date = v }, { title: 'Toute la journée', toggle: { on: ev.allDay, onchange: v => ev.allDay = v } }, { label: 'Heure', input: true, left: true, type: 'time', value: ev.time, onInput: v => ev.time = v }]));
    pg.body.appendChild(Group('Rappel', [{ el: h('select', { style: 'flex:1;font-size:17px;background:none;color:var(--fg)', onchange: e => ev.alert = parseInt(e.target.value) }, [[-1, 'Aucun'], [0, 'À l\'heure'], [5, '5 minutes avant'], [10, '10 minutes avant'], [30, '30 minutes avant'], [60, '1 heure avant']].map(o => h('option', { value: o[0], selected: o[0] === ev.alert, style: 'color:#000' }, o[1]))) }]));
    pg.body.appendChild(Group('Couleur', [{ el: h('div', { style: 'display:flex;gap:12px;padding:10px 0' }, colors.map(c => h('div', { style: `width:30px;height:30px;border-radius:50%;background:${c};border:3px solid ${c === ev.color ? 'var(--fg)' : 'transparent'}`, onclick: (x) => { ev.color = c; $$('div', x.target.parentNode).forEach(d => d.style.borderColor = 'transparent'); x.target.style.borderColor = 'var(--fg)'; } }))) }]));
    pg.body.appendChild(Group('Note', [{ input: true, multiline: true, left: true, rows: 3, placeholder: 'Note', value: ev.note, onInput: v => ev.note = v }]));
    if (!isNew) pg.body.appendChild(Group(null, [{ title: 'Supprimer', danger: true, center: true, onclick: () => { this.events = this.events.filter(x => x !== e); this.save(); this.ctx.pop(); this.draw(); } }]));
    this.ctx.push(pg);
  },
};
const ymd = d => d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate());
registerApp({ id: 'calendar', name: 'Calendrier', icon: 'calendar', grad: ['#ffffff', '#e5e5ea'], glyphFn: () => { const d = clockDate(); return '<div class="cal-ico"><small>' + DAYS[d.getDay()].slice(0, 3).toUpperCase() + '</small><b>' + d.getDate() + '</b></div>'; }, open: ctx => Calendar.open(ctx) });

/* ───────────── Horloge ───────────── */
const Clk = {
  alarms: [], sw: { start: 0, acc: 0, run: false, laps: [] }, tm: { left: 0, total: 0, run: false, end: 0 }, fired: {},
  async open(ctx) {
    this.ctx = ctx; this.alarms = (await rpc('kvGet', 'alarms')) || [];
    const tabs = [{ id: 'world', label: 'Horloge', icon: 'globe' }, { id: 'alarm', label: 'Réveils', icon: 'alarm' }, { id: 'sw', label: 'Chrono', icon: 'stopwatch' }, { id: 'tm', label: 'Minuteur', icon: 'hourglass' }];
    const holder = h('div', { style: 'position:absolute;inset:0' });
    const bar = TabBar(tabs, 'alarm', id => { this.tab = id; draw(); });
    const wrap = Page({ noNav: true, nopad: true, tabbar: bar }); wrap.body.style.cssText = 'position:relative;overflow:hidden'; wrap.body.appendChild(holder);
    ctx.root(wrap); this.tab = 'alarm';
    const draw = () => { clear(holder); clearInterval(this.ti); const pg = this['pg_' + this.tab](); holder.appendChild(pg.el); ctx.stack[0] = pg; pg.ctx = ctx; };
    this.draw = draw; draw();
  },
  saveAlarms() { rpc('kvSet', 'alarms', this.alarms); },
  pg_world() {
    const pg = Page({ title: 'Horloge mondiale' });
    const cities = [['Los Santos', 0], ['Paris', 9], ['New York', 12], ['Tokyo', 17], ['Londres', 8], ['Sydney', 18]];
    const list = h('div'); pg.body.appendChild(list);
    const draw = () => { const d = clockDate(); clear(list); list.appendChild(Group(null, cities.map(c => { const t = new Date(d.getTime() + c[1] * 3600e3); return { title: h('span', { style: 'font-size:20px' }, c[0]), sub: c[1] === 0 ? 'Aujourd\'hui, heure locale' : 'Aujourd\'hui, ' + (c[1] > 0 ? '+' : '') + c[1] + ' h', trailing: h('span', { style: 'font-size:40px;font-weight:300;font-variant-numeric:tabular-nums' }, pad(t.getHours()) + ':' + pad(t.getMinutes())) }; }))); };
    draw(); this.ti = setInterval(draw, 2000); return pg;
  },
  pg_alarm() {
    const pg = Page({ title: 'Réveils', right: [{ icon: 'plus', onclick: () => this.editAlarm({}) }] });
    const draw = () => {
      clear(pg.body);
      if (!this.alarms.length) { pg.body.appendChild(Empty('alarm', 'Aucun réveil', 'Touchez + pour en programmer un.')); return; }
      pg.body.appendChild(Group(null, this.alarms.sort((a, b) => a.time.localeCompare(b.time)).map(a => ({ title: h('span', { style: 'font-size:48px;font-weight:300;opacity:' + (a.on ? 1 : .45) }, a.time), sub: (a.label || 'Réveil') + (a.days && a.days.length ? ' · ' + a.days.map(d => 'dim lun mar mer jeu ven sam'.split(' ')[d]).join(' ') : ''), onclick: () => this.editAlarm(a), trailing: Toggle(a.on, v => { a.on = v; this.saveAlarms(); draw(); }) }))));
    };
    pg.draw = draw; this.redrawAlarms = draw; draw(); return pg;
  },
  editAlarm(a) {
    const isNew = !a.id; const al = Object.assign({ id: Date.now(), time: pad(clockDate().getHours()) + ':' + pad(clockDate().getMinutes()), label: '', days: [], on: true }, a);
    const pg = Page({ title: isNew ? 'Ajouter' : 'Modifier', large: false, modal: true, left: [{ label: 'Annuler', onclick: () => this.ctx.pop() }], right: [{ label: 'OK', bold: true, onclick: () => { if (isNew) this.alarms.push(al); else Object.assign(a, al); this.saveAlarms(); this.ctx.pop(); this.redrawAlarms(); } }] });
    pg.body.appendChild(h('div', { style: 'padding:30px 0;text-align:center' }, h('input', { type: 'time', value: al.time, style: 'font-size:58px;font-weight:300;background:var(--card);border-radius:16px;padding:10px 20px;color:var(--fg)', oninput: e => al.time = e.target.value })));
    pg.body.appendChild(Group('Répéter', [{ el: h('div', { style: 'display:flex;gap:6px;padding:10px 0;flex-wrap:wrap' }, ['D', 'L', 'M', 'M', 'J', 'V', 'S'].map((l, i) => h('div', { style: `width:38px;height:38px;border-radius:50%;display:grid;place-items:center;font-weight:600;background:${al.days.includes(i) ? 'var(--accent)' : 'var(--card2)'};color:${al.days.includes(i) ? '#fff' : 'var(--fg)'}`, onclick: (e) => { al.days.includes(i) ? al.days.splice(al.days.indexOf(i), 1) : al.days.push(i); e.target.style.background = al.days.includes(i) ? 'var(--accent)' : 'var(--card2)'; e.target.style.color = al.days.includes(i) ? '#fff' : 'var(--fg)'; } }, l))) }]));
    pg.body.appendChild(Group(null, [{ label: 'Nom', input: true, left: true, placeholder: 'Réveil', value: al.label, onInput: v => al.label = v }]));
    if (!isNew) pg.body.appendChild(Group(null, [{ title: 'Supprimer le réveil', danger: true, center: true, onclick: () => { this.alarms = this.alarms.filter(x => x !== a); this.saveAlarms(); this.ctx.pop(); this.redrawAlarms(); } }]));
    this.ctx.push(pg);
  },
  pg_sw() {
    const pg = Page({ title: 'Chronomètre', large: false });
    const disp = h('div', { style: 'font-size:76px;font-weight:200;text-align:center;font-variant-numeric:tabular-nums;padding:40px 0 30px' }, '00:00,00'), laps = h('div');
    const fmt = (ms) => { const t = Math.floor(ms / 10), cs = t % 100, s = Math.floor(t / 100) % 60, m = Math.floor(t / 6000); return pad(m) + ':' + pad(s) + ',' + pad(cs); };
    const el = () => this.sw.acc + (this.sw.run ? Date.now() - this.sw.start : 0);
    const draw = () => { disp.textContent = fmt(el()); };
    const btns = h('div', { style: 'display:flex;justify-content:space-around;padding:0 40px' });
    const redraw = () => {
      clear(btns);
      btns.appendChild(h('button.btn.sec', { style: 'width:90px;height:90px;border-radius:50%;background:var(--card2);color:var(--fg)', onclick: () => { if (this.sw.run) { this.sw.laps.unshift(el()); drawLaps(); } else { this.sw = { start: 0, acc: 0, run: false, laps: [] }; draw(); drawLaps(); } } }, this.sw.run ? 'Tour' : 'Réinit.'));
      btns.appendChild(h('button.btn', { style: `width:90px;height:90px;border-radius:50%;background:${this.sw.run ? 'rgba(255,69,58,.25)' : 'rgba(48,209,88,.25)'};color:${this.sw.run ? 'var(--red)' : 'var(--green)'}`, onclick: () => { if (this.sw.run) { this.sw.acc = el(); this.sw.run = false; } else { this.sw.start = Date.now(); this.sw.run = true; } redraw(); } }, this.sw.run ? 'Stop' : 'Start'));
    };
    const drawLaps = () => { clear(laps); this.sw.laps.forEach((l, i, arr) => laps.appendChild(h('div', { style: 'display:flex;justify-content:space-between;padding:12px 24px;border-bottom:.5px solid var(--sep);font-variant-numeric:tabular-nums' }, h('span', 'Tour ' + (arr.length - i)), h('span', fmt(l - (arr[i + 1] || 0)))))); };
    pg.body.appendChild(disp); pg.body.appendChild(btns); pg.body.appendChild(h('div', { style: 'height:20px' })); pg.body.appendChild(laps);
    redraw(); drawLaps(); draw(); this.ti = setInterval(draw, 50); return pg;
  },
  pg_tm() {
    const pg = Page({ title: 'Minuteur', large: false });
    const wrap = h('div', { style: 'padding:30px 20px;text-align:center' }); pg.body.appendChild(wrap);
    let mins = 5;
    const draw = () => {
      clear(wrap);
      if (this.tm.run) {
        const left = Math.max(0, Math.round((this.tm.end - Date.now()) / 1000));
        wrap.appendChild(h('div', { style: 'font-size:80px;font-weight:200;font-variant-numeric:tabular-nums;margin:50px 0' }, dur(left)));
        wrap.appendChild(h('button.btn.red', { style: 'width:150px;margin:auto', onclick: () => { this.tm.run = false; draw(); } }, 'Annuler'));
      } else {
        wrap.appendChild(h('div', { style: 'font-size:70px;font-weight:200;margin:30px 0' }, mins + ' min'));
        wrap.appendChild(h('input', { type: 'range', min: 1, max: 120, value: mins, style: 'width:100%', oninput: e => { mins = +e.target.value; draw(); } }));
        wrap.appendChild(h('div', { style: 'display:flex;gap:8px;justify-content:center;margin:18px 0' }, [1, 5, 10, 15, 30].map(m => h('button.chip', { onclick: () => { mins = m; draw(); } }, m + ' min'))));
        wrap.appendChild(h('button.btn.green', { style: 'width:150px;margin:20px auto 0', onclick: () => { this.tm = { run: true, end: Date.now() + mins * 60000 }; draw(); } }, 'Démarrer'));
      }
    };
    draw(); this.ti = setInterval(() => this.tm.run && draw(), 500); return pg;
  },
  /* sonnerie des réveils et du minuteur, même téléphone fermé */
  watch() {
    setInterval(() => {
      const d = clockDate(), key = pad(d.getHours()) + ':' + pad(d.getMinutes());
      (this.alarms || []).forEach(a => {
        if (!a.on || a.time !== key) return;
        if (a.days && a.days.length && !a.days.includes(d.getDay())) return;
        const k = a.id + ymd(d) + key; if (this.fired[k]) return; this.fired[k] = 1;
        this.ring(a.label || 'Réveil', a.time);
        if (!a.days || !a.days.length) { a.on = false; this.saveAlarms(); }
      });
      if (this.tm.run && Date.now() >= this.tm.end) { this.tm.run = false; this.ring('Minuteur', 'Terminé'); }
    }, 1000);
  },
  ring(title, sub) {
    Sound.alarm();
    const card = h('div.callbanner.incoming', { style: 'background:rgba(255,159,10,.95)' }, h('div', { html: icon('alarm', 30) }), h('div.nm', title, h('small', sub)), h('button.cb.r', { style: 'width:auto;padding:0 16px;border-radius:22px;font-weight:600', onclick: () => { Sound.stop(); card.remove(); } }, 'Arrêter'));
    if (S.open) { card.style.cssText += ';position:absolute;left:10px;right:10px;top:12px;z-index:190'; Screen().appendChild(card); } else $('#peek').appendChild(card);
    setTimeout(() => { if (card.isConnected) { Sound.stop(); card.remove(); } }, 60000);
  },
};
registerApp({ id: 'clock', name: 'Horloge', icon: 'clock', grad: ['#2c2c2e', '#000'], dark: true, open: ctx => Clk.open(ctx) });
Bus.on('boot', () => { rpc('kvGet', 'alarms').then(a => { Clk.alarms = a || []; }); Clk.watch(); Cal_watch(); });
function Cal_watch() {
  const fired = {};
  setInterval(async () => {
    if (!Calendar.events.length && !Calendar._loaded) { Calendar.events = (await rpc('kvGet', 'events')) || []; Calendar._loaded = true; }
    const d = clockDate();
    Calendar.events.forEach(e => {
      if (e.alert == null || e.alert < 0 || e.allDay) return;
      const t = new Date(e.date + 'T' + (e.time || '12:00') + ':00').getTime() - e.alert * 60000;
      const k = e.id + 'a' + t; if (fired[k]) return;
      if (d.getTime() >= t && d.getTime() < t + 90000) { fired[k] = 1; OS.notify({ app: 'calendar', title: e.title, body: e.alert ? 'Dans ' + e.alert + ' minutes' : 'Maintenant', icon: 'calendar' }); }
    });
  }, 15000);
}

/* ───────────── Calculette ───────────── */
const Calc = {
  open(ctx) {
    const pg = Page({ noNav: true, nopad: true }); pg.el.style.background = '#000';
    let cur = '0', prev = null, op = null, fresh = true;
    const disp = h('div.calc-disp', '0');
    const fmt = v => { const n = Number(v); if (!isFinite(n)) return 'Erreur'; const s = String(v); return s.length > 9 ? Number(n.toPrecision(9)).toString() : s; };
    const show = () => { disp.textContent = fmt(cur).replace('.', ','); disp.style.fontSize = Math.max(44, 90 - Math.max(0, disp.textContent.length - 6) * 8) + 'px'; };
    const calc = (a, b, o) => ({ '+': a + b, '−': a - b, '×': a * b, '÷': b === 0 ? NaN : a / b }[o]);
    const press = (k) => {
      Sound.click();
      if (/^[0-9]$/.test(k)) { cur = fresh || cur === '0' ? k : cur + k; fresh = false; }
      else if (k === ',') { if (fresh) { cur = '0.'; fresh = false; } else if (!cur.includes('.')) cur += '.'; }
      else if (k === 'AC') { cur = '0'; prev = null; op = null; fresh = true; }
      else if (k === '±') cur = String(-Number(cur));
      else if (k === '%') cur = String(Number(cur) / 100);
      else if (k === '=') { if (op != null && prev != null) { cur = String(calc(prev, Number(cur), op)); prev = null; op = null; fresh = true; } }
      else { if (op != null && prev != null && !fresh) { cur = String(calc(prev, Number(cur), op)); } prev = Number(cur); op = k; fresh = true; }
      show(); $$('.cbtn.op').forEach(b => b.classList.toggle('act', b.dataset.k === op && fresh));
    };
    const keys = [['AC', 'f'], ['±', 'f'], ['%', 'f'], ['÷', 'op'], ['7'], ['8'], ['9'], ['×', 'op'], ['4'], ['5'], ['6'], ['−', 'op'], ['1'], ['2'], ['3'], ['+', 'op'], ['0', 'z'], [','], ['=', 'op']];
    const grid = h('div.calc-grid', keys.map(k => h('button.cbtn' + (k[1] ? '.' + k[1] : ''), { 'data-k': k[0], onclick: () => press(k[0]) }, k[0])));
    pg.body.appendChild(h('div.calc', disp, grid));
    ctx.root(pg);
    const kd = e => { if (!$('.calc')) { document.removeEventListener('keydown', kd); return; } const m = { '*': '×', '/': '÷', '-': '−', 'Enter': '=', 'Escape': 'AC', ',': ',', '.': ',' }; const k = m[e.key] || e.key; if (/^[0-9+=%,]$/.test(k) || ['×', '÷', '−'].includes(k) || k === 'AC') press(k); };
    document.addEventListener('keydown', kd);
  },
};
registerApp({ id: 'calculator', name: 'Calculette', icon: 'calc', grad: ['#ff9f0a', '#e07800'], dark: true, open: ctx => Calc.open(ctx) });

/* ───────────── Météo ───────────── */
const Weather = {
  async open(ctx) {
    const pg = Page({ noNav: true, nopad: true }); pg.el.style.cssText += ';background:linear-gradient(180deg,#2b6cb0,#1a365d)';
    pg.body.appendChild(Spinner()); ctx.root(pg);
    const w = (await post('weather')) || { label: '—', temp: 20, icon: 'sun', next: '—', nextIcon: 'sun', hour: 12, minute: 0, wind: 0, day: 0 };
    clear(pg.body);
    const days = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
    const seed = Math.floor(Date.now() / 86400000);
    const rnd = (i) => Math.abs(Math.sin(seed * 9301 + i * 49297)) % 1;
    const ics = ['sun', 'cloudsun', 'cloud', 'rain', 'sun'];
    const hours = [...Array(8)].map((_, i) => { const hh = (w.hour + i) % 24; const t = Math.round(w.temp + Math.sin(((hh - 14) / 24) * Math.PI * 2) * -4 - 2 + (i * .0)); return { h: i === 0 ? 'Maint.' : pad(hh) + 'h', t, i: i < 3 ? w.icon : i < 5 ? w.nextIcon : (hh >= 20 || hh < 6 ? 'moon' : w.nextIcon) }; });
    pg.body.appendChild(h('div.wx', { style: 'color:#fff;text-align:center;padding:90px 20px 20px' },
      h('div', { style: 'font-size:34px' }, 'Los Santos'), h('div', { style: 'font-size:96px;font-weight:200;line-height:1.05' }, w.temp + '°'), h('div', { style: 'font-size:22px' }, w.label), h('div', { style: 'opacity:.8;margin-top:4px' }, 'Vent ' + w.wind + ' km/h · Ensuite : ' + w.next)));
    pg.body.appendChild(h('div.wxcard', { style: 'margin:0 16px 14px' }, h('div.wxh', 'Prévisions horaires'), h('div', { style: 'display:flex;gap:18px;overflow:auto;padding:10px 4px' }, hours.map(x => h('div', { style: 'text-align:center;flex:none;color:#fff' }, h('div', { style: 'font-size:14px' }, x.h), h('div', { style: 'margin:8px 0', html: icon(x.i, 26) }), h('div', { style: 'font-weight:600' }, x.t + '°'))))));
    pg.body.appendChild(h('div.wxcard', { style: 'margin:0 16px 14px' }, h('div.wxh', 'Prévisions sur 7 jours'), [...Array(7)].map((_, i) => { const lo = Math.round(w.temp - 5 + rnd(i) * 3), hi = Math.round(w.temp + 1 + rnd(i + 9) * 5); return h('div', { style: 'display:flex;align-items:center;gap:12px;padding:10px 0;color:#fff;border-top:.5px solid rgba(255,255,255,.2)' }, h('span', { style: 'width:60px' }, i === 0 ? 'Auj.' : days[(w.day + i) % 7]), h('span', { html: icon(i === 0 ? w.icon : ics[Math.floor(rnd(i + 3) * 5)], 22) }), h('span', { style: 'opacity:.6;margin-left:auto' }, lo + '°'), h('div', { style: 'width:80px;height:5px;border-radius:3px;background:linear-gradient(90deg,#64d2ff,#ffd60a)' }), h('span', { style: 'font-weight:600' }, hi + '°')); })));
    const info = h('div', { style: 'display:grid;grid-template-columns:1fr 1fr;gap:12px;margin:0 16px 30px' }, [['Vent', w.wind + ' km/h', 'gauge'], ['Ressenti', (w.temp - 1) + '°', 'sun'], ['Humidité', Math.round(40 + rnd(1) * 40) + ' %', 'rain'], ['UV', Math.round(rnd(4) * 8 + 1), 'sun']].map(x => h('div.wxcard', { style: 'margin:0' }, h('div.wxh', x[0]), h('div', { style: 'font-size:32px;color:#fff;margin-top:8px' }, x[1]))));
    pg.body.appendChild(info);
  },
};
registerApp({ id: 'weather', name: 'Météo', icon: 'cloudsun', grad: ['#4facfe', '#1b6fd6'], dark: true, open: ctx => Weather.open(ctx) });

/* ───────────── Mail ───────────── */
const Mail = {
  folder: 'inbox',
  async open(ctx) {
    this.ctx = ctx;
    const pg = Page({ title: 'Boîtes', right: [{ icon: 'edit', onclick: () => this.compose() }] });
    this.pg = pg; ctx.root(pg); this.root();
    S.unreadMail = (await rpc('mailUnread')) || 0; OS.setBadge('mail', S.unreadMail); this.root();
  },
  root() {
    const pg = this.pg; clear(pg.body);
    pg.body.appendChild(Group(null, [
      { icon: 'inbox', color: 'var(--accent)', title: 'Réception', value: S.unreadMail ? String(S.unreadMail) : '', chev: true, onclick: () => this.list('inbox', 'Réception') },
      { icon: 'send', color: '#ff9f0a', title: 'Envoyés', chev: true, onclick: () => this.list('sent', 'Envoyés') },
      { icon: 'trash', color: '#8e8e93', title: 'Corbeille', chev: true, onclick: () => this.list('trash', 'Corbeille') },
    ], 'Votre adresse : ' + S.me.mail));
  },
  list(folder, title) {
    const pg = Page({ title, back: 'Boîtes', right: [{ icon: 'edit', onclick: () => this.compose() }] });
    pg.body.appendChild(Spinner());
    this.ctx.push(pg);
    const draw = async () => {
      const rows = (await rpc('mailList', folder)) || []; clear(pg.body);
      if (!rows.length) { pg.body.appendChild(Empty('mail', 'Aucun message')); return; }
      pg.body.appendChild(Group(null, rows.map(m => ({
        left: h('div', { style: 'width:10px' }, !m.seen && folder === 'inbox' ? h('div', { style: 'width:10px;height:10px;border-radius:50%;background:var(--accent)' }) : null),
        title: h('div', { style: 'display:flex;justify-content:space-between;gap:6px' }, h('span', { style: 'font-weight:' + (m.seen ? 400 : 600) }, folder === 'sent' ? 'À : ' + m.to_addr : m.from_addr.replace(/<.*>/, '').trim()), h('span', { style: 'font-size:14px;color:var(--fg2)' }, fmtDay(m.created))),
        sub: m.subject + ' — ' + (m.body || '').replace(/\n/g, ' '), onclick: () => this.read(m, folder, draw), onlong: () => this.menu(m, draw),
      }))));
    };
    draw();
  },
  menu(m, redraw) { ActionSheet(m.subject, [{ label: m.starred ? 'Retirer l\'étoile' : 'Marquer d\'une étoile', onclick: async () => { await rpc('mailFlag', m.id, 'starred', !m.starred); redraw(); } }, { label: 'Corbeille', red: true, onclick: async () => { await rpc('mailFlag', m.id, m.folder === 'trash' ? 'delete' : 'trash'); redraw(); } }]); },
  async read(m, folder, redraw) {
    if (!m.seen) { await rpc('mailFlag', m.id, 'seen', true); m.seen = 1; if (folder === 'inbox') { S.unreadMail = Math.max(0, S.unreadMail - 1); OS.setBadge('mail', S.unreadMail); } }
    const pg = Page({ title: 'Message', large: false, back: 'Retour', right: [{ icon: 'trash', onclick: async () => { await rpc('mailFlag', m.id, folder === 'trash' ? 'delete' : 'trash'); this.ctx.pop(); redraw(); } }] });
    pg.body.appendChild(h('div', { style: 'padding:16px 20px' }, h('div', { style: 'font-size:22px;font-weight:600;margin-bottom:12px' }, m.subject), h('div', { style: 'display:flex;gap:10px;align-items:center;padding-bottom:12px;border-bottom:.5px solid var(--sep)' }, avatar(m.from_addr, 40), h('div', h('b', m.from_addr), h('div', { style: 'font-size:13px;color:var(--fg2)' }, 'À : ' + m.to_addr + ' · ' + fmtDay(m.created)))), h('div', { style: 'padding:16px 0;font-size:17px;line-height:1.4;white-space:pre-wrap;user-select:text', html: linkify(m.body) })));
    if (folder === 'inbox') pg.body.appendChild(Group(null, [{ icon: 'reply', color: 'var(--accent)', title: 'Répondre', onclick: () => this.compose(m.from_addr.replace(/.*<(.*)>/, '$1'), 'Re: ' + m.subject.replace(/^Re: /, '')) }]));
    this.ctx.push(pg);
  },
  compose(to, subject) {
    const v = { to: to || '', subject: subject || '', body: '' };
    const pg = Page({ title: 'Nouveau message', large: false, modal: true, left: [{ label: 'Annuler', onclick: () => this.ctx.pop() }], right: [{ label: 'Envoyer', bold: true, onclick: async () => { const ok = await rpc('mailSend', v.to, v.subject, v.body); if (!ok) { Toast(rpc.err || 'Envoi impossible', 'warning'); return; } Toast('Message envoyé', 'send'); this.ctx.pop(); } }] });
    pg.body.appendChild(Group(null, [{ label: 'À', input: true, left: true, placeholder: 'adresse@' + ((S.config && S.config.mailDomain) || 'aero.mail'), value: v.to, onInput: x => v.to = x }, { label: 'Objet', input: true, left: true, placeholder: 'Objet', value: v.subject, onInput: x => v.subject = x }, { input: true, multiline: true, left: true, rows: 10, placeholder: 'Votre message', onInput: x => v.body = x }]));
    this.ctx.push(pg);
  },
};
registerApp({ id: 'mail', name: 'Mail', icon: 'mail', grad: ['#64b5ff', '#0a6cf0'], open: ctx => Mail.open(ctx) });

/* ───────────── Wallet ───────────── */
const Wallet = {
  async open(ctx) {
    const pg = Page({ title: 'Wallet' }); ctx.root(pg); pg.body.appendChild(Spinner());
    const b = (await rpc('bank')) || { bank: 0, cash: 0 };
    clear(pg.body);
    const me = S.me;
    const card = (bg, top, mid, bot, ic) => h('div.wcard', { style: `background:${bg}` }, h('div', { style: 'display:flex;justify-content:space-between;align-items:center;font-weight:700;letter-spacing:.06em' }, h('span', top), h('span', { html: icon(ic, 26) })), h('div', { style: 'font-size:30px;font-weight:600;margin-top:auto' }, mid), h('div', { style: 'display:flex;justify-content:space-between;font-size:13px;opacity:.85;margin-top:8px' }, bot));
    pg.body.appendChild(h('div', { style: 'padding:6px 16px;display:grid;gap:14px' },
      card('linear-gradient(135deg,#0f2027,#2c5364)', (S.config.brand || 'Aero').toUpperCase() + ' BANK', money(b.bank), [h('span', me.name), h('span', '•••• ' + String(me.number).slice(-4))], 'card'),
      card('linear-gradient(135deg,#134e5e,#71b280)', 'ESPÈCES', money(b.cash), [h('span', 'Argent liquide'), h('span', '')], 'money'),
      card('linear-gradient(135deg,#373b44,#4286f4)', 'IDENTITÉ', me.name, [h('span', me.jobLabel || 'Citoyen'), h('span', fmtNum(me.number))], 'user')));
    pg.body.appendChild(Group(null, [{ icon: 'bank', color: '#30d158', title: 'Ouvrir Aero Bank', chev: true, onclick: () => OS.openApp('bank') }]));
  },
};
registerApp({ id: 'wallet', name: 'Wallet', icon: 'wallet', grad: ['#3a3a3c', '#000'], dark: true, open: ctx => Wallet.open(ctx) });

/* ───────────── AirShare ───────────── */
const AirShare = {
  async open(ctx) {
    const pg = Page({ title: 'AirShare' }); ctx.root(pg);
    const draw = async () => {
      clear(pg.body);
      pg.body.appendChild(h('div', { style: 'text-align:center;padding:30px 30px 10px;color:var(--fg2)' }, h('div.airpulse', { html: icon('share', 40) }), h('p', { style: 'margin-top:14px;line-height:1.4' }, 'Partagez photos, contacts, notes et positions avec les personnes proches.')));
      pg.body.appendChild(h('div', { style: 'padding:0 16px 10px' }, h('button.btn.sec.block', { onclick: draw }, 'Actualiser')));
      pg.body.appendChild(Spinner());
      const near = (await rpc('airNearby')) || []; $('.spinner', pg.body).remove();
      pg.body.appendChild(near.length ? Group('À proximité', near.map(n => ({ left: avatar(n.name, 36), title: n.name, sub: n.distance + ' m', chev: true, onclick: () => this.pickSend(n) }))) : Empty('users', 'Personne à proximité', 'Approchez-vous d\'une personne dont le téléphone est actif.'));
    };
    draw();
  },
  async pickSend(n) {
    ActionSheet('Envoyer à ' + n.name, [
      { label: 'Une photo', onclick: () => Messages.pickPhoto(async url => this.deliver(n.src, 'photo', { url })) },
      { label: 'Un contact', onclick: async () => { const c = await pickContact(); c && this.deliver(n.src, 'contact', { name: c.name, number: c.number }); } },
      { label: 'Ma position', onclick: async () => { const p = await post('position'); p && this.deliver(n.src, 'location', { x: p.x, y: p.y }); } },
      { label: 'Une note', onclick: () => { const ns = Notes.list; Sheet({ title: 'Notes', render: (b, close) => { b.appendChild(ns.length ? Group(null, ns.map(x => ({ title: x.title || 'Note', onclick: () => { close(); this.deliver(n.src, 'note', { title: x.title, body: x.body }); } }))) : Empty('note', 'Aucune note')); } }); } },
    ]);
  },
  async deliver(src, kind, data) { const r = await rpc('airSend', src, kind, data); Toast(r ? 'Demande envoyée' : (rpc.err || 'Échec'), 'share'); },
  /* utilisé depuis d'autres apps : choisit le destinataire à proximité puis envoie */
  async send(kind, data) {
    const near = (await rpc('airNearby')) || [];
    if (!near.length) { Alert('AirShare', 'Personne à proximité.', [{ label: 'OK', bold: true }]); return; }
    Sheet({ title: 'AirShare', render: (b, close) => { b.appendChild(Group('À proximité', near.map(n => ({ left: avatar(n.name, 34), title: n.name, sub: n.distance + ' m', onclick: () => { close(); this.deliver(n.src, kind, data); } })))); } });
  },
};
registerApp({ id: 'airshare', name: 'AirShare', icon: 'share', grad: ['#32ade6', '#0a84ff'], open: ctx => AirShare.open(ctx) });
