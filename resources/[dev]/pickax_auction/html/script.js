const $root = document.getElementById('root');
const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const money = n => Number(n || 0).toLocaleString('fr-FR') + ' $';
async function rpc(name, ...args) {
  try { const r = await fetch(`https://${GetParentResourceName()}/rpc`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ name, args }) }); return await r.json(); }
  catch (e) { return { ok: false, error: 'Pas de réponse' }; }
}
function toast(m, k) { const t = document.createElement('div'); t.className = 'toast ' + (k || ''); t.textContent = m; document.getElementById('toasts').appendChild(t); setTimeout(() => t.remove(), 3600); }
const left = (ends, off) => Math.max(0, ends - Math.floor(Date.now() / 1000 - off));
const fmt = s => s >= 86400 ? Math.floor(s / 86400) + ' j ' + Math.floor(s % 86400 / 3600) + ' h' : s >= 3600 ? Math.floor(s / 3600) + ' h ' + String(Math.floor(s % 3600 / 60)).padStart(2, '0') + ' min' : Math.floor(s / 60) + ':' + String(s % 60).padStart(2, '0');

const A = {
  tab: 'explore', d: null, off: 0, q: '', kind: '', sort: 'end', sel: null, pay: 'bank', amount: '', sellKind: 'item', inv: null, pickItem: null, pickPlate: null, form: { count: 1, start: '', buyout: '', hours: 24, account: 'bank' },
  open(d) { this.set(d); this.tab = 'explore'; this.sel = null; $root.classList.remove('hidden'); this.render(); },
  set(d) { this.d = d; this.off = Math.floor(Date.now() / 1000) - d.now; },
  async reload() { const d = await rpc('list'); if (d && d.ok) { this.set(d); this.render(); } },
  close() { $root.classList.add('hidden'); rpc('close'); },
  go(t) { this.tab = t; if (t === 'sell' && !this.inv) this.loadInv(); this.render(); },
  async loadInv() { const r = await rpc('inventory'); if (r && r.ok) { this.inv = r; this.render(); } else toast((r && r.error) || 'Erreur', 'err'); },
  img(a, ph) {
    if (a.kind === 'item') return `<div class="img"><img src="nui://ox_inventory/web/images/${esc(a.item)}.png" onerror="this.outerHTML='<span class=&quot;ph&quot;>📦</span>'"></div>`;
    return `<div class="img"><span class="ph">🚗</span></div>`;
  },
  list() {
    let l = this.d.auctions.filter(a => (!this.kind || a.kind === this.kind) && (!this.q || (a.label + ' ' + (a.plate || '')).toLowerCase().includes(this.q.toLowerCase())));
    l.sort(this.sort === 'asc' ? (x, y) => (x.bid || x.start) - (y.bid || y.start) : this.sort === 'desc' ? (x, y) => (y.bid || y.start) - (x.bid || x.start) : (x, y) => x.ends - y.ends);
    return l;
  },
  renderExplore() {
    const l = this.list(), sel = l.find(a => a.id === this.sel) || l[0];
    const card = a => { const s = left(a.ends, this.off); return `<div class="card ${sel && sel.id === a.id ? 'sel' : ''}" data-a="sel" data-id="${a.id}">${this.img(a)}${a.leading ? '<span class="tag g">Tu mènes</span>' : a.mine ? '<span class="tag">Ta vente</span>' : ''}<span class="time ${s < 600 ? 'hot' : ''}" data-end="${a.ends}">${fmt(s)}</span>
      <div class="inf"><b>${esc(a.label)}${a.kind === 'item' && a.count > 1 ? ' ×' + a.count : ''}</b><small>${a.kind === 'vehicle' ? 'Plaque ' + esc(a.plate) : 'Objet'} · ${esc(a.seller)}</small><div class="price">${money(a.bid || a.start)}</div></div></div>`; };
    let side = '<div class="detail muted">Aucune enchère ne correspond.</div>';
    if (sel) {
      const s = left(sel.ends, this.off), amt = this.amount === '' ? sel.minBid : this.amount;
      const po = (id, label, bal) => `<button class="po ${this.pay === id ? 'on' : ''}" data-a="pay" data-id="${id}"><b>${label}</b><small>${money(bal)}</small></button>`;
      side = `<div class="detail">${this.img(sel)}<div><h3>${esc(sel.label)}${sel.kind === 'item' && sel.count > 1 ? ' ×' + sel.count : ''}</h3><small class="muted">${sel.kind === 'vehicle' ? 'Véhicule · plaque ' + esc(sel.plate) : 'Objet'} · vendu par ${esc(sel.seller)}</small></div>
        <div><div class="eyebrow">${sel.bids ? 'Enchère actuelle' : 'Prix de départ'}</div><div class="big">${Number(sel.bid || sel.start).toLocaleString('fr-FR')}<small> $</small></div></div>
        <div><div class="kv"><span>Temps restant</span><b data-end="${sel.ends}">${fmt(s)}</b></div>${sel.buyout ? `<div class="kv"><span>Achat immédiat</span><b>${money(sel.buyout)}</b></div>` : ''}<div class="kv"><span>Enchère minimale</span><b>${money(sel.minBid)}</b></div></div>
        ${sel.mine ? (sel.bids ? '<p class="muted">Une enchère a été placée : la vente ne peut plus être annulée.</p>' : '<button class="danger" data-a="cancel" data-id="' + sel.id + '">Annuler ma vente</button>')
          : `<label class="f"><span>Ton enchère ($)</span><input id="amt" type="number" min="${sel.minBid}" value="${amt}"></label><div class="pay">${po('bank', 'Banque', this.d.bank)}${po('money', 'Liquide', this.d.cash)}</div>
          <button class="primary" data-a="bid" data-id="${sel.id}" ${sel.leading ? 'disabled' : ''}>${sel.leading ? 'Tu mènes déjà' : 'Enchérir'}</button>${sel.buyout ? `<button data-a="buy" data-id="${sel.id}">Acheter maintenant · ${money(sel.buyout)}</button>` : ''}`}</div>`;
    }
    return `<div class="ex"><div class="exm"><div class="row"><input id="q" placeholder="Rechercher un objet, un véhicule, une plaque…" value="${esc(this.q)}"><select data-s="sort" style="width:190px"><option value="end" ${this.sort === 'end' ? 'selected' : ''}>Fin proche</option><option value="asc" ${this.sort === 'asc' ? 'selected' : ''}>Prix croissant</option><option value="desc" ${this.sort === 'desc' ? 'selected' : ''}>Prix décroissant</option></select></div>
      <div class="chips">${[['', 'Tout'], ['item', 'Objets'], ['vehicle', 'Véhicules']].map(([k, n]) => `<span class="chip ${this.kind === k ? 'on' : ''}" data-a="kind" data-id="${k}">${n}</span>`).join('')}</div>
      <div class="grid">${l.map(card).join('') || '<p class="muted">Aucune enchère en cours.</p>'}</div></div>${side}</div>`;
  },
  renderSell() {
    const c = this.d.cfg, f = this.form, inv = this.inv;
    if (!inv) return '<p class="muted">Chargement de ton inventaire…</p>';
    const items = this.sellKind === 'item' ? inv.items : inv.vehicles;
    const sel = this.sellKind === 'item' ? inv.items.find(i => i.name === this.pickItem) : inv.vehicles.find(v => v.plate === this.pickPlate);
    const fee = Math.max(c.minFee, Math.floor((Number(f.start) || 0) * c.fee / 100));
    return `<div class="sell"><div><div class="chips" style="margin-bottom:12px"><span class="chip ${this.sellKind === 'item' ? 'on' : ''}" data-a="sk" data-id="item">Objets</span>${c.vehicles ? `<span class="chip ${this.sellKind === 'vehicle' ? 'on' : ''}" data-a="sk" data-id="vehicle">Véhicules (au garage)</span>` : ''}</div>
      <div class="pick">${items.map(i => this.sellKind === 'item' ? `<div class="item ${this.pickItem === i.name ? 'sel' : ''}" data-a="pick" data-id="${esc(i.name)}"><div class="thumb"><img src="nui://ox_inventory/web/images/${esc(i.name)}.png" onerror="this.style.display='none'"></div><div class="n"><b>${esc(i.label)}</b><small>×${i.count} dans ton inventaire</small></div></div>`
        : `<div class="item ${this.pickPlate === i.plate ? 'sel' : ''}" data-a="pick" data-id="${esc(i.plate)}"><div class="thumb">🚗</div><div class="n"><b>${esc(i.label)}</b><small>Plaque ${esc(i.plate)}</small></div></div>`).join('') || '<p class="muted">Rien à vendre ici.</p>'}</div></div>
      <div class="detail"><b>${sel ? esc(sel.label) : 'Choisis ce que tu veux vendre'}</b>
        ${this.sellKind === 'item' && sel ? `<label class="f"><span>Quantité (max ${sel.count})</span><input data-f="count" type="number" min="1" max="${sel.count}" value="${f.count}"></label>` : ''}
        <label class="f"><span>Prix de départ ($)</span><input data-f="start" type="number" min="1" value="${esc(f.start)}"></label>
        <label class="f"><span>Achat immédiat ($, optionnel)</span><input data-f="buyout" type="number" min="1" value="${esc(f.buyout)}"></label>
        <div class="f"><span>Durée</span><div class="chips">${c.durations.map(h => `<span class="chip ${Number(f.hours) === h ? 'on' : ''}" data-a="hours" data-id="${h}">${h} h</span>`).join('')}</div></div>
        <div class="kv"><span>Frais de mise en vente (${c.fee} %)</span><b>${money(fee)}</b></div><div class="kv"><span>Taxe à la vente</span><b>${c.tax} % du prix final</b></div>
        <div class="pay"><button class="po ${f.account === 'bank' ? 'on' : ''}" data-a="facc" data-id="bank"><b>Frais : banque</b><small>${money(this.d.bank)}</small></button><button class="po ${f.account === 'money' ? 'on' : ''}" data-a="facc" data-id="money"><b>Frais : liquide</b><small>${money(this.d.cash)}</small></button></div>
        <button class="primary" data-a="create" ${sel ? '' : 'disabled'}>Mettre en vente</button><p class="muted" style="margin:0;font-size:12px">L'objet / le véhicule est mis de côté pendant la vente. Annulable tant qu'aucune enchère n'est placée.</p></div></div>`;
  },
  renderMine() {
    const l = this.d.mine, st = { active: ['En cours', 'ok'], sold: ['Vendu', 'ok'], expired: ['Invendu', 'mute'], cancelled: ['Annulé', 'mute'], closing: ['Clôture…', 'warn'] };
    return l.map(a => `<div class="item"><div class="thumb">${a.kind === 'item' ? `<img src="nui://ox_inventory/web/images/${esc(a.item)}.png" onerror="this.style.display='none'">` : '🚗'}</div><div class="n"><b>${esc(a.label)}${a.count > 1 ? ' ×' + a.count : ''}</b><small>${a.status === 'sold' ? 'Vendu ' + money(a.final) : a.bids ? 'Meilleure offre ' + money(a.bid) : 'Départ ' + money(a.start)}${a.status === 'active' ? ' · reste ' + fmt(left(a.ends, this.off)) : ''}</small></div>
      <span class="st ${st[a.status] ? st[a.status][1] : 'mute'}">${st[a.status] ? st[a.status][0] : esc(a.status)}</span>${a.status === 'active' && !a.bids ? `<button class="danger" data-a="cancel" data-id="${a.id}">Annuler</button>` : ''}</div>`).join('') || '<p class="muted">Tu n\'as encore rien mis en vente.</p>';
  },
  renderBids() { return this.d.bids.map(a => `<div class="item"><div class="thumb">${a.kind === 'item' ? `<img src="nui://ox_inventory/web/images/${esc(a.item)}.png" onerror="this.style.display='none'">` : '🚗'}</div><div class="n"><b>${esc(a.label)}</b><small>Ton enchère ${money(a.bid)} · reste ${fmt(left(a.ends, this.off))}</small></div><span class="st ok">Tu mènes</span></div>`).join('') || '<p class="muted">Tu n\'as aucune enchère en cours. Si quelqu\'un te surenchérit, ton argent est rendu automatiquement.</p>'; },
  renderClaims() { return this.d.claims.map(c => `<div class="item"><div class="thumb"><img src="nui://ox_inventory/web/images/${esc(c.item)}.png" onerror="this.style.display='none'"></div><div class="n"><b>${esc(c.label)} ×${c.count}</b><small>${c.reason === 'won' ? 'Enchère remportée' : c.reason === 'unsold' ? 'Invendu' : 'Vente annulée'}</small></div><button class="primary" data-a="claim" data-id="${c.id}">Récupérer</button></div>`).join('') || '<p class="muted">Rien à récupérer.</p>'; },
  render() {
    const d = this.d; if (!d) return;
    const T = { explore: ['Enchères en cours', `${d.auctions.length} enchère(s) ouverte(s)`], sell: ['Vendre', 'Mets un objet ou un véhicule aux enchères'], mine: ['Mes ventes', 'Historique de tes mises en vente'], bids: ['Mes enchères', 'Les enchères sur lesquelles tu mènes'], claims: ['Réclamations', 'Objets gagnés ou invendus à récupérer'] };
    const nav = (id, ico, label, n) => `<div class="nav ${this.tab === id ? 'on' : ''}" data-a="go" data-id="${id}"><span>${ico}</span>${label}${n ? `<span class="n">${n}</span>` : ''}</div>`;
    const body = this.tab === 'explore' ? this.renderExplore() : this.tab === 'sell' ? this.renderSell() : this.tab === 'mine' ? this.renderMine() : this.tab === 'bids' ? this.renderBids() : this.renderClaims();
    $root.innerHTML = `<div class="shell"><div class="side"><div class="brand pl"><img class="plogo" data-pk-logo src="${window.PICKAX_LOGO || 'https://cfx-nui-pickax_theme/logo/logo.png'}" alt="" onerror="this.style.visibility='hidden'"><div class="logo">🔨</div><div><b>Hôtel des ventes</b><small data-pk="short">AERO</small></div></div>
      ${nav('explore', '🔎', 'Explorer', d.auctions.length)}${nav('sell', '➕', 'Vendre')}${nav('mine', '📦', 'Mes ventes', d.mine.filter(a => a.status === 'active').length)}${nav('bids', '🏷️', 'Mes enchères', d.bids.length)}${nav('claims', '🎁', 'Réclamations', d.claims.length)}<div class="sp"></div><button data-a="close">Fermer</button></div>
      <div class="main"><div class="head"><div style="flex:1"><h2>${T[this.tab][0]}</h2><p>${T[this.tab][1]}</p></div><div class="bal"><span>Liquide <b>${money(d.cash)}</b></span><span>Banque <b>${money(d.bank)}</b></span></div></div><div class="body">${body}</div></div></div>`;
  },
  tick() { document.querySelectorAll('[data-end]').forEach(el => { el.textContent = fmt(left(Number(el.dataset.end), this.off)); }); },
  async onA(el) {
    const a = el.dataset.a, id = el.dataset.id;
    const done = async (r, msg) => { if (r && r.ok) { if (msg) toast(msg, 'ok'); await this.reload(); return true; } toast((r && r.error) || 'Erreur', 'err'); return false; };
    if (a === 'close') return this.close();
    if (a === 'go') return this.go(id);
    if (a === 'sel') { this.sel = Number(id); this.amount = ''; return this.render(); }
    if (a === 'kind') { this.kind = id; return this.render(); }
    if (a === 'pay') { this.pay = id; return this.render(); }
    if (a === 'bid') { const v = Number(document.getElementById('amt').value); const r = await rpc('bid', Number(id), v, this.pay, false); this.amount = ''; if (await done(r, r && r.bought ? 'Acheté !' : 'Enchère placée : ' + money(r && r.amount))) { } return; }
    if (a === 'buy') { const r = await rpc('bid', Number(id), 0, this.pay, true); this.amount = ''; await done(r, 'Acheté !'); return; }
    if (a === 'cancel') return done(await rpc('cancel', Number(id)), 'Vente annulée');
    if (a === 'claim') { const r = await rpc('claim', Number(id)); return done(r, 'Récupéré'); }
    if (a === 'sk') { this.sellKind = id; return this.render(); }
    if (a === 'pick') { if (this.sellKind === 'item') { this.pickItem = id; this.form.count = 1; } else this.pickPlate = id; return this.render(); }
    if (a === 'hours') { this.form.hours = Number(id); return this.render(); }
    if (a === 'facc') { this.form.account = id; return this.render(); }
    if (a === 'create') {
      const f = this.form;
      const r = await rpc('create', { kind: this.sellKind, item: this.pickItem, count: Number(f.count), plate: this.pickPlate, start: Number(f.start), buyout: f.buyout ? Number(f.buyout) : null, hours: Number(f.hours), account: f.account });
      if (r && r.ok) { this.inv = null; this.pickItem = null; this.pickPlate = null; this.form = { count: 1, start: '', buyout: '', hours: this.form.hours, account: f.account }; toast('Mise en vente effectuée (frais ' + money(r.fee) + ')', 'ok'); await this.reload(); this.tab = 'mine'; this.render(); this.loadInv(); } else toast((r && r.error) || 'Erreur', 'err');
    }
  },
};
document.addEventListener('click', e => { const el = e.target.closest('[data-a]'); if (el) A.onA(el); });
document.addEventListener('input', e => {
  const el = e.target;
  if (el.id === 'q') { A.q = el.value; const p = el.selectionStart; A.render(); const q = document.getElementById('q'); if (q) { q.focus(); q.setSelectionRange(p, p); } }
  else if (el.dataset && el.dataset.f) A.form[el.dataset.f] = el.value;
  else if (el.id === 'amt') A.amount = el.value;
});
document.addEventListener('change', e => { if (e.target.dataset && e.target.dataset.s === 'sort') { A.sort = e.target.value; A.render(); } });
document.addEventListener('keydown', e => { if (e.key === 'Escape' && !$root.classList.contains('hidden')) A.close(); });
window.addEventListener('message', e => { const d = e.data || {}; if (d.action === 'open') A.open(d); else if (d.action === 'close') $root.classList.add('hidden'); });
setInterval(() => A.tick(), 1000);
