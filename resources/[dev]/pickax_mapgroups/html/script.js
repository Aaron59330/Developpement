'use strict';
// Fiche d'un lieu (image + description) affichée en haut à gauche quand on sélectionne un blip sur la carte.
const $ = id => document.getElementById(id);
let timer = null;

// Image : lien https:// ou nom de fichier du dossier places/ ; tout le reste est ignoré
const imageUrl = v => {
  v = String(v || '').trim();
  if (/^https:\/\/[^\s"'<>]+$/i.test(v)) return v;
  if (/^[A-Za-z0-9._-]{1,80}$/.test(v) && !v.startsWith('.')) return 'places/' + v;
  return '';
};

function show(d) {
  clearTimeout(timer);
  const url = imageUrl(d.image), pic = $('pic');
  pic.classList.toggle('none', !url);
  pic.onerror = () => pic.classList.add('none');
  pic.src = url || '';
  $('title').textContent = d.title || '';
  $('desc').textContent = d.description || '';
  $('tag').textContent = d.tag || 'Lieu';
  $('more').textContent = d.total > 1 ? `Lieu ${d.index} / ${d.total}  ·  ◄ ► pour changer` : '';
  $('dist').textContent = d.distance != null ? (d.distance >= 1000 ? (d.distance / 1000).toFixed(1) + ' km' : Math.round(d.distance) + ' m') : '';
  const c = $('card'); c.classList.remove('hidden', 'out'); void c.offsetWidth; c.style.animation = 'none'; void c.offsetWidth; c.style.animation = '';
}
function hide() {
  const c = $('card'); if (c.classList.contains('hidden')) return;
  c.classList.add('out'); timer = setTimeout(() => { c.classList.add('hidden'); c.classList.remove('out'); }, 230);
}
window.addEventListener('message', e => { const d = e.data || {}; if (d.action === 'show') show(d); else if (d.action === 'hide') hide(); });
