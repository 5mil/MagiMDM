//! JSON for parent apps. Wire GET /api/parent/devices behind a session.
const std = @import("std");

/// Example payload the Android/iOS clients decode.
pub const sample =
    \\\{"devices":[{"id":1,"name":"kid-phone","platform":"android","status":"enrolled","last_seen_at":"2026-09-08T12:00:00Z","policy":"SchoolDay"}]}\
;
