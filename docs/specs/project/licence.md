# Licence and README

What the firmware says about itself: its name, its relation to NextUI, its
licence, the credits it owes, and what the move to a divergent firmware removed.

| Section | Content |
|---|---|
| [Decisions](#decisions) | L1–L6 |
| [Docs rewrite](#docs-rewrite) | What changes for the divergent OS |
| [README](#readme) | Name, relation to NextUI, licence |
| [NOTICE](#notice) | Credits, in the repo and on the SD card |
| [Dependencies](#dependencies) | libsmb2, tomlc17, civetweb |
| [Open questions](#open-questions) | Not decided yet |

## Decisions

| # | Question | Decision |
|---|---|---|
| L1 | Docs and divergence | Rewrite the docs for the divergent OS; upstream is no longer merged |
| L2 | Name | Keep FlexUI |
| L3 | Relation to NextUI | "Based on NextUI", with a link |
| L4 | libsmb2 sources | The public repository is enough: sources and makefile |
| L5 | Where credits go | README, plus a `NOTICE` file in the repo and on the SD card |
| L6 | Third-party pak licences | Free choice; nothing imposed |

## Docs rewrite

Upstream is no longer merged. What that removes:

| Removed | Was |
|---|---|
| `docs/fork-strategy.md` | Seams, hunk budget, five core edits |
| `docs/os-vision.md` | Initial framing, now split between [SPEC.md](../../SPEC.md) and the specs |
| `.claude/rules/fork-changes.md` | 3-hunk budget per core edit |
| `.claude/skills/upstream-sync` | Merge `nextui/main` |
| `scripts/flexui/` | Upstream setup, merge, footprint measurement |
| `.gitattributes` | `merge=ours` for README and install logos |

`CLAUDE.md` now points to `docs/SPEC.md` and the specs. An upstream fix is taken
by hand with `git cherry-pick`.

## README

- **Name**: FlexUI (L2).
- **Relation**: "Based on [NextUI](https://github.com/LoveRetro/NextUI)" (L3). The
  claims "tracks NextUI closely" and "not a competitor, a small set of changes"
  are removed.
- **Device**: TrimUI Brick only. The Smart Pro mention goes.
- **Licence**: PolyForm Noncommercial 1.0.0, inherited from upstream
  (`ae652648`), stated as **source-available, not open source in the OSI
  sense**.
- **Credits**: a short section pointing to `NOTICE` (L5).
- **Third-party paks**: any licence their authors choose (L6); the README says
  so where it documents the hook API.

## NOTICE

`NOTICE` already exists: upstream's credits to MinUI and the NextUI team. FlexUI
appends its own section and never edits upstream's.

| Location | File |
|---|---|
| Repository | `NOTICE` |
| SD card | `skeleton/BASE/NOTICE.txt`, next to the existing `README.txt` |

FlexUI's section lists:

- "Based on NextUI", with the link;
- each third-party library compiled into a FlexUI binary, with its licence and
  source URL.

## Dependencies

| Library | Licence | Used by | Where it ships | Obligation |
|---|---|---|---|---|
| tomlc17 | MIT | `flexui-manifest` ([manifest](../core/manifest.md)) | FlexUI | Credit in `NOTICE` |
| civetweb | MIT | `flexui-admin` ([admin](../admin/server.md)) | FlexUI | Credit in `NOTICE` |
| libsmb2 | LGPL-2.1 | Sync pak ([sync](../sync/sync.md)) | Sync pak repo | Public sources and makefile so users can relink (L4); credit in that pak |

The sync pak lives in its own repository, so libsmb2 is not linked into
FlexUI. Its LGPL obligations, including the public sources of L4, are that
repository's.

## Open questions

| Question | Why it matters |
|---|---|
| Seams offered upstream | LoveRetro/NextUI#821 was built for upstream; does FlexUI still offer generic seams as PRs? |
