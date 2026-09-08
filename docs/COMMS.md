# Contacts, calls, texts, and comms archive

Policy decides who the student phone may call, text, and receive.
Emergency numbers (911, 112, 000, 110, 119, 999) are always allowed and are logged as emergency.

Household rule: the student knows the school phone is monitored. This is not covert spyware.

## Policy JSON

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

`logging` values:

| Value | Stored |
|-------|--------|
| `off` | Nothing |
| `deny_only` | Blocked call/SMS attempts |
| `metadata` | Time, direction, number, allowed/denied, SMS length — **not** SMS body |
| `sms_body` | Metadata + SMS/MMS body **only if** the agent is the default SMS app |

## What can be archived

- Calls the screening service sees (in/out, number, allow/deny)
- Native SMS/MMS when MagiMDM is default SMS role (`sms_body` or metadata)
- Agent check-ins and policy changes (existing audit)

## What cannot be archived (do not claim otherwise)

- WhatsApp, Signal, iMessage, RCS in Google Messages if not default SMS, Snapchat, etc. (E2E)
- HTTPS bodies of arbitrary apps
- A second unmanaged phone

Use app allowlists + school hours so those apps are not installed, rather than pretending to decrypt them.

## Server

`POST /api/agent/comms-log` with device uuid + events[].
Table `comms_log`. Nightly `deploy/backup.sh` already copies SQLite to `/srv/mdm/backups`.
Optional: `tools/comms_export.sh` → CSV on SAS.
