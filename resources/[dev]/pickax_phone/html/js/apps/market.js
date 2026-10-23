/* ═══════════ Annonces (marché) ═══════════ */
const Market = {
  cat: 'all',
  async open(ctx) {
    this.ctx = ctx;
    const holder = h('div', { style: 'position:absolute;inset:0' }); let tab = 'browse';
    const bar = TabBar([{ id: 'browse', label: 'Parcourir', icon: 'tag' }, { id: 'sell', label: 'Vendre', icon: 'plus' }, { id: 'mine', label: 'Mes annonces', icon: 'list' }], 'browse', id => { tab = id; draw(); });
    const wrap = Page({ noNav: true, nopad: true, tabbar: bar }); wrap.body.style.cssText = 'position:relative;overflow:hidden'; wrap.body.appendChild(holder); ctx.root(wrap);
    const draw = () => { clear(holder); const pg = this['tab_' + tab](); holder.appendChild(pg.el); ctx.stack[0] = pg; pg.ctx = ctx; };
    this.draw = draw; draw();
  },
  tab_browse() {
    const pg = Page({ title: 'Annonces' });
    let q = '', timer;
    pg.body.appendChild(SearchBar({ placeholder: 'Rechercher une annonce', onInput: v => { q = v; clearTimeout(timer); timer = setTimeout(load, 300); } }));
    const cats = ['all', ...(S.config.market || [])];
    const chips = h('div', { style: 'display:flex;gap:8px;overflow:auto;padding:0 16px 12px' }, cats.map(c => h('button.chip' + (c === this.cat ? '.sel' : ''), { style: c === this.cat ? 'background:var(--accent);color:#fff' : '', onclick: () => { this.cat = c; this.draw(); } }, c === 'all' ? 'Tout' : c)));
    pg.body.appendChild(chips);
    const grid = h('div.mgrid'); pg.body.appendChild(grid);
    const load = async () => {
      clear(grid); grid.appendChild(Spinner());
      const rows = (await rpc('marketList', this.cat, q)) || []; clear(grid);
      if (!rows.length) { grid.style.display = 'block'; grid.appendChild(Empty('tag', 'Aucune annonce', 'Soyez le premier à publier !')); return; }
      grid.style.display = 'grid';
      rows.forEach(a => grid.appendChild(h('div.mitem', { onclick: () => this.detail(a) }, h('div.mimg', { style: a.images[0] ? `background-image:url("${a.images[0]}")` : '' }, a.images[0] ? null : h('span', { html: icon('image', 34) })), h('div.mt', h('b', money(a.price)), h('div', a.title), h('small', a.category + ' · ' + ago(a.created))))));
    };
    load();
    return pg;
  },
  detail(a) {
    const pg = Page({ title: 'Annonce', large: false, back: 'Retour', right: a.mine ? [] : [{ icon: 'share', onclick: () => Contacts.copy(a.title + ' — ' + money(a.price)) }] });
    if (a.images.length) pg.body.appendChild(h('div', { style: 'display:flex;overflow:auto;scroll-snap-type:x mandatory' }, a.images.map(u => h('img', { src: u, style: 'width:100%;flex:none;aspect-ratio:4/3;object-fit:cover;scroll-snap-align:center', onclick: () => viewImage(u) }))));
    pg.body.appendChild(h('div', { style: 'padding:16px 20px' }, h('div', { style: 'font-size:30px;font-weight:700' }, money(a.price)), h('div', { style: 'font-size:20px;margin:4px 0' }, a.title), h('div', { style: 'color:var(--fg2);font-size:14px' }, a.category + ' · ' + ago(a.created)), h('div', { style: 'margin-top:14px;line-height:1.45;white-space:pre-wrap;user-select:text' }, a.descr || '')));
    pg.body.appendChild(Group('Vendeur', [{ left: avatar(a.seller, 40), title: a.seller, sub: fmtNum(a.number) }]));
    if (!a.mine) pg.body.appendChild(h('div', { style: 'display:flex;gap:12px;padding:0 16px' }, h('button.btn', { style: 'flex:1', onclick: () => Messages.openWith(a.number) }, 'Message'), h('button.btn.green', { style: 'flex:1', onclick: () => Calls.dial(a.number) }, 'Appeler')));
    else pg.body.appendChild(Group(null, [{ title: 'Supprimer l\'annonce', danger: true, center: true, onclick: async () => { await rpc('marketDelete', a.id); this.ctx.pop(); this.draw(); } }]));
    this.ctx.push(pg);
  },
  tab_sell() {
    const v = { title: '', price: '', category: (S.config.market || [])[0] || 'Autre', descr: '', images: [] };
    const pg = Page({ title: 'Vendre', right: [{ label: 'Publier', bold: true, onclick: async () => {
      if (!v.title.trim()) { Toast('Titre requis', 'warning'); return; }
      const r = await rpc('marketCreate', v); if (!r) { Toast(rpc.err || 'Publication impossible', 'warning'); return; }
      Toast('Annonce publiée', 'check'); this.draw();
    } }] });
    const prev = h('div', { style: 'display:flex;gap:8px;flex-wrap:wrap;padding:0 16px 14px' });
    const lim = S.config.maxMarketImages || 4;
    const drawI = () => { clear(prev); v.images.forEach((u, i) => prev.appendChild(h('div', { style: `width:90px;height:90px;border-radius:10px;background:url("${u}") center/cover;position:relative` }, h('button', { style: 'position:absolute;top:3px;right:3px;width:22px;height:22px;border-radius:50%;background:rgba(0,0,0,.6);color:#fff', html: icon('x', 12), onclick: () => { v.images.splice(i, 1); drawI(); } })))); if (v.images.length < lim) prev.appendChild(h('button', { style: 'width:90px;height:90px;border-radius:10px;border:2px dashed var(--fg3);display:grid;place-items:center;color:var(--fg2)', html: icon('camera', 28), onclick: () => ActionSheet('Ajouter une photo', [{ label: 'Depuis la galerie', onclick: () => Messages.pickPhoto(u => { v.images.push(u); drawI(); }) }, { label: 'Par lien', onclick: async () => { const u = await Prompt('Lien de la photo', null, { placeholder: 'https://…' }); if (u && /^https?:/.test(u)) { v.images.push(u); drawI(); } } }]) })); };
    drawI();
    pg.body.appendChild(h('div', { style: 'padding:6px 20px;color:var(--fg2)' }, 'Photos')); pg.body.appendChild(prev);
    pg.body.appendChild(Group(null, [{ label: 'Titre', input: true, left: true, maxlength: 80, placeholder: 'Titre', onInput: x => v.title = x }, { label: 'Prix ($)', input: true, left: true, type: 'number', placeholder: '0', onInput: x => v.price = x },
      { label: 'Catégorie', el: h('select', { style: 'flex:1;text-align:right;font-size:17px;background:none;color:var(--fg)', onchange: e => v.category = e.target.value }, (S.config.market || []).map(c => h('option', { value: c, style: 'color:#000' }, c))) }]));
    pg.body.appendChild(Group('Description', [{ input: true, multiline: true, left: true, rows: 5, maxlength: 800, placeholder: 'Décrivez votre article…', onInput: x => v.descr = x }]));
    return pg;
  },
  tab_mine() {
    const pg = Page({ title: 'Mes annonces' }); pg.body.appendChild(Spinner());
    rpc('marketMine').then(rows => {
      clear(pg.body); rows = rows || [];
      if (!rows.length) { pg.body.appendChild(Empty('tag', 'Aucune annonce', 'Publiez votre première annonce depuis l\'onglet Vendre.')); return; }
      pg.body.appendChild(Group(null, rows.map(a => ({ left: h('div', { style: `width:54px;height:54px;border-radius:10px;background:var(--card2) url("${a.images[0] || ''}") center/cover` }), title: a.title, sub: money(a.price) + ' · ' + (a.sold ? 'Vendu' : 'En ligne'), chev: true, onclick: () => ActionSheet(a.title, [
        { label: a.sold ? 'Remettre en ligne' : 'Marquer comme vendu', onclick: async () => { await rpc('marketUpdate', a.id, { sold: !a.sold }); this.draw(); } },
        { label: 'Modifier le prix', onclick: async () => { const p = await Prompt('Nouveau prix', null, { value: a.price, type: 'number' }); if (p != null && p !== '') { await rpc('marketUpdate', a.id, { price: Number(p) }); this.draw(); } } },
        { label: 'Supprimer', red: true, onclick: async () => { await rpc('marketDelete', a.id); this.draw(); } }]) }))));
    });
    return pg;
  },
};
registerApp({ id: 'market', name: 'Annonces', icon: 'tag', grad: ['#ff9500', '#ff5e3a'], open: ctx => Market.open(ctx) });
