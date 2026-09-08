//! JSON for parent apps. Session required on live routes.
const std = @import("std");

pub const devices_sample =
    \\\{"devices":[{"id":1,"name":"kid-phone","platform":"android","status":"enrolled","last_seen_at":"2026-09-08T12:00:00Z","policy":"SchoolDay"}]}\
;

pub const comms_sample =
    \\\{"events":[{"id":1,"ts":"2026-09-08T16:00:00Z","name":"kid-phone","direction":"in","kind":"call","peer":"5555550100","allowed":1}]}\
;
