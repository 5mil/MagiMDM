-- Homeschool templates. mining.enabled always false.
INSERT OR IGNORE INTO policies (name, description, config_json, is_default) VALUES
('Baseline', 'Floor for every student device',
 '{"mining":{"enabled":false},"install_lock":true,"unknown_sources":false,"encryption":true}', 1),
('SchoolDay', 'Weekday class hours',
 '{"mining":{"enabled":false},"mode":"school","hours":{"start":"08:00","end":"15:00","days":[1,2,3,4,5]},"apps_allow":["org.mozilla.firefox","org.documentfoundation.libreoffice"],"install_lock":true,"camera":false,"usb_file_transfer":false}', 0),
('AfterHours', 'Evening cap',
 '{"mining":{"enabled":false},"mode":"after","hours":{"start":"15:00","end":"20:00"},"curfew":"20:00","install_lock":true}', 0),
('ExamLock', 'Single-task exam',
 '{"mining":{"enabled":false},"mode":"exam","kiosk":true,"install_lock":true,"camera":false}', 0),
('Weekend', 'Weekend lighter rules',
 '{"mining":{"enabled":false},"mode":"weekend","curfew":"21:00"}', 0),
('Monitor', 'Inventory only (tutor/guest)',
 '{"mining":{"enabled":false},"mode":"monitor","enforce":false}', 0);

CREATE TABLE IF NOT EXISTS term_calendar (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    starts_on TEXT NOT NULL,
    ends_on TEXT NOT NULL,
    kind TEXT NOT NULL DEFAULT 'term'
);

INSERT OR IGNORE INTO term_calendar (id, name, starts_on, ends_on, kind) VALUES
(1, 'Fall', '2026-08-17', '2026-12-18', 'term'),
(2, 'Winter break', '2026-12-19', '2027-01-04', 'break'),
(3, 'Spring', '2027-01-05', '2027-05-29', 'term'),
(4, 'Exam week fall', '2026-12-14', '2026-12-18', 'exam');
