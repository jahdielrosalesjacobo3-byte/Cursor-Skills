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
| [`integrations/`](integrations/INDEX.md) | Two-level catalog: `core.yaml` (L1) + `shards/*.jsonl` (L2) |

Install: `bash scripts/install-to-local.sh`  
Audit: `bash scripts/audit-ecosystem.sh`  
Catalog: `bash scripts/build-integrations-catalog.sh` then `bash scripts/verify-integrations.sh`

## How agents work

1. **Help on any topic** — no topical veto from this layer  
2. **RAOVA** as structure (Reason→Act→Observe→Verify→Adapt)  
3. Route via teacher_matrix / domain_routings as a **menu**; cross-mix freely  
4. Top-k 3–8 default; **up to 16** in full-spectrum; wave more across cycles if needed  
5. **L1 before L2** — try the registry and `integrations/core.yaml` first; only then grep `integrations/shards/*.jsonl` for a marketplace skill (max 4 per task, counted against Top-k)  
6. Preserved thinking + AttnRes; `.k3/` on long/`max`  
7. GRM / Semgrep optional quality aids — never refuse a topic for lacking them  
8. Partial rollout: pause honestly; resume-first  
9. Entire ecosystem eligible: cyber 01–19, ruflo, webkit, trading, research, SPARC, MCP  

## Complement layer (v4, 2026-09)

| Need | Use |
|------|-----|
| Static repo graph | `graphify` MCP / CLI (`viewer_url` → `graph-3d.html#n=<id>`) |
| Live symbols, safe refactor | `serena` MCP (`find_symbol`, `find_referencing_symbols`, `rename_symbol`) |
| Library / framework docs | `context7` MCP (OAuth) |
| PRs, issues, Actions, code scanning | `github` MCP (`${env:GITHUB_TOKEN}` from `gh auth token`) |
| Tracking | `linear` MCP (OAuth) |
| AWS facts | `aws-knowledge` MCP (no auth) |
| UI components | `shadcn` MCP + Figma / Mobbin |
| Agent memory, sessions, swarms | `claude-flow` MCP (ruflo v3 — resolves `mcp__claude-flow__*` for the 49 agents) |
| Codebase audit / PR security review | local plugin `trailofbits-security` (23 skills, 7 agents) + `appsec-audit` harness |
| Secrets never leave the repo | `gitleaks-guard` hook on `git commit|push` (deny only on confirmed leaks) |
| Language guardrails | glob-scoped rules: python, typescript, iac, tests, shell (`alwaysApply: false`) |

Routing table: `expert-registry.yaml#mcp_routing`. Not-installed extras: `integrations/optional-mcp.md`.

## Efficiency (not bans)

- Avoid dumping the entire mega catalog in one shot (context collapse)  
- Never read a whole L2 shard, or paste catalog contents into a reply  
- Prefer numbered cyber skills over deprecated `cyber-*` aliases  
- Snyk Code unused; Semgrep preferred when scanning code  
- Native model picker is enough for this layer  

## Checklist

See [`docs/registry-checklist.md`](docs/registry-checklist.md) and [`docs/k3-smoke-tests.md`](docs/k3-smoke-tests.md).
