//! POST /api/agent/comms-log  { uuid, events: [ { ts, direction, kind, peer, allowed, meta, body } ] }
const std = @import("std");

pub const insert_sql =
    \\INSERT INTO comms_log (device_id, ts, direction, kind, peer, allowed, meta_json, body)
    \\SELECT d.id, ?, ?, ?, ?, ?, ?, ? FROM devices d WHERE d.uuid = ?;
;

pub const sample =
    \\\{"uuid":"…","events":[{"ts":"2026-09-08T16:00:00Z","direction":"in","kind":"call","peer":"+15555550100","allowed":true}]}\
;
