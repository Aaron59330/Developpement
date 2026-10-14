const container = document.getElementById('notifications');

const gtaColors = {
    '~r~': '<span class="red">',
    '~g~': '<span class="green">',
    '~b~': '<span class="blue">',
    '~y~': '<span class="yellow">',
    '~p~': '<span class="purple">',
    '~c~': '<span class="muted">'
};

const controls = {
    '~INPUT_CONTEXT~': 'E',
    '~INPUT_PICKUP~': 'E',
    '~INPUT_ENTER~': 'F',
    '~INPUT_RELOAD~': 'R',
    '~INPUT_CELLPHONE_CANCEL~': 'Retour',
    '~INPUT_FRONTEND_ACCEPT~': 'Entrée',
    '~INPUT_FRONTEND_RDOWN~': 'Entrée',
    '~INPUT_FRONTEND_RRIGHT~': 'Retour',
    '~INPUT_FRONTEND_CANCEL~': 'Retour',
    '~INPUT_FRONTEND_PAUSE_ALTERNATE~': 'Échap',
    '~INPUT_VEH_EXIT~': 'F',
    '~INPUT_VEH_HORN~': 'E',
    '~INPUT_VEH_HEADLIGHT~': 'H',
    '~INPUT_VEH_HANDBRAKE~': 'Espace',
    '~INPUT_VEH_DUCK~': 'X',
    '~INPUT_JUMP~': 'Espace',
    '~INPUT_SPRINT~': 'Maj',
    '~INPUT_DUCK~': 'Ctrl',
    '~INPUT_DETONATE~': 'G',
    '~INPUT_THROW_GRENADE~': 'G',
    '~INPUT_COVER~': 'Q',
    '~INPUT_CONTEXT_SECONDARY~': 'Q',
    '~INPUT_ATTACK~': 'Clic gauche',
    '~INPUT_AIM~': 'Clic droit',
    '~INPUT_PHONE~': '↑',
    '~INPUT_MP_TEXT_CHAT_ALL~': 'T'
};

const notificationStacks = new Map();

let uiSettings = {
    stackWindow: 3000,
    maxVisibleNotifications: 4,
    counterEnabled: true
};

function normalizeHexColor(value, fallback = '#00a4ff') {
    const raw = String(value || '').trim();
    const hex = raw.startsWith('#') ? raw.slice(1) : raw;
    if (/^[0-9a-fA-F]{3}$/.test(hex)) return `#${hex.split('').map(c => c + c).join('')}`;
    if (/^[0-9a-fA-F]{6}$/.test(hex)) return `#${hex}`;
    return fallback;
}

function hexToRgb(hexColor, fallback = '#000000') {
    const hex = normalizeHexColor(hexColor, fallback).slice(1);
    return {
        r: parseInt(hex.slice(0, 2), 16),
        g: parseInt(hex.slice(2, 4), 16),
        b: parseInt(hex.slice(4, 6), 16)
    };
}

function clamp(value, min, max, fallback) {
    const n = Number(value);
    if (!Number.isFinite(n)) return fallback;
    return Math.min(max, Math.max(min, n));
}

function px(value, fallback) {
    const n = Number(value);
    return `${Number.isFinite(n) ? n : fallback}px`;
}

function cssLength(value, fallback) {
    if (typeof value === 'string') {
        const v = value.trim();
        if (v && (/[a-z%]/i.test(v) || v.startsWith('clamp(') || v.startsWith('calc('))) {
            return v;
        }
        const numericString = Number(v);
        if (Number.isFinite(numericString)) return `${numericString}px`;
    }
    const n = Number(value);
    if (Number.isFinite(n)) return `${n}px`;
    return String(fallback);
}

function applyConfig(config = {}) {
    const root = document.documentElement;

    const accent = normalizeHexColor(config.mainColor, '#00a4ff');
    const accentRgb = hexToRgb(accent);
    const panel = normalizeHexColor(config.backgroundColor, '#070c12');
    const panelRgb = hexToRgb(panel, '#070c12');

    root.style.setProperty('--accent', accent);
    root.style.setProperty('--accent-rgb', `${accentRgb.r}, ${accentRgb.g}, ${accentRgb.b}`);
    root.style.setProperty('--panel-rgb', `${panelRgb.r}, ${panelRgb.g}, ${panelRgb.b}`);
    root.style.setProperty('--panel-alpha', String(clamp(config.backgroundTransparency, 0, 1, .68)));

    root.style.setProperty('--text', normalizeHexColor(config.textColor, '#f7f7fb'));
    root.style.setProperty('--muted', normalizeHexColor(config.smallTextColor, '#b7b6c1'));
    root.style.setProperty('--success', normalizeHexColor(config.successColor, '#5be39a'));
    root.style.setProperty('--error', normalizeHexColor(config.errorColor, '#ff7373'));
    root.style.setProperty('--warning', normalizeHexColor(config.warningColor, '#ffd86a'));
    root.style.setProperty('--blue-text', normalizeHexColor(config.blueTextColor, '#74b7ff'));

    root.style.setProperty('--notify-width', cssLength(config.width, 'clamp(270px, 14.2vw, 315px)'));
    root.style.setProperty('--notify-min-height', px(config.minHeight, 65));
    root.style.setProperty('--notify-gap', px(config.notificationGap, 8));
    root.style.setProperty('--notify-left', String(config.positionLeft || '1.35vw'));
    root.style.setProperty('--notify-bottom', String(config.positionBottom || '22.5vh'));
    root.style.setProperty('--radius', px(config.borderRadius, 11));
    root.style.setProperty('--side-line-width', px(config.sideLineWidth, 4));

    root.style.setProperty('--pad-top', px(config.paddingTop, 11));
    root.style.setProperty('--pad-right', px(config.paddingRight, 13));
    root.style.setProperty('--pad-bottom', px(config.paddingBottom, 12));
    root.style.setProperty('--pad-left', px(config.paddingLeft, 16));

    root.style.setProperty('--title-size', px(config.titleFontSize, 12.5));
    root.style.setProperty('--title-weight', String(config.titleFontWeight ?? 750));
    root.style.setProperty('--message-size', px(config.messageFontSize, 12));
    root.style.setProperty('--message-weight', String(config.messageFontWeight ?? 600));
    root.style.setProperty('--message-line-height', String(config.messageLineHeight ?? 1.45));
    root.style.setProperty('--small-size', px(config.smallTextFontSize, 10.5));
    root.style.setProperty('--small-weight', String(config.smallTextFontWeight ?? 600));
    root.style.setProperty('--header-gap', px(config.headerGap, 7));
    root.style.setProperty('--header-bottom', px(config.headerBottomSpacing, 6));

    root.style.setProperty('--icon-box-size', px(config.iconBoxSize, 22));
    root.style.setProperty('--icon-size', px(config.iconSize, 13));
    root.style.setProperty('--icon-radius', px(config.iconRadius, 7));
    root.style.setProperty('--icon-stroke', String(config.iconStrokeWidth ?? 1.9));
    root.style.setProperty('--icon-bg-alpha', String(clamp(config.iconBackgroundOpacity, 0, 1, .12)));
    root.style.setProperty('--icon-border-alpha', String(clamp(config.iconBorderOpacity, 0, 1, .34)));

    root.style.setProperty('--counter-size', px(config.counterSize, 16));
    root.style.setProperty('--counter-font-size', px(config.counterFontSize, 9));
    root.style.setProperty('--counter-radius', px(config.counterRadius, 6));
    root.style.setProperty('--counter-top', px(config.counterTop, 6));
    root.style.setProperty('--counter-right', px(config.counterRight, 6));
    root.style.setProperty('--counter-bg-alpha', String(clamp(config.counterBackgroundOpacity, 0, 1, .92)));

    root.style.setProperty('--progress-height', px(config.progressLineHeight, 2));
    root.style.setProperty('--progress-opacity', String(clamp(config.progressLineOpacity, 0, 1, .85)));

    uiSettings.stackWindow = Math.max(0, Number(config.stackWindow) || 3000);
    uiSettings.maxVisibleNotifications = Math.max(1, Math.floor(Number(config.maxVisibleNotifications) || 4));
    uiSettings.counterEnabled = config.counterEnabled !== false;
    uiSettings.iconEnabled = config.iconEnabled !== false;
    uiSettings.sideLineEnabled = config.sideLineEnabled !== false;
    uiSettings.progressLineEnabled = config.progressLineEnabled !== false;
}

function applyConfigToNotification(el, config = {}) {
    applyConfig(config);

    el.classList.toggle('counter-disabled', config.counterEnabled === false);
    el.classList.toggle('no-side-line', config.sideLineEnabled === false);
    el.classList.toggle('no-progress', config.progressLineEnabled === false);

    const icon = el.querySelector('.notify-icon');
    if (icon) icon.classList.toggle('hidden', config.iconEnabled === false);
}

async function loadConfig() {
    try {
        const resourceName = typeof GetParentResourceName === 'function'
            ? GetParentResourceName()
            : 'pickax_notify';

        const response = await fetch(`https://${resourceName}/getConfig`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify({})
        });

        if (response.ok) applyConfig(await response.json());
    } catch (_) {}
}

loadConfig();

function escapeHtml(value) {
    return String(value ?? '')
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#039;');
}

function formatGtaText(value) {
    let text = escapeHtml(value);

    // « Retour ou Retour » : deux touches GTA différentes qui s'affichent pareil -> une seule
    text = text.replace(/(~INPUT_[A-Z0-9_]+~)(\s*(?:ou|or|\/)\s*)(~INPUT_[A-Z0-9_]+~)/gi, (m, a, sep, b) => (controls[a] && controls[a] === controls[b]) ? a : m);

    for (const [token, key] of Object.entries(controls)) {
        text = text.split(token).join(`<span class="key">${key}</span>`);
    }

    text = text.split('~s~').join('</span>');

    for (const [token, html] of Object.entries(gtaColors)) {
        text = text.split(token).join(html);
    }

    text = text.replace(/~[a-zA-Z0-9_]+~/g, '');
    text = text.replace(/\n/g, '<br>');
    return text;
}

// Logos de métiers / catégories (icône affichée dans la notification quand `icon` est renseigné)
const S = (p) => `<svg viewBox="0 0 24 24" aria-hidden="true">${p}</svg>`;
const NAMED_ICONS = {
    police: S('<path d="M12 3l7.5 3v5.5c0 4.5-3.2 8-7.5 9.5-4.3-1.5-7.5-5-7.5-9.5V6z"></path><path d="M9 12l2 2 4-4.2"></path>'),
    ems: S('<circle cx="12" cy="12" r="9"></circle><path d="M12 7.5v9M7.5 12h9"></path>'),
    mecano: S('<path d="M14.5 6.2a4 4 0 0 0-5.2 5.2L4 16.7 7.3 20l5.3-5.3a4 4 0 0 0 5.2-5.2l-2.6 2.6-2.4-.6-.6-2.4z"></path>'),
    taxi: S('<path d="M5 15l1.6-5A2 2 0 0 1 8.5 8.6h7a2 2 0 0 1 1.9 1.4L19 15"></path><path d="M4 15h16v3.5H4z"></path><path d="M10 6h4v2.6h-4z"></path><circle cx="7.5" cy="18.5" r="1"></circle><circle cx="16.5" cy="18.5" r="1"></circle>'),
    bank: S('<path d="M3.5 9.5L12 4l8.5 5.5z"></path><path d="M6 11v6M10 11v6M14 11v6M18 11v6"></path><path d="M3.5 19.5h17"></path>'),
    government: S('<path d="M12 3.5l8 3.8H4z"></path><path d="M6 10v7M10 10v7M14 10v7M18 10v7"></path><path d="M3.5 19.5h17M12 3.5V1.8"></path>'),
    realestate: S('<path d="M4 11l8-6.5 8 6.5"></path><path d="M6 10v9.5h12V10"></path><path d="M10 19.5v-5h4v5"></path>'),
    bar: S('<path d="M5 5h14l-6 8v6M9 19h6"></path><path d="M7.5 8.5h9"></path>'),
    dealer: S('<path d="M4 14.5l1.7-4.6A2 2 0 0 1 7.6 8.6h8.8a2 2 0 0 1 1.9 1.3L20 14.5"></path><path d="M3 14.5h18v3.5H3z"></path><circle cx="7" cy="18" r="1.2"></circle><circle cx="17" cy="18" r="1.2"></circle>'),
    garage: S('<path d="M3.5 10.5L12 5l8.5 5.5V19h-17z"></path><path d="M7.5 19v-5h9v5M7.5 16.5h9"></path>'),
    impound: S('<rect x="5" y="11" width="14" height="9" rx="2"></rect><path d="M8 11V8a4 4 0 0 1 8 0v3"></path>'),
    fuel: S('<path d="M5 20V5.5A1.5 1.5 0 0 1 6.5 4h6A1.5 1.5 0 0 1 14 5.5V20"></path><path d="M4 20h11M14 9h2.2a1.8 1.8 0 0 1 1.8 1.8v5.2a1.5 1.5 0 0 0 3 0V9l-2.5-2.5"></path><path d="M7.5 7.5h4"></path>'),
    carwash: S('<path d="M12 3.5s5.5 5.8 5.5 10A5.5 5.5 0 0 1 6.5 13.5c0-4.2 5.5-10 5.5-10z"></path>'),
    drug: S('<path d="M12 21V11"></path><path d="M12 12c-4.5 0-6.5-3-6.5-6.5C9.5 5.5 12 8 12 12z"></path><path d="M12 12c4.5 0 6.5-3 6.5-6.5C14.5 5.5 12 8 12 12z"></path>'),
    robbery: S('<path d="M5 8h14l-1.2 11H6.2z"></path><path d="M9 8V6.5a3 3 0 0 1 6 0V8"></path><path d="M12 11.5v4M10.3 13.5h3.4"></path>'),
    school: S('<path d="M2.5 9.5L12 5l9.5 4.5L12 14z"></path><path d="M6.5 11.5v4.2c0 1.2 2.5 2.3 5.5 2.3s5.5-1.1 5.5-2.3v-4.2"></path>'),
    gang: S('<path d="M6 21V4"></path><path d="M6 5h11.5l-2.5 3.8 2.5 3.7H6"></path>'),
    shop: S('<path d="M6 8h12l1 12H5z"></path><path d="M9 8a3 3 0 0 1 6 0"></path>'),
    world: S('<circle cx="12" cy="12" r="9"></circle><path d="M3 12h18M12 3c3 3 3 15 0 18M12 3c-3 3-3 15 0 18"></path>'),
    job: S('<rect x="3.5" y="7.5" width="17" height="12" rx="2"></rect><path d="M9 7.5V6a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v1.5"></path><path d="M3.5 13h17"></path>')
};
// Textures GTA d'icônes de notification (ESX avancé) -> logos
const GTA_ICON_MAP = { CHAR_BANK_FLEECA: 'bank', CHAR_BANK_MAZE: 'bank', CHAR_BANK_BOL: 'bank', CHAR_CALL911: 'police', CHAR_MP_MORS_MUTUAL: 'mecano', CHAR_CARSITE: 'dealer', CHAR_CARSITE2: 'dealer', CHAR_PROPERTY_CAR_SCRAP_YARD: 'mecano', CHAR_TAXI: 'taxi', CHAR_PROPERTY_BAR_AIRPORT: 'bar' };

function namedIcon(name) {
    if (!name) return null;
    const key = String(name);
    return NAMED_ICONS[key] || NAMED_ICONS[GTA_ICON_MAP[key]] || null;
}

function iconForKind(kind) {
    if (kind === 'help') {
        return `
            <svg viewBox="0 0 24 24" aria-hidden="true">
                <circle cx="12" cy="12" r="9"></circle>
                <path d="M9.7 9.1a2.45 2.45 0 0 1 4.74.85c0 1.8-2.44 2.05-2.44 3.55"></path>
                <path d="M12 17.2h.01"></path>
            </svg>`;
    }

    if (kind === 'advanced') {
        return `
            <svg viewBox="0 0 24 24" aria-hidden="true">
                <path d="M12 3.5 20 8v8l-8 4.5L4 16V8l8-4.5Z"></path>
                <path d="M12 8.2v4.5"></path>
                <path d="M12 16.2h.01"></path>
            </svg>`;
    }

    return `
        <svg viewBox="0 0 24 24" aria-hidden="true">
            <circle cx="12" cy="12" r="9"></circle>
            <path d="M12 10.8v5.1"></path>
            <path d="M12 7.7h.01"></path>
        </svg>`;
}

function labelForKind(kind) {
    switch (kind) {
        case 'help': return ['help', 'Aide'];
        case 'advanced': return ['advanced', 'Information'];
        default: return ['info', 'Information'];
    }
}

function buildNotificationKey(data) {
    return JSON.stringify([
        data.kind || 'info',
        data.title || '',
        data.subject || '',
        data.message || '',
        data.icon || '',
        data.iconType ?? ''
    ]);
}

function scheduleRemoval(record, duration) {
    if (record.timeout) window.clearTimeout(record.timeout);
    if (record.removeTimeout) window.clearTimeout(record.removeTimeout);

    record.timeout = window.setTimeout(() => {
        record.el.classList.add('closing');
        record.removeTimeout = window.setTimeout(() => {
            record.el.remove();
            if (notificationStacks.get(record.key) === record) {
                notificationStacks.delete(record.key);
            }
        }, 240);
    }, duration);
}

function createNotification(data) {
    const [iconKind, fallbackTitle] = labelForKind(data.kind);
    const named = namedIcon(data.icon);
    const icon = named || iconForKind(data.kind);
    const duration = Math.max(1500, Number(data.duration) || 4500);
    const key = buildNotificationKey(data);

    const now = Date.now();
    const existing = notificationStacks.get(key);

    // Si la même notification revient dans les 3 secondes, on l'empile
    // sur la carte existante au lieu d'en créer une nouvelle.
    if (
        existing &&
        (now - existing.lastReceivedAt) <= uiSettings.stackWindow &&
        existing.el.isConnected &&
        !existing.el.classList.contains('closing')
    ) {
        if (!data.noCounter) existing.repeatCount += 1;
        existing.lastReceivedAt = now;

        if (data.config) applyConfigToNotification(existing.el, data.config);
        if (uiSettings.counterEnabled && !data.noCounter) existing.el.classList.add('repeated');
        existing.el.querySelector('.notify-repeat').textContent = String(existing.repeatCount);

        // Chaque répétition relance la durée d'affichage de la carte.
        scheduleRemoval(existing, duration);

        // Relance aussi la barre de progression.
        existing.el.style.setProperty('--duration', `${duration}ms`);
        existing.el.classList.add('refresh-progress');
        void existing.el.offsetWidth;
        requestAnimationFrame(() => {
            if (existing.el.isConnected) {
                existing.el.classList.remove('refresh-progress');
            }
        });
        return;
    }

    const el = document.createElement('section');
    el.className = 'notification';
    el.style.setProperty('--duration', `${duration}ms`);

    const title = escapeHtml(data.title || fallbackTitle);
    const subject = data.subject ? `<div class="notify-subject">${escapeHtml(data.subject)}</div>` : '';

    el.innerHTML = `
        <div class="notify-repeat">1</div>
        <div class="notify-header">
            <div class="notify-icon ${iconKind}${named ? ' named' : ''}">${icon}</div>
            <div>${title}</div>
            ${subject}
        </div>
        <div class="notify-message">${formatGtaText(data.message)}</div>
    `;

    applyConfigToNotification(el, data.config || {});
    // Teinte selon le type (succès / erreur / attention)
    const cfg = data.config || {};
    const toneColor = { success: cfg.successColor, error: cfg.errorColor, warning: cfg.warningColor }[data.tone];
    if (toneColor) {
        const rgb = hexToRgb(toneColor);
        el.style.setProperty('--accent', normalizeHexColor(toneColor));
        el.style.setProperty('--accent-rgb', `${rgb.r}, ${rgb.g}, ${rgb.b}`);
    }
    container.appendChild(el);

    const record = {
        key,
        el,
        repeatCount: 1,
        lastReceivedAt: now,
        timeout: null,
        removeTimeout: null
    };

    notificationStacks.set(key, record);
    scheduleRemoval(record, duration);

    // Maximum 4 notifications visibles comme un feed compact.
    while (container.children.length > uiSettings.maxVisibleNotifications) {
        const first = container.firstElementChild;
        if (!first) break;

        // Nettoie aussi la Map si la carte supprimée y est encore référencée.
        for (const [stackKey, stackRecord] of notificationStacks.entries()) {
            if (stackRecord.el === first) {
                notificationStacks.delete(stackKey);
                break;
            }
        }
        first.remove();
    }
}

// Aide « Appuyez sur E » : prompt centré à l'écran (point · touche ronde · action), sans cadre
let helpHideTimer = null;
function showCenterHelp(data) {
    const el = document.getElementById('helpPrompt');
    const raw = String(data.message ?? '').replace(/(~INPUT_[A-Z0-9_]+~)(\s*(?:ou|or|\/)\s*)(~INPUT_[A-Z0-9_]+~)/gi, (m, a, sep, b) => (controls[a] && controls[a] === controls[b]) ? a : m);
    const m = raw.match(/^\s*(?:appuy(?:ez|e|er)|press)\s+(?:sur\s+)?(~INPUT_[A-Z_0-9]+~)\s*(?:pour|to|:|-)\s*(.+)$/is);
    let keyHtml = '', label = raw;
    if (m && controls[m[1]] && !/~INPUT_/.test(m[2])) {
        keyHtml = `<span class="hp-key">${escapeHtml(controls[m[1]])}</span>`;
        label = m[2].charAt(0).toUpperCase() + m[2].slice(1);
    }
    const html = `<span class="hp-dot"></span>${keyHtml}<span class="hp-text">${formatGtaText(label)}</span>`;
    if (el.dataset.html !== html) { el.innerHTML = html; el.dataset.html = html; }
    el.classList.add('show');
    clearTimeout(helpHideTimer);
    helpHideTimer = setTimeout(() => el.classList.remove('show'), Number(data.duration) || 1200);
}

window.addEventListener('message', (event) => {
    const data = event.data || {};

    if (data.action === 'config') {
        applyConfig(data.config || {});
        return;
    }

    if (data.action === 'notify' && data.kind === 'help') {
        showCenterHelp(data);
        return;
    }

    if (data.action === 'notify') {
        // On réapplique la config à chaque notif : aucun problème de cache/timing NUI.
        if (data.config) applyConfig(data.config);
        createNotification(data);
    }
});
