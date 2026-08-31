# Rule — changing NextUI's own code

FlexUI is a plain fork: one long-lived `main` that merges `nextui/main`. There
are no topic branches. Everything below exists to keep upstream merges cheap.

## Budget

The fork's maintenance cost is the number of **hunks it leaves in files upstream
keeps editing** — `workspace/all/nextui/nextui.c`, `workspace/all/common/api.c`,
`workspace/all/settings/settings.cpp`, the two makefile lists,
`skeleton/SYSTEM/{tg5040,tg5050,desktop}/`.

**At most 3 hunks for a change that opens a seam, 0 for anything built on one.**
Measure, do not estimate:

```sh
scripts/flexui/footprint.sh
```

Over budget means the seam is in the wrong place. Find another one rather than
accept the diff.

## Put the substance in new files

A change to NextUI should open an **extension point** — a hook, a dispatch
table, a registry, a compiler-flag injection — and keep its logic in files
upstream will never touch: `workspace/all/flexui/`, `skeleton/FLEXUI/`, a new
script under `skeleton/SYSTEM/*/bin/`.

New files cost nothing to merge. Hunks in `nextui.c` cost something forever.

## One change, one commit

Keep each fork change in a single atomic commit prefixed `flexui:`, with the
smallest possible reach. That is what makes it extractable later:

```sh
git log --oneline --grep='^flexui:' nextui/main..main   # what the fork carries
git cherry-pick <sha>                                   # onto nextui/main, for a PR
```

A commit mixing a seam with a feature built on it cannot be offered upstream.

## Files the fork owns outright

`README.md` and the two `install/logo.png` are marked `merge=ours` in
`.gitattributes`: upstream edits to them are discarded silently, on purpose.

Use that only for **fork identity** — name, logo, branding. For a file where
upstream's content still matters, carry a real diff and pay the conflicts; that
cost is the signal to re-read the change at each sync, which is correct.

## After every upstream merge

A merge that conflicts nowhere still proves nothing:

- run `make PLATFORM=tg5040 build` before calling a sync done;
- check the fork's name did not leak back — upstream adding a *new* user-visible
  "NextUI" string conflicts with nothing.
