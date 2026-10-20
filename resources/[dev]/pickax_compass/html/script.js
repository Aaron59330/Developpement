let PPD = 4;                      // pixels par degré
let W = 460;                      // largeur visible (px)
const NAMES = { 0: 'N', 45: 'NE', 90: 'E', 135: 'SE', 180: 'S', 225: 'SO', 270: 'O', 315: 'NO' };
const track = document.getElementById('track');
const root = document.getElementById('compass');
let curH = 0, street = true;

// trois tours de graduation : le défilement boucle sans coupure
function build() {
  let html = '';
  for (let turn = -1; turn <= 1; turn++) {
    for (let d = 0; d < 360; d += 5) {
      const x = (d + turn * 360 + 360) * PPD;
      const name = NAMES[d];
      const cls = ['t', name ? 'c' : (d % 15 === 0 ? 'm' : ''), d === 0 ? 'n' : ''].join(' ');
      const label = name ? name : (d % 30 === 0 && PPD >= 4 ? d : '');
      html += `<div class="${cls}" style="left:${x}px"><i></i>${label !== '' ? `<span>${label}</span>` : ''}</div>`;
    }
  }
  track.innerHTML = html;
  track.style.width = (1080 * PPD) + 'px';
  setHeading(curH);
}
function setHeading(h) { curH = h; track.style.transform = `translateX(${W / 2 - (h + 360) * PPD}px)`; }
build();

window.addEventListener('message', e => {
  const m = e.data || {};
  if (m.a === 'cfg') {
    const compact = m.layout !== 'top';
    document.body.classList.toggle('compact', compact);
    street = m.street !== false;
    if (compact) {
      W = Number(m.width) || 210; PPD = 3;
      root.style.setProperty('--cl', m.left || '19.6vw'); root.style.setProperty('--cb', m.bottom || '3.4vh'); root.style.setProperty('--cw', W + 'px');
    } else { W = 460; PPD = 4; }
    build();
  }
  else if (m.a === 'show') root.classList.toggle('hidden', !m.v);
  else if (m.a === 'h') {
    setHeading(m.h);
    document.getElementById('deg').textContent = m.h;
    const w = street ? [m.street, m.zone].filter(Boolean).join(' · ') : '';
    document.getElementById('where').textContent = w;
  }
});
