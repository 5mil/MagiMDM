CREATE TABLE IF NOT EXISTS game_sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  child_id INTEGER REFERENCES children(id),
  course_id INTEGER REFERENCES courses(id),
  mode TEXT NOT NULL DEFAULT 'lane',
  band INTEGER NOT NULL DEFAULT 1,
  started_at TEXT NOT NULL DEFAULT (datetime('now')),
  ended_at TEXT,
  gold INTEGER NOT NULL DEFAULT 0,
  last_hits INTEGER NOT NULL DEFAULT 0,
  misses INTEGER NOT NULL DEFAULT 0,
  tower_down INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS game_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL REFERENCES game_sessions(id) ON DELETE CASCADE,
  ts TEXT NOT NULL DEFAULT (datetime('now')),
  kind TEXT NOT NULL,
  prompt TEXT,
  answer TEXT,
  correct INTEGER NOT NULL DEFAULT 0
);
INSERT OR IGNORE INTO courses(code,title,credit_hours,kind,track,nys_bucket)
  VALUES('ALG1-WAR','Algebra 1 fluency (Algebra War)',1,'home','legal','mathematics');
