/* ═══════════ Noyau : DOM, état, RPC, sons, formats ═══════════ */
const IN_GAME = typeof GetParentResourceName === 'function';
const RES = IN_GAME ? GetParentResourceName() : 'pickax_phone';
const $ = (s, r) => (r || document).querySelector(s);
const $$ = (s, r) => [...(r || document).querySelectorAll(s)];

function h(tag, attrs, ...kids) {
  const parts = String(tag).split(/(?=[.#])/);
  const el = document.createElement(parts[0] || 'div');
  for (const p of parts.slice(1)) { if (p[0] === '.') el.classList.add(p.slice(1)); else if (p[0] === '#') el.id = p.slice(1); }
  if (attrs && (typeof attrs !== 'object' || attrs instanceof Node || Array.isArray(attrs))) { kids.unshift(attrs); attrs = null; }
  for (const k in (attrs || {})) {
    const v = attrs[k];
    if (v == null || v === false) continue;
    if (k === 'class') v.split(' ').forEach(c => c && el.classList.add(c));
    else if (k === 'style') { if (typeof v === 'string') el.style.cssText = v; else Object.assign(el.style, v); }
    else if (k === 'html') el.innerHTML = v;
    else if (k.startsWith('on') && typeof v === 'function') el.addEventListener(k.slice(2), v);
    else if (k === 'value') el.value = v;
    else el.setAttribute(k, v === true ? '' : v);
  }
  const add = (c) => {
    if (c == null || c === false) return;
    if (Array.isArray(c)) c.forEach(add);
    else el.appendChild(c instanceof Node ? c : document.createTextNode(String(c)));
  };
  kids.forEach(add);
  return el;
}
const esc = s => String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const clear = el => { while (el.firstChild) el.removeChild(el.firstChild); return el; };
const sleep = ms => new Promise(r => setTimeout(r, ms));
const debounce = (fn, ms) => { let t; return (...a) => { clearTimeout(t); t = setTimeout(() => fn(...a), ms); }; };

/* ───── événements internes ───── */
const Bus = {
  m: {},
  on(ev, fn) { (this.m[ev] = this.m[ev] || []).push(fn); return () => this.off(ev, fn); },
  off(ev, fn) { this.m[ev] = (this.m[ev] || []).filter(f => f !== fn); },
  emit(ev, d) { (this.m[ev] || []).slice().forEach(f => { try { f(d); } catch (e) { console.error(ev, e); } }); },
};

/* ───── réseau ───── */
async function post(name, data) {
  if (window.__MOCK) return window.__MOCK(name, data || {});
  try {
    const r = await fetch(`https://${RES}/${name}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data || {}) });
    return await r.json();
  } catch (e) { return null; }
}
async function rpc2(name, ...args) {
  const r = await post('rpc', { name, args, n: args.length });
  return r ? [r.a, r.b] : [null, 'Hors ligne'];
}
async function rpc(name, ...args) { const [a, b] = await rpc2(name, ...args); rpc.err = b; return a; }

/* ───── état global ───── */
const S = {
  me: null, settings: {}, contacts: {}, contactList: [], installed: [], catalog: [], battery: 100, charging: false,
  convs: [], notifs: [], badges: {}, locked: true, open: false, call: null, config: {}, hasPin: false, running: [], unreadMail: 0, wifi: true,
};

/* ───── formats ───── */
const pad = n => String(n).padStart(2, '0');
function fmtNum(n) {
  n = String(n || '').replace(/\D/g, '');
  if (!n) return '';
  const g = (S.config && S.config.numberGroup) || 2;
  const out = [n.slice(0, g)]; for (let i = g; i < n.length; i += g) out.push(n.slice(i, i + g));
  return out.join(' ');
}
function contactOf(number) { return S.contacts[String(number || '').replace(/\D/g, '')]; }
function contactName(number) {
  if (!number) return 'Numéro masqué';
  const c = contactOf(number); return c ? c.name : fmtNum(number);
}
function initials(name) {
  const p = String(name || '?').trim().split(/\s+/); return ((p[0] || '?')[0] + (p.length > 1 ? p[p.length - 1][0] : '')).toUpperCase();
}
const PALETTE = ['#ff6b6b', '#f59f00', '#40c057', '#15aabf', '#4c6ef5', '#7950f2', '#e64980', '#868e96', '#e8590c', '#12b886'];
function colorFor(s) { let x = 0; s = String(s || ''); for (let i = 0; i < s.length; i++) x = (x * 31 + s.charCodeAt(i)) >>> 0; return PALETTE[x % PALETTE.length]; }
function avatar(name, size, url) {
  const s = size || 40;
  const st = `width:${s}px;height:${s}px;font-size:${Math.round(s * .4)}px;`;
  if (url) return h('div.avatar', { style: st + `background-image:url("${String(url).replace(/"/g, '%22')}")` });
  return h('div.avatar', { style: st + `background:linear-gradient(160deg, ${colorFor(name)}, ${colorFor(name + '1')}aa)` }, initials(name));
}
const DAYS = ['dimanche', 'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi'];
const MONTHS = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
function fmtTime(ms) { const d = new Date(ms); return S.settings.hour24 === false ? ((d.getHours() % 12) || 12) + ':' + pad(d.getMinutes()) + (d.getHours() >= 12 ? ' PM' : ' AM') : pad(d.getHours()) + ':' + pad(d.getMinutes()); }
function sameDay(a, b) { return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate(); }
function fmtDay(ms) {
  const d = new Date(ms), n = new Date();
  if (sameDay(d, n)) return fmtTime(ms);
  const y = new Date(n); y.setDate(n.getDate() - 1);
  if (sameDay(d, y)) return 'Hier';
  if (n - d < 6 * 864e5) return DAYS[d.getDay()][0].toUpperCase() + DAYS[d.getDay()].slice(1);
  return pad(d.getDate()) + '/' + pad(d.getMonth() + 1) + '/' + String(d.getFullYear()).slice(2);
}
function fmtLong(ms) { const d = new Date(ms); return DAYS[d.getDay()] + ' ' + d.getDate() + ' ' + MONTHS[d.getMonth()] + ' ' + d.getFullYear(); }
function ago(ms) {
  const s = Math.max(1, Math.round((Date.now() - ms) / 1000));
  if (s < 60) return 'à l\'instant'; if (s < 3600) return Math.floor(s / 60) + ' min'; if (s < 86400) return Math.floor(s / 3600) + ' h'; return Math.floor(s / 86400) + ' j';
}
function money(n, d) { return (Number(n) || 0).toLocaleString('fr-FR', { minimumFractionDigits: d || 0, maximumFractionDigits: d == null ? 0 : d }) + ' $'; }
function dur(s) { s = Math.round(s || 0); return Math.floor(s / 60) + ':' + pad(s % 60); }
function linkify(t) { return esc(t).replace(/(https?:\/\/[^\s<]+)/g, '<a class="lnk" data-url="$1">$1</a>').replace(/(^|\s)#([\wÀ-ÿ]+)/g, '$1<a class="tag" data-tag="$2">#$2</a>').replace(/(^|\s)@([\w]+)/g, '$1<a class="tag" data-user="$2">@$2</a>'); }

/* ───── sons (WebAudio) ───── */
const Sound = {
  ctx: null, ringTimer: null, nodes: [],
  c() { if (!this.ctx) { try { this.ctx = new (window.AudioContext || window.webkitAudioContext)(); } catch (e) {} } if (this.ctx && this.ctx.state === 'suspended') this.ctx.resume(); return this.ctx; },
  vol() { return Math.max(0, Math.min(1, (S.settings.volume == null ? 70 : S.settings.volume) / 100)); },
  tone(freq, start, len, type, gain) {
    const c = this.c(); if (!c) return;
    const o = c.createOscillator(), g = c.createGain();
    o.type = type || 'sine'; o.frequency.value = freq;
    const v = (gain || .25) * this.vol(), t = c.currentTime + start;
    g.gain.setValueAtTime(0, t); g.gain.linearRampToValueAtTime(v, t + .012); g.gain.exponentialRampToValueAtTime(.0001, t + len);
    o.connect(g); g.connect(c.destination); o.start(t); o.stop(t + len + .05); this.nodes.push(o);
  },
  patterns: {
    Marimba: { len: 2.6, seq: [[784, 0, .3], [988, .15, .3], [1175, .3, .3], [988, .45, .3], [784, .8, .3], [988, .95, .3], [1175, 1.1, .3], [1568, 1.25, .5]], type: 'triangle' },
    Cristal: { len: 2.4, seq: [[1319, 0, .5], [1568, .2, .5], [1976, .4, .7], [1568, 1.1, .5], [1319, 1.3, .5], [1976, 1.5, .7]], type: 'sine' },
    Radar: { len: 2.0, seq: [[880, 0, .12], [880, .2, .12], [880, .4, .12], [1320, .7, .5]], type: 'square', gain: .1 },
    Pulse: { len: 1.6, seq: [[440, 0, .18], [660, .18, .18], [880, .36, .3], [440, .9, .18], [660, 1.08, .18], [880, 1.26, .3]], type: 'sawtooth', gain: .08 },
    Classique: { len: 3.0, seq: [[1400, 0, .08], [1100, .09, .08], [1400, .18, .08], [1100, .27, .08], [1400, .36, .08], [1100, .45, .08], [1400, 1.2, .08], [1100, 1.29, .08], [1400, 1.38, .08], [1100, 1.47, .08]], type: 'square', gain: .09 },
  },
  ring(name, loop) {
    this.stop();
    name = name || S.settings.ringtone;
    const p = this.patterns[name]; if (!p || S.settings.dnd) return;
    const play = () => p.seq.forEach(s => this.tone(s[0], s[1], s[2], p.type, p.gain));
    play(); this.ringTimer = setInterval(play, p.len * 1000);
  },
  stop() { clearInterval(this.ringTimer); this.ringTimer = null; this.nodes.forEach(n => { try { n.stop(); } catch (e) {} }); this.nodes = []; },
  text() { if (S.settings.dnd) return; const n = S.settings.texttone; if (n === 'Silence') return; this.tone(1568, 0, .25, 'sine', .2); this.tone(1175, .12, .35, 'sine', .2); this.tone(1568, .26, .5, 'sine', .15); },
  click() { this.tone(1800, 0, .03, 'sine', .05); },
  shutter() { this.tone(2400, 0, .03, 'square', .12); this.tone(1200, .06, .06, 'square', .1); },
  dial(d) { const f = { 1: [697, 1209], 2: [697, 1336], 3: [697, 1477], 4: [770, 1209], 5: [770, 1336], 6: [770, 1477], 7: [852, 1209], 8: [852, 1336], 9: [852, 1477], '*': [941, 1209], 0: [941, 1336], '#': [941, 1477] }[d]; if (f) { this.tone(f[0], 0, .12, 'sine', .1); this.tone(f[1], 0, .12, 'sine', .1); } },
  busy() { for (let i = 0; i < 4; i++) this.tone(480, i * .5, .25, 'sine', .12), this.tone(620, i * .5, .25, 'sine', .12); },
  ringback() { this.stop(); const play = () => { this.tone(440, 0, 1.0, 'sine', .08); this.tone(480, 0, 1.0, 'sine', .08); }; play(); this.ringTimer = setInterval(play, 3000); },
  alarm() { this.stop(); const play = () => { for (let i = 0; i < 4; i++) this.tone(1500, i * .22, .14, 'square', .12); }; play(); this.ringTimer = setInterval(play, 1400); },
};

/* ───── temps de jeu / réel ───── */
const Clock = { game: null, off: 0 };
async function syncClock() { if (!IN_GAME) return; const g = await post('gameTime'); if (g) Clock.game = g; }
function now() { return new Date(); }

/* ───── heure du téléphone : horloge de jeu (repli : heure réelle) ───── */
const GT = { h: null, m: 0, day: 0, mo: 1, y: 2024, dow: 0 };
async function pollGameTime() {
  const g = (IN_GAME || window.__MOCK) ? await post('gameTime') : null;
  if (g && g.h != null) { GT.h = g.h; GT.m = g.m; GT.day = g.day; GT.mo = g.mo; GT.y = g.y; GT.dow = g.d; GT.at = Date.now(); }
}
function clockDate() {
  if (GT.h == null) return new Date();
  const d = new Date(GT.y, GT.mo - 1, GT.day, GT.h, GT.m, 0);
  return new Date(d.getTime() + Math.max(0, Date.now() - GT.at) * 30);   // 1 s réelle ≈ 30 s de jeu
}
