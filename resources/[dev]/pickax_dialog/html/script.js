const $ = id => document.getElementById(id);
let timer = null, full = '', typing = false, shown = false;
const post = (name, data) => fetch(`https://${GetParentResourceName()}/${name}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data || {}) }).catch(() => {});

function finishTyping() {
  clearInterval(timer); typing = false;
  $('txt').textContent = full; $('txt').classList.remove('typing'); $('btns').classList.remove('wait');
  post('typed');
}
function show(d) {
  full = String(d.text || ''); shown = true;
  $('name').textContent = d.name || 'Interlocuteur';
  $('okLbl').textContent = d.accept || 'Accepter'; $('noLbl').textContent = d.refuse || 'Refuser';
  $('txt').textContent = ''; $('txt').classList.add('typing'); $('btns').classList.add('wait');
  $('dlg').classList.remove('hidden');
  let i = 0; typing = true; clearInterval(timer);
  const speed = Math.max(5, Number(d.speed) || 28);
  timer = setInterval(() => { i++; $('txt').textContent = full.slice(0, i); if (i >= full.length) finishTyping(); }, speed);
}
function hide() { shown = false; clearInterval(timer); $('dlg').classList.add('hidden'); }
function answer(ok) { if (!shown) return; hide(); post('choice', { accept: ok }); }

window.addEventListener('message', e => { const d = e.data || {}; if (d.action === 'show') show(d); else if (d.action === 'hide') hide(); });
$('ok').addEventListener('click', () => answer(true));
$('no').addEventListener('click', () => answer(false));
$('txt').addEventListener('click', () => { if (typing) finishTyping(); });
document.addEventListener('keydown', e => {
  if (!shown) return;
  if (e.key === 'Enter' || e.key === 'e' || e.key === 'E') { e.preventDefault(); typing ? finishTyping() : answer(true); }
  else if (e.key === 'Backspace' || e.key === 'Escape') { e.preventDefault(); answer(false); }
});
