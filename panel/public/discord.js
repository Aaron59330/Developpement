'use strict';
// ───────── Message Discord : éditeur de messages et d'embeds (comme Discohook) avec aperçu fidèle de Discord, envoi dans les salons par webhook ─────────
const DM_KEY = 'aero_dm_draft_v1';
const DM_COLORS = ['#fdc27d', '#5865f2', '#57f287', '#fee75c', '#eb459e', '#ed4245', '#3ba9ff', '#ffffff'];
const dmEmbed = (o = {}) => Object.assign({ color: '#fdc27d', title: '', description: '', url: '', author: { name: '', url: '', icon_url: '' }, footer: { text: '', icon_url: '' }, thumbnail: '', image: '', fields: [], timestamp: false, _open: true }, o);
const dmNew = () => ({ content: '', username: '', avatar_url: '', embeds: [] });

// ── modèles livrés avec le panel ──
const DM_PRESETS = {
  'Annonce': () => ({ content: '', username: '', avatar_url: '', embeds: [dmEmbed({ color: '#fdc27d', author: { name: 'Annonce officielle', url: '', icon_url: '' }, title: '📢  Titre de l’annonce', description: 'Écris ici ton annonce.\n\n**Gras**, *italique*, __souligné__ et [liens](https://discord.com) fonctionnent comme sur Discord.', footer: { text: 'L’équipe du serveur', icon_url: '' }, timestamp: true })] }),
  'Règlement': () => ({ content: '', username: '', avatar_url: '', embeds: [dmEmbed({ color: '#ed4245', title: '📜  Règlement du serveur', description: 'Merci de lire attentivement avant de jouer.', fields: [{ name: '1 · Respect', value: 'Aucune insulte, aucun harcèlement.', inline: false }, { name: '2 · Roleplay', value: 'Reste dans ton personnage, pas de FreeKill.', inline: false }, { name: '3 · Fair-play', value: 'Aucun cheat ni bug abusé.', inline: false }], footer: { text: 'Le non-respect entraîne des sanctions', icon_url: '' } })] }),
  'Événement': () => ({ content: '@everyone', username: '', avatar_url: '', embeds: [dmEmbed({ color: '#57f287', title: '🎉  Événement ce soir !', description: 'Rejoignez-nous pour une soirée spéciale sur le serveur.', fields: [{ name: '🕗 Heure', value: '21h00', inline: true }, { name: '📍 Lieu', value: 'Place centrale', inline: true }, { name: '🎁 Récompense', value: '10 000 $', inline: true }], footer: { text: 'Inscription sur Discord', icon_url: '' }, timestamp: true })] }),
  'Mise à jour': () => ({ content: '', username: '', avatar_url: '', embeds: [dmEmbed({ color: '#3ba9ff', title: '🛠️  Mise à jour du serveur', description: '**Nouveautés**\n• Ajout de …\n• Nouveau …\n\n**Corrections**\n• Correction de …', footer: { text: 'Version 1.0', icon_url: '' }, timestamp: true })] }),
  'Ouverture': () => ({ content: '', username: '', avatar_url: '', embeds: [dmEmbed({ color: '#fdc27d', title: '🟢  Le serveur est ouvert', description: 'Connecte-toi dès maintenant !\n`connect ton.serveur.fr`', fields: [{ name: 'Joueurs', value: '0 / 64', inline: true }, { name: 'Statut', value: 'En ligne', inline: true }], timestamp: true })] }),
};

// ── conversion éditeur ⇄ message Discord ──
const hexToInt = h => { const m = /^#?([0-9a-f]{6})$/i.exec(h || ''); return m ? parseInt(m[1], 16) : undefined; };
const intToHex = n => '#' + (Number.isInteger(n) ? n : 0xfdc27d).toString(16).padStart(6, '0');
function dmToWire(m) {
  return { content: m.content, username: m.username, avatar_url: m.avatar_url, embeds: m.embeds.map(e => ({
    title: e.title, description: e.description, url: e.url, color: hexToInt(e.color), timestamp: e.timestamp ? true : undefined,
    author: e.author.name ? e.author : undefined, footer: e.footer.text ? e.footer : undefined,
    thumbnail: e.thumbnail ? { url: e.thumbnail } : undefined, image: e.image ? { url: e.image } : undefined, fields: e.fields.filter(f => f.name && f.value) })) };
}
function dmFromWire(d) {
  d = d && typeof d === 'object' ? d : {};
  const e = x => dmEmbed({ color: intToHex(x.color), title: x.title || '', description: x.description || '', url: x.url || '', author: { name: '', url: '', icon_url: '', ...(x.author || {}) }, footer: { text: '', icon_url: '', ...(x.footer || {}) },
    thumbnail: (x.thumbnail && x.thumbnail.url) || '', image: (x.image && x.image.url) || '', fields: (x.fields || []).map(f => ({ name: f.name || '', value: f.value || '', inline: !!f.inline })), timestamp: !!x.timestamp, _open: false });
  return { content: d.content || '', username: d.username || '', avatar_url: d.avatar_url || '', embeds: (Array.isArray(d.embeds) ? d.embeds : []).slice(0, 10).map(e) };
}

// ── markdown Discord → HTML (le texte est échappé AVANT toute transformation) ──
const dmEsc = s => String(s == null ? '' : s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
function dmMd(text) {
  let s = dmEsc(text); const blocks = [], codes = [];
  s = s.replace(/```(?:[a-z]+\n)?([\s\S]*?)```/g, (_, c) => { blocks.push(c.replace(/^\n|\n$/g, '')); return `\u0000B${blocks.length - 1}\u0000`; });
  s = s.replace(/`([^`\n]+)`/g, (_, c) => { codes.push(c); return `\u0000C${codes.length - 1}\u0000`; });
  s = s.replace(/^### (.+)$/gm, '<div class="dm-h3">$1</div>').replace(/^## (.+)$/gm, '<div class="dm-h2">$1</div>').replace(/^# (.+)$/gm, '<div class="dm-h1">$1</div>').replace(/^-# (.+)$/gm, '<div class="dm-sub">$1</div>');
  s = s.replace(/(^|\s)(https?:\/\/[^\s<]+[^\s<.,;:!?)])/g, '$1<a href="$2" target="_blank" rel="noopener noreferrer">$2</a>');
  s = s.replace(/\[([^\]\n]+)\]\((https?:\/\/[^\s)]+)\)/g, '<a href="$2" target="_blank" rel="noopener noreferrer">$1</a>');
  s = s.replace(/\*\*\*(.+?)\*\*\*/g, '<b><i>$1</i></b>').replace(/\*\*(.+?)\*\*/g, '<b>$1</b>').replace(/__(.+?)__/g, '<u>$1</u>').replace(/(^|[^*\w])\*(?!\s)(.+?)\*(?!\*)/g, '$1<i>$2</i>').replace(/(^|[^_\w])_(?!\s)(.+?)_(?![_\w])/g, '$1<i>$2</i>')
    .replace(/~~(.+?)~~/g, '<s>$1</s>').replace(/\|\|(.+?)\|\|/g, '<span class="dm-spoiler">$1</span>');
  s = s.replace(/&lt;@&amp;\d+&gt;/g, '<span class="dm-mention">@rôle</span>').replace(/&lt;@!?\d+&gt;/g, '<span class="dm-mention">@utilisateur</span>').replace(/&lt;#\d+&gt;/g, '<span class="dm-mention">#salon</span>').replace(/@(everyone|here)\b/g, '<span class="dm-mention">@$1</span>');
  s = s.replace(/^(?:&gt; ?.*(?:\n|$))+/gm, m => `<blockquote>${m.replace(/^&gt; ?/gm, '').replace(/\n$/, '')}</blockquote>`);
  s = s.replace(/\n/g, '<br>').replace(/<\/(div|blockquote)><br>/g, '</$1>');
  return s.replace(/\u0000C(\d+)\u0000/g, (_, i) => `<code class="dm-code">${codes[+i]}</code>`).replace(/\u0000B(\d+)\u0000/g, (_, i) => `<pre class="dm-pre">${blocks[+i]}</pre>`);
}
const dmHtml = (tag, cls, html) => { const e = document.createElement(tag); if (cls) e.className = cls; e.innerHTML = html; return e; };
const dmHm = () => new Date().toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });
const dmUrl = u => /^https?:\/\//i.test(u || '') ? u : '';

// ── aperçu : message rendu comme sur Discord ──
function dmPreview(m, chan) {
  const name = m.username.trim() || (curServer() && curServer().server_name) || 'Serveur';
  const av = dmUrl(m.avatar_url);
  const avatar = el('div', { class: 'dm-av', style: av ? `background-image:url("${av.replace(/"/g, '%22')}")` : '' }, av ? null : name.slice(0, 1).toUpperCase());
  const body = el('div', { class: 'dm-body' }, el('div', { class: 'dm-meta' }, el('span', { class: 'dm-name' }, name), el('span', { class: 'dm-tag' }, el('i', {}, '✓'), 'APP'), el('span', { class: 'dm-time' }, `Aujourd’hui à ${dmHm()}`)));
  if (m.content.trim()) body.append(dmHtml('div', 'dm-text', dmMd(m.content)));
  for (const e of m.embeds) {
    const has = e.title || e.description || e.author.name || e.footer.text || e.fields.length || e.image || e.thumbnail;
    if (!has) continue;
    const card = el('div', { class: 'dm-embed', style: `border-left-color:${/^#[0-9a-f]{6}$/i.test(e.color) ? e.color : '#202225'}` });
    const grid = el('div', { class: 'dm-eg' });
    if (e.author.name) grid.append(el('div', { class: 'dm-ea' }, dmUrl(e.author.icon_url) ? el('img', { src: e.author.icon_url, alt: '' }) : null, dmUrl(e.author.url) ? el('a', { href: e.author.url, target: '_blank', rel: 'noopener noreferrer' }, e.author.name) : el('span', {}, e.author.name)));
    if (e.title) grid.append(dmUrl(e.url) ? el('a', { class: 'dm-et link', href: e.url, target: '_blank', rel: 'noopener noreferrer' }, e.title) : el('div', { class: 'dm-et' }, e.title));
    if (e.description) grid.append(dmHtml('div', 'dm-ed', dmMd(e.description)));
    if (e.fields.length) { const f = el('div', { class: 'dm-ef' }); for (const x of e.fields) if (x.name || x.value) f.append(el('div', { class: 'dm-f' + (x.inline ? ' in' : '') }, dmHtml('div', 'dm-fn', dmMd(x.name)), dmHtml('div', 'dm-fv', dmMd(x.value)))); grid.append(f); }
    if (dmUrl(e.image)) grid.append(el('img', { class: 'dm-ei', src: e.image, alt: '' }));
    if (e.footer.text || e.timestamp) grid.append(el('div', { class: 'dm-eft' }, dmUrl(e.footer.icon_url) ? el('img', { src: e.footer.icon_url, alt: '' }) : null, el('span', {}, [e.footer.text, e.timestamp ? `Aujourd’hui à ${dmHm()}` : ''].filter(Boolean).join(' • '))));
    if (dmUrl(e.thumbnail)) grid.append(el('img', { class: 'dm-eth', src: e.thumbnail, alt: '' }));
    card.append(grid); body.append(card);
  }
  const empty = !m.content.trim() && !m.embeds.length;
  return el('div', { class: 'dm-win' },
    el('div', { class: 'dm-bar' }, el('span', { class: 'dm-hash' }, '#'), el('b', {}, chan || 'salon'), el('span', { class: 'dm-sep' }), el('span', { class: 'dm-topic' }, 'Aperçu en direct · rendu fidèle de Discord (thème sombre)')),
    el('div', { class: 'dm-msgs' }, empty ? el('div', { class: 'dm-empty' }, 'Écris un message ou ajoute un embed : l’aperçu apparaît ici.') : el('div', { class: 'dm-msg' }, avatar, body)));
}

PAGES.discord = async function () {
  const s = curServer(); if (!s) return needServer();
  const r = await api('GET', `/api/servers/${s.id}/discord`); if (!r.ok) return el('div', { class: 'card' }, r.error);
  let st = (() => { try { return JSON.parse(sessionStorage.getItem(DM_KEY)); } catch (e) { return null; } })() || {};
  st.msg = st.msg && Array.isArray(st.msg.embeds) ? st.msg : dmNew();
  st.msg.embeds = st.msg.embeds.map(e => dmEmbed(e));
  st.mentions = st.mentions || 'none'; st.channelId = (r.channels.find(c => c.id === st.channelId) || r.channels[0] || {}).id || null; st.tpl = st.tpl || '';
  const m = st.msg; const prevBox = el('div', { class: 'dm-prev' });
  const save = () => { try { sessionStorage.setItem(DM_KEY, JSON.stringify(st)); } catch (e) {} };
  const chanName = () => { const c = r.channels.find(x => x.id === st.channelId); return c ? c.name : 'salon'; };
  const upd = () => { save(); prevBox.replaceChildren(dmPreview(m, chanName())); };
  const redraw = () => { save(); render(); };
  const txt = (label, get, set, o = {}) => { const i = o.area ? el('textarea', { rows: o.rows || 4, maxlength: o.max, value: get(), placeholder: o.ph || '' }) : el('input', { value: get(), maxlength: o.max, placeholder: o.ph || '' }); i.addEventListener('input', () => { set(i.value); if (cnt) cnt.textContent = `${i.value.length} / ${o.max}`; upd(); }); const cnt = o.max && o.area ? el('small', { class: 'muted' }, `${get().length} / ${o.max}`) : null; return el('div', { class: o.cls || '' }, el('label', {}, label), i, cnt); };
  const color = e => el('div', { class: 'dm-colors' }, DM_COLORS.map(c => el('button', { class: 'dm-sw' + (e.color.toLowerCase() === c ? ' on' : ''), style: `background:${c}`, title: c, onclick: () => { e.color = c; redraw(); } })), el('input', { type: 'color', value: e.color, oninput: ev => { e.color = ev.target.value; upd(); }, style: 'width:42px;padding:2px;height:32px' }));

  const embedCard = (e, i) => {
    const body = el('div', { class: 'dm-eb' + (e._open ? '' : ' hidden') },
      el('div', { class: 'dm-row' }, el('div', {}, el('label', {}, 'Couleur de la barre'), color(e))),
      el('div', { class: 'dm-row two' }, txt('Auteur', () => e.author.name, v => e.author.name = v, { max: 256, ph: 'Nom affiché au-dessus du titre' }), txt('Lien de l’auteur', () => e.author.url, v => e.author.url = v, { max: 300, ph: 'https://…' })),
      txt('Icône de l’auteur (URL)', () => e.author.icon_url, v => e.author.icon_url = v, { max: 300, ph: 'https://…/icone.png' }),
      el('div', { class: 'dm-row two' }, txt('Titre', () => e.title, v => e.title = v, { max: 256, ph: 'Titre de l’embed' }), txt('Lien du titre', () => e.url, v => e.url = v, { max: 300, ph: 'https://…' })),
      txt('Description', () => e.description, v => e.description = v, { area: true, rows: 5, max: 4096, ph: 'Texte principal (markdown Discord accepté)' }),
      el('div', { class: 'dm-row two' }, txt('Miniature (URL, en haut à droite)', () => e.thumbnail, v => e.thumbnail = v, { max: 300, ph: 'https://…' }), txt('Grande image (URL)', () => e.image, v => e.image = v, { max: 300, ph: 'https://…' })),
      el('label', {}, 'Champs (', e.fields.length, ' / 25)'),
      e.fields.map((f, k) => el('div', { class: 'dm-field' }, el('div', { class: 'dm-row two' }, txt('Nom', () => f.name, v => f.name = v, { max: 256 }), txt('Valeur', () => f.value, v => f.value = v, { max: 1024 })),
        el('label', { class: 'dm-chk' }, el('input', { type: 'checkbox', checked: f.inline, onchange: ev => { f.inline = ev.target.checked; upd(); } }), ' Sur la même ligne'), el('button', { class: 'btn s d', onclick: () => { e.fields.splice(k, 1); redraw(); } }, el('span', {}, 'Retirer')))),
      el('button', { class: 'btn s', disabled: e.fields.length >= 25, onclick: () => { e.fields.push({ name: '', value: '', inline: false }); redraw(); } }, el('span', {}, '+ Ajouter un champ')),
      el('div', { class: 'dm-row two' }, txt('Pied de page', () => e.footer.text, v => e.footer.text = v, { max: 2048 }), txt('Icône du pied (URL)', () => e.footer.icon_url, v => e.footer.icon_url = v, { max: 300 })),
      el('label', { class: 'dm-chk' }, el('input', { type: 'checkbox', checked: e.timestamp, onchange: ev => { e.timestamp = ev.target.checked; upd(); } }), ' Afficher la date et l’heure d’envoi'));
    return el('div', { class: 'card dm-embedcard' }, el('div', { class: 'dm-eh', style: `border-left:4px solid ${e.color}` },
      el('b', {}, `Embed ${i + 1}`), el('span', { class: 'muted dm-ehs' }, e.title || e.description.slice(0, 40) || '(vide)'), el('div', { class: 'grow' }),
      el('button', { class: 'btn s', title: 'Monter', disabled: i === 0, onclick: () => { [m.embeds[i - 1], m.embeds[i]] = [m.embeds[i], m.embeds[i - 1]]; redraw(); } }, '↑'),
      el('button', { class: 'btn s', title: 'Descendre', disabled: i === m.embeds.length - 1, onclick: () => { [m.embeds[i + 1], m.embeds[i]] = [m.embeds[i], m.embeds[i + 1]]; redraw(); } }, '↓'),
      el('button', { class: 'btn s', title: 'Dupliquer', disabled: m.embeds.length >= 10, onclick: () => { m.embeds.splice(i + 1, 0, dmEmbed(JSON.parse(JSON.stringify(e)))); redraw(); } }, '⧉'),
      el('button', { class: 'btn s', onclick: () => { e._open = !e._open; redraw(); } }, e._open ? 'Replier' : 'Déplier'),
      el('button', { class: 'btn s d', onclick: () => { m.embeds.splice(i, 1); redraw(); } }, 'Supprimer')), body);
  };

  // ── salons ──
  const addChannel = () => ask('Ajouter un salon Discord', [{ name: 'name', label: 'Nom (pour toi, ex : annonces)', placeholder: 'annonces' }, { name: 'url', label: 'Adresse du webhook', placeholder: 'https://discord.com/api/webhooks/…' }], async v => {
    const x = await api('POST', `/api/servers/${s.id}/discord/channels`, v); if (!x.ok) { toast(x.error, 'bad'); return false; } st.channelId = x.id; toast('Salon ajouté', 'ok'); redraw(); }, 'Ajouter');
  const chSel = el('select', { onchange: e => { st.channelId = +e.target.value || null; upd(); } }, r.channels.length ? r.channels.map(c => el('option', { value: c.id, selected: c.id === st.channelId }, '# ' + c.name)) : el('option', { value: '' }, 'Aucun salon : ajoute un webhook'));
  const curCh = r.channels.find(c => c.id === st.channelId);

  // ── modèles ──
  const tplSel = el('select', {}, el('option', { value: '' }, '— Mes modèles —'), r.templates.map(t => el('option', { value: t.id, selected: String(t.id) === String(st.tpl) }, t.name)));
  const presetSel = el('select', { onchange: e => { const f = DM_PRESETS[e.target.value]; if (f) { Object.assign(m, f()); st.tpl = ''; redraw(); } } }, el('option', { value: '' }, '— Modèles du panel —'), Object.keys(DM_PRESETS).map(k => el('option', { value: k }, k)));

  const send = () => {
    if (!st.channelId) return toast('Ajoute puis choisis un salon.', 'bad');
    const wire = dmToWire(m); if (!wire.content.trim() && !wire.embeds.length) return toast('Le message est vide.', 'bad');
    confirmBox('Envoyer le message ?', `Il sera publié dans #${chanName()} sur Discord.${st.mentions === 'all' ? ' Les mentions @everyone / @here sont autorisées.' : ''}`, async () => {
      const x = await api('POST', `/api/servers/${s.id}/discord/send`, { channelId: st.channelId, message: wire, mentions: st.mentions });
      toast(x.ok ? `Message envoyé dans #${x.channel}` : x.error, x.ok ? 'ok' : 'bad'); });
  };
  const json = el('textarea', { rows: 10, class: 'dm-json', spellcheck: 'false' }); json.value = JSON.stringify(JSON.parse(JSON.stringify(dmToWire(m))), null, 2);

  upd();
  return el('div', {}, head('Message Discord', el('button', { class: 'btn p', onclick: send }, el('span', {}, 'Envoyer sur Discord'))),
    el('p', { class: 'muted', style: 'margin-bottom:12px' }, 'Compose un message avec des embeds comme sur Discohook, vois le rendu exact de Discord, puis envoie-le dans le salon de ton choix. Les adresses de webhooks restent sur le serveur du panel et ne sont jamais réaffichées.'),
    el('div', { class: 'dm-wrap' },
      el('div', { class: 'dm-edit' },
        el('div', { class: 'card' }, el('h2', {}, 'Salon d’envoi'), el('div', { class: 'row' }, chSel, el('button', { class: 'btn', onclick: addChannel }, el('span', {}, '+ Salon')), curCh ? el('button', { class: 'btn d', onclick: () => confirmBox('Retirer ce salon ?', `« # ${curCh.name} » sera retiré du panel (le webhook reste sur Discord).`, async () => { await api('DELETE', `/api/servers/${s.id}/discord/channels/${curCh.id}`); redraw(); }, true) }, el('span', {}, 'Retirer')) : null),
          curCh ? el('small', { class: 'muted' }, 'Webhook : ', curCh.hint) : el('small', { class: 'muted' }, 'Discord → Paramètres du salon → Intégrations → Webhooks → Nouveau webhook → Copier l’URL.')),
        el('div', { class: 'card' }, el('h2', {}, 'Modèles'), el('div', { class: 'row' }, presetSel, tplSel),
          el('div', { class: 'row', style: 'margin-top:8px' },
            el('button', { class: 'btn s', onclick: async () => { if (!tplSel.value) return toast('Choisis un modèle.', 'bad'); const x = await api('GET', `/api/servers/${s.id}/discord/templates/${tplSel.value}`); if (!x.ok) return toast(x.error, 'bad'); Object.assign(m, dmFromWire(x.data)); st.tpl = x.id; redraw(); } }, 'Charger'),
            el('button', { class: 'btn s', onclick: () => ask('Enregistrer le modèle', [{ name: 'name', label: 'Nom du modèle', value: (r.templates.find(t => String(t.id) === String(tplSel.value)) || {}).name || '' }], async v => { const x = await api('POST', `/api/servers/${s.id}/discord/templates`, { name: v.name, data: dmToWire(m) }); if (!x.ok) { toast(x.error, 'bad'); return false; } st.tpl = x.id; toast('Modèle enregistré', 'ok'); redraw(); }, 'Enregistrer') }, 'Enregistrer'),
            el('button', { class: 'btn s d', onclick: async () => { if (!tplSel.value) return; await api('DELETE', `/api/servers/${s.id}/discord/templates/${tplSel.value}`); st.tpl = ''; redraw(); } }, 'Supprimer'),
            el('button', { class: 'btn s', onclick: () => { Object.assign(m, dmNew()); st.tpl = ''; redraw(); } }, 'Nouveau message'))),
        el('div', { class: 'card' }, el('h2', {}, 'Message'),
          el('div', { class: 'dm-row two' }, txt('Nom affiché (facultatif)', () => m.username, v => m.username = v, { max: 80, ph: 'Par défaut : le nom du webhook' }), txt('Avatar (URL, facultatif)', () => m.avatar_url, v => m.avatar_url = v, { max: 300, ph: 'https://…' })),
          txt('Texte du message', () => m.content, v => m.content = v, { area: true, rows: 4, max: 2000, ph: 'Texte au-dessus des embeds' }),
          el('label', {}, 'Mentions'), el('select', { onchange: e => { st.mentions = e.target.value; save(); } }, [['none', 'Aucune mention (sûr)'], ['users', 'Autoriser les mentions de membres et de rôles'], ['all', 'Autoriser aussi @everyone et @here']].map(([v, l]) => el('option', { value: v, selected: v === st.mentions }, l)))),
        m.embeds.map(embedCard),
        el('button', { class: 'btn', disabled: m.embeds.length >= 10, onclick: () => { m.embeds.push(dmEmbed()); redraw(); } }, el('span', {}, `+ Ajouter un embed (${m.embeds.length} / 10)`)),
        el('div', { class: 'card' }, el('h2', {}, 'JSON (import / export)'), el('p', { class: 'muted', style: 'margin:-6px 0 8px' }, 'Compatible avec Discohook : copie le message ici ou colle un JSON pour le charger.'), json,
          el('div', { class: 'row', style: 'margin-top:8px' }, el('button', { class: 'btn s', onclick: () => { try { const d = JSON.parse(json.value); Object.assign(m, dmFromWire(d)); redraw(); toast('JSON chargé', 'ok'); } catch (e) { toast('JSON invalide : ' + e.message, 'bad'); } } }, 'Charger ce JSON'), el('button', { class: 'btn s', onclick: () => copy(JSON.stringify(dmToWire(m), null, 2)) }, 'Copier le JSON')))),
      el('div', { class: 'dm-side' }, el('div', { class: 'dm-sticky' }, el('div', { class: 'dm-label' }, el('span', { class: 'dm-dot' }), 'Aperçu Discord'), prevBox,
        el('div', { class: 'row', style: 'margin-top:12px' }, el('button', { class: 'btn p', onclick: send }, el('span', {}, 'Envoyer sur Discord')), el('span', { class: 'muted' }, st.channelId ? `→ #${chanName()}` : ''))))));
};
