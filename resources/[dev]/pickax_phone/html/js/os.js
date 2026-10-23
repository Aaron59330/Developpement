/* ═══════════ Système : écran de verrouillage, accueil, notifications, centre de contrôle, multitâche ═══════════ */
const Apps = {
  defs: {},
  register(d) { this.defs[d.id] = d; },
  get(id) { return this.defs[id]; },
};
const registerApp = d => Apps.register(d);

const OS = {
  current: null,          // { id, ctx, el }
  running: {},            // id → { ctx, el }
  order: [],              // ordre de récence
  homePage: 0, editing: false, lockTimer: null, started: false,

  /* ───── construction ───── */
  build() {
    const sc = Screen(); clear(sc);
    sc.appendChild(h('div.wall#wall'));
    sc.appendChild(h('div#home.home'));
    sc.appendChild(h('div#statusbar', h('div.l#sb-l'), h('div.r#sb-r')));
    sc.appendChild(h('div#island'));
    sc.appendChild(h('div#homebar'));
    sc.appendChild(h('div.dim#dim'));
    sc.appendChild(h('div.nc#nc'));
    sc.appendChild(h('div.cc#cc'));
    sc.appendChild(h('div.lock#lock'));
    this.bindGestures();
    this.drawWallpaper(); this.drawHome(); this.drawLock(); this.drawStatus(); this.applyTheme();
    $('#home').classList.add('under');
  },

  applyTheme() {
    const t = S.settings.theme === 'light' ? 'light' : 'dark';
    document.documentElement.dataset.theme = t;
    document.documentElement.style.setProperty('--accent', S.settings.accent || '#0a84ff');
    const dim = $('#dim'); if (dim) dim.style.opacity = String(Math.max(0, (100 - (S.settings.brightness == null ? 100 : S.settings.brightness)) / 100 * .75));
    document.documentElement.style.fontSize = ((S.settings.textSize || 100) / 100 * 16) + 'px';
    this.updateBars();
  },
  wallpaperCss(id, custom) {
    if (custom && /^https?:/.test(custom)) return `url("${custom.replace(/"/g, '%22')}") center/cover`;
    const w = (S.config.wallpapers || []).find(x => x.id === id) || (S.config.wallpapers || [])[0];
    return w ? w.css : '#123';
  },
  drawWallpaper() {
    const w = $('#wall'); if (!w) return;
    const locked = S.locked;
    const id = locked ? (S.settings.lockWallpaper || S.settings.wallpaper) : S.settings.wallpaper;
    w.style.background = this.wallpaperCss(id, S.settings.customWallpaper && (locked ? S.settings.lockWallpaper === 'custom' : S.settings.wallpaper === 'custom') ? S.settings.customWallpaper : null);
    this.updateBars();
  },
  barColor() {
    if (this.current && !S.locked) return (document.documentElement.dataset.theme === 'light' && !this.current.dark) ? '#000' : '#fff';
    const id = S.locked ? (S.settings.lockWallpaper || S.settings.wallpaper) : S.settings.wallpaper;
    return id === 'light' ? '#111' : '#fff';
  },
  updateBars() {
    const sc = Screen(); if (!sc) return;
    const c = this.barColor();
    sc.style.setProperty('--sb', c); sc.style.setProperty('--hb', c);
    const light = this.current && !S.locked && document.documentElement.dataset.theme === 'light' && !this.current.dark;
    $('#homebar') && ($('#homebar').style.background = light ? '#000' : c);
  },

  /* ───── barre d'état + îlot ───── */
  drawStatus() {
    const l = $('#sb-l'), r = $('#sb-r'); if (!l) return;
    const d = clockDate();
    l.textContent = S.settings.hour24 === false ? ((d.getHours() % 12) || 12) + ':' + pad(d.getMinutes()) : pad(d.getHours()) + ':' + pad(d.getMinutes());
    const air = S.settings.airplane;
    const lvl = Math.round(S.battery);
    clear(r);
    r.appendChild(h('span', { html: air ? icon('plane', 16) : icon('signal', 16) }));
    if (!air && S.settings.wifi) r.appendChild(h('span', { html: icon('wifi', 16) }));
    if (S.settings.dnd) r.appendChild(h('span', { html: icon('moon', 15) }));
    r.appendChild(h('span.batt', h('span', lvl + '%'), h('i' + (lvl <= 20 ? '.low' : '') + (S.charging ? '.chg' : ''), h('b', { style: `width:${Math.max(6, lvl)}%` }))));
    this.drawIsland();
  },
  drawIsland() {
    const isl = $('#island'); if (!isl) return;
    clear(isl);
    const c = S.call;
    isl.className = '';
    if (c && c.state === 'active') { isl.classList.add('call'); isl.appendChild(h('span.dot')); isl.appendChild(h('span.txt', dur((Date.now() - c.since) / 1000))); }
    else if (c && (c.state === 'ringing' || c.state === 'incoming')) { isl.classList.add('call'); isl.appendChild(h('span.dot', { style: 'background:var(--orange)' })); isl.appendChild(h('span.txt', c.state === 'incoming' ? 'Appel…' : 'Sonnerie…')); }
    else if (window.MusicState && MusicState.playing) { isl.classList.add('call'); isl.appendChild(h('span', { html: icon('music', 15) })); isl.appendChild(h('span.txt', MusicState.title || 'Musique')); }
  },

  /* ───── écran verrouillé ───── */
  drawLock() {
    const el = $('#lock'); if (!el) return;
    clear(el);
    const d = clockDate();
    el.appendChild(h('div.date', DAYS[d.getDay()] + ' ' + d.getDate() + ' ' + MONTHS[d.getMonth()]));
    el.appendChild(h('div.time', (S.settings.hour24 === false ? ((d.getHours() % 12) || 12) : pad(d.getHours())) + ':' + pad(d.getMinutes())));
    const list = h('div.notifs#lock-notifs'); el.appendChild(list);
    el.appendChild(h('div.quick', h('button', { onclick: (e) => { e.stopPropagation(); this.unlock(() => this.openApp('phone')); }, html: icon('torch', 22) }), h('button', { onclick: (e) => { e.stopPropagation(); this.unlock(() => this.openApp('camera')); }, html: icon('camera', 22) })));
    el.appendChild(h('div.hint', S.hasPin ? 'Touchez pour déverrouiller' : 'Touchez pour déverrouiller'));
    el.onclick = () => this.unlock();
    this.drawLockNotifs();
  },
  drawLockNotifs() {
    const list = $('#lock-notifs'); if (!list) return;
    clear(list);
    S.notifs.filter(n => !n.cleared).slice(0, 6).forEach(n => list.appendChild(this.notifEl(n, true)));
  },
  tickLock() { const t = $('#lock .time'); if (t) { const d = clockDate(); t.textContent = (S.settings.hour24 === false ? ((d.getHours() % 12) || 12) : pad(d.getHours())) + ':' + pad(d.getMinutes()); } },
  lock() {
    S.locked = true; const lk = $('#lock'); if (!lk) return;
    lk.classList.remove('gone'); this.drawLock(); this.drawWallpaper(); $('#home') && $('#home').classList.add('under');
    this.closeCC(); this.closeNC(); this.updateBars();
  },
  unlock(after) {
    if (!S.locked) { after && after(); return; }
    const done = () => {
      S.locked = false; $('#lock').classList.add('gone'); $('#home').classList.remove('under'); this.drawWallpaper(); this.updateBars();
      $$('.pin').forEach(p => p.remove()); after && after();
    };
    if (!S.hasPin) return done();
    if ($('.pin')) return;
    let code = '';
    const dots = h('div.dots', [0, 1, 2, 3].map(() => h('i')));
    const pad_ = h('div.pad');
    const update = () => $$('i', dots).forEach((d, i) => d.classList.toggle('on', i < code.length));
    const press = async (k) => {
      if (code.length >= 4) return;
      code += k; update(); Sound.click();
      if (code.length === 4) {
        const ok = await rpc('pinCheck', code);
        if (ok) { pin.remove(); done(); }
        else { dots.classList.add('err'); setTimeout(() => { dots.classList.remove('err'); code = ''; update(); }, 450); }
      }
    };
    const letters = { 2: 'ABC', 3: 'DEF', 4: 'GHI', 5: 'JKL', 6: 'MNO', 7: 'PQRS', 8: 'TUV', 9: 'WXYZ' };
    ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'].forEach(k => {
      if (k === '') { pad_.appendChild(h('button.ghost', { style: 'visibility:hidden' })); return; }
      if (k === '⌫') { pad_.appendChild(h('button.ghost', { onclick: () => { code = code.slice(0, -1); update(); } }, '⌫')); return; }
      pad_.appendChild(h('button', { onclick: () => press(k) }, k, h('small', letters[k] || ' ')));
    });
    const pin = h('div.pin', h('h3', 'Saisissez le code'), dots, pad_, h('button.cancel', { onclick: () => pin.remove() }, 'Annuler'));
    Screen().appendChild(pin);
  },

  /* ───── accueil ───── */
  installedDefs() {
    return S.installed.map(id => Apps.get(id)).filter(Boolean);
  },
  dockIds() { return (S.catalog || []).filter(a => a.dock).map(a => a.id).filter(id => S.installed.includes(id)).slice(0, 4); },
  drawHome() {
    const el = $('#home'); if (!el) return;
    clear(el);
    const dock = this.dockIds();
    const grid = this.installedDefs().filter(d => !dock.includes(d.id));
    const perFirst = 12, perPage = 20;
    const pages = [];
    pages.push(grid.slice(0, perFirst));
    for (let i = perFirst; i < grid.length; i += perPage) pages.push(grid.slice(i, i + perPage));
    const wrap = h('div.pages');
    pages.forEach((apps, pi) => {
      const p = h('div.hpage');
      if (pi === 0) p.appendChild(this.widgets());
      apps.forEach(d => p.appendChild(this.appIcon(d)));
      wrap.appendChild(p);
    });
    wrap.style.transform = `translateX(${-this.homePage * 390}px)`;
    el.appendChild(wrap);
    if (pages.length > 1) el.appendChild(h('div.dots', pages.map((_, i) => h('i' + (i === this.homePage ? '.on' : '')))));
    el.appendChild(h('div.search-pill', { style: 'display:block;', onclick: () => this.spotlight() }, '🔍 Rechercher'));
    el.appendChild(h('div.dock', dock.map(id => this.appIcon(Apps.get(id), true))));
    let sx = null;
    el.addEventListener('pointerdown', e => { sx = e.clientX; });
    el.addEventListener('pointerup', e => {
      if (sx == null) return; const dx = e.clientX - sx; sx = null;
      if (Math.abs(dx) > 60) { this.homePage = Math.max(0, Math.min(pages.length - 1, this.homePage + (dx < 0 ? 1 : -1))); wrap.style.transform = `translateX(${-this.homePage * 390}px)`; $$('.dots i', el).forEach((d, i) => d.classList.toggle('on', i === this.homePage)); }
    });
    el.addEventListener('wheel', e => { if (Math.abs(e.deltaY) < 20 || pages.length < 2) return; this.homePage = Math.max(0, Math.min(pages.length - 1, this.homePage + (e.deltaY > 0 ? 1 : -1))); wrap.style.transform = `translateX(${-this.homePage * 390}px)`; $$('.dots i', el).forEach((d, i) => d.classList.toggle('on', i === this.homePage)); });
    el.addEventListener('click', e => { if (this.editing && !e.target.closest('.appicon')) { this.editing = false; this.drawHome(); } });
  },
  appIcon(d, dock) {
    const badge = S.badges[d.id] || 0;
    const el = h('div.appicon', h('div.ico' + (this.editing ? '.wiggle' : ''), { style: `background:linear-gradient(160deg, ${d.grad[0]}, ${d.grad[1]})`, html: d.glyphFn ? d.glyphFn() : (d.glyph ? d.glyph : icon(d.icon)) }), h('div.nm', d.name));
    if (badge && !S.settings.badgeOff[d.id] && !this.editing) el.appendChild(h('div.badge', badge > 99 ? '99+' : badge));
    const sys = (S.catalog.find(a => a.id === d.id) || {}).system;
    if (this.editing && !sys) el.appendChild(h('div.rm', { html: icon('minus'), onclick: async (e) => { e.stopPropagation(); if (await Confirm('Supprimer « ' + d.name + ' » ?', 'Vous pourrez la réinstaller depuis l\'App Store.', 'Supprimer', true)) { const apps = await rpc('appInstall', d.id, false); if (apps) { S.installed = apps; this.drawHome(); } } } }));
    el.addEventListener('click', () => { if (this.editing) return; this.openApp(d.id, el); });
    el.addEventListener('contextmenu', e => { e.preventDefault(); this.editing = true; this.drawHome(); });
    return el;
  },
  widgets() {
    const d = clockDate();
    const wrap = h('div.widgets');
    const w = h('div.widget.w-weather', { onclick: () => this.openApp('weather') }, h('small', 'Los Santos'), h('div.big#w-temp', '--°'), h('div', { style: 'flex:1' }), h('div#w-lbl', { style: 'font-size:13px;font-weight:600' }, '…'), h('small#w-hl', ''));
    const c = h('div.widget.w-clock', { onclick: () => this.openApp('clock') }, h('div.analog#analog', h('i.h'), h('i.m'), h('i.s'), h('b')));
    wrap.appendChild(w); wrap.appendChild(c);
    this.tickAnalog(); this.refreshWidgetWeather();
    return wrap;
  },
  tickAnalog() {
    const a = $('#analog'); if (!a) return;
    const d = clockDate();
    const hh = (d.getHours() % 12) * 30 + d.getMinutes() * .5, mm = d.getMinutes() * 6, ss = d.getSeconds() * 6;
    $('.h', a).style.transform = `rotate(${hh}deg)`; $('.m', a).style.transform = `rotate(${mm}deg)`; $('.s', a).style.transform = `rotate(${ss}deg)`;
  },
  async refreshWidgetWeather() {
    const w = await post('weather'); if (!w) return;
    S.weather = w;
    const t = $('#w-temp'); if (t) { t.textContent = w.temp + '°'; $('#w-lbl').textContent = w.label; $('#w-hl').textContent = 'Ensuite : ' + w.next; }
  },
  spotlight() {
    const sh = Sheet({
      title: 'Recherche', full: true,
      render(body, close) {
        const out = h('div');
        const draw = (q) => {
          clear(out); q = (q || '').toLowerCase().trim();
          const apps = OS.installedDefs().filter(d => !q || d.name.toLowerCase().includes(q));
          const cons = q ? S.contactList.filter(c => c.name.toLowerCase().includes(q) || c.number.includes(q)).slice(0, 8) : [];
          if (apps.length) out.appendChild(Group('Applications', apps.map(d => ({ icon: d.icon, color: d.grad[1], title: d.name, onclick: () => { close(); OS.openApp(d.id); } }))));
          if (cons.length) out.appendChild(Group('Contacts', cons.map(c => ({ left: avatar(c.name, 29, c.avatar), title: c.name, sub: fmtNum(c.number), onclick: () => { close(); OS.openApp('contacts'); } }))));
        };
        body.appendChild(SearchBar({ placeholder: 'Applications, contacts…', onInput: draw }));
        body.appendChild(out); draw('');
        setTimeout(() => $('input', body).focus(), 80);
      },
    });
  },

  /* ───── applications ───── */
  openApp(id, from) {
    const d = Apps.get(id); if (!d) return;
    if (S.locked) return this.unlock(() => this.openApp(id, from));
    if (this.current && this.current.id === id) return;
    this.closeCC(); this.closeNC(); $('.switcher') && $('.switcher').remove();
    if (this.current) this.detach(this.current);
    let r = this.running[id];
    const sc = Screen();
    if (from && from.getBoundingClientRect) {
      const b = from.getBoundingClientRect(), s = sc.getBoundingClientRect(), k = (parseFloat(getComputedStyle($('#stage')).getPropertyValue('--scale')) || 1);
      sc.style.setProperty('--ox', ((b.left + b.width / 2 - s.left) / k) + 'px'); sc.style.setProperty('--oy', ((b.top + b.height / 2 - s.top) / k) + 'px');
    } else { sc.style.setProperty('--ox', '50%'); sc.style.setProperty('--oy', '50%'); }
    if (!r) {
      const el = h('div.appview' + (d.dark ? '.dark' : ''));
      const ctx = new AppCtx(d, el);
      r = this.running[id] = { id, ctx, el, dark: !!d.dark, def: d };
      sc.insertBefore(el, $('#statusbar'));
      try { d.open(ctx); } catch (e) { console.error(e); Toast('Erreur : ' + e.message); }
    } else { sc.insertBefore(r.el, $('#statusbar')); r.el.classList.remove('closing'); r.el.style.animation = 'appopen .38s var(--ease)'; r.ctx.top && r.ctx.top.opts.onResume && r.ctx.top.opts.onResume(r.ctx.top); }
    this.current = r; this.order = [id, ...this.order.filter(x => x !== id)];
    $('#home').classList.add('under'); this.updateBars();
    Bus.emit('appopen', id);
  },
  detach(r) {
    r.el.remove(); r.ctx.top && r.ctx.top.opts.onHide && r.ctx.top.opts.onHide(r.ctx.top);
    if (this.current === r) this.current = null;
  },
  home() {
    if (S.locked) return;
    this.closeCC(); this.closeNC(); $('.switcher') && $('.switcher').remove(); $$('.sheet,.scrim,.actions,.alert').forEach(x => x.remove());
    if (this.current) {
      const r = this.current; r.el.classList.add('closing');
      setTimeout(() => { if (r.el.classList.contains('closing')) { r.el.remove(); r.ctx.top && r.ctx.top.opts.onHide && r.ctx.top.opts.onHide(r.ctx.top); } }, 300);
      this.current = null;
    }
    $('#home').classList.remove('under'); this.editing = false; this.drawHome(); this.updateBars();
  },
  quit(id) {
    const r = this.running[id]; if (!r) return;
    r.el.remove(); r.ctx.alive = false; r.def.onQuit && r.def.onQuit(r.ctx);
    delete this.running[id]; this.order = this.order.filter(x => x !== id); if (this.current === r) this.current = null;
  },
  switcher() {
    if (S.locked) return;
    if ($('.switcher')) { $('.switcher').remove(); return; }
    if (this.current) { this.current.el.remove(); this.current = null; $('#home').classList.remove('under'); }
    const ids = this.order.filter(id => this.running[id]);
    const sw = h('div.switcher', { onclick: (e) => { if (e.target === sw) sw.remove(); } });
    if (!ids.length) sw.appendChild(h('div', { style: 'color:#fff;margin:auto;opacity:.7' }, 'Aucune application récente'));
    ids.forEach(id => {
      const d = Apps.get(id);
      const c = h('div.card', h('div.snap', { style: `--c1:linear-gradient(160deg, ${d.grad[0]}, ${d.grad[1]})`, html: icon(d.icon), onclick: () => { sw.remove(); OS.openApp(id); } }), h('span', d.name));
      c.addEventListener('wheel', e => { if (e.deltaY < -20) { c.classList.add('kill'); setTimeout(() => { OS.quit(id); c.remove(); }, 250); } });
      c.addEventListener('contextmenu', e => { e.preventDefault(); c.classList.add('kill'); setTimeout(() => { OS.quit(id); c.remove(); }, 250); });
      sw.appendChild(c);
    });
    Screen().appendChild(sw);
  },
  back() {
    // retour hiérarchique : superpositions → page d'application → accueil → fermeture du téléphone
    const sc = Screen();
    const ov = $$('.sheet,.actions,.alert,.pin', sc).pop();
    if (ov) { const scr = $$('.scrim', sc).pop(); ov.remove(); scr && scr.remove(); return true; }
    if ($('.switcher')) { $('.switcher').remove(); return true; }
    if ($('.cc.open')) { this.closeCC(); return true; }
    if ($('.nc.open')) { this.closeNC(); return true; }
    if (S.locked) return false;
    if (this.current) { if (!this.current.ctx.pop()) { const hook = this.current.def.onBack; if (hook && hook(this.current.ctx)) return true; this.home(); } return true; }
    if (this.editing) { this.editing = false; this.drawHome(); return true; }
    return false;
  },

  /* ───── notifications ───── */
  notifEl(n, lock) {
    const d = Apps.get(n.app) || { grad: ['#555', '#333'], icon: 'bell', name: 'Système' };
    const el = h('div.notif', { onclick: () => { n.cleared = true; this.drawLockNotifs(); this.drawNC(); n.onTap ? n.onTap() : this.openApp(n.app); } },
      h('div.ni', { style: `background:linear-gradient(160deg, ${d.grad[0]}, ${d.grad[1]})`, html: icon(n.icon || d.icon) }),
      h('div.nt', h('b', n.title || d.name), n.body ? h('p', n.body) : null), h('div.nm', ago(n.at)));
    if (n.actions && n.actions.length) { const na = h('div.na'); n.actions.forEach(a => na.appendChild(h('button', { onclick: (e) => { e.stopPropagation(); a.onclick(); n.cleared = true; el.remove(); } }, a.label))); $('.nt', el).appendChild(na); }
    return el;
  },
  notify(n) {
    n.at = Date.now(); n.id = n.id || Math.random().toString(36).slice(2);
    const off = S.settings.notifOff || {};
    if (n.app && off[n.app]) return;
    S.notifs.unshift(n); if (S.notifs.length > 60) S.notifs.pop();
    if (!S.settings.dnd) { if (n.sound !== false) Sound.text(); }
    const banner = this.notifEl(n);
    const host = (S.open && !S.locked) ? $('#screen') : (S.open ? null : $('#peek'));
    if (S.open && S.locked) { this.drawLockNotifs(); }
    else if (host) {
      if (host.id === 'screen') { banner.style.cssText = 'position:absolute;left:10px;right:10px;top:12px;z-index:186;width:auto;'; }
      if (S.settings.dnd && !S.open) return;
      host.appendChild(banner);
      setTimeout(() => { banner.style.transition = 'opacity .3s, transform .3s'; banner.style.opacity = '0'; banner.style.transform = 'translateY(-30px)'; setTimeout(() => banner.remove(), 320); }, 4200);
    }
    this.drawNC();
    Bus.emit('notify', n);
  },
  drawNC() {
    const nc = $('#nc'); if (!nc) return;
    clear(nc);
    nc.appendChild(h('div.nch', h('h2', 'Notifications'), h('button', { onclick: () => { S.notifs.forEach(n => n.cleared = true); this.drawNC(); this.drawLockNotifs(); } }, 'Tout effacer')));
    const list = h('div.list'); const items = S.notifs.filter(n => !n.cleared);
    if (!items.length) list.appendChild(h('div', { style: 'text-align:center;opacity:.6;margin-top:60px' }, 'Aucune notification'));
    items.forEach(n => list.appendChild(this.notifEl(n)));
    nc.appendChild(list); nc.appendChild(h('div.grab', { onclick: () => this.closeNC() }));
  },
  openNC() { if (S.locked) return; this.closeCC(); this.drawNC(); $('#nc').classList.add('open'); },
  closeNC() { $('#nc') && $('#nc').classList.remove('open'); },
  setBadge(app, n) { S.badges[app] = n; const home = $('#home'); if (home && !this.current) { /* redessin léger */ this.drawHome(); } },

  /* ───── centre de contrôle ───── */
  drawCC() {
    const cc = $('#cc'); clear(cc);
    const st = S.settings;
    const save = (p) => { Object.assign(S.settings, p); rpc('settingsSet', p); this.drawStatus(); this.applyTheme(); };
    const rb = (ic, on, cls, fn) => h('div.rb' + (on ? '.on' : '') + (cls ? '.' + cls : ''), { html: icon(ic), onclick: (e) => { fn(); this.drawCC(); } });
    const tile = h('div.tile.conn',
      rb('plane', st.airplane, 'orange', () => save({ airplane: !st.airplane })), rb('signal', !st.airplane, 'green', () => save({ airplane: !st.airplane })),
      rb('wifi', st.wifi && !st.airplane, '', () => save({ wifi: !st.wifi })), rb('bluetooth', st.bluetooth, '', () => save({ bluetooth: !st.bluetooth })));
    const music = h('div.tile', { style: 'padding:14px;display:flex;flex-direction:column;justify-content:center;cursor:pointer', onclick: () => this.openApp('music') }, h('small', { style: 'opacity:.7' }, 'Lecture en cours'), h('b', { style: 'font-size:15px;margin:6px 0' }, (window.MusicState && MusicState.title) || 'Aucun titre'), h('div', { style: 'display:flex;gap:14px;font-size:22px;opacity:.9' }, h('span', { html: icon((window.MusicState && MusicState.playing) ? 'pause' : 'play', 24) })));
    const slider = (ic, val, on) => {
      const el = h('div.slider', h('i', { style: `width:${val}%` }), h('span', { html: icon(ic, 24) }));
      const setFrom = (e) => { const r = el.getBoundingClientRect(); let v = Math.round(((e.clientX - r.left) / (r.width || 1)) * 100); v = Math.max(5, Math.min(100, v)); $('i', el).style.width = v + '%'; on(v); };
      let drag = false; el.addEventListener('pointerdown', e => { drag = true; el.setPointerCapture(e.pointerId); setFrom(e); }); el.addEventListener('pointermove', e => drag && setFrom(e)); el.addEventListener('pointerup', () => { drag = false; });
      return el;
    };
    const sl = h('div.sliders', slider('sun', st.brightness == null ? 100 : st.brightness, v => { S.settings.brightness = v; this.applyTheme(); clearTimeout(this.bt); this.bt = setTimeout(() => rpc('settingsSet', { brightness: v }), 400); }), slider('volume', st.volume == null ? 70 : st.volume, v => { S.settings.volume = v; clearTimeout(this.vt); this.vt = setTimeout(() => rpc('settingsSet', { volume: v }), 400); }));
    const cts = (ic, label, on, fn) => h('div.tile.wide', { onclick: () => { fn(); this.drawCC(); } }, h('div', { style: 'width:36px;height:36px;border-radius:50%;display:grid;place-items:center;background:' + (on ? 'var(--accent)' : 'rgba(120,120,128,.5)'), html: icon(ic, 20) }), h('span', label));
    const small = h('div.small-row',
      ...[['torch', 'Lampe', this.torch, () => { this.torch = !this.torch; post('flashlight', { state: this.torch }); }],
        ['moon', 'Ne pas déranger', st.dnd, () => save({ dnd: !st.dnd })],
        ['volume', 'Silencieux', st.volume === 0, () => { const v = st.volume === 0 ? 70 : 0; S.settings.volume = v; rpc('settingsSet', { volume: v }); }],
        ['sun', 'Mode sombre', st.theme !== 'light', () => save({ theme: st.theme === 'light' ? 'dark' : 'light' })]]
        .map(x => h('div.tile' + (x[2] ? '.on' : ''), { title: x[1], onclick: () => { x[3](); this.drawCC(); }, html: icon(x[0], 26) })));
    const small2 = h('div.small-row',
      ...[['calc', 'Calculette', () => this.openApp('calculator')], ['camera', 'Appareil photo', () => this.openApp('camera')], ['alarm', 'Réveil', () => this.openApp('clock')], ['lightning', 'Batterie externe', async () => { const ok = await post('usePowerbank'); Toast(ok ? 'Batterie rechargée' : 'Aucune batterie externe', 'lightning'); }]]
        .map(x => h('div.tile', { title: x[1], onclick: () => { this.closeCC(); x[2](); }, html: icon(x[0] === 'calc' ? 'calc' : x[0], 26) })));
    cc.appendChild(h('div.grid', tile, music));
    cc.appendChild(sl); cc.appendChild(small); cc.appendChild(small2);
    cc.appendChild(h('div', { style: 'text-align:center;margin-top:26px;opacity:.75;font-size:14px' }, 'Batterie ' + Math.round(S.battery) + '%' + (S.charging ? ' · en charge' : '')));
    cc.appendChild(h('div.grab', { style: 'position:absolute;bottom:10px;left:50%;width:138px;margin-left:-69px;height:5px;border-radius:3px;background:#fff;opacity:.6;cursor:pointer', onclick: () => this.closeCC() }));
  },
  openCC() { if (S.locked) return; this.closeNC(); this.drawCC(); $('#cc').classList.add('open'); },
  closeCC() { $('#cc') && $('#cc').classList.remove('open'); },

  /* ───── gestes ───── */
  bindGestures() {
    const sb = $('#statusbar');
    $('#sb-l').addEventListener('click', () => { if (S.locked) return; $('.nc.open') ? this.closeNC() : this.openNC(); });
    $('#sb-r').addEventListener('click', () => { if (S.locked) return; $('.cc.open') ? this.closeCC() : this.openCC(); });
    const hb = $('#homebar');
    let t0 = null, y0 = 0;
    hb.addEventListener('pointerdown', e => { t0 = Date.now(); y0 = e.clientY; hb.setPointerCapture(e.pointerId); });
    hb.addEventListener('pointerup', e => {
      if (t0 == null) return; const dy = e.clientY - y0, dt = Date.now() - t0; t0 = null;
      if (S.locked) return this.unlock();
      if (dy < -30 && dt > 350) return this.switcher();
      if ($('.switcher')) { $('.switcher').remove(); return; }
      this.home();
    });
    hb.addEventListener('dblclick', () => this.switcher());
    // balayage vers le bas depuis le haut du téléphone
    let ty = null;
    Screen().addEventListener('pointerdown', e => { const r = Screen().getBoundingClientRect(); const k = r.height / 844; if ((e.clientY - r.top) / k < 50) ty = { y: e.clientY, x: e.clientX, w: (e.clientX - r.left) / k }; });
    Screen().addEventListener('pointerup', e => { if (!ty) return; const dy = e.clientY - ty.y; if (dy > 40) { if (ty.w > 195) this.openCC(); else this.openNC(); } ty = null; });
    Screen().addEventListener('wheel', e => { if (S.locked || e.target.closest('.body,.list,.notifs,.switcher')) return; });
  },

  /* ───── cycle de vie ───── */
  show() {
    S.open = true;
    const stage = $('#stage'); stage.classList.remove('hidden'); requestAnimationFrame(() => stage.classList.add('open'));
    $('#peek').innerHTML = '';
    clearTimeout(this.lockTimer);
    if (!this.started) { this.started = true; if (!S.config.ui || S.config.ui.showBootLogo !== false) Screen().appendChild(h('div.boot', h('b', (S.config.brand || 'Aero').toUpperCase()))); setTimeout(() => $$('.boot').forEach(b => b.remove()), 1900); }
    this.drawStatus(); this.drawLockNotifs(); Bus.emit('show');
  },
  hide() {
    S.open = false;
    const stage = $('#stage'); stage.classList.remove('open');
    setTimeout(() => { if (!S.open) stage.classList.add('hidden'); }, 460);
    const t = (S.settings.autoLock == null ? 30 : S.settings.autoLock);
    if (t > 0) this.lockTimer = setTimeout(() => this.lock(), t * 1000);
    this.closeCC(); this.closeNC(); $('.switcher') && $('.switcher').remove();
    Bus.emit('hide');
  },
  fit() {
    const u = (S.config && S.config.ui) || {};
    const k = Math.max(u.minScale || .55, Math.min(u.maxScale || 1, (window.innerHeight - 24) / 864));
    const st = $('#stage');
    st.style.setProperty('--scale', String(k));
    const left = u.side === 'left';
    st.style.right = left ? 'auto' : (u.marginX == null ? 28 : u.marginX) + 'px';
    st.style.left = left ? (u.marginX == null ? 28 : u.marginX) + 'px' : 'auto';
    st.style.bottom = (u.marginY == null ? -8 : u.marginY) + 'px';
    st.style.transformOrigin = left ? 'bottom left' : 'bottom right';
    const peek = $('#peek'); if (peek) { peek.style.right = left ? 'auto' : '38px'; peek.style.left = left ? '38px' : 'auto'; }
  },
};
window.addEventListener('resize', () => OS.fit());

/* ───── événements serveur communs ───── */
Bus.on('push:notify', d => { const def = Apps.get(d.app); OS.notify({ app: d.app, title: d.title, body: d.body, icon: def ? def.icon : 'bell' }); });
Bus.on('push:battery', d => { S.battery = d.level; S.charging = !!d.charging; OS.drawStatus(); if (d.level === 20 || d.level === 10 || d.level === 5) OS.notify({ app: 'settings', title: 'Batterie faible', body: d.level + ' % restants', icon: 'lightning' }); });
Bus.on('push:reset', () => { Toast('Téléphone réinitialisé'); post('close'); });
Bus.on('push:mail', d => { S.unreadMail++; OS.setBadge('mail', S.unreadMail); OS.notify({ app: 'mail', title: d.from, body: d.subject, icon: 'mail' }); });
Bus.on('push:airRequest', d => {
  const labels = { photo: 'une photo', contact: 'un contact', note: 'une note', location: 'une position' };
  OS.notify({ app: 'airshare', title: 'AirShare', body: d.from + ' souhaite partager ' + (labels[d.kind] || 'un élément'), icon: 'share', sound: true,
    actions: [{ label: 'Accepter', onclick: () => rpc('airRespond', d.id, true) }, { label: 'Refuser', onclick: () => rpc('airRespond', d.id, false) }] });
});
Bus.on('push:airReceived', async d => {
  const p = d.payload || {};
  if (d.kind === 'contact') { await rpc('contactSave', { name: p.name, number: p.number }); await Core.reloadContacts(); Toast('Contact ajouté', 'user'); }
  else if (d.kind === 'note') { const notes = (await rpc('kvGet', 'notes')) || []; notes.unshift({ id: Date.now(), title: p.title || 'Note partagée', body: p.body || '', at: Date.now() }); await rpc('kvSet', 'notes', notes); Toast('Note reçue', 'note'); }
  else if (d.kind === 'location') { post('waypoint', { x: p.x, y: p.y }); Toast('Position ajoutée au GPS', 'pin'); }
  else if (d.kind === 'photo') Toast('Photo reçue dans Photos', 'image');
});
Bus.on('push:dispatch', a => {
  OS.notify({ app: 'services', title: '🚨 ' + a.label, body: (a.name ? a.name + ' : ' : '') + (a.message || 'Demande d\'assistance'), icon: 'warning',
    actions: [{ label: 'GPS', onclick: () => post('dispatchGps', { id: a.id }) }] });
});

/* ───── données partagées ───── */
const Core = {
  async reloadContacts() {
    const list = (await rpc('contacts')) || [];
    S.contactList = list; S.contacts = {}; list.forEach(c => { S.contacts[String(c.number).replace(/\D/g, '')] = c; });
    Bus.emit('contacts');
  },
};
