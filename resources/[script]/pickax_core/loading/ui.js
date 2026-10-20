// Habillage uniquement : lit l'avancement affiché par index.js, ne le modifie pas.

// ===== Liens des boutons (mets tes URLs https:// complètes) =====
var LINKS = {
	reglement: '',
	discord: 'https://discord.gg/JGxkBuckU',
	boutique: 'https://bluebayrp.tebex.io/'
};

(function () {
	var bars = ['INIT_BEFORE_MAP_LOADED', 'MAP', 'INIT_AFTER_MAP_LOADED', 'INIT_SESSION'];
	var texts = ['Initialisation…', 'Chargement de la carte…', 'Démarrage…', 'Connexion à la session…'];
	var percentEl = document.getElementById('percent');
	var stageEl = document.getElementById('stageText');
	var shown = 0;

	function target() {
		var total = 0, stage = 0;
		bars.forEach(function (name, i) {
			var b = document.getElementById(name + '-bar');
			if (!b) return;
			var w = parseFloat(b.style.width) || 0;
			total += w;
			if (w > 0) stage = i;
		});
		return { p: Math.min(100, Math.round(total / 99.1 * 100)), stage: stage };
	}

	(function tick() {
		var t = target();
		if (shown < t.p) shown += Math.max(1, Math.round((t.p - shown) / 8));
		else if (shown > t.p) shown = t.p;
		percentEl.textContent = shown;
		stageEl.textContent = texts[t.stage];
		requestAnimationFrame(tick);
	})();

	var SV = window.PICKAX_SERVER || {};
	if (!LINKS.discord && SV.discord) LINKS.discord = 'https://' + String(SV.discord).replace(/^https?:\/\//, '');   // Discord du config du core

	// Boutons de liens
	Array.prototype.forEach.call(document.querySelectorAll('.tab'), function (el) {
		el.addEventListener('click', function () {
			el.blur();
			var url = LINKS[el.getAttribute('data-link')];
			if (!url) return;
			if (window.invokeNative) window.invokeNative('openUrl', url); else window.open(url, '_blank');
		});
	});

	// Volume + bouton musique (même logique que la touche ESPACE)
	var slider = document.getElementById('volume');
	var vv = document.getElementById('volumeValue');
	var icOn = document.getElementById('icOn'), icOff = document.getElementById('icOff');
	function paintSlider() {
		var v = slider.value;
		slider.style.background = 'linear-gradient(90deg, var(--accent) ' + v + '%, rgba(255,255,255,.12) ' + v + '%)';
		vv.textContent = v + '%';
	}
	slider.addEventListener('input', function () { myAudio.volume = slider.value / 100; paintSlider(); });
	document.getElementById('musicBtn').addEventListener('click', function () { this.blur(); toggleMusic(); });
	window.onMusicToggle = function (on) { icOn.style.display = on ? '' : 'none'; icOff.style.display = on ? 'none' : ''; };
	paintSlider();
})();
