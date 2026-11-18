---
name: sim
description: Start, drive and inspect the FlexUI simulator - the desktop platform built for Linux in a container, on a 1024x768 virtual screen. Use to try a change to the launcher, a pak, a hook or the admin server without the device, to take screenshots, press device buttons, simulate battery/charging/Wi-Fi, or fire hook events. Triggers - "test in the simulator", "run it in docker", "sim", "take a screenshot of the UI", "try this hook", "start the test container".
---

# FlexUI simulator

`test/sim/sim.sh` drives a container that builds the **desktop** platform from
this repository and runs the launcher loop on a virtual X screen. Every command
runs from the repository root.

## Start

```sh
test/sim/sim.sh up       # build or update the image, start the container
test/sim/sim.sh build    # copy the repo in, build desktop, install on the SD card
test/sim/sim.sh start    # run the launcher loop on the virtual screen
test/sim/sim.sh shot     # -> build-sim/shot.png; open it with the Read tool
```

The first `build` clones dependencies and takes a few minutes; later ones reuse
a cache volume. After changing code: `stop`, `build`, `start`.

## Drive

| Command | Effect |
|---|---|
| `key a`, `key down down a`, `key b wait b` | Press device buttons: `up down left right a b x y start select menu power l1 r1`; `wait` pauses 0.5 s |
| `shot [file]` | Screenshot, PNG, 1024×768. Read it to see the screen |
| `set battery 15`, `set charging 0`, `set wifi 1` | Simulated hardware state, read by the desktop platform (`workspace/desktop/platform/platform.c`, `simInt`) |
| `emit pre-launch` | Run an event's hooks with the device environment; prints `exit=` (non-zero means vetoed) |
| `log [n]` | Last lines of the simulator log: launcher output, `/tmp/next` commands, vetoes |
| `exec <cmd>` | A command in the container with the device variables (`$SDCARD_PATH`, `$SYSTEM_PATH`, `$LOGS_PATH`...) |
| `stop`, `down`, `reset` | Stop the loop; remove the container; also drop its build cache and SD card |

The SD card lives at `/var/tmp/nextui/sdcard` in the container, on a volume:
ROMs, `.userdata` and test paks survive `down` and rebuilds. Port 80 of the
container is published on `localhost:8080`, for the admin server.

## Typical checks

- **A UI change**: `stop`, `build`, `start`, then `key ...` and `shot` at each
  step. Compare screenshots rather than trusting the log.
- **A hook or pak**: write the pak under `$SDCARD_PATH/Tools/desktop/` with
  `exec`, delete `/tmp/pak_hooks_cache.txt`, then `emit <event>` and read the
  pak's log under `$LOGS_PATH`.
- **Battery or Wi-Fi reactions**: `set ...`, wait ~5 s for the launcher's poll,
  `shot`.
- **Shell scripts**: `exec shellcheck -s sh <file>` — shellcheck is installed in
  the image, not on the host.

## Limitations

What the simulator cannot show; test these on the Brick.

| Not simulated | Why |
|---|---|
| Games | No libretro core is built for desktop; launching a ROM fails, so minarch, save-and-quit and in-game behaviour are device-only |
| Vibration, LED | `PLAT_setRumble` is a no-op; desktop has no LED control |
| Sleep, wake, lid | No suspend on desktop; fire the `pre-sleep` / `post-resume` hooks with `emit` |
| Bluetooth, real Wi-Fi | `wifi` only flips the status icon and `PLAT_getNetworkStatus` |
| Events from hardware | `set` changes state, it raises no event. `emit` fires the events that exist today: `boot`, `pre-launch`, `post-launch`, `pre-sleep`, `post-resume`; the other events of `docs/specs/core/hooks.md` come with its implementation |
| `ntpd`, `uci`, `/sys/class/power_supply` | Stock firmware services, absent from the container |
| Device-only paks | `workspace/all/flexui/makefile` builds Parental.pak and other modules for device platforms only |
| `gametimectl.elf` | Not built for desktop; the log shows "not found", harmless |
| BusyBox `ash` | Scripts run under Ubuntu's `dash`; `busybox ash script.sh` checks the device shell |

The Brick is `tg5040`, 1024×768: the desktop build uses the same resolution.
