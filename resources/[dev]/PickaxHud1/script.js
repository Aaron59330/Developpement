window.addEventListener("message", (event) => {
    // Masquer / afficher le HUD (menu pause, chargement, inventaire ouvert)
    if (event.data.action === "hideUi" || event.data.action === "fadeUi") {
        const container = document.querySelector(".hud-container");
        if (container) container.style.display = event.data.value === true ? "none" : "";
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
