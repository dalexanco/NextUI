# Sync

The Brick as a client of a master folder on a NAS, over SMB, with a conflict
policy per folder. It ships as an **official pak from its own repository**,
not part of the OS and not installed by default: the OS works without any NAS.
Builds on [hooks](../core/hooks.md) and [manifest](../core/manifest.md).

| Section | Content |
|---|---|
| [Decisions](#decisions) | S1–S11 |
| [Packaging](#packaging) | Separate repo, what the OS provides |
| [Links and policies](#links-and-policies) | What a synced folder is |
| [Change detection](#change-detection) | Size and hash, state file |
| [Conflicts and deletions](#conflicts-and-deletions) | `_conflicts/`, mirror mode |
| [Triggers and lifecycle](#triggers-and-lifecycle) | Charge, on demand, sleep |
| [Credentials](#credentials) | Device first, admin web optional |
| [Open questions](#open-questions) | Not decided yet |

## Decisions

| # | Question | Decision |
|---|---|---|
| S1 | Where the code lives | Separate repo, distributed as a pak |
| S2 | Protocols | SMB only |
| S3 | Change detection | Size plus hash; mtime ignored |
| S4 | Sync state | One state file per synced folder, on the console |
| S5 | Undeclared folder | Not synced |
| S6 | "Keep both" conflicts | Copy into `_conflicts/` at the link root |
| S7 | Deletions | Mirror mode only, on the slave side |
| S8 | Triggers | `charge-start`, and on demand from the pak |
| S9 | Saves on the NAS | Plain copy, overwritten at each sync |
| S10 | User feedback | Toast when a sync ends |
| S11 | NAS credentials | Entered on the device, or through the admin web; stored outside synced folders |

## Packaging

[dalexanco/nextui-samba-sync](https://github.com/dalexanco/nextui-samba-sync)
evolves into the sync pak. It keeps its own repository, release cycle and
licence obligations: libsmb2 (LGPL-2.1) stays out of the FlexUI tree.

### Reuse

nextui-samba-sync today: ~2 250 lines of C, libsmb2, tomlc17. Pull only,
`add` / `mirror` modes, already running on a Brick against a real share.

| Keep | Evolve |
|---|---|
| `smb_client.c` — libsmb2, already cross-compiled for `tg5040` | Pull only → per-folder policies, both ways |
| `sync_engine.c` add/mirror, and "no deletion if any file failed" | Name + size comparison → size + hash and a state file |
| `sync_queue.c`, `link_state.c` | Blocking check → worker thread, for background sync while charging |
| TOML parser, the "link" concept | `Samba Sync.toml` stays the pak's own config, with one entry per link |
| | 4 096-file limit per side → lifted for media libraries |

### Public API used

The pak uses only the public API:

| From the OS | Used for |
|---|---|
| `manifest.toml` ([manifest](../core/manifest.md)) | `name = "sync"`, hooks, category `tool` |
| Core events ([hooks](../core/hooks.md#events)) | `charge-start`, `charge-stop`, `sleep`, `wifi-lost` |
| Own namespace (H6) | Emits `sync.start`, `sync.done`, `sync.content-received` |
| Toast (see [open questions](#open-questions)) | End-of-sync message |

## Links and policies

A **link** pairs a folder on the SD card with a folder on a share. Links are
declared in the sync pak's own config; nothing is synced unless a link names it
(S5). Synced folders are not part of the core manifest.

| Policy | Direction | Mode `add` | Mode `mirror` |
|---|---|---|---|
| NAS master | NAS → device | Copy new and changed files | Also delete on the device what the NAS no longer has |
| Device master | device → NAS | Copy new and changed files | Also delete on the NAS what the device no longer has |
| Keep both | both ways | Copy both ways; conflicts go to `_conflicts/` | Not allowed: keep both never deletes |

Saves use **device master**, `add` mode: a plain copy on the NAS, overwritten at
each sync (S9). No history is kept.

## Change detection

Each link has a state file on the console, outside synced folders, recording
per file the size and hash seen at the last successful sync (S4).

| Side | Changed when |
|---|---|
| Device | Size differs from the state, or, at equal size, the hash differs |
| NAS | Size differs from the state — see [open questions](#open-questions) |

- mtime is ignored (S3): the Brick's clock is not trustworthy ([clock](../core/clock.md)).
- Hashing only runs on equal sizes, so a changed ROM of a new size costs no read.
- The existing rule stays: if any file of a link fails, no deletion runs for
  that link in that pass.

## Conflicts and deletions

- A conflict exists only under **keep both**: the file changed on both sides
  since the last sync.
- The NAS version stays in place. The device version is copied to
  `<link root>/_conflicts/<relative path>` on both sides, so the game list
  stays clean (S6).
- Deletions propagate only in `mirror` mode, from master to slave (S7).

## Triggers and lifecycle

| Trigger | Action |
|---|---|
| `charge-start` | Start a sync in the background, if Wi-Fi is associated |
| "Sync now" in the pak's own menu | Start a sync, with progress shown |
| `charge-stop`, `wifi-lost` | Finish the current file, save state, stop |
| `sleep` | Veto while a file is being written, then let the next sleep through |
| End of a sync | Toast: "Sync done: 12 files received" or the error |

- On demand means from the sync pak itself: under H6, another pak cannot emit
  in the `sync.` namespace.
- No NAS configured: the pak does nothing on `charge-start`.

## Credentials

Stored in the sync pak's config under `.userdata/`, outside synced folders, in
clear text: acceptable under the deterrent threat model.

| Channel | Role |
|---|---|
| Device, in the sync pak's menu | Always available: host, share, user, password with the on-screen keyboard |
| Admin web ([admin](../admin/interface.md)) | Optional convenience for typing; the pak works without it |

## Open questions

| Question | Why it matters |
|---|---|
| Hash of a NAS file | SMB gives no server-side hash: hashing a NAS file means downloading it. Proposal: on the NAS side, compare size plus the NAS's own mtime against the state file, used as an opaque marker, never compared with the Brick's clock |
| Toast from a pak | [Hooks](../core/hooks.md#open-questions) have no notification API yet |
| Admin web pages for paks | Typing credentials in the admin web means the admin server serves a page owned by a third-party pak: a new extension point |
| Sync during an activity | Charging while playing would sync during the game, against the "an activity never pays" principle ([SPEC](../../SPEC.md#principles)) |
| `sleep` veto bounds | Needs the [hooks](../core/hooks.md#open-questions) question on which sleeps can be vetoed |
