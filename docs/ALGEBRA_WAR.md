# Algebra War — MagiMDM module

A **Warcraft III–shaped RTS / Dota-shaped lane mode** where combat math *is* algebra. Not a Blizzard or Valve clone and not their art or names.

Lives next to `school` and `lms`. Outcomes write into the same SQLite file (`game_sessions`, `game_events`) and can attach to a `courses` row (`nys_bucket=mathematics`, `code=ALG1`).

Playable slice today: `web/algebra_war.html` (one mid lane, last-hit by solving).

---

## Why it is a module, not a second game studio

| Layer | Owns |
|-------|------|
| mdm | SchoolDay allows this origin; ExamLock can block it |
| school / lms | Course `ALG1` / `ALG2`, hours, grade |
| algebra-war | Match loop, problems, gold/XP |

Same binary serves the page. No extra daemon. Optional later: dedicated match server if you add 5v5 netcode.

---

## Two modes

### Skirmish (WC3-shaped)

- Map: base, gold, army cap.
- **Gold** = correct simplifications (`2(x+3)` → `2x+6`).
- **Train unit** = spend gold; unit cost is an expression you must evaluate at current `x` (tech level).
- **Attack** = subtract polynomials (HP is `ax+b`; damage is `c`). Last hit when HP reaches 0 after a true statement.
- Not in the first HTML slice.

### Lane (Dota-shaped) — shipped slice

- One mid lane, your hero, waves of creeps toward a tower.
- Creep HP label is an equation (`3x+1=10`). **Last-hit** = type `x` correctly while the creep is in the last-hit window (low HP).
- Miss / wrong answer: deny or lose gold (wrong answer feeds the tower).
- Tower falls when you bank N last-hits (algebra fluencies), not when you click it to death.
- Items later: `Boots` = speed of wave; `Wand` = one skip; paid with gold from solutions.

Difficulty bands map to courses:

| Band | Course | Items |
|------|--------|--------|
| 1 | pre-alg / Alg1 start | one-step `x+a=b`, `ax=b` |
| 2 | Alg1 | two-step, distribute |
| 3 | Alg1/2 | variables both sides |
| 4 | Alg2 | systems (2 creeps linked) |

---

## Algebra ↔ game

| Game verb | Algebra |
|-----------|---------|
| Last-hit | Solve for x |
| Deny | Correctly say “no integer / no solution” when we plant those |
| Gold | Accurate closed form |
| XP / level | Problem band unlocked |
| Tower | Cumulative fluency (N correct in a wave) |
| Item | Unlocks a legal move (distribute, factor) |
| Teamfight (later) | System of equations |

Hours: a match can add `hour_logs` minutes for `nys_bucket=mathematics` when the parent marks the session on the course.

---

## What this is not

- Warcraft III or Dota 2 assets, maps, or netcode.
- A replacement for Open edX sequences. Use Open edX for the written unit; use this for timed fluency.
- 5v5 ranked. Hotseat or vs-creeps first.

---

## Files

- `web/algebra_war.html` — playable lane
- `sql/algebra_war.sql` — sessions + events
- Route contract: `GET /algebra-war`
