# Changelog — SecureSkills

## 2026-07-30 — Full integrations catalog + L1/L2 routing

### Added

- **`integrations/`** — generated two-level catalog: `catalog.json` (root manifest),
  `core.yaml` (L1: 2 MCP, 4 hooks, 2 rules, 49 agents, 79 canonical skills, 11 profiles),
  15 JSONL shards indexing **5 078** marketplace plugin skills, and `INDEX.md`
- **`scripts/build-integrations-catalog.sh`** + `scripts/lib/build_catalog.py` — dependency-free
  scanner with frontmatter parsing, cross-bundle dedup and K3 domain classification
- **`scripts/verify-integrations.sh`** — health check for CLIs, MCP commands, hook binaries,
  K3 artifacts, symlinks and catalog drift
- **`scripts/lib/build_manifest.py`** — manifest generator, now including catalog counts
- **`catalog-l2.md`** — L2 lookup protocol for the router

### Changed

- `expert-registry.yaml` v3 — `catalog_l2`, `catalog_core` and `lookup_policy` (L1 → L2, max 4 per task)
- `harness-profiles.yaml` v2 — `catalog_access` per profile plus `preferred_marketplaces`;
  fixed an unquoted header that made the file invalid YAML
- `k3-cognitive-runtime.mdc`, router skill and agent — L1-before-L2 protocol and shard guardrails
- `orchestrator-state.schema.json` — tracks `l2_activations`
- `install-to-local.sh` installs the catalog; `export-from-local.sh` regenerates it;
  `audit-ecosystem.sh` verifies shard/catalog consistency
- `plugins-manifest.json` v3 — corrected `agentsCount` (48 → 49) and added the integrations block

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
