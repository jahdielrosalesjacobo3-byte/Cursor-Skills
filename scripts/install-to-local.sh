#!/usr/bin/env bash
# Restore SecureSkills configs to local Cursor / Claude / Codex paths
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> Installing Cursor config..."
mkdir -p "$HOME/.cursor"
cp "$ROOT/cursor/mcp.json" "$HOME/.cursor/mcp.json"
cp "$ROOT/cursor/hooks.json" "$HOME/.cursor/hooks.json"

echo "==> Installing Cursor skills..."
mkdir -p "$HOME/.cursor/skills-cursor"
rsync -a "$ROOT/cursor/skills/" "$HOME/.cursor/skills-cursor/"

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

echo ""
echo "==> Plugins restored. See plugins-manifest.json for full inventory."
echo "==> Done. Restart Cursor and Claude Code."
echo "    Run: snyk auth  (if using Snyk MCP)"
