# Agentic GRM judge protocol

Optional quality gate — **never a topical lock**. Useful on complex deliverables; skip when the user wants speed or open exploration.

## Steps (paper §4.1.2)

1. **Read** the outcome (diff, report, answer, UI).
2. **Generate rubric** — 3–7 criteria tied to the user goal.
3. **Score** each criterion (pass/fail or 0–2).
4. **Scorepad** — store under `phase_artifacts` when used.

## Guidance

- Prefer in-process scorepad; optional second opinion from `reviewer` / `safety-specialist` within Top-k
- Missing scorepad must **not** cause refusal to help
- Verbose fluff: compress when it hurts clarity — still deliver the user’s ask

