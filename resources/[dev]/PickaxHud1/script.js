window.addEventListener("message", (event) => {
    // Masquer / afficher le HUD (menu pause, chargement, inventaire ouvert)
    if (event.data.action === "hideUi" || event.data.action === "fadeUi") {
        const container = document.querySelector(".hud-container");
        if (container) container.style.display = event.data.value === true ? "none" : "";
        return;
    }
    // Thème envoyé par le panel web (position, espacement, fond)
    if (event.data.action === "setTheme") {
        const t = event.data.theme || {};
        const container = document.querySelector(".hud-container");
        if (container) {
            container.style.bottom = t.bottom != null ? t.bottom + "px" : "";
            container.style.left = t.left != null ? t.left + "px" : "";
            container.style.gap = t.gap != null ? t.gap + "px" : "";
        }
        document.querySelectorAll(".hud-element").forEach((el) => { el.style.background = t.bg || ""; });
        return;
    }
    if (event.data.action === "updateHud") {
        const { hunger, thirst } = event.data;

        const thirstProgress = document.querySelector(".hud-container .hud-element:nth-child(1) .progress");
        const hungerProgress = document.querySelector(".hud-container .hud-element:nth-child(2) .progress");

        // offset basé sur les pourcentages (100% = dashoffset 0, 0% = dashoffset max)
        const maxDashOffset = 94; // Correspond à `stroke-dasharray`

        if (thirstProgress) {
            thirstProgress.style.strokeDashoffset = maxDashOffset * (1 - thirst / 100);
        }
        if (hungerProgress) {
            hungerProgress.style.strokeDashoffset = maxDashOffset * (1 - hunger / 100);
        }
    }
});
