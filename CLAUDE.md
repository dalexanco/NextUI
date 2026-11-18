# FlexUI

A firmware for **one device, the TrimUI Brick (`tg5040`)**, based on
[LoveRetro/NextUI](https://github.com/LoveRetro/NextUI). FlexUI diverges on
purpose: upstream is no longer merged, and the code is ours to change.

Its features are paks on a public hook API: parental control, clock, an admin
page served by the console, an optional NAS sync. Read
[`docs/SPEC.md`](docs/SPEC.md) before designing a change, and the lot spec in
[`docs/specs/`](docs/specs/index.md) it touches.

## Rules

@.claude/rules/shell-scripts.md
@.claude/rules/markdown.md

## Building on the specs

- A feature is a pak on the public API (hooks, manifest), not a special case in
  the launcher. A change to the launcher or the API itself updates the matching
  spec in the same commit.
- Fork-built binaries are modules registered in `workspace/all/flexui/makefile`.
- A decision that contradicts a spec is made in the spec first.

## Git

**One long-lived `main`.** Commits are prefixed `flexui:` and atomic.

"Pull" means **pull from the fork**, `mine` (`dalexanco/NextUI`), never `origin`.
Here `origin` and `nextui` both point to upstream LoveRetro/NextUI, which is not
merged any more; an upstream fix is taken by hand with `git cherry-pick`.

```sh
git fetch https://github.com/dalexanco/NextUI.git <branch>:refs/remotes/mine/<branch>
git merge --ff-only mine/<branch>   # or reset --hard if the fork rebased it, after `git cherry` shows no local-only commit
```

SSH to `mine` can fail (no key loaded); fetch over HTTPS, as above.

## Repository layout

Two trees, merged into `./build` at build time:

- `skeleton/` — files as they appear on the SD card (`BOOT`, `BASE`, `SYSTEM`,
  `EXTRAS`)
- `workspace/` — the sources: `all/` (shared) plus one directory per platform

See [`docs/architecture/`](docs/architecture/index.md) for how the NextUI base
works, and upstream's `PAKS.md` / `HOOKS.md` for its extension points.

## Build

Cross-compilation runs in a Docker/Podman container; the root makefile runs on
the host.

```sh
make PLATFORM=tg5040 build      # the Brick
make PLATFORM=tg5040 shell      # interactive toolchain shell
```

Build before claiming a change works.

## Test without the device

`test/sim/sim.sh` builds the desktop platform in a container and runs it on a
virtual screen: keys in, screenshots out, simulated battery and Wi-Fi, hook
events on demand. See the `sim` skill (`.claude/skills/sim/SKILL.md`) for the
commands and what only the Brick can show.

## Licence

PolyForm Noncommercial 1.0.0, inherited from upstream (`ae652648`):
source-available, not OSI open source. Commercial use is not allowed.
