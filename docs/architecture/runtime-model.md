# Runtime model

## One process at a time

There is no window manager and no visual multitasking. A shell loop
(`skeleton/SYSTEM/<platform>/paks/MinUI.pak/launch.sh`) orchestrates everything:

1. it runs `nextui.elf` (the menu) and **waits for it to exit**;
2. when the user picks a game or a tool, `nextui.elf` **writes the command to
   `/tmp/next`** and quits;
3. the shell reads `/tmp/next`, runs the `pre-launch` hooks, `eval`s the command
   (starting `minarch.elf` or a tool), then runs the `post-launch` hooks;
4. back to step 1.

```sh
while [ -f $EXEC_PATH ]; do
    nextui.elf &> $LOGS_PATH/nextui.txt
    sh "$SYSTEM_PATH/bin/governor.sh" "performance"
    if [ -f $NEXT_PATH ]; then
        CMD=`cat $NEXT_PATH`
        parse_hook_cmd "$CMD"
        "$SYSTEM_PATH/bin/pak-hooks.sh" pre-launch && eval $CMD
        "$SYSTEM_PATH/bin/pak-hooks.sh" post-launch
        rm -f $NEXT_PATH
    fi
done
```

## Consequences

- Memory is fully reclaimed between menu and game — the right trade on a
  constrained device.
- **IPC happens through sentinel files**, declared in
  `workspace/all/common/defines.h:34`: `/tmp/next`, `/tmp/last.txt`,
  `/tmp/poweroff`, `/tmp/reboot`, `/tmp/change_disc.txt`, `/tmp/resume_slot.txt`,
  `/tmp/noui`.
- A pak is never more than a `launch.sh`. The extension system *is* the shell.
- Anything that must survive across foreground processes (key handling, battery
  history, audio routing) has to be a daemon. See
  [system-services.md](system-services.md).

## The shared library

`workspace/all/common/` is what every application links against.

| File | Lines | Role |
|---|---|---|
| `api.c` / `api.h` | 4753 / 969 | the whole API surface: `GFX_*`, `SND_*`, `PAD_*`, `PWR_*`, `VIB_*`, `LEDS_*` |
| `scaler.c` | 3072 | NEON + C pixel scalers for emulator output |
| `generic_video.c` | 2321 | SDL2 + OpenGL ES backend, compositor layers, shaders |
| `config.c` / `config.h` | 1752 / 482 | `NextUISettings` and ~120 `CFG_get*` / `CFG_set*` accessors |
| `generic_wifi.c` / `generic_bt.c` | 606 / 775 | networking, driven through `wpa_cli` / `bluetoothctl` |
| `notification.c` | 668 | toast queue and in-game system indicators |
| `ra_*.c` | ~2500 | RetroAchievements |
| `defines.h` | 238 | paths, UI metrics, button enums |

The launcher itself, `workspace/all/nextui/nextui.c`, is 3435 lines in a single
file — MinUI's `minui.c`, renamed. It carries its own mini standard library
(`Array`, `Hash`, `Entry`, `Directory`, `Recent`) and an immediate-mode render
loop. This is the file most likely to conflict on an upstream sync.
