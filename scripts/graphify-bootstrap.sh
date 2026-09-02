#!/usr/bin/env bash
# Bootstrap Graphify for a repo: AST-only extract, cluster, optional hooks.
# Does NOT install the mandatory graphify cursor rule (opt-in via graphify cursor install).
#
# Usage:
#   bash scripts/graphify-bootstrap.sh              # from repo root
#   bash scripts/graphify-bootstrap.sh /path/to/repo
#   GRAPHIFY_HOOKS=1 bash scripts/graphify-bootstrap.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${1:-.}"
TARGET="$(cd "$TARGET" && pwd)"

export PATH="${HOME}/.local/bin:${PATH}"

if ! command -v graphify >/dev/null 2>&1; then
  echo "==> graphify not found; installing graphifyy[mcp]..."
  uv tool install "graphifyy[mcp]"
fi

echo "==> Graphify bootstrap: $TARGET"
cd "$TARGET"

if [[ -f graphify-out/graph.json ]]; then
  echo "    graph.json exists — running incremental update"
  graphify update . --no-viz 2>/dev/null || graphify extract . --code-only --no-viz
else
  echo "    building AST-only graph (no LLM / no API key)"
  graphify extract . --code-only --no-viz
fi

echo "==> Clustering + GRAPH_REPORT.md"
graphify cluster-only .

if [[ "${GRAPHIFY_HOOKS:-}" == "1" ]]; then
  echo "==> Installing git hooks (post-commit / post-checkout)"
  graphify hook install
fi

if [[ "${GRAPHIFY_WIKI:-}" == "1" ]]; then
  echo "==> Generating wiki index"
  graphify extract . --code-only --wiki --no-viz 2>/dev/null || true
fi

echo ""
echo "==> Done."
echo "    graph:     $TARGET/graphify-out/graph.json"
echo "    report:    $TARGET/graphify-out/GRAPH_REPORT.md"
echo "    query:     graphify query \"your question\""
echo "    seed ADB:  bash $(dirname "$0")/graphify-seed-agentdb.sh \"$TARGET\""
echo ""
echo "    Soft rule: install SecureSkills (graphify-graph-first.mdc) via install-to-local.sh"
echo "    Strict:    graphify cursor install   # opt-in per repo only"
