# Changelog — SecureSkills

## 2026-07-29 — K3 cognitive layer + full-spectrum ecosystem

### Added

- **K3 cognitive runtime** (`cursor/rules/k3-cognitive-runtime.mdc`) — RAOVA, Top-k, AttnRes, full-spectrum posture
- **Skill + agent** `k3-cognitive-router` with references (budgets, GRM optional, partial-rollout, schema)
- **`expert-registry.yaml`** — expert catalog, `teacher_matrix` (9 teachers), domain routings
- **`harness-profiles.yaml`** — white-box profiles incl. `full-spectrum` + phrase overrides
- **`AGENTS.md`**, **`ecosystem-map.md`**
- **`scripts/audit-ecosystem.sh`**
- **Docs**: smoke tests, registry checklist, smoke-results
- **Fixtures**: `fixtures/k3-smoke` rate limiter + unit tests
- Claude profiles: `k3_domain` + `default_effort`
- Install copies registry/harness/AGENTS to `~/.cursor/secureskills/`

### Changed

- `install-to-local.sh` / `export-from-local.sh` — rules, user-skills, cyber dedupe, secureskills bundle
- `security-scanning.mdc` — Semgrep primary; Snyk Code unused; **non-blocking / no topical veto**
- Project template rules include K3 runtime
- `cyber-*` Claude skills → **symlinks** to numbered `01–19` (dedupe)

### Policy

- No OpenRouter/BYOK expansion in this layer (Cursor native models)
- Full-spectrum: no domain veto from the cognitive layer; Top-k up to 16
- Snyk Code disabled by team decision
