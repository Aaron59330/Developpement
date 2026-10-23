/* ═══════════ Téléphone : clavier, récents, favoris + écran d'appel ═══════════ */
const Calls = {
  timer: null, el: null,
  setState(c) { S.call = c; post('callState', { ringing: c && c.state === 'incoming' }); OS.drawIsland(); Bus.emit('call', c); },

  async dial(number, hidden) {
    number = String(number || '').replace(/[^\d]/g, '');
    if (!number) return;
    if (S.call) { Toast('Un appel est déjà en cours', 'phone'); return; }
    if (S.settings.airplane) { Alert('Mode avion', 'Désactivez le mode avion pour passer un appel.', [{ label: 'OK', bold: true }]); return; }
    this.setState({ state: 'dialing', number, hidden: !!hidden, since: Date.now() });
    this.show();
    const r = await rpc('callStart', number, !!hidden);
    if (!r || !r.ok) { this.end(); Alert('Appel impossible', (r && r.error) || rpc.err || 'Réseau indisponible', [{ label: 'OK', bold: true }]); return; }
    if (r.service) { this.end(); OS.openApp('services'); Bus.emit('serviceDial', r.service); return; }
    if (r.line) S.call.service = r.line;
    if (r.state === 'busy') { this.setState(Object.assign(S.call, { state: 'busy' })); this.show(); Sound.busy(); setTimeout(() => this.end(), 2400); return; }
    if (r.state === 'unavailable') { this.setState(Object.assign(S.call, { state: 'unavailable' })); this.show(); Sound.busy(); setTimeout(() => this.end(), 2400); return; }
    S.call.id = r.id; S.call.state = 'ringing'; this.show(); Sound.ringback();
  },

  incoming(d) {
    if (S.call) return;
    this.setState({ state: 'incoming', number: d.number, hidden: d.hidden, id: d.id, silent: d.silent, service: d.service });
    if (!d.silent) Sound.ring();
    if (S.open && !S.locked && OS.current) this.banner(); else this.show();
    if (!S.open) this.peek();
  },

  async answer() { const c = S.call; if (!c || c.state !== 'incoming') return; Sound.stop(); await rpc('callAnswer', c.id); },
  async decline() { const c = S.call; if (!c) return; Sound.stop(); await rpc('callEnd', c.state === 'incoming' ? 'declined' : 'ended'); this.end(); },
  hang() { return this.decline(); },
  connected(d) {
    Sound.stop(); const c = S.call || { number: d.number };
    c.state = 'active'; c.since = Date.now(); c.id = d.id; c.number = d.number || c.number; c.muted = false; if (d.service) c.service = d.service;
    this.setState(c); $$('.callbanner', Screen()).forEach(b => b.remove()); $('#peek') && clear($('#peek')); if (!S.open) this.peek(); this.show();
    clearInterval(this.timer); this.timer = setInterval(() => { OS.drawIsland(); this.tick(); }, 1000);
  },
  ended(d) {
    Sound.stop(); clearInterval(this.timer);
    const c = S.call;
    if (c) { c.state = 'ended'; c.reason = d && d.reason; this.show(); }
    setTimeout(() => this.end(), 900);
    Bus.emit('callsChanged');
  },
  end() {
    Sound.stop(); clearInterval(this.timer); this.setState(null);
    if (this.el) { this.el.remove(); this.el = null; }
    $$('.callbanner', Screen()).forEach(b => b.remove()); $('#peek') && clear($('#peek'));
  },

  tick() { const t = $('.cs-time'); if (t && S.call && S.call.state === 'active') t.textContent = dur((Date.now() - S.call.since) / 1000); },

  /* ───── bandeau (téléphone fermé ou autre application ouverte) ───── */
  banner() {
    $$('.callbanner', Screen()).forEach(b => b.remove());
    const c = S.call; if (!c) return;
    const b = h('div.callbanner.incoming', { style: 'position:absolute;left:10px;right:10px;top:12px;z-index:186' },
      avatar(contactName(c.number), 44, (contactOf(c.number) || {}).avatar), h('div.nm', contactName(c.number), h('small', c.service ? 'Appel pour : ' + c.service : 'Appel entrant')),
      h('button.cb.r', { html: icon('phoneDown', 22), onclick: () => this.decline() }), h('button.cb.g', { html: icon('phoneUp', 22), onclick: () => { b.remove(); this.answer(); } }));
    Screen().appendChild(b);
  },
  peek() {
    const peek = $('#peek'); if (!peek) return; clear(peek);
    const c = S.call; if (!c) return;
    const nm = contactName(c.number);
    if (c.state === 'incoming') peek.appendChild(h('div.callbanner.incoming', avatar(nm, 44, (contactOf(c.number) || {}).avatar), h('div.nm', nm, h('small', (c.service ? 'Appel pour : ' + c.service : 'Appel entrant') + ' · ↑ décrocher · ↓ refuser')), h('button.cb.r', { html: icon('phoneDown', 22), onclick: () => this.decline() }), h('button.cb.g', { html: icon('phoneUp', 22), onclick: () => this.answer() })));
    else if (c.state === 'active') peek.appendChild(h('div.callbanner', h('div.nm', nm, h('small', 'Appel en cours · ↓ raccrocher')), h('button.cb.r', { html: icon('phoneDown', 22), onclick: () => this.decline() })));
  },

  /* ───── écran d'appel plein écran ───── */
  show() {
    if (!S.call) return;
    const c = S.call;
    if (!this.el) { this.el = h('div.callscreen'); Screen().appendChild(this.el); }
    const el = this.el; clear(el);
    const nm = c.hidden && c.state === 'incoming' ? 'Numéro masqué' : contactName(c.number);
    const ct = contactOf(c.number);
    const labels = { dialing: 'Appel en cours…', ringing: 'Sonnerie…', incoming: 'Appel entrant', active: '', busy: 'Occupé', unavailable: 'Indisponible', ended: 'Appel terminé' };
    el.appendChild(h('div.cs-top', avatar(nm, 110, ct && ct.avatar), h('div.cs-name', nm), c.service ? h('div.cs-sub', (c.state === 'incoming' ? 'Appel pour : ' : 'Service : ') + c.service) : (c.number && !ct ? null : h('div.cs-sub', fmtNum(c.number))), h('div.cs-state' + (c.state === 'active' ? '.cs-time' : ''), c.state === 'active' ? dur((Date.now() - c.since) / 1000) : labels[c.state])));
    if (c.state === 'incoming') {
      el.appendChild(h('div.cs-incoming',
        h('div', h('button.cs-btn.r', { html: icon('phoneDown', 32), onclick: () => this.decline() }), h('small', 'Refuser')),
        h('div', h('button.cs-btn.g', { html: icon('phoneUp', 32), onclick: () => this.answer() }), h('small', 'Accepter'))));
    } else {
      const toggles = h('div.cs-grid',
        this.cbtn('mic', c.muted ? 'Muet ✓' : 'Muet', c.muted, () => { c.muted = !c.muted; post('callMute', { state: c.muted }); this.show(); }),
        this.cbtn('keypad', 'Clavier', false, () => this.dtmf()),
        this.cbtn('user', 'Contact', false, () => { if (c.number) { if (ct) Contacts.card(ct); else Contacts.edit({ number: c.number }); } }),
        this.cbtn('message', 'Message', false, () => { if (c.number) { Messages.openWith(c.number); } }),
        this.cbtn('pin', 'Position', false, async () => { const p = await post('position'); if (p && c.number) { const r = await rpc('msgSend', { to: c.number, kind: 'location', body: 'Ma position', meta: { x: p.x, y: p.y, label: p.street } }); Toast(r && r.ok ? 'Position envoyée' : 'Échec', 'pin'); } }),
        this.cbtn('plus', 'Ajouter', false, () => Toast('Appel à plusieurs bientôt disponible', 'info')));
      el.appendChild(toggles);
      el.appendChild(h('div.cs-end', h('button.cs-btn.r', { html: icon('phoneDown', 32), onclick: () => this.hang() })));
    }
  },
  cbtn(ic, label, on, fn) { return h('div', h('button.cs-b' + (on ? '.on' : ''), { html: icon(ic, 26), onclick: fn }), h('small', label)); },
  dtmf() {
    let typed = '';
    const sh = Sheet({ title: 'Clavier', render(body) {
      const disp = h('div', { style: 'text-align:center;font-size:30px;height:44px;letter-spacing:4px' });
      const pad_ = h('div.dialpad', { style: 'padding:0 30px' });
      '123456789*0#'.split('').forEach(k => pad_.appendChild(h('button', { onclick: () => { typed += k; disp.textContent = typed; Sound.dial(k); } }, k)));
      body.appendChild(disp); body.appendChild(pad_);
    } });
  },
};
Bus.on('push:incomingCall', d => Calls.incoming(d));
Bus.on('push:callConnect', d => Calls.connected(d));
Bus.on('push:callEnd', d => Calls.ended(d));
Bus.on('push:missedCall', d => {
  S.missed = (S.missed || 0) + 1; OS.setBadge('phone', S.missed);
  OS.notify({ app: 'phone', title: d.service ? 'Appel manqué — ' + d.service : 'Appel manqué', body: d.hidden ? 'Numéro masqué' : contactName(d.number), icon: 'phoneMissed' });
});
window.addEventListener('message', e => {
  const d = e.data || {};
  if (d.action === 'quickAnswer') Calls.answer();
  if (d.action === 'quickDecline') Calls.decline();
});

const Phone = {
  tab: 'keypad', ctx: null, buf: '',
  async open(ctx) {
    this.ctx = ctx;
    const tabs = [{ id: 'favs', label: 'Favoris', icon: 'star' }, { id: 'recents', label: 'Récents', icon: 'clock', badge: S.missed || 0 }, { id: 'contacts', label: 'Contacts', icon: 'users' }, { id: 'keypad', label: 'Clavier', icon: 'keypad' }];
    const holder = h('div', { style: 'position:absolute;inset:0' });
    const bar = TabBar(tabs, this.tab, (id) => { this.tab = id; draw(); });
    const draw = () => {
      S.missed = 0; OS.setBadge('phone', 0); bar.setBadge('recents', 0);
      clear(holder);
      const fn = { favs: this.favs, recents: this.recents, contacts: this.contactsTab, keypad: this.keypad }[this.tab];
      const pg = fn.call(this, ctx);
      holder.appendChild(pg.el); pg.ctx = ctx; if (pg.opts.onShow) pg.opts.onShow(pg);
      ctx.stack[0] = pg;
    };
    const wrap = Page({ noNav: true, nopad: true, tabbar: bar });
    wrap.body.appendChild(holder); wrap.body.style.position = 'relative'; wrap.body.style.overflow = 'hidden';
    ctx.root(wrap);
    draw();
    this.redraw = draw;
    Bus.on('callsChanged', () => { this.tab === 'recents' && draw(); });
  },
  favs() {
    const pg = Page({ title: 'Favoris', right: [{ icon: 'plus', onclick: () => pickContact().then(c => c && rpc('contactFlag', c.id, 'favorite', true).then(() => Core.reloadContacts().then(() => this.redraw()))) }] });
    const favs = S.contactList.filter(c => c.favorite);
    if (!favs.length) pg.body.appendChild(Empty('star', 'Aucun favori', 'Ajoutez vos contacts préférés pour les appeler en un geste.'));
    else pg.body.appendChild(Group(null, favs.map(c => ({ left: avatar(c.name, 40, c.avatar), title: c.name, sub: fmtNum(c.number), trailing: h('span', { html: icon('phone', 20), style: 'color:var(--accent)' }), onclick: () => Calls.dial(c.number), onlong: () => Contacts.card(c) }))));
    return pg;
  },
  recents() {
    const pg = Page({ title: 'Récents', right: [{ label: 'Effacer', onclick: async () => { if (await Confirm('Effacer l\'historique ?', null, 'Effacer', true)) { await rpc('callLogClear'); this.redraw(); } } }] });
    pg.body.appendChild(Spinner());
    rpc('callLog').then(rows => {
      clear(pg.body); rows = rows || [];
      if (!rows.length) { pg.body.appendChild(Empty('clock', 'Aucun appel récent')); return; }
      const me = S.me.number;
      const out = [];
      rows.forEach(r => { const other = r.caller === me ? r.callee : r.caller; const dir = r.caller === me ? 'out' : 'in'; const last = out[out.length - 1]; if (last && last.other === other && last.dir === dir && last.status === r.status) { last.count++; } else out.push({ other: (dir === 'in' && r.hidden) ? '' : other, dir, status: r.status, created: r.created, duration: r.duration, count: 1 }); });
      pg.body.appendChild(Group(null, out.map(r => {
        const missed = r.dir === 'in' && r.status !== 'answered';
        return { left: h('div', { style: 'width:30px;display:grid;place-items:center;color:' + (missed ? 'var(--red)' : 'var(--fg2)'), html: icon(missed ? 'phoneMissed' : r.dir === 'out' ? 'phoneOut' : 'phoneIn', 20) }),
          title: h('span', { style: missed ? 'color:var(--red)' : '' }, contactName(r.other) + (r.count > 1 ? ' (' + r.count + ')' : '')), titleHtml: false,
          sub: (r.dir === 'out' ? 'Sortant' : r.status === 'answered' ? 'Entrant' : r.status === 'declined' ? 'Refusé' : 'Manqué') + (r.duration ? ' · ' + dur(r.duration) : ''),
          trailing: h('div', { style: 'display:flex;gap:10px;align-items:center;color:var(--fg2);font-size:15px' }, fmtDay(r.created), h('span', { style: 'color:var(--accent)', html: icon('info', 22), onclick: (e) => { e.stopPropagation(); const c = contactOf(r.other); c ? Contacts.card(c) : Contacts.edit({ number: r.other }); } })),
          onclick: () => r.other && Calls.dial(r.other) };
      })));
    });
    return pg;
  },
  contactsTab() {
    const pg = Page({ title: 'Contacts', right: [{ icon: 'plus', onclick: () => Contacts.edit({}) }] });
    pg.body.appendChild(SearchBar({ onInput: q => draw(q) }));
    const list = h('div'); pg.body.appendChild(list);
    const draw = (q) => {
      clear(list); q = (q || '').toLowerCase();
      const cs = S.contactList.filter(c => !q || c.name.toLowerCase().includes(q) || c.number.includes(q));
      if (!cs.length) { list.appendChild(Empty('users', 'Aucun contact')); return; }
      list.appendChild(Group(null, cs.map(c => ({ left: avatar(c.name, 36, c.avatar), title: c.name, sub: fmtNum(c.number), onclick: () => Calls.dial(c.number), onlong: () => Contacts.card(c) }))));
    };
    draw('');
    return pg;
  },
  keypad() {
    const pg = Page({ noNav: true, nopad: true });
    let buf = '';
    const disp = h('div.dp-disp'), addBtn = h('button.dp-add.hidden', { onclick: () => Contacts.edit({ number: buf.replace(/[^\d]/g, '') }) }, 'Ajouter au contact');
    const upd = () => { disp.textContent = /^\*31#/.test(buf) ? '🔒 ' + fmtNum(buf.slice(4)) : (/^\d+$/.test(buf) && buf.length > 3 ? fmtNum(buf) : buf); addBtn.classList.toggle('hidden', !buf); const c = contactOf(buf); if (c) addBtn.textContent = c.name; };
    const press = (k) => { if (buf.length >= 20) return; buf += k; Sound.dial(k); upd(); };
    const letters = { 2: 'ABC', 3: 'DEF', 4: 'GHI', 5: 'JKL', 6: 'MNO', 7: 'PQRS', 8: 'TUV', 9: 'WXYZ', 0: '+' };
    const padEl = h('div.dialpad');
    '123456789*0#'.split('').forEach(k => padEl.appendChild(h('button', { onclick: () => press(k) }, k, h('small', letters[k] || ' '))));
    const call = h('button.dp-call', { html: icon('phoneUp', 32), onclick: () => { if (!buf) return; let n = buf, hid = false; if (n.startsWith('*31#')) { hid = true; n = n.slice(4); } Calls.dial(n, hid); buf = ''; upd(); } });
    const del = h('button.dp-del', { html: icon('x', 26), onclick: () => { buf = buf.slice(0, -1); upd(); }, ondblclick: () => { buf = ''; upd(); } });
    pg.body.appendChild(h('div.dp-wrap', h('div', { style: 'height:56px' }), disp, addBtn, padEl, h('div.dp-row', h('span'), call, del)));
    pg.opts.onShow = () => { const f = (e) => { if (!$('.dp-wrap')) { document.removeEventListener('keydown', f); return; } if (/^[0-9*#]$/.test(e.key) && !(e.target.tagName === 'INPUT')) press(e.key); else if (e.key === 'Backspace' && e.target.tagName !== 'INPUT') { buf = buf.slice(0, -1); upd(); } else if (e.key === 'Enter' && e.target.tagName !== 'INPUT') call.click(); }; document.addEventListener('keydown', f); };
    return pg;
  },
};
registerApp({ id: 'phone', name: 'Téléphone', icon: 'phone', grad: ['#4cd964', '#1fa83e'], dark: false, open: ctx => Phone.open(ctx) });
