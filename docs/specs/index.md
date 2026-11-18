# Specs

The FlexUI firmware for the TrimUI Brick, by domain. The overview that
coordinates them is [SPEC.md](../SPEC.md).

| Domain | Spec | Covers |
|---|---|---|
| Core | [hooks.md](core/hooks.md) | Events, veto, timeouts, `<pak>.<event>`, hooks log |
| Core | [manifest.md](core/manifest.md) | `manifest.toml`, categories, legacy paks, validation |
| Core | [clock.md](core/clock.md) | NTP, trusted time |
| Parental | [rules.md](parental/rules.md) | Activities, budgets, time windows, extra time, budget day |
| Parental | [enforcement.md](parental/enforcement.md) | Vetoes, warnings, save-and-quit, `parental.*` events |
| Parental | [data.md](parental/data.md) | The `parental/` folder, history, stats recording |
| Admin | [server.md](admin/server.md) | When the server runs, transport, binary |
| Admin | [pairing.md](admin/pairing.md) | QR code, token, paired phones |
| Admin | [interface.md](admin/interface.md) | Screens, stats chart, JSON API |
| Sync | [sync.md](sync/sync.md) | The sync pak: links, policies, conflicts |
| Project | [licence.md](project/licence.md) | README, `NOTICE`, dependencies |
| Project | [testing.md](project/testing.md) | Simulator, device-only checks |

Each spec has the same shape: decisions with stable IDs (H1, M3, P7...),
behaviour, interfaces, open questions.
