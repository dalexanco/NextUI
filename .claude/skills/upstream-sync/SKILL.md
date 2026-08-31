---
name: upstream-sync
description: Sync the FlexUI fork with upstream NextUI - fetch LoveRetro/NextUI, merge it into main, resolve the conflicts, and verify the result. Use when asked to update the fork, pull in upstream changes, or merge upstream.
---

# Syncing FlexUI with upstream NextUI

## Model

FlexUI is a plain fork: one long-lived `main` that merges `nextui/main`. A merge
resolves each conflict once, against the merge base, instead of replaying it at
every sync.

## Procedure

### 1. Look before merging

```sh
git fetch nextui
scripts/flexui/footprint.sh
```

`footprint.sh` lists the upstream files the fork changes and what each costs in
hunks. Those files are the only places a conflict can come from. If upstream
touched none of them, the merge is free.

### 2. Merge

```sh
scripts/flexui/sync-upstream.sh
```

### 3. Resolve conflicts

| Situation | Action |
|---|---|
| Upstream moved code around our hunk | reapply the change at its new location |
| Upstream rewrote the function we hook into | rework the seam |
| Upstream implemented the change itself | drop ours — the debt goes down |
| `README.md` or an install logo conflicts | should not happen; `git config merge.ours.driver true` is missing, run `scripts/flexui/setup.sh` |

Resolve in favour of upstream's structure wherever possible: the smaller the
fork's diff, the cheaper the next sync.

### 4. Check the branding did not leak back

Upstream adding a *new* user-visible mention of NextUI conflicts with nothing, so
a perfectly clean merge can still put the name back on screen.

```sh
git grep -n -i nextui -- workspace/all/settings workspace/all/nextui \
  'workspace/*/install/boot.sh' makefile .github/workflows/release.yaml
```

Expected hits are only the ones the fork knowingly leaves alone: internal
identifiers (`NextUISettings`, `nextui.elf`, `/tmp/nextui_exec`), the `nextui.c`
log line, and the vendored pak URLs in the makefile. Anything new reaching the
launcher, Settings or the install splash needs renaming.

The fork also deliberately does not rebrand the Bluetooth pairing name, the HTTP
user agent, or the SD card `README.txt` files.

### 5. Build before claiming success

A clean merge proves nothing — upstream may have renamed a symbol or moved a
file under `skeleton/`.

```sh
make PLATFORM=tg5040 build
```

Report the sync as done only after this passes. If it cannot be run, say so
explicitly rather than implying the sync is verified.

## Do not

- Do not merge upstream with `-X ours` or `-X theirs` wholesale; resolve per
  file.
- Do not let a fix to a fork change land in the same commit as unrelated work —
  atomic `flexui:` commits are what make a change cherry-pickable upstream.
- Do not `git push --force`; use `--force-with-lease`.
