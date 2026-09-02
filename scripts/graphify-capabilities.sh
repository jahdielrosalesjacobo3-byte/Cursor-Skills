#!/usr/bin/env bash
# Build a scoped "ecosystem capabilities" graph — agents, skills, MCP configs,
# integrations catalog metadata. Plugin caches excluded via .graphifyignore.
#
# Usage:
#   bash scripts/graphify-capabilities.sh
#   GRAPHIFY_WIKI=1 bash scripts/graphify-capabilities.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="${HOME}/.local/bin:${PATH}"

if ! command -v graphify >/dev/null 2>&1; then
  echo "==> installing graphifyy[mcp]..."
  uv tool install "graphifyy[mcp]"
fi

cd "$ROOT"

echo "==> Graphify capabilities extract (repo root + .graphifyignore)"
echo "    excludes: claude/plugins, cursor/plugins, graphify-out, caches"

rm -rf graphify-out/cache 2>/dev/null || true

graphify extract . --code-only --force --no-viz

echo "==> Clustering + report + graph.html"
graphify cluster-only .

if [[ "${GRAPHIFY_WIKI:-}" == "1" ]]; then
  echo "==> Wiki index for agents"
  graphify export wiki 2>/dev/null || graphify extract . --code-only --wiki --no-viz --force
fi

python3 - <<'PY'
import json
from collections import Counter
g=json.load(open("graphify-out/graph.json"))
nodes=g.get("nodes",[])
edges=g.get("links",g.get("edges",[]))
print(f"    nodes: {len(nodes)}  edges: {len(edges)}")
for label, c in Counter(n.get("file_type","?") for n in nodes).most_common(5):
    print(f"      {label}: {c}")
mcp=[n for n in nodes if n.get("label") in ("Snyk","Semgrep","graphify") or "mcp_server" in str(n.get("id",""))]
print(f"    MCP-related nodes: {len(mcp)}")
for n in mcp[:6]:
    print(f"      - {n.get('label')} ({n.get('source_file','')[:50]})")
PY

echo ""
echo "==> Capabilities graph ready."
echo "    open graphify-out/graph.html"
echo "    test: graphify query \"mcp servers and task agents\""
echo "    bash scripts/graphify-seed-agentdb.sh ."
