---
name: tool-discovery
description: >-
  Discover available MCP servers, L1 experts/skills, and marketplace tools before
  acting. Use when a task may need Semgrep, Snyk, Vercel, Supabase, Graphify,
  Figma, plugins, or any external capability — without asking the user first.
---

# Tool discovery (use before guessing)

When a task might need an MCP, plugin, subagent, or marketplace skill:

## 1. Live MCP catalog (session truth)

Call `GetDynamicTools` with no args for the full namespace list, or `{ "pattern": "<product>" }` to search (e.g. `vercel`, `supabase`, `graphify`, `semgrep`, `serena`, `context7`, `github`, `linear`, `claude-flow`, `shadcn`, `aws`, `figma`).

Before invoking an external MCP tool, read its schema via `GetDynamicTools` `{ "namespace": "<id>", "toolName": "<name>" }`.

If a namespace is `needsAuth`, authenticate once with `CallDynamicTool` on that namespace's auth tool, then retry.

## 2. L1 inventory (always eligible)

Read from `~/.cursor/secureskills/` (or repo `integrations/`):

| File | Contents |
|------|----------|
| `integrations/core.yaml` | MCP servers, hooks, rules, 49 Task agents, core skills |
| `expert-registry.yaml` | K3 routing, triggers, teacher_matrix |
| `integrations/INDEX.md` | L2 shard map (5078 marketplace skills) |
| `harness-profiles.yaml` | Which skills/subagents per task profile |

**Do not** load all of L2 — grep one shard line, open one `SKILL.md` (max 4 per task).

## 3. Structural graph (repo / ecosystem)

If `graphify-out/graph.json` exists:

```bash
graphify query "mcp servers and integrations"
graphify query "available agents and skills"
```

Or MCP `query_graph` with `project_path` pointing at SecureSkills or the active repo.

Navigate `graphify-out/wiki/index.md` when present.

## 4. Selection rules

- Match task → L1 trigger in `expert-registry.yaml` → activate expert/skill silently
- Security/code (single file, custom rule) → Semgrep MCP; **full codebase audit** → Trail of Bits plugin (`semgrep`/`codeql` skills, `differential-review`, `variant-analysis`, `fp-check`)
- Dependencies/SCA/IaC/containers → Snyk MCP (+ `supply-chain-risk-auditor` skill)
- Repo structure (static graph) → Graphify MCP / CLI (`query_graph`, `get_neighbors`, `shortest_path`; `viewer_url` / `graphify viewer` for `graph-3d.html#n=<id>`)
- Live symbols / safe refactor → **Serena** MCP (`find_symbol`, `find_referencing_symbols`, `replace_symbol_body`, `rename_symbol`, `get_diagnostics_for_file`) — activate the project first if asked
- Library / framework API questions → **Context7** MCP (`resolve-library-id` → `query-docs`) before guessing signatures
- GitHub PRs/issues/Actions/code scanning → **github** MCP (needs `GITHUB_TOKEN`; `graphify list_prs` for graph impact)
- Project tracking → **linear** MCP (OAuth)
- AWS services/regions/limits → **aws-knowledge** MCP (`search_documentation`, no auth)
- UI components → **shadcn** MCP (`search_items_in_registries`, `get_add_command_for_items`) + Figma / Mobbin
- Cross-session memory, swarms, hooks, sessions → **claude-flow** MCP (`memory_*`, `agent_*`, `swarm_*`, `session_*`); this is what the 49 Task agents mean by `mcp__claude-flow__*`
- Deploy/hosting → Vercel namespace; DB/auth → Supabase namespace
- Not installed but documented → `integrations/optional-mcp.md` (Sentry, Terraform, Firecrawl, Exa, Playwright MCP, AWS API)
- No L1 match → L2 shard search, one skill at a time

Full intent → namespace table: `expert-registry.yaml` → `mcp_routing`.

## 5. Never

- Ask the user "¿quieres que use X?" when X is in L1 and clearly matches the task
- Dump the entire 5078-skill catalog into context
- Grep all of `plugins/cache/` for capabilities — use catalog + MCP instead
