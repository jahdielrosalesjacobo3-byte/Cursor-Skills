#!/usr/bin/env bash
# Re-export local skills/agents/configs/plugins into this repo (run from repo root)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> Exporting from local machine to $ROOT ..."

# --- Cursor skills (agents & subagents entrypoints) ---
rsync -a --delete \
  --exclude='.sync-manifest.json' \
  --exclude='canvas/sdk/*.d.ts' \
  "$HOME/.cursor/skills-cursor/" "$ROOT/cursor/skills/"

# --- Cursor agents (Task/subagent definitions) ---
if [ -d "$HOME/.cursor/agents" ]; then
  mkdir -p "$ROOT/cursor/agents"
  rsync -a --delete "$HOME/.cursor/agents/" "$ROOT/cursor/agents/"
  echo "    Cursor agents: $(ls "$ROOT/cursor/agents" | wc -l | tr -d ' ')"
fi

# --- Cursor MCP + hooks ---
cp "$HOME/.cursor/mcp.json" "$ROOT/cursor/mcp.json"
cp "$HOME/.cursor/hooks.json" "$ROOT/cursor/hooks.json"

# --- Cursor rules (K3 + security) ---
if [ -d "$HOME/.cursor/rules" ]; then
  mkdir -p "$ROOT/cursor/rules"
  rsync -a "$HOME/.cursor/rules/" "$ROOT/cursor/rules/"
  echo "    Cursor rules: $(ls "$ROOT/cursor/rules"/*.mdc 2>/dev/null | wc -l | tr -d ' ')"
fi

# --- Cursor user skills (k3-cognitive-router; exclude cyber symlinks) ---
if [ -d "$HOME/.cursor/skills/k3-cognitive-router" ]; then
  mkdir -p "$ROOT/cursor/user-skills/k3-cognitive-router"
  rsync -a --delete \
    "$HOME/.cursor/skills/k3-cognitive-router/" \
    "$ROOT/cursor/user-skills/k3-cognitive-router/"
  echo "    Exported k3-cognitive-router user skill"
fi

# --- Project template (from skillsClaude if present) ---
PROJECT_CURSOR="${SECURESKILLS_PROJECT_CURSOR:-$HOME/Documents/skillsClaude/.cursor}"
if [ -d "$PROJECT_CURSOR" ]; then
  mkdir -p "$ROOT/templates/project/.cursor"
  rsync -a "$PROJECT_CURSOR/" "$ROOT/templates/project/.cursor/"
  echo "    Project template .cursor synced from $PROJECT_CURSOR"
fi

# --- Claude profiles + skills ---
mkdir -p "$ROOT/claude/profiles" "$ROOT/claude/skills" "$ROOT/claude/plugins"
cp "$HOME/.claude/profiles/"*.json "$ROOT/claude/profiles/" 2>/dev/null || true
# -aL follows symlinks so numbered cyber 01-19 land as real directories when
# local points at SECURECORP. Then re-assert deprecated cyber-* as relative symlinks.
rsync -aL --delete --exclude='.git' --exclude='__pycache__' --exclude='*.pyc' \
  "$HOME/.claude/skills/" "$ROOT/claude/skills/"
(
  cd "$ROOT/claude/skills"
  rm -rf cyber-web-security cyber-blue-team-defense cyber-ai-llm-security cyber-grc-compliance
  ln -sfn 09-web-security cyber-web-security
  ln -sfn 15-blue-team-defense cyber-blue-team-defense
  ln -sfn 16-ai-llm-security cyber-ai-llm-security
  ln -sfn 19-grc-compliance cyber-grc-compliance
  echo "    Re-linked cyber-* aliases → numbered 01–19"
)

# --- Claude plugins ---
cp "$HOME/.claude/plugins/installed_plugins.json" "$ROOT/claude/plugins/" 2>/dev/null || true
cp "$HOME/.claude/plugins/known_marketplaces.json" "$ROOT/claude/plugins/" 2>/dev/null || true
rsync -a --delete --exclude='.git' "$HOME/.claude/plugins/cache/" "$ROOT/claude/plugins/cache/"
rsync -a --delete --exclude='.git' "$HOME/.claude/plugins/marketplaces/" "$ROOT/claude/plugins/marketplaces/" 2>/dev/null || true

# --- Cursor plugins ---
mkdir -p "$ROOT/cursor/plugins"
rsync -a --delete --exclude='.git' "$HOME/.cursor/plugins/cache/" "$ROOT/cursor/plugins/cache/"
rsync -a --delete --exclude='.git' "$HOME/.cursor/plugins/marketplaces/" "$ROOT/cursor/plugins/marketplaces/" 2>/dev/null || true
if [ -d "$HOME/.cursor/plugins/local" ]; then
  rsync -a --delete "$HOME/.cursor/plugins/local/" "$ROOT/cursor/plugins/local/" 2>/dev/null || true
fi

# --- Codex skills ---
if [ -d "$HOME/.codex/skills" ]; then
  mkdir -p "$ROOT/codex/skills"
  rsync -aL --delete --exclude='.git' "$HOME/.codex/skills/" "$ROOT/codex/skills/"
fi

# --- L2 integrations catalog (must run before the manifest, which reads it) ---
echo "==> Rebuilding integrations catalog..."
bash "$ROOT/scripts/build-integrations-catalog.sh"

# --- Manifest ---
python3 "$ROOT/scripts/lib/build_manifest.py" "$ROOT"

echo "==> Export complete. Review with: git status"
echo "    Health check: bash scripts/verify-integrations.sh"
