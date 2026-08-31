# FlexUI

A variant of [NextUI](https://github.com/LoveRetro/NextUI) for the TrimUI Brick and
Smart Pro, built around **paks**: more extension points in the firmware itself, and
more of the useful paks shipped as part of the system rather than bolted on.

FlexUI is not a rewrite and not a competitor. It tracks NextUI closely and carries a
deliberately small set of changes to it. Everything NextUI does, FlexUI does — the
launcher, `minarch`, the emulator paks, RetroAchievements, all of it.

## Why it exists

NextUI's extension system is the shell: a pak is a directory with a `launch.sh`. That
is elegant, and it stops short in two places.

- A pak can be *launched*, but it cannot easily *react* — to a game starting, to the
  console going to sleep, to boot.
- Anything that needs to be always-on has to be installed by hand on the SD card, so
  it is not really part of the system.

FlexUI adds the seams that fix both, then uses them to ship paks natively.

## What FlexUI adds

| | Status |
|---|---|
| **Lifecycle hooks** — a Tools pak registers for `boot`, `pre-launch`, `post-launch`, `pre-sleep`, `post-resume` by dropping a matching script next to its `launch.sh`; a `pre-launch.sh` that exits non-zero cancels the launch | done |
| **Native paks** — Parental control, Music Player, Gift Code shipped with the system instead of installed by hand | in progress |
| **Interface translations** | planned |
| **Pak auto-discovery in the build** — adding a pak stops meaning "edit two makefiles" | planned |

Each is kept as small as possible inside NextUI's own code. See
[docs/fork-strategy.md](docs/fork-strategy.md).

## Relationship to NextUI

FlexUI is a fork that intends to stay one. Every change to NextUI's own code is kept
minimal on purpose, so that upstream releases can be picked up quickly and so that
the changes can be offered back as pull requests. A change that gets merged upstream
is deleted here.

**Report FlexUI problems here, not to LoveRetro.** If a bug reproduces on stock
NextUI, it belongs upstream.

All credit for the firmware itself goes to the NextUI team, and to
[@shauninman](https://github.com/shauninman) for MinUI, which NextUI forked.

## Installing

Build from source for now (below). FlexUI installs the same way NextUI does — see
NextUI's [installation guide](https://nextui.loveretro.games/usage/#getting-started)
for the SD card side.

## Building

Cross-compilation runs in a Docker or Podman container; the root makefile runs on the
host.

```sh
make PLATFORM=tg5040 build      # one platform
make all                        # both platforms + release zips
make PLATFORM=tg5040 shell      # interactive toolchain shell
```

Prerequisites: Docker or Podman, git, make, curl, zip, jq, zipmerge, and adb to
deploy to the device.

## Working on FlexUI

| Document | Covers |
|---|---|
| [docs/fork-strategy.md](docs/fork-strategy.md) | Why the fork is shaped this way |
| [docs/architecture/](docs/architecture/index.md) | How NextUI works |
| `PAKS.md`, `HOOKS.md` | The extension points, upstream's own specs |

FlexUI is a plain fork of NextUI: one `main` that merges `nextui/main` at each
sync, via `scripts/flexui/sync-upstream.sh`. Changes to NextUI's own code are
kept deliberately small so that upstream releases stay cheap to pick up.

## Licence

[PolyForm Noncommercial 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0),
inherited from NextUI. Personal, educational and non-commercial use is freely
permitted; commercial use is not. See [LICENSE](LICENSE) and [NOTICE](NOTICE).
