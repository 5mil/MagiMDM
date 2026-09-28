# Beat Ollama — full axis plan

You asked to beat it in all ways. That is two products glued together:

1. **House product** (MagiMDM + Arcis console) — winnable on this box this year.
2. **Runtime** (what `ollama run` is) — years of kernels, registry, and packaging unless you *wrap* llama.cpp instead of rewriting it.

Arcis already chose rewrite-in-Zig. Keep that for control. Do **not** pretend a custom attention.zig outruns Ollama’s llama.cpp/MLX next quarter.

Engine: https://github.com/5mil/arcis

---

## Scoreboard (how you actually win)

| Axis | Ollama today | Beat it by |
|------|----------------|------------|
| Model catalog | Thousands of tags, `ollama pull` | Import any GGUF + a small *curated* house catalog (Forma/Figura/Visio). Do not clone ollama.com. |
| Install | One script | `zig build` + one `arcis doctor` that checks RAM, GGUF, sidecars |
| Chat UX | Open WebUI / app | Parent desk: citations, library, terms, device-aware. Student-safe modes. |
| API | `/api/chat` + OpenAI-compat | Speak **both**: native Arcis + drop-in `/v1/chat/completions` so tools do not care |
| Speed | llama.cpp / MLX | **Link llama.cpp or llama.cpp-zig** for generate(); keep Zig for orchestration. Pure Zig generate is the long game. |
| Embeddings | nomic via Ollama | First-class embed in-process or sidecar; RAG is default, not an add-on |
| Vision | Many VL tags | Start with one small VL GGUF *or* a caption sidecar; worksheet photos |
| ASR | Not really | whisper.cpp first, Zig Whisper when encode is real |
| TTS | Not really | Piper first, Bark later if GPU appears |
| Image gen | No | sd.cpp / Comfy later; not P0 |
| Tools / agents | Growing | Figura ReAct that may only *read* MagiMDM + library; never set policy |
| Privacy | Local but generic | House LAN, no telemetry, student traffic never hits :9090 |
| Grounding | Prompt only | Library + validated terms + URNs on every answer |
| Multi-user | Weak | MagiMDM session = parent; Arcis has no kid login |
| Offline | Good | Equal + official-ISO style: models live in `data/gguf/` you already fetched |
| Docs / doctor | Medium | `arcis doctor` + MagiMDM `/settings` health |

If an axis is “faster 70B on NVIDIA,” you lost on purpose. This box is an i7 desktop. Win on **control, grounding, media sidecars, and MDM join**.

---

## Architecture that can pass Ollama

```
                  MagiMDM :8787 (devices)
                         |
                         | parent link
                         v
              Arcis console :9090
              /ask /library /terms /v1/chat/completions
                         |
          +--------------+----------------+
          v              v                v
   Infer backend     Sidecars         Stores
   A) llama.cpp      whisper.cpp      library / terms / names
      via Zig FFI    piper            sqlite or existing EntityStore
   B) Zig Session    optional sd.cpp
      when ready
   C) Ollama :11434
      labeled fallback only
```

Rule: **one facade**. The console never makes the parent pick “engine.” Doctor picks A, then B, then C.

OpenAI-compat `/v1/chat/completions` is how you beat Ollama *for other software* (Moodle plugins, parent app, scripts). Native `/ask` is how you beat it *for this house* (citations).

---

## Phases (all axes, ordered so each ships)

### A — Facade (beat the API + empty states)

- HTML console on `:9090` (library, ask, terms, health).
- `GET /health`, `GET /v1/models` (whatever is on disk + fallback).
- `POST /v1/chat/completions` even if backend is Ollama at first — same contract you will keep.
- `arcis doctor`

Exit: anything that talks OpenAI-compat can point at Arcis instead of Ollama.

### B — Grounding (beat chat quality for *your* data)

- Import + chunk + embed + `/ask` with hits.
- Terms in the system prompt.
- Refuse to answer IHIP/hours without a hit when `strict=1`.

Exit: Ollama raw chat loses on school questions because it cannot cite the folder.

### C — Fast infer (beat “it feels slow / dumb”)

- Ship llama.cpp (or `llama-server`) next to Arcis; Zig talks HTTP or FFI.
- Load Q4 1B/3B by default; 7B optional.
- Streaming tokens on `/v1/chat/completions`.
- Zig-native generate remains a compile flag `arcis -Dinfer=zig` until it matches latency within 2× on 1B.

Exit: interactive chat on tank without going through Ollama.

### D — Media (beat Ollama where it is empty)

- ASR: whisper.cpp `base.en`
- TTS: piper
- Vision: one small VL GGUF *or* moondream via fallback, labeled
- Image gen: explicit later milestone

Exit: parent can dictate a paragraph and hear a hint. Ollama cannot.

### E — Catalog without ollama.com

- `data/gguf/` + `catalog.toml` (name, file, ram_gb, kind: chat|embed|vl).
- `arcis pull llama3.2-1b` downloads **from the same official sources you already trust** (Hugging Face GGUF you name in the catalog), checksum, place file.
- No scraping Ollama’s registry.

Exit: one command installs the house set. Fewer models, better ones for this box.

### F — Agents (beat “just a chatbot”)

- One tool: `library.search`
- One tool: `magimdm.hours_export` (read-only file MagiMDM writes)
- One tool: `moodle.none` — do not scrape Moodle until REST token exists
- Approve-only drafts

Exit: weekly hours paragraph. Not auto-lock devices.

### G — Zig infer parity (optional prestige)

Only after C is default. Then replace FFI with `src/infer/session.zig` on 1B, then 3B. If you never get within 2×, keep llama.cpp. Beating Ollama for the family does not require a from-scratch CUDA kernel.

---

## What “all ways” does **not** mean

- More models than ollama.com.
- Faster than MLX on a Mac you do not own.
- Training SOTA weights on the XPS.
- Hiding Ollama if it is the only working generate() this month.
- Student access.

---

## Definition of done (product, not ego)

1. Point a client at Arcis `/v1` instead of Ollama; chat still works.
2. Ask a question about an imported lesson; answer has file + excerpt.
3. Dictate and hear speech without any Ollama media feature.
4. Doctor is green or names the missing binary.
5. MagiMDM still owns devices.
6. Ollama can be uninstalled and A+B+C+D still run (fallback off).

When 6 is true, you beat Ollama **as the house stack**. Until 6, Ollama is a spare tire with a label.
