# SecureSkills

Repositorio centralizado de **skills**, **agents/subagents**, **plugins**, **MCPs**, **rules** y la **capa cognitiva K3** para SecureCorp-Mexico.

Compatible con **Cursor Agent**, **Claude Code** y **Codex**.

**Hub canónico** del ecosistema global de agentes. Incluye una capa cognitiva inspirada en Kimi K3 (LatentMoE Top-k, RAOVA, teacher matrix, preserved thinking, partial rollout, harness profiles) — **model-agnostic** y en postura **full-spectrum** (sin veto temático).

| Doc | Purpose |
|-----|---------|
| [`AGENTS.md`](AGENTS.md) | Contrato cognitivo (full-spectrum) |
| [`expert-registry.yaml`](expert-registry.yaml) | Catálogo + `teacher_matrix` 3×3 |
| [`harness-profiles.yaml`](harness-profiles.yaml) | Kits white-box incl. `full-spectrum` |
| [`ecosystem-map.md`](ecosystem-map.md) | Mapa de hubs + dedup |
| [`docs/k3-smoke-tests.md`](docs/k3-smoke-tests.md) | Smoke tests post-install |
| [`docs/registry-checklist.md`](docs/registry-checklist.md) | Checklist pre-commit |
| [`docs/smoke-results/`](docs/smoke-results/) | Resultados de verificación |

Inventario (ver también [`plugins-manifest.json`](plugins-manifest.json)):

| Área | Cantidad |
|------|----------|
| Cursor skills (skills-cursor) | 20 |
| Cursor user skills | `k3-cognitive-router` (+ cyber 01–19 vía install) |
| Cursor agents / subagents | 49 (48 ruflo + `k3-cognitive-router`) |
| Cursor rules | `k3-cognitive-runtime` + `security-scanning` |
| Cursor plugins | 11 |
| Cursor MCPs | Snyk + Semgrep |
| Claude plugins | 44 |
| Claude skills | 01–19 canónicos; `cyber-*` → symlinks |

## Instalación rápida (equipo)

```bash
git clone https://github.com/SecureCorp-Mexico/SecureSkills.git
cd SecureSkills
bash scripts/install-to-local.sh
bash scripts/audit-ecosystem.sh
```

Esto restaura en tu máquina:

- `~/.cursor/rules/` — K3 full-spectrum + security-scanning (advisory en código)
- `~/.cursor/skills/k3-cognitive-router/` — orquestador cognitivo
- `~/.cursor/secureskills/` — registry, harness profiles, AGENTS.md
- `~/.cursor/skills-cursor/` — skills oficiales Cursor
- `~/.cursor/agents/` — Task subagents (incl. k3-cognitive-router)
- `~/.cursor/mcp.json` + `hooks.json` — Snyk/Semgrep + Semgrep Guardian
- `~/.cursor/plugins/` — cache + marketplaces
- `~/.claude/skills/`, `profiles/` (`k3_domain` / `default_effort`), `plugins/`
- `~/.codex/skills/` (si aplica)

Luego:

1. Reinicia **Cursor** y **Claude Code**
2. (Opcional) `snyk auth` para SCA/IaC — **Snyk Code no se usa**
3. Smoke: [`docs/k3-smoke-tests.md`](docs/k3-smoke-tests.md)
4. Sembrar plantilla de proyecto:

```bash
SECURESKILLS_SEED_PROJECT=1 SECURESKILLS_PROJECT_ROOT=/ruta/a/tu/repo \
  bash scripts/install-to-local.sh
```

## Capa cognitiva K3 (full-spectrum)

No configura OpenRouter/BYOK. Enseña a los agentes a **amplificar** el stack:

1. **RAOVA** — Reason → Act → Observe → Verify → Adapt  
2. Clasificar `domain` (open set) + `effort` + `teacher_family`  
3. Top-k **3–8** (efficient) o hasta **16** (`full-spectrum`)  
4. Preserved thinking + AttnRes; state en `.k3/` en trabajo largo/`max`  
5. GRM (rubric→scorepad) **opcional** — nunca veto temático  
6. Partial rollout: `paused_rollouts` + resume-first  
7. Harness `full-spectrum` cuando el usuario pide máximo provecho / libertad total  
8. SPARC solo como workflow de features coding bajo el router  

Triggers de full-spectrum (ver `harness-profiles.yaml` → `user_override`):  
`libertad total`, `máximo provecho`, `full-spectrum`, `usa todo el stack`, …

## Estructura

```
SecureSkills/
├── AGENTS.md
├── expert-registry.yaml
├── harness-profiles.yaml
├── ecosystem-map.md
├── docs/
│   ├── k3-smoke-tests.md
│   ├── registry-checklist.md
│   └── smoke-results/
├── fixtures/k3-smoke/          # util + tests de verificación
├── cursor/
│   ├── mcp.json / hooks.json
│   ├── rules/                  # K3 + security-scanning
│   ├── user-skills/            # → ~/.cursor/skills/
│   ├── skills/                 # → ~/.cursor/skills-cursor/
│   ├── agents/                 # 49 Task agents
│   └── plugins/
├── claude/
│   ├── profiles/               # + k3_domain / default_effort
│   ├── skills/                 # 01–19; cyber-* → symlinks
│   └── plugins/
├── codex/skills/
├── security-skills/
├── templates/project/
├── scripts/
│   ├── install-to-local.sh
│   ├── export-from-local.sh
│   ├── audit-ecosystem.sh
│   └── setup-security-stack.sh
└── .github/workflows/
```

## Cursor — Skills destacados

| Skill | Uso |
|-------|-----|
| `k3-cognitive-router` | Orquestación full-spectrum / RAOVA / Top-k |
| `review-security` | Security review sobre diffs |
| `review-bugbot` | Bugbot PR review |
| `create-subagent` / `create-skill` / `create-rule` | Extender Cursor |
| `canvas` / `automate` / `loop` | Artefactos y automatización |

## Cursor — Agents destacados

| Agent | Rol |
|-------|-----|
| `k3-cognitive-router` | Router cognitivo |
| `security-auditor` / `safety-specialist` | Seguridad / AI safety |
| `coder` / `tester` / `reviewer` | Implementación y calidad |
| `sparc-orchestrator` / `coordinator` | Features / swarm (bajo el router) |
| `deep-researcher` / `dossier-investigator` | Investigación |
| `deployment-expert` / `performance-optimizer` | Deploy / perf |
| `trading-strategist` / `market-analyst` | Trading (on-demand) |

Lista completa: `cursor/agents/` y `plugins-manifest.json`.

## Seguridad / scanning

- **Semgrep** = SAST primario (MCP + hooks)  
- **Snyk** = SCA / IaC / container cuando aplique (`snyk auth`)  
- **Snyk Code** = no usado por política del equipo  
- Rule `security-scanning` = advisory en **código de aplicación**, nunca veto de temas  

## Claude profiles

Cada perfil incluye `k3_domain` + `default_effort` alineados al registry.

| Perfil | k3_domain | default_effort |
|--------|-----------|----------------|
| baseline | general | low |
| coder | coding | high |
| web | design | high |
| security | security | max |
| research | research | max |
| devops / iot | infra | high |
| trading | trading | high |
| autonomous | agentic | max |
| mega | research | max (sigue siendo Top-k, no catálogo entero) |

## Mantenimiento

```bash
cd SecureSkills
bash scripts/export-from-local.sh   # re-export desde la máquina
bash scripts/audit-ecosystem.sh
git status
```

## CI/CD

`agent-security.yml`: AgentAuditKit + Semgrep SARIF.

## Relación con skillsClaude

`skillsClaude` es el hub de CI/seguridad de proyecto. El instalador global de MCP/hooks/rules/K3 vive aquí (`install-to-local.sh`). El setup de skillsClaude **delega** a SecureSkills.

## License / contacto

Uso interno SecureCorp-Mexico. Issues y PRs vía el repo GitHub del equipo.
