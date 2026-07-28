# SecureSkills

Repositorio centralizado de **skills**, **agents/subagents**, **plugins**, **MCPs** y **configuraciones de seguridad** para el equipo SecureCorp-Mexico.

Compatible con **Cursor Agent**, **Claude Code** y **Codex**.

Inventario actual (ver [`plugins-manifest.json`](plugins-manifest.json)):

| Área | Cantidad |
|------|----------|
| Cursor skills | 20 |
| Cursor agents / subagents | 48 |
| Cursor plugins | 11 |
| Cursor MCPs | Snyk + Semgrep |
| Claude plugins | 44 |
| Claude skills | 40 |

## Instalación rápida (equipo)

```bash
git clone https://github.com/SecureCorp-Mexico/SecureSkills.git
cd SecureSkills
bash scripts/install-to-local.sh
```

Esto restaura en tu máquina:

- `~/.cursor/skills-cursor/` — skills de agents/subagents
- `~/.cursor/agents/` — definiciones de subagents (Task)
- `~/.cursor/mcp.json` + `hooks.json` — Snyk/Semgrep + Semgrep Guardian
- `~/.cursor/plugins/` — cache + marketplaces
- `~/.claude/skills/`, `profiles/`, `plugins/`
- `~/.codex/skills/` (si aplica)

Luego:

1. Reinicia **Cursor** y **Claude Code**
2. Ejecuta `snyk auth` (MCP Snyk)
3. (Opcional) siembra la plantilla de proyecto:

```bash
SECURESKILLS_SEED_PROJECT=1 SECURESKILLS_PROJECT_ROOT=/ruta/a/tu/repo \
  bash scripts/install-to-local.sh
```

## Estructura

```
SecureSkills/
├── cursor/
│   ├── mcp.json            # Snyk + Semgrep MCP
│   ├── hooks.json          # Semgrep Guardian hooks
│   ├── skills/             # Skills Cursor (~/.cursor/skills-cursor)
│   ├── agents/             # 48 subagents Task (~/.cursor/agents)
│   └── plugins/            # Cache + marketplaces Cursor
├── claude/
│   ├── profiles/           # security, web, devops, mega, etc.
│   ├── skills/             # 40 skills (cyber 01–19, OWASP, webkit…)
│   └── plugins/            # 44 plugins + marketplaces
├── codex/skills/
├── security-skills/        # OWASP, Trail of Bits, Masriyan, toshipon
├── templates/project/      # Plantilla .cursor para nuevos repos
├── scripts/
│   ├── install-to-local.sh # Equipo: cargar todo
│   ├── export-from-local.sh# Maintainer: re-exportar desde tu máquina
│   └── setup-security-stack.sh
└── .github/workflows/      # CI AgentAuditKit + Semgrep
```

## Cursor — Skills (agents / subagents)

| Skill | Uso |
|-------|-----|
| `review-security` | Subagente security-review sobre diffs |
| `review-bugbot` | Bugbot PR review |
| `review` | Review general |
| `create-subagent` | Crear nuevos subagents |
| `create-skill` / `create-rule` / `create-hook` | Extender Cursor |
| `automate` / `loop` / `babysit` | Automatización y loops |
| `canvas` | Canvas analíticos |
| `sdk` | Cursor SDK |
| `onboard` / `env-setup` | Onboarding / entorno |
| `split-to-prs` / `shell` / `statusline` | Workflows utilitarios |

## Cursor — Agents (48)

Definiciones en `cursor/agents/` (se instalan en `~/.cursor/agents/`). Destacados:

| Agent | Rol |
|-------|-----|
| `security-auditor` | Auditoría y remediación de vulnerabilidades |
| `safety-specialist` | AI safety / PII / defensa adaptativa |
| `architect` / `ai-architect` | Arquitectura de sistemas y apps AI |
| `coder` / `reviewer` / `tester` | Implementación, review, TDD |
| `browser-agent` | Automatización Playwright |
| `deep-researcher` / `dossier-investigator` | Investigación multi-fuente |
| `sparc-orchestrator` / `coordinator` | Orquestación de swarms |
| `deployment-expert` / `performance-optimizer` | Deploy y performance (Vercel) |
| `git-specialist` / `migration-engineer` | Git / migraciones DB |
| `agentdb-specialist` / `memory-specialist` / `vector-engineer` | Memoria y vectores |

Lista completa en `plugins-manifest.json` → `cursor.agents`.

## Cursor — Plugins

| Origen | Plugins |
|--------|---------|
| `cursor-public` | **vercel**, **supabase**, **figma**, **gsap-skills**, **kraken-cli** |
| `antigravity-awesome-skills` | agent-architect, architecture-design, apple-platform-design + bundles |
| `hackingtool-marketplace` | hackingtool |
| `agent-browser` | agent-browser |

## Cursor — MCPs

| Servidor | Función |
|----------|---------|
| **Snyk** | SCA, SAST, IaC, containers |
| **Semgrep** | SAST determinístico + hooks |

Requisito: `snyk auth` y CLI Semgrep instalado (`brew install semgrep` / `pipx`).

## Claude Code

### Plugins (44)

Marketplaces: `ruflo`, `antigravity-awesome-skills`, `claude-plugins-official`, `hackingtool-marketplace`, `agent-browser`, `netresearch`.

Destacados ruflo: `security-audit`, `aidefence`, `swarm`, `autopilot`, `intelligence`, `sparc`, `goals`.

### Skills (40)

- Cyber suite `01-recon-osint` … `19-grc-compliance`
- `owasp-security`, `security-audit`, `cyber-*`
- Webkit frontend / Vercel / Playwright

### Perfiles

| Perfil | Uso |
|--------|-----|
| `security.json` | Pentest, auditoría, blue team |
| `web.json` | Desarrollo web |
| `devops.json` | Infra y CI/CD |
| `research.json` | Investigación / OSINT |
| `mega.json` | Stack completo |
| `autonomous.json` | Agentes autónomos |

## Plantilla de proyecto

`templates/project/.cursor/` incluye:

- `mcp.json` — Snyk + Semgrep
- `hooks.json` — Semgrep Guardian
- `rules/security-scanning.mdc` — shift-left (Snyk/Semgrep en cada cambio)

## Mantenimiento (maintainers)

Actualizar el repo desde tu máquina (Cursor cerrado o idle):

```bash
cd SecureSkills
bash scripts/export-from-local.sh
git status
git add -A
git commit -m "Sync Cursor/Claude skills, agents, plugins and MCPs."
git push
```

## CI/CD

El workflow `agent-security.yml` ejecuta:

- **AgentAuditKit** — auditoría de configs MCP y agentes
- **Semgrep** — SAST con salida SARIF

## Trail of Bits (Claude Code)

```text
/plugin marketplace add trailofbits/skills
/plugin install static-analysis@trailofbits
/plugin install differential-review@trailofbits
/plugin install supply-chain-risk-auditor@trailofbits
```

Marketplace local también en `security-skills/trailofbits-skills/`.

## Seguridad

- No commitear `.env`, tokens ni credenciales
- Revisar `.cursor/mcp.json` en cada PR (vector MCPoison)
- Mantener Cursor actualizado
- Rotar API keys si se exponen en chats

---

**SecureCorp-Mexico** — DevSecOps & AI Agent Security
