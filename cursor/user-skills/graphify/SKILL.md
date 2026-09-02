---
name: graphify
description: >-
  Query structural knowledge graphs built from code (tree-sitter AST, local, no LLM).
  Use for architecture, dependencies, symbol paths, god nodes, and communities
  when graphify-out/graph.json exists. Complements AgentDB/RuVector semantic memory.
---

# Graphify — structural repo graph

Graphify maps a project into a **traversable knowledge graph** (not a vector index). Code extraction is local AST-only — no API cost.

## When to use

Use Graphify **before** broad Grep/Glob when:

- `graphify-out/graph.json` exists in the workspace
- The question is structural: architecture, dependencies, "where does X live", path between symbols, communities, blast radius

**Skip** (keep K3 fast path):

- Git status, small edits, non-code Q&A
- No `graph.json` yet — offer `bash scripts/graphify-bootstrap.sh` only if the user wants a map or the repo is large

One `graphify query` or MCP call counts as a single Act step, not full orchestration.

## Commands

```bash
# Build / refresh (AST-only, no API key)
graphify extract . --code-only --no-viz
graphify cluster-only .          # GRAPH_REPORT.md + communities
graphify update .                # incremental AST (hooks / watch automate this)

# Query (prefer over reading raw files)
graphify query "auth flow to database"
graphify path "SourceSymbol" "TargetSymbol" [--undirected]
graphify explain "ClassName"
graphify god_nodes --top 10
graphify viewer "ClassName"          # graph-3d.html#n=<id> (same IDs as MCP)
graphify viewer "ClassName" --open   # also open the sidecar in the browser

# Wiki index (optional, after --wiki extract)
# graphify-out/wiki/index.md
```

## MCP tools (namespace `graphify`)

When MCP is configured: `query_graph`, `get_node`, `get_neighbors`, `get_community`, `god_nodes`, `graph_stats`, `shortest_path`, `viewer_url`.

Pass `project_path` to target another repo's `graphify-out/graph.json`.

## 3D sidecar — how agents navigate

`graph-3d.html` is a **human UI** over the same `graph.json`. Agents do **not** click or OCR the WebGL canvas.

1. **Traverse** — `query_graph` / `get_node` / `get_neighbors` / `shortest_path` (or CLI `query` / `explain` / `path`). Node `id` values are the viewer hash.
2. **Show** — `graphify viewer "Symbol"` or MCP `viewer_url` `{ "label": "Symbol" }` → `file_url` with `#n=<id>`. Give that URL to the user (or `agent-browser open`).
3. **Which graph** — full: `graphify-out/graph-3d.html`; capabilities: `--graph graphify-out-capabilities/graph.json`. Catalog dropdown uses the same files.
4. **Operate the UI only if asked** — open `file_url`; type in `#search` (must fire `input`); Path A→B; do not parse the canvas.

After `graphify update .`, re-run `graphify export forcegraph --html` if the sidecar should match the new graph.

## Automatic node refresh

Do not wait for the user to ask. Three layers keep `graph.json` current (AST-only, no API cost):

1. **Cursor `afterFileEdit`** — `~/.cursor/hooks/graphify-auto-update.py` finds the nearest `graphify-out/graph.json` and runs `graphify update .` in the background. Opt out: `GRAPHIFY_SKIP_HOOK=1`. Optional 3D sidecar: `GRAPHIFY_AUTO_FORCEGRAPH=1`.
2. **Git** — `graphify hook install` (already on this repo): post-commit / post-checkout rebuild of changed code files.
3. **Live watch** — `graphify watch .` in a terminal for continuous edits outside Cursor.

Agents still run `graphify update .` after a large edit batch if they will query immediately and the hook may still be running.

## Layering with SecureSkills stack

| Layer | Role |
|-------|------|
| **Graphify** | Structural truth of **current repo** (calls, imports, inherits, INFERRED edges) |
| **AgentDB / RuVector** | Cross-session semantic memory, patterns, HNSW |
| **ruflo kg-extract** | LLM concepts / docs Graphify AST did not cover |

Do not re-extract entities Graphify already has. Seed AgentDB from god nodes via `scripts/graphify-seed-agentdb.sh` after extract.

## Subagent prompts

When spawning Task subagents for code exploration, include:

> If `graphify-out/graph.json` exists, run `graphify query` or MCP `query_graph` before broad Grep. After code edits, run `graphify update .`.

## Strict mode (opt-in per repo)

`graphify cursor install` writes a mandatory always-on rule — use only when you want hard enforcement; default SecureSkills uses the soft rule `graphify-graph-first.mdc`.
