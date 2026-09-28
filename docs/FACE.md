# Face — 28 Sep 2026 (evening)

Two stacks on tank. Parents touch MagiMDM. Arcis holds published weights + traces.

## MagiMDM :8787 — https://github.com/5mil/MagiMDM

| Piece | State |
|-------|--------|
| Login / LAN bind | works |
| Desk chrome | works |
| `src/lists.zig` | devices + comms from SQLite |
| `main.zig` stubs | **replace** empty `[]` with `lists.*Json` (docs/NEXT_BOTH.md) |
| `/ai` page | embed ready; add GET `/ai` if 404 |
| Bulk School/Lock | persist when main hunk applied |
| Moodle :8888 | Docker; watch wwwroot |
| Agents | enroll/poll JSON; APK not from zig build |

## Arcis :9090 — https://github.com/5mil/arcis

| Piece | State |
|-------|--------|
| Q4_K dequant + qwen2 keys | in tree |
| `pull_gguf.sh` R1 1.5B | catalog |
| `pull_traces.sh` OpenThoughts | catalog |
| GET `/` HTML | `static_index.html` + handleRoot (pull this commit) |
| `/infer` | needs `--model` and generate() |
| Whisper | still stub |

## Pull on tank

```bash
cd ~/magimdm && git pull && /opt/zig/zig build
cd ~/arcis && git pull && zig build
./tools/pull_gguf.sh r1-1.5b-q4
./zig-out/bin/arcis --tier forma --port 9090 --model models/gguf/DeepSeek-R1-Distill-Qwen-1.5B-Q4_K_M.gguf
```

Desk: http://192.168.50.143:8787/ 
Library: http://192.168.50.143:9090/ 
Moodle: http://192.168.50.143:8888/ 
