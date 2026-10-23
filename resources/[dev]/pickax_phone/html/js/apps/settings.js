/* ═══════════ Réglages & App Store ═══════════ */
const APP_INFO = {
  pulse: ['Réseau social', 'Le fil d\'actualité de Los Santos : publiez, aimez, partagez.'], snap: ['Photo & vidéo', 'Partagez vos photos et stories avec vos abonnés.'], match: ['Rencontres', 'Faites des rencontres autour de vous.'],
  crypto: ['Finance', 'Achetez et vendez des cryptomonnaies en temps réel.'], market: ['Shopping', 'Achetez et vendez entre particuliers.'], bank: ['Finance', 'Votre compte, vos virements et vos factures.'],
  maps: ['Navigation', 'Itinéraires et lieux enregistrés.'], mail: ['Productivité', 'Votre boîte mail.'], notes: ['Productivité', 'Notez vos idées.'], calendar: ['Productivité', 'Vos événements et rappels.'],
  clock: ['Utilitaires', 'Réveils, chrono, minuteur.'], calculator: ['Utilitaires', 'Calculette.'], weather: ['Météo', 'Prévisions pour Los Santos.'], services: ['Utilité', 'Contactez la police, le SAMU, les dépanneurs…'],
  garage: ['Auto', 'Retrouvez vos véhicules.'], music: ['Musique', 'Radios et liens audio.'], findmy: ['Utilitaires', 'Localisez vos proches.'], airshare: ['Utilitaires', 'Partage à proximité.'], wallet: ['Finance', 'Vos cartes et votre identité.'],
};
const Settings = {
  async open(ctx) {
    this.ctx = ctx;
    const pg = Page({ title: 'Réglages' }); this.pg = pg; ctx.root(pg); this.root();
  },
  save(patch) { Object.assign(S.settings, patch); rpc('settingsSet', patch); OS.applyTheme(); OS.drawStatus(); },
  root() {
    const pg = this.pg, st = S.settings; clear(pg.body);
    pg.body.appendChild(SearchBar({ placeholder: 'Rechercher' }));
    pg.body.appendChild(Group(null, [{ left: avatar(S.me.name, 60), title: h('b', { style: 'font-size:20px;font-weight:500' }, S.me.name), sub: fmtNum(S.me.number) + ' · ' + S.me.mail }]));
    const sub = (title, fn) => () => { const p = Page({ title, back: 'Réglages' }); fn(p); this.ctx.push(p); };
    pg.body.appendChild(Group(null, [
      { icon: 'plane', color: '#ff9f0a', title: 'Mode avion', toggle: { on: st.airplane, onchange: v => this.save({ airplane: v }) } },
      { icon: 'wifi', color: '#0a84ff', title: 'Wi-Fi', toggle: { on: st.wifi, onchange: v => this.save({ wifi: v }) } },
      { icon: 'bluetooth', color: '#0a84ff', title: 'Bluetooth', toggle: { on: st.bluetooth, onchange: v => this.save({ bluetooth: v }) } },
    ]));
    pg.body.appendChild(Group(null, [
      { icon: 'bell', color: '#ff453a', title: 'Notifications', chev: true, onclick: sub('Notifications', p => this.notifs(p)) },
      { icon: 'volume', color: '#ff375f', title: 'Sons', chev: true, onclick: sub('Sons', p => this.sounds(p)) },
      { icon: 'moon', color: '#5e5ce6', title: 'Ne pas déranger', toggle: { on: st.dnd, onchange: v => this.save({ dnd: v }) } },
    ]));
    pg.body.appendChild(Group(null, [
      { icon: 'gear', color: '#8e8e93', title: 'Général', chev: true, onclick: sub('Général', p => this.general(p)) },
      { icon: 'sun', color: '#0a84ff', title: 'Affichage et luminosité', chev: true, onclick: sub('Affichage', p => this.display(p)) },
      { icon: 'image', color: '#32ade6', title: 'Fond d\'écran', chev: true, onclick: sub('Fond d\'écran', p => this.wallpaper(p)) },
      { icon: 'lock', color: '#30d158', title: 'Code et sécurité', chev: true, onclick: sub('Code', p => this.passcode(p)) },
      { icon: 'lightning', color: '#30d158', title: 'Batterie', chev: true, onclick: sub('Batterie', p => this.battery(p)) },
      { icon: 'shield', color: '#0a84ff', title: 'Confidentialité', chev: true, onclick: sub('Confidentialité', p => this.privacy(p)) },
    ]));
    pg.body.appendChild(Group(null, [{ icon: 'store', color: '#0a84ff', title: 'App Store', chev: true, onclick: () => OS.openApp('appstore') }]));
  },
  notifs(p) {
    const off = S.settings.notifOff || {}, bd = S.settings.badgeOff || {};
    p.body.appendChild(Group(null, [{ title: 'Aperçus des messages', toggle: { on: S.settings.previews !== false, onchange: v => this.save({ previews: v }) } }]));
    p.body.appendChild(Group('Style de notification', S.installed.map(id => Apps.get(id)).filter(Boolean).map(d => ({ icon: d.icon, color: d.grad[1], title: d.name, toggle: { on: !off[d.id], onchange: v => { const o = Object.assign({}, S.settings.notifOff); if (v) delete o[d.id]; else o[d.id] = true; this.save({ notifOff: o }); } } }))));
    p.body.appendChild(Group('Pastilles', S.installed.map(id => Apps.get(id)).filter(Boolean).map(d => ({ icon: d.icon, color: d.grad[1], title: d.name, toggle: { on: !bd[d.id], onchange: v => { const o = Object.assign({}, S.settings.badgeOff); if (v) delete o[d.id]; else o[d.id] = true; this.save({ badgeOff: o }); OS.drawHome(); } } }))));
  },
  sounds(p) {
    const st = S.settings;
    const vol = h('input', { type: 'range', min: 0, max: 100, value: st.volume, style: 'width:100%', oninput: e => { S.settings.volume = +e.target.value; }, onchange: e => { this.save({ volume: +e.target.value }); Sound.text(); } });
    p.body.appendChild(Group('Sonnerie et alertes', [{ el: h('div', { style: 'display:flex;gap:12px;align-items:center;width:100%;padding:10px 0' }, h('span', { html: icon('volumeOff', 20) }), vol, h('span', { html: icon('volume', 20) })) }]));
    const tones = S.config.ringtones || [];
    const draw = () => { clear(rg.rows); tones.forEach(t => rg.rows.appendChild(Row({ title: t, trailing: S.settings.ringtone === t ? h('span', { style: 'color:var(--accent)', html: icon('check', 22) }) : null, onclick: () => { this.save({ ringtone: t }); Sound.stop(); if (t !== 'Silence') { Sound.ring(t); setTimeout(() => Sound.stop(), 1800); } draw(); } }))); };
    const rg = Group('Sonnerie', []); p.body.appendChild(rg); draw();
    const tt = ['Cristal', 'Silence']; const tg = Group('Son des messages', []); p.body.appendChild(tg);
    const drawT = () => { clear(tg.rows); tt.forEach(t => tg.rows.appendChild(Row({ title: t, trailing: S.settings.texttone === t ? h('span', { style: 'color:var(--accent)', html: icon('check', 22) }) : null, onclick: () => { this.save({ texttone: t }); if (t !== 'Silence') Sound.text(); drawT(); } }))); }; drawT();
    p.body.appendChild(Group(null, [{ title: 'Vibreur', toggle: { on: st.vibrate, onchange: v => this.save({ vibrate: v }) } }]));
  },
  display(p) {
    const st = S.settings;
    p.body.appendChild(Seg([{ value: 'dark', label: 'Sombre' }, { value: 'light', label: 'Clair' }], st.theme === 'light' ? 'light' : 'dark', v => this.save({ theme: v })));
    const cols = ['#0a84ff', '#30d158', '#ff453a', '#ff9f0a', '#bf5af2', '#ff375f', '#64d2ff'];
    p.body.appendChild(Group('Couleur d\'accentuation', [{ el: h('div', { style: 'display:flex;gap:12px;padding:12px 0' }, cols.map(c => h('div', { style: `width:32px;height:32px;border-radius:50%;background:${c};border:3px solid ${c === st.accent ? 'var(--fg)' : 'transparent'}`, onclick: (e) => { this.save({ accent: c }); $$('div', e.target.parentNode).forEach(d => d.style.borderColor = 'transparent'); e.target.style.borderColor = 'var(--fg)'; } }))) }]));
    p.body.appendChild(Group('Luminosité', [{ el: h('input', { type: 'range', min: 20, max: 100, value: st.brightness, style: 'width:100%', oninput: e => { S.settings.brightness = +e.target.value; OS.applyTheme(); }, onchange: e => this.save({ brightness: +e.target.value }) }) }]));
    p.body.appendChild(Group('Taille du texte', [{ el: h('input', { type: 'range', min: 85, max: 120, step: 5, value: st.textSize, style: 'width:100%', onchange: e => this.save({ textSize: +e.target.value }) }) }]));
    p.body.appendChild(Group(null, [{ title: 'Format 24 heures', toggle: { on: st.hour24 !== false, onchange: v => { this.save({ hour24: v }); OS.drawStatus(); } } }, { title: 'Texte en gras', toggle: { on: st.bold, onchange: v => { this.save({ bold: v }); document.body.style.fontWeight = v ? 600 : ''; } } }]));
  },
  wallpaper(p) {
    const st = S.settings;
    const apply = (key, id) => { const patch = {}; patch[key] = id; this.save(patch); OS.drawWallpaper(); Toast('Fond d\'écran modifié', 'image'); drawG(); };
    const grid = h('div', { style: 'display:grid;grid-template-columns:repeat(3,1fr);gap:12px;padding:0 16px 16px' });
    const drawG = () => { clear(grid); (S.config.wallpapers || []).forEach(w => grid.appendChild(h('div', { style: `aspect-ratio:9/16;border-radius:14px;background:${w.css};border:3px solid ${S.settings.wallpaper === w.id ? 'var(--accent)' : 'transparent'};display:flex;align-items:flex-end;justify-content:center;color:#fff;font-size:12px;padding:6px;cursor:pointer;text-shadow:0 1px 4px #000`, onclick: () => { S.settings.lockWallpaper = w.id; this.save({ lockWallpaper: w.id, wallpaper: w.id }); OS.drawWallpaper(); drawG(); } }, w.name))); };
    drawG(); p.body.appendChild(h('div', { style: 'padding:10px 20px;color:var(--fg2)' }, 'Choisir un fond')); p.body.appendChild(grid);
    p.body.appendChild(Group(null, [{ title: 'Image personnalisée (lien)', accent: true, onclick: async () => { const u = await Prompt('Lien de l\'image', null, { placeholder: 'https://…', value: st.customWallpaper }); if (u && /^https?:/.test(u)) { S.settings.customWallpaper = u; this.save({ customWallpaper: u, wallpaper: 'custom', lockWallpaper: 'custom' }); OS.drawWallpaper(); drawG(); } } }, { title: 'Choisir depuis Photos', accent: true, onclick: () => Messages.pickPhoto(u => { this.save({ customWallpaper: u, wallpaper: 'custom', lockWallpaper: 'custom' }); OS.drawWallpaper(); drawG(); }) }]));
  },
  passcode(p) {
    const st = S.settings;
    const draw = () => {
      clear(p.body);
      p.body.appendChild(Group(null, [S.hasPin ? { title: 'Désactiver le code', danger: true, onclick: async () => { const c = await Prompt('Code actuel', null, { type: 'password', placeholder: '••••' }); if (c == null) return; if (!await rpc('pinCheck', c)) { Toast('Code incorrect', 'warning'); return; } await rpc('settingsSet', { pinEnabled: false, pin: '' }); S.hasPin = false; draw(); } } : null,
        { title: S.hasPin ? 'Modifier le code' : 'Activer le code', accent: true, onclick: async () => { if (S.hasPin) { const c = await Prompt('Code actuel', null, { type: 'password', placeholder: '••••' }); if (c == null) return; if (!await rpc('pinCheck', c)) { Toast('Code incorrect', 'warning'); return; } } const n = await Prompt('Nouveau code', '4 chiffres', { type: 'password', placeholder: '••••' }); if (!n) return; if (!/^\d{4}$/.test(n)) { Toast('Le code doit contenir 4 chiffres', 'warning'); return; } await rpc('settingsSet', { pin: n, pinEnabled: true }); S.hasPin = true; Toast('Code enregistré', 'lock'); draw(); } }].filter(Boolean)));
      p.body.appendChild(Group('Verrouillage automatique', [30, 60, 120, 300, 0].map(s => ({ title: s === 0 ? 'Jamais' : s < 60 ? s + ' secondes' : s / 60 + ' minute' + (s > 60 ? 's' : ''), trailing: st.autoLock === s ? h('span', { style: 'color:var(--accent)', html: icon('check', 22) }) : null, onclick: () => { this.save({ autoLock: s }); draw(); } })), 'Délai avant verrouillage une fois le téléphone rangé.'));
    }; draw();
  },
  battery(p) {
    const lvl = Math.round(S.battery);
    p.body.appendChild(h('div', { style: 'text-align:center;padding:34px 0 10px' }, h('div', { style: 'font-size:70px;font-weight:200' }, lvl + '%'), h('div', { style: 'color:' + (S.charging ? 'var(--green)' : 'var(--fg2)') }, S.charging ? 'En charge' : lvl <= 20 ? 'Batterie faible' : 'Sur batterie')));
    p.body.appendChild(Group(null, [{ title: 'Recharger avec une batterie externe', accent: true, onclick: async () => { const ok = await post('usePowerbank'); Toast(ok ? 'Batterie rechargée' : 'Aucune batterie externe', 'lightning'); } }], 'Le téléphone se recharge aussi dans un véhicule dont le moteur tourne.'));
  },
  privacy(p) {
    const st = S.settings;
    p.body.appendChild(Group(null, [{ title: 'Confirmations de lecture', toggle: { on: st.readReceipts !== false, onchange: v => this.save({ readReceipts: v }) } }, { title: 'Masquer mon numéro', toggle: { on: st.hideNumber, onchange: v => this.save({ hideNumber: v }) } }], 'Avec le numéro masqué, vos appels s\'affichent « Numéro masqué ».'));
    const blocked = S.contactList.filter(c => c.blocked);
    p.body.appendChild(Group('Contacts bloqués', blocked.length ? blocked.map(c => ({ left: avatar(c.name, 34), title: c.name, sub: fmtNum(c.number), onclick: () => ActionSheet(c.name, [{ label: 'Débloquer', onclick: async () => { await rpc('contactFlag', c.id, 'blocked', false); await Core.reloadContacts(); p.body.parentNode && (clear(p.body), this.privacy(p)); } }]) })) : [{ title: 'Aucun contact bloqué' }]));
  },
  general(p) {
    p.body.appendChild(Group(null, [{ title: 'Nom', value: S.me.name }, { title: 'Modèle', value: S.config.model || 'Aura' }, { title: 'Numéro de téléphone', value: fmtNum(S.me.number) }, { title: 'Adresse mail', value: S.me.mail }, { title: 'Version', value: 'AuraOS 1.0' }, { title: 'Applications', value: String(S.installed.length) }]));
    p.body.appendChild(Group(null, [{ title: 'Réinitialiser les réglages', danger: true, onclick: async () => { if (await Confirm('Réinitialiser les réglages ?', 'Vos données (contacts, photos, messages) sont conservées.', 'Réinitialiser', true)) { await rpc('settingsSet', { wallpaper: 'aurora', lockWallpaper: 'aurora', customWallpaper: '', theme: 'dark', accent: '#0a84ff', ringtone: 'Marimba', dnd: false, airplane: false, wifi: true, volume: 70, brightness: 100, textSize: 100, notifOff: {}, badgeOff: {} }); Toast('Réglages réinitialisés — rouvrez le téléphone', 'check'); post('close'); S.reload = true; } } }]));
  },
};
registerApp({ id: 'settings', name: 'Réglages', icon: 'gear', grad: ['#9a9aa0', '#5b5b61'], open: ctx => Settings.open(ctx) });

/* ───────────── App Store ───────────── */
const AppStore = {
  async open(ctx) {
    this.ctx = ctx;
    const holder = h('div', { style: 'position:absolute;inset:0' }); let tab = 'discover';
    const bar = TabBar([{ id: 'discover', label: 'Découvrir', icon: 'store' }, { id: 'mine', label: 'Mes apps', icon: 'grid' }], 'discover', id => { tab = id; draw(); });
    const wrap = Page({ noNav: true, nopad: true, tabbar: bar }); wrap.body.style.cssText = 'position:relative;overflow:hidden'; wrap.body.appendChild(holder); ctx.root(wrap);
    const draw = () => { clear(holder); const pg = this['tab_' + tab](); holder.appendChild(pg.el); ctx.stack[0] = pg; pg.ctx = ctx; };
    this.draw = draw; draw();
  },
  async toggle(id, install) { const apps = await rpc('appInstall', id, install); if (apps) { S.installed = apps; OS.drawHome(); this.draw(); Toast(install ? 'Application installée' : 'Application supprimée', install ? 'download' : 'trash'); } },
  line(d, c) {
    const has = S.installed.includes(d.id); const info = APP_INFO[d.id] || ['Application', ''];
    return Row({ left: h('div.ico', { style: `width:58px;height:58px;border-radius:13px;display:grid;place-items:center;color:#fff;background:linear-gradient(160deg, ${d.grad[0]}, ${d.grad[1]})`, html: icon(d.icon, 30) }), title: d.name, sub: info[0] + ' · ' + info[1],
      trailing: has ? h('button.btn.sm.sec', { onclick: (e) => { e.stopPropagation(); (c && c.system) ? OS.openApp(d.id) : OS.openApp(d.id); } }, 'Ouvrir') : h('button.btn.sm', { onclick: (e) => { e.stopPropagation(); this.toggle(d.id, true); } }, 'Obtenir'),
      onlong: () => has && !(c && c.system) && ActionSheet(d.name, [{ label: 'Supprimer l\'application', red: true, onclick: () => this.toggle(d.id, false) }]) });
  },
  tab_discover() {
    const pg = Page({ title: 'Découvrir' });
    const store = S.catalog.filter(c => c.store).map(c => ({ c, d: Apps.get(c.id) })).filter(x => x.d);
    const hero = store.find(x => !S.installed.includes(x.c.id)) || store[0];
    if (hero) pg.body.appendChild(h('div.hero', { style: `background:linear-gradient(135deg, ${hero.d.grad[0]}, ${hero.d.grad[1]})` }, h('small', 'APPLICATION DU JOUR'), h('b', hero.d.name), h('p', (APP_INFO[hero.c.id] || [])[1] || ''), h('button.btn.sm', { style: 'background:#fff;color:#000;margin-top:10px', onclick: () => S.installed.includes(hero.c.id) ? OS.openApp(hero.c.id) : this.toggle(hero.c.id, true) }, S.installed.includes(hero.c.id) ? 'Ouvrir' : 'Obtenir')));
    pg.body.appendChild(Group('Applications', store.map(x => this.line(x.d, x.c))));
    const more = S.catalog.filter(c => !c.store && !c.default && Apps.get(c.id));
    if (more.length) pg.body.appendChild(Group('Autres', more.map(c => this.line(Apps.get(c.id), c))));
    return pg;
  },
  tab_mine() {
    const pg = Page({ title: 'Mes apps' });
    pg.body.appendChild(Group(null, S.installed.map(id => ({ c: S.catalog.find(x => x.id === id), d: Apps.get(id) })).filter(x => x.d).map(x => this.line(x.d, x.c)), 'Appui long sur une application pour la supprimer.'));
    return pg;
  },
};
registerApp({ id: 'appstore', name: 'App Store', icon: 'store', grad: ['#32ade6', '#0a63d6'], open: ctx => AppStore.open(ctx) });
