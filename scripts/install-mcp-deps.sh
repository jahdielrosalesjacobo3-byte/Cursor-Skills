#!/usr/bin/env bash
# Install / verify local runtimes required by cursor/mcp.json and cursor/hooks.json.
# Idempotent. Never writes secrets: GITHUB_TOKEN is derived from `gh auth token` at shell start.
#
#   bash scripts/install-mcp-deps.sh
set -euo pipefail

export PATH="${HOME}/.local/bin:/opt/homebrew/bin:${PATH}"
ok()   { printf '    OK:   %s\n' "$*"; }
warn() { printf '    WARN: %s\n' "$*"; }

echo "==> uv (Serena, graphify)"
command -v uv >/dev/null 2>&1 || { warn "uv missing — https://docs.astral.sh/uv/getting-started/installation/"; }

echo "==> Serena (LSP symbol tools MCP)"
if command -v uv >/dev/null 2>&1; then
  if ! command -v serena >/dev/null 2>&1; then
    uv tool install -p 3.13 serena-agent
  fi
  [ -f "$HOME/.serena/serena_config.yml" ] || serena init >/dev/null
  ok "serena $(serena --version 2>/dev/null | head -1)"
fi

echo "==> Graphify (viewer_url MCP tool + export forcegraph + graphify viewer)"
GRAPHIFY_REPO="${GRAPHIFY_REPO:-$HOME/Documents/Graphify}"
if command -v uv >/dev/null 2>&1; then
  if [ -f "$GRAPHIFY_REPO/pyproject.toml" ]; then
    # Local fork carries the 3D sidecar + viewer tooling until upstream ships it.
    uv tool install --force "$GRAPHIFY_REPO[mcp]" >/dev/null 2>&1 && ok "graphify from $GRAPHIFY_REPO ($(graphify --version 2>/dev/null))"
  elif ! command -v graphify >/dev/null 2>&1; then
    uv tool install "graphifyy[mcp]" >/dev/null 2>&1 && ok "graphify from PyPI (no viewer tooling)"
  else
    ok "graphify $(graphify --version 2>/dev/null) (set GRAPHIFY_REPO to install the fork)"
  fi
fi

echo "==> gitleaks (beforeShellExecution guard)"
if command -v gitleaks >/dev/null 2>&1; then ok "$(gitleaks version 2>/dev/null | head -1)"; else
  if command -v brew >/dev/null 2>&1; then brew install gitleaks && ok "gitleaks installed"; else warn "gitleaks missing — brew install gitleaks"; fi
fi

echo "==> claude-flow / ruflo (agent memory + swarm MCP)"
if command -v claude-flow >/dev/null 2>&1; then ok "$(claude-flow --version 2>/dev/null | head -1)"; else
  warn "claude-flow missing — npm i -g @claude-flow/cli  (mcp.json falls back to npx ruflo@latest)"
fi

echo "==> node/npx (shadcn MCP)"
command -v npx >/dev/null 2>&1 && ok "npx $(npx --version 2>/dev/null)" || warn "npx missing — brew install node"

echo "==> GitHub token for github MCP"
if command -v gh >/dev/null 2>&1; then
  LINE='export GITHUB_TOKEN="${GITHUB_TOKEN:-$(gh auth token 2>/dev/null)}"'
  if ! grep -qF 'GITHUB_TOKEN="${GITHUB_TOKEN:-$(gh auth token' "$HOME/.zshenv" 2>/dev/null; then
    printf '\n# SecureSkills: github MCP reads ${env:GITHUB_TOKEN}; derived from gh, no literal secret\n%s\n' "$LINE" >> "$HOME/.zshenv"
    ok "added GITHUB_TOKEN export to ~/.zshenv"
  else
    ok "~/.zshenv already exports GITHUB_TOKEN"
  fi
  if gh auth status >/dev/null 2>&1; then ok "gh authenticated"; else warn "run: gh auth login   (github MCP stays 401 until then)"; fi
else
  warn "gh missing — brew install gh; github MCP needs GITHUB_TOKEN"
fi

echo "==> Remote MCPs (OAuth on first use, nothing to store): context7, linear, aws-knowledge"
echo "==> Done. Restart Cursor so ~/.cursor/mcp.json + ~/.cursor/plugins/local reload."
