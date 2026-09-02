#!/usr/bin/env bash
# Verify Cursor latency setup: compact K3 rule globally, no duplicate project rules.
set -euo pipefail

HOME_RULES="$HOME/.cursor/rules"
K3="$HOME_RULES/k3-cognitive-runtime.mdc"
SEC="$HOME_RULES/security-scanning.mdc"
ERR=0

fail() { echo "ERR:  $*"; ERR=$((ERR + 1)); }
ok()   { echo "OK:   $*"; }

echo "==> Cursor latency / global rules check"
echo ""

[[ -f "$K3" ]] || fail "missing $K3 — run: bash scripts/install-to-local.sh"
[[ -f "$SEC" ]] || fail "missing $SEC"

if grep -q "Fast path (default)" "$K3" 2>/dev/null; then
  ok "K3 rule is compact (Fast path present)"
else
  fail "K3 rule still verbose/old — reinstall from SecureSkills"
fi

bytes=$(wc -c < "$K3" | tr -d ' ')
if [[ "$bytes" -lt 2500 ]]; then
  ok "K3 rule size ${bytes} bytes (< 2500)"
else
  fail "K3 rule too large (${bytes} bytes) — expected compact version"
fi

if grep -q "Default effort: \`high\`" "$K3" 2>/dev/null; then
  fail "K3 still says default effort high (old rule)"
else
  ok "K3 default effort not forced to high"
fi

# Duplicate project rule loads security twice every turn
for proj in "$HOME/Documents/skillsClaude" "$HOME/Documents/SecureSkills"; do
  dup="$proj/.cursor/rules/security-scanning.mdc"
  if [[ -f "$dup" ]]; then
    fail "duplicate security rule (extra context): $dup — remove; use ~/.cursor/rules only"
  fi
done
[[ "$ERR" -eq 0 ]] && ok "no duplicate project security-scanning.mdc"

if grep -q "composer-fast" "$HOME/.cursor/secureskills/harness-profiles.yaml" 2>/dev/null; then
  ok "harness composer-fast installed"
else
  fail "harness missing composer-fast — run install-to-local.sh"
fi

echo ""
if [[ "$ERR" -gt 0 ]]; then
  echo "Fix: cd ~/Documents/SecureSkills && bash scripts/install-to-local.sh"
  echo "Then: Cursor → Command Palette → Developer: Reload Window"
  echo "Then: open a **new** Agent chat (old threads keep stale rule snapshots)"
  exit 2
fi
echo "==> Global latency rules OK."
echo "    Open a **new** chat after Reload Window if this thread still feels slow."
exit 0
