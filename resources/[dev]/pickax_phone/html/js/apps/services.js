/* ═══════════ Services : tous les métiers du serveur, joignables par appel ou par alerte ═══════════ */
const TYPE_GROUP = { police: 'Urgences', ems: 'Urgences', mecano: 'Dépannage & transport', taxi: 'Dépannage & transport', dealer: 'Commerces & services', realestate: 'Commerces & services', bar: 'Commerces & services', bank: 'Administration', government: 'Administration' };
const Services = {
  hist: [], lines: [],
  async open(ctx) {
    this.ctx = ctx;
    const pg = Page({ title: 'Services', right: [{ icon: 'search', onclick: () => { const s = $('input', pg.body); s && s.focus(); } }] }); this.pg = pg; ctx.root(pg);
    await this.draw();
  },
  async load() {
    this.lines = (await rpc('serviceLines')) || [];
    S.lines = this.lines.map(l => Object.assign({}, l, { key: l.number || ('srv-' + l.id).slice(0, 20) }));
  },
  async draw(q) {
    const pg = this.pg;
    if (!this.lines.length || q === undefined) { clear(pg.body); pg.body.appendChild(Spinner()); await this.load(); }
    clear(pg.body);
    const search = SearchBar({ placeholder: 'Rechercher un service', value: q || '', onInput: v => this.list(v) });
    pg.body.appendChild(search);
    pg.body.appendChild(h('div', { style: 'padding:0 20px 12px;color:var(--fg2);font-size:14px;line-height:1.4' }, 'Appelez un métier du serveur ou envoyez-lui une alerte : votre position est transmise automatiquement aux employés en service.'));
    this.wrap = h('div'); pg.body.appendChild(this.wrap); this.list(q || '');
    if (this.hist.length) pg.body.appendChild(Group('Alertes envoyées', this.hist.slice(0, 6).map(x => ({ title: x.label, sub: ago(x.at) + ' · ' + x.msg.slice(0, 40) }))));
  },
  list(q) {
    const wrap = this.wrap; clear(wrap); q = (q || '').toLowerCase();
    const lines = this.lines.filter(l => !q || l.label.toLowerCase().includes(q) || (l.number || '').includes(q));
    if (!lines.length) { wrap.appendChild(Empty('warning', q ? 'Aucun résultat' : 'Aucun service', q ? null : 'Aucun métier n\'est joignable pour le moment.')); return; }
    const groups = {};
    lines.forEach(l => { const g = TYPE_GROUP[l.type] || 'Autres services'; (groups[g] = groups[g] || []).push(l); });
    const order = ['Urgences', 'Dépannage & transport', 'Commerces & services', 'Administration', 'Autres services'];
    order.filter(g => groups[g]).forEach(g => wrap.appendChild(Group(g, groups[g].map(l => ({
      icon: l.icon, color: l.color, title: l.label,
      sub: (l.online ? l.online + ' employé' + (l.online > 1 ? 's' : '') + ' en service' : 'Aucun employé disponible') + (l.number ? ' · ' + l.number : ''),
      trailing: h('span', { style: 'width:10px;height:10px;border-radius:50%;background:' + (l.online ? 'var(--green)' : 'var(--fg3)') }),
      chev: true, onclick: () => this.actions(l),
    })))));
  },
  actions(l) {
    const acts = [];
    if (l.voice) acts.push({ label: '📞  Appeler' + (l.number ? ' (' + l.number + ')' : ''), bold: true, onclick: () => this.call(l) });
    if (l.alert) acts.push({ label: '🚨  Envoyer une alerte avec ma position', onclick: () => this.compose(l) });
    if (l.number) acts.push({ label: 'Copier le numéro', onclick: () => Contacts.copy(l.number) });
    ActionSheet(l.label + (l.online ? '' : ' — indisponible'), acts);
  },
  async call(l) {
    if (S.call) { Toast('Un appel est déjà en cours', 'phone'); return; }
    if (!l.online) { Toast('Aucun employé disponible pour le moment', 'warning'); return; }
    const number = l.number || ('srv-' + l.id).slice(0, 20);
    Calls.setState({ state: 'dialing', number, hidden: false, since: Date.now(), service: l.label }); Calls.show();
    const r = await rpc('serviceVoice', l.id, false);
    if (!r || !r.ok) { Calls.end(); Alert('Appel impossible', (r && r.error) || rpc.err || 'Service indisponible', [{ label: 'OK', bold: true }]); return; }
    if (r.state === 'unavailable') { S.call.state = 'unavailable'; Calls.show(); Sound.busy(); setTimeout(() => Calls.end(), 2400); return; }
    S.call.id = r.id; S.call.state = 'ringing'; Calls.show(); Sound.ringback();
  },
  compose(l) {
    const v = { msg: '', anon: false };
    const pg = Page({ title: l.label, large: false, modal: true, left: [{ label: 'Annuler', onclick: () => this.ctx.pop() }], right: [{ label: 'Envoyer', bold: true, onclick: async () => {
      const r = await rpc('serviceCall', l.id, v.msg, v.anon);
      if (!r || !r.ok) { Toast((r && r.error) || rpc.err || 'Alerte impossible', 'warning'); return; }
      this.hist.unshift({ label: l.label, msg: v.msg || 'Demande d\'assistance', at: Date.now() });
      Toast('Alerte envoyée à ' + r.count + ' employé' + (r.count > 1 ? 's' : ''), 'check'); this.ctx.pop();
    } }] });
    pg.body.appendChild(h('div', { style: 'text-align:center;padding:18px' }, h('div', { style: `width:70px;height:70px;border-radius:18px;margin:auto;background:${l.color};display:grid;place-items:center;color:#fff`, html: icon(l.icon, 38) }), h('div', { style: 'font-size:22px;font-weight:600;margin-top:10px' }, l.label), h('div', { style: 'color:var(--fg2);font-size:14px' }, l.online + ' en service')));
    pg.body.appendChild(Group('Message', [{ input: true, multiline: true, left: true, rows: 5, maxlength: 300, placeholder: l.hint || 'Décrivez la situation…', onInput: x => v.msg = x }]));
    if (l.anon) pg.body.appendChild(Group(null, [{ title: 'Alerte anonyme', toggle: { on: false, onchange: x => v.anon = x } }]));
    pg.body.appendChild(Group(null, [{ icon: 'pin', color: '#ff375f', title: 'Position jointe automatiquement' }]));
    this.ctx.push(pg); setTimeout(() => { const t = $('textarea', pg.body); t && t.focus(); }, 420);
  },
};
Bus.on('serviceDial', async id => { await Services.load(); const l = Services.lines.find(x => x.id === id); if (l) setTimeout(() => (Services.ctx && Services.ctx.alive ? Services.compose(l) : null), 500); });
registerApp({ id: 'services', name: 'Services', icon: 'warning', grad: ['#ff453a', '#b3170e'], open: ctx => Services.open(ctx) });
