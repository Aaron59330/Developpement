'use strict';
const $ = id => document.getElementById(id);
const esc = s => String(s == null ? '' : s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const post = (n, d) => fetch(`https://${typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'pickax_medical'}/${n}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(d || {}) }).then(r => r.json()).catch(() => ({}));
let D = null, sel = null, tab = 'exam', TR = null;
const toast = (m, bad) => { const t = $('toast'); t.textContent = m; t.style.borderColor = bad ? 'var(--bad)' : 'var(--ok)'; t.classList.remove('hidden'); clearTimeout(toast.t); toast.t = setTimeout(() => t.classList.add('hidden'), 3200); };
const bcol = b => b >= 70 ? '#7bd88f' : b >= 40 ? '#f1c40f' : '#f28b82';

const SHAPES = {
  head: '<circle class="z" data-z="head" cx="105" cy="32" r="22"/>',
  torso: '<path class="z" data-z="torso" d="M72 62 h66 l8 78 h-82 z"/>',
  larm: '<path class="z" data-z="larm" d="M70 64 l-26 18 l-14 70 l20 4 l14 -62 l12 -14 z"/>',
  rarm: '<path class="z" data-z="rarm" d="M140 64 l26 18 l14 70 l-20 4 l-14 -62 l-12 -14 z"/>',
  lleg: '<path class="z" data-z="lleg" d="M72 142 h32 l-4 118 h-26 z"/>',
  rleg: '<path class="z" data-z="rleg" d="M106 142 h32 l-2 118 h-26 z"/>'
};
function bodySvg(zones) {
  let h = '<svg class="body" viewBox="0 0 210 270">';
  Object.keys(SHAPES).forEach(k => { const z = zones[k]; h += SHAPES[k].replace('class="z"', `class="z ${z ? 'l' + z.lvl : ''} ${sel === k ? 'sel' : ''}"`); });
  return h + '</svg>';
}

function renderExam() {
  const p = D.patient, cfg = D.cfg, sup = D.supplies, zn = Object.keys(cfg.zones);
  $('ttl').textContent = p.name; $('sub').textContent = p.dead ? 'En arrêt cardio-respiratoire' : `Pouls ${p.pulse} bpm`;
  const inj = zn.filter(k => p.zones[k]);
  if (sel && !p.zones[sel]) sel = null;
  const z = sel && p.zones[sel];
  const treatBtns = z ? Object.keys(cfg.treatments).map(k => { const tr = cfg.treatments[k]; const lv = z.lvl; const ok = (tr.only === 'bleeding' && z.bleed) || (tr.only === 'wound' && lv === 2) || (tr.only === 'fracture' && lv === 3 && z.kind === 'fracture') || (tr.only === 'severe' && lv === 3 && z.kind !== 'fracture' && z.kind !== 'à explorer');
    return `<button class="btn sm" data-a="treat" data-k="${k}" ${ok && sup[k] > 0 ? '' : 'disabled'} title="${ok ? '' : 'Ne convient pas'}">${esc(tr.label)} (${sup[k]})</button>`; }).join('') : '';
  $('body').innerHTML = `<div class="cols"><div><div class="card">${bodySvg(p.zones)}<div class="vit"><div><small>Sang</small><b style="color:${bcol(p.blood)}">${p.blood} %</b></div><div><small>Pouls</small><b>${p.pulse}</b></div></div>
      <div class="bar"><i style="width:${p.blood}%;background:${bcol(p.blood)}"></i></div></div></div>
    <div style="overflow:auto;padding-right:4px">
      ${p.dead ? `<div class="card" style="border-color:var(--bad)"><b class="bad">Arrêt cardio-respiratoire</b><div class="row"><button class="btn" data-a="cpr">Massage cardiaque (RCR)</button></div></div>` : ''}
      <h4>Blessures ${inj.length ? '(' + inj.length + ')' : ''}</h4>
      ${inj.length ? inj.map(k => { const v = p.zones[k], c = ['', '#8a6d2f', '#c0392b', '#7a1020'][v.lvl]; return `<div class="inj ${sel === k ? 'sel' : ''}" data-z="${k}"><span class="dot" style="background:${c}"></span><div style="flex:1"><b>${esc(cfg.zones[k])}</b> <span class="mut">— ${esc(v.kind)}${v.bleed ? ' · <span class="bad">saigne</span>' : ''}</span></div></div>`; }).join('') : '<div class="mut">Aucune blessure visible.</div>'}
      ${z ? `<div class="row">${treatBtns}</div>` : '<div class="mut" style="margin-top:6px">Sélectionne une blessure (ou une zone du corps) pour la soigner.</div>'}
      <h4>Examens</h4><div class="row"><button class="btn ghost sm" data-a="xray">Radio${cfg.hospital ? '' : ' (hôpital)'}</button><button class="btn ghost sm" data-a="blood">Prise de sang</button><button class="btn ghost sm" data-a="donate">Prélever une poche</button><button class="btn ghost sm" data-a="transfuse" ${sup.blood_bag > 0 ? '' : 'disabled'}>Transfuser (${sup.blood_bag})</button></div>
      <h4>Dossier médical</h4>${D.records.length ? D.records.map(r => `<div class="rec"><span>${esc(r.text)}</span><span class="mut">${esc(r.at)}</span></div>`).join('') : '<div class="mut">Dossier vide.</div>'}
    </div></div>`;
  $('body').querySelectorAll('[data-z]').forEach(e => e.onclick = () => { sel = e.dataset.z; if (!p.zones[sel]) return toast('Aucune blessure ici.'); renderExam(); });
  $('body').querySelectorAll('[data-a]').forEach(b => b.onclick = () => act(b.dataset.a, b.dataset.k));
}
async function act(a, k) {
  let r;
  if (a === 'treat') r = await post('treat', { zone: sel, kind: k });
  else if (a === 'cpr') r = await post('cpr');
  else if (a === 'xray') r = await post('xray');
  else if (a === 'blood') r = await post('bloodTest');
  else if (a === 'donate') r = await post('donate');
  else if (a === 'transfuse') r = await post('transfuse');
}
function renderTriage() {
  const d = TR;
  $('ttl').textContent = 'Triage en catastrophe'; $('sub').textContent = `Précision : ${d.score.ok} / ${d.score.total} étiquettes correctes`;
  $('body').innerHTML = d.list.length ? d.list.map(p => `<div class="tg"><div><b>${esc(p.name)}</b> <span class="mut">${p.dist} m · ${p.injuries} blessure(s)</span><div class="bar"><i style="width:${p.blood}%;background:${bcol(p.blood)}"></i></div></div><div class="mut">${p.dead ? '<span class="bad">arrêt</span>' : 'sang ' + p.blood + ' %'}</div><div class="mut">${p.tag ? 'étiqueté' : 'non trié'}</div>
    <div class="row" style="margin:0">${Object.keys(d.tags).map(t => `<button class="tag ${t} ${p.tag === t ? '' : 'off'}" data-id="${p.id}" data-t="${t}" title="${esc(d.tags[t])}">${({ red: 'Rouge', orange: 'Orange', green: 'Vert', black: 'Noir' })[t]}</button>`).join('')}<button class="btn sm ghost" data-open="${p.id}">Examiner</button></div></div>`).join('') : '<div class="mut">Aucun blessé autour de toi.</div>';
  $('body').querySelectorAll('.tag').forEach(b => b.onclick = async () => { const r = await post('triageTag', { id: Number(b.dataset.id), tag: b.dataset.t }); if (r && r.ok) { toast(r.correct ? 'Bon choix de priorité.' : `Priorité attendue : ${TR.tags[r.expected]}`, !r.correct); TR.score = r.score; const l = await post('triageList'); if (l && l.ok) { TR = l; renderTriage(); } } });
  $('body').querySelectorAll('[data-open]').forEach(b => b.onclick = () => { tab = 'exam'; setTabs(); post('openPatient', { id: Number(b.dataset.open) }); });
}
function setTabs() { document.querySelectorAll('.tab').forEach(t => t.classList.toggle('on', t.dataset.t === tab)); }
document.querySelectorAll('.tab').forEach(t => t.onclick = async () => { tab = t.dataset.t; setTabs(); if (tab === 'triage') { const l = await post('triageList'); if (l && l.ok) { TR = l; renderTriage(); } } else if (D) renderExam(); });
$('x').onclick = () => post('close');
document.addEventListener('keydown', e => { if (e.key === 'Escape') post('close'); });
window.addEventListener('message', e => {
  const m = e.data || {};
  if (m.action === 'exam') { D = m.data; $('win').classList.remove('hidden'); if (m.first) { tab = 'exam'; sel = null; } setTabs(); if (tab === 'exam') renderExam(); }
  else if (m.action === 'triage') { TR = m.data; tab = 'triage'; $('win').classList.remove('hidden'); setTabs(); renderTriage(); }
  else if (m.action === 'close') $('win').classList.add('hidden');
});
