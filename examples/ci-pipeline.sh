#!/usr/bin/env bash
# Nexus Dashboard full change-analysis pipeline (live ND + terraform apply).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=examples/_lib.sh
source "$ROOT/examples/_lib.sh"

PLAN="${PLAN_FILE:-$DEFAULT_PLAN_FILE}"

resolve_nac_nd

if [[ ! -f "$PLAN" ]]; then
  echo "error: plan file not found: $PLAN" >&2
  echo "Generate from examples/terraform:" >&2
  echo "  cd examples/terraform && terraform plan -out=plan.tfplan" >&2
  echo "  terraform show -json plan.tfplan > plan.json" >&2
  echo "Then: PLAN_FILE=examples/terraform/plan.json $0" >&2
  exit 1
fi

echo "==> pin baseline (latest, before apply)"
SNAPSHOT_ID=$("${NAC_ND[@]}" snapshots latest)
test -n "$SNAPSHOT_ID"
echo "snapshot_id=$SNAPSHOT_ID"

echo "==> prechange gate"
"${NAC_ND[@]}" prechange "$PLAN"
test -f prechange-report.xml

echo "==> apply (in examples/terraform: terraform apply plan.tfplan, then confirm)"
read -r -p "Apply complete? [y/N] " confirm
if [[ "$confirm" != [yY] ]]; then
  echo "Aborted."
  exit 1
fi

echo "==> post-apply delta"
"${NAC_ND[@]}" delta "$SNAPSHOT_ID"
test -f delta-report.xml

echo "PASS: full pipeline complete"
