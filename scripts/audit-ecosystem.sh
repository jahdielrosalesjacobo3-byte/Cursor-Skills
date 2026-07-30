#!/usr/bin/env bash
# Audit SecureSkills ecosystem consistency vs local Cursor/Claude install.
# Exit codes: 0 = clean, 1 = warnings found, 2 = hard errors
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REGISTRY="$ROOT/expert-registry.yaml"
CURSOR="$HOME/.cursor"
CLAUDE="$HOME/.claude"
WARN=0
ERR=0

warn() { echo "WARN: $*"; WARN=$((WARN + 1)); }
err()  { echo "ERR:  $*"; ERR=$((ERR + 1)); }
ok()   { echo "OK:   $*"; }

echo "==> SecureSkills ecosystem audit"
echo "    Root: $ROOT"
echo ""

# --- Registry present ---
if [[ -f "$REGISTRY" ]]; then
  ok "expert-registry.yaml present"
else
  err "missing expert-registry.yaml"
fi

# --- Required cognitive artifacts in repo ---
for f in \
  "cursor/rules/k3-cognitive-runtime.mdc" \
  "cursor/rules/security-scanning.mdc" \
  "cursor/user-skills/k3-cognitive-router/SKILL.md" \
  "cursor/user-skills/k3-cognitive-router/references/catalog-l2.md" \
  "cursor/agents/k3-cognitive-router.md" \
  "harness-profiles.yaml" \
  "AGENTS.md" \
  "ecosystem-map.md" \
  "integrations/catalog.json" \
  "integrations/core.yaml" \
  "integrations/INDEX.md"
do
  if [[ -e "$ROOT/$f" ]]; then
    ok "repo has $f"
  else
    err "repo missing $f"
  fi
done

# teacher_matrix present in registry
if grep -q "teacher_matrix:" "$REGISTRY" 2>/dev/null; then
  ok "expert-registry.yaml has teacher_matrix"
else
  err "expert-registry.yaml missing teacher_matrix"
fi

# --- Two-level catalog wiring ---
if grep -q "^catalog_l2:" "$REGISTRY" 2>/dev/null && grep -q "^lookup_policy:" "$REGISTRY" 2>/dev/null; then
  ok "expert-registry.yaml wires L2 (catalog_l2 + lookup_policy)"
else
  err "expert-registry.yaml missing catalog_l2 / lookup_policy"
fi

if grep -q "catalog_access:" "$ROOT/harness-profiles.yaml" 2>/dev/null; then
  ok "harness-profiles.yaml declares catalog_access"
else
  err "harness-profiles.yaml missing catalog_access"
fi

SHARDS=$(ls "$ROOT/integrations/shards"/*.jsonl 2>/dev/null | wc -l | tr -d ' ')
if [[ "$SHARDS" -gt 0 ]]; then
  ok "integrations shards present ($SHARDS)"
  # Every shard the manifest points at must exist, and counts must line up.
  if ! python3 - "$ROOT" <<'PY'
import json, sys
from pathlib import Path

repo = Path(sys.argv[1])
catalog = json.loads((repo / "integrations" / "catalog.json").read_text())
problems = []
total = 0
for shard in catalog.get("shards", []):
    path = repo / "integrations" / shard["file"]
    if not path.exists():
        problems.append(f"missing shard {shard['file']}")
        continue
    lines = sum(1 for _ in path.open(encoding="utf-8"))
    total += lines
    if lines != shard["count"]:
        problems.append(f"{shard['file']}: {lines} lines vs catalog {shard['count']}")
expected = catalog["counts"]["l2Total"]
if total != expected:
    problems.append(f"l2Total {expected} vs {total} shard lines")
for problem in problems:
    print(problem)
sys.exit(1 if problems else 0)
PY
  then
    err "integrations catalog is internally inconsistent (see above)"
  else
    ok "integrations catalog counts match shard contents"
  fi
else
  err "no shards under integrations/shards/ — run build-integrations-catalog.sh"
fi

# --- Cursor agents: every *.md should be listed in registry (best-effort grep) ---
if [[ -d "$ROOT/cursor/agents" ]]; then
  while IFS= read -r agent; do
    id="${agent%.md}"
    if ! grep -qE "^[[:space:]]*- id: ${id}$|^[[:space:]]*id: ${id}$" "$REGISTRY" 2>/dev/null \
      && ! grep -q "id: ${id}" "$REGISTRY" 2>/dev/null; then
      # k3-cognitive-router is expected; others should be registered
      if [[ "$id" != "README" ]]; then
        warn "agent $id not found in expert-registry.yaml"
      fi
    fi
  done < <(ls "$ROOT/cursor/agents"/*.md 2>/dev/null | xargs -n1 basename)
fi

# --- Deprecated cyber-* : warn only if NOT a symlink to numbered canonical ---
for alias in cyber-web-security cyber-blue-team-defense cyber-ai-llm-security cyber-grc-compliance; do
  for base in "$CLAUDE/skills" "$CURSOR/skills"; do
    path="$base/$alias"
    if [[ -L "$path" ]]; then
      target="$(readlink "$path")"
      case "$target" in
        *09-web-security*|*15-blue-team-defense*|*16-ai-llm-security*|*19-grc-compliance*)
          ok "alias OK (symlink): $path -> $target"
          ;;
        *)
          warn "alias symlink points unexpectedly: $path -> $target"
          ;;
      esac
    elif [[ -d "$path" ]]; then
      warn "deprecated alias is a full directory (should be symlink): $path"
    fi
  done
done

# --- Canonical 01–19 present in repo ---
for n in $(seq -w 1 19); do
  id="$(printf '%02d' "$((10#$n))" 2>/dev/null || printf '%02d' "$n")"
done
for n in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19; do
  # find directory matching ${n}-*
  match=$(ls -d "$ROOT/claude/skills/${n}-"* 2>/dev/null | head -1 || true)
  if [[ -n "$match" ]]; then
    ok "canonical cyber present: $(basename "$match")"
  else
    err "missing canonical cyber skill ${n}-* under claude/skills/"
  fi
done

# --- Broken symlinks under ~/.cursor/skills and ~/.claude/skills ---
check_broken_links() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  while IFS= read -r link; do
    if [[ -L "$link" && ! -e "$link" ]]; then
      err "broken symlink: $link -> $(readlink "$link")"
    fi
  done < <(find "$dir" -maxdepth 1 -type l 2>/dev/null)
}
check_broken_links "$CURSOR/skills"
check_broken_links "$CLAUDE/skills"

# --- Local install of K3 cognitive layer ---
if [[ -f "$CURSOR/rules/k3-cognitive-runtime.mdc" ]]; then
  ok "installed ~/.cursor/rules/k3-cognitive-runtime.mdc"
else
  warn "not installed: ~/.cursor/rules/k3-cognitive-runtime.mdc (run install-to-local.sh)"
fi
if [[ -f "$CURSOR/rules/security-scanning.mdc" ]]; then
  ok "installed ~/.cursor/rules/security-scanning.mdc"
else
  warn "not installed: ~/.cursor/rules/security-scanning.mdc"
fi
if [[ -d "$CURSOR/skills/k3-cognitive-router" || -L "$CURSOR/skills/k3-cognitive-router" ]]; then
  ok "installed ~/.cursor/skills/k3-cognitive-router"
else
  warn "not installed: ~/.cursor/skills/k3-cognitive-router"
fi
if [[ -f "$CURSOR/agents/k3-cognitive-router.md" ]]; then
  ok "installed ~/.cursor/agents/k3-cognitive-router.md"
else
  warn "not installed: ~/.cursor/agents/k3-cognitive-router.md"
fi
if [[ -f "$CURSOR/secureskills/integrations/catalog.json" ]]; then
  ok "installed ~/.cursor/secureskills/integrations/catalog.json"
else
  warn "not installed: ~/.cursor/secureskills/integrations (run install-to-local.sh)"
fi

# --- MCP / hooks parity ---
if [[ -f "$CURSOR/mcp.json" && -f "$ROOT/cursor/mcp.json" ]]; then
  if diff -q "$CURSOR/mcp.json" "$ROOT/cursor/mcp.json" >/dev/null 2>&1; then
    ok "mcp.json matches repo"
  else
    warn "mcp.json diverges from repo (export or reinstall)"
  fi
else
  warn "cannot compare mcp.json"
fi
if [[ -f "$CURSOR/hooks.json" && -f "$ROOT/cursor/hooks.json" ]]; then
  if diff -q "$CURSOR/hooks.json" "$ROOT/cursor/hooks.json" >/dev/null 2>&1; then
    ok "hooks.json matches repo"
  else
    warn "hooks.json diverges from repo"
  fi
else
  warn "cannot compare hooks.json"
fi

# --- OpenRouter BYOK note (informational) ---
if [[ -f "$CURSOR/KIMI-K3-OPENROUTER.md" ]]; then
  warn "OpenRouter Kimi docs present at ~/.cursor (archived/out-of-scope for K3 cognitive layer — do not expand)"
fi

echo ""
echo "==> Summary: errors=$ERR warnings=$WARN"
if [[ "$ERR" -gt 0 ]]; then
  exit 2
elif [[ "$WARN" -gt 0 ]]; then
  exit 1
fi
exit 0
