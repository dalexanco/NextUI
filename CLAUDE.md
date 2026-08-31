# FlexUI

A fork of [LoveRetro/NextUI](https://github.com/LoveRetro/NextUI), the alternative
firmware for TrimUI Brick / Smart Pro handhelds.

The goal is not to diverge. It is to add a small number of **extension seams** to
NextUI so that features can be built without touching upstream code, and to stay
cheap to re-sync with upstream forever. Read
[`docs/fork-strategy.md`](docs/fork-strategy.md) before proposing any change to
an upstream-owned file.

## Rules

@.claude/rules/fork-changes.md
@.claude/rules/shell-scripts.md
@.claude/rules/markdown.md

## The one metric

The fork's maintenance cost is the number of **hunks it leaves in files upstream
keeps editing** — `workspace/all/nextui/nextui.c`, `workspace/all/common/api.c`,
`workspace/all/settings/settings.cpp`, the two makefile lists,
`skeleton/SYSTEM/{tg5040,tg5050,desktop}/`.

Budget: **at most 3 hunks per core edit, zero for anything built on top of one.**
Measure it, do not estimate it:

```sh
scripts/flexui/footprint.sh
```

A change that costs more than its budget means the seam is in the wrong place.
Find a different seam rather than accepting the diff.

## Model

FlexUI is a plain fork: **one long-lived `main`** that merges `nextui/main`. No
topic branches, no generated branch.

```sh
scripts/flexui/setup.sh          # once: upstream remote + 'ours' merge driver
scripts/flexui/sync-upstream.sh  # fetch and merge upstream
scripts/flexui/footprint.sh      # what the fork costs
```

- Keep each fork change in one atomic commit prefixed `flexui:`, so it can be
  cherry-picked onto `nextui/main` for a pull request.
- `README.md` and the install logos are `merge=ours` in `.gitattributes`: the
  fork owns them, upstream edits to them are discarded.

## Repository layout

Two trees, merged into `./build` at build time:

- `skeleton/` — files as they appear on the SD card (`BOOT`, `BASE`, `SYSTEM`,
  `EXTRAS`)
- `workspace/` — the sources: `all/` (shared) plus one directory per platform
  (`tg5040`, `tg5050`, `desktop`)

See [`docs/architecture/`](docs/architecture/index.md) for how the system works,
and upstream's `PAKS.md` / `HOOKS.md` for the extension points.

## Build

Cross-compilation runs in a Docker/Podman container; the root makefile runs on
the host.

```sh
make PLATFORM=tg5040 build      # one platform
make all                        # both platforms + packaging
make PLATFORM=tg5040 shell      # interactive toolchain shell
```

A clean rebase never proves a sync worked. Build before claiming it did.

## Licence

Upstream moved to PolyForm Noncommercial 1.0.0 in `ae652648`. Forking is allowed;
commercial use is not.
