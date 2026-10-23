/* ═══════════ Démarrage : pont NUI ↔ jeu ═══════════ */
async function bootPhone(data) {
  S.me = data.me; S.settings = data.settings || {}; S.hasPin = !!data.hasPin; S.installed = data.installed || []; S.catalog = data.catalog || [];
  S.battery = data.battery == null ? 100 : data.battery; S.config = data.config || {}; S.charging = false;
  S.lines = S.config.lines || []; S.contactList = data.contacts || []; S.contacts = {}; S.contactList.forEach(c => { S.contacts[String(c.number).replace(/\D/g, '')] = c; });
  if (!S.settings.notifOff) S.settings.notifOff = {}; if (!S.settings.badgeOff) S.settings.badgeOff = {};
  S.locked = true; S.notifs = []; S.badges = {}; OS.running = {}; OS.current = null; OS.order = [];
  OS.fit(); OS.build();
  await pollGameTime(); OS.drawStatus(); OS.drawLock();
  Messages.load(); rpc('mailUnread').then(n => { S.unreadMail = n || 0; OS.setBadge('mail', S.unreadMail); });
  Bus.emit('boot');
}

window.addEventListener('message', async (e) => {
  const d = e.data || {};
  switch (d.action) {
    case 'init': await bootPhone(d.data); break;
    case 'open': OS.show(); break;
    case 'close': OS.hide(); break;
    case 'push': Bus.emit('push:' + d.event, d.data); break;
  }
});

document.addEventListener('keydown', e => {
  if (e.key !== 'Escape') return;
  const a = document.activeElement;
  if (a && /^(INPUT|TEXTAREA|SELECT)$/.test(a.tagName)) { a.blur(); return; }
  if (!S.open) return;
  if (OS.back()) return;
  post('close');
});

setInterval(() => { if (!S.me) return; OS.drawStatus(); OS.tickLock(); OS.tickAnalog(); }, 1000);
setInterval(() => { if (S.me) pollGameTime(); }, 6000);
setInterval(() => { Calls.tick && Calls.tick(); }, 1000);

if (!IN_GAME && !window.__MOCK) document.body.innerHTML = '<div style="color:#fff;padding:20px;font-family:sans-serif">Interface Aura : à ouvrir depuis le jeu.</div>';
