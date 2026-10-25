// Poste le message « tarifs » (Components V2) via un webhook Discord.
// Usage : WEBHOOK_URL="https://discord.com/api/webhooks/ID/TOKEN" node send.js   (Node 18+, après node build-images.js)
// Ajoute DRY_RUN=1 pour afficher le JSON sans rien envoyer.
const fs = require('fs'), path = require('path');
const cfg = JSON.parse(fs.readFileSync(path.join(__dirname, 'config.json'), 'utf8'));
const img = n => ({ type: 12, items: [{ media: { url: 'attachment://' + n } }] });
const sep = { type: 14, divider: true, spacing: 1 };
const files = [];
const use = n => { if (!files.includes(n)) files.push(n); return n; };

const comps = [];
for (const f of cfg.formules) {
  comps.push(img(use(`banner_${f.id}.png`)));
  comps.push({ type: 9, components: [{ type: 10, content: f.lignes.map(l => '• ' + l).join('\n') }],
    accessory: { type: 11, media: { url: 'attachment://' + use(`price_${f.id}.png`) } } });
}
comps.push(img(use('banner_infos.png')));
comps.push({ type: 9, components: [{ type: 10, content: cfg.infos.texte }],
  accessory: { type: 2, style: 5, label: 'Tickets', emoji: { name: '🎫' }, url: cfg.lienTickets } });

const accent = parseInt(cfg.couleur.replace('#', ''), 16);
const payload = { flags: 1 << 15, components: [{ type: 17, accent_color: accent, components: comps }],
  attachments: files.map((n, i) => ({ id: i, filename: n })) };

if (process.env.DRY_RUN) { console.log(JSON.stringify(payload, null, 2)); process.exit(0); }
const url = process.env.WEBHOOK_URL;
if (!url) { console.error('WEBHOOK_URL manquant'); process.exit(1); }
const fd = new FormData();
fd.append('payload_json', JSON.stringify(payload));
files.forEach((n, i) => fd.append(`files[${i}]`, new Blob([fs.readFileSync(path.join(__dirname, 'images', n))], { type: 'image/png' }), n));
fetch(url + (url.includes('?') ? '&' : '?') + 'with_components=true&wait=true', { method: 'POST', body: fd })
  .then(async r => { console.log(r.status, (await r.text()).slice(0, 300)); });
