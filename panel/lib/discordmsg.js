// Message Discord (style Discohook) : validation et nettoyage d'un message avant envoi par webhook, selon les limites de Discord.
const URL_RE = /^https?:\/\/[^\s<>"'\\]{1,500}$/i;
const HOOK_RE = /^https:\/\/(?:(?:ptb|canary)\.)?(?:discord|discordapp)\.com\/api\/webhooks\/\d+\/[\w-]+$/;
const str = (v, max) => typeof v === 'string' ? v.replace(/\r\n/g, '\n').slice(0, max) : '';
const url = v => { v = typeof v === 'string' ? v.trim() : ''; return v && URL_RE.test(v) ? v : ''; };
const httpsUrl = v => { v = url(v); return /^https:\/\//i.test(v) ? v : ''; };

// → { message } prêt à envoyer, ou { error }. opts.mentions : 'none' | 'users' | 'all'
function clean(input, opts = {}) {
  if (!input || typeof input !== 'object') return { error: 'Message invalide' };
  const out = {};
  const content = str(input.content, 2000); if (content.trim()) out.content = content;
  const username = str(input.username, 80).trim(); if (username) out.username = username;
  const avatar = httpsUrl(input.avatar_url); if (avatar) out.avatar_url = avatar;
  if (input.tts === true) out.tts = true;
  const embeds = [];
  let total = 0;
  for (const e of (Array.isArray(input.embeds) ? input.embeds : []).slice(0, 10)) {
    if (!e || typeof e !== 'object') continue;
    const o = {};
    const title = str(e.title, 256); if (title.trim()) { o.title = title; total += title.length; }
    const desc = str(e.description, 4096); if (desc.trim()) { o.description = desc; total += desc.length; }
    const u = httpsUrl(e.url); if (u) o.url = u;
    if (Number.isInteger(e.color) && e.color >= 0 && e.color <= 0xffffff) o.color = e.color;
    if (e.timestamp) { const t = new Date(e.timestamp === true ? Date.now() : e.timestamp); if (!isNaN(t)) o.timestamp = t.toISOString(); }
    if (e.author && typeof e.author === 'object') { const n = str(e.author.name, 256); if (n.trim()) { o.author = { name: n }; total += n.length; const au = httpsUrl(e.author.url), ai = httpsUrl(e.author.icon_url); if (au) o.author.url = au; if (ai) o.author.icon_url = ai; } }
    if (e.footer && typeof e.footer === 'object') { const n = str(e.footer.text, 2048); if (n.trim()) { o.footer = { text: n }; total += n.length; const fi = httpsUrl(e.footer.icon_url); if (fi) o.footer.icon_url = fi; } }
    const th = e.thumbnail && httpsUrl(e.thumbnail.url); if (th) o.thumbnail = { url: th };
    const im = e.image && httpsUrl(e.image.url); if (im) o.image = { url: im };
    const fields = [];
    for (const f of (Array.isArray(e.fields) ? e.fields : []).slice(0, 25)) {
      const n = str(f && f.name, 256), v = str(f && f.value, 1024);
      if (n.trim() && v.trim()) { fields.push({ name: n, value: v, inline: f.inline === true }); total += n.length + v.length; }
    }
    if (fields.length) o.fields = fields;
    if (Object.keys(o).length) embeds.push(o);
  }
  if (embeds.length) out.embeds = embeds;
  if (!out.content && !out.embeds) return { error: 'Le message est vide : ajoute du texte ou un embed.' };
  if (total > 6000) return { error: `Les embeds dépassent la limite de Discord (${total} / 6000 caractères au total).` };
  const parse = opts.mentions === 'all' ? ['users', 'roles', 'everyone'] : opts.mentions === 'users' ? ['users', 'roles'] : [];
  out.allowed_mentions = { parse };
  return { message: out };
}

module.exports = { clean, HOOK_RE, okHook: u => typeof u === 'string' && HOOK_RE.test(u) };
