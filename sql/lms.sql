-- College-format catalog. Unbounded courses per year.
CREATE TABLE IF NOT EXISTS courses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL,
  title TEXT NOT NULL,
  credit_hours REAL NOT NULL DEFAULT 3,
  kind TEXT NOT NULL DEFAULT 'home',
  track TEXT NOT NULL DEFAULT 'legal',
  nys_bucket TEXT,
  institution TEXT,
  openedx_key TEXT,
  year_id INTEGER REFERENCES school_years(id),
  UNIQUE(code, year_id)
);
CREATE TABLE IF NOT EXISTS enrollments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  course_id INTEGER NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  child_id INTEGER NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'student',
  UNIQUE(course_id, child_id)
);
CREATE TABLE IF NOT EXISTS outcomes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  enrollment_id INTEGER NOT NULL REFERENCES enrollments(id) ON DELETE CASCADE,
  as_of TEXT NOT NULL DEFAULT (datetime('now')),
  grade TEXT,
  narrative TEXT,
  percent REAL,
  source TEXT NOT NULL DEFAULT 'manual'
);
CREATE TABLE IF NOT EXISTS assignments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  course_id INTEGER NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  due_on TEXT,
  openedx_block TEXT
);
CREATE TABLE IF NOT EXISTS submissions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  assignment_id INTEGER NOT NULL REFERENCES assignments(id) ON DELETE CASCADE,
  child_id INTEGER NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  submitted_at TEXT NOT NULL DEFAULT (datetime('now')),
  body TEXT,
  file_path TEXT,
  status TEXT NOT NULL DEFAULT 'in'
);
