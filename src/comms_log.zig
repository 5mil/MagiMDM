//! Agent upload + parent list for comms archive.
const std = @import("std");

/// POST /api/agent/comms-log
/// { "uuid": "…", "events": [ { "ts", "direction", "kind", "peer", "allowed", "meta", "body" } ] }
pub const insert_sql =
    \\INSERT INTO comms_log (device_id, ts, direction, kind, peer, allowed, meta_json, body)
    \\SELECT d.id,
    \\       COALESCE(?, datetime('now')),
    \\       ?, ?, ?, ?,
    \\       ?, ?
    \\  FROM devices d WHERE d.uuid = ?;
;

/// GET /api/parent/comms?device_id= optional
pub const list_sql =
    \\SELECT c.id, c.ts, d.name, d.uuid, c.direction, c.kind, c.peer, c.allowed, c.body
    \\  FROM comms_log c
    \\  JOIN devices d ON d.id = c.device_id
    \\ WHERE (? IS NULL OR c.device_id = ?)
    \\ ORDER BY c.id DESC LIMIT 200;
;

pub const ack = "{\"ok\":true}";
