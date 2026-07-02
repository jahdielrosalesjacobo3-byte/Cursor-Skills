#!/usr/bin/env bash
# Setup security stack: symlinks Claude skills + global Cursor MCP/hooks
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CLAUDE_SKILLS="$HOME/.claude/skills"
CURSOR_DIR="$HOME/.cursor"

echo "==> Linking Claude Code skills..."

link_skill() {
  local src="$1"
  local name="$2"
  if [[ ! -d "$src" ]]; then
    echo "  SKIP (missing): $src"
    return
  fi
  mkdir -p "$CLAUDE_SKILLS"
  ln -sfn "$src" "$CLAUDE_SKILLS/$name"
  echo "  OK: $name -> $src"
}

# OWASP
link_skill "$ROOT/skills/claude-code-owasp/.claude/skills/owasp-security" "owasp-security"

# Full-stack security audit (toshipon)
link_skill "$ROOT/skills/claude-code-security-audit" "security-audit"

# Masriyan — blue team + web + AI security (subset; full set in skills/claude-cybersecurity/)
for skill in 09-web-security 15-blue-team-defense 16-ai-llm-security 19-grc-compliance; do
  name="cyber-${skill#*-}"
  link_skill "$ROOT/skills/claude-cybersecurity/skills/$skill" "$name"
done

echo ""
echo "==> Configuring global Cursor MCP servers..."

mkdir -p "$CURSOR_DIR"
cat > "$CURSOR_DIR/mcp.json" <<'EOF'
{
  "mcpServers": {
    "Snyk": {
      "command": "/opt/homebrew/bin/snyk",
      "args": ["mcp", "-t", "stdio"],
      "env": {}
    },
    "Semgrep": {
      "command": "/opt/homebrew/bin/semgrep",
      "args": ["mcp", "-t", "stdio"],
      "env": {}
    }
  }
}
EOF
echo "  OK: ~/.cursor/mcp.json"

echo ""
echo "==> Configuring global Semgrep Guardian hooks..."

cat > "$CURSOR_DIR/hooks.json" <<'EOF'
{
  "version": 1,
  "hooks": {
    "sessionStart": [
      {
        "command": "/opt/homebrew/bin/semgrep mcp -k inject-secure-defaults -a cursor"
      }
    ],
    "afterFileEdit": [
      {
        "command": "/opt/homebrew/bin/semgrep mcp -k record-file-edit -a cursor"
      }
    ],
    "postToolUse": [
      {
        "command": "/opt/homebrew/bin/semgrep mcp -k supply-chain-scan -a cursor",
        "matcher": "Shell"
      }
    ],
    "stop": [
      {
        "command": "/opt/homebrew/bin/semgrep mcp -k stop-cli-scan -a cursor",
        "loop_limit": 3
      }
    ]
  }
}
EOF
echo "  OK: ~/.cursor/hooks.json"

echo ""
echo "==> Trail of Bits (Claude Code) — run manually in Claude:"
echo "    /plugin marketplace add trailofbits/skills"
echo "    /plugin install static-analysis@trailofbits"
echo "    /plugin install differential-review@trailofbits"
echo "    /plugin install supply-chain-risk-auditor@trailofbits"
echo ""
echo "==> Snyk auth (required for scans):"
echo "    snyk auth"
echo ""
echo "==> Done. Restart Cursor to load MCP + hooks."
