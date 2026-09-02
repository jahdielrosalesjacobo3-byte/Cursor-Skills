#!/usr/bin/env bash
# Re-vendor the curated Trail of Bits skills subset into cursor/plugins/local/trailofbits-security.
# Upstream: https://github.com/trailofbits/skills (CC BY-SA 4.0)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DST="$ROOT/cursor/plugins/local/trailofbits-security"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

PLUGINS=(
  static-analysis semgrep-rule-creator semgrep-rule-variant-creator
  differential-review variant-analysis fp-check audit-context-building
  agentic-actions-auditor supply-chain-risk-auditor vulnerability-triage-brocards
  entry-point-analyzer burpsuite-project-parser yara-authoring
  property-based-testing mutation-testing sharp-edges spec-to-code-compliance
  second-opinion github-triage gh-cli modern-python
)

echo "==> Cloning trailofbits/skills"
git clone --depth 1 --quiet https://github.com/trailofbits/skills "$TMP/tob"
REV="$(git -C "$TMP/tob" rev-parse --short HEAD)"

echo "==> Rebuilding $DST (keeping manifest + NOTICE)"
find "$DST" -mindepth 1 -maxdepth 1 \
  ! -name '.cursor-plugin' ! -name 'NOTICE.md' -exec rm -rf {} +
mkdir -p "$DST/skills" "$DST/agents" "$DST/workflows"

for p in "${PLUGINS[@]}"; do
  src="$TMP/tob/plugins/$p"
  [ -d "$src" ] || { echo "    WARN: upstream plugin missing: $p"; continue; }
  for s in "$src"/skills/*/; do
    [ -f "$s/SKILL.md" ] || continue
    rsync -a --exclude tests --exclude __pycache__ --exclude .pytest_cache \
      "$s" "$DST/skills/$(basename "$s")/"
  done
  [ -d "$src/agents" ] && rsync -a "$src/agents/" "$DST/agents/"
  [ -d "$src/workflows" ] && find "$src/workflows" -type f -exec cp {} "$DST/workflows/" \;
  [ -d "$src/resources" ] && { mkdir -p "$DST/resources/$p"; rsync -a "$src/resources/" "$DST/resources/$p/"; }
done
cp "$TMP/tob/LICENSE" "$DST/LICENSE"
sed -i.bak -E "s/commit \`[0-9a-f]+\`/commit \`$REV\`/" "$DST/NOTICE.md" && rm -f "$DST/NOTICE.md.bak"

echo "==> skills: $(ls "$DST/skills" | wc -l | tr -d ' ')  agents: $(ls "$DST/agents" | wc -l | tr -d ' ')  upstream: $REV"
echo "    Install: bash scripts/install-to-local.sh  (rsyncs cursor/plugins/local -> ~/.cursor/plugins/local)"
