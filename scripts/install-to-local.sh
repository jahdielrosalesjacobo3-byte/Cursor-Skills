#!/usr/bin/env bash
# Restore SecureSkills configs to local Cursor / Claude / Codex paths
# Usage (team onboarding):
#   git clone https://github.com/SecureCorp-Mexico/SecureSkills.git
#   cd SecureSkills && bash scripts/install-to-local.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> Installing Cursor MCP + hooks..."
mkdir -p "$HOME/.cursor"
cp "$ROOT/cursor/mcp.json" "$HOME/.cursor/mcp.json"
cp "$ROOT/cursor/hooks.json" "$HOME/.cursor/hooks.json"

echo "==> Installing Cursor skills (agents/subagents entrypoints)..."
mkdir -p "$HOME/.cursor/skills-cursor"
rsync -a "$ROOT/cursor/skills/" "$HOME/.cursor/skills-cursor/"

echo "==> Installing Cursor agents (Task subagents)..."
if [ -d "$ROOT/cursor/agents" ] && [ "$(ls -A "$ROOT/cursor/agents" 2>/dev/null)" ]; then
  mkdir -p "$HOME/.cursor/agents"
  rsync -a "$ROOT/cursor/agents/" "$HOME/.cursor/agents/"
  echo "    Agents: $(ls "$HOME/.cursor/agents" | wc -l | tr -d ' ')"
fi

echo "==> Installing Claude profiles..."
mkdir -p "$HOME/.claude/profiles"
rsync -a "$ROOT/claude/profiles/" "$HOME/.claude/profiles/"

echo "==> Installing Claude skills..."
mkdir -p "$HOME/.claude/skills"
rsync -a "$ROOT/claude/skills/" "$HOME/.claude/skills/"

echo "==> Installing Codex skills (if present)..."
if [ -d "$ROOT/codex/skills" ] && [ "$(ls -A "$ROOT/codex/skills" 2>/dev/null)" ]; then
  mkdir -p "$HOME/.codex/skills"
  rsync -a "$ROOT/codex/skills/" "$HOME/.codex/skills/"
fi

echo "==> Installing Claude plugins (cache + marketplaces)..."
mkdir -p "$HOME/.claude/plugins"
cp "$ROOT/claude/plugins/installed_plugins.json" "$HOME/.claude/plugins/" 2>/dev/null || true
cp "$ROOT/claude/plugins/known_marketplaces.json" "$HOME/.claude/plugins/" 2>/dev/null || true
rsync -a "$ROOT/claude/plugins/cache/" "$HOME/.claude/plugins/cache/"
rsync -a "$ROOT/claude/plugins/marketplaces/" "$HOME/.claude/plugins/marketplaces/"

echo "==> Installing Cursor plugins (cache + marketplaces)..."
mkdir -p "$HOME/.cursor/plugins"
rsync -a "$ROOT/cursor/plugins/cache/" "$HOME/.cursor/plugins/cache/"
rsync -a "$ROOT/cursor/plugins/marketplaces/" "$HOME/.cursor/plugins/marketplaces/"
if [ -d "$ROOT/cursor/plugins/local" ]; then
  rsync -a "$ROOT/cursor/plugins/local/" "$HOME/.cursor/plugins/local/"
fi

# Optional: seed current project with SecureCorp .cursor template
if [ "${SECURESKILLS_SEED_PROJECT:-}" = "1" ] && [ -d "$ROOT/templates/project/.cursor" ]; then
  TARGET="${SECURESKILLS_PROJECT_ROOT:-.}"
  mkdir -p "$TARGET/.cursor"
  rsync -a "$ROOT/templates/project/.cursor/" "$TARGET/.cursor/"
  echo "==> Seeded project template into $TARGET/.cursor"
fi

echo ""
echo "==> Plugins restored. See plugins-manifest.json for full inventory."
echo "==> Done. Restart Cursor and Claude Code."
echo "    Run: snyk auth  (if using Snyk MCP)"
echo "    Optional: SECURESKILLS_SEED_PROJECT=1 bash scripts/install-to-local.sh"
