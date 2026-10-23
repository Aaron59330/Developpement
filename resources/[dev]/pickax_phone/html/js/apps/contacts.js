/* ═══════════ Contacts ═══════════ */
const Contacts = {
  ctxFor(ctx) {
    if (ctx) return ctx;
    if (OS.current) return OS.current.ctx;
    OS.openApp('contacts'); return OS.running.contacts && OS.running.contacts.ctx;
  },
  async open(ctx) {
    await Core.reloadContacts();
    const pg = Page({ title: 'Contacts', right: [{ icon: 'plus', onclick: () => this.edit({}, ctx) }] });
    pg.body.appendChild(SearchBar({ placeholder: 'Rechercher', onInput: q => draw(q) }));
    const me = S.me;
    pg.body.appendChild(Group(null, [{ left: avatar(me.name, 56), title: h('b', { style: 'font-size:20px;font-weight:600' }, me.name), titleHtml: false, sub: 'Ma carte · ' + fmtNum(me.number), onclick: () => this.myCard(ctx) }]));
    const list = h('div'); pg.body.appendChild(list);
    const draw = (q) => {
      clear(list); q = (q || '').toLowerCase().trim();
      const cs = S.contactList.filter(c => !q || c.name.toLowerCase().includes(q) || c.number.includes(q) || (c.email || '').toLowerCase().includes(q));
      if (!cs.length) { list.appendChild(Empty('users', q ? 'Aucun résultat' : 'Aucun contact', q ? null : 'Touchez + pour ajouter votre premier contact.')); return; }
      const groups = {};
      cs.forEach(c => { const l = (c.name[0] || '#').toUpperCase().replace(/[^A-Z]/, '#'); (groups[l] = groups[l] || []).push(c); });
      Object.keys(groups).sort().forEach(l => list.appendChild(Group(l, groups[l].map(c => ({ left: avatar(c.name, 34, c.avatar), title: c.name, sub: c.blocked ? 'Bloqué' : null, onclick: () => this.card(c, ctx) })))));
      list.appendChild(h('div', { style: 'text-align:center;color:var(--fg2);font-size:15px;padding:6px 0 30px' }, cs.length + ' contact' + (cs.length > 1 ? 's' : '')));
    };
    draw('');
    ctx.root(pg);
    Bus.on('contacts', () => { if (ctx.alive && ctx.stack[0] === pg) draw(''); });
  },
  myCard(ctx) {
    ctx = this.ctxFor(ctx); const me = S.me;
    const pg = Page({ title: 'Ma carte', back: 'Contacts', large: false });
    pg.body.appendChild(h('div', { style: 'text-align:center;padding:20px 0 14px' }, h('div', { style: 'display:inline-block' }, avatar(me.name, 110)), h('div', { style: 'font-size:26px;font-weight:600;margin-top:10px' }, me.name), h('div', { style: 'color:var(--fg2)' }, me.jobLabel || '')));
    pg.body.appendChild(Group(null, [{ title: 'téléphone', sub: fmtNum(me.number), onclick: () => this.copy(fmtNum(me.number)) }, { title: 'e-mail', sub: me.mail, onclick: () => this.copy(me.mail) }]));
    pg.body.appendChild(Group(null, [{ icon: 'share', color: 'var(--accent)', title: 'Partager mon contact', onclick: () => Messages.shareContact({ name: me.name, number: me.number }) }]));
    ctx.push(pg);
  },
  copy(t) { Toast('Copié : ' + t, 'copy'); post('copy', { text: t }); try { navigator.clipboard && navigator.clipboard.writeText(t); } catch (e) {} },

  card(c, ctx) {
    ctx = this.ctxFor(ctx);
    const pg = Page({ title: c.name, back: 'Contacts', large: false, right: [{ label: 'Modifier', onclick: () => this.edit(c, ctx) }] });
    const act = (ic, label, fn, dis) => h('div', { style: 'flex:1;text-align:center' }, h('button', { style: 'width:100%;height:60px;border-radius:12px;background:var(--card);display:flex;flex-direction:column;align-items:center;justify-content:center;gap:2px;color:var(--accent);font-size:11px;' + (dis ? 'opacity:.4;pointer-events:none' : ''), onclick: fn }, h('span', { html: icon(ic, 22) }), label));
    pg.body.appendChild(h('div', { style: 'text-align:center;padding:14px 0' }, h('div', { style: 'display:inline-block' }, avatar(c.name, 110, c.avatar)), h('div', { style: 'font-size:26px;font-weight:600;margin-top:10px' }, c.name)));
    pg.body.appendChild(h('div', { style: 'display:flex;gap:8px;padding:0 16px 18px' }, act('message', 'message', () => Messages.openWith(c.number)), act('phone', 'appeler', () => Calls.dial(c.number)), act('mail', 'mail', () => Mail.compose(c.email), !c.email), act('share', 'partager', () => Messages.shareContact(c))));
    pg.body.appendChild(Group(null, [{ title: 'téléphone', sub: fmtNum(c.number), onclick: () => Calls.dial(c.number) }, c.email ? { title: 'e-mail', sub: c.email, onclick: () => this.copy(c.email) } : null, c.note ? { title: 'note', sub: c.note } : null]));
    pg.body.appendChild(Group(null, [
      { title: c.favorite ? 'Retirer des favoris' : 'Ajouter aux favoris', accent: true, onclick: async () => { await rpc('contactFlag', c.id, 'favorite', !c.favorite); await Core.reloadContacts(); ctx.pop(); Toast(c.favorite ? 'Retiré des favoris' : 'Ajouté aux favoris', 'star'); } },
      { title: 'Partager via AirShare', accent: true, onclick: () => AirShare.send('contact', { name: c.name, number: c.number }) },
      { title: 'Envoyer ma position', accent: true, onclick: () => Messages.sendLocation(c.number) },
      { title: c.blocked ? 'Débloquer ce contact' : 'Bloquer ce contact', danger: !c.blocked, accent: c.blocked, onclick: async () => { await rpc('contactFlag', c.id, 'blocked', !c.blocked); await Core.reloadContacts(); ctx.pop(); } },
    ]));
    pg.body.appendChild(Group(null, [{ title: 'Supprimer le contact', danger: true, onclick: async () => { if (await Confirm('Supprimer ' + c.name + ' ?', null, 'Supprimer', true)) { await rpc('contactDelete', c.id); await Core.reloadContacts(); ctx.pop(); } } }]));
    ctx.push(pg);
  },

  edit(c, ctx) {
    ctx = this.ctxFor(ctx);
    const isNew = !c.id;
    const val = { name: c.name || '', number: c.number || '', email: c.email || '', avatar: c.avatar || '', note: c.note || '' };
    const pg = Page({ title: isNew ? 'Nouveau contact' : 'Modifier', large: false, modal: true, left: [{ label: 'Annuler', onclick: () => ctx.pop() }], right: [{ label: 'OK', bold: true, onclick: save }] });
    const prev = h('div', { style: 'text-align:center;padding:16px 0 6px' });
    const drawPrev = () => { clear(prev); prev.appendChild(h('div', { style: 'display:inline-block' }, avatar(val.name || '?', 90, val.avatar))); };
    drawPrev();
    pg.body.appendChild(prev);
    const inp = (label, k, ph, type) => ({ label, input: true, left: true, placeholder: ph, value: val[k], type: type || 'text', onInput: v => { val[k] = v; if (k === 'name' || k === 'avatar') drawPrev(); } });
    pg.body.appendChild(Group(null, [inp('Nom', 'name', 'Nom complet'), inp('Téléphone', 'number', NUM_EXAMPLE(), 'tel'), inp('E-mail', 'email', 'adresse@' + ((S.config && S.config.mailDomain) || 'aero.mail') + ''), inp('Photo', 'avatar', 'Lien d\'image (https://…)'), inp('Note', 'note', 'Note')]));
    async function save() {
      if (!val.name.trim() || !val.number.replace(/\D/g, '')) { Toast('Nom et numéro requis', 'warning'); return; }
      const r = await rpc('contactSave', Object.assign({}, c, val, { id: c.id }));
      if (!r) { Toast(rpc.err || 'Erreur', 'warning'); return; }
      await Core.reloadContacts(); ctx.pop(); if (!isNew && ctx.stack.length > 1) ctx.pop();
    }
    if (isNew && !c.name) setTimeout(() => { const f = $('input', pg.body); f && f.focus(); }, 380);
    ctx.push(pg);
  },
};
registerApp({ id: 'contacts', name: 'Contacts', icon: 'user', grad: ['#a3a8b3', '#6b7280'], open: ctx => Contacts.open(ctx) });
