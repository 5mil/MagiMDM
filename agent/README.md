# ZigMDM Android Agent (minimal)

Kotlin scaffold for Device-Owner agent talking to MagiMDM / ZigMDM.

**Repo:** https://github.com/5mil/MagiMDM

See [main README](../README.md) and [docs/DEPLOY.md](../docs/DEPLOY.md).

## Quick start

1. Open `agent/` in Android Studio
2. Emulator server URL: `http://10.0.2.2:8787`
3. Optional Device Owner:

```bash
adb shell dpm set-device-owner com.zigmdm.agent/.MdmDeviceAdminReceiver
```

4. Enroll with token from `/enroll` → Start polling

## Polling

- In-app: ~30s (`MainActivity`)
- Background: WorkManager `PollWorker` (≥15 min)
- Boot: `BootReceiver` reschedules WorkManager

## Commands

`lock`, `reboot`, `wipe` (refused in scaffold), `deploy_apk` (simulated)
