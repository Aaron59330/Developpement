// Carte d'identité dynamique, nationalités et sons (UI uniquement)
(function () {
	var NATIONALITIES = ["Américaine","Française","Britannique","Allemande","Italienne","Espagnole","Portugaise","Belge","Suisse","Néerlandaise","Canadienne","Mexicaine","Brésilienne","Argentine","Colombienne","Cubaine","Jamaïcaine","Haïtienne","Marocaine","Algérienne","Tunisienne","Égyptienne","Sénégalaise","Ivoirienne","Camerounaise","Nigériane","Sud-africaine","Turque","Libanaise","Russe","Ukrainienne","Polonaise","Roumaine","Grecque","Suédoise","Norvégienne","Irlandaise","Indienne","Pakistanaise","Chinoise","Japonaise","Coréenne","Vietnamienne","Philippine","Australienne","Autre"];

	var $sel = $("#nationalite");
	NATIONALITIES.forEach(function (n) { $sel.append($("<option>").val(n).text(n)); });

	/* ---------- Sons (WebAudio, aucun fichier) ---------- */
	var ctx = null;
	function ac() {
		if (!ctx) { try { ctx = new (window.AudioContext || window.webkitAudioContext)(); } catch (e) {} }
		if (ctx && ctx.state === "suspended") ctx.resume();
		return ctx;
	}
	function tone(freq, dur, type, vol, slideTo, delay) {
		var c = ac(); if (!c) return;
		var t = c.currentTime + (delay || 0);
		var o = c.createOscillator(), g = c.createGain();
		o.type = type || "sine";
		o.frequency.setValueAtTime(freq, t);
		if (slideTo) o.frequency.exponentialRampToValueAtTime(slideTo, t + dur);
		g.gain.setValueAtTime(0.0001, t);
		g.gain.exponentialRampToValueAtTime(vol || 0.05, t + 0.008);
		g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
		o.connect(g); g.connect(c.destination);
		o.start(t); o.stop(t + dur + 0.02);
	}
	var SFX = {
		hover:   function () { tone(900, 0.05, "sine", 0.025, 1200); },
		click:   function () { tone(300, 0.09, "triangle", 0.07, 140); },
		type:    function () { tone(1400 + Math.random() * 300, 0.03, "square", 0.012); },
		select:  function () { tone(520, 0.08, "sine", 0.05); tone(780, 0.1, "sine", 0.05, null, 0.06); },
		filled:  function () { tone(660, 0.1, "sine", 0.04); tone(990, 0.14, "sine", 0.04, null, 0.07); },
		error:   function () { tone(180, 0.18, "sawtooth", 0.05, 110); },
		success: function () { [523, 659, 784, 1046].forEach(function (f, i) { tone(f, 0.22, "sine", 0.06, null, i * 0.09); }); }
	};
	window.IdentitySFX = SFX;

	$(document).on("mouseenter", ".submit, .radio-toolbar label", SFX.hover);
	$(document).on("mousedown", ".submit, .radio-toolbar label", SFX.click);
	$(document).on("focus", "input[type='text'], select", SFX.hover);
	$("#prenom, #nom, #date, #taille").on("keydown", function (e) { if (e.which !== 9 && e.which !== 13) SFX.type(); });
	$sel.on("change", SFX.select);

	/* ---------- Carte ---------- */
	var state = {};
	function cap(v) { return v.replace(/(^|[\s-])(\S)/g, function (m, a, b) { return a + b.toUpperCase(); }); }
	function fill(id, key, val, empty) {
		var $el = $(id), $f = $el.closest(".cf");
		var had = $f.hasClass("done");
		$el.text(val || " ");
		if (val) {
			$f.addClass("done");
			$el.removeClass("pop"); void $el[0].offsetWidth; $el.addClass("pop");
		} else { $f.removeClass("done"); }
		if (val && !state[key]) SFX.filled();
		state[key] = !!val;
	}
	function mrz(s) { return (s || "").toUpperCase().replace(/[^A-Z]/g, "").replace(/ /g, "<"); }

	var cardId = String(Math.floor(100000 + Math.random() * 900000));

	function update() {
		var f = $.trim($("#prenom").val()), l = $.trim($("#nom").val());
		var d = $("#date").val(), h = $.trim($("#taille").val());
		var n = $sel.val() || "";
		var sex = $("input[name='radioFruit']:checked").val();

		fill("#cFirst", "firstname", cap(f));
		fill("#cLast", "lastname", l.toUpperCase());
		fill("#cDob", "dob", d.length === 10 ? d : "");
		fill("#cHeight", "height", h ? h + " cm" : "");
		fill("#cNat", "nat", n);
		$("#cSex").text(sex === "f" ? "F" : "M"); 
		
		$("#cSign").text(f && l ? f[0].toUpperCase() + ". " + cap(l) : "");

		$("#cNo").text(cardId);
		var line = "ID" + cardId + "<<" + mrz(l) + "<<" + mrz(f);
		while (line.length < 60) line += "<";
		$("#mrz").text(line.slice(0, 30) + "\n" + (cardId + "<<<" + mrz(f + l)).padEnd(30, "<").slice(0, 30));

		var total = 5, done = [f, l, d.length === 10, h, n].filter(Boolean).length;
		var pct = Math.round(done / total * 100);
		$("#pct").text(pct + "%"); $("#bar").css("width", pct + "%");
		$("#idcard").toggleClass("complete", pct === 100);
	}
	$("#prenom, #nom, #date, #taille").on("input keyup", update);
	$sel.on("change", update);
	$("input[name='radioFruit']").on("change", update);
	$("input[name='radioFruit']").on("change", function () {
		window.headRetries = 0;
		setTimeout(function () { $.post("http://esx_identity/requestHead", "{}"); }, 400);
	});
	update();

	/* focus -> surligne le champ correspondant sur la carte */
	var map = { prenom: "firstname", nom: "lastname", date: "dob", taille: "height", nationalite: "nat" };
	$("#prenom, #nom, #date, #taille, #nationalite").on("focus", function () {
		$(".cf").removeClass("active");
		$(".cf[data-f='" + map[this.id] + "']").addClass("active");
	}).on("blur", function () { $(".cf").removeClass("active"); });
	$("input[name='radioFruit']").on("change", function () {
		$(".cf").removeClass("active"); $(".cf[data-f='sex']").addClass("active");
	});

	/* vraie tête du personnage (envoyée par le client Lua) */
	window.addEventListener("message", function (e) {
		if (e.data && e.data.type === "head") {
			window.headRetries = 0;
			var img = document.getElementById("headImg");
			if (e.data.src) {
				img.onload = function () { $("#photo").addClass("has-head"); };
				img.onerror = function () {
					$("#photo").removeClass("has-head");
					// la texture peut ne pas être prête : on redemande (3 fois max)
					if ((window.headRetries = (window.headRetries || 0) + 1) <= 3) {
						setTimeout(function () { $.post("http://esx_identity/requestHead", "{}"); }, 800);
					}
				};
				img.src = e.data.src + (e.data.src.indexOf("?") === -1 ? "?" : "&") + "t=" + Date.now();
			} else { $("#photo").removeClass("has-head"); }
		}
	});

	/* inclinaison 3D au survol */
	$(".card-scene").on("mousemove", function (e) {
		var r = this.getBoundingClientRect();
		var x = (e.clientX - r.left) / r.width - 0.5, y = (e.clientY - r.top) / r.height - 0.5;
		$("#idcard").css("transform", "rotateY(" + x * 14 + "deg) rotateX(" + -y * 14 + "deg)");
		$(".shine").css("background-position", (x * 100 + 50) + "% 50%");
	}).on("mouseleave", function () { $("#idcard").css("transform", ""); });

	/* validation visuelle + sons (n'altère pas l'envoi des données) */
	$("#register").on("submit", function () {
		var ok = $.trim($("#prenom").val()) && $.trim($("#nom").val()) && validBirthDate($("#date").val()) && $.trim($("#taille").val()) && $sel.val();
		if (ok) { SFX.success(); $("#idcard").addClass("stamp"); }
		else {
			SFX.error();
			var $w = $(".wrapper").removeClass("shake"); void $w[0].offsetWidth; $w.addClass("shake");
		}
	});
})();
