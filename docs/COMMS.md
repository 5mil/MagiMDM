# Contacts, calls, texts, and comms archive

Emergency numbers (911, 112, 000, 110, 119, 999) always allowed.
Student should know the school phone is monitored.

## Policy

```json
"comms": {
  "emergency_always": true,
  "allow_numbers": ["+15555550100"],
  "incoming": "allowlist",
  "outgoing_calls": "allowlist",
  "sms": "allowlist",
  "logging": "metadata"
}
```

logging: `off` | `deny_only` | `metadata` | `sms_body`

## Live routes to wire in main.zig

| Method | Path |
|--------|------|
| POST | `/api/agent/comms-log` |
| GET | `/api/parent/comms` |
| GET | `/comms` page |

SQL: `sql/comms_log.sql`. Helpers: `src/comms_log.zig`.
Export: `tools/comms_export.sh`.

## Limits

No E2E app bodies. Full SMS archive needs default SMS role (`SmsGateStub`).
