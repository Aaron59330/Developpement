/* ═══════════ Services (urgences & métiers) ═══════════ */
const Services = {
  hist: [],
  async open(ctx) {
    this.ctx = ctx;
    const pg = Page({ title: 'Services' }); this.pg = pg; ctx.root(pg); pg.body.appendChild(Spinner());
    const st = (await rpc('serviceStatus')) || {};
    clear(pg.body);
    pg.body.appendChild(h('div', { style: 'padding:4px 20px 12px;color:var(--fg2);font-size:14px;line-height:1.4' }, 'Envoyez une alerte aux équipes en service. Votre position est transmise automatiquement.'));
    pg.body.appendChild(Group(null, (S.config.services || []).map(s => ({ icon: s.icon, color: s.color, title: s.label, sub: (st[s.id] || 0) + ' disponible' + ((st[s.id] || 0) > 1 ? 's' : '') + (s.number ? ' · ' + s.number : ''), chev: true, onclick: () => this.compose(s) }))));
    if (this.hist.length) pg.body.appendChild(Group('Alertes envoyées', this.hist.slice(0, 6).map(h_ => ({ title: h_.label, sub: ago(h_.at) + ' · ' + h_.msg.slice(0, 40) }))));
  },
  compose(s) {
    const v = { msg: '', anon: false };
    const pg = Page({ title: s.label, large: false, modal: true, left: [{ label: 'Annuler', onclick: () => this.ctx.pop() }], right: [{ label: 'Envoyer', bold: true, onclick: async () => {
      const r = await rpc('serviceCall', s.id, v.msg, v.anon);
      if (!r || !r.ok) { Toast((r && r.error) || rpc.err || 'Alerte impossible', 'warning'); return; }
      this.hist.unshift({ label: s.label, msg: v.msg || 'Demande d\'assistance', at: Date.now() });
      Toast('Alerte envoyée à ' + r.count + ' agent' + (r.count > 1 ? 's' : ''), 'check'); this.ctx.pop();
    } }] });
    pg.body.appendChild(h('div', { style: 'text-align:center;padding:18px' }, h('div.rico', { style: `width:70px;height:70px;border-radius:18px;margin:auto;background:${s.color};display:grid;place-items:center;color:#fff`, html: icon(s.icon, 38) }), h('div', { style: 'font-size:22px;font-weight:600;margin-top:10px' }, s.label)));
    pg.body.appendChild(Group('Message', [{ input: true, multiline: true, left: true, rows: 5, maxlength: 300, placeholder: 'Décrivez la situation…', onInput: x => v.msg = x }]));
    if (s.anon) pg.body.appendChild(Group(null, [{ title: 'Alerte anonyme', toggle: { on: false, onchange: x => v.anon = x } }]));
    pg.body.appendChild(Group(null, [{ icon: 'pin', color: '#ff375f', title: 'Position jointe automatiquement' }]));
    this.ctx.push(pg); setTimeout(() => { const t = $('textarea', pg.body); t && t.focus(); }, 420);
  },
};
Bus.on('serviceDial', id => { const s = (S.config.services || []).find(x => x.id === id); setTimeout(() => s && Services.compose(s), 450); });
registerApp({ id: 'services', name: 'Services', icon: 'warning', grad: ['#ff453a', '#b3170e'], open: ctx => Services.open(ctx) });
