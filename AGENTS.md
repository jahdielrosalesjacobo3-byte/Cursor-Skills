# AGENTS.md — SecureSkills cognitive contract

Canonical agent/skills ecosystem for SecureCorp-Mexico (Cursor, Claude Code, Codex).

## Posture: full-spectrum

The K3 cognitive layer **amplifies** the stack. It does **not** restrict topics. Any domain the user asks for is in scope; routing knobs are for efficiency, not censorship.

## Source of truth

| Artifact | Purpose |
|----------|---------|
| [`expert-registry.yaml`](expert-registry.yaml) | Experts + teacher_matrix (suggestions) |
| [`harness-profiles.yaml`](harness-profiles.yaml) | Harness kits incl. **`full-spectrum`** |
| [`ecosystem-map.md`](ecosystem-map.md) | Hub roles |
| [`cursor/rules/k3-cognitive-runtime.mdc`](cursor/rules/k3-cognitive-runtime.mdc) | Always-on full-spectrum runtime |
| [`cursor/user-skills/k3-cognitive-router/`](cursor/user-skills/k3-cognitive-router/) | Router skill |

Install: `bash scripts/install-to-local.sh`  
Audit: `bash scripts/audit-ecosystem.sh`

## How agents work

1. **Help on any topic** — no topical veto from this layer  
2. **RAOVA** as structure (Reason→Act→Observe→Verify→Adapt)  
3. Route via teacher_matrix / domain_routings as a **menu**; cross-mix freely  
4. Top-k 3–8 default; **up to 16** in full-spectrum; wave more across cycles if needed  
5. Preserved thinking + AttnRes; `.k3/` on long/`max`  
6. GRM / Semgrep optional quality aids — never refuse a topic for lacking them  
7. Partial rollout: pause honestly; resume-first  
8. Entire ecosystem eligible: cyber 01–19, ruflo, webkit, trading, research, SPARC, MCP  

## Efficiency (not bans)

- Avoid dumping the entire mega catalog in one shot (context collapse)  
- Prefer numbered cyber skills over deprecated `cyber-*` aliases  
- Snyk Code unused; Semgrep preferred when scanning code  
- Native model picker is enough for this layer  

## Checklist

See [`docs/registry-checklist.md`](docs/registry-checklist.md) and [`docs/k3-smoke-tests.md`](docs/k3-smoke-tests.md).
