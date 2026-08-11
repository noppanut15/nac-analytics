# nac-nd

> **In development** — install from source today; PyPI release planned.

CLI for change analysis on Cisco ACI fabrics via Nexus Dashboard 4.2.1+. Upload a candidate configuration, compare snapshots, or check compliance.

**Requirements:** Nexus Dashboard 4.2.1+, Python 3.10+, an ACI fabric registered in Nexus Dashboard.

## Install (from source)

```bash
git clone https://github.com/netascode/nac-nd.git
cd nac-nd
uv sync --group dev
uv run nac-nd --help
```

PyPI install (`pip install nac-nd` / `uv tool install nac-nd`) will be added when the first release is published.

## Quick start

```bash
cp config.example.yaml nac-nd.yaml   # edit host, fabric, domain
cp .env.example .env                 # set ND_USER and ND_PASSWORD (gitignored)
uv run nac-nd doctor
```

Run `nac-nd <command> --help` for all options.

## Configuration

Settings resolve in order: **CLI flags → environment variables → YAML → `.env` in cwd**.

| YAML key | Environment variable | Notes |
| --- | --- | --- |
| `host` | `ND_HOST` | Nexus Dashboard hostname (optional `http://` prefix) |
| `username` / `user` | `ND_USER` | |
| `password` | `ND_PASSWORD` | Keep in env/CI secrets, not YAML |
| `domain` | `ND_DOMAIN` | Default `DefaultAuth` |
| `fabric` | `ND_FABRIC` | Default fabric for commands |
| `fabrics` | — | List for `compliance --all` |
| `verify_ssl` / `verify_tls` | `ND_VERIFY_SSL` | `ND_VERIFY_TLS` accepted as alias |
| `ca_bundle` | `ND_CA_BUNDLE` | |
| `job_timeout_minutes` | `ND_JOB_TIMEOUT_MINUTES` | |
| `poll_interval` | `ND_POLL_INTERVAL` | |
| `delta_detail` | `ND_DELTA_DETAIL` | Overrides `--detail` default |

Config file locations: `--config path`, `ND_CONFIG`, `./nac-nd.yaml`, or `~/.config/nac-nd/config.yaml`.

## Commands

All primary inputs use **positional arguments** (not flags):

| Command | Syntax |
| --- | --- |
| `prechange` | `nac-nd prechange <plan.json> [<baseline>]` or `nac-nd prechange --job-id <id>` |
| `snapshots` | `nac-nd snapshots <selector>` |
| `delta` | `nac-nd delta [<pre>] [<post>]` |

`prechange` and `delta` are **gate commands**: they fail on new `critical`/`major` anomalies by default, write JUnit to `prechange-report.xml` / `delta-report.xml`, and print a one-line verdict on stderr. Use `--output text` for a full human-readable report.

### doctor — check connectivity

```bash
nac-nd doctor
```

### prechange — Terraform plan (Network as Code)

Use with [Network as Code](https://netascode.cisco.com) projects: run `terraform plan`, export JSON, analyse before apply.

```bash
terraform plan -out=plan.tfplan
terraform show -json plan.tfplan > plan.json
nac-nd prechange plan.json
```

- **Exit 0** — DECISION: PASS  
- **Exit 3** — DECISION: FAIL  
- Writes `prechange-report.xml` automatically  
- Use `--fail-on none` to report only (always exit 0)  
- Use `--output text` for the full change-approval report on stdout

Optional baseline positional (defaults to `latest`):

```bash
nac-nd prechange plan.json latest-1
```

Resume or fetch an existing analysis (no re-upload) — useful after a timeout while ND was still queued:

```bash
nac-nd prechange --job-id <job-id> --fail-on none
```

`--job-id` waits if the job is still running, then writes the report from the completed result.

### prechange — APIC MO JSON

```bash
nac-nd prechange examples/minimal-change.json --output text
```

### snapshots — pin a snapshot ID

```bash
SNAPSHOT_ID=$(nac-nd snapshots latest)
```

Text output is the snapshot ID only (for `$()` capture). Use `--output json` for the full record.

### delta — compare snapshots

```bash
nac-nd delta                    # latest-1 vs latest (ad-hoc only)
nac-nd delta abc-123            # pinned pre, post defaults to latest
nac-nd delta abc-123 def-456    # both pinned
```

Writes `delta-report.xml` by default. Selectors: `latest`, `latest-N`, or a snapshot ID.

### compliance — rule status

```bash
nac-nd compliance
nac-nd --config nac-nd.yaml compliance --all --fail-on-violations
```

## CI/CD

Gate commands need **no extra flags** in CI — fail on exit code, not by parsing output:

```yaml
- name: Pre-change analysis
  run: nac-nd prechange plan.json

- name: Pin baseline snapshot
  id: baseline
  run: echo "snapshot_id=$(nac-nd snapshots latest)" >> "$GITHUB_OUTPUT"

- run: terraform apply -auto-approve plan.tfplan

- name: Post-apply delta
  run: nac-nd delta "${{ steps.baseline.outputs.snapshot_id }}"
```

Pin the baseline snapshot ID saved **before** apply. Do not rely on `nac-nd delta` with no arguments in CI — another snapshot may arrive between stages.

Optional: upload auto-generated reports:

```yaml
- uses: actions/upload-artifact@v4
  if: always()
  with:
    name: nd-reports
    path: |
      prechange-report.xml
      delta-report.xml
```

### Local full pipeline

After exporting a Terraform plan from `examples/terraform`:

```bash
PLAN_FILE=examples/terraform/plan.json ./examples/ci-pipeline.sh
```

See [examples/README.md](examples/README.md) for APIC credentials and apply steps.

## Exit codes

| Code | Meaning |
| --- | --- |
| 0 | Success; threshold not breached |
| 1 | Unexpected error |
| 2 | Analysis job failed, stopped, vanished, or timed out |
| 3 | New anomalies at `--fail-on` (or compliance violations with `--fail-on-violations`) |
| 4 | Bad input, config, or configuration rejected by Nexus Dashboard |
| 5 | Authentication or authorisation failure |

## Development

```bash
uv sync --group dev
uv run pytest
uv run ruff check .
uv run ruff format --check .
uv run python -m mypy nac_nd
```
