# Repository layout

Two trees, merged into `./build` by the makefile: copy `skeleton/` into `build/`,
then drop the binaries compiled from `workspace/` on top.

## `skeleton/` — the SD card image

Four subtrees, matching the release zips.

| Subtree | Becomes | Holds |
|---|---|---|
| `BOOT/` | `.tmp_update/` | the boot hijack: `common/updater`, replacements for TrimUI's boot scripts |
| `BASE/` | the visible card root | `Bios/ Roms/ Saves/ Cheats/ Overlays/ Palettes/ Shaders/` |
| `SYSTEM/` | `/.system` (hidden) | `res/` shared assets, then one directory per platform |
| `EXTRAS/` | the `-extras` zip | ~30 extra Emu paks, ~10 Tool paks |

`SYSTEM/<platform>/` contains `bin/`, `lib/`, `cores/`, `paks/MinUI.pak/launch.sh`
(the main loop), the seven base Emu paks, `etc/wifi`, `etc/bluetooth`, `shaders/`,
and `system.cfg`.

`.system` is **wiped and replaced on every update**. Personal paks go in `/Emus/`
and `/Tools/` at the card root, never there.

## `workspace/` — the sources

```
workspace/
├── makefile              orchestrator, RUNS INSIDE THE CONTAINER
├── all/                  platform-independent
│   ├── common/           the shared library
│   ├── nextui/nextui.c   the launcher
│   ├── minarch/          the libretro frontend, split into ma_*.c
│   ├── settings/         Settings app (C++17, widget framework)
│   ├── audiomon/ show2/  C++ daemons/tools
│   ├── batmon/ libbatmondb/ battery/          battery tracking
│   ├── gametimectl/ libgametimedb/ gametime/  play-time tracking
│   ├── ledcontrol/ bootlogo/ clock/ minput/   tools
│   ├── nextval/ syncsettings/                 shell-facing utilities
│   └── cores/            generic libretro core build template
├── tg5040/               Brick / Smart Pro / Brick Pro
│   ├── platform/         platform.c/.h, makefile.env, makefile.copy
│   ├── libmsettings/     shared-memory settings (volume, brightness)
│   ├── keymon/           raw key daemon
│   ├── cores/            core list, commit pins, 29 patches
│   ├── install/          boot.sh, update.sh, splash
│   └── btmanager/ rfkill/ poweroff_next/
├── tg5050/               near-clone of tg5040
└── desktop/              native target for local development
```

## Root files

| File | Role |
|---|---|
| `makefile` | host orchestrator (macOS/Linux), not in Docker |
| `makefile.toolchain` | Docker/Podman cross-compilation driver |
| `makefile.native` | pseudo-toolchain for `PLATFORM=desktop` |
| `commits.sh` | writes `commits.txt`, the hash of every repository used |
| `PAKS.md`, `HOOKS.md` | extension-point specs, inherited from MinUI |

`.gitignore` excludes what is cloned or built on the fly: `libretro-common`,
`**/rcheevos/src`, `**/cores/src`, `toolchains/`, `build/`, `releases/`.

## Where FlexUI puts its own code

`workspace/all/flexui/` and `skeleton/FLEXUI/` — paths upstream will never have,
so they cannot conflict. See [../fork-strategy.md](../fork-strategy.md).
