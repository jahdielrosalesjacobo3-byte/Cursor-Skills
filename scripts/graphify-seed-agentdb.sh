#!/usr/bin/env bash
# Seed AgentDB / claude-flow memory with Graphify god nodes + community labels.
# Does not re-extract AST — reads graphify-out/.graphify_analysis.json only.
#
# Usage:
#   bash scripts/graphify-seed-agentdb.sh
#   bash scripts/graphify-seed-agentdb.sh /path/to/repo
#   TOP_N=20 bash scripts/graphify-seed-agentdb.sh
set -euo pipefail

TARGET="${1:-.}"
TARGET="$(cd "$TARGET" && pwd)"
ANALYSIS="$TARGET/graphify-out/.graphify_analysis.json"
OUT="$TARGET/graphify-out/.graphify_agentdb_seed.json"
TOP_N="${TOP_N:-15}"
NS="${GRAPHIFY_SEED_NAMESPACE:-graphify-structure}"

if [[ ! -f "$ANALYSIS" ]]; then
  echo "error: missing $ANALYSIS — run graphify cluster-only first" >&2
  exit 1
fi

python3 - "$ANALYSIS" "$OUT" "$TOP_N" <<'PY'
import json, sys
analysis_path, out_path, top_n = sys.argv[1], sys.argv[2], int(sys.argv[3])
data = json.loads(open(analysis_path, encoding="utf-8").read())
gods = (data.get("gods") or [])[:top_n]
communities = data.get("communities") or {}
labels = data.get("community_labels") or {}
payload = {
    "namespace": "graphify-structure",
    "god_nodes": [
        {"label": g.get("label"), "id": g.get("id"), "degree": g.get("degree")}
        for g in gods
    ],
    "communities": [
        {
            "id": cid,
            "label": labels.get(str(cid)) or labels.get(cid) or f"Community {cid}",
            "size": len(nodes) if isinstance(nodes, list) else 0,
        }
        for cid, nodes in sorted(communities.items(), key=lambda x: -len(x[1]) if isinstance(x[1], list) else 0)[:30]
    ],
}
json.dump(payload, open(out_path, "w", encoding="utf-8"), indent=2, ensure_ascii=False)
print(f"wrote {out_path} ({len(payload['god_nodes'])} gods, {len(payload['communities'])} communities)")
PY

CLI="npx @claude-flow/cli@latest"
if ! command -v npx >/dev/null 2>&1; then
  echo "npx not found — seed JSON only at $OUT"
  exit 0
fi

REPO_NAME="$(basename "$TARGET")"
STORED=0

while IFS= read -r line; do
  label="$(echo "$line" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('label',''))")"
  degree="$(echo "$line" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('degree',0))")"
  node_id="$(echo "$line" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('id',''))")"
  [[ -z "$label" ]] && continue
  key="god-${REPO_NAME}-${label}"
  val="degree=${degree} id=${node_id} source=graphify"
  if $CLI memory store --namespace "$NS" --key "$key" --value "$val" 2>/dev/null; then
    STORED=$((STORED + 1))
  fi
done < <(python3 -c "import json; d=json.load(open('$OUT')); print('\n'.join(json.dumps(g) for g in d['god_nodes']))")

python3 - "$OUT" "$REPO_NAME" "$NS" "$CLI" <<'PY'
import json, subprocess, sys
out_path, repo, ns, cli = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
data = json.load(open(out_path, encoding="utf-8"))
for c in data.get("communities", [])[:20]:
    cid = c.get("id")
    label = c.get("label", f"Community {cid}")
    size = c.get("size", 0)
    key = f"community-{repo}-{cid}"
    val = f"label={label} size={size} source=graphify"
    subprocess.run(
        f'{cli} memory store --namespace {ns} --key "{key}" --value "{val}"',
        shell=True,
        capture_output=True,
    )
PY

echo "==> AgentDB seed complete (attempted god-node stores: $STORED)"
echo "    JSON fallback: $OUT"
echo "    namespace:     $NS"
