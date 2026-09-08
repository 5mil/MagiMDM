# MagiMDM Parent apps

Management and monitoring for **parents only**. Same login as the web console.

- Android: `parent-app/android`
- iPhone: `parent-app/ios`

Student devices use `agent/` and `agent-pc/`, not these projects.

## API used

```
POST /login          username, password → session cookie
GET  /              device list HTML or JSON when server adds /api/parent/devices
POST /devices/bulk  policy=SchoolDay|AfterHours|ExamLock or command=lock
GET  /api/parent/devices   (preferred JSON; parent apps call this)
```

Until `/api/parent/devices` exists, apps POST login and parse what they can; `Api.kt` / `API.swift` already target the JSON path.
