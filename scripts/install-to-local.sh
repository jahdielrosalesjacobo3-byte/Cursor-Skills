#!/usr/bin/env bash
# Restore SecureSkills configs to local Cursor / Claude / Codex paths
# Usage (team onboarding):
#   git clone https://github.com/SecureCorp-Mexico/SecureSkills.git
#   cd SecureSkills && bash scripts/install-to-local.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> Installing Cursor MCP + hooks..."
mkdir -p "$HOME/.cursor/hooks"
cp "$ROOT/cursor/mcp.json" "$HOME/.cursor/mcp.json"
cp "$ROOT/cursor/hooks.json" "$HOME/.cursor/hooks.json"
if [ -d "$ROOT/cursor/hooks" ]; then
  rsync -a "$ROOT/cursor/hooks/" "$HOME/.cursor/hooks/"
  chmod +x "$HOME/.cursor/hooks/"*.py "$HOME/.cursor/hooks/"*.sh 2>/dev/null || true
fi

echo "==> Installing Cursor rules (K3 cognitive + security-scanning)..."
mkdir -p "$HOME/.cursor/rules"
if [ -d "$ROOT/cursor/rules" ]; then
  rsync -a "$ROOT/cursor/rules/" "$HOME/.cursor/rules/"
  echo "    Rules: $(ls "$HOME/.cursor/rules"/*.mdc 2>/dev/null | wc -l | tr -d ' ')"
  echo "    K3 size: $(wc -c < "$HOME/.cursor/rules/k3-cognitive-runtime.mdc" 2>/dev/null | tr -d ' ') bytes (compact if <2500)"
fi

echo "==> Installing K3 harness profiles + registry pointers..."
mkdir -p "$HOME/.cursor/secureskills"
cp "$ROOT/harness-profiles.yaml" "$HOME/.cursor/secureskills/harness-profiles.yaml"
cp "$ROOT/expert-registry.yaml" "$HOME/.cursor/secureskills/expert-registry.yaml"
cp "$ROOT/AGENTS.md" "$HOME/.cursor/secureskills/AGENTS.md"
echo "    OK: ~/.cursor/secureskills/{harness-profiles,expert-registry,AGENTS}"

echo "==> Installing L2 integrations catalog..."
if [ -d "$ROOT/integrations" ]; then
  rsync -a --delete "$ROOT/integrations/" "$HOME/.cursor/secureskills/integrations/"
  echo "    Shards: $(ls "$HOME/.cursor/secureskills/integrations/shards"/*.jsonl 2>/dev/null | wc -l | tr -d ' ')"
else
  echo "    SKIP: integrations/ absent — run scripts/build-integrations-catalog.sh"
fi

echo "==> Installing Cursor skills (agents/subagents entrypoints → skills-cursor)..."
mkdir -p "$HOME/.cursor/skills-cursor"
rsync -a "$ROOT/cursor/skills/" "$HOME/.cursor/skills-cursor/"

echo "==> Installing Cursor user skills (k3-cognitive-router + cyber 01–19)..."
mkdir -p "$HOME/.cursor/skills"
# K3 cognitive router (do not place under skills-cursor — Cursor-managed)
if [ -d "$ROOT/cursor/user-skills/k3-cognitive-router" ]; then
  rsync -a --delete \
    "$ROOT/cursor/user-skills/k3-cognitive-router/" \
    "$HOME/.cursor/skills/k3-cognitive-router/"
  echo "    OK: k3-cognitive-router"
fi
if [ -d "$ROOT/cursor/user-skills/graphify" ]; then
  rsync -a --delete \
    "$ROOT/cursor/user-skills/graphify/" \
    "$HOME/.cursor/skills/graphify/"
  echo "    OK: graphify"
fi
if [ -d "$ROOT/cursor/user-skills/tool-discovery" ]; then
  rsync -a --delete \
    "$ROOT/cursor/user-skills/tool-discovery/" \
    "$HOME/.cursor/skills/tool-discovery/"
  echo "    OK: tool-discovery"
fi
# Canonical cyber 01–19 as symlinks into user skills (same content as Claude skills)
if [ -d "$ROOT/claude/skills" ]; then
  for skill_dir in "$ROOT/claude/skills"/[0-9][0-9]-*; do
    [ -d "$skill_dir" ] || continue
    name="$(basename "$skill_dir")"
    ln -sfn "$skill_dir" "$HOME/.cursor/skills/$name"
  done
  echo "    Linked cyber 01–19 into ~/.cursor/skills/"
fi
# Remove deprecated cyber-* aliases from Cursor user skills if present
for alias in cyber-web-security cyber-blue-team-defense cyber-ai-llm-security cyber-grc-compliance; do
  if [ -e "$HOME/.cursor/skills/$alias" ] || [ -L "$HOME/.cursor/skills/$alias" ]; then
    rm -rf "$HOME/.cursor/skills/$alias"
    echo "    Removed deprecated alias: ~/.cursor/skills/$alias"
  fi
done

echo "==> Installing Cursor agents (Task subagents)..."
if [ -d "$ROOT/cursor/agents" ] && [ "$(ls -A "$ROOT/cursor/agents" 2>/dev/null)" ]; then
  mkdir -p "$HOME/.cursor/agents"
  rsync -a "$ROOT/cursor/agents/" "$HOME/.cursor/agents/"
  echo "    Agents: $(ls "$HOME/.cursor/agents"/*.md 2>/dev/null | wc -l | tr -d ' ')"
fi

echo "==> Installing Claude profiles..."
mkdir -p "$HOME/.claude/profiles"
rsync -a "$ROOT/claude/profiles/" "$HOME/.claude/profiles/"

echo "==> Installing Claude skills..."
mkdir -p "$HOME/.claude/skills"
rsync -a "$ROOT/claude/skills/" "$HOME/.claude/skills/"
# Remove deprecated cyber-* duplicates if they exist as separate trees after rsync
for alias in cyber-web-security cyber-blue-team-defense cyber-ai-llm-security cyber-grc-compliance; do
  if [ -e "$HOME/.claude/skills/$alias" ]; then
    # Keep only if not already covered: replace with symlink to numbered canonical when possible
    case "$alias" in
      cyber-web-security) target="09-web-security" ;;
      cyber-blue-team-defense) target="15-blue-team-defense" ;;
      cyber-ai-llm-security) target="16-ai-llm-security" ;;
      cyber-grc-compliance) target="19-grc-compliance" ;;
    esac
    if [ -n "${target:-}" ] && [ -d "$HOME/.claude/skills/$target" ]; then
      rm -rf "$HOME/.claude/skills/$alias"
      ln -sfn "$HOME/.claude/skills/$target" "$HOME/.claude/skills/$alias"
      echo "    Alias $alias -> $target (symlink)"
    fi
  fi
done

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
  mkdir -p "$HOME/.cursor/plugins/local"
  rsync -a --delete "$ROOT/cursor/plugins/local/" "$HOME/.cursor/plugins/local/"
  echo "    Local plugins: $(ls "$HOME/.cursor/plugins/local" | tr '\n' ' ')"
fi

echo "==> MCP runtimes (serena, gitleaks, claude-flow, GITHUB_TOKEN)..."
if [ "${SECURESKILLS_SKIP_MCP_DEPS:-}" != "1" ]; then
  bash "$ROOT/scripts/install-mcp-deps.sh" || echo "    WARN: install-mcp-deps.sh reported issues (non-fatal)"
fi

# Optional: seed current project with SecureCorp .cursor template
if [ "${SECURESKILLS_SEED_PROJECT:-}" = "1" ] && [ -d "$ROOT/templates/project/.cursor" ]; then
  TARGET="${SECURESKILLS_PROJECT_ROOT:-.}"
  mkdir -p "$TARGET/.cursor"
  rsync -a "$ROOT/templates/project/.cursor/" "$TARGET/.cursor/"
  echo "==> Seeded project template into $TARGET/.cursor"
fi

echo ""
echo "==> Plugins restored. See plugins-manifest.json / expert-registry.yaml."
echo "==> Done. Restart Cursor and Claude Code."
echo "    Run: snyk auth  (if using Snyk MCP)"
echo "    Audit:  bash scripts/audit-ecosystem.sh"
echo "    Health: bash scripts/verify-integrations.sh"
echo "    Latency: bash scripts/verify-cursor-latency.sh  (then NEW Agent chat)"
echo "    Optional: SECURESKILLS_SEED_PROJECT=1 bash scripts/install-to-local.sh"
