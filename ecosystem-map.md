# Ecosystem Map — SecureSkills (canonical)

Single source of truth for Cursor Agent, Claude Code, and Codex agent tooling at SecureCorp-Mexico.

## Hub roles

| Hub | Path | Role |
|-----|------|------|
| **SecureSkills** | `~/Documents/SecureSkills` | **Canonical** inventory, install/export, expert registry, K3 cognitive runtime |
| **skillsClaude** | `~/Documents/skillsClaude` | Security CI hub (AgentAuditKit, Semgrep workflow, project template). Feeds SecureSkills; does **not** own global MCP/hooks anymore |
| **SECURECORP cyber pack** | `~/Documents/Documents/SECURECORP/SECURE-CURSOR/Claude-Code-CyberSecurity-Skill` | Upstream Masriyan 01–19 content historically symlinked; SecureSkills now vendors copies under `claude/skills/01–19` |
| **Ruflo agents** | `SecureSkills/cursor/agents/*.md` → `~/.cursor/agents/` | 48 Task subagents; routed via K3 registry (Top-k), not all-at-once |
| **Plugin caches** | `~/.cursor/plugins`, `~/.claude/plugins` | On-demand catalogs (Vercel, Figma, antigravity, etc.) — activation via profiles + registry |

## Runtime layout (after install)

```
~/.cursor/
  rules/                 # k3-cognitive-runtime.mdc + security-scanning.mdc
  skills/                # user skills: k3-cognitive-router + cyber 01–19 symlinks
  skills-cursor/         # Cursor-managed official skills (from repo cursor/skills)
  agents/                # 48 ruflo + k3-cognitive-router
  mcp.json               # Snyk + Semgrep
  hooks.json             # Semgrep Guardian

~/.claude/
  skills/                # 01–19 canonical + owasp + security-audit + webkit…
  profiles/              # baseline, coder, security, … (+ k3_domain metadata)
```

## K3 cognitive overlay

Full-spectrum posture (tech-report patterns, **no topical locks**):

- **RAOVA** + soft effort budgets
- **LatentMoE** Top-k (up to 16 in full-spectrum); wave experts if needed
- **teacher_matrix** as menu — cross-family allowed
- **GRM** optional quality aid
- **Partial rollout** resume
- **Harness** `full-spectrum` for máximo provecho
- Semgrep advisory on **code** only — never a domain veto

See: `cursor/user-skills/k3-cognitive-router/`, `AGENTS.md`, `harness-profiles.yaml`.

## Dedup policy

| Duplicate | Canonical | Deprecated |
|-----------|-----------|------------|
| `09-web-security` vs `cyber-web-security` | `09-web-security` | `cyber-*` aliases |
| `15-blue-team-defense` vs `cyber-blue-team-defense` | numbered | `cyber-*` |
| `16-ai-llm-security` vs `cyber-ai-llm-security` | numbered | `cyber-*` |
| `19-grc-compliance` vs `cyber-grc-compliance` | numbered | `cyber-*` |
| skillsClaude global MCP installer vs SecureSkills install | SecureSkills `scripts/install-to-local.sh` | skillsClaude only delegates |

## Out of scope / archived notes

- `~/.cursor/KIMI-K3-OPENROUTER.md` and `setup-openrouter-kimi-k3.sh` — **do not expand**. Cursor provides native Kimi K3; cognitive layer is model-agnostic.
- Antigravity mega catalog (~1500 skills) — keep installed; never activate wholesale; router Top-k only.

## Install / audit

```bash
cd ~/Documents/SecureSkills
bash scripts/audit-ecosystem.sh
bash scripts/install-to-local.sh
```

Export local drift back into the repo:

```bash
bash scripts/export-from-local.sh
```
