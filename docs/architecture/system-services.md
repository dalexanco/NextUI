# System services

All daemons are started from `MinUI.pak/launch.sh` and run for the whole session,
because they must keep working **between** foreground processes (launcher ↔ game)
and during sleep.

```sh
trimui_inputd &      # the VENDOR's input daemon, not NextUI's
syslogd -S
sh governor.sh auto
keymon.elf &
batmon.elf &
audiomon.elf &
/etc/bluetooth/bt_init.sh start &
/etc/wifi/wifi_init.sh start &
```

## `keymon.elf`

`workspace/<platform>/keymon/keymon.c`. Reads `/dev/input/event*` directly (up to
5 devices) for input SDL does not surface, and writes state into `libmsettings`
shared memory so every other process sees it.

| Code | Meaning |
|---|---|
| `CODE_PLUS` 115 / `CODE_MINUS` 114 | volume up/down |
| `CODE_MENU0/1/2` 314/315/316 | menu keys |
| `CODE_MUTE` 1 | physical DIP switch (`/sys/class/gpio/gpio243/value`) |
| `CODE_JACK` 2 | headphone jack insertion |

It also enforces the bounds: `VOLUME_MAX 20`, `BRIGHTNESS_MAX 10`,
`COLORTEMP_MAX 40`.

## `batmon.elf`

`workspace/all/batmon/` plus `libbatmondb.so`. Records charge history and the
discharge curve into a local database; `Battery.pak` (`workspace/all/battery/`,
781 lines) draws the graph and the remaining-time estimate.

Instantaneous state comes from a monitoring thread in `api.c`
(`PWR_monitorBattery`, `api.c:3993`), exposed as `PWR_getBattery()`,
`PWR_isCharging()`, `PWR_isUSBConnected()`.

## `audiomon.elf`

C++ daemon using D-Bus and libudev to track audio sinks — Bluetooth headsets,
USB-C DACs — and route output accordingly. `.asoundrc` is deleted at boot before
it starts.

## `show2.elf`

Full-screen splash and message tool, used by the installer and by hooks that need
to tell the user something (`show2.elf --mode=simple --text="..." --timeout=3`).
It is the only way a vetoing `pre-launch.sh` can explain itself.

## `gametimectl.elf`

Play-time tracking, backed by `libgametimedb.so`; `Game Tracker.pak` reads it.
Since seam A it is driven entirely by that pak's own hooks rather than by calls
inside `nextui.c` and `api.c` — the one remaining direct call is a defensive
`stop_all` at launcher startup, catching sessions left open by a crash.
