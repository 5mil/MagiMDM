# Contacts, calls, and texts (student Android)

Policy decides who the phone may call, text, and receive.
Emergency numbers (911, 112, 000, 110, 119) are **always** allowed.

## Policy JSON

```json
"comms": {
  "emergency_always": true,
  "allow_numbers": ["+15555550100", "5555550101"],
  "incoming": "allowlist",
  "outgoing_calls": "allowlist",
  "sms": "allowlist"
}
```

Values for incoming / outgoing_calls / sms:

| Value | Meaning |
|-------|---------|
| `allowlist` | Only `allow_numbers` |
| `block_all` | Nobody (exam) except emergency calls |
| `open` | No extra filter (Monitor / some Weekend) |

SchoolDay default: allowlist both directions + SMS.  
ExamLock: incoming allowlist (parent), outgoing_calls + sms `block_all`.  
AfterHours: allowlist, usually a longer number list.

## How the agent enforces

- Incoming: `CallGateService` (CallScreeningService) rejects numbers not on the list.
- Outgoing calls: Device Owner `DISALLOW_OUTGOING_CALLS` when mode is `block_all`; otherwise screening + stored allowlist. A custom default dialer is the only way to *hard* stop a raw `tel:` intent to a random number on every OEM — document that gap.
- SMS: Device Owner `DISALLOW_SMS` when `sms=block_all`. Allowlist SMS needs the agent as **default SMS app** (next slice: `SmsGate`). Until then treat SMS allowlist as best-effort + DISALLOW when exam.

Parent apps do not place student calls. They only edit the allowlist on the console/policy.
