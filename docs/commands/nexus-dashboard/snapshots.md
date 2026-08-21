# snapshots

[← Nexus Dashboard commands](README.md) · [Command reference](../README.md)

Resolve a fabric snapshot selector and print its ID. Use in CI to pin baselines before and after a change.

Selectors: `latest`, `latest-N`, or a concrete `snapshotId`. Combine with `-since` / `-until` when the API's 50-record listing cap requires narrowing the window.

This command only reads what ND has already collected, and ND collects online fabrics every 2–4 hours. To produce a snapshot on demand instead, use [analyze](analyze.md).

## Examples

```bash
nac-analytics nd snapshots latest
SNAP=$(nac-analytics nd snapshots latest)
nac-analytics nd snapshots -output json latest-1
```

Run `nac-analytics nd snapshots --help` for all flags and options.
