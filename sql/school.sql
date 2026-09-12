-- NY household year. Apply: sqlite3 data/mdm.db < sql/school.sql
CREATE TABLE IF NOT EXISTS school_years (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  label TEXT NOT NULL UNIQUE,
  starts_on TEXT NOT NULL,
  ends_on TEXT NOT NULL,
  is_current INTEGER NOT NULL DEFAULT 0,
  loi_due TEXT,
  ihip_due TEXT,
  q1_due TEXT, q2_due TEXT, q3_due TEXT, q4_due TEXT
);
CREATE TABLE IF NOT EXISTS children (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  given_name TEXT NOT NULL,
  family_name TEXT,
  grade_band TEXT NOT NULL DEFAULT '9-12',
  grade INTEGER,
  district TEXT,
  instructor TEXT,
  device_id INTEGER REFERENCES devices(id),
  notes TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS ihips (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  child_id INTEGER NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  year_id INTEGER NOT NULL REFERENCES school_years(id) ON DELETE CASCADE,
  submitted_on TEXT,
  status TEXT NOT NULL DEFAULT 'draft',
  UNIQUE(child_id, year_id)
);
CREATE TABLE IF NOT EXISTS ihip_subjects (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ihip_id INTEGER NOT NULL REFERENCES ihips(id) ON DELETE CASCADE,
  nys_bucket TEXT NOT NULL,
  materials TEXT,
  course_id INTEGER REFERENCES courses(id)
);
CREATE TABLE IF NOT EXISTS hour_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  child_id INTEGER NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  year_id INTEGER NOT NULL REFERENCES school_years(id),
  on_date TEXT NOT NULL,
  minutes INTEGER NOT NULL DEFAULT 0,
  course_id INTEGER REFERENCES courses(id),
  note TEXT
);
CREATE TABLE IF NOT EXISTS quarterlies (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  child_id INTEGER NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  year_id INTEGER NOT NULL REFERENCES school_years(id),
  quarter INTEGER NOT NULL CHECK(quarter BETWEEN 1 AND 4),
  hours REAL,
  body TEXT,
  submitted_on TEXT,
  UNIQUE(child_id, year_id, quarter)
);
CREATE TABLE IF NOT EXISTS assessments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  child_id INTEGER NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  year_id INTEGER NOT NULL REFERENCES school_years(id),
  kind TEXT NOT NULL DEFAULT 'narrative',
  result TEXT,
  file_path TEXT
);
