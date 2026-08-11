# Examples

| File / script | Purpose |
| --- | --- |
| `minimal-change.json` | Small APIC MO JSON for trying `nac-nd prechange` without Terraform |
| `terraform/` | Minimal NAC-as-Code project — `data/tenant_nac_nd_test.nac.yaml`, `env.example` |
| `ci-pipeline.sh` | Full lab pipeline: prechange → terraform apply → delta |
| `_lib.sh` | Shared plan path and `nac-nd` binary resolution (sourced by pipeline scripts) |

Do not commit real fabric plans or files that contain credentials or Terraform variable values.

## Terraform full pipeline

From the repo root:

```bash
cp examples/terraform/env.example examples/terraform/env.sh
# edit env.sh — APIC URL and credentials (may differ from nac-nd .env)
source examples/terraform/env.sh

cd examples/terraform
terraform init
terraform plan -out=plan.tfplan
terraform show -json plan.tfplan > plan.json
cd ../..

PLAN_FILE=examples/terraform/plan.json ./examples/ci-pipeline.sh
# When prompted: cd examples/terraform && terraform apply plan.tfplan
# Then confirm with y for post-apply delta
```

Requires a configured `nac-nd.yaml` and `.env` pointing at a live Nexus Dashboard fabric.

The sample tenant is `NAC_ND_TEST` with a single VRF — safe for lab fabrics.
