/* ═══════════ Plans (GPS), Garage, Localiser ═══════════ */
const PLACES = [
  ['Hôpital Pillbox', 298, -584, 'heart', '#ff453a'], ['Commissariat de Mission Row', 425, -979, 'shield', '#0a84ff'], ['Legion Square', 195, -934, 'city', '#8e8e93'],
  ['Aéroport international (LSIA)', -1037, -2737, 'plane', '#5ac8fa'], ['Vinewood Boulevard', 300, 190, 'star', '#ffd60a'], ['Plage de Vespucci', -1330, -1100, 'sun', '#ff9f0a'],
  ['Port de Los Santos', 850, -3000, 'truck', '#a2845e'], ['Concession Premium Deluxe', -45, -1100, 'car', '#34c759'], ['Banque Fleeca (centre)', 149, -1040, 'bank', '#30d158'],
  ['Mont Chiliad', 450, 5566, 'leaf', '#34c759'], ['Sandy Shores', 1850, 3700, 'home', '#ff9f0a'], ['Paleto Bay', -150, 6250, 'home', '#64d2ff'],
];
const Maps = {
  places: [],
  async open(ctx) {
    this.ctx = ctx; this.places = (await rpc('kvGet', 'places')) || [];
    const pg = Page({ title: 'Plans', right: [{ icon: 'plus', onclick: () => this.addHere() }] }); this.pg = pg; ctx.root(pg);
    this.draw();
  },
  async draw() {
    const pg = this.pg; clear(pg.body);
    const pos = (await post('position')) || { x: 0, y: 0, street: '—', zone: '' };
    pg.body.appendChild(h('div.mapcard', h('div.mapgrid'), h('div.mappin', { html: icon('locate', 34) }), h('div.mapinfo', h('b', pos.street || '—'), h('small', (pos.zone || '') + ' · ' + Math.round(pos.x) + ', ' + Math.round(pos.y)))));
    pg.body.appendChild(h('div.bankacts', this.act('pin', 'Ma position', () => Messages.shareLocationPick()), this.act('x', 'Effacer GPS', () => { post('clearWaypoint'); Toast('Itinéraire effacé', 'pin'); }), this.act('plus', 'Enregistrer ici', () => this.addHere()), this.act('car', 'Garage', () => OS.openApp('garage'))));
    const q = SearchBar({ placeholder: 'Rechercher un lieu', onInput: v => list(v) }); pg.body.appendChild(q);
    const lw = h('div'); pg.body.appendChild(lw);
    const list = (v) => {
      clear(lw); v = (v || '').toLowerCase();
      const mine = this.places.filter(p => !v || p.name.toLowerCase().includes(v));
      const std = PLACES.filter(p => !v || p[0].toLowerCase().includes(v));
      if (mine.length) lw.appendChild(Group('Mes lieux', mine.map(p => ({ icon: 'pin', color: '#ff375f', title: p.name, sub: Math.round(this.dist(pos, p)) + ' m', chev: true, onclick: () => this.go(p.x, p.y, p.name), onlong: () => ActionSheet(p.name, [{ label: 'Supprimer', red: true, onclick: async () => { this.places = this.places.filter(x => x !== p); await rpc('kvSet', 'places', this.places); list(v); } }]) }))));
      lw.appendChild(Group('Lieux populaires', std.map(p => ({ icon: p[3], color: p[4], title: p[0], sub: Math.round(this.dist(pos, { x: p[1], y: p[2] })) + ' m', chev: true, onclick: () => this.go(p[1], p[2], p[0]) }))));
    };
    list('');
  },
  dist(a, b) { return Math.hypot(a.x - b.x, a.y - b.y); },
  act(ic, label, fn) { return h('button.bact', { onclick: fn }, h('span', { html: icon(ic, 24) }), label); },
  go(x, y, name) { post('waypoint', { x, y }); Toast('GPS : ' + name, 'pin'); },
  async addHere() {
    const pos = await post('position'); if (!pos) return;
    const name = await Prompt('Nouveau lieu', 'Nommer cette position', { placeholder: pos.street || 'Lieu' }); if (name === null) return;
    this.places.push({ name: name || pos.street || 'Lieu', x: pos.x, y: pos.y }); await rpc('kvSet', 'places', this.places); this.draw();
  },
};
Messages.shareLocationPick = async function () { const c = await pickContact({ title: 'Envoyer ma position à' }); if (c) Messages.sendLocation(c.number); };
registerApp({ id: 'maps', name: 'Plans', icon: 'map', grad: ['#5ac8fa', '#34c759'], open: ctx => Maps.open(ctx) });

/* ───────────── Garage ───────────── */
const Garage = {
  async open(ctx) {
    const pg = Page({ title: 'Garage' }); ctx.root(pg); pg.body.appendChild(Spinner());
    const rows = (await rpc('garage')) || []; clear(pg.body);
    if (!rows.length) { pg.body.appendChild(Empty('car', 'Aucun véhicule', 'Les véhicules que vous possédez apparaîtront ici.')); return; }
    const named = await Promise.all(rows.map(async r => { const n = await post('vehicleName', { model: r.model }); return Object.assign(r, { name: (n && n.name) || 'Véhicule' }); }));
    pg.body.appendChild(Group(null, named.map(v => ({ icon: 'car', color: v.stored ? '#34c759' : '#ff9f0a', title: v.name, sub: v.plate + ' · ' + (v.stored ? 'Au garage' : 'Sorti'), chev: true, onclick: () => ActionSheet(v.name + ' — ' + v.plate, [
      { label: 'Localiser sur la carte', onclick: async () => { const r = await post('locateVehicle', { plate: v.plate }); Toast(r && r.found ? 'Véhicule localisé : GPS activé' : v.stored ? 'Le véhicule est rangé au garage' : 'Véhicule introuvable à proximité', 'pin'); } },
      { label: 'Carburant : ' + (v.fuel != null ? Math.round(v.fuel) + ' %' : '—') }, { label: 'État : ' + (v.engine != null ? Math.round(v.engine / 10) + ' %' : '—') }]) }))));
  },
};
registerApp({ id: 'garage', name: 'Garage', icon: 'car', grad: ['#636366', '#2c2c2e'], dark: true, open: ctx => Garage.open(ctx) });

/* ───────────── Localiser ───────────── */
const FindMy = {
  async open(ctx) {
    this.ctx = ctx;
    const holder = h('div', { style: 'position:absolute;inset:0' }); let tab = 'people';
    const bar = TabBar([{ id: 'people', label: 'Personnes', icon: 'users' }, { id: 'share', label: 'Partager', icon: 'locate' }], 'people', id => { tab = id; draw(); });
    const wrap = Page({ noNav: true, nopad: true, tabbar: bar }); wrap.body.style.cssText = 'position:relative;overflow:hidden'; wrap.body.appendChild(holder); ctx.root(wrap);
    const draw = () => { clear(holder); const pg = this['tab_' + tab](); holder.appendChild(pg.el); ctx.stack[0] = pg; pg.ctx = ctx; };
    this.draw = draw; draw();
  },
  tab_people() {
    const pg = Page({ title: 'Personnes' }); pg.body.appendChild(Spinner());
    Promise.all([rpc('fmList'), post('position')]).then(([list, me]) => {
      clear(pg.body); list = list || [];
      if (!list.length) { pg.body.appendChild(Empty('locate', 'Personne ne partage sa position', 'Vos proches peuvent partager leur position avec vous depuis l\'onglet Partager.')); return; }
      pg.body.appendChild(Group(null, list.map(p => ({ left: avatar(contactName(p.number), 44), title: contactName(p.number), sub: p.coords ? Math.round(Math.hypot(me.x - p.coords.x, me.y - p.coords.y)) + ' m de vous' : (p.online ? 'Position indisponible' : 'Hors ligne'), chev: !!p.coords, onclick: () => p.coords && ActionSheet(contactName(p.number), [{ label: 'Itinéraire', onclick: () => { post('waypoint', p.coords); Toast('GPS activé', 'pin'); } }, { label: 'Message', onclick: () => Messages.openWith(p.number) }, { label: 'Appeler', onclick: () => Calls.dial(p.number) }]) }))));
    });
    return pg;
  },
  tab_share() {
    const pg = Page({ title: 'Partager' }); pg.body.appendChild(Spinner());
    rpc('fmMine').then(mine => {
      clear(pg.body); mine = new Set(mine || []);
      pg.body.appendChild(h('div', { style: 'padding:10px 20px;color:var(--fg2);font-size:14px' }, 'Les contacts cochés peuvent voir votre position en temps réel.'));
      pg.body.appendChild(S.contactList.length ? Group(null, S.contactList.map(c => ({ left: avatar(c.name, 36, c.avatar), title: c.name, sub: fmtNum(c.number), toggle: { on: mine.has(c.number), onchange: async v => { const ok = await rpc('fmShare', c.number, v); if (!ok) Toast('Ce contact n\'a pas de téléphone', 'warning'); } } }))) : Empty('users', 'Aucun contact'));
    });
    return pg;
  },
};
registerApp({ id: 'findmy', name: 'Localiser', icon: 'locate', grad: ['#7ed957', '#00a65a'], open: ctx => FindMy.open(ctx) });
