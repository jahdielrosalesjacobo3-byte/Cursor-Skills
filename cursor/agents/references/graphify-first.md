# Graphify-first (shared block for code agents)

Apply when exploring or reasoning about **this repo's structure**.

## Preconditions

Check for `graphify-out/graph.json` in the workspace root (or pass `project_path` to MCP).

## Query order

1. **Graphify** — structural graph (calls, imports, inherits; EXTRACTED + INFERRED edges):
   - CLI: `graphify query "…"`, `graphify path "A" "B"`, `graphify explain "Symbol"`, `graphify viewer "Symbol"`
   - MCP: `query_graph`, `shortest_path`, `get_node`, `god_nodes`, `viewer_url`
2. **Show (optional)** — `graphify viewer` / `viewer_url` gives `graph-3d.html#n=<id>`. Agents traverse via MCP; they do not scrape the WebGL canvas.
3. **Targeted Read** — only the files/lines Graphify surfaced
4. **Grep/Glob** — narrow follow-ups, not repo-wide discovery
5. **AgentDB / RuVector** — cross-session patterns and semantic memory (not a substitute for AST paths)

## After code edits

Run `graphify update .` before relying on the graph again.

## If no graph

Suggest `bash scripts/graphify-bootstrap.sh` from SecureSkills, or `graphify extract . --code-only --no-viz` in the project root.

## Do not

- Re-extract entities Graphify already indexed into AgentDB manually
- Replace `graphify path` with prompt-loop pathfinder when `graph.json` exists
