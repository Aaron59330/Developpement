// Génère UNE image « tarifs » (tarifs.png) à partir de config.json.  Usage : node tarifs-image.js
const { chromium } = require('playwright');
const fs = require('fs'), path = require('path');
const cfg = JSON.parse(fs.readFileSync(path.join(__dirname, 'config.json'), 'utf8'));
const C = cfg.couleur;
const head = t => `<div class="h"><i class="bar"></i><span class="e">${cfg.emoji}</span><i class="ln"></i><b>${t}</b></div>`;
const block = f => `${head(f.titre)}<div class="row"><ul>${f.lignes.map(l => `<li>${l}</li>`).join('')}</ul><div class="p">${f.prix}</div></div>`;
const html = `<body><style>
*{box-sizing:border-box}body{margin:0;background:#16171c;font-family:Montserrat,'Segoe UI',Arial,sans-serif;color:#fff}
.card{width:1200px;padding:40px 48px 44px;background:radial-gradient(900px 400px at 0 0,${C}22,transparent 70%),#16171c;border-left:8px solid ${C}}
.top{font-size:30px;font-weight:900;letter-spacing:3px;color:${C};margin-bottom:6px}
.h{display:flex;align-items:center;gap:16px;margin:30px 0 14px}.bar{width:64px;height:9px;border-radius:6px;background:${C}}.e{font-size:34px}
.ln{flex:1;height:7px;border-radius:6px;background:linear-gradient(90deg,${C},transparent)}.h b{font-size:38px;font-weight:900}
.row{display:flex;justify-content:space-between;align-items:center;gap:30px}ul{margin:0;padding-left:26px;font-size:24px;line-height:1.75;color:#e4e6ec}
.p{font-size:84px;font-weight:900;white-space:nowrap}.info{font-size:24px;line-height:1.7;color:#e4e6ec;white-space:pre-line}
</style><div class="card"><div class="top">${cfg.nomBase.toUpperCase()}</div>${cfg.formules.map(block).join('')}${head(cfg.infos.titre)}<div class="info">${cfg.infos.texte}</div></div></body>`;
(async () => {
  const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 1200, height: 800 } });
  fs.writeFileSync(path.join(__dirname, '_tarifs.html'), html); await p.goto('file://' + path.join(__dirname, '_tarifs.html')); await p.waitForTimeout(300);
  await p.locator('.card').screenshot({ path: path.join(__dirname, 'tarifs.png') });
  fs.unlinkSync(path.join(__dirname, '_tarifs.html')); await b.close(); console.log('tarifs.png généré');
})();
