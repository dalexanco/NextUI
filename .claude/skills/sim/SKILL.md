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
| `rom GB "Zelda.gb"` | Add an empty ROM to a system's folder, by tag (`GB`, `GBA`, `GBC`, `FC`, `MD`, `PS`, `SFC`) |
| `game start GB "Zelda.gb"` | Launch it as the launcher does: `/tmp/next`, `pre-launch` hooks (may veto), the Emus pak, `post-launch` |
| `game stop` | Quit the running game, as the player would |
| `game status` | The running game, if any |
| `emit pre-launch` | Run an event's hooks with the device environment; prints `exit=` (non-zero means vetoed) |
| `log [n]` | Last lines of the simulator log: launcher output, `/tmp/next` commands, vetoes |
| `exec <cmd>` | A command in the container with the device variables (`$SDCARD_PATH`, `$SYSTEM_PATH`, `$LOGS_PATH`...) |
| `stop`, `down`, `reset` | Stop the loop; remove the container; also drop its build cache and SD card |

The SD card lives at `/var/tmp/nextui/sdcard` in the container, on a volume:
ROMs, `.userdata` and test paks survive `down` and rebuilds. Port 80 of the
container is published on `localhost:8080`, for the admin server.

## Games

No libretro core is built for desktop, so `minarch.elf` is a stand-in
(`test/sim/in-container/fake-minarch.sh`, first on `PATH`). It is a process
named `minarch.elf` that shows "Playing <rom>" on screen and answers the same
signals as the real one (`workspace/all/flexui/minarch_control.h`):

| Signal | Effect | Log line |
|---|---|---|
| `SIGUSR1` | Save and quit | `[game] save-and-quit (SIGUSR1)` |
| `SIGUSR2` | Toast with `/tmp/minarch_notify.txt`, then delete it | `[game] toast: <text>` |
| `SIGTERM` (`game stop`) | Quit | `[game] quit` |

A launch also works from the UI: `key a` on a system, `key a` on the ROM. Paks
run under `busybox ash`, the device shell.

Parental contexts to drive this way:

| Context | Steps |
|---|---|
| Launch allowed | `game start ...`, then `game status` says playing |
| Launch refused | A `pre-launch.sh` exits non-zero: `game status` says no game, `log` shows `--- vetoed` |
| Warning during a game | `exec killall -USR2 minarch.elf` after writing the notify file, as Parental.pak does |
| Budget exhausted | `exec killall -USR1 minarch.elf`: save-and-quit, then back to the launcher and `post-launch` |
| Player quits | `game stop`, then `post-launch` runs |

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
| Gameplay | A stand-in replaces minarch: launch, quit and the control signals are simulated, the game itself is not |
| Vibration, LED | `PLAT_setRumble` is a no-op; desktop has no LED control |
| Sleep, wake, lid | No suspend on desktop; fire the `pre-sleep` / `post-resume` hooks with `emit` |
| Bluetooth, real Wi-Fi | `wifi` only flips the status icon and `PLAT_getNetworkStatus` |
| Events from hardware | `set` changes state, it raises no event. `emit` fires the events that exist today: `boot`, `pre-launch`, `post-launch`, `pre-sleep`, `post-resume`; the other events of `docs/specs/core/hooks.md` come with its implementation |
| `ntpd`, `uci`, `/sys/class/power_supply` | Stock firmware services, absent from the container |
| Parental.pak | Not built for desktop: it links `libgametimedb`, whose desktop build fails (`-Werror`, OpenGL). Test its logic through hooks and signals until it builds |
| `gametimectl.elf` | Not built for desktop; the log shows "not found", harmless |
| BusyBox `ash` | Scripts run under Ubuntu's `dash`; `busybox ash script.sh` checks the device shell |

The Brick is `tg5040`, 1024×768: the desktop build uses the same resolution.
