# K3 Cognitive Router — Smoke Tests

Run after `bash scripts/install-to-local.sh` and restarting Cursor.

## Preconditions

- `~/.cursor/rules/k3-cognitive-runtime.mdc` exists
- `~/.cursor/skills/k3-cognitive-router/` exists
- `~/.cursor/agents/k3-cognitive-router.md` exists
- `bash scripts/audit-ecosystem.sh` exits 0 or 1 (warnings OK; exit 2 = fix errors)

## Test A — effort `low`

**Prompt:** `¿Qué es LatentMoE en una frase?`

**Expect:**

- Direct answer, no Task swarm
- Shared security only (no security-auditor spawn)
- No `.k3/orchestrator-state.json` created

## Test B — effort `high`

**Prompt:** `Añade una función utilitaria de rate-limit en el repo actual con tests. Usa el router cognitivo K3.`

**Expect:**

- Short plan + 2–4 specialists (e.g. coder, tester, reviewer)
- Scratchpad / preserved thinking visible in approach
- Security scanning expectations if code lands
- Optional state file; not required

## Test C — effort `max`

**Expect (post polish):**

- Domain `security`, `teacher_family=coding`, effort `max`, harness `security-max`
- Top-k from teacher_matrix + security specialists — **not** all agents
- `.k3/orchestrator-state.json` with `raova_phase`, scratchpad, checkpoints
- **GRM** `phase_artifacts.rubric` + `scorepad` before done
- Semgrep attempted; Snyk Code **not** required
- If incomplete: `paused_rollouts` present

## Pass criteria (all tests)

| Check | Pass |
|-------|------|
| Experts activated ≤ 8 | Yes |
| RAOVA / budgets considered on high/max | Yes |
| GRM scorepad on max | Yes |
| Deprecated cyber-* preferred over 01–19 | No (fail) |
| OpenRouter BYOK / Snyk Code required | No (fail) |
| Mega/antigravity catalog fully loaded | No (fail) |
