/* ═══════════ Musique (flux audio) ═══════════ */
const MusicState = { playing: false, title: '', idx: -1, list: [] };
window.MusicState = MusicState;
const Music = {
  audio: new Audio(), custom: [],
  init() {
    this.audio.preload = 'none'; this.audio.crossOrigin = 'anonymous';
    this.audio.addEventListener('ended', () => this.next());
    this.audio.addEventListener('error', () => { MusicState.playing = false; OS.drawIsland(); if (MusicState.title) Toast('Flux indisponible', 'warning'); this.refresh(); });
  },
  tracks() { return [...(S.config.radios || []).map(r => ({ name: r.name, url: r.url, color: r.color, radio: true })), ...this.custom.map(c => ({ name: c.name, url: c.url, color: '#8e8e93' }))]; },
  play(i) {
    const t = this.tracks()[i]; if (!t) return;
    MusicState.idx = i; MusicState.title = t.name; MusicState.playing = true;
    this.audio.src = t.url; this.audio.volume = Math.min(1, (S.settings.volume == null ? 70 : S.settings.volume) / 100);
    this.audio.play().catch(() => { MusicState.playing = false; this.refresh(); });
    OS.drawIsland(); this.refresh();
  },
  toggle() { if (MusicState.idx < 0) return this.play(0); if (MusicState.playing) { this.audio.pause(); MusicState.playing = false; } else { this.audio.play(); MusicState.playing = true; } OS.drawIsland(); this.refresh(); },
  next() { const n = this.tracks().length; if (n) this.play((MusicState.idx + 1) % n); },
  prev() { const n = this.tracks().length; if (n) this.play((MusicState.idx - 1 + n) % n); },
  async open(ctx) {
    this.ctx = ctx; this.custom = (await rpc('kvGet', 'playlist')) || [];
    const pg = Page({ title: 'Musique', right: [{ icon: 'plus', onclick: () => this.add() }] }); this.pg = pg; ctx.root(pg); this.refresh();
  },
  refresh() {
    const pg = this.pg; if (!pg || !pg.body.isConnected) return; clear(pg.body);
    const t = this.tracks();
    if (MusicState.idx >= 0) {
      const cur = t[MusicState.idx] || {};
      pg.body.appendChild(h('div.np', h('div.cover', { style: `background:linear-gradient(135deg, ${cur.color || '#555'}, #111)`, html: icon('music', 70) }), h('div.nt', h('b', cur.name), h('small', cur.radio ? 'Radio en direct' : 'Titre personnalisé')),
        h('div.ctrl', h('button', { html: icon('prev', 30), onclick: () => this.prev() }), h('button.pp', { html: icon(MusicState.playing ? 'pause' : 'play', 34), onclick: () => this.toggle() }), h('button', { html: icon('next', 30), onclick: () => this.next() }))));
    }
    pg.body.appendChild(Group('Radios', t.filter(x => x.radio).map((x) => ({ left: h('div.avatar', { style: `width:44px;height:44px;border-radius:8px;background:${x.color}`, html: icon('radio', 22) }), title: x.name, sub: 'Flux en direct', trailing: MusicState.title === x.name && MusicState.playing ? h('span', { style: 'color:var(--accent)', html: icon('volume', 22) }) : null, onclick: () => this.play(t.indexOf(x)) }))));
    const cs = t.filter(x => !x.radio);
    pg.body.appendChild(Group('Ma liste', cs.length ? cs.map(x => ({ left: h('div.avatar', { style: 'width:44px;height:44px;border-radius:8px;background:#444', html: icon('music', 22) }), title: x.name, sub: x.url.slice(0, 40), onclick: () => this.play(t.indexOf(x)), onlong: () => ActionSheet(x.name, [{ label: 'Retirer', red: true, onclick: async () => { this.custom = this.custom.filter(c => c.url !== x.url); await rpc('kvSet', 'playlist', this.custom); this.refresh(); } }]) })) : [{ title: 'Touchez + pour ajouter un lien audio', sub: 'MP3, AAC, OGG ou flux direct' }]));
  },
  async add() {
    const url = await Prompt('Lien audio', 'Adresse directe d\'un fichier ou flux audio', { placeholder: 'https://…/musique.mp3' }); if (!url || !/^https?:/.test(url)) return;
    const name = await Prompt('Titre', null, { placeholder: 'Mon titre' }); if (name === null) return;
    this.custom.push({ name: name || 'Titre', url }); await rpc('kvSet', 'playlist', this.custom); this.refresh();
  },
};
Music.init();
registerApp({ id: 'music', name: 'Musique', icon: 'music', grad: ['#fa2d48', '#c4152b'], dark: true, open: ctx => Music.open(ctx) });
