/* ═══════════ Aero Bank & Crypto ═══════════ */
const Bank = {
  data: null,
  async open(ctx) {
    this.ctx = ctx;
    const pg = Page({ title: 'Banque', right: [{ icon: 'receipt', onclick: () => this.bills() }] });
    this.pg = pg; ctx.root(pg); pg.body.appendChild(Spinner());
    await this.load(); this.draw();
  },
  async load() { this.data = (await rpc('bank')) || { bank: 0, cash: 0, tx: [], bills: [], max: 0 }; },
  draw() {
    const pg = this.pg, d = this.data; clear(pg.body);
    pg.body.appendChild(h('div.bankcard', h('small', 'Solde disponible'), h('div.amount', money(d.bank)), h('div', { style: 'display:flex;justify-content:space-between;opacity:.85;font-size:14px;margin-top:18px' }, h('span', S.me.name), h('span', 'Espèces ' + money(d.cash)))));
    pg.body.appendChild(h('div.bankacts',
      this.act('send', 'Virement', () => this.transfer()),
      this.act('receipt', 'Factures' + (d.bills.length ? ' (' + d.bills.length + ')' : ''), () => this.bills()),
      this.act('trend', 'Crypto', () => OS.openApp('crypto')),
      this.act('wallet', 'Wallet', () => OS.openApp('wallet'))));
    if (d.bills.length) pg.body.appendChild(Group(null, [{ icon: 'warning', color: '#ff9f0a', title: d.bills.length + ' facture' + (d.bills.length > 1 ? 's' : '') + ' à régler', sub: money(d.bills.reduce((a, b) => a + b.amount, 0)) + ' au total', chev: true, onclick: () => this.bills() }]));
    const income = d.tx.filter(t => t.amount > 0).reduce((a, t) => a + t.amount, 0), spent = d.tx.filter(t => t.amount < 0).reduce((a, t) => a - t.amount, 0);
    pg.body.appendChild(h('div', { style: 'display:grid;grid-template-columns:1fr 1fr;gap:12px;margin:0 16px 20px' }, h('div.stat', h('small', 'Entrées'), h('b', { style: 'color:var(--green)' }, '+' + money(income))), h('div.stat', h('small', 'Sorties'), h('b', { style: 'color:var(--red)' }, '−' + money(spent)))));
    if (!d.tx.length) { pg.body.appendChild(Empty('receipt', 'Aucune opération')); return; }
    const byDay = {}; d.tx.forEach(t => { const k = fmtLong(t.created); (byDay[k] = byDay[k] || []).push(t); });
    Object.entries(byDay).forEach(([day, arr]) => pg.body.appendChild(Group(day, arr.map(t => ({
      icon: { in: 'download', out: 'send', bill: 'receipt', crypto: 'trend' }[t.kind] || 'money', color: t.amount > 0 ? '#30d158' : t.kind === 'bill' ? '#ff9f0a' : '#8e8e93',
      title: t.label || (t.amount > 0 ? 'Crédit' : 'Débit'), sub: (t.other || '') + ' · ' + fmtTime(t.created),
      trailing: h('b', { style: 'font-weight:600;color:' + (t.amount > 0 ? 'var(--green)' : 'var(--fg)') }, (t.amount > 0 ? '+' : '−') + money(Math.abs(t.amount))) })))));
  },
  act(ic, label, fn) { return h('button.bact', { onclick: fn }, h('span', { html: icon(ic, 24) }), label); },
  async transfer(prefill) {
    const v = { number: prefill || '', amount: '', label: '' };
    const pg = Page({ title: 'Virement', large: false, modal: true, left: [{ label: 'Annuler', onclick: () => this.ctx.pop() }], right: [{ label: 'Envoyer', bold: true, onclick: send }] });
    const dest = Row({ label: 'Destinataire', input: true, left: true, placeholder: 'Numéro de téléphone', type: 'tel', value: v.number, onInput: x => v.number = x });
    pg.body.appendChild(Group(null, [dest, { title: 'Choisir un contact', accent: true, onclick: async () => { const c = await pickContact(); if (c) { v.number = c.number; dest.input.value = fmtNum(c.number); } } }]));
    pg.body.appendChild(Group('Montant', [{ label: '$', input: true, left: true, placeholder: '0', type: 'number', value: '', onInput: x => v.amount = x }], 'Plafond : ' + money(this.data.max) + (this.data.fee ? ' · frais ' + this.data.fee + ' %' : '')));
    pg.body.appendChild(Group(null, [{ label: 'Motif', input: true, left: true, placeholder: 'Facultatif', onInput: x => v.label = x }]));
    const self = this;
    async function send() {
      const amt = Math.floor(Number(v.amount));
      if (!v.number || !amt || amt < 1) { Toast('Renseignez le destinataire et le montant', 'warning'); return; }
      if (!await Confirm('Envoyer ' + money(amt) + ' ?', 'À ' + contactName(v.number), 'Envoyer')) return;
      const r = await rpc('bankTransfer', v.number, amt, v.label);
      if (!r || !r.ok) { Toast((r && r.error) || 'Virement refusé', 'warning'); return; }
      Toast('Virement effectué', 'check'); self.ctx.pop(); await self.load(); self.draw();
    }
    this.ctx.push(pg);
  },
  bills() {
    const pg = Page({ title: 'Factures', large: false, back: 'Banque' });
    const draw = async () => {
      await this.load(); clear(pg.body);
      if (!this.data.bills.length) { pg.body.appendChild(Empty('receipt', 'Aucune facture', 'Vous êtes à jour !')); return; }
      pg.body.appendChild(Group(null, this.data.bills.map(b => ({ icon: 'receipt', color: '#ff9f0a', title: b.issuer, sub: (b.reason || '') + ' · ' + fmtDay(b.created), value: money(b.amount), onclick: () => ActionSheet(b.issuer + ' — ' + money(b.amount), [
        { label: 'Payer maintenant', bold: true, onclick: async () => { const r = await rpc('billPay', b.id); if (r && r.ok) { Toast('Facture réglée', 'check'); draw(); } else Toast((r && r.error) || 'Paiement refusé', 'warning'); } },
        { label: 'Refuser', red: true, onclick: async () => { await rpc('billDecline', b.id); draw(); } }]) }))));
    };
    pg.body.appendChild(Spinner()); this.ctx.push(pg); draw();
  },
};
registerApp({ id: 'bank', name: 'Aero Bank', icon: 'bank', grad: ['#34c759', '#0a8f3c'], open: ctx => Bank.open(ctx) });
Bus.on('push:notify', d => { if (d.app === 'bank' && Bank.ctx && Bank.ctx.alive && Bank.pg && Bank.ctx.stack[0] === Bank.pg) Bank.load().then(() => Bank.draw()); });

/* ───────────── Crypto ───────────── */
const Crypto = {
  async open(ctx) {
    this.ctx = ctx;
    const pg = Page({ title: 'Crypto' }); this.pg = pg; ctx.root(pg); pg.body.appendChild(Spinner());
    await this.load(); this.draw();
    this.iv = setInterval(async () => { if (!ctx.alive || ctx.stack.length > 1) return; await this.load(); this.draw(); }, 30000);
  },
  async load() { this.d = (await rpc('crypto')) || { coins: [], holdings: [], bank: 0, fee: 0 }; },
  spark(h_, color, w, ht) {
    if (!h_ || h_.length < 2) return '';
    const min = Math.min(...h_), max = Math.max(...h_), r = max - min || 1;
    const pts = h_.map((v, i) => (i / (h_.length - 1) * w).toFixed(1) + ',' + (ht - (v - min) / r * (ht - 4) - 2).toFixed(1)).join(' ');
    return `<svg viewBox="0 0 ${w} ${ht}" width="${w}" height="${ht}"><polyline points="${pts}" fill="none" stroke="${color}" stroke-width="2" stroke-linejoin="round" stroke-linecap="round"/></svg>`;
  },
  fmtP(p) { return p >= 100 ? money(p, 0) : p >= 1 ? money(p, 2) : (p.toFixed(4) + ' $'); },
  draw() {
    const pg = this.pg, d = this.d; clear(pg.body);
    const val = d.holdings.reduce((a, h_) => { const c = d.coins.find(x => x.id === h_.coin); return a + (c ? c.price * h_.amount : 0); }, 0);
    const inv = d.holdings.reduce((a, h_) => a + h_.invested, 0);
    const pl = val - inv;
    pg.body.appendChild(h('div.bankcard', { style: 'background:linear-gradient(135deg,#1a1a2e,#16213e 60%,#0f3460)' }, h('small', 'Portefeuille'), h('div.amount', money(val, 2)), h('div', { style: 'display:flex;justify-content:space-between;font-size:14px;margin-top:14px;opacity:.9' }, h('span', 'Disponible ' + money(d.bank)), h('span', { style: 'color:' + (pl >= 0 ? '#30d158' : '#ff453a') }, (pl >= 0 ? '+' : '') + money(pl, 2)))));
    pg.body.appendChild(Group('Marché', d.coins.map(c => {
      const own = d.holdings.find(x => x.coin === c.id);
      return { left: h('div.avatar', { style: `width:38px;height:38px;background:${c.color};font-size:12px` }, c.id.slice(0, 4)), title: c.name, sub: own ? own.amount.toFixed(4) + ' ' + c.id : c.id,
        trailing: h('div', { style: 'display:flex;align-items:center;gap:12px;text-align:right' }, h('span', { html: this.spark(c.history, c.change >= 0 ? '#30d158' : '#ff453a', 56, 26) }), h('div', h('b', { style: 'font-weight:600' }, this.fmtP(c.price)), h('div', { style: 'font-size:13px;color:' + (c.change >= 0 ? 'var(--green)' : 'var(--red)') }, (c.change >= 0 ? '▲ ' : '▼ ') + Math.abs(c.change).toFixed(2) + '%'))),
        onclick: () => this.coin(c) };
    }), 'Les cours évoluent en temps réel. Frais de transaction : ' + d.fee + ' %.'));
  },
  coin(c) {
    const d = this.d; const own = d.holdings.find(x => x.coin === c.id);
    const pg = Page({ title: c.name, large: false, back: 'Crypto' });
    pg.body.appendChild(h('div', { style: 'text-align:center;padding:16px' }, h('div', { style: 'font-size:38px;font-weight:700' }, this.fmtP(c.price)), h('div', { style: 'color:' + (c.change >= 0 ? 'var(--green)' : 'var(--red)') }, (c.change >= 0 ? '▲ ' : '▼ ') + Math.abs(c.change).toFixed(2) + '%'), h('div', { style: 'margin-top:14px', html: this.spark(c.history, c.change >= 0 ? '#30d158' : '#ff453a', 340, 150) })));
    if (own) pg.body.appendChild(Group('Votre position', [{ title: 'Quantité', value: own.amount.toFixed(6) + ' ' + c.id }, { title: 'Valeur', value: money(own.amount * c.price, 2) }, { title: 'Investi', value: money(own.invested, 2) }, { title: 'Plus / moins-value', value: h('span', { style: 'color:' + (own.amount * c.price - own.invested >= 0 ? 'var(--green)' : 'var(--red)') }, money(own.amount * c.price - own.invested, 2)) }]));
    pg.body.appendChild(h('div', { style: 'display:flex;gap:12px;padding:0 16px' }, h('button.btn.green', { style: 'flex:1', onclick: () => this.trade(c, 'buy') }, 'Acheter'), h('button.btn.red', { style: 'flex:1', disabled: !own, onclick: () => this.trade(c, 'sell') }, 'Vendre')));
    this.ctx.push(pg);
  },
  trade(c, side) {
    const own = this.d.holdings.find(x => x.coin === c.id);
    let amount = '';
    Sheet({ title: (side === 'buy' ? 'Acheter ' : 'Vendre ') + c.id, render: (body, close) => {
      const est = h('div', { style: 'text-align:center;color:var(--fg2);height:24px' });
      const inp = h('input', { type: 'number', placeholder: side === 'buy' ? 'Montant en $' : 'Quantité de ' + c.id, style: 'width:calc(100% - 32px);margin:14px 16px;height:54px;font-size:26px;text-align:center;background:var(--card2);border-radius:12px;color:var(--fg)', oninput: e => { amount = e.target.value; const n = Number(amount) || 0; est.textContent = side === 'buy' ? '≈ ' + (n * (1 - this.d.fee / 100) / c.price).toFixed(6) + ' ' + c.id : '≈ ' + money(n * c.price * (1 - this.d.fee / 100), 2); } });
      body.appendChild(inp); body.appendChild(est);
      body.appendChild(h('div', { style: 'text-align:center;color:var(--fg2);font-size:13px;margin:6px 0 12px' }, side === 'buy' ? 'Disponible : ' + money(this.d.bank) : 'Possédé : ' + (own ? own.amount.toFixed(6) : 0) + ' ' + c.id));
      body.appendChild(h('div', { style: 'display:flex;gap:8px;justify-content:center;margin-bottom:14px' }, (side === 'buy' ? [100, 500, 1000, 5000] : [25, 50, 100]).map(v => h('button.chip', { onclick: () => { inp.value = side === 'buy' ? v : (own.amount * v / 100).toFixed(6); inp.dispatchEvent(new Event('input')); } }, side === 'buy' ? v + ' $' : v + '%'))));
      body.appendChild(h('div', { style: 'padding:0 16px' }, h('button.btn.block' + (side === 'buy' ? '.green' : '.red'), { onclick: async () => {
        const r = await rpc('cryptoTrade', c.id, side, Number(amount), side === 'buy' ? 'fiat' : 'units');
        if (!r || !r.ok) { Toast((r && r.error) || 'Ordre refusé', 'warning'); return; }
        close(); Toast('Ordre exécuté', 'check'); await this.load(); this.ctx.pop(); this.draw();
      } }, side === 'buy' ? 'Confirmer l\'achat' : 'Confirmer la vente')));
    } });
  },
};
registerApp({ id: 'crypto', name: 'Crypto', icon: 'bitcoin', grad: ['#f7931a', '#d97706'], dark: true, open: ctx => Crypto.open(ctx), onQuit: () => clearInterval(Crypto.iv) });
