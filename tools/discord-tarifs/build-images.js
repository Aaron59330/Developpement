// Génère les bannières (titres) et les images de prix dans ./images à partir de config.json
// Usage : npm i playwright (une fois) puis  node build-images.js
const { chromium } = require('playwright');
const fs = require('fs'), path = require('path');
const cfg = JSON.parse(fs.readFileSync(path.join(__dirname, 'config.json'), 'utf8'));
const out = path.join(__dirname, 'images'); fs.mkdirSync(out, { recursive: true });
const C = cfg.couleur;

const banner = t => `<body style="margin:0;background:transparent"><div style="width:1100px;height:90px;display:flex;align-items:center;gap:18px;font-family:Montserrat,Segoe UI,Arial,sans-serif">
  <div style="width:70px;height:10px;border-radius:6px;background:${C}"></div><div style="font-size:40px">${cfg.emoji}</div>
  <div style="flex:1;height:8px;border-radius:6px;background:linear-gradient(90deg,${C},transparent)"></div>
  <div style="font-weight:900;font-size:44px;color:#fff;letter-spacing:1px">${t}</div></div></body>`;
const price = p => `<body style="margin:0;background:transparent"><div style="width:360px;height:360px;display:flex;align-items:center;justify-content:center;font-family:Montserrat,Segoe UI,Arial,sans-serif;font-weight:900;font-size:110px;color:#fff">${p}</div></body>`;

(async () => {
  const b = await chromium.launch(); const p = await b.newPage();
  const shot = async (html, file, w, h) => { await p.setViewportSize({ width: w, height: h }); await p.setContent(html); await p.screenshot({ path: path.join(out, file), omitBackground: true }); };
  for (const f of cfg.formules) { await shot(banner(f.titre), `banner_${f.id}.png`, 1100, 90); await shot(price(f.prix), `price_${f.id}.png`, 360, 360); }
  await shot(banner(cfg.infos.titre), 'banner_infos.png', 1100, 90);
  await b.close(); console.log('Images générées dans', out);
})();
