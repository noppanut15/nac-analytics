# analyze

[← Nexus Dashboard commands](README.md) · [Command reference](../README.md)

Trigger an assurance analysis on a fabric, wait for it to finish, and print the ID of the snapshot it produced. This is the API behind the GUI's "Analyze now".

Nexus Dashboard collects online fabrics on its own schedule — every 2–4 hours depending on fabric size. A pipeline that pins [`snapshots latest`](snapshots.md) before a change and compares against `latest` afterwards races that schedule: if no collection happened in between, both selectors resolve to the same record and [`delta`](delta.md) reports nothing. `analyze` removes the race by producing a snapshot on demand.

## Examples

```bash
nac-analytics nd analyze
```

Bracket a configuration push with two real snapshots:

```bash
PRE=$(nac-analytics nd analyze)
terraform apply plan.tfplan
POST=$(nac-analytics nd analyze)
nac-analytics nd delta "$PRE" "$POST"
```

Trigger without waiting — prints the **analysis job ID**, which is not a snapshot ID and cannot be passed to `delta`:

```bash
nac-analytics nd analyze --no-wait
```

`-output json` (or `yaml`) emits the whole snapshot record, including the `analysisJobId` that ties it back to the trigger.

## Notes

Run `nac-analytics nd analyze --help` for all flags and options.
