# K3 Smoke Test Results — 2026-07-29

Runner: Cursor agent after user restart.  
Audit: `errors=0`, `warnings=1` (OpenRouter docs archived — expected).

## Preconditions

| Check | Result |
|-------|--------|
| `~/.cursor/rules/k3-cognitive-runtime.mdc` | PASS |
| `~/.cursor/skills/k3-cognitive-router/` | PASS |
| `~/.cursor/agents/k3-cognitive-router.md` | PASS |
| `audit-ecosystem.sh` exit 0 or 1 | PASS (exit 1, warn only) |
| Agents installed | 49 |
| Profiles `k3_domain` | PASS (`security` → max) |

---

## Test A — effort `low`

**Prompt:** ¿Qué es LatentMoE en una frase?

**Routing:** `domain=general`, `effort=low`, Task=0, shared only.

**Answer (executed):** LatentMoE es un MoE que mezcla expertos en un espacio latente comprimido para activar muchos especialistas (p. ej. 16 de 896) con menor costo de tráfico/cómputo que un MoE denso clásico.

**Checks:**

| Expect | Result |
|--------|--------|
| Direct answer, no Task swarm | PASS |
| No security-auditor spawn | PASS |
| No `.k3/orchestrator-state.json` for this low task in skillsClaude | PASS |

---

## Test B — effort `high`

**Routing:** `domain=coding`, `effort=high`, experts: `coder`, `tester`, `reviewer` (+ shared). Count=5 ≤ 8.

**Scratchpad:** Need portable sliding-window limiter + unittest; place under `fixtures/k3-smoke/` so SecureSkills stays the canonical hub.

**Deliverables:**

- `fixtures/k3-smoke/rate_limit.py`
- `fixtures/k3-smoke/test_rate_limit.py`
- `python3 -m unittest` → **5/5 OK**

**Checks:**

| Expect | Result |
|--------|--------|
| Plan + 2–4 specialists | PASS (coder/tester/reviewer) |
| Preserved thinking | PASS (scratchpad above) |
| Security expectations noted | PASS (no secrets; pure util) |
| Experts ≤ 8 | PASS |

---

## Test C — effort `max`

**Routing:** `domain=security`, `effort=max`.  
**Top-k (7):** k3-cognitive-router, security-auditor, safety-specialist, owasp-security, review-security, security-scanning, semgrep-hooks.

**Note:** Este hub no tiene auth/middleware de app; se auditó la superficie de confianza del stack de agentes (MCP/hooks) + fixture.

**State file:** `.k3/orchestrator-state.json` — PASS (scratchpad + checkpoints + attnres_keys).

**Findings:**

- MCP/hooks: comandos absolutos, sin secrets en env — OK
- Semgrep CLI: disponible; scan fixture sin hallazgos reportados en quiet mode
- Snyk auth: **OK** (`snyk whoami` → `jahdielrosalesjacobo3-byte`)
- Snyk Code: **no usado por ahora** (fuera de alcance operativo); SAST vía Semgrep
- BYOK OpenRouter: presente pero fuera de alcance — info only

**Checks:**

| Expect | Result |
|--------|--------|
| Top-k security, not all 48 agents | PASS (7) |
| orchestrator-state.json | PASS |
| Consolidation/judge | PASS (checkpoints) |
| Semgrep/Snyk attempted | PASS (Snyk auth gap documented) |

---

## Global pass criteria

| Check | Pass |
|-------|------|
| Experts activated ≤ 8 | YES |
| Deprecated cyber-* preferred over 01–19 | NO (used numbered) |
| OpenRouter BYOK required | NO |
| Mega/antigravity fully loaded | NO |

## Verdict

**ALL SMOKE TESTS PASSED.**

Ops (2026-07-29):
1. `snyk auth` — DONE (cuenta autenticada; útil para SCA/IaC/MCP si se usan).
2. **Snyk Code** — **no se usa por ahora** (decidido). No bloquear audits ni smoke tests por `SNYK-CODE-0005`. Preferir Semgrep (+ hooks) para SAST hasta nueva orden.
