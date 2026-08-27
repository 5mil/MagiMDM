# ZigMDM Android Agent

Kotlin scaffold. Repo: https://github.com/5mil/MagiMDM
Pool companion: https://github.com/fivemil/YarnRake

## Mining policy

Off unless the assigned policy includes:

```json
"mining": {"enabled": true, "algo": "skein", "stratum_url": "stratum+tcp://HOST:3333", "max_cpu_pct": 25}
```

`MiningController` stores the flag and stops when `enabled` is false or omitted.
No hasher is bundled — parental/work templates stay off.

## Polling

In-app ~30s; WorkManager `PollWorker` ≥15 min; `BootReceiver` reschedules.

Commands: lock, reboot, wipe (refused in scaffold), deploy_apk (simulated).
