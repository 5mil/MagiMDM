# Arcis console — past Ollama, only where this house needs it

Ollama stays a **runtime**: pull a tag, chat, embed, tiny vision.
Arcis becomes the **homeschool instrument**: your texts, your year, your terms, optional speech.
MagiMDM stays the **device box**. The Arcis UI is a sibling tab, not a second MDM.

Engine: https://github.com/5mil/arcis
Desk:   https://github.com/5mil/MagiMDM

---

## What “better than Ollama” means here

Not a prettier chat. Ollama already wins at model menu + HTTP.

Win on jobs Ollama will never own:

1. **Grounded answers** over *this family’s* materials (IHIP, lesson PDFs, Moodle exports, NYS hour notes).
2. **A library** with titles, tags, pages — not a context window dump.
3. **Terms that do not drift** (sophia = wisdom, proposed → validated) so Algebra War and Moodle labels stay consistent.
4. **Speech in/out** as house tools (transcribe a read-aloud, speak a hint) without waiting for Ollama TTS.
5. **One parent login story**: MagiMDM session can open Arcis; students never get the console.
6. **Fail closed** when no GGUF / no sidecar is present. Empty state, not a fake transcript.

Do not rebuild: device enroll, Device Owner, USB ISO, Moodle gradebook, Ollama `/api/tags`.

---

## Target surface (parent only)

Path on tank, later: `http://192.168.50.143:9090` (Arcis `--port 9090`).
MagiMDM desk link: `/lms`-style card “Library / tutor” → that origin.

Screens (map to existing `ViewKind` in arcis `src/dashboard/views.zig`):

| Screen | ViewKind | Need |
|--------|----------|------|
| Home | admin | counts: texts, pending terms, whether a GGUF is loaded |
| Library | reading | ingest file, paginate body, tags |
| Ask | search + infer | retrieve top-k chunks, then generate with citation URNs |
| Terms | term | propose / validate; no silent rename |
| Names | naming | optional; keep folded under Advanced |
| Voice | media | upload wav → transcript; text → Piper wav |
| Health | — | GGUF path, whisper.cpp binary, piper binary, RAM |

No student-facing Arcis. SchoolDay allowlist does not include `:9090` or `:11434`.

---

## Capability split (do not collapse)

```
MagiMDM :8787     devices, policy, enroll, Moodle link
Ollama  :11434    leftover general chat + embed if Arcis GGUF missing
Arcis   :9090     library, RAG ask, terms
whisper.cpp       ASR sidecar  (until Zig Whisper encode is real)
piper             TTS sidecar  (do not wait for Bark)
Moodle  :8888     courses of record
```

Inference policy:

- If `models/llama-3.2-1b.gguf` (or configured path) loads → Ask uses Arcis `Session.generate`.
- Else Ask may call Ollama `llama3.2:3b` as **fallback only**, labeled in the UI “box runtime”.
- Never hide which engine answered.

---

## Phases

### P0 — Truth (1 week of evenings)

Arcis today: GGUF loader exists; Whisper `encode` is zeros; dashboard is payloads, not HTML.

- [ ] One HTML shell in-tree (`src/dashboard/static/index.html`) served by `src/api/server.zig` at `/`.
- [ ] `GET /health` returns `{ tier, gguf_loaded, texts, ollama_fallback }`.
- [ ] Load one GGUF from `ARCIS_GGUF=` env; if missing, health says so.
- [ ] MagiMDM `/settings` lists Arcis URL. No Zig proxy yet.

Exit: parent laptop opens `:9090` and sees loaded / not loaded. No fake chat.

### P1 — Library + Ask that cites (the product)

- [ ] `POST /import` text/markdown/pdf-text; `catalog.ingest`.
- [ ] Chunk + embed (Arcis embedder or Ollama `nomic-embed-text` if Zig embed is weak).
- [ ] `POST /ask` `{ q }` → `{ answer, hits: [{ urn, title, score, excerpt }] }`.
- [ ] Reading view: page through one text.
- [ ] Seed folder `data/library/year/` for 2026–27 outlines — not the whole internet.

Exit: parent pastes a lesson, asks “what hours does algebra need this week”, gets snippets with titles.

### P2 — Terms + school vocabulary

- [ ] Wire `/term/propose` `/term/validate` to the HTML Terms screen.
- [ ] Import Moodle glossary CSV or a hand list (integer, polynomial, …).
- [ ] Ask prompt always includes validated terms for the active domain.

Exit: the model cannot redefine “credit” contrary to a validated term without showing the fork.

### P3 — Voice sidecars (not Zig media fantasies)

Until `whisper.zig` encode is a real forward pass:

- [ ] `whisper.cpp` tiny/base.en on tank; Arcis `POST /asr` shells out or HTTP to it.
- [ ] `piper` one `en_US` voice; `POST /tts`.
- [ ] UI: file picker + play button. Parent only.

Do not block P1 on Bark or EnCodec. Revisit Zig Whisper only after P1 cites sources.

### P4 — MagiMDM join

- [ ] Same-LAN link from MagiMDM desk “Library”.
- [ ] Optional shared cookie later; v1 is two logins on the same house net.
- [ ] Device policy never grants students `:9090`.
- [ ] Hour-log / IHIP markdown can be imported as library texts (read-only from MagiMDM export).

### P5 — Agents / workflow (Figura) only if P1 is used weekly

ReAct planner exists in Arcis. Do not expose it until Ask+Library is the daily tool. First agent: “draft weekly hours paragraph from library + MagiMDM hour_logs dump.” Human approve. No autonomous policy changes.

---

## Hardware on this box (XPS-class i7, ~16 GB)

| Piece | Fit |
|-------|-----|
| llama 3.2 1B GGUF Q4 | default Arcis infer |
| llama 3.2 3B or qwen 7B Q4 | if RAM allows; one loaded at a time |
| nomic-embed via Ollama | fine for P1 |
| whisper.cpp tiny/base.en | ASR |
| piper | TTS |
| 11B vision / 70B / Bark GPU | skip |

---

## Explicit non-goals

- Open WebUI clone.
- Replacing Moodle quizzes.
- Replacing MagiMDM enroll/QR/USB.
- Shipping stub Whisper as ASR.
- Student chatbot.
- Training foundation models on the desk.

---

## Done when

A parent can: import this week’s lesson → ask a question → see the excerpt and file name → optional read-aloud via Piper → devices still managed only in MagiMDM.

If that loop is slower or worse than raw Ollama chat on the same GGUF, the console failed. Citations and library are the reason it exists.
