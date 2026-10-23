/* ═══════════ Appareil photo & Photos ═══════════ */
const Cam = {
  selfie: false, active: false, last: null,
  open(ctx) {
    const pg = Page({ noNav: true, nopad: true });
    pg.el.classList.add('cam-page');
    const hint = h('div.cam-hint', h('div', { html: icon('camera', 56) }), h('b', 'Appareil photo'), h('p', 'Touchez l\'obturateur : le viseur s\'ouvre dans le jeu.'), h('p', { style: 'font-size:13px;opacity:.7' }, 'ENTRÉE : photo · E : retourner · Molette : zoom · RETOUR : quitter'));
    const thumb = h('div.cam-thumb', { onclick: () => OS.openApp('photos') });
    const shut = h('button.cam-shutter', { onclick: () => this.start(false) }, h('i'));
    const flip = h('button.cam-flip', { html: icon('flip', 26), onclick: () => this.start(true) });
    const mode = h('div.cam-modes', h('span.on', 'PHOTO'), h('span', { style: 'opacity:.4' }, 'VIDÉO (bientôt)'));
    pg.body.appendChild(h('div.cam-wrap', hint, mode, h('div.cam-bar', thumb, shut, flip)));
    ctx.root(pg);
    rpc('photos').then(p => { if (p && p[0]) thumb.style.backgroundImage = `url("${p[0].url}")`; });
  },
  start(selfie) {
    this.selfie = !!selfie; this.active = true;
    post('cameraStart', { selfie: this.selfie });
    OS.hide(); this.hud(true);
  },
  hud(on) {
    const el = $('#camhud'); el.classList.toggle('hidden', !on);
    if (!on) return;
    clear(el);
    el.appendChild(h('div.vf', h('i.corner.tl'), h('i.corner.tr'), h('i.corner.bl'), h('i.corner.br')));
    el.appendChild(h('div.zoom#cam-zoom', 'Zoom 0 %'));
    el.appendChild(h('div.flash#cam-flash'));
    el.appendChild(h('div.thumb#cam-thumb'));
    el.appendChild(h('div.hintbar', h('span', h('kbd', 'ENTRÉE'), 'Photo'), h('span', h('kbd', 'E'), this.selfie ? 'Caméra arrière' : 'Selfie'), h('span', h('kbd', 'MOLETTE'), 'Zoom'), h('span', h('kbd', 'RETOUR'), 'Quitter')));
  },
};
registerApp({ id: 'camera', name: 'Appareil photo', icon: 'camera', grad: ['#8e8e93', '#48484a'], dark: true, open: ctx => Cam.open(ctx) });

/* messages du jeu pour la caméra */
window.addEventListener('message', e => {
  const d = e.data || {};
  if (d.action === 'cameraFlash') { const f = $('#cam-flash'); if (f) { f.classList.remove('go'); void f.offsetWidth; f.classList.add('go'); Sound.shutter(); } }
  else if (d.action === 'cameraHide') { const el = $('#camhud'); if (el) el.style.visibility = d.state ? 'hidden' : 'visible'; }
  else if (d.action === 'cameraShot') { const t = $('#cam-thumb'); if (t) { t.style.display = 'block'; t.style.backgroundImage = `url("${d.photo.url}")`; } Cam.last = d.photo; Bus.emit('photoTaken', d.photo); }
  else if (d.action === 'cameraError') { const el = $('#camhud'); if (el) { const x = h('div.err', d.error); el.appendChild(x); setTimeout(() => x.remove(), 3500); } }
  else if (d.action === 'cameraZoom') { const z = $('#cam-zoom'); if (z) z.textContent = 'Zoom ' + Math.max(0, d.value) + ' %'; }
  else if (d.action === 'cameraMode') { Cam.selfie = d.selfie; Cam.hud(true); }
  else if (d.action === 'cameraStopped') { Cam.active = false; Cam.hud(false); }
});

/* ───── Photos ───── */
const Photos = {
  list: [], sel: new Set(), selecting: false,
  async open(ctx) {
    this.ctx = ctx; this.tab = 'all';
    const tabs = [{ id: 'all', label: 'Photothèque', icon: 'image' }, { id: 'favs', label: 'Favoris', icon: 'heart' }, { id: 'albums', label: 'Albums', icon: 'grid' }];
    const holder = h('div', { style: 'position:absolute;inset:0' });
    const bar = TabBar(tabs, 'all', id => { this.tab = id; draw(); });
    const wrap = Page({ noNav: true, nopad: true, tabbar: bar });
    wrap.body.style.cssText = 'position:relative;overflow:hidden'; wrap.body.appendChild(holder);
    ctx.root(wrap);
    const draw = () => {
      clear(holder); this.selecting = false; this.sel.clear();
      const pg = this.page(ctx); holder.appendChild(pg.el); ctx.stack[0] = pg; pg.ctx = ctx;
    };
    this.draw = draw;
    this.list = (await rpc('photos')) || []; draw();
  },
  page(ctx) {
    const title = { all: 'Photothèque', favs: 'Favoris', albums: 'Albums' }[this.tab];
    const right = [{ label: this.selecting ? 'Annuler' : 'Sélectionner', onclick: () => { this.selecting = !this.selecting; this.sel.clear(); this.draw(); } }];
    if (this.tab === 'albums') right.length = 0;
    const pg = Page({ title, right });
    if (this.tab === 'albums') {
      const cnt = (f) => this.list.filter(f).length;
      pg.body.appendChild(Group(null, [
        { icon: 'image', color: 'var(--accent)', title: 'Récents', value: cnt(() => true), chev: true, onclick: () => { this.tab = 'all'; this.draw(); } },
        { icon: 'heart', color: '#ff375f', title: 'Favoris', value: cnt(p => p.favorite), chev: true, onclick: () => { this.tab = 'favs'; this.draw(); } },
      ]));
      return pg;
    }
    const items = this.list.filter(p => this.tab !== 'favs' || p.favorite);
    if (!items.length) { pg.body.appendChild(Empty('image', this.tab === 'favs' ? 'Aucun favori' : 'Aucune photo', 'Les photos prises avec l\'appareil apparaîtront ici.')); return pg; }
    const grid = h('div.pgrid');
    items.forEach(p => {
      const c = h('div.pcell' + (this.sel.has(p.id) ? '.sel' : ''), { style: `background-image:url("${p.url}")`, onclick: () => {
        if (this.selecting) { this.sel.has(p.id) ? this.sel.delete(p.id) : this.sel.add(p.id); c.classList.toggle('sel'); this.updateSel(pg); return; }
        this.view(p, items, ctx);
      } });
      if (p.favorite) c.appendChild(h('span.fv', { html: icon('heartFill', 14) }));
      grid.appendChild(c);
    });
    pg.body.appendChild(grid);
    pg.body.appendChild(h('div', { style: 'text-align:center;color:var(--fg2);padding:16px' }, items.length + ' photo' + (items.length > 1 ? 's' : '')));
    this.updateSel(pg);
    return pg;
  },
  updateSel(pg) {
    if (!this.selecting) return;
    pg.setRight([{ label: 'Annuler', onclick: () => { this.selecting = false; this.sel.clear(); this.draw(); } }, { label: this.sel.size ? 'Supprimer (' + this.sel.size + ')' : 'Supprimer', danger: true, disabled: !this.sel.size, onclick: async () => { if (await Confirm('Supprimer ' + this.sel.size + ' photo(s) ?', 'Cette action est définitive.', 'Supprimer', true)) { await rpc('photoDelete', [...this.sel]); this.list = (await rpc('photos')) || []; this.selecting = false; this.sel.clear(); this.draw(); } } }]);
  },
  view(p, items, ctx) {
    const actions = [
      { icon: p.favorite ? 'heartFill' : 'heart', onclick: async (close) => { await rpc('photoFav', p.id, !p.favorite); p.favorite = p.favorite ? 0 : 1; close(); this.draw(); } },
      { icon: 'share', onclick: () => this.share(p) },
      { icon: 'trash', red: true, onclick: async (close) => { if (await Confirm('Supprimer cette photo ?', null, 'Supprimer', true)) { await rpc('photoDelete', [p.id]); this.list = this.list.filter(x => x.id !== p.id); close(); this.draw(); } } },
    ];
    viewImage(p.url, actions);
  },
  share(p) {
    ActionSheet('Partager la photo', [
      { label: 'Messages', onclick: async () => { const n = await pickContactNumber(); if (!n) return; const r = await rpc('msgSend', { to: n, kind: 'image', body: p.url }); Toast(r && r.ok ? 'Photo envoyée' : 'Échec', 'image'); } },
      { label: 'AirShare', onclick: () => AirShare.send('photo', { url: p.url }) },
      { label: 'Publier sur Pulse', onclick: () => Social.quickPost('pulse', p.url) },
      { label: 'Publier sur Snapgram', onclick: () => Social.quickPost('snap', p.url) },
      { label: 'Fond d\'écran', onclick: async () => { S.settings.customWallpaper = p.url; S.settings.wallpaper = 'custom'; await rpc('settingsSet', { customWallpaper: p.url, wallpaper: 'custom' }); OS.drawWallpaper(); Toast('Fond d\'écran modifié', 'image'); } },
      { label: 'Copier le lien', onclick: () => Contacts.copy(p.url) },
    ]);
  },
};
registerApp({ id: 'photos', name: 'Photos', icon: 'image', grad: ['#ffd60a', '#ff375f'], open: ctx => Photos.open(ctx) });
