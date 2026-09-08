CREATE TABLE IF NOT EXISTS comms_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    device_id INTEGER NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    ts TEXT NOT NULL DEFAULT (datetime('now')),
    direction TEXT NOT NULL,
    kind TEXT NOT NULL,
    peer TEXT,
    allowed INTEGER NOT NULL DEFAULT 1,
    meta_json TEXT,
    body TEXT
);
CREATE INDEX IF NOT EXISTS comms_log_dev_ts ON comms_log(device_id, ts);
