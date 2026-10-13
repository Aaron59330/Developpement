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
    '~INPUT_FRONTEND_ACCEPT~': 'Entrée'
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
    const icon = iconForKind(data.kind);
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
        existing.repeatCount += 1;
        existing.lastReceivedAt = now;

        if (data.config) applyConfigToNotification(existing.el, data.config);
        if (uiSettings.counterEnabled) existing.el.classList.add('repeated');
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
            <div class="notify-icon ${iconKind}">${icon}</div>
            <div>${title}</div>
            ${subject}
        </div>
        <div class="notify-message">${formatGtaText(data.message)}</div>
    `;

    applyConfigToNotification(el, data.config || {});
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

window.addEventListener('message', (event) => {
    const data = event.data || {};

    if (data.action === 'config') {
        applyConfig(data.config || {});
        return;
    }

    if (data.action === 'notify') {
        // On réapplique la config à chaque notif : aucun problème de cache/timing NUI.
        if (data.config) applyConfig(data.config);
        createNotification(data);
    }
});
