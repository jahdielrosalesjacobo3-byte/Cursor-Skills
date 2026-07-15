# SecureSkills

Repositorio centralizado de **skills**, **plugins**, **MCPs** y **configuraciones de seguridad** para el equipo SecureCorp-Mexico.

Compatible con **Cursor Agent**, **Claude Code** y **Codex**.

## Estructura

```
SecureSkills/
├── cursor/                 # Config global Cursor
│   ├── mcp.json            # Snyk + Semgrep MCP
│   ├── hooks.json          # Semgrep Guardian hooks
│   ├── skills/             # Skills oficiales Cursor (~/.cursor/skills-cursor)
│   └── plugins/            # Cache y marketplaces de plugins Cursor
├── claude/                 # Config Claude Code
│   ├── profiles/           # Perfiles (security, web, devops, mega, etc.)
│   ├── skills/             # Skills personales + seguridad + webkit
│   └── plugins/            # Plugins instalados + cache (ruflo, antigravity, etc.)
├── codex/                  # Skills Codex (linear, system)
├── security-skills/        # Repos de seguridad (OWASP, Trail of Bits, Masriyan, toshipon)
├── templates/project/      # Plantilla .cursor + .claude para nuevos proyectos
├── scripts/                # Instalación local + security stack
└── .github/workflows/      # CI: AgentAuditKit + Semgrep
```

## Instalación rápida

```bash
git clone https://github.com/SecureCorp-Mexico/SecureSkills.git
cd SecureSkills
bash scripts/install-to-local.sh
```

`install-to-local.sh` restaura automáticamente **todos los plugins** (cache + marketplaces).

## Plugins incluidos

Ver inventario completo en [`plugins-manifest.json`](plugins-manifest.json).

### Claude Code (44 plugins)

| Marketplace | Plugins destacados |
|-------------|-------------------|
| `claude-plugins-official` | superpowers, skill-creator |
| `ruflo` | security-audit, aidefence, swarm, autopilot, intelligence, sparc, goals, etc. |
| `antigravity-awesome-skills` | essentials, security-engineer, full-stack, web-wizard, devops-cloud |
| `hackingtool-marketplace` | hackingtool (pentest) |
| `agent-browser` | agent-browser |
| `netresearch` | file-search |

### Cursor (10 plugins + marketplaces)

| Origen | Plugins |
|--------|---------|
| `cursor-public` | **vercel**, **supabase**, **gsap-skills**, **kraken-cli** |
| `antigravity-awesome-skills` | agent-architect, apple-platform-design, architecture-design + 30+ bundles |
| `hackingtool-marketplace` | hackingtool |
| `agent-browser` | agent-browser |

## Perfiles Claude disponibles

| Perfil | Uso |
|--------|-----|
| `security.json` | Pentest, auditoría, blue team, ruflo, antigravity |
| `web.json` | Desarrollo web |
| `devops.json` | Infraestructura y CI/CD |
| `research.json` | Investigación y OSINT |
| `mega.json` | Stack completo |
| `autonomous.json` | Agentes autónomos |

## MCPs configurados (Cursor)

| Servidor | Función |
|----------|---------|
| **Snyk** | SCA, SAST, IaC, containers |
| **Semgrep** | SAST determinístico + hooks |

Requisito: `snyk auth` antes del primer uso.

## Skills de seguridad destacados

| Skill | Plataforma | Descripción |
|-------|------------|-------------|
| `owasp-security` | Claude | OWASP Top 10:2025, ASVS 5.0, LLM/Agentic |
| `security-audit` | Claude | Auditoría full-stack (`/security-audit all`) |
| `cyber-blue-team-defense` | Claude | Hardening, detection engineering |
| `review-security` | Cursor | Subagente security-review en diffs |
| `review-bugbot` | Cursor | Bugbot PR review |

Ver `security-skills/` para repos completos y `scripts/setup-security-stack.sh` para el stack DevSecOps.

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

## Mantenimiento

Para actualizar el repo desde tu máquina local:

```bash
# Re-ejecutar sync (desde el directorio del repo clonado)
bash scripts/export-from-local.sh   # crear si se necesita export incremental
```

## Seguridad

- No commitear `.env`, tokens ni credenciales
- Revisar `.cursor/mcp.json` en cada PR (vector MCPoison)
- Mantener Cursor actualizado

---

**SecureCorp-Mexico** — DevSecOps & AI Agent Security
