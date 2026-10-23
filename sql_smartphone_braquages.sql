-- ═══════════════════════════════════════════════════════════════════════════
-- Tables du smartphone (pickax_phone) et des braquages (pickax_heists)
-- Facultatif : les ressources créent ces tables automatiquement au démarrage
-- (CREATE TABLE IF NOT EXISTS). Ce fichier permet de les créer à l'avance ou
-- de les inclure dans une installation propre. Peut être importé plusieurs fois.
-- ═══════════════════════════════════════════════════════════════════════════

SET FOREIGN_KEY_CHECKS=0;

-- ── pickax_phone ──
CREATE TABLE IF NOT EXISTS aura_phones (
    identifier VARCHAR(80) NOT NULL PRIMARY KEY,
    number VARCHAR(20) NOT NULL UNIQUE,
    mail VARCHAR(120) NULL,
    settings LONGTEXT NULL,
    apps LONGTEXT NULL,
    battery TINYINT UNSIGNED NOT NULL DEFAULT 100,
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aura_kv (
    owner VARCHAR(80) NOT NULL,
    k VARCHAR(40) NOT NULL,
    v LONGTEXT NULL,
    PRIMARY KEY (owner, k)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aura_contacts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    owner VARCHAR(80) NOT NULL,
    name VARCHAR(60) NOT NULL,
    number VARCHAR(20) NOT NULL,
    email VARCHAR(120) NULL,
    avatar TEXT NULL,
    favorite TINYINT(1) NOT NULL DEFAULT 0,
    blocked TINYINT(1) NOT NULL DEFAULT 0,
    note VARCHAR(255) NULL,
    INDEX (owner)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aura_calls (
    id INT AUTO_INCREMENT PRIMARY KEY,
    caller VARCHAR(20) NOT NULL,
    callee VARCHAR(20) NOT NULL,
    status VARCHAR(12) NOT NULL DEFAULT 'missed',
    duration INT NOT NULL DEFAULT 0,
    hidden TINYINT(1) NOT NULL DEFAULT 0,
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX (caller), INDEX (callee)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aura_conv (
    id VARCHAR(60) NOT NULL PRIMARY KEY,
    kind VARCHAR(8) NOT NULL DEFAULT 'direct',
    name VARCHAR(60) NULL,
    avatar TEXT NULL,
    owner VARCHAR(20) NULL,
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aura_conv_members (
    conv VARCHAR(60) NOT NULL,
    number VARCHAR(20) NOT NULL,
    muted TINYINT(1) NOT NULL DEFAULT 0,
    pinned TINYINT(1) NOT NULL DEFAULT 0,
    hidden TINYINT(1) NOT NULL DEFAULT 0,
    last_read BIGINT NOT NULL DEFAULT 0,
    PRIMARY KEY (conv, number),
    INDEX (number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aura_messages (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    conv VARCHAR(60) NOT NULL,
    sender VARCHAR(20) NOT NULL,
    kind VARCHAR(12) NOT NULL DEFAULT 'text',
    body TEXT NULL,
    meta TEXT NULL,
    reply_to BIGINT NULL,
    reactions TEXT NULL,
    created BIGINT NOT NULL,
    INDEX (conv, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aura_photos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    owner VARCHAR(80) NOT NULL,
    url TEXT NOT NULL,
    kind VARCHAR(8) NOT NULL DEFAULT 'photo',
    favorite TINYINT(1) NOT NULL DEFAULT 0,
    created BIGINT NOT NULL,
    INDEX (owner)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aura_accounts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    app VARCHAR(12) NOT NULL,
    identifier VARCHAR(80) NOT NULL,
    handle VARCHAR(30) NOT NULL,
    display VARCHAR(60) NOT NULL,
    avatar TEXT NULL,
    banner TEXT NULL,
    bio VARCHAR(200) NULL,
    verified TINYINT(1) NOT NULL DEFAULT 0,
    created BIGINT NOT NULL,
    UNIQUE KEY uq_handle (app, handle),
    UNIQUE KEY uq_owner (app, identifier)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aura_posts (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    app VARCHAR(12) NOT NULL,
    handle VARCHAR(30) NOT NULL,
    kind VARCHAR(8) NOT NULL DEFAULT 'post',
    body TEXT NULL,
    images TEXT NULL,
    parent BIGINT NULL,
    repost BIGINT NULL,
    created BIGINT NOT NULL,
    INDEX (app, created), INDEX (parent), INDEX (handle)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aura_likes (
    app VARCHAR(12) NOT NULL,
    post BIGINT NOT NULL,
    handle VARCHAR(30) NOT NULL,
    PRIMARY KEY (app, post, handle)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aura_follows (
    app VARCHAR(12) NOT NULL,
    follower VARCHAR(30) NOT NULL,
    followee VARCHAR(30) NOT NULL,
    PRIMARY KEY (app, follower, followee)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aura_match (
    identifier VARCHAR(80) NOT NULL PRIMARY KEY,
    name VARCHAR(40) NOT NULL,
    age TINYINT UNSIGNED NOT NULL DEFAULT 25,
    gender VARCHAR(10) NOT NULL DEFAULT 'autre',
    looking VARCHAR(10) NOT NULL DEFAULT 'tous',
    bio VARCHAR(250) NULL,
    photos TEXT NULL,
    active TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aura_swipes (
    identifier VARCHAR(80) NOT NULL,
    target VARCHAR(80) NOT NULL,
    liked TINYINT(1) NOT NULL,
    created BIGINT NOT NULL,
    PRIMARY KEY (identifier, target)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aura_bank_tx (
    id INT AUTO_INCREMENT PRIMARY KEY,
    identifier VARCHAR(80) NOT NULL,
    kind VARCHAR(12) NOT NULL,
    amount DOUBLE NOT NULL,
    other VARCHAR(80) NULL,
    label VARCHAR(120) NULL,
    created BIGINT NOT NULL,
    INDEX (identifier, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aura_bills (
    id INT AUTO_INCREMENT PRIMARY KEY,
    identifier VARCHAR(80) NOT NULL,
    issuer VARCHAR(80) NOT NULL,
    society VARCHAR(40) NULL,
    amount DOUBLE NOT NULL,
    reason VARCHAR(200) NULL,
    status VARCHAR(8) NOT NULL DEFAULT 'open',
    created BIGINT NOT NULL,
    INDEX (identifier, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aura_crypto (
    identifier VARCHAR(80) NOT NULL,
    coin VARCHAR(10) NOT NULL,
    amount DOUBLE NOT NULL DEFAULT 0,
    invested DOUBLE NOT NULL DEFAULT 0,
    PRIMARY KEY (identifier, coin)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aura_crypto_prices (
    coin VARCHAR(10) NOT NULL PRIMARY KEY,
    price DOUBLE NOT NULL,
    history TEXT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aura_market (
    id INT AUTO_INCREMENT PRIMARY KEY,
    identifier VARCHAR(80) NOT NULL,
    number VARCHAR(20) NOT NULL,
    seller VARCHAR(60) NOT NULL,
    title VARCHAR(80) NOT NULL,
    descr TEXT NULL,
    price DOUBLE NOT NULL DEFAULT 0,
    category VARCHAR(30) NOT NULL,
    images TEXT NULL,
    sold TINYINT(1) NOT NULL DEFAULT 0,
    created BIGINT NOT NULL,
    INDEX (category), INDEX (identifier)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aura_mail (
    id INT AUTO_INCREMENT PRIMARY KEY,
    owner VARCHAR(120) NOT NULL,
    from_addr VARCHAR(120) NOT NULL,
    to_addr VARCHAR(120) NOT NULL,
    subject VARCHAR(120) NOT NULL,
    body TEXT NULL,
    folder VARCHAR(8) NOT NULL DEFAULT 'inbox',
    seen TINYINT(1) NOT NULL DEFAULT 0,
    starred TINYINT(1) NOT NULL DEFAULT 0,
    created BIGINT NOT NULL,
    INDEX (owner, folder)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aura_dc_users (
        identifier VARCHAR(80) NOT NULL PRIMARY KEY, alias VARCHAR(24) NOT NULL, color VARCHAR(8) NOT NULL, changed BIGINT NOT NULL DEFAULT 0, UNIQUE KEY uq_alias (alias)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aura_dc_rooms (
        id VARCHAR(32) NOT NULL PRIMARY KEY, name VARCHAR(40) NOT NULL, public TINYINT(1) NOT NULL DEFAULT 1, pass VARCHAR(64) NULL,
        ttl INT NOT NULL DEFAULT 24, creator VARCHAR(80) NULL, created BIGINT NOT NULL, last BIGINT NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aura_dc_members (
        room VARCHAR(32) NOT NULL, identifier VARCHAR(80) NOT NULL, PRIMARY KEY (room, identifier), INDEX (identifier)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aura_dc_msgs (
        id BIGINT AUTO_INCREMENT PRIMARY KEY, room VARCHAR(32) NOT NULL, alias VARCHAR(24) NOT NULL, color VARCHAR(8) NOT NULL, body TEXT NULL, image TEXT NULL,
        created BIGINT NOT NULL, identifier VARCHAR(80) NOT NULL, INDEX (room, id)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aura_scores (
        game VARCHAR(16) NOT NULL, identifier VARCHAR(80) NOT NULL, name VARCHAR(40) NOT NULL, score INT NOT NULL, updated BIGINT NOT NULL, PRIMARY KEY (game, identifier), INDEX (game, score)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aura_news (
        id INT AUTO_INCREMENT PRIMARY KEY, title VARCHAR(100) NOT NULL, body TEXT NULL, image TEXT NULL, author VARCHAR(60) NOT NULL, author_id VARCHAR(80) NULL,
        source VARCHAR(40) NULL, breaking TINYINT(1) NOT NULL DEFAULT 0, created BIGINT NOT NULL, INDEX (created)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aura_loto_tickets (
        id INT AUTO_INCREMENT PRIMARY KEY, identifier VARCHAR(80) NOT NULL, nums VARCHAR(40) NOT NULL, draw INT NOT NULL, won INT NOT NULL DEFAULT 0, matches TINYINT NOT NULL DEFAULT 0, created BIGINT NOT NULL, INDEX (identifier, draw)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aura_loto_state (
        id TINYINT NOT NULL PRIMARY KEY, pool BIGINT NOT NULL, next_draw BIGINT NOT NULL, draw INT NOT NULL, last TEXT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aura_findmy (
        owner VARCHAR(80) NOT NULL, viewer VARCHAR(80) NOT NULL, PRIMARY KEY (owner, viewer)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── pickax_heists ──
CREATE TABLE IF NOT EXISTS pk_heists (
        identifier VARCHAR(60) NOT NULL, heist VARCHAR(40) NOT NULL,
        done LONGTEXT NULL, finales INT NOT NULL DEFAULT 0, last_finale INT NOT NULL DEFAULT 0,
        PRIMARY KEY (identifier, heist)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS=1;
