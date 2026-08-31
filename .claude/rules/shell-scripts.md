# Rule — shell scripts (`*.sh`)

## Language

Comments, messages and identifiers are **English**. This is true of maintenance
scripts and of anything shipped on the device.

## Portability

Scripts run in one of two environments. Know which one you are writing for, and
target the smaller of the two when unsure.

| Where | Interpreter | Constraints |
|---|---|---|
| **Maintainer machine** (`scripts/`) | macOS or Linux | macOS ships bash 3.2 and a BSD userland |
| **Device** (`skeleton/SYSTEM/**`) | BusyBox `ash` | POSIX only, no bashisms at all |

Default to `#!/bin/sh` and POSIX syntax everywhere. It costs almost nothing and
removes the whole question.

## Do not use

These work on Linux and fail (or behave differently) on macOS or BusyBox:

| Avoid | Use instead |
|---|---|
| `[[ ... ]]`, arrays, `local` in `sh` | `[ ... ]`, positional args, plain variables |
| `sed -i` | `sed ... > tmp && mv tmp file` (the `-i` argument differs on BSD) |
| `readlink -f`, `realpath` | `cd "$(dirname "$0")" && pwd` |
| `grep -P` | `grep -E` |
| `echo -e`, `echo -n` | `printf` |
| `mktemp -p`, `mktemp --suffix` | `mktemp` with no options |
| `date -d`, `date --iso-8601` | `date +%Y-%m-%d`, or compute in C |
| `seq`, `realpath`, `timeout` | shell loops; check availability first |
| GNU-only `find -printf` | `find ... -exec` |

## Always

- `set -e` in maintenance scripts. Device scripts often want the opposite: a
  failing hook must not take the launcher down with it.
- Quote every expansion: `"$VAR"`, `"$@"`. Paths on the SD card contain spaces
  (`Tools/tg5040/Game Tracker.pak`).
- `: "${VAR:=default}"` for defaults, so callers can override from the
  environment.
- Redirect device-script output to a log file. Hook stdout/stderr is discarded,
  so a script that only prints is a script that says nothing.
- Keep device hooks fast. They sit between the user and their game.

## Verify

```sh
shellcheck -s sh scripts/flexui/*.sh
```
