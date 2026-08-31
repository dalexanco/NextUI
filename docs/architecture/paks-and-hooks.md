# Paks and hooks

Upstream specs: `PAKS.md` and `HOOKS.md` at the repository root. This page is the
short version.

## Paks

**A pak is a directory whose name ends in `.pak` and contains a `launch.sh`.**
That is the entire plugin system: no ABI, no manifest, no registry — the launcher
scans directories and runs scripts.

| Type | Location | Role |
|---|---|---|
| Emu pak | `/Emus/<platform>/<TAG>.pak` | launch an emulator for one system |
| Tool pak | `/Tools/<platform>/<Name>.pak` | launch a utility |

The `<platform>` subdirectory is mandatory and lowercase. A pak may additionally
test `DEVICE` (`brick`, `brickpro`, `smartpro`).

### ROM → pak mapping

```
/Roms/Game Boy (GB)/Dr. Mario.gb  →  /Emus/tg5040/GB.pak/launch.sh
```

The **tag in parentheses at the end of the parent directory name** selects the
emulator. Implemented by `hasEmu()` in `workspace/all/nextui/nextui.c:535`.

### Anatomy

```sh
#!/bin/sh
EMU_EXE=picodrive
###############################
EMU_TAG=$(basename "$(dirname "$0")" .pak)
ROM="$1"
mkdir -p "$BIOS_PATH/$EMU_TAG" "$SAVES_PATH/$EMU_TAG" "$CHEATS_PATH/$EMU_TAG"
HOME="$USERDATA_PATH"; cd "$HOME"
minarch.elf "$CORES_PATH/${EMU_EXE}_libretro.so" "$ROM" &> "$LOGS_PATH/$EMU_TAG.txt"
```

Everything below the hash line is identical boilerplate everywhere. A pak may
ship its own core (`CORES_PATH=$(dirname "$0")`). Standalone emulators are
discouraged: no resume, no quicksave, no consistent in-game menu.

`default.cfg` carries default options and bindings. An option prefixed with `-`
is applied and hidden from the UI.

## Hooks

A Tools pak registers for a lifecycle phase by dropping an executable script next
to its own `launch.sh`. **The file's presence is the registration** — no arming
step, and removing the pak removes its hooks.

| File | Fires |
|---|---|
| `boot.sh` | at startup |
| `pre-launch.sh` | before a ROM or pak starts — **non-zero exit vetoes the launch** |
| `post-launch.sh` | after it exits |
| `pre-sleep.sh` | before sleep or power off |
| `post-resume.sh` | after wake |

The runner is `skeleton/SYSTEM/<platform>/bin/pak-hooks.sh`, called from
`MinUI.pak/launch.sh` and from `api.c` for the sleep phases. The list of
qualifying paks is cached in `/tmp` and rebuilt when returning to the menu from a
Tools pak.

Rules:

- each script runs in its own subshell; a crash affects nothing else;
- stdout and stderr are discarded — log to your own file;
- only `pre-launch.sh` can veto, and a vetoing hook must clean up anything the
  launcher already started (`gametimectl.elf stop_all`, for instance);
- nothing is displayed on a veto — use `show2.elf` to say why;
- stay fast: hooks sit between the user and their game.

The legacy `$USERDATA_PATH/.hooks/*.d/` mechanism driven by `run_hooks.sh` still
works but is deprecated.
