-- Facultatif : les tables sont créées automatiquement au démarrage de la ressource.
CREATE TABLE IF NOT EXISTS activejobs_points (
  id INT AUTO_INCREMENT PRIMARY KEY, job VARCHAR(30) NOT NULL, kind VARCHAR(20) NOT NULL, label VARCHAR(80) NULL,
  x FLOAT NOT NULL, y FLOAT NOT NULL, z FLOAT NOT NULL, h FLOAT NOT NULL DEFAULT 0, INDEX idx_job (job, kind)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS activejobs_stats (
  identifier VARCHAR(80) NOT NULL, job VARCHAR(30) NOT NULL, xp INT NOT NULL DEFAULT 0, done INT NOT NULL DEFAULT 0, earned INT NOT NULL DEFAULT 0,
  PRIMARY KEY (identifier, job)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS activejobs_farm (
  identifier VARCHAR(80) NOT NULL, plot INT NOT NULL, crop VARCHAR(30) NOT NULL, planted BIGINT NOT NULL, watered TINYINT NOT NULL DEFAULT 0,
  PRIMARY KEY (identifier, plot)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
