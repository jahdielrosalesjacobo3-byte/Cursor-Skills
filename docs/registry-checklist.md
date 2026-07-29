# Registry consistency checklist (pre-commit / PR)

Use before committing changes to SecureSkills agent/skill/config trees.

1. Run `bash scripts/audit-ecosystem.sh`
   - Exit `2` → fix errors before commit
   - Exit `1` → review warnings (OpenRouter docs warn is expected/informational)
   - Exit `0` → clean
2. New file under `cursor/agents/*.md` → add matching `id` in `expert-registry.yaml` **and** consider `teacher_matrix` cell
3. New always-on behavior → add under `cursor/rules/` and mark `shared: true` in registry
4. Do not reintroduce `cyber-*` as full directories; keep relative symlinks to `01–19`
5. Do not expand OpenRouter/BYOK; do not require Snyk Code
6. Profiles: keep `k3_domain` + `default_effort` in sync with registry
7. Harness changes → update `harness-profiles.yaml` and reinstall to `~/.cursor/secureskills/`
8. After local experimentation: `bash scripts/export-from-local.sh` then review `git diff`
9. Smoke: `docs/k3-smoke-tests.md` (max must include GRM scorepad)
