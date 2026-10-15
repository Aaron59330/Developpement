const { chromium } = require('/opt/node-tools/node_modules/playwright');
const { Ctx } = require('./lib.cjs');
const I = require('./icons.cjs');
const fs = require('fs');
const outDir = process.argv[2] || '/tmp/claude-0/-home-user-Developpement/fa12efd6-6454-534f-bb41-35732b74637f/scratchpad/icons/out';
fs.mkdirSync(outDir, { recursive: true });
(async () => {
  const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium', args: ['--no-sandbox'] });
  const p = await b.newPage({ viewport: { width: 128, height: 128 }, deviceScaleFactor: 1 });
  const errs = [];
  for (const [name, fn] of Object.entries(I)) {
    try {
      const c = new Ctx(); fn(c);
      await p.setContent(`<html><body style="margin:0;background:transparent">${c.svg()}</body></html>`);
      await p.screenshot({ path: `${outDir}/${name}.png`, omitBackground: true, clip: { x: 0, y: 0, width: 128, height: 128 } });
    } catch (e) { errs.push(name + ': ' + e.message); }
  }
  console.log(Object.keys(I).length, 'icônes ; erreurs:', errs);
  await b.close();
})();
