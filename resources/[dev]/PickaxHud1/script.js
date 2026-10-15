window.addEventListener("message", (event) => {
    // Masquer / afficher le HUD (menu pause, chargement, inventaire ouvert)
    if (event.data.action === "hideUi" || event.data.action === "fadeUi") {
        const container = document.querySelector(".hud-container");
        if (container) container.style.display = event.data.value === true ? "none" : "";
        const hh = document.getElementById("healthHud");
        if (hh) hh.style.visibility = event.data.value === true ? "hidden" : "";
        return;
    }
    // Barre de vie : réglages (position, taille, activation)
    if (event.data.action === "setHealthConfig") {
        const c = event.data.config || {};
        const hh = document.getElementById("healthHud");
        if (!hh) return;
        hh.classList.toggle("off", c.Enabled === false);
        if (c.Left) hh.style.left = c.Left;
        if (c.Bottom) hh.style.bottom = c.Bottom;
        if (c.Width) hh.style.width = c.Width;
        if (c.Height) hh.style.setProperty("--hh-h", c.Height + "px");
        hh.dataset.armor = c.ShowArmor === false ? "0" : "1";
        return;
    }
    // Barre de vie : valeurs (vie et armure en %)
    if (event.data.action === "updateHealth") {
        const health = Math.max(0, Math.min(100, Math.round(event.data.health || 0)));
        const armor = Math.max(0, Math.min(100, Math.round(event.data.armor || 0)));
        const hh = document.getElementById("healthHud");
        const fill = document.getElementById("hhFill");
        if (!hh || !fill) return;
        const ghost = document.getElementById("hhGhost");
        // la traînée blanche reste à l'ancienne valeur puis rattrape ; elle suit tout de suite quand la vie remonte
        if (ghost) {
            const prev = parseFloat(fill.style.width) || 0;
            if (health >= prev) { ghost.style.transition = "none"; ghost.style.width = health + "%"; void ghost.offsetWidth; ghost.style.transition = ""; }
            else { ghost.style.width = health + "%"; }
        }
        fill.style.width = health + "%";
        // vert (100 %) -> jaune -> rouge (0 %)
        fill.parentElement.style.setProperty("--hh-color", "hsl(" + Math.round(health * 1.2) + ", 78%, 50%)");
        document.getElementById("hhVal").textContent = health;
        document.getElementById("hhBar").classList.toggle("low", health > 0 && health <= 25);
        const ar = document.getElementById("hhArmor");
        ar.classList.toggle("on", armor > 0 && hh.dataset.armor !== "0");
        document.getElementById("hhArmorFill").style.width = armor + "%";
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
