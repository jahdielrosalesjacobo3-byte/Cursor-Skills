#!/usr/bin/env bash
# Health-check every integration the K3 cognitive layer can route to:
# CLIs, MCP servers, hooks, K3 artifacts, symlinks and catalog freshness.
# Exit codes: 0 = clean, 1 = warnings, 2 = hard errors
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CURSOR="$HOME/.cursor"
CLAUDE="$HOME/.claude"
CATALOG="$ROOT/integrations/catalog.json"
PY="${PYTHON:-python3}"
DRIFT_TOLERANCE="${DRIFT_TOLERANCE:-25}"
WARN=0
ERR=0

warn() { echo "WARN: $*"; WARN=$((WARN + 1)); }
err()  { echo "ERR:  $*"; ERR=$((ERR + 1)); }
ok()   { echo "OK:   $*"; }

echo "==> Integrations health check"
echo "    Repo: $ROOT"
echo ""

# --- Security CLIs --------------------------------------------------------
echo "-- CLIs --"
if command -v semgrep >/dev/null 2>&1; then
  ok "semgrep $(semgrep --version 2>/dev/null | tail -1 | tr -d '\n')"
else
  err "semgrep not on PATH (primary SAST)"
fi

if command -v snyk >/dev/null 2>&1; then
  ok "snyk $(snyk --version 2>/dev/null | head -1)"
  if snyk whoami >/dev/null 2>&1; then
    ok "snyk authenticated ($(snyk whoami 2>/dev/null | head -1))"
  else
    warn "snyk not authenticated — run: snyk auth (SCA/IaC scans will fail)"
  fi
else
  warn "snyk not on PATH (SCA/IaC scans unavailable)"
fi

# --- MCP servers ----------------------------------------------------------
echo ""
echo "-- MCP --"
MCP_JSON="$CURSOR/mcp.json"
if [[ -f "$MCP_JSON" ]]; then
  if "$PY" -c "import json,sys; json.load(open(sys.argv[1]))" "$MCP_JSON" 2>/dev/null; then
    ok "mcp.json is valid JSON"
    while IFS=$'\t' read -r name command; do
      if [[ "$command" != /* ]]; then
        warn "MCP $name uses a relative command: $command"
      elif [[ -x "$command" ]]; then
        ok "MCP $name -> $command"
      else
        err "MCP $name command missing or not executable: $command"
      fi
    done < <("$PY" - "$MCP_JSON" <<'PY'
import json, sys
cfg = json.load(open(sys.argv[1]))
for name, server in cfg.get("mcpServers", {}).items():
    print(f"{name}\t{server.get('command','')}")
PY
    )
  else
    err "mcp.json is not valid JSON"
  fi
else
  err "missing $MCP_JSON"
fi

# --- Hooks ----------------------------------------------------------------
echo ""
echo "-- Hooks --"
HOOKS_JSON="$CURSOR/hooks.json"
if [[ -f "$HOOKS_JSON" ]]; then
  if "$PY" -c "import json,sys; json.load(open(sys.argv[1]))" "$HOOKS_JSON" 2>/dev/null; then
    ok "hooks.json is valid JSON"
    while IFS=$'\t' read -r event binary; do
      if [[ -x "$binary" ]]; then
        ok "hook $event -> $binary"
      else
        err "hook $event binary missing: $binary"
      fi
    done < <("$PY" - "$HOOKS_JSON" <<'PY'
import json, sys
cfg = json.load(open(sys.argv[1]))
for event, hooks in cfg.get("hooks", {}).items():
    for hook in hooks:
        command = hook.get("command", "")
        print(f"{event}\t{command.split()[0] if command else ''}")
PY
    )
  else
    err "hooks.json is not valid JSON"
  fi
else
  err "missing $HOOKS_JSON"
fi

# --- K3 cognitive layer ---------------------------------------------------
echo ""
echo "-- K3 cognitive layer --"
for artifact in \
  "$CURSOR/rules/k3-cognitive-runtime.mdc" \
  "$CURSOR/rules/security-scanning.mdc" \
  "$CURSOR/skills/k3-cognitive-router/SKILL.md" \
  "$CURSOR/agents/k3-cognitive-router.md" \
  "$CURSOR/secureskills/harness-profiles.yaml" \
  "$CURSOR/secureskills/expert-registry.yaml" \
  "$CURSOR/secureskills/AGENTS.md"
do
  if [[ -e "$artifact" ]]; then
    ok "installed $(basename "$artifact")"
  else
    warn "not installed: $artifact (run install-to-local.sh)"
  fi
done

if [[ -f "$ROOT/expert-registry.yaml" ]] && grep -q "catalog_l2:" "$ROOT/expert-registry.yaml"; then
  ok "expert-registry declares catalog_l2"
else
  err "expert-registry.yaml missing catalog_l2 (L2 lookup not wired)"
fi

# --- Symlinks -------------------------------------------------------------
echo ""
echo "-- Symlinks --"
BROKEN=0
for dir in "$CURSOR/skills" "$CLAUDE/skills"; do
  [[ -d "$dir" ]] || continue
  while IFS= read -r link; do
    if [[ ! -e "$link" ]]; then
      err "broken symlink: $link -> $(readlink "$link")"
      BROKEN=$((BROKEN + 1))
    fi
  done < <(find "$dir" -maxdepth 1 -type l 2>/dev/null)
done
[[ "$BROKEN" -eq 0 ]] && ok "no broken symlinks in user skill dirs"

# --- Catalog freshness ----------------------------------------------------
echo ""
echo "-- Catalog --"
if [[ -f "$CATALOG" ]]; then
  ok "integrations/catalog.json present"
  if [[ -f "$ROOT/integrations/core.yaml" ]]; then
    ok "integrations/core.yaml present"
  else
    err "missing integrations/core.yaml"
  fi

  SHARD_COUNT=$(ls "$ROOT/integrations/shards"/*.jsonl 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$SHARD_COUNT" -gt 0 ]]; then
    ok "shards on disk: $SHARD_COUNT"
  else
    err "no shards under integrations/shards/"
  fi

  # Disk counts come from the builder itself so both sides agree on what a
  # "skill" is (dedup across bundles of the same marketplace).
  DRIFT_ROWS="$("$PY" "$ROOT/scripts/lib/build_catalog.py" --drift "$CATALOG" 2>/dev/null)"
  if [[ -z "$DRIFT_ROWS" ]]; then
    err "could not compute disk counts (build_catalog.py --drift failed)"
  else
    while IFS=$'\t' read -r key disk cataloged severity; do
      [[ -n "$key" ]] || continue
      drift=$(( disk > cataloged ? disk - cataloged : cataloged - disk ))
      if [[ "$drift" -eq 0 ]]; then
        ok "$key in sync ($cataloged)"
      elif [[ "$severity" == "hard" && "$drift" -gt "$DRIFT_TOLERANCE" ]]; then
        err "$key drift $drift (disk=$disk catalog=$cataloged) — run build-integrations-catalog.sh"
      else
        warn "$key drift $drift (disk=$disk catalog=$cataloged) — run build-integrations-catalog.sh"
      fi
    done <<<"$DRIFT_ROWS"
  fi
else
  err "missing $CATALOG — run scripts/build-integrations-catalog.sh"
fi

echo ""
echo "==> Summary: errors=$ERR warnings=$WARN"
if [[ "$ERR" -gt 0 ]]; then
  exit 2
elif [[ "$WARN" -gt 0 ]]; then
  exit 1
fi
exit 0
