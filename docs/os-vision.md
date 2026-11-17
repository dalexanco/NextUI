# OS vision — a dedicated TrimUI Brick firmware

Functional framing for turning FlexUI into a firmware for **one device, the TrimUI
Brick (`tg5040`)**, with hooks, parental control and synced folders built in.
Scope: what the OS does, not yet how it is split into modules.

| Section | Content |
|---|---|
| [Decisions](#decisions) | The choices already made |
| [Core concepts](#core-concepts) | Activity, pak manifest, parental as a pak |
| [Hooks](#hooks) | The public event API |
| [Parental control](#parental-control) | Rules, admin channels, threat model |
| [Admin web server](#admin-web-server) | Cost on the device |
| [Synced folders](#synced-folders) | Client sync against a NAS |
| [Reuse from nextui-samba-sync](#reuse-from-nextui-samba-sync) | What carries over |
| [Licence](#licence) | Terms and dependencies |
| [Open questions](#open-questions) | Not decided yet |

## Decisions

| Axis | Decision |
|---|---|
| Relation to NextUI | **Assumed divergence.** Brick only; the code is ours. This supersedes the "stay close to upstream" goal of [fork-strategy.md](fork-strategy.md) for this OS. |
| Users | One child, one parent acting as admin |
| Admin | On the device (emergencies, "+15 min") **and** from the parent's phone (rules, reports) |
| Parental security | Deterrent: PIN and unobvious config. No signing, no encryption. |
| Parental storage | **Outside synced folders.** Rules, counters and remote control never travel through sync. |
| Sync model | The Brick is a **client** of a master folder on a NAS or PC (SMB, later WebDAV) |
| Sync triggers | While charging, and on demand |
| Sync conflicts | Policy chosen **per folder** |
| Hooks | Public, documented, stable API for third-party paks |
| Licence | Same as upstream: PolyForm Noncommercial 1.0.0 |

## Core concepts

### Activity, not game

Anything the child spends time on is an **activity**: a game, a podcast, a video,
an audiobook. Budgets, time windows and reports apply to activities, grouped by
**category** (`game`, `media`, `education`, …), so a rule can read "1 h of games,
audiobooks unlimited".

### Pak manifest

One declaration per pak, the contract of the public API. It states:

- the events the pak subscribes to;
- its synced folders, each with its conflict policy;
- its activity category.

The admin can override any entry and add folders of their own. Third-party apps
declare their synced folders the same way the OS does.

### Parental control is a pak

It has no privileged path. It subscribes to `pre-launch` (veto), activity events
and `wake`, and emits its own events for other paks to react to.

## Hooks

Exposed from the first version:

| Family | Events |
|---|---|
| Activity lifecycle | `pre-launch` (can veto), `post-launch`, `activity-start`, `activity-stop` — for games and apps alike |
| System | `boot`, `shutdown`, `sleep`, `wake`, `charge-start`, `charge-stop`, `battery-low` |
| Network and sync | `wifi-connected`, `wifi-lost`, `sync-start`, `sync-done`, `content-received` |
| Parental | `budget-low`, `budget-exhausted`, `window-closed`, `extra-time-granted` |

Requirements of a public API: a documented event list, error isolation (a failing
hook never takes the launcher down), a per-hook timeout.

Starting point: `pak-hooks.sh` on branch `chore/hooks-launch`, offered upstream as
LoveRetro/NextUI#821 — pak-scoped hooks around a launch, with a pre-launch veto.

## Parental control

Starting point: `Parental.pak` (`workspace/all/parental/parental.c`, 1 136 lines) —
daily budget, PIN-locked admin menu, per-emulator exemptions, warning toast then
save-and-quit through minarch's `SIGUSR2` / `SIGUSR1`.

Rules to add:

| Rule | Behaviour |
|---|---|
| Time windows | No play outside allowed hours; weekday, weekend and holiday profiles |
| Activity reports | Which activity, how long, when — readable by the parent |
| Extra time request | The child asks "+15 min" on the device; the parent accepts or refuses from the phone |
| Wider activity scope | Budgets cover apps (podcast, video player), not only emulators |

### Threat model

The SD card is removable and readable on any PC. The target is a deterrent, enough
for a young child. A child editing files from a computer is out of scope.

## Admin web server

Remote admin goes through a small HTTP server on the Brick, since parental data
stays out of synced folders.

| Item | Cost | Why |
|---|---|---|
| Idle CPU | ≈ 0 | A C server (BusyBox `httpd`, mongoose, civetweb) blocks on `accept`; no wake-ups without a client |
| CPU per request | a few ms | Small JSON read/write, a page of a few KB |
| RAM | 1–2 MB of 1 GB | Python or Node would cost 15–50 MB; excluded |
| Disk | a few hundred KB | Static binary with an embedded page |
| **Wi-Fi kept associated** | **dominant, unmeasured** | Reachability requires the radio on, even during offline play |

Consequences:

- **Unreachable while asleep.** Acceptable: an extra time request happens while
  the child is playing, so the device is awake.
- **No easy HTTPS on a LAN**: the PIN crosses the home Wi-Fi in clear. Acceptable
  under the deterrent threat model.
- Fallback if the radio cost is too high: run the server only on `charge-start` or
  on demand.

To measure before deciding: battery current from `/sys/class/power_supply/`, Wi-Fi
off then associated and idle, 10 minutes each.

## Synced folders

The Brick pulls from, and pushes to, a master folder on a NAS. Content can be
dropped there at any time; the Brick catches up while charging or on demand.

| Content | Typical policy |
|---|---|
| Games (ROMs, `.media` box art) | NAS is master |
| Saves and save states | Device is master; backed up to the NAS, restorable after a reinstall |
| Media (podcasts, video, music, audiobooks) | NAS is master |
| Third-party pak folders | Declared in the pak manifest |

Conflict policies, set per folder: **NAS master**, **device master**, **keep both
copies**. "Newest wins" is excluded: the Brick has no reliable clock without NTP.

## Reuse from nextui-samba-sync

[dalexanco/nextui-samba-sync](https://github.com/dalexanco/nextui-samba-sync):
~2 250 lines of C, libsmb2, tomlc17. Pull only, add/mirror modes, already running
on a Brick against a real share.

| Keep | Evolve |
|---|---|
| `smb_client.c` — libsmb2, already cross-compiled for `tg5040` | Pull only → two-way with a per-folder conflict policy |
| `sync_engine.c` add/mirror, and "no deletion if any file failed" | Name + size comparison → mtime or hash, required for saves |
| `sync_queue.c`, `link_state.c` | Blocking check → worker thread, for background sync while charging |
| TOML parser, the "link" concept | One `Samba Sync.toml` → pak manifests plus admin overrides |
| | 4 096-file limit per side → lifted for media libraries |

## Licence

- PolyForm Noncommercial 1.0.0, as upstream (`ae652648`). It is **source-available,
  not OSI open source**: say so in the README.
- libsmb2 is LGPL-2.1 and statically linked: keep the source public so users can
  relink, and credit it. tomlc17 is MIT.

## Open questions

| Question | Why it matters |
|---|---|
| Express sync for parental requests? | Moot if requests go through the web server only; confirm |
| NTP on wake | Time windows and reports need a trustworthy clock |
| Phone UI: Brick-served page only, or also something on the NAS? | Defines the "both" admin channel |
| Save restore flow after a reinstall | Needs an explicit, confirmed path |
| Wi-Fi idle cost on the Brick | Decides whether the admin server runs always or on demand |
