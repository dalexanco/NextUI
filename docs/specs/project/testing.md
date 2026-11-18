# Testing

What can be tested without the Brick, with what, and what stays device-only.

| Section | Content |
|---|---|
| [Simulator](#simulator) | The desktop platform in a container |
| [By domain](#by-domain) | What each domain can check in the simulator |
| [Device only](#device-only) | What needs the Brick |

## Simulator

`test/sim/sim.sh` builds the **desktop** platform for Linux in a container and
runs the launcher loop on a 1024×768 virtual screen, the Brick's resolution.
Commands and limits: [`.claude/skills/sim/SKILL.md`](../../../.claude/skills/sim/SKILL.md).

| Input | Output |
|---|---|
| Device buttons (`key`) | Screenshots (`shot`) |
| Battery, charging, Wi-Fi state (`set`), read by `workspace/desktop/platform/platform.c` | Simulator log (`log`) |
| Hook events (`emit`) | Files on the simulated SD card (`exec`) |

The SD card and the build cache live on volumes, so test data survives rebuilds.

## By domain

| Domain | In the simulator |
|---|---|
| [Hooks](../core/hooks.md) | Order, veto, timeouts, log rotation, with test paks and `emit` |
| [Manifest](../core/manifest.md) | Discovery, legacy synthesis, validation errors in the hooks log |
| [Clock](../core/clock.md) | Trust state logic; NTP itself needs the device |
| [Parental](../parental/rules.md) | Budgets, windows, vetoes, counters and logs, once Parental.pak builds for desktop |
| [Admin](../admin/server.md) | The API and page on `localhost:8080` |
| [Sync](../sync/sync.md) | Against a Samba container, from the sync pak's repository |

## Device only

| Area | Why |
|---|---|
| Games, minarch, save-and-quit | No libretro core is built for desktop |
| LED, vibration | No desktop implementation |
| Sleep, wake, lid, power | No suspend on desktop |
| Real Wi-Fi, Bluetooth, `ntpd`, `uci` | Stock firmware services |
| Battery readings from `/sys` | Replaced by the `set` files |
