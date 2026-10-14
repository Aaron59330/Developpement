const { Ctx, light, dark, mix, OUT } = require('./lib.cjs');
const I = {};   // nom d'objet -> fonction(ctx)

/* ───── gabarits ───── */
const bottle = (o) => (c) => {
  const { body = '#6b3f1d', cap = '#d4af37', label = '#f1e6c8', stripe = '#a83232', shape = 'tall', glass = false, liquid } = o;
  if (shape === 'flask') {
    c.path('M52 22h24v10c0 6 14 12 14 30v38c0 8-6 12-14 12H52c-8 0-14-4-14-12V62c0-18 14-24 14-30z', body, 'h');
    c.rect(50, 12, 28, 14, cap, 4);
  } else if (shape === 'square') {
    c.path('M54 22h20v16c0 4 16 8 16 22v40c0 8-6 12-14 12H52c-8 0-14-4-14-12V60c0-14 16-18 16-22z', body, 'h');
    c.rect(52, 12, 24, 14, cap, 4);
  } else {
    c.path('M54 14h20v26c0 8 14 12 14 28v34c0 8-6 12-14 12H54c-8 0-14-4-14-12V68c0-16 14-20 14-28z', body, 'h');
    c.rect(52, 8, 24, 12, cap, 4);
  }
  c.rect(44, 70, 40, 28, label, 4);
  c.rect(44, 78, 40, 8, stripe, 0);
  c.shine('M48 66v36', .4);
};
const can = (o) => (c) => {
  const { color = '#d62d2d', band = '#f5f5f5', stripe = '#1c1e24' } = o;
  c.rect(38, 24, 52, 84, color, 10, 'h');
  c.ellipse(64, 24, 26, 7, '#c9ced6');
  c.rect(38, 56, 52, 24, band, 0, 'h');
  c.rect(38, 64, 52, 8, stripe, 0);
  c.ellipse(64, 108, 26, 6, dark(color, .25));
  c.line(62, 22, 74, 20, OUT, 3);
  c.shine('M44 30v72', .45);
};
const glassCock = (o) => (c) => {
  const { liquid = '#e8a72c', garnish = 'lime', straw = true, ice = true, tall = true } = o;
  c.path(tall ? 'M38 30h52l-5 76c0 4-3 6-7 6H50c-4 0-7-2-7-6z' : 'M34 36h60l-8 64c-1 5-4 8-9 8H51c-5 0-8-3-9-8z', 'rgba(210,235,250,0.0)'.length ? '#cfe6f2' : '#cfe6f2');
  c.path(tall ? 'M42 52h44l-3 54c0 3-2 4-5 4H50c-3 0-5-1-5-4z' : 'M39 52h50l-6 48c-1 4-3 6-7 6H52c-4 0-6-2-7-6z', liquid);
  if (ice) { c.rect(50, 58, 16, 16, '#e9f6fc', 4); c.rect(66, 70, 14, 14, '#e9f6fc', 4); }
  if (straw) c.path('M74 14l-12 52', null, 'v', 6);
  if (straw) c.line(74, 14, 62, 66, '#f26d6d', 4);
  if (garnish === 'lime') { c.ellipse(86, 36, 12, 12, '#7bd143'); c.circle(86, 36, 4, '#e9f7b8'); }
  if (garnish === 'mint') { c.path('M80 36c4-14 16-18 22-14-2 12-10 20-22 14z', '#3fae4a'); c.path('M72 30c-2-12-12-16-18-12 2 10 8 16 18 12z', '#52c25c'); }
  if (garnish === 'orange') { c.circle(88, 36, 12, '#f59a1b'); c.circle(88, 36, 5, '#ffd27a'); }
  c.shine('M48 40l3 56', .5);
};
const vglass = (o) => (c) => {   // verre à cocktail (martini)
  const { liquid = '#e6f2c8', olive = true } = o;
  c.path('M24 28h80L70 76v28h16v8H42v-8h16V76z', '#cfe6f2');
  c.path('M34 34h60L68 70H60z', liquid);
  if (olive) { c.circle(72, 44, 7, '#6a8f2a'); c.line(60, 22, 84, 56, '#b88a4a', 3.5); }
  c.shine('M32 32l30 34', .55);
};
const shot = (o) => (c) => {
  const { liquid = '#d99a2b', lemon = true } = o;
  c.path('M40 40h48l-6 62c0 4-3 6-7 6H53c-4 0-7-2-7-6z', '#cfe6f2');
  c.path('M44 62h40l-4 38c0 3-2 4-5 4H53c-3 0-5-1-5-4z', liquid);
  if (lemon) { c.ellipse(92, 42, 13, 11, '#f7d33b'); c.ellipse(92, 42, 6, 5, '#fff3a8'); }
  c.shine('M48 48l3 52', .5);
};
const carton = (o) => (c) => {
  const { color = '#f08a1a', fruit = '#f59a1b', leaf = '#4caf50', stripe = '#fff' } = o;
  c.path('M38 34l26-18 26 18z', dark(color, .15));
  c.rect(38, 34, 52, 76, color, 4, 'h');
  c.circle(64, 70, 17, fruit);
  c.path('M64 54c0-8 8-12 14-10-1 8-6 12-14 10z', leaf);
  c.rect(38, 98, 52, 6, stripe, 0);
  c.shine('M44 40v66', .4);
};
const pooch = (o) => (c) => {
  const { fill = '#2fa32f', kind = 'bud' } = o;
  c.path('M30 26h68l5 82c0 4-3 6-7 6H32c-4 0-7-2-7-6z', 'rgba(255,255,255,.0)' && '#e4eef3');
  c.rect(28, 20, 72, 14, '#d83a3a', 3);
  if (kind === 'powder') { c.path('M36 106c2-26 14-40 28-40s26 14 28 40z', fill); c.path('M46 96c4-12 10-18 18-18', null, 'v', 2.6); }
  else for (const [x, y, r] of [[48, 92, 11], [68, 96, 12], [82, 84, 10], [58, 76, 11], [74, 68, 10], [46, 70, 9], [62, 56, 9]]) c.circle(x, y, r, fill);
  c.shine('M34 40v62', .5);
};
const apple = (col, leafCol = '#3c9d3c') => (c) => {
  c.path('M64 38c-12-10-34-6-36 20-2 24 14 52 32 52 4 0 5-2 4-2 0 0 0 2 4 2 18 0 34-28 32-52-2-26-24-30-36-20z', col, 'h');
  c.line(64, 38, 66, 22, '#5a3a1a', 4);
  c.path('M66 26c6-10 18-10 24-6-4 10-14 14-24 6z', leafCol);
  c.shine('M40 54c0 12 4 24 10 32', .5);
};
const orange = (c) => {
  c.circle(64, 68, 40, '#f59a1b', 'h');
  c.path('M64 28c0-8 8-12 14-10-1 8-6 12-14 10z', '#3c9d3c');
  c.shine('M38 58c2-10 10-18 20-22', .55);
  for (const [x, y] of [[50, 70], [66, 82], [78, 62]]) c.circle(x, y, 1.6, '#c9760e');
};
const grapes = (col, leafCol = '#3c9d3c') => (c) => {
  const pts = [[48, 54], [64, 54], [80, 54], [56, 70], [72, 70], [64, 86], [40, 70], [88, 70], [64, 102]];
  c.path('M64 40c-6-16 8-24 20-20-2 12-8 20-20 20z', leafCol);
  c.line(64, 40, 64, 54, '#5a3a1a', 4);
  for (const [x, y] of pts) { c.circle(x, y + 4, 11, col); }
  c.shine('M44 52l-2 4', .6);
};
const leaf = (col, n = 1, veins = true) => (c) => {
  const one = (rot, s = 1) => { c.add(`<g transform="translate(64 66) rotate(${rot}) scale(${s}) translate(-64 -66)">`); c.path('M64 18c28 14 38 44 0 92-38-48-28-78 0-92z', col, 'h'); c.line(64, 24, 64, 106, dark(col, .45), 3); if (veins) for (const y of [46, 62, 78]) { c.line(64, y, 46, y - 12, dark(col, .45), 2.4); c.line(64, y, 82, y - 12, dark(col, .45), 2.4); } c.add('</g>'); };
  if (n === 1) one(0); else { one(-28, .9); one(28, .9); one(0, 1); }
};
const fish = (o) => (c) => {
  const { body = '#7a8fa6', belly = '#e4ecf2', fin = '#4d6179', long = false } = o;
  const w = long ? 40 : 34;
  c.path(`M20 64l-4-26 24 14c8-8 22-12 44-8 16 4 30 14 36 24-6 10-20 20-36 24-22 4-36 0-44-8l-24 14z`.replace('M20', 'M18').replace('-4-26', '-2-24'), body, 'v');
  c.path('M44 74c14 10 40 10 62-6-10 16-34 22-62 6z', belly);
  c.circle(98, 58, 4.5, '#fff'); c.circle(99, 58, 2, '#111');
  c.path('M62 44c4-10 14-14 22-10-2 8-10 14-22 10z', fin);
  c.line(88, 70, 96, 72, OUT, 2.6);
  c.shine('M52 56c10-6 24-8 36-4', .45);
};
const kit = (o) => (c) => {   // mallette / trousse
  const { color = '#d63b3b', sym = 'cross', symCol = '#fff' } = o;
  c.rect(24, 40, 80, 62, color, 12, 'h');
  c.path('M48 40v-8c0-4 3-6 7-6h18c4 0 7 2 7 6v8', null, 'v', 5);
  c.rect(24, 62, 80, 4, dark(color, .3), 0);
  c.circle(64, 78, 16, symCol);
  if (sym === 'cross') { c.rect(62, 68, 4, 20, color, 1); c.rect(54, 76, 20, 4, color, 1); }
  if (sym === 'wrench') { c.line(56, 88, 72, 68, color, 6); c.circle(74, 66, 6, symCol); }
  if (sym === 'car') { c.rect(52, 76, 24, 8, color, 3); c.circle(57, 86, 3, OUT); c.circle(71, 86, 3, OUT); }
  if (sym === 'heart') { c.path('M64 90c-14-9-14-18-8-20 4-1 8 2 8 6 0-4 4-7 8-6 6 2 6 11-8 20z', color); }
  c.shine('M30 48h66', .35);
};
const card = (o) => (c) => {
  const { color = '#e7e1d1', head = '#2f6fd1', sym = 'person', label = '' } = o;
  c.rect(14, 28, 100, 72, color, 8, 'h');
  c.rect(14, 28, 100, 18, head, 8);
  c.rect(14, 38, 100, 8, head, 0);
  c.rect(24, 54, 28, 34, '#b9b4a6', 3);
  if (sym === 'person') { c.circle(38, 66, 7, '#8a8678'); c.path('M26 88c0-10 6-14 12-14s12 4 12 14z', '#8a8678'); }
  for (const y of [58, 68, 78]) c.rect(60, y, [44, 36, 28][(y - 58) / 10], 5, '#a8a394', 2);
  if (label) c.text(64, 40, label, 10, '#fff');
  if (sym === 'car') { c.rect(30, 66, 16, 8, head, 3); c.circle(34, 76, 2.4, OUT); c.circle(44, 76, 2.4, OUT); }
  if (sym === 'moto') { c.circle(32, 74, 5, '#6a6a6a'); c.circle(46, 74, 5, '#6a6a6a'); c.line(32, 74, 40, 64, OUT, 3); c.line(40, 64, 46, 74, OUT, 3); }
  if (sym === 'truck') { c.rect(26, 62, 14, 12, head, 2); c.rect(40, 66, 8, 8, head, 2); c.circle(32, 76, 2.4, OUT); c.circle(44, 76, 2.4, OUT); }
  if (sym === 'gun') { c.path('M28 70h18v-6H34v-4h-6z', head); c.rect(34, 70, 6, 10, head, 1); }
  if (sym === 'dumbbell') { c.line(30, 72, 48, 72, OUT, 4); c.rect(26, 64, 6, 16, head, 2); c.rect(46, 64, 6, 16, head, 2); }
  if (sym === 'sign') { c.path('M38 58l12 20H26z', head); c.line(38, 66, 38, 72, '#fff', 2.5); }
  if (sym === 'star') { c.path('M38 58l3 7 8 1-6 5 2 8-7-4-7 4 2-8-6-5 8-1z', head); }
};
const stackBills = (band = '#e9d89a', bill = '#6fa86b', mark = false) => (c) => {
  for (const [dx, dy, r] of [[0, 14, -4], [0, 4, -2], [0, -6, 0]]) { c.add(`<g transform="translate(${dx} ${dy}) rotate(${r} 64 64)">`); c.rect(22, 44, 84, 42, bill, 5, 'h'); c.circle(64, 65, 12, light(bill, .35)); c.text(64, 71, '$', 18, dark(bill, .55)); c.add('</g>'); }
  c.rect(52, 36, 24, 62, band, 2);
  if (mark) c.line(52, 56, 76, 80, '#d63b3b', 5);
};
const pack = (o) => (c) => {   // paquet de cigarettes
  const { color = '#1f4a9a', stripe = '#f5f5f5', logo = '#d63b3b' } = o;
  c.rect(34, 24, 60, 84, color, 6, 'h');
  c.rect(34, 24, 60, 24, light(color, .12), 6);
  c.rect(34, 50, 60, 20, stripe, 0);
  c.circle(64, 60, 7, logo);
  c.shine('M40 30v74', .35);
};
const leather = (o) => (c) => {};
Object.assign(I, {
  armor: (c) => { c.path('M30 30l20-8c4 8 24 8 28 0l20 8 6 24-14 6v44H38V60l-14-6z', '#3a4a5e', 'h'); c.rect(38, 78, 52, 10, '#2a3646', 2); c.rect(38, 92, 52, 6, '#2a3646', 2); c.shine('M42 40l-2 16', .4); },
  basic_cuff: (c) => { c.add(`<circle cx="44" cy="70" r="22" fill="none" stroke="${OUT}" stroke-width="12"/><circle cx="44" cy="70" r="22" fill="none" stroke="#bfc5cf" stroke-width="7"/>`); c.add(`<circle cx="88" cy="58" r="22" fill="none" stroke="${OUT}" stroke-width="12"/><circle cx="88" cy="58" r="22" fill="none" stroke="#aab1bd" stroke-width="7"/>`); c.line(60, 62, 72, 60, '#8b919c', 6); c.rect(38, 44, 12, 8, '#3d4450', 2); },
  police_cuff: (c) => { c.add(`<circle cx="44" cy="70" r="22" fill="none" stroke="${OUT}" stroke-width="12"/><circle cx="44" cy="70" r="22" fill="none" stroke="#c8d1e0" stroke-width="7"/>`); c.add(`<circle cx="88" cy="58" r="22" fill="none" stroke="${OUT}" stroke-width="12"/><circle cx="88" cy="58" r="22" fill="none" stroke="#9db3d6" stroke-width="7"/>`); c.line(60, 62, 72, 60, '#5d7db5', 6); c.rect(38, 44, 12, 8, '#2f5fb0', 2); },
  handcuff: (c) => { c.path('M24 96c-8-30 8-64 40-64 28 0 42 22 38 40', null, 'v', 11); c.path('M24 96c-8-30 8-64 40-64 28 0 42 22 38 40', null, 'v', 5); c.rect(84, 70, 28, 22, '#1f2430', 4); c.line(98, 92, 104, 108, '#1f2430', 5); c.shine('M40 54c6-10 16-14 26-14', .5); },
  basic_key: (c) => { c.circle(40, 54, 20, '#c3c9d3', 'h'); c.rect(52, 50, 54, 10, '#aab1bd', 3); c.rect(88, 60, 8, 14, '#aab1bd', 2); c.rect(100, 60, 8, 10, '#aab1bd', 2); c.circle(40, 54, 7, '#2a2e36'); },
  police_key: (c) => { c.circle(40, 54, 20, '#8aa9dd', 'h'); c.rect(52, 50, 54, 10, '#aab1bd', 3); c.rect(88, 60, 8, 14, '#aab1bd', 2); c.rect(100, 60, 8, 10, '#aab1bd', 2); c.circle(40, 54, 7, '#1f3a73'); },
  beer: bottle({ body: '#b8741a', cap: '#d4af37', label: '#f3e8c4', stripe: '#c0392b' }),
  blowpipe: (c) => { c.rect(26, 62, 52, 22, '#c9822a', 8, 'h'); c.rect(76, 66, 22, 14, '#8b919c', 3); c.path('M98 73c10-8 18-6 22 0-4 8-12 8-22 0z', '#ffb22e'); c.path('M106 73c4-3 7-2 9 0-2 3-5 3-9 0z', '#fff2a8'); c.rect(34, 84, 12, 22, '#6b3f1d', 3); c.shine('M32 68h40', .5); },
  carokit: kit({ color: '#2f6fd1', sym: 'car' }),
  carotool: (c) => { c.path('M30 96l44-44', null, 'v', 14); c.line(30, 96, 74, 52, '#8b919c', 9); c.circle(84, 44, 16, '#aab1bd'); c.rect(60, 22, 22, 18, '#2f6fd1', 4); c.shine('M36 90l34-34', .5); },
  chip: (c) => { c.circle(64, 66, 38, '#d63b3b'); c.add(`<circle cx="64" cy="66" r="30" fill="none" stroke="#fff" stroke-width="7" stroke-dasharray="12 11"/>`); c.circle(64, 66, 20, '#b02525'); c.text(64, 72, '$', 22, '#fff'); c.shine('M38 50c4-8 12-14 22-16', .5); },
  clip: (c) => { c.rect(40, 30, 48, 74, '#4a525e', 5, 'h'); for (const y of [40, 56, 72]) { c.rect(46, y, 36, 10, '#d4af37', 5); } c.rect(40, 96, 48, 10, '#2c313a', 3); c.shine('M46 36v60', .35); },
  magazine: (c) => { c.path('M38 26h44l10 80H46z', '#4a525e', 'h'); for (const y of [34, 50, 66, 82]) c.rect(48, y, 30, 8, '#d4af37', 4); c.rect(42, 100, 54, 10, '#2c313a', 3); c.shine('M48 32l8 64', .35); },
  coke: (c) => { c.path('M18 104c4-30 22-52 46-52s42 22 46 52z', '#f4f4f6'); c.path('M44 90c6-16 14-24 22-24', null, 'v', 3); c.shine('M30 90c4-14 12-26 24-30', .7); },
  coke_pooch: pooch({ fill: '#f4f4f6', kind: 'powder' }),
  cola: can({ color: '#c0392b', band: '#f5f5f5', stripe: '#1c1e24' }),
  corde: (c) => { for (const [r, col] of [[34, '#c9a266'], [26, '#b98d4e'], [18, '#c9a266']]) c.add(`<circle cx="64" cy="68" r="${r}" fill="none" stroke="${OUT}" stroke-width="12"/><circle cx="64" cy="68" r="${r}" fill="none" stroke="${col}" stroke-width="7"/>`); c.circle(64, 68, 8, '#a67c3e'); c.line(88, 90, 106, 106, '#b98d4e', 8); },
  defibrillateur: (c) => { c.rect(22, 38, 84, 66, '#d63b3b', 12, 'h'); c.rect(30, 46, 68, 22, '#1c1e24', 5); c.path('M34 58h12l4-8 6 16 5-10h12', null, 'v', 3); c.add(`<path d="M34 58h12l4-8 6 16 5-10h12" fill="none" stroke="#5fe08a" stroke-width="3" stroke-linecap="round"/>`); c.circle(46, 86, 8, '#fde047'); c.circle(82, 86, 8, '#fde047'); c.path('M48 38v-8h32v8', null, 'v', 5); },
  feuille_coca: leaf('#4fae52', 3),
  firstaidkit: kit({ color: '#e6e8ec', sym: 'cross', symCol: '#d63b3b' }),
  fixkit: kit({ color: '#e08a1e', sym: 'wrench' }),
  repairkit: kit({ color: '#e0562e', sym: 'wrench' }),
  fixtool: (c) => { c.path('M30 100l40-40', null, 'v', 14); c.line(30, 100, 70, 60, '#9aa1ad', 11); c.path('M70 44a18 18 0 1 0 22 22l-12 2-8-8 2-12z', '#bfc5cf'); c.shine('M38 94l30-30', .55); },
  gazbottle: (c) => { c.rect(40, 32, 48, 78, '#e07a1e', 14, 'h'); c.rect(52, 22, 24, 14, '#8b919c', 4); c.rect(58, 12, 12, 12, '#3d4450', 3); c.rect(40, 58, 48, 22, '#f5f5f5', 0, 'h'); c.text(64, 74, 'GAZ', 13, '#c0392b'); c.shine('M46 40v64', .4); },
  gitanes: pack({ color: '#2a55a8', stripe: '#e8eef8', logo: '#2a55a8' }),
  malbora: pack({ color: '#c0392b', stripe: '#f5f5f5', logo: '#c0392b' }),
  grand_cru: bottle({ body: '#2c5a2f', cap: '#8b1c1c', label: '#f1e6c8', stripe: '#8b1c1c', shape: 'tall' }),
  vine: bottle({ body: '#5a1220', cap: '#d4af37', label: '#efe3c6', stripe: '#8b1c1c', shape: 'tall' }),
  vittvin: bottle({ body: '#c9d98a', cap: '#d4af37', label: '#f5f5f5', stripe: '#6a8f2a', shape: 'tall' }),
  grapperaisin: grapes('#7a2fa8'),
  raisin: grapes('#8fc23d'),
  ice: (c) => { c.path('M30 52l40-14 28 18v40l-40 14-28-18z', '#cfeaf7', 'h'); c.path('M30 52l28 18v40M58 70l40-14', null, 'v', 3); c.shine('M38 58l20 12', .8); c.shine('M74 48l16 8', .7); },
  jager: bottle({ body: '#1f3a22', cap: '#d9a21b', label: '#e8731c', stripe: '#1f3a22', shape: 'flask' }),
  jagercerbere: bottle({ body: '#141a16', cap: '#c0392b', label: '#2a2a2a', stripe: '#c0392b', shape: 'flask' }),
  jagerbomb: glassCock({ liquid: '#6b3f1d', garnish: 'none', straw: false }),
  jumelles: (c) => { c.rect(22, 44, 30, 54, '#3a4048', 10, 'h'); c.rect(76, 44, 30, 54, '#3a4048', 10, 'h'); c.rect(50, 58, 28, 16, '#2a2e36', 3); c.circle(37, 98, 12, '#5d7db5'); c.circle(91, 98, 12, '#5d7db5'); c.rect(26, 34, 22, 14, '#2a2e36', 3); c.rect(80, 34, 22, 14, '#2a2e36', 3); c.shine('M28 56v32', .4); },
  yusuf: card({ color: '#2b1f4d', head: '#d4af37', sym: 'star', label: 'LUXE' }),
  grip: (c) => { c.path('M44 26h38l-8 74c0 6-4 10-10 10H52c-6 0-10-4-10-10z', '#3a3f48', 'h'); for (const y of [40, 54, 68, 82]) c.line(50, y, 74, y, '#1c1e24', 2.6); c.shine('M50 32l-4 56', .3); },
  silencieux: (c) => { c.rect(18, 52, 92, 30, '#3a3f48', 8, 'h'); for (const x of [38, 58, 78]) c.line(x, 52, x, 82, '#1c1e24', 2.6); c.ellipse(110, 67, 5, 15, '#14171c'); c.shine('M24 58h70', .4); },
  flashlight: (c) => { c.rect(20, 54, 50, 24, '#3a3f48', 6, 'h'); c.path('M70 46h22l12-12v64L92 86H70z', '#c9ced6', 'h'); c.path('M104 40l16-10M104 66h18M104 92l16 10', null, 'v', 4); c.add(`<path d="M106 40l14-8M106 66h16M106 92l14 8" stroke="#ffe27a" stroke-width="4" stroke-linecap="round"/>`); c.shine('M26 60h36', .4); },
  scope: (c) => { c.rect(16, 54, 96, 20, '#3a3f48', 8, 'h'); c.circle(30, 64, 18, '#2a2e36'); c.circle(30, 64, 11, '#5d9ad6'); c.circle(98, 64, 14, '#2a2e36'); c.circle(98, 64, 8, '#5d9ad6'); c.rect(54, 40, 18, 14, '#3a3f48', 3); c.line(30, 64, 30, 64, OUT, 3); c.shine('M24 58l10 4', .8); },
  jus_coca: glassCock({ liquid: '#4a2a14', garnish: 'none', straw: true, ice: true }),
  jus_raisin: carton({ color: '#7a2fa8', fruit: '#8b3fc0' }),
  jusfruit: carton({ color: '#e0562e', fruit: '#f5a31b' }),
  orange_juice: carton({ color: '#f08a1a', fruit: '#f59a1b' }),
  limonade: bottle({ body: '#d8e86a', cap: '#2f8f3a', label: '#f5f5f5', stripe: '#d4b800', shape: 'tall' }),
  martini: vglass({ liquid: '#eaf3d0', olive: true }),
  meat: (c) => { c.path('M24 70c0-24 24-38 48-34 24 4 38 22 32 44-6 20-30 26-50 20-18-6-30-14-30-30z', '#c0392b', 'h'); c.path('M40 72c4-14 18-20 30-16 10 4 14 14 8 24-8 10-26 12-38-8z', '#e8908a'); c.circle(54, 74, 8, '#f5efe6'); c.shine('M36 56c6-8 16-12 26-12', .5); },
  menthe: leaf('#58c26a', 3),
  meth: (c) => { for (const [x, y, r, rot] of [[44, 76, 14, -20], [70, 84, 16, 14], [88, 64, 12, 30], [60, 56, 14, -8]]) { c.add(`<g transform="rotate(${rot} ${x} ${y})">`); c.path(`M${x - r} ${y}l${r} -${r}l${r} ${r*.4}l${r*.6} ${r}l-${r*.8} ${r}l-${r*1.2} -${r*.3}z`, '#b8e8f5'); c.add('</g>'); } },
  meth_pooch: pooch({ fill: '#a8e0f2' }),
  metreshooter: (c) => { c.rect(14, 54, 100, 14, '#8b5a2b', 3, 'h'); for (const x of [26, 46, 66, 86, 104]) { c.path(`M${x - 8} 28h16l-2 26h-12z`, '#cfe6f2'); c.path(`M${x - 6} 38h12l-1 16h-10z`, '#e8a72c'); } c.rect(14, 68, 100, 10, '#6b3f1d', 3); },
  mixapero: (c) => { c.path('M18 62h92c0 28-18 44-46 44S18 90 18 62z', '#d9d4c5', 'h'); c.ellipse(64, 62, 46, 10, '#efe9d8'); for (const [x, y, col] of [[42, 56, '#e8b04a'], [58, 50, '#e08a1e'], [76, 56, '#e8b04a'], [90, 52, '#c9742c'], [64, 62, '#f2cf6a']]) c.circle(x, y, 8, col); c.shine('M26 76c6 12 18 20 36 22', .5); },
  mojito: glassCock({ liquid: '#bfe8a8', garnish: 'mint', straw: true }),
  opium: (c) => { c.path('M64 30c18 0 26 16 26 32 0 18-10 28-26 28S38 80 38 62c0-16 8-32 26-32z', '#7a4a8e', 'h'); c.path('M52 30h24l-4-8H56z', '#5a2f6e'); c.line(64, 90, 64, 112, '#4f8f3a', 6); c.path('M64 106c-14-2-22-12-24-20M64 100c12-2 20-10 24-18', null, 'v', 3); c.shine('M46 48c2-8 8-14 16-16', .5); },
  opium_pooch: pooch({ fill: '#7a4a8e' }),
  orange: orange,
  oxygen_mask: (c) => { c.path('M34 40c0-10 14-16 30-16s30 6 30 16v26c0 18-14 30-30 30S34 84 34 66z', '#2f8f9a', 'h'); c.rect(46, 52, 36, 24, '#bfe6ec', 10); c.circle(64, 86, 10, '#1f6b75'); c.path('M94 50c18 4 20 30 6 46', null, 'v', 8); c.add(`<path d="M94 50c18 4 20 30 6 46" fill="none" stroke="#2a2e36" stroke-width="5" stroke-linecap="round"/>`); c.shine('M42 40c4-6 12-10 22-10', .55); },
  pepperspray: (c) => { c.rect(44, 40, 40, 70, '#c0392b', 12, 'h'); c.rect(52, 24, 24, 20, '#2a2e36', 5); c.rect(76, 22, 18, 8, '#2a2e36', 3); c.rect(44, 62, 40, 22, '#f5f5f5', 0, 'h'); c.text(64, 78, 'GAZ', 12, '#c0392b'); c.shine('M50 46v58', .4); },
  piluleoubli: (c) => { c.add('<g transform="rotate(-35 64 64)">'); c.rect(28, 48, 72, 32, '#f5f5f5', 16, 'h'); c.path('M64 48h20c8 0 16 7 16 16s-8 16-16 16H64z', '#8a5cd6'); c.add('</g>'); c.shine('M36 70c4-10 12-18 22-20', .7); },
  pomme: apple('#d63b3b'),
  redbull: can({ color: '#c9d4e6', band: '#1f3a8f', stripe: '#d63b3b' }),
  rhum: bottle({ body: '#4a2810', cap: '#c0392b', label: '#efe3c6', stripe: '#8b5a2b', shape: 'square' }),
  rhumcoca: glassCock({ liquid: '#5a3016', garnish: 'lime', straw: true }),
  rhumfruit: glassCock({ liquid: '#f08a1a', garnish: 'orange', straw: true }),
  tabac: leaf('#8a5a2b', 1),
  tabacblond: leaf('#c9a040', 1),
  tabacblondsec: leaf('#d8bb68', 3, false),
  tabacbrun: leaf('#5a3a1a', 1),
  tabacbrunsec: leaf('#7a5230', 3, false),
  tarte_pomme: (c) => { c.path('M16 70c0-24 20-38 48-38s48 14 48 38z', '#e0a24a', 'h'); c.path('M16 70h96l-8 30c-2 6-6 8-12 8H36c-6 0-10-2-12-8z', '#c9822a', 'h'); for (const [x, y] of [[40, 56], [58, 48], [78, 50], [94, 58], [66, 62]]) c.circle(x, y, 7, '#e8c46a'); c.shine('M24 64c6-14 18-22 34-24', .5); },
  teqpaf: shot({ liquid: '#e6b43a', lemon: true }),
  tequila: bottle({ body: '#e0b03a', cap: '#1c1e24', label: '#2f8f3a', stripe: '#f5f5f5', shape: 'flask' }),
  vodka: bottle({ body: '#d6eef8', cap: '#c9ced6', label: '#f5f5f5', stripe: '#2f6fd1', shape: 'tall' }),
  vodkaenergy: glassCock({ liquid: '#e8d23a', garnish: 'none', straw: true }),
  vodkafruit: glassCock({ liquid: '#f0a02a', garnish: 'orange', straw: true }),
  vodkaredbull: glassCock({ liquid: '#e9b8c8', garnish: 'none', straw: true }),
  weed_pooch: pooch({ fill: '#2fa32f' }),
  whisky: bottle({ body: '#c9821a', cap: '#1c1e24', label: '#efe3c6', stripe: '#8b1c1c', shape: 'square' }),
  whiskycoca: glassCock({ liquid: '#5a3016', garnish: 'none', straw: false, tall: false }),
  gym_membership: card({ color: '#1f2430', head: '#e0562e', sym: 'dumbbell', label: 'GYM' }),
  fishingrod: (c) => { c.line(22, 108, 98, 22, '#8b5a2b', 7); c.line(22, 108, 98, 22, '#c9822a', 3.5); c.add(`<path d="M98 22c14 6 18 30 8 52" fill="none" stroke="#9aa1ad" stroke-width="2.4"/>`); c.path('M106 74l-6 8 8 2z', '#c9ced6'); c.circle(40, 90, 10, '#5d7db5'); c.circle(40, 90, 4, '#2a2e36'); },
  macro: (c) => { c.rect(26, 26, 76, 76, '#2a2e36', 10, 'h'); for (const [x, y] of [[40, 40], [64, 40], [88, 40], [40, 64], [64, 64], [88, 64], [40, 88], [64, 88], [88, 88]]) c.rect(x - 8, y - 8, 16, 16, '#5d7db5', 3); },
  bar: fish({ body: '#8aa0b4', belly: '#e8eef2', fin: '#4d6179' }),
  dorade: fish({ body: '#c9ced6', belly: '#f1f3f5', fin: '#d4af37' }),
  lieu: fish({ body: '#5d7a6a', belly: '#dfe8e2', fin: '#3a5246', long: true }),
  raie: (c) => { c.path('M14 70c20-34 44-44 50-44s30 10 50 44c-18 8-34 8-50 40-16-32-32-32-50-40z', '#8a7a68', 'h'); c.path('M64 40c8 18 8 40 0 66', null, 'v', 2.6); c.circle(50, 58, 3, '#111'); c.circle(78, 58, 3, '#111'); c.line(64, 110, 64, 124, '#6a5a48', 4); c.shine('M30 64c10-14 22-22 34-26', .4); },
  sardine: fish({ body: '#9db0c0', belly: '#f1f3f5', fin: '#6a7f92', long: true }),
  saumon: fish({ body: '#f0907a', belly: '#fbd5c8', fin: '#d6604a' }),
  thon: fish({ body: '#2f5a8f', belly: '#cfe0f0', fin: '#d4af37' }),
  requin: (c) => { c.path('M14 78c6-30 40-48 82-44-4 14-6 20-2 30 6 6 18 8 26 6-8 14-24 20-46 20-22 2-48-2-60-12z', '#7a8a9a', 'h'); c.path('M46 24l14 22H34z', '#5a6a7a'); c.path('M30 84c16 8 48 8 76-4-12 14-40 22-76 4z', '#e8eef2'); c.circle(40, 66, 3.5, '#111'); for (const x of [34, 40, 46]) c.path(`M${x} 78l3 5 3-5z`, '#fff', 'v', 1.4); },
  zetony: (c) => { for (const [x, y, col] of [[64, 92, '#2f8f3a'], [64, 78, '#d63b3b'], [64, 64, '#2f6fd1']]) { c.ellipse(x, y, 34, 12, col); c.rect(x - 34, y - 12, 68, 12, col, 0); c.ellipse(x, y - 12, 34, 12, light(col, .12)); } c.ellipse(64, 52, 34, 12, '#f5f5f5'); c.add(`<ellipse cx="64" cy="52" rx="26" ry="8" fill="none" stroke="#d63b3b" stroke-width="3" stroke-dasharray="8 6"/>`); },
  clothing: (c) => { c.path('M40 26c4 10 12 14 24 14s20-4 24-14l28 14-12 22-12-6v50H36V56l-12 6L12 40z', '#d6dce6', 'h'); c.path('M52 26c4 8 8 10 12 10s8-2 12-10', null, 'v', 3); c.shine('M42 50l-2 40', .45); },
  clothes_helmet: (c) => { c.path('M24 78c0-30 18-46 42-46s38 16 38 46z', '#3a4a5e', 'h'); c.path('M24 78h80c8 0 12 4 12 10H12c0-6 4-10 12-10z', '#2a3646', 'h'); c.rect(56, 40, 16, 14, '#d4af37', 3); c.shine('M34 62c2-14 12-24 26-26', .5); },
  code: card({ color: '#e7e1d1', head: '#2f6fd1', sym: 'sign', label: 'CODE' }),
  drive: card({ color: '#e7e1d1', head: '#2f8f3a', sym: 'car', label: 'PERMIS' }),
  drive_bike: card({ color: '#e7e1d1', head: '#e08a1e', sym: 'moto', label: 'MOTO' }),
  drive_truck: card({ color: '#e7e1d1', head: '#6b7480', sym: 'truck', label: 'CAMION' }),
  weapon: card({ color: '#e7e1d1', head: '#c0392b', sym: 'gun', label: 'PPA' }),
  diamond: (c) => { c.path('M36 32h56l22 28-50 52L14 60z', '#7fd4f2', 'h'); c.path('M14 60h100M36 32l28 28 28-28M64 112L42 60M64 112l22-52', null, 'v', 2.8); c.shine('M40 40l10 14', .8); },
  goldbar: (c) => { c.path('M32 56h64l16 40H16z', '#e8b923', 'h'); c.path('M44 40h40l12 16H32z', '#f4d35e', 'h'); c.rect(40, 70, 48, 14, '#d29a14', 3); c.text(64, 82, '999', 11, '#7a5408'); c.shine('M40 46h34', .8); },
  markedbills: stackBills('#c0392b', '#7aa874', true),
  drill: (c) => { c.path('M20 54h60c8 0 10 6 10 12v14c0 6-4 10-10 10H20c-6 0-10-4-10-10V64c0-6 4-10 10-10z', '#e0a21e', 'h'); c.rect(36, 90, 26, 26, '#2a2e36', 6, 'h'); c.rect(88, 62, 16, 18, '#8b919c', 3); c.line(104, 71, 122, 71, '#6a717c', 6); c.line(110, 66, 118, 76, OUT, 2.4); c.shine('M24 62h52', .5); },
  thermite: (c) => { c.rect(36, 44, 56, 66, '#6b7480', 10, 'h'); c.rect(32, 36, 64, 14, '#3a4048', 5); c.rect(36, 70, 56, 18, '#d63b3b', 0); c.text(64, 83, 'HOT', 11, '#fff'); c.path('M64 12c10 10 14 16 8 24-4 6-12 6-16 0-4-8 2-14 8-24z', '#ff9b21'); c.path('M64 22c4 5 6 8 3 12-2 3-6 3-8 0-2-4 1-7 5-12z', '#ffe27a'); c.shine('M42 52v52', .4); },
});
I._default = (c) => { c.path('M20 46l44-20 44 20v50l-44 20-44-20z', '#b98d4e', 'h'); c.path('M20 46l44 20 44-20M64 66v50', null, 'v', 3); c.path('M20 46l44 20v50l-44-20z', '#a67c3e', 'h'); c.text(86, 92, '?', 34, '#fff'); c.shine('M30 52l24 12', .5); };
module.exports = I;
