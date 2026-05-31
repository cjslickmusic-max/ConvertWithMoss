# ConvertWithMoss machine progress protocol (RUS contribution)

Public reference for [git-moss/ConvertWithMoss#141](https://github.com/git-moss/ConvertWithMoss/issues/141).

## Activation

- **Environment:** `RUS_CWM_MACHINE_PROGRESS=1` or `true` (proposed upstream name: `CWM_MACHINE_PROGRESS`)
- **CLI flag (patched builds):** `-P` / `--machine-progress`

## Line format (stderr)

```text
RUS_CWM_PROGRESS pct=<0..100> phase=<token> detail=<text>
```

Phases: `start`, `convert`, `sample`, `done`.

## Files in this folder

| File | Purpose |
|------|---------|
| `cwm-rus-machine-progress.patch` | git apply against upstream tip |
| `MachineProgressReporter.java` | stderr emitter (new class) |
| `apply-cwm-sample-progress.ps1` | idempotent per-sample hooks after machine patch |

Full patched sources: branch [`rus-patched-2026-05`](../../tree/rus-patched-2026-05).

Pre-built CLI: [Releases](../../releases) tag `rus-patched-17.2.0`.

Licensed under LGPL-3 (ConvertWithMoss derivative).
