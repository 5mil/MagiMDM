# MagiMDM as a product

One house box. Parent desk. 1–10 student devices. Classwork in Moodle. Optional local models.
Repo: https://github.com/5mil/MagiMDM

## Promise

A parent can:

1. Sign in on the LAN desk.
2. Enroll a blank Android (QR) or blank PC (official ISO + USB pack).
3. Put the house in School / Free / Exam / Lock.
4. Open Moodle for real courses.
5. See last-seen and comms the agent actually uploaded.
6. Optionally chat with models that *this box* already has.

Kids never get a MagiMDM login. Mining stays off on student policies.

## Layers (do not flatten them)

| Layer | Job | Today |
|-------|-----|-------|
| zig-mdm :8787 | Auth, tokens, policies, agent API, desk UI | Running on tank if built from main |
| Android agent | Device Owner + poll | Scaffold; APK not produced by `zig build` |
| PC agent | Linux service / Windows task | Scripts exist; need first successful image |
| Moodle :8888 | Courses, quizzes, grades | Docker; wwwroot/LAN still the fragile bit |
| Ollama :11434 | Parent side tool | Optional; `/ai` page + `tools/arcis_ollama.sh` |
| Arcis | Native GGUF/RAG engine | Separate repo; not required to run MagiMDM |

## Honest status

**Works if you pull, build, and stay on the LAN**

- Login (`admin` / `changeme` until changed)
- Desk chrome: `/` `/devices` `/enroll/pc` `/policies` `/school` `/lms` `/comms` `/settings`
- Token create + QR page for Android; USB notes + `os_fetch.sh` for official ISOs
- Agent enroll/poll/ack JSON
- Algebra War routes
- Policy *buttons* POST `/devices/bulk` (queued text, not yet per-device DB apply)

**Looks finished in docs, thin in the binary**

- `/api/parent/devices` returns `[]` — desk fleet is empty even after enroll
- `/api/parent/comms` returns `[]` — archive UI has no rows
- Bulk policy does not write `devices.policy_id`
- No `/audit` page
- `/ai` HTML exists; `main.zig` may 404 until the GET `/ai` line is in the running binary
- Moodle is not SSO with MagiMDM
- Student iPhone is not an MDM target
- Parent apps (`parent-app/`) are not the desk

**Out of scope for v1 (say so in the UI)**

- Apple Business Manager
- WhatsApp / iMessage capture
- Cloud LLM requirement
- Mining on student devices
- Replacing Moodle with a Zig LMS

## Complete product = these 12 gates

1. Cold start: Ubuntu box + Zig 0.16 + `zig build` + `/login` from another PC.
2. Password changed; only parent sessions.
3. Blank Android: six-tap QR → Device Owner → last-seen updates on `/devices`.
4. Blank Linux *or* Windows: official ISO from `os_fetch.sh` + token pack → last-seen.
5. School button → Moodle reachable; extra browsers blocked on that device class.
6. Lock button → next poll locks.
7. Exam button → quiz URL only (policy JSON + agent honor it).
8. Comms page shows a real call or SMS from a lab phone.
9. Moodle: one course, one student, one quiz, year catalog row in MagiMDM.
10. Backup: `data/mdm.db` + Moodle backup copied off-box.
11. Ollama optional: `ollama list` non-empty → `/ai` lists those names. Fail closed if Ollama is off.
12. Weekend checklist in PARENT_GUIDE passes without editing source.

Until 3 and 4 and the devices API read SQLite, this is a **console plus agents**, not a fleet product.

## Build order (do not skip)

1. SELECT devices / comms into the parent APIs (desk becomes true).
2. Persist bulk policy onto each device row; poll returns *that* policy.
3. Serve `/agent.apk` from `data/apk/` so factory QR works.
4. One successful Device Owner phone and one successful PC image.
5. Moodle wwwroot + `learn.home` documented as the only classroom URL.
6. GET `/ai` in `main.zig` + Ollama bind + Arcis-mapped pulls.
7. Audit log page.
8. Then parent-app polish.

## Related trees

- MagiMDM — this product
- https://github.com/5mil/arcis — Zig GGUF/RAG if you want native infer later
- Moodle — classroom of record
