# RAOVA + effort budgets

## RAOVA

| Phase | Agent must |
|-------|------------|
| Reason | Classify domain/effort/teacher_family; write scratchpad goal + plan |
| Act | Call tools / edit / spawn Top-k Tasks only |
| Observe | Ingest outputs into scratchpad; never drop prior reasoning |
| Verify | Tests, Semgrep, or GRM scorepad |
| Adapt | Change plan/experts, checkpoint, or resume paused rollouts |

Stop claiming completion while `raova_phase` is still `act` without a Verify pass on `high`/`max`.

## Budgets (from K3 Reasoning Effort RL)

Cold-start estimate `b0` = rough expected work for the task (qualitative is fine in Cursor).

- Soft cap: do not exceed ~`τ · b0` of thrashing (repeated failed approaches with no new evidence).
- Agentic tasks count tool-call volume + reasoning; simple Q&A counts thinking only.
- Curriculum tip: prefer `high`; escalate to `max` only when needed; anneal down if overthinking.

## Verbosity (from K3 GRM)

If the deliverable is longer than needed for the rubric (`σ · ℓ0`), compress before final answer. Prefer artifacts + scorepad over essay padding.
