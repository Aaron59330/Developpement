/* ═══════════ Pulse (micro-blog), Snapgram (photos & stories) ═══════════ */
const Social = {
  accts: {},
  badge(v) { return v ? h('span', { style: 'color:#1d9bf0;margin-left:3px', html: icon('check', 13).replace('stroke-width="1.8"', 'stroke-width="3.5"') }) : null; },

  async open(app, ctx) {
    const cfg = { pulse: { title: 'Pulse', color: '#1d9bf0' }, snap: { title: 'Snapgram', color: '#e1306c' } }[app];
    const st = { app, ctx, tab: 'home', acct: null, cfg };
    this.accts[app] = null;
    ctx.state = st;
    const acct = await rpc('acctGet', app);
    if (!acct) return this.onboard(st);
    st.acct = acct; this.accts[app] = acct; this.shell(st);
  },
  onboard(st) {
    const { app, ctx, cfg } = st;
    const v = { handle: '', display: S.me.name, avatar: '' };
    const pg = Page({ noNav: true, nopad: true }); pg.el.style.background = `linear-gradient(160deg, ${cfg.color}, #111)`; pg.el.classList.add('dark');
    pg.body.appendChild(h('div', { style: 'padding:90px 28px;color:#fff;text-align:center' },
      h('div', { style: 'font-size:46px;font-weight:800;letter-spacing:-1px' }, cfg.title), h('p', { style: 'opacity:.85;margin:10px 0 28px' }, app === 'pulse' ? 'Dites ce qui se passe à Los Santos.' : 'Partagez vos plus beaux moments.'),
      h('div', { style: 'background:rgba(255,255,255,.12);border-radius:14px;overflow:hidden;text-align:left' },
        Row({ label: 'Pseudo', input: true, left: true, placeholder: '@identifiant', onInput: x => v.handle = x.replace(/^@/, '').toLowerCase() }),
        Row({ label: 'Nom', input: true, left: true, value: v.display, placeholder: 'Nom affiché', onInput: x => v.display = x }),
        Row({ label: 'Photo', input: true, left: true, placeholder: 'Lien (facultatif)', onInput: x => v.avatar = x })),
      h('button.btn.block', { style: 'margin-top:22px;background:#fff;color:#111', onclick: async () => {
        const r = await rpc('acctCreate', app, v.handle, v.display, v.avatar);
        if (!r) { Toast(rpc.err || 'Création impossible', 'warning'); return; }
        st.acct = r; this.accts[app] = r; this.shell(st);
      } }, 'Créer mon compte')));
    ctx.root(pg);
  },

  shell(st) {
    const { app, ctx } = st;
    const tabs = app === 'pulse'
      ? [{ id: 'home', label: 'Accueil', icon: 'home' }, { id: 'search', label: 'Recherche', icon: 'search' }, { id: 'post', label: 'Publier', icon: 'plus' }, { id: 'me', label: 'Profil', icon: 'user' }]
      : [{ id: 'home', label: 'Accueil', icon: 'home' }, { id: 'search', label: 'Recherche', icon: 'search' }, { id: 'post', label: 'Publier', icon: 'plus' }, { id: 'me', label: 'Profil', icon: 'user' }];
    const holder = h('div', { style: 'position:absolute;inset:0' });
    const bar = TabBar(tabs, 'home', id => { if (id === 'post') { bar.querySelectorAll('button').forEach(b => b.classList.toggle('on', b.id_ === st.tab)); this.compose(st); return; } st.tab = id; draw(); });
    const wrap = Page({ noNav: true, nopad: true, tabbar: bar }); wrap.body.style.cssText = 'position:relative;overflow:hidden'; wrap.body.appendChild(holder);
    ctx.root(wrap);
    const draw = () => { clear(holder); const pg = this['tab_' + st.tab](st); holder.appendChild(pg.el); ctx.stack[0] = pg; pg.ctx = ctx; };
    st.draw = draw; draw();
    st.unsub = [Bus.on('push:notify', d => { if (d.app === app && st.tab === 'home' && ctx.alive && ctx.stack.length === 1) draw(); })];
  },

  /* ───── cartes de publication ───── */
  card(p, st, opts) {
    opts = opts || {};
    const { app } = st; const mine = st.acct && p.handle === st.acct.handle;
    if (p.repost && p.original && !p.body && !(p.images || []).length) {
      const c = this.card(p.original, st, { head: p.display + ' a partagé' }); return c;
    }
    const el = h('div.post' + (app === 'snap' ? '.snapcard' : ''));
    if (opts.head) el.appendChild(h('div.rt', { html: icon('repost', 14) }, ' ' + opts.head));
    const head = h('div.ph', h('div', { onclick: () => this.profile(p.handle, st) }, avatar(p.display, app === 'snap' ? 34 : 44, p.avatar)),
      h('div.pn', { onclick: () => this.profile(p.handle, st) }, h('b', p.display, this.badge(p.verified)), h('span', (app === 'snap' ? '' : '@' + p.handle + ' · ') + ago(p.created))),
      h('button.pm', { html: icon('more', 20), onclick: () => ActionSheet(null, [mine || S.me.admin ? { label: 'Supprimer', red: true, onclick: async () => { if (await rpc('postDelete', app, p.id)) { Toast('Supprimé', 'trash'); st.draw(); } } } : null, { label: 'Copier le texte', onclick: () => Contacts.copy(p.body || '') }, { label: 'Voir le profil', onclick: () => this.profile(p.handle, st) }].filter(Boolean)) }));
    el.appendChild(head);
    if (app === 'snap' && (p.images || []).length) el.appendChild(h('img.simg', { src: p.images[0], onclick: () => viewImage(p.images[0]) }));
    const body = h('div.pb');
    if (p.body) body.appendChild(h('div.pt', { html: linkify(p.body), onclick: (e) => { const a = e.target.closest('a'); if (a && a.dataset.tag) this.tag(a.dataset.tag, st); else if (a && a.dataset.user) this.profile(a.dataset.user, st); else if (!opts.noOpen) this.detail(p, st); } }));
    if (app === 'pulse' && (p.images || []).length) body.appendChild(h('div.pimgs.n' + p.images.length, p.images.map(u => h('img', { src: u, onclick: () => viewImage(u) }))));
    if (p.repost && p.original && (p.body || (p.images || []).length)) body.appendChild(h('div.quote-post', this.card(p.original, st, { noOpen: true })));
    const act = h('div.pa');
    const mk = (ic, n, cls, fn) => h('button' + (cls ? '.' + cls : ''), { onclick: (e) => { e.stopPropagation(); fn(e); } }, h('span', { html: icon(ic, 19) }), n ? String(n) : '');
    const like = mk(p.liked ? 'heartFill' : 'heart', p.likes, p.liked ? 'on.like' : 'like', () => {});
    like.onclick = async (e) => { e.stopPropagation(); p.liked = !p.liked; p.likes += p.liked ? 1 : -1; like.classList.toggle('on', p.liked); like.innerHTML = icon(p.liked ? 'heartFill' : 'heart', 19) + (p.likes || ''); await rpc('like', app, p.id, p.liked); };
    act.appendChild(mk('reply', p.replies, '', () => this.detail(p, st, true)));
    if (app === 'pulse') act.appendChild(mk('repost', p.reposts, p.reposted ? 'on.rp' : '', async () => { const r = await rpc('post', 'pulse', { repost: p.id, body: '' }); Toast(r ? 'Partagé' : (rpc.err || 'Impossible'), 'repost'); }));
    act.appendChild(like);
    act.appendChild(mk('share', 0, '', () => ActionSheet(null, [{ label: 'Envoyer par message', onclick: async () => { const n = await pickContactNumber(); if (n) { const r = await rpc('msgSend', { to: n, body: (p.display + ' (@' + p.handle + ') : ' + (p.body || '')).slice(0, 900) }); Toast(r && r.ok ? 'Envoyé' : 'Échec', 'message'); } } }, { label: 'Copier le texte', onclick: () => Contacts.copy(p.body || '') }])));
    body.appendChild(act);
    if (app === 'snap' && p.body) { /* légende déjà dans pt */ }
    el.appendChild(body);
    return el;
  },

  /* ───── onglets ───── */
  tab_home(st) {
    const { app } = st;
    const pg = Page({ title: st.cfg.title, right: [{ icon: 'edit', onclick: () => this.compose(st) }] });
    if (app === 'pulse') {
      let mode = st.mode || 'explore';
      pg.body.appendChild(Seg([{ value: 'explore', label: 'Pour vous' }, { value: 'following', label: 'Abonnements' }], mode, v => { st.mode = v; st.draw(); }));
      pg.body.appendChild(h('div#feed', Spinner()));
      this.loadFeed(st, pg, mode);
    } else {
      pg.body.appendChild(h('div.stories#stories'));
      pg.body.appendChild(h('div#feed', Spinner()));
      this.loadStories(st, pg); this.loadFeed(st, pg, 'explore');
    }
    return pg;
  },
  async loadFeed(st, pg, mode, before) {
    const feed = $('#feed', pg.body); if (!feed) return;
    const posts = (await rpc('feed', st.app, mode, before)) || [];
    if (!before) clear(feed);
    if (!posts.length && !before) { feed.appendChild(Empty(st.app === 'pulse' ? 'message' : 'image', 'Rien pour le moment', mode === 'following' ? 'Suivez des comptes pour voir leurs publications ici.' : 'Soyez le premier à publier !')); return; }
    posts.forEach(p => feed.appendChild(this.card(p, st)));
    if (posts.length >= 30) feed.appendChild(h('button.btn.sec.block', { style: 'margin:10px 16px;width:calc(100% - 32px)', onclick: (e) => { e.target.remove(); this.loadFeed(st, pg, mode, posts[posts.length - 1].id); } }, 'Voir plus'));
  },
  async loadStories(st, pg) {
    const el = $('#stories', pg.body); if (!el) return;
    const rows = (await rpc('feed', 'snap', 'stories')) || [];
    clear(el);
    el.appendChild(h('div.story', { onclick: () => this.compose(st, true) }, h('div.sring.add', avatar(st.acct.display, 56, st.acct.avatar), h('i', { html: icon('plus', 14) })), h('span', 'Ma story')));
    const by = {}; rows.forEach(r => (by[r.handle] = by[r.handle] || []).push(r));
    Object.values(by).forEach(list => el.appendChild(h('div.story', { onclick: () => this.storyViewer(list.slice().reverse()) }, h('div.sring', avatar(list[0].display, 56, list[0].avatar)), h('span', list[0].handle))));
  },
  storyViewer(list) {
    let i = 0, t;
    const node = h('div', { style: 'position:absolute;inset:0;z-index:165;background:#000;color:#fff;animation:fadein .2s' });
    const draw = () => {
      clear(node); const p = list[i];
      node.appendChild(h('div', { style: 'position:absolute;top:54px;left:10px;right:10px;display:flex;gap:4px;z-index:2' }, list.map((_, k) => h('div', { style: 'flex:1;height:3px;border-radius:2px;background:rgba(255,255,255,' + (k <= i ? .95 : .3) + ')' }))));
      node.appendChild(h('div', { style: 'position:absolute;top:70px;left:14px;display:flex;gap:10px;align-items:center;z-index:2' }, avatar(p.display, 34, p.avatar), h('b', p.display), h('span', { style: 'opacity:.7;font-size:13px' }, ago(p.created))));
      node.appendChild(h('img', { src: p.images[0], style: 'width:100%;height:100%;object-fit:contain' }));
      if (p.body) node.appendChild(h('div', { style: 'position:absolute;bottom:60px;left:20px;right:20px;text-align:center;font-size:18px;text-shadow:0 1px 6px #000' }, p.body));
      node.appendChild(h('div', { style: 'position:absolute;inset:100px 0 0;display:flex;z-index:1' }, h('div', { style: 'flex:1', onclick: () => { if (i > 0) { i--; draw(); } } }), h('div', { style: 'flex:2', onclick: next })));
      node.appendChild(h('button', { style: 'position:absolute;top:66px;right:14px;z-index:3;color:#fff', html: icon('x', 26), onclick: () => { clearTimeout(t); node.remove(); } }));
      clearTimeout(t); t = setTimeout(next, 5000);
    };
    const next = () => { if (i < list.length - 1) { i++; draw(); } else { clearTimeout(t); node.remove(); } };
    Screen().appendChild(node); draw();
  },
  tab_search(st) {
    const { app } = st;
    const pg = Page({ title: 'Recherche' }); let timer;
    const res = h('div');
    const bar = SearchBar({ placeholder: app === 'pulse' ? 'Comptes, #tendances' : 'Rechercher des comptes', onInput: q => { clearTimeout(timer); timer = setTimeout(() => run(q), 250); } });
    pg.body.appendChild(bar); pg.body.appendChild(res);
    const run = async (q) => {
      const r = (await rpc('socialSearch', app, q)) || { accounts: [], tags: [] }; clear(res);
      if (r.tags.length) res.appendChild(Group('Tendances', r.tags.map((t, i) => ({ title: '#' + t.tag, sub: t.count + ' publication' + (t.count > 1 ? 's' : ''), left: h('b', { style: 'width:24px;color:var(--fg2)' }, i + 1), onclick: () => this.tag(t.tag, st) }))));
      if (r.accounts.length) res.appendChild(Group('Comptes', r.accounts.map(a => ({ left: avatar(a.display, 40, a.avatar), title: h('span', a.display, this.badge(a.verified)), sub: '@' + a.handle, onclick: () => this.profile(a.handle, st) }))));
      if (!r.tags.length && !r.accounts.length) res.appendChild(Empty('search', q ? 'Aucun résultat' : 'Rien à afficher'));
    };
    run('');
    return pg;
  },
  tab_me(st) {
    const pg = Page({ title: 'Profil', right: [{ label: 'Modifier', onclick: () => this.editProfile(st) }] });
    this.profileBody(pg, st.acct.handle, st);
    return pg;
  },

  async profileBody(pg, handle, st) {
    pg.body.appendChild(Spinner());
    const p = await rpc('profile', st.app, handle);
    clear(pg.body);
    if (!p) { pg.body.appendChild(Empty('user', 'Compte introuvable')); return; }
    pg.setTitle(p.display);
    pg.body.appendChild(h('div.prof', { style: p.banner ? `background:linear-gradient(rgba(0,0,0,.2),rgba(0,0,0,.2)),url("${p.banner}") center/cover` : '' },
      h('div', { style: 'margin-top:24px' }, avatar(p.display, 84, p.avatar)),
      h('div', { style: 'font-size:22px;font-weight:700;margin-top:8px' }, p.display, this.badge(p.verified)), h('div', { style: 'opacity:.7' }, '@' + p.handle),
      p.bio ? h('div', { style: 'margin:8px 20px 0;opacity:.9' }, p.bio) : null,
      h('div.pstats', h('div', h('b', p.posts), h('small', 'publications')), h('div', h('b', p.followers), h('small', 'abonnés')), h('div', h('b', p.following), h('small', 'abonnements'))),
      p.isMe ? null : h('button.btn' + (p.isFollowing ? '.sec' : ''), { style: 'margin-top:12px;min-width:150px', onclick: async (e) => { await rpc('follow', st.app, p.handle, !p.isFollowing); pg.render ? null : null; clear(pg.body); this.profileBody(pg, handle, st); } }, p.isFollowing ? 'Abonné ✓' : 'Suivre')));
    const feed = h('div'); pg.body.appendChild(feed);
    const posts = (await rpc('feed', st.app, 'user:' + p.handle)) || [];
    if (!posts.length) feed.appendChild(Empty('message', 'Aucune publication'));
    else if (st.app === 'snap') feed.appendChild(h('div', { style: 'display:grid;grid-template-columns:repeat(3,1fr);gap:2px' }, posts.map(x => h('div', { style: `aspect-ratio:1;background:url("${(x.images || [])[0]}") center/cover`, onclick: () => this.detail(x, st) }))));
    else posts.forEach(x => feed.appendChild(this.card(x, st)));
  },
  profile(handle, st) {
    const pg = Page({ title: '@' + handle, large: false, back: 'Retour' }); st.ctx.push(pg); this.profileBody(pg, handle, st);
  },
  tag(tag, st) {
    const pg = Page({ title: '#' + tag, back: 'Retour' }); pg.body.appendChild(h('div#feed', Spinner())); st.ctx.push(pg); this.loadFeed(st, pg, 'tag:' + tag);
  },
  editProfile(st) {
    const a = Object.assign({}, st.acct);
    const pg = Page({ title: 'Modifier le profil', large: false, modal: true, left: [{ label: 'Annuler', onclick: () => st.ctx.pop() }], right: [{ label: 'OK', bold: true, onclick: async () => { const r = await rpc('acctUpdate', st.app, a); if (r) { st.acct = r; this.accts[st.app] = r; st.ctx.pop(); st.draw(); } } }] });
    pg.body.appendChild(Group(null, [{ label: 'Nom', input: true, left: true, value: a.display, onInput: v => a.display = v }, { label: 'Photo', input: true, left: true, value: a.avatar || '', placeholder: 'Lien d\'image', onInput: v => a.avatar = v }, { label: 'Bannière', input: true, left: true, value: a.banner || '', placeholder: 'Lien d\'image', onInput: v => a.banner = v }, { label: 'Bio', input: true, left: true, value: a.bio || '', maxlength: 200, onInput: v => a.bio = v }]));
    st.ctx.push(pg);
  },

  /* ───── détail & commentaires ───── */
  async detail(p, st, focus) {
    const pg = Page({ title: st.app === 'pulse' ? 'Publication' : 'Photo', large: false, back: 'Retour' });
    pg.body.classList.add('nopad'); pg.body.style.cssText = 'display:flex;flex-direction:column;overflow:hidden';
    const scroll = h('div', { style: 'flex:1;overflow:auto' });
    const inp = h('input', { placeholder: 'Répondre…', style: 'flex:1;height:38px;border-radius:19px;background:var(--card2);padding:0 14px;font-size:16px' });
    const send = h('button', { style: 'color:var(--accent);font-weight:600;padding:0 8px', onclick: async () => { const t = inp.value.trim(); if (!t) return; inp.value = ''; const r = await rpc('post', st.app, { body: t, parent: p.id }); if (!r) Toast(rpc.err || 'Erreur', 'warning'); else load(); } }, 'Publier');
    pg.body.appendChild(scroll); pg.body.appendChild(h('div', { style: 'display:flex;gap:8px;padding:8px 12px 30px;border-top:.5px solid var(--sep);align-items:center' }, inp, send));
    const load = async () => {
      clear(scroll); scroll.appendChild(this.card(p, st, { noOpen: true }));
      const cm = (await rpc('comments', st.app, p.id)) || [];
      cm.forEach(c => scroll.appendChild(this.card(c, st, { noOpen: true })));
      if (!cm.length) scroll.appendChild(h('div', { style: 'text-align:center;color:var(--fg2);padding:30px' }, 'Aucune réponse'));
    };
    st.ctx.push(pg); await load(); if (focus) setTimeout(() => inp.focus(), 420);
  },

  /* ───── nouvelle publication ───── */
  compose(st, story) {
    const { app } = st; const v = { body: '', images: [], story: !!story };
    const max = (S.config.social && S.config.social.max) || 280;
    const pg = Page({ title: story ? 'Nouvelle story' : 'Nouvelle publication', large: false, modal: true, left: [{ label: 'Annuler', onclick: () => st.ctx.pop() }], right: [{ label: 'Publier', bold: true, onclick: async () => {
      if (app === 'snap' && !v.images.length) { Toast('Ajoutez une photo', 'warning'); return; }
      const r = await rpc('post', app, { body: v.body, images: v.images, kind: v.story ? 'story' : 'post' });
      if (!r) { Toast(rpc.err || 'Publication impossible', 'warning'); return; }
      Toast('Publié', 'check'); st.ctx.pop(); st.tab = 'home'; st.draw();
    } }] });
    const prev = h('div', { style: 'display:flex;gap:8px;flex-wrap:wrap;padding:0 16px' });
    const drawImgs = () => { clear(prev); v.images.forEach((u, i) => prev.appendChild(h('div', { style: `width:96px;height:96px;border-radius:10px;background:url("${u}") center/cover;position:relative` }, h('button', { style: 'position:absolute;top:3px;right:3px;width:22px;height:22px;border-radius:50%;background:rgba(0,0,0,.6);color:#fff;display:grid;place-items:center', html: icon('x', 12), onclick: () => { v.images.splice(i, 1); drawImgs(); } })))); };
    const counter = h('div', { style: 'text-align:right;padding:0 20px;color:var(--fg2);font-size:13px' }, '0/' + max);
    pg.body.appendChild(h('div', { style: 'display:flex;gap:12px;padding:14px 16px' }, avatar(st.acct.display, 44, st.acct.avatar), h('textarea.note-ed', { style: 'padding:6px 0;min-height:110px;font-size:18px', placeholder: app === 'pulse' ? 'Quoi de neuf ?' : 'Ajoutez une légende…', maxlength: max, oninput: e => { v.body = e.target.value; counter.textContent = v.body.length + '/' + max; } })));
    pg.body.appendChild(counter); pg.body.appendChild(prev);
    const lim = (S.config.social && S.config.social.images) || 4;
    pg.body.appendChild(Group(null, [
      { icon: 'image', color: '#34c759', title: 'Photo de la galerie', chev: true, onclick: () => Messages.pickPhoto(u => { if (v.images.length < (app === 'snap' ? 1 : lim)) { v.images.push(u); drawImgs(); } else Toast('Limite atteinte', 'warning'); }) },
      { icon: 'link', color: 'var(--accent)', title: 'Image par lien', chev: true, onclick: async () => { const u = await Prompt('Lien de l\'image', null, { placeholder: 'https://…' }); if (u && /^https?:/.test(u)) { v.images.length < (app === 'snap' ? 1 : lim) ? v.images.push(u) : Toast('Limite atteinte', 'warning'); drawImgs(); } } },
      app === 'snap' ? { title: 'Publier en story (24 h)', toggle: { on: v.story, onchange: x => v.story = x } } : null,
    ]));
    st.ctx.push(pg); setTimeout(() => { const t = $('textarea', pg.body); t && t.focus(); }, 420);
    if (story) { /* focus sur photo */ }
    return pg;
  },
  async quickPost(app, url) {
    const acct = this.accts[app] || await rpc('acctGet', app);
    if (!acct) { Toast('Ouvrez l\'application pour créer un compte', 'info'); return; }
    this.accts[app] = acct;
    const cap = await Prompt('Légende', 'Publier sur ' + (app === 'pulse' ? 'Pulse' : 'Snapgram'), { placeholder: 'Légende (facultatif)' }); if (cap === null) return;
    const r = await rpc('post', app, { body: cap, images: [url], kind: 'post' });
    Toast(r ? 'Publié' : (rpc.err || 'Impossible'), r ? 'check' : 'warning');
  },
};
registerApp({ id: 'pulse', name: 'Pulse', icon: 'lightning', grad: ['#1d9bf0', '#0b5ea8'], dark: true, open: ctx => Social.open('pulse', ctx), onQuit: ctx => (ctx.state && ctx.state.unsub || []).forEach(f => f()) });
registerApp({ id: 'snap', name: 'Snapgram', icon: 'camera', grad: ['#f58529', '#dd2a7b'], dark: true, open: ctx => Social.open('snap', ctx), onQuit: ctx => (ctx.state && ctx.state.unsub || []).forEach(f => f()) });

/* ───────────── Match ───────────── */
const Match = {
  async open(ctx) {
    this.ctx = ctx; const me = await rpc('matchMe');
    if (!me) return this.profileForm(ctx, {}, true);
    this.shell(ctx, me);
  },
  profileForm(ctx, data, first) {
    const v = Object.assign({ name: S.me.name.split(' ')[0], age: 25, gender: 'autre', looking: 'tous', bio: '', photos: [] }, data);
    const pg = Page({ title: first ? 'Créer mon profil' : 'Mon profil', large: !first, modal: !first, left: first ? [] : [{ label: 'Annuler', onclick: () => ctx.pop() }], right: [{ label: 'OK', bold: true, onclick: async () => { const ok = await rpc('matchSave', v); if (!ok) { Toast(rpc.err || 'Profil invalide', 'warning'); return; } this.open(ctx); if (!first) ctx.pop(); } }] });
    const photos = h('div', { style: 'display:flex;gap:8px;flex-wrap:wrap;padding:0 16px 14px' });
    const drawP = () => { clear(photos); v.photos.forEach((u, i) => photos.appendChild(h('div', { style: `width:96px;height:128px;border-radius:12px;background:url("${u}") center/cover;position:relative` }, h('button', { style: 'position:absolute;top:3px;right:3px;width:22px;height:22px;border-radius:50%;background:rgba(0,0,0,.6);color:#fff', html: icon('x', 12), onclick: () => { v.photos.splice(i, 1); drawP(); } })))); if (v.photos.length < 5) photos.appendChild(h('button', { style: 'width:96px;height:128px;border-radius:12px;border:2px dashed var(--fg3);display:grid;place-items:center;color:var(--fg2)', html: icon('plus', 28), onclick: () => ActionSheet('Ajouter une photo', [{ label: 'Depuis la galerie', onclick: () => Messages.pickPhoto(u => { v.photos.push(u); drawP(); }) }, { label: 'Par lien', onclick: async () => { const u = await Prompt('Lien de la photo', null, { placeholder: 'https://…' }); if (u && /^https?:/.test(u)) { v.photos.push(u); drawP(); } } }]) })); };
    drawP();
    pg.body.appendChild(h('div', { style: 'padding:16px 20px 8px;color:var(--fg2)' }, 'Photos (1 à 5)')); pg.body.appendChild(photos);
    const sel = (k, opts) => h('select', { style: 'flex:1;text-align:right;font-size:17px;background:none;color:var(--fg)', onchange: e => v[k] = e.target.value }, opts.map(o => h('option', { value: o[0], selected: o[0] === v[k], style: 'color:#000' }, o[1])));
    pg.body.appendChild(Group(null, [{ label: 'Prénom', input: true, left: true, value: v.name, onInput: x => v.name = x }, { label: 'Âge', input: true, left: true, type: 'number', value: v.age, onInput: x => v.age = x }, { label: 'Je suis', el: sel('gender', [['homme', 'Un homme'], ['femme', 'Une femme'], ['autre', 'Autre']]) }, { label: 'Je cherche', el: sel('looking', [['tous', 'Tout le monde'], ['homme', 'Des hommes'], ['femme', 'Des femmes']]) }]));
    pg.body.appendChild(Group('À propos de moi', [{ input: true, multiline: true, left: true, rows: 4, maxlength: 250, value: v.bio, placeholder: 'Quelques mots…', onInput: x => v.bio = x }]));
    if (!first) pg.body.appendChild(Group(null, [{ title: 'Supprimer mon profil', danger: true, center: true, onclick: async () => { if (await Confirm('Supprimer le profil ?', 'Vos matchs seront perdus.', 'Supprimer', true)) { await rpc('matchDelete'); ctx.pop(); this.open(ctx); } } }]));
    first ? ctx.root(pg) : ctx.push(pg);
  },
  shell(ctx, me) {
    const holder = h('div', { style: 'position:absolute;inset:0' }); let tab = 'deck';
    const bar = TabBar([{ id: 'deck', label: 'Découvrir', icon: 'flame' }, { id: 'matches', label: 'Matchs', icon: 'heart' }, { id: 'me', label: 'Profil', icon: 'user' }], 'deck', id => { tab = id; draw(); });
    const wrap = Page({ noNav: true, nopad: true, tabbar: bar }); wrap.body.style.cssText = 'position:relative;overflow:hidden'; wrap.body.appendChild(holder); ctx.root(wrap);
    const draw = () => { clear(holder); const pg = this['tab_' + tab](ctx, me); holder.appendChild(pg.el); ctx.stack[0] = pg; pg.ctx = ctx; };
    draw();
  },
  tab_deck(ctx, me) {
    const pg = Page({ title: 'Match', large: false }); pg.el.style.background = '#111'; pg.el.classList.add('dark');
    const stack = h('div.deck'); pg.body.appendChild(stack); pg.body.appendChild(Spinner());
    rpc('matchDeck').then(deck => {
      $('.spinner', pg.body) && $('.spinner', pg.body).remove(); deck = deck || [];
      if (!deck.length) { stack.appendChild(Empty('flame', 'Plus personne autour de vous', 'Revenez plus tard pour de nouvelles rencontres.')); return; }
      const render = () => {
        clear(stack); const c = deck[0]; if (!c) { stack.appendChild(Empty('flame', 'Vous avez tout vu !', 'Revenez plus tard.')); return; }
        let pi = 0;
        const card = h('div.mcard', { style: `background-image:url("${c.photos[0]}")` }, h('div.mshade'), h('div.minfo', h('b', c.name + ', ' + c.age), c.bio ? h('p', c.bio) : null), h('div.mdots', c.photos.map((_, i) => h('i' + (i === 0 ? '.on' : '')))));
        card.addEventListener('click', e => { const r = card.getBoundingClientRect(); if (e.clientX > r.left + r.width / 2) pi = Math.min(c.photos.length - 1, pi + 1); else pi = Math.max(0, pi - 1); card.style.backgroundImage = `url("${c.photos[pi]}")`; $$('.mdots i', card).forEach((d, i) => d.classList.toggle('on', i === pi)); });
        const swipe = async (like) => { card.style.transition = 'transform .35s, opacity .35s'; card.style.transform = `translateX(${like ? 420 : -420}px) rotate(${like ? 20 : -20}deg)`; card.style.opacity = 0; const r = await rpc('matchSwipe', c.token, like); deck.shift(); setTimeout(render, 280); if (r && r.match) this.matchPopup(r); };
        stack.appendChild(card);
        stack.appendChild(h('div.mbtns', h('button.nope', { html: icon('x', 30), onclick: () => swipe(false) }), h('button.like', { html: icon('heartFill', 30), onclick: () => swipe(true) })));
      };
      render();
    });
    return pg;
  },
  matchPopup(r) {
    Sheet({ title: 'C\'est un match !', render: (b, close) => { b.appendChild(h('div', { style: 'text-align:center;padding:20px' }, h('div', { style: 'display:inline-block' }, avatar(r.name, 110, r.photo)), h('h2', { style: 'margin:14px 0 4px' }, 'Vous et ' + r.name), h('p', { style: 'color:var(--fg2)' }, 'Vous vous plaisez mutuellement.'), h('div', { style: 'display:flex;gap:10px;margin-top:18px' }, h('button.btn.sec', { style: 'flex:1', onclick: close }, 'Plus tard'), h('button.btn', { style: 'flex:1', onclick: () => { close(); Messages.openWith(r.number); } }, 'Écrire')))); } });
  },
  tab_matches(ctx) {
    const pg = Page({ title: 'Matchs' }); pg.body.appendChild(Spinner());
    rpc('matchList').then(l => { clear(pg.body); l = l || []; if (!l.length) { pg.body.appendChild(Empty('heart', 'Pas encore de match', 'Likez des profils pour commencer.')); return; } pg.body.appendChild(Group(null, l.map(m => ({ left: avatar(m.name, 52, m.photos[0]), title: m.name + ', ' + m.age, sub: m.bio, chev: true, onclick: () => m.number && Messages.openWith(m.number) })))); });
    return pg;
  },
  tab_me(ctx, me) {
    const pg = Page({ title: 'Mon profil', right: [{ label: 'Modifier', onclick: () => this.profileForm(ctx, me, false) }] });
    pg.body.appendChild(h('div', { style: 'text-align:center;padding:20px' }, h('div', { style: 'display:inline-block' }, avatar(me.name, 120, me.photos[0])), h('div', { style: 'font-size:26px;font-weight:700;margin-top:10px' }, me.name + ', ' + me.age), h('div', { style: 'color:var(--fg2);margin-top:6px' }, me.bio || '')));
    pg.body.appendChild(Group(null, [{ title: 'Profil visible', toggle: { on: true, onchange: () => Toast('Bientôt disponible', 'info') } }]));
    return pg;
  },
};
registerApp({ id: 'match', name: 'Match', icon: 'flame', grad: ['#ff6b6b', '#ee0979'], dark: true, open: ctx => Match.open(ctx) });
