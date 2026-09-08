-- PC / laptop golden images (applied at enroll)
CREATE TABLE IF NOT EXISTS images (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    slug TEXT NOT NULL UNIQUE,
    label TEXT NOT NULL,
    os TEXT NOT NULL,
    arch TEXT NOT NULL DEFAULT 'x86_64',
    source_path TEXT,
    sha256 TEXT,
    seed_json TEXT NOT NULL DEFAULT '{}',
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS device_images (
    device_id INTEGER NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    image_id INTEGER NOT NULL REFERENCES images(id),
    applied_at TEXT NOT NULL DEFAULT (datetime('now')),
    PRIMARY KEY (device_id)
);

INSERT OR IGNORE INTO images (slug, label, os, seed_json) VALUES
('linux-debian12-student', 'Debian 12 student', 'linux',
 '{"hostname_prefix":"student","student_user":"student","admin_user":"parent","packages":["firefox-esr","libreoffice"]}'),
('windows11-student', 'Windows 11 student', 'windows',
 '{"hostname_prefix":"STUDENT","student_user":"student","admin_user":"parent"}');
