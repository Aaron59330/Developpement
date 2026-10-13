window.addEventListener("message", (event) => {
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
