const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch(); const ctx = await b.newContext({ viewport: { width: 1280, height: 900 } }); const p = await ctx.newPage(); const base = 'http://127.0.0.1:3199'; const lr = await ctx.request.post(base + '/api/auth/login', { data: { email: 'client@demo.fr', password: 'ClientDemo!1' }, headers: { origin: base } }); console.log('login', lr.status());
  const errs = []; p.on('pageerror', e => errs.push('PAGEERROR ' + e.message)); p.on('console', m => { if (m.type() === 'error') errs.push('CONSOLE ' + m.text()); });
  p.on('response', r => { if (r.url().includes('/api/') && r.status() >= 400) errs.push(`HTTP ${r.status()} ${r.url()}`); });
  await p.goto(base + '/'); await p.waitForTimeout(1500);
  const keys = await p.evaluate(() => Object.keys(window.PAGES)); const navs = await p.evaluate(() => [...document.querySelectorAll('a.nav')].map(a => a.getAttribute('href').slice(2)));
  console.log('nav sans page:', navs.filter(n => !keys.includes(n)));
  for (const n of navs) { errs.length = 0; await p.goto('http://127.0.0.1:3199/#/' + n); await p.waitForTimeout(900); const txt = await p.evaluate(() => document.body.innerText.slice(0, 4000)); const bad = /undefined|NaN|\[object Object\]|null/.test(txt) ? ' ⚠ texte suspect: ' + (txt.match(/.{0,30}(undefined|NaN|\[object Object\]|null).{0,30}/) || [''])[0].replace(/\n/g, ' ') : ''; const h = await p.evaluate(() => { const e = document.querySelector('main h1, .head h1, h1'); return e ? e.innerText : '(aucun titre)'; }); console.log(n.padEnd(14), h.slice(0,32).padEnd(34), errs.length ? 'ERREURS ' + errs.join(' | ') : 'ok', bad); }
  await p.screenshot({ path: '/tmp/smoke_last.png' }); await b.close();
})();
