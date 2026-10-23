/* ═══════════ Composants d'interface (style iOS) ═══════════ */
const Screen = () => $('#screen');

/* ───── pages & navigation ───── */
function Page(o) {
  o = o || {};
  const left = [], right = [];
  const page = { opts: o, el: null, body: null, nav: null };
  const mkBtn = (b) => {
    const el = h('button.nb' + (b.bold ? '.bold' : '') + (b.danger ? '.danger' : ''), { onclick: (e) => b.onclick && b.onclick(e, page) },
      b.icon ? h('span', { html: icon(b.icon) }) : null, b.label ? b.label : null);
    if (b.disabled) el.setAttribute('disabled', '');
    return el;
  };
  const lft = h('div.lft'), rgt = h('div.rgt'), title = h('div.t', o.title || '');
  const large = o.large === false || !o.title ? null : h('div.large', o.title);
  const setLeft = () => { clear(lft); if (o.back) lft.appendChild(mkBtn({ icon: 'chevL', label: typeof o.back === 'string' ? o.back : 'Retour', onclick: () => page.ctx.pop() })); (o.left || []).forEach(b => lft.appendChild(mkBtn(b))); };
  const setRight = () => { clear(rgt); (o.right || []).forEach(b => rgt.appendChild(mkBtn(b))); };
  setLeft(); setRight();
  const nav = o.noNav ? null : h('div.nav' + (large ? '' : '.small'), h('div.bar', lft, title, rgt), large);
  const body = h('div.body' + (o.nopad ? '.nopad' : ''));
  if (nav && large) body.addEventListener('scroll', () => nav.classList.toggle('scrolled', body.scrollTop > 6));
  const el = h('div.page' + (o.modal ? '.modal' : ''), nav, body, o.tabbar || null);
  Object.assign(page, {
    el, body, nav,
    setTitle(t) { title.textContent = t; if (large) large.textContent = t; },
    setRight(items) { o.right = items; setRight(); },
    setLeft(items) { o.left = items; setLeft(); },
    render(fn) { clear(body); const r = fn(body, page); if (r instanceof Node) body.appendChild(r); },
    scrollBottom() { body.scrollTop = body.scrollHeight; },
  });
  if (o.render) { const r = o.render(body, page); if (r instanceof Node) body.appendChild(r); }
  else if (o.content) body.appendChild(o.content);
  return page;
}

class AppCtx {
  constructor(def, el) { this.def = def; this.el = el; this.stack = []; this.alive = true; }
  push(page) {
    const prev = this.stack[this.stack.length - 1];
    page.ctx = this; page.el.classList.add('in'); this.el.appendChild(page.el);
    setTimeout(() => page.el.classList.remove('in'), 400);
    if (prev && !page.opts.modal) prev.el.classList.add('under');
    this.stack.push(page); Sound.click();
    page.opts.onShow && page.opts.onShow(page);
    return page;
  }
  root(page) { this.stack.forEach(p => p.el.remove()); this.stack = []; page.ctx = this; this.el.appendChild(page.el); this.stack.push(page); page.opts.onShow && page.opts.onShow(page); return page; }
  pop() {
    if (this.stack.length <= 1) return false;
    const p = this.stack.pop(), prev = this.stack[this.stack.length - 1];
    p.el.classList.add('out'); setTimeout(() => p.el.remove(), 300);
    if (prev) { prev.el.classList.remove('under'); prev.opts.onResume && prev.opts.onResume(prev); }
    p.opts.onClose && p.opts.onClose(p);
    return true;
  }
  popTo(page) { while (this.stack.length > 1 && this.stack[this.stack.length - 1] !== page) this.pop(); }
  get top() { return this.stack[this.stack.length - 1]; }
}

/* ───── éléments simples ───── */
function Toggle(on, onchange) {
  const el = h('div.toggle' + (on ? '.on' : ''));
  el.addEventListener('click', (e) => { e.stopPropagation(); el.classList.toggle('on'); Sound.click(); onchange && onchange(el.classList.contains('on')); });
  el.set = v => el.classList.toggle('on', !!v); el.get = () => el.classList.contains('on');
  return el;
}
function Seg(options, value, onchange) {
  const el = h('div.seg');
  options.forEach(o => {
    const v = typeof o === 'object' ? o.value : o, l = typeof o === 'object' ? o.label : o;
    const b = h('button' + (v === value ? '.on' : ''), { onclick: () => { $$('button', el).forEach(x => x.classList.remove('on')); b.classList.add('on'); Sound.click(); onchange && onchange(v); } }, l);
    el.appendChild(b);
  });
  return el;
}
function Spinner() { return h('div.spinner'); }
function Empty(ic, title, text) { return h('div.empty', h('div', { html: icon(ic) }), h('b', title), text ? h('p', text) : null); }
function SearchBar(o) {
  const inp = h('input', { placeholder: o.placeholder || 'Rechercher', value: o.value || '', type: 'text' });
  const clr = h('div.clr.hidden', { html: icon('x') });
  const upd = () => { clr.classList.toggle('hidden', !inp.value); o.onInput && o.onInput(inp.value); };
  inp.addEventListener('input', upd);
  if (o.onEnter) inp.addEventListener('keydown', e => { if (e.key === 'Enter') o.onEnter(inp.value); });
  clr.addEventListener('click', () => { inp.value = ''; upd(); inp.focus(); });
  const el = h('div.search', { html: icon('search') }, inp, clr);
  el.input = inp;
  return el;
}

/* ───── listes ───── */
function Row(r) {
  const el = h('div.row' + (r.icon || r.color ? '.ic-row' : '') + (r.danger ? '.danger' : '') + (r.accent ? '.accent' : '') + (r.center ? '.center' : '') + (r.class ? '.' + r.class : ''));
  if (r.icon) el.appendChild(h('div.rico', { style: `background:${r.color || 'var(--accent)'}`, html: icon(r.icon) }));
  else if (r.left instanceof Node) { el.appendChild(r.left); el.classList.add('has-left'); }
  if (r.label) el.appendChild(h('div.lbl', r.label));
  if (r.title != null || r.sub != null) el.appendChild(h('div.main', h('b', r.titleHtml ? { html: r.title } : null, r.titleHtml ? null : r.title), r.sub ? h('small', r.sub) : null));
  if (r.el) el.appendChild(r.el);
  if (r.input) {
    const i = h(r.multiline ? 'textarea.in' : 'input.in' + (r.left ? '.left' : ''), Object.assign({ placeholder: r.placeholder || '', value: r.value || '', type: r.type || 'text', rows: r.rows }, r.attrs || {}));
    if (r.maxlength) i.maxLength = r.maxlength;
    if (r.onInput) i.addEventListener('input', () => r.onInput(i.value));
    el.appendChild(i); el.input = i;
  }
  if (r.value != null && !r.input) el.appendChild(h('div.val', r.value, r.chev ? h('span', { html: icon('chevR', 15, 'chev') }) : null));
  else if (r.chev) el.appendChild(h('span', { html: icon('chevR', 15, 'chev') }));
  if (r.toggle) { el.toggle = Toggle(r.toggle.on, r.toggle.onchange); el.appendChild(el.toggle); }
  if (r.trailing) el.appendChild(r.trailing);
  if (r.onclick) el.addEventListener('click', (e) => { Sound.click(); r.onclick(e, el); });
  else if (!r.toggle && !r.chev) el.style.cursor = 'default';
  if (r.onlong) el.addEventListener('contextmenu', (e) => { e.preventDefault(); r.onlong(e, el); });
  return el;
}
function Group(title, rows, foot) {
  const g = h('div.group');
  if (title) g.appendChild(h('h6', title));
  const list = h('div.rows'); (rows || []).forEach(r => r && list.appendChild(r instanceof Node ? r : Row(r)));
  g.appendChild(list);
  if (foot) g.appendChild(h('div.foot', foot));
  g.rows = list;
  return g;
}

/* ───── superpositions ───── */
function overlay(node, scrim, onScrim) {
  const s = Screen();
  let sc = null;
  if (scrim !== false) { sc = h('div.scrim'); sc.addEventListener('click', () => { onScrim ? onScrim() : close(); }); s.appendChild(sc); }
  s.appendChild(node);
  const close = () => { node.remove(); sc && sc.remove(); };
  return close;
}
function Sheet(o) {
  const body = h('div.sh-body');
  const closeBtn = h('button.nb', { onclick: () => close() }, o.closeLabel || 'Fermer');
  const head = o.title != null ? h('div.sh-title' + (o.right || o.left ? '.l' : ''), o.left ? h('button.nb', { onclick: () => o.left.onclick(close) }, o.left.label) : (o.right ? h('span', { style: 'width:70px' }) : null), h('span', { style: 'font-weight:600' }, o.title), o.right ? h('button.nb.bold', { onclick: () => o.right.onclick(close) }, o.right.label) : (o.left ? h('span', { style: 'width:70px' }) : null)) : null;
  const sheet = h('div.sheet' + (o.full ? '.full' : ''), h('div.grab'), head, body);
  let close = overlay(sheet, true, () => close());
  const orig = close;
  close = () => { orig(); o.onClose && o.onClose(); };
  const r = o.render && o.render(body, close);
  if (r instanceof Node) body.appendChild(r);
  if (o.content) body.appendChild(o.content);
  return { close, body, el: sheet };
}
function ActionSheet(title, actions) {
  const grp = h('div.grp');
  if (title) grp.appendChild(h('div.head', title));
  actions.filter(Boolean).forEach(a => grp.appendChild(h('button' + (a.red ? '.red' : '') + (a.bold ? '.bold' : ''), { onclick: () => { close(); a.onclick && a.onclick(); } }, a.label)));
  const cancel = h('div.grp.c', h('button.bold', { onclick: () => close() }, 'Annuler'));
  const node = h('div.actions', grp, cancel);
  const close = overlay(node);
  return close;
}
function Alert(title, message, buttons, o) {
  o = o || {};
  const inp = o.input ? h('input', { placeholder: o.input.placeholder || '', value: o.input.value || '', type: o.input.type || 'text' }) : null;
  const btns = (buttons || [{ label: 'OK', bold: true }]).map(b => h('button' + (b.red ? '.red' : '') + (b.bold ? '.bold' : ''), { onclick: () => { close(); b.onclick && b.onclick(inp ? inp.value : undefined); } }, b.label));
  const node = h('div.alert', h('div.ab', h('h4', title), message ? h('p', message) : null, inp), h('div.ac', btns));
  const close = overlay(node, true, () => {});
  if (inp) setTimeout(() => inp.focus(), 50);
  return close;
}
const Confirm = (title, message, okLabel, red) => new Promise(res => Alert(title, message, [{ label: 'Annuler', onclick: () => res(false) }, { label: okLabel || 'OK', bold: true, red, onclick: () => res(true) }]));
const Prompt = (title, message, o) => new Promise(res => Alert(title, message, [{ label: 'Annuler', onclick: () => res(null) }, { label: 'OK', bold: true, onclick: v => res(v) }], { input: o || {} }));
function Toast(msg, ic) {
  $$('.toast', Screen()).forEach(t => t.remove());
  const t = h('div.toast', ic ? h('span', { html: icon(ic, 18) }) : null, msg);
  Screen().appendChild(t); setTimeout(() => t.remove(), 2600);
}
function TabBar(items, active, onchange) {
  const bar = h('div.tabbar');
  items.forEach(it => {
    const b = h('button' + (it.id === active ? '.on' : ''), { onclick: () => { $$('button', bar).forEach(x => x.classList.remove('on')); b.classList.add('on'); onchange(it.id); Sound.click(); } }, h('span', { html: icon(it.icon) }), it.label);
    if (it.badge) b.appendChild(h('div.badge', it.badge));
    b.id_ = it.id; bar.appendChild(b);
  });
  bar.setBadge = (id, n) => { const b = [...bar.children].find(x => x.id_ === id); if (!b) return; const old = $('.badge', b); old && old.remove(); if (n) b.appendChild(h('div.badge', n)); };
  return bar;
}

/* ───── sélecteurs communs ───── */
function pickContact(o) {
  o = o || {};
  return new Promise(res => {
    const sel = new Set();
    let done = false;
    const sh = Sheet({
      title: o.title || 'Choisir un contact', full: true, left: { label: 'Annuler', onclick: c => c() },
      right: o.multi ? { label: 'OK', onclick: c => { done = true; c(); res([...sel]); } } : null,
      onClose: () => { if (!done) res(o.multi ? [] : null); },
      render(body, close) {
        const list = h('div');
        const draw = (q) => {
          clear(list);
          q = (q || '').toLowerCase();
          const rows = S.contactList.filter(c => !q || c.name.toLowerCase().includes(q) || c.number.includes(q)).map(c => Row({
            left: avatar(c.name, 36, c.avatar), title: c.name, sub: fmtNum(c.number),
            trailing: o.multi ? h('div', { style: 'width:22px;height:22px;border-radius:50%;border:2px solid var(--fg3);display:grid;place-items:center', id: 'pk' + c.id }) : null,
            onclick: (e, el) => {
              if (!o.multi) { done = true; close(); res(c); return; }
              if (sel.has(c.number)) sel.delete(c.number); else sel.add(c.number);
              const t = $('div[id^=pk]', el); t.style.background = sel.has(c.number) ? 'var(--accent)' : ''; t.style.borderColor = sel.has(c.number) ? 'var(--accent)' : ''; t.innerHTML = sel.has(c.number) ? icon('check', 13).replace('stroke-width="1.8"', 'stroke-width="3.5"') : ''; t.style.color = '#fff';
            },
          }));
          list.appendChild(h('div.group', h('div.rows', rows.length ? rows : [h('div.row.center', { style: 'color:var(--fg2)' }, 'Aucun contact')])));
        };
        body.appendChild(SearchBar({ placeholder: 'Rechercher', onInput: draw }));
        body.appendChild(list); draw('');
      },
    });
  });
}

/* ───── visionneuse de photo ───── */
function viewImage(url, actions) {
  const node = h('div', { style: 'position:absolute;inset:0;z-index:160;background:#000;display:flex;flex-direction:column;animation:fadein .2s' },
    h('div', { style: 'padding:56px 14px 8px;display:flex;justify-content:space-between;align-items:center;color:var(--accent)' },
      h('button.nb', { style: 'font-size:17px;color:var(--accent)', onclick: () => node.remove() }, 'Fermer'),
      h('div', { style: 'display:flex;gap:6px' }, (actions || []).map(a => h('button', { style: 'padding:6px 10px;color:' + (a.red ? 'var(--red)' : 'var(--accent)') + ';font-size:16px', onclick: () => { a.onclick(() => node.remove()); } }, a.icon ? h('span', { html: icon(a.icon, 24) }) : a.label)))),
    h('div', { style: 'flex:1;display:grid;place-items:center;overflow:hidden' }, h('img', { src: url, style: 'max-width:100%;max-height:100%;object-fit:contain' })));
  Screen().appendChild(node);
  return node;
}

/* ───── saisie : prévient le jeu quand le clavier est utilisé ───── */
let typingState = false;
document.addEventListener('focusin', e => { if (/^(INPUT|TEXTAREA|SELECT)$/.test(e.target.tagName) && !typingState) { typingState = true; post('typing', { state: true }); } });
document.addEventListener('focusout', () => { setTimeout(() => { const a = document.activeElement; if (!(a && /^(INPUT|TEXTAREA|SELECT)$/.test(a.tagName)) && typingState) { typingState = false; post('typing', { state: false }); } }, 40); });
document.addEventListener('click', e => {
  const a = e.target.closest && e.target.closest('a.lnk');
  if (a) { e.preventDefault(); Toast('Lien : ' + a.dataset.url.slice(0, 40), 'link'); }
});
