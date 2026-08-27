# Agent poll extras

`POST /api/agent/poll` may include:

```json
{
  "uuid": "…",
  "battery_pct": 80,
  "agent_version": "0.1.0-android",
  "extras": {
    "mining_enabled": false,
    "mining_algo": "",
    "mining_url": ""
  }
}
```

Server stores `extras` on `devices.extras_json` (`touchDevice` + `extractExtrasJson`).
Agent sends this from `MiningController.extras` via `PollWorker`.

Helper: `src/poll_extras.zig`.
