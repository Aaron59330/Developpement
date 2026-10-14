// Générateur d'icônes d'objets : style « illustration à contour sombre », ombrage doux, reflet — cohérent avec les images existantes.
const OUT = '#1c1e24', SW = 3.4;
function hex2rgb(h) { h = h.replace('#', ''); return [0, 2, 4].map(i => parseInt(h.slice(i, i + 2), 16)); }
function mix(c, t, a) { const x = hex2rgb(c), y = hex2rgb(t); return '#' + x.map((v, i) => Math.round(v + (y[i] - v) * a).toString(16).padStart(2, '0')).join(''); }
const light = (c, a = .35) => mix(c, '#ffffff', a), dark = (c, a = .35) => mix(c, '#000000', a);
let gid = 0;
function grad(c) { const id = 'g' + (gid++); return { id, def: `<linearGradient id="${id}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${light(c, .3)}"/><stop offset=".55" stop-color="${c}"/><stop offset="1" stop-color="${dark(c, .28)}"/></linearGradient>` }; }
function gradH(c) { const id = 'g' + (gid++); return { id, def: `<linearGradient id="${id}" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="${dark(c, .22)}"/><stop offset=".4" stop-color="${light(c, .28)}"/><stop offset="1" stop-color="${dark(c, .3)}"/></linearGradient>` }; }
// Forme dégradée avec contour : shape = fonction (attrs) => balise
class Ctx {
  constructor() { this.defs = ''; this.body = ''; }
  fill(c, dir = 'v') { const g = dir === 'h' ? gradH(c) : grad(c); this.defs += g.def; return `url(#${g.id})`; }
  add(s) { this.body += s; return this; }
  rect(x, y, w, h, c, r = 6, dir = 'v') { return this.add(`<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${r}" fill="${this.fill(c, dir)}" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>`); }
  circle(cx, cy, r, c, dir = 'v') { return this.add(`<circle cx="${cx}" cy="${cy}" r="${r}" fill="${this.fill(c, dir)}" stroke="${OUT}" stroke-width="${SW}"/>`); }
  ellipse(cx, cy, rx, ry, c, dir = 'v') { return this.add(`<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" fill="${this.fill(c, dir)}" stroke="${OUT}" stroke-width="${SW}"/>`); }
  path(d, c, dir = 'v', sw = SW) { return this.add(`<path d="${d}" fill="${c ? this.fill(c, dir) : 'none'}" stroke="${OUT}" stroke-width="${sw}" stroke-linejoin="round" stroke-linecap="round"/>`); }
  line(x1, y1, x2, y2, c = OUT, w = SW) { return this.add(`<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="${c}" stroke-width="${w}" stroke-linecap="round"/>`); }
  shine(d, a = .38) { return this.add(`<path d="${d}" fill="none" stroke="#fff" stroke-opacity="${a}" stroke-width="3.4" stroke-linecap="round"/>`); }
  text(x, y, t, size = 14, c = '#fff', w = 800) { return this.add(`<text x="${x}" y="${y}" text-anchor="middle" font-family="Arial Black,Arial,sans-serif" font-weight="${w}" font-size="${size}" fill="${c}">${t}</text>`); }
  svg() { return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" width="128" height="128"><defs><filter id="sh" x="-20%" y="-20%" width="140%" height="150%"><feDropShadow dx="0" dy="3" stdDeviation="2.2" flood-color="#000" flood-opacity=".38"/></filter>${this.defs}</defs><g filter="url(#sh)">${this.body}</g></svg>`; }
}
module.exports = { Ctx, light, dark, mix, OUT, SW };
