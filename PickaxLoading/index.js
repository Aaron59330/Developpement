/* =========================
   UTILS
========================= */
function qs(sel) {
    return document.querySelector(sel);
}

if (!String.format) {
    String.format = function (format) {
        var args = Array.prototype.slice.call(arguments, 1);
        return format.replace(/{(\d+)}/g, function (match, number) {
            return typeof args[number] !== 'undefined' ? args[number] : match;
        });
    };
}

/* =========================
   CONFIG
========================= */
const technicalNames = [
    "INIT_BEFORE_MAP_LOADED",
    "MAP",
    "INIT_AFTER_MAP_LOADED",
    "INIT_SESSION"
];

const loadingWeights = [1.5 / 10, 4 / 10, 1.5 / 10, 3 / 10];
const loadingTotals = [70, 70, 70, 220];
const totalWidth = 99.1;

/* =========================
   STATE
========================= */
let currentLoadingStage = 0;
let currentLoadingCount = 0;
let currentProgress = [0, 0, 0, 0];
let stageVisible = [false, false, false, false];

const gstate = {
    log: []
};

/* =========================
   PROGRESS CALC
========================= */
let progressPositions = [];
let progressMaxLengths = [];

progressPositions[0] = 0;
for (let i = 0; i < currentProgress.length; i++) {
    progressMaxLengths[i] = loadingWeights[i] * totalWidth;
    progressPositions[i + 1] = progressPositions[i] + progressMaxLengths[i];
}

/* =========================
   PROGRESS FUNCTIONS
========================= */
function doProgress(stage) {
    const idx = technicalNames.indexOf(stage);
    if (idx < 0) return;

    if (idx > currentLoadingStage) {
        while (currentLoadingStage < idx) {
            currentProgress[currentLoadingStage] = 1;
            currentLoadingStage++;
        }
        currentLoadingCount = 1;
    } else {
        currentLoadingCount++;
    }

    currentProgress[currentLoadingStage] = Math.min(
        currentLoadingCount / loadingTotals[idx],
        1
    );

    updateProgress();
}

function updateProgress() {
    const debug = qs('#debug');
    if (!debug) return;

    debug.innerHTML = '';

    for (let i = 0; i <= currentLoadingStage; i++) {
        const label = qs(`#${technicalNames[i]}-label`);
        const bar = qs(`#${technicalNames[i]}-bar`);

        if (!label || !bar) continue;

        if ((currentProgress[i] > 0 || !currentProgress[i - 1]) && !stageVisible[i]) {
            label.style.display = 'inline-block';
            bar.style.display = 'inline-block';
            stageVisible[i] = true;
        }

        bar.style.width = (currentProgress[i] * progressMaxLengths[i]) + '%';
        label.style.width = progressMaxLengths[i] + '%';


    }
}

updateProgress();

/* =========================
   LOG SYSTEM (SAFE)
========================= */
function printLog(type, str) {
    gstate.log.push({ type, str });
}



/* =========================
   HANDLERS (FiveM)
========================= */
const handlers = {
    startInitFunction(data) {
        printLog(1, `Running ${data.type}`);
        if (data.type) doProgress(data.type);
    },

    startInitFunctionOrder(data) {
        printLog(1, `[${data.type}] Order ${data.order}`);
        if (data.type) doProgress(data.type);
    },

    initFunctionInvoking(data) {
        printLog(3, `Invoking ${data.name}`);
        if (data.type) doProgress(data.type);
    },

    initFunctionInvoked(data) {
        if (data.type) doProgress(data.type);
    },

    endInitFunction(data) {
        printLog(1, `Done ${data.type}`);
        if (data.type) doProgress(data.type);
    },

    startDataFileEntries(data) {
        printLog(1, 'Loading map');
        if (data.type) doProgress(data.type);
    },

    onDataFileEntry(data) {
        printLog(3, `Loading ${data.name}`);
        if (data.type) doProgress(data.type);
    },

    endDataFileEntries() {
        printLog(1, 'Map loaded');
    },

    performMapLoadFunction() {
        doProgress('MAP');
    },

    onLogLine(data) {
        printLog(3, data.message);
    }
};

/* =========================
   MESSAGE LISTENER
========================= */
window.addEventListener('message', function (e) {
    (handlers[e.data.eventName] || function () { })(e.data);
});

/* =========================
   DEMO MODE (hors FiveM)
========================= */
if (!window.invokeNative) {
    const demoSteps = [
        () => handlers.startInitFunction({ type: 'MAP' }),
        () => handlers.initFunctionInvoking({ type: 'MAP', name: 'file1' }),
        () => handlers.initFunctionInvoking({ type: 'MAP', name: 'file2' }),
        () => handlers.initFunctionInvoking({ type: 'MAP', name: 'file3' }),
        () => handlers.startInitFunction({ type: 'INIT_SESSION' }),
        () => handlers.initFunctionInvoking({ type: 'INIT_SESSION', name: 'session1' }),
        () => handlers.initFunctionInvoking({ type: 'INIT_SESSION', name: 'session2' }),
        () => handlers.initFunctionInvoking({ type: 'INIT_SESSION', name: 'session3' }),
    ];

    setInterval(() => {
        if (demoSteps.length) demoSteps.shift()();
    }, 350);
}
