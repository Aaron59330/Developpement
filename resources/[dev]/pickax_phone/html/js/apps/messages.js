/* ═══════════ Messages ═══════════ */
const EMOJIS = ['❤️', '👍', '👎', '😂', '😮', '😢', '🔥', '🙏'];
const EMOJI_PICK = '😀😁😂🤣😊😍😘😎🤔😅😭😡🥳😴🤯🙄😇🤝👍👎👏🙏💪🔥❤️💔🎉✨💯🚗🔫💰🍕🍺'.match(/(\p{Extended_Pictographic}️?(‍\p{Extended_Pictographic}️?)*)/gu) || [];

const Messages = {
  ctx: null, convs: [], unread: 0, listPg: null, open: null,

  async load() { this.convs = (await rpc('convList')) || []; this.updateBadge(); Bus.emit('convs'); },
  updateBadge() { this.unread = this.convs.reduce((a, c) => a + (c.unread || 0), 0); OS.setBadge('messages', this.unread); },
  title(c) { return c.kind === 'group' ? (c.name || 'Groupe') : contactName(c.other); },
  preview(c) {
    const m = c.last; if (!m) return 'Aucun message';
    const mine = m.sender === S.me.number;
    const who = c.kind === 'group' && !mine ? contactName(m.sender).split(' ')[0] + ' : ' : (mine ? 'Vous : ' : '');
    if (m.kind === 'image') return who + '📷 Photo'; if (m.kind === 'location') return who + '📍 Position'; if (m.kind === 'contact') return who + '👤 Contact';
    return who + (m.body || '');
  },
  convAvatar(c, size) {
    if (c.kind === 'group') return h('div.avatar', { style: `width:${size}px;height:${size}px;background:linear-gradient(160deg,#9aa0a6,#6b7280)`, html: icon('users', size * .5) });
    const ct = contactOf(c.other); return avatar(contactName(c.other), size, ct && ct.avatar);
  },

  async openApp(ctx) {
    this.ctx = ctx;
    const pg = Page({ title: 'Messages', left: [{ label: 'Modifier', onclick: () => this.editMode() }], right: [{ icon: 'edit', onclick: () => this.compose() }] });
    this.listPg = pg;
    pg.body.appendChild(Spinner());
    ctx.root(pg);
    await this.load(); this.draw();
    Bus.on('convs', () => { if (ctx.alive && this.listPg) this.draw(); });
  },
  editMode() { Toast('Appui long sur une conversation pour les options', 'info'); },
  draw() {
    const pg = this.listPg; if (!pg) return;
    clear(pg.body);
    pg.body.appendChild(SearchBar({ onInput: q => this.drawList(q) }));
    this.listEl = h('div'); pg.body.appendChild(this.listEl); this.drawList('');
  },
  drawList(q) {
    const list = this.listEl; clear(list); q = (q || '').toLowerCase();
    const cs = this.convs.filter(c => !q || this.title(c).toLowerCase().includes(q) || (c.last && (c.last.body || '').toLowerCase().includes(q)));
    if (!cs.length) { list.appendChild(Empty('message', q ? 'Aucun résultat' : 'Aucune conversation', q ? null : 'Touchez le crayon pour écrire un message.')); return; }
    list.appendChild(h('div.group', h('div.rows', cs.map(c => {
      const el = Row({
        left: h('div', { style: 'display:flex;align-items:center;gap:8px' }, h('div', { style: 'width:10px;display:flex;justify-content:center' }, c.unread ? h('div', { style: 'width:10px;height:10px;border-radius:50%;background:var(--accent)' }) : null), this.convAvatar(c, 48)),
        title: h('div', { style: 'display:flex;justify-content:space-between;gap:8px' }, h('span', { style: 'font-weight:' + (c.unread ? 600 : 500) + ';overflow:hidden;text-overflow:ellipsis;white-space:nowrap' }, (c.pinned ? '📌 ' : '') + this.title(c)), h('span', { style: 'font-size:14px;color:var(--fg2);font-weight:400;flex:none' }, c.last ? fmtDay(c.last.created) : '')),
        sub: this.preview(c), onclick: () => this.openConv(c), onlong: () => this.convMenu(c),
      });
      $('small', el).style.cssText += ';white-space:normal;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden';
      $('.main', el).style.padding = '10px 0';
      return el;
    }))));
  },
  convMenu(c) {
    ActionSheet(this.title(c), [
      { label: c.pinned ? 'Désépingler' : 'Épingler', onclick: async () => { await rpc('convSet', c.id, { pinned: !c.pinned }); await this.load(); } },
      { label: c.muted ? 'Réactiver les alertes' : 'Masquer les alertes', onclick: async () => { await rpc('convSet', c.id, { muted: !c.muted }); await this.load(); } },
      { label: 'Supprimer', red: true, onclick: async () => { await rpc('convClear', c.id); await this.load(); } },
    ]);
  },

  /* ───── nouveau message ───── */
  async compose(prefill) {
    const ctx = this.ctx || (OS.running.messages && OS.running.messages.ctx);
    const to = new Set(prefill ? [prefill] : []);
    const chips = h('div', { style: 'display:flex;flex-wrap:wrap;gap:6px;padding:10px 16px;min-height:44px;align-items:center' });
    const drawChips = () => { clear(chips); chips.appendChild(h('span', { style: 'color:var(--fg2)' }, 'À :')); [...to].forEach(n => chips.appendChild(h('span.chip', { style: 'background:var(--accent);color:#fff', onclick: () => { to.delete(n); drawChips(); } }, contactName(n), ' ✕'))); chips.appendChild(inp); };
    const inp = h('input', { placeholder: 'Nom ou numéro', style: 'flex:1;min-width:100px;font-size:17px', onkeydown: e => { if (e.key === 'Enter' && inp.value.replace(/\D/g, '').length >= 3) { to.add(inp.value.replace(/\D/g, '')); inp.value = ''; drawChips(); inp.focus(); } } });
    const pg = Page({ title: 'Nouveau message', large: false, modal: true, left: [{ label: 'Annuler', onclick: () => ctx.pop() }], right: [{ label: 'Suivant', bold: true, onclick: next }] });
    pg.body.appendChild(chips); drawChips();
    pg.body.appendChild(h('div', { style: 'padding:6px 16px;color:var(--fg2);font-size:13px;text-transform:uppercase' }, 'Contacts'));
    pg.body.appendChild(Group(null, S.contactList.map(c => ({ left: avatar(c.name, 34, c.avatar), title: c.name, sub: fmtNum(c.number), onclick: () => { to.add(c.number); drawChips(); } }))));
    async function next() {
      if (inp.value.replace(/\D/g, '').length >= 3) { to.add(inp.value.replace(/\D/g, '')); inp.value = ''; }
      const nums = [...to]; if (!nums.length) { Toast('Choisissez un destinataire', 'warning'); return; }
      if (nums.length === 1) { ctx.pop(); Messages.openWith(nums[0]); return; }
      if ((S.config.limits || {}).groups === false) { Toast('Les groupes sont désactivés', 'warning'); return; }
      const name = await Prompt('Nom du groupe', null, { placeholder: 'Groupe' }); if (name === null) return;
      const cid = await rpc('groupCreate', name || 'Groupe', nums);
      if (!cid) { Toast(rpc.err || 'Impossible de créer le groupe', 'warning'); return; }
      ctx.pop(); await Messages.load(); const c = Messages.convs.find(x => x.id === cid); c && Messages.openConv(c);
    }
    ctx.push(pg);
    setTimeout(() => inp.focus(), 420);
  },

  async openWith(number) {
    number = String(number).replace(/\D/g, '');
    if (!OS.running.messages || OS.current !== OS.running.messages) OS.openApp('messages');
    await sleep(60);
    if (!this.ctx) this.ctx = OS.running.messages && OS.running.messages.ctx;
    await this.load();
    let c = this.convs.find(x => x.kind === 'direct' && x.other === number);
    if (!c) { c = { id: null, kind: 'direct', other: number, members: [S.me.number, number], unread: 0 }; }
    this.openConv(c);
  },

  /* ───── conversation ───── */
  async openConv(c) {
    const ctx = this.ctx || (OS.running.messages && OS.running.messages.ctx);
    if (!ctx) return;
    const state = { c, msgs: [], typing: null, reply: null, loadingOld: false, done: false };
    const title = () => this.title(c);
    const pg = Page({
      title: title(), large: false, back: 'Messages',
      right: [{ icon: 'info', onclick: () => this.info(c, state, pg) }],
      onClose: () => { this.open = null; unsub.forEach(f => f()); this.load(); },
    });
    pg.nav.classList.add('conv-nav');
    $('.t', pg.nav).style.opacity = 1;
    pg.body.classList.add('nopad'); pg.body.style.cssText = 'display:flex;flex-direction:column;overflow:hidden';
    const scroll = h('div.conv-scroll'); const typingEl = h('div.typing.hidden', h('i'), h('i'), h('i'));
    const replyBar = h('div.replybar.hidden');
    const input = h('textarea', { rows: 1, placeholder: 'Message', maxlength: Config_maxMsg() });
    const sendBtn = h('button.sendbtn.hidden', { html: icon('send', 18), onclick: send });
    const attach = h('button.attachbtn', { html: icon('plus', 22), onclick: () => attachMenu() });
    const bar = h('div.inputbar', attach, h('div.inputwrap', input, sendBtn));
    pg.body.appendChild(scroll); pg.body.appendChild(replyBar); pg.body.appendChild(bar);
    scroll.appendChild(typingEl);
    ctx.push(pg); this.open = state;
    let lastTypingSent = 0;
    input.addEventListener('input', () => { input.style.height = 'auto'; input.style.height = Math.min(110, input.scrollHeight) + 'px'; sendBtn.classList.toggle('hidden', !input.value.trim()); if (c.id && Date.now() - lastTypingSent > 2500) { lastTypingSent = Date.now(); post('msgTyping', { conv: c.id }); } });
    input.addEventListener('keydown', e => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); send(); } });

    const kids = () => $$('.mrow', scroll);
    const renderAll = () => { $$('.mrow,.dsep', scroll).forEach(x => x.remove()); let last = null; state.msgs.forEach((m, i) => { const d = new Date(m.created); if (!last || !sameDay(last, d)) { scroll.insertBefore(h('div.dsep', fmtLong(m.created)), typingEl); last = d; } scroll.insertBefore(this.bubble(m, c, state, pg), typingEl); }); };
    const toBottom = () => { scroll.scrollTop = scroll.scrollHeight; };
    if (c.id) { state.msgs = (await rpc('msgHistory', c.id)) || []; renderAll(); toBottom(); await rpc('msgRead', c.id); c.unread = 0; this.updateBadge(); }
    else scroll.insertBefore(h('div.dsep', 'Nouvelle conversation'), typingEl);
    scroll.addEventListener('scroll', async () => {
      if (scroll.scrollTop < 40 && !state.loadingOld && !state.done && state.msgs.length >= 40 && c.id) {
        state.loadingOld = true; const old = (await rpc('msgHistory', c.id, state.msgs[0].id)) || []; state.loadingOld = false;
        if (!old.length) { state.done = true; return; }
        const h0 = scroll.scrollHeight; state.msgs = old.concat(state.msgs); renderAll(); scroll.scrollTop = scroll.scrollHeight - h0;
      }
    });

    async function send(extra) {
      const body = typeof extra === 'object' && extra.kind ? extra.body : input.value.trim();
      const kind = typeof extra === 'object' && extra.kind ? extra.kind : 'text';
      if (kind === 'text' && !body) return;
      const payload = { kind, body, meta: extra && extra.meta, replyTo: state.reply && state.reply.id };
      if (c.id) payload.conv = c.id; else payload.to = c.other;
      if (kind === 'text') { input.value = ''; input.style.height = 'auto'; sendBtn.classList.add('hidden'); }
      state.reply = null; replyBar.classList.add('hidden');
      const r = await rpc('msgSend', payload);
      if (!r || !r.ok) { Toast((r && r.error) || rpc.err || 'Message non envoyé', 'warning'); return; }
      if (!c.id) { c.id = r.conv; }
    }
    const LIM = S.config.limits || {};
    const attachMenu = () => ActionSheet('Joindre', [
      LIM.messageImages === false ? null : { label: '📷  Photo de la galerie', onclick: () => Messages.pickPhoto(url => send({ kind: 'image', body: url })) },
      LIM.messageImages === false ? null : { label: '🔗  Image par lien', onclick: async () => { const u = await Prompt('Lien de l\'image', null, { placeholder: 'https://…' }); if (u && /^https?:/.test(u)) send({ kind: 'image', body: u }); } },
      LIM.messageLocation === false ? null : { label: '📍  Ma position', onclick: async () => { const p = await post('position'); if (p) send({ kind: 'location', body: 'Position', meta: { x: p.x, y: p.y, label: p.street || 'Position' } }); } },
      { label: '👤  Un contact', onclick: async () => { const k = await pickContact(); if (k) send({ kind: 'contact', body: k.name, meta: { name: k.name, number: k.number } }); } },
      { label: '😀  Emoji', onclick: () => { Sheet({ title: 'Emoji', render: (b, close) => { const g = h('div', { style: 'display:grid;grid-template-columns:repeat(7,1fr);gap:4px;padding:10px 16px;font-size:28px;text-align:center' }, EMOJI_PICK.map(e => h('div', { style: 'cursor:pointer', onclick: () => { input.value += e; sendBtn.classList.remove('hidden'); close(); input.focus(); } }, e))); b.appendChild(g); } }); } },
    ]);
    state.send = send; state.renderAll = renderAll; state.toBottom = toBottom; state.scroll = scroll; state.typingEl = typingEl;
    state.setReply = (m) => { state.reply = m; clear(replyBar); replyBar.classList.remove('hidden'); replyBar.appendChild(h('div', { style: 'flex:1;min-width:0' }, h('b', 'Réponse à ' + (m.sender === S.me.number ? 'vous-même' : contactName(m.sender))), h('div', { style: 'white-space:nowrap;overflow:hidden;text-overflow:ellipsis;color:var(--fg2)' }, m.kind === 'text' ? m.body : '📎 ' + m.kind))); replyBar.appendChild(h('button', { html: icon('x', 18), onclick: () => { state.reply = null; replyBar.classList.add('hidden'); } })); input.focus(); };

    const unsub = [];
    unsub.push(Bus.on('push:message', async d => {
      if (d.conv !== c.id) return;
      state.msgs.push(d.msg); const d0 = new Date(d.msg.created); const prev = state.msgs[state.msgs.length - 2];
      if (!prev || !sameDay(new Date(prev.created), d0)) scroll.insertBefore(h('div.dsep', fmtLong(d.msg.created)), typingEl);
      scroll.insertBefore(this.bubble(d.msg, c, state, pg), typingEl); typingEl.classList.add('hidden'); toBottom(); rpc('msgRead', c.id);
    }));
    unsub.push(Bus.on('push:messageSent', d => {
      if (d.conv !== c.id || state.msgs.find(m => m.id === d.msg.id)) return;
      state.msgs.push(d.msg); const prev = state.msgs[state.msgs.length - 2];
      if (!prev || !sameDay(new Date(prev.created), new Date(d.msg.created))) scroll.insertBefore(h('div.dsep', fmtLong(d.msg.created)), typingEl);
      scroll.insertBefore(this.bubble(d.msg, c, state, pg), typingEl); toBottom();
    }));
    unsub.push(Bus.on('push:messageDeleted', d => { if (d.conv !== c.id) return; state.msgs = state.msgs.filter(m => m.id !== d.id); renderAll(); }));
    unsub.push(Bus.on('push:messageReact', d => { if (d.conv !== c.id) return; const m = state.msgs.find(x => x.id === d.id); if (m) { m.reactions = d.reactions; renderAll(); } }));
    unsub.push(Bus.on('push:messageRead', d => { if (d.conv !== c.id) return; state.readAt = d.at; $$('.mrow.me .status', scroll).forEach(s => { s.textContent = 'Lu'; }); }));
    unsub.push(Bus.on('push:typing', d => { if (d.conv !== c.id) return; typingEl.classList.remove('hidden'); toBottom(); clearTimeout(state.tt); state.tt = setTimeout(() => typingEl.classList.add('hidden'), 3500); }));
    setTimeout(() => input.focus(), 450);
  },

  bubble(m, c, state, pg) {
    const mine = m.sender === S.me.number;
    const row = h('div.mrow' + (mine ? '.me' : ''));
    if (c.kind === 'group' && !mine) row.appendChild(h('div.who', contactName(m.sender)));
    let inner;
    if (m.kind === 'image') inner = h('div.mb.img', h('img', { src: m.body, draggable: false, onclick: () => viewImage(m.body, [{ icon: 'download', onclick: async (cl) => { const r = await rpc('photoAdd', m.body, 'photo'); Toast(r ? 'Ajoutée à Photos' : 'Impossible', 'image'); } }]) }));
    else if (m.kind === 'location') inner = h('div.mb.loc', { onclick: () => { post('waypoint', m.meta); Toast('Position ajoutée au GPS', 'pin'); } }, h('div.mapthumb', { html: icon('pin', 34) }), h('div', { style: 'padding:8px 12px' }, h('b', (m.meta && m.meta.label) || 'Position'), h('div', { style: 'font-size:13px;opacity:.8' }, 'Appuyez pour naviguer')));
    else if (m.kind === 'contact') inner = h('div.mb.card', { onclick: () => { const ex = contactOf(m.meta.number); ex ? Contacts.card(ex) : Contacts.edit({ name: m.meta.name, number: m.meta.number }); } }, avatar(m.meta.name, 40), h('div', h('b', m.meta.name), h('div', { style: 'font-size:13px;opacity:.8' }, fmtNum(m.meta.number))));
    else inner = h('div.mb', { html: linkify(m.body) });
    const bubble = h('div.mcol', inner);
    if (m.reply_to) { const q = state.msgs.find(x => x.id === m.reply_to); if (q) bubble.insertBefore(h('div.quote', h('b', q.sender === S.me.number ? 'Vous' : contactName(q.sender)), h('div', q.kind === 'text' ? q.body : '📎 ' + q.kind)), inner); }
    const rx = Object.values(m.reactions || {});
    if (rx.length) { const cnt = {}; rx.forEach(e => cnt[e] = (cnt[e] || 0) + 1); bubble.appendChild(h('div.reacts', Object.entries(cnt).map(([e, n]) => h('span', e + (n > 1 ? n : ''))))); }
    row.appendChild(bubble);
    const last = state.msgs[state.msgs.length - 1];
    row.appendChild(h('div.time', fmtTime(m.created)));
    if (mine && last && last.id === m.id) row.appendChild(h('div.status', state.readAt && state.readAt >= m.created ? 'Lu' : 'Distribué'));
    row.addEventListener('contextmenu', (e) => { e.preventDefault(); this.msgMenu(m, mine, state, c); });
    row.addEventListener('dblclick', () => rpc('msgReact', m.id, '❤️'));
    return row;
  },
  msgMenu(m, mine, state, c) {
    const grp = [
      { label: 'Répondre', onclick: () => state.setReply(m) },
      m.kind === 'text' ? { label: 'Copier', onclick: () => Contacts.copy(m.body) } : null,
      m.kind === 'image' ? { label: 'Enregistrer dans Photos', onclick: async () => { const r = await rpc('photoAdd', m.body, 'photo'); Toast(r ? 'Enregistrée' : 'Impossible', 'image'); } } : null,
      mine ? { label: 'Supprimer', red: true, onclick: () => rpc('msgDelete', m.id) } : null,
    ];
    const bar = h('div', { style: 'display:flex;justify-content:space-around;padding:12px 8px;border-bottom:.5px solid var(--sep)' }, EMOJIS.map(e => h('span', { style: 'font-size:26px;cursor:pointer', onclick: () => { cl(); rpc('msgReact', m.id, e); } }, e)));
    const cl = ActionSheet(null, grp);
    const head = $('.actions .grp'); if (head) head.insertBefore(bar, head.firstChild);
  },

  info(c, state, pg) {
    const ctx = this.ctx;
    const p = Page({ title: 'Détails', large: false, back: this.title(c) });
    p.body.appendChild(h('div', { style: 'text-align:center;padding:18px 0 10px' }, h('div', { style: 'display:inline-block' }, this.convAvatar(c, 90)), h('div', { style: 'font-size:24px;font-weight:600;margin-top:8px' }, this.title(c))));
    if (c.kind === 'direct') {
      const k = contactOf(c.other);
      p.body.appendChild(Group(null, [{ icon: 'phone', color: '#30d158', title: 'Appeler', sub: fmtNum(c.other), onclick: () => Calls.dial(c.other) }, { icon: 'user', color: '#8e8e93', title: k ? 'Voir le contact' : 'Ajouter aux contacts', onclick: () => k ? Contacts.card(k, ctx) : Contacts.edit({ number: c.other }, ctx) }]));
    } else {
      const mem = (c.members || []).map(n => ({ left: avatar(contactName(n), 34), title: n === S.me.number ? 'Vous' : contactName(n), sub: fmtNum(n) }));
      p.body.appendChild(Group('Membres (' + mem.length + ')', mem));
      p.body.appendChild(Group(null, [
        { title: 'Renommer le groupe', accent: true, onclick: async () => { const n = await Prompt('Nom du groupe', null, { value: c.name }); if (n) { await rpc('groupEdit', c.id, { name: n }); c.name = n; p.setTitle('Détails'); await this.load(); } } },
        { title: 'Ajouter des membres', accent: true, onclick: async () => { const l = await pickContact({ multi: true, title: 'Ajouter' }); if (l && l.length) { await rpc('groupEdit', c.id, { add: l }); await this.load(); Toast('Membres ajoutés', 'users'); } } },
        { title: 'Quitter la conversation', danger: true, onclick: async () => { if (await Confirm('Quitter ce groupe ?', null, 'Quitter', true)) { await rpc('groupEdit', c.id, { leave: true }); await this.load(); ctx.pop(); ctx.pop(); } } },
      ]));
    }
    p.body.appendChild(Group(null, [{ title: 'Masquer les alertes', toggle: { on: !!c.muted, onchange: async v => { c.muted = v ? 1 : 0; await rpc('convSet', c.id, { muted: v }); } } }, { title: 'Envoyer ma position', accent: true, onclick: () => state.send({ kind: 'location', body: 'Position', meta: null }) }]));
    // galerie des photos échangées
    const imgs = state.msgs.filter(m => m.kind === 'image');
    if (imgs.length) p.body.appendChild(h('div.group', h('h6', 'Photos'), h('div', { style: 'display:grid;grid-template-columns:repeat(3,1fr);gap:3px' }, imgs.slice(-12).map(m => h('div', { style: `aspect-ratio:1;background:url("${m.body}") center/cover;border-radius:6px`, onclick: () => viewImage(m.body) })))));
    ctx.push(p);
  },

  pickPhoto(cb) {
    Sheet({ title: 'Photos', full: true, render: async (body, close) => {
      body.appendChild(Spinner());
      const ph = (await rpc('photos')) || []; clear(body);
      if (!ph.length) { body.appendChild(Empty('image', 'Aucune photo', 'Prenez des photos avec l\'appareil photo.')); return; }
      body.appendChild(h('div', { style: 'display:grid;grid-template-columns:repeat(3,1fr);gap:2px;padding:2px' }, ph.map(p => h('div', { style: `aspect-ratio:1;background:url("${p.url}") center/cover;cursor:pointer`, onclick: () => { close(); cb(p.url); } }))));
    } });
  },
  async shareContact(c) {
    const n = await pickContactNumber(); if (!n) return;
    const r = await rpc('msgSend', { to: n, kind: 'contact', body: c.name, meta: { name: c.name, number: c.number } });
    Toast(r && r.ok ? 'Contact envoyé' : 'Échec de l\'envoi', 'user');
  },
  async sendLocation(number) {
    const p = await post('position'); if (!p) return;
    const r = await rpc('msgSend', { to: number, kind: 'location', body: 'Position', meta: { x: p.x, y: p.y, label: p.street || 'Position' } });
    Toast(r && r.ok ? 'Position envoyée' : 'Échec de l\'envoi', 'pin');
  },
};
function Config_maxMsg() { return (S.config.messages && S.config.messages.maxLength) || 1000; }
async function pickContactNumber() { const c = await pickContact({ title: 'Envoyer à' }); return c && c.number; }

/* notifications de messages */
Bus.on('push:message', async d => {
  const open = Messages.open && Messages.open.c.id === d.conv && S.open && !S.locked && OS.current && OS.current.id === 'messages';
  const known = Messages.convs.find(c => c.id === d.conv);
  if (open) return;
  await Messages.load();
  if (d.silent || d.muted) return;
  const m = d.msg; const c = Messages.convs.find(x => x.id === d.conv);
  const title = c && c.kind === 'group' ? (c.name || 'Groupe') : contactName(m.sender);
  const body = (c && c.kind === 'group' ? contactName(m.sender).split(' ')[0] + ' : ' : '') + (m.kind === 'image' ? '📷 Photo' : m.kind === 'location' ? '📍 Position' : m.kind === 'contact' ? '👤 Contact' : m.body);
  OS.notify({ app: 'messages', title, body: S.settings.previews === false ? 'Nouveau message' : body, icon: 'message', onTap: () => { if (c) { OS.openApp('messages'); setTimeout(() => Messages.openConv(c), 120); } else OS.openApp('messages'); },
    actions: S.open && !S.locked ? null : null });
});
Bus.on('push:convUpdate', () => Messages.load());
registerApp({ id: 'messages', name: 'Messages', icon: 'message', grad: ['#5cf26b', '#1db954'], open: ctx => Messages.openApp(ctx) });
