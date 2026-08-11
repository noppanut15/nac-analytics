# Shared helpers for ci-pipeline scripts.
# Expects ROOT to be set to the repository root before sourcing.

: "${ROOT:?ROOT must be set before sourcing _lib.sh}"

DEFAULT_PLAN_FILE="$ROOT/examples/terraform/plan.json"

resolve_nac_nd() {
  if [[ -n "${NAC_ND_BIN:-}" ]]; then
    NAC_ND=("$NAC_ND_BIN")
  elif [[ -x "$ROOT/.venv/bin/nac-nd" ]]; then
    NAC_ND=("$ROOT/.venv/bin/nac-nd")
  else
    NAC_ND=(uv run nac-nd)
  fi
}
