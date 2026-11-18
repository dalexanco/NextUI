# Hooks

The public, documented, stable event API that third-party paks, parental
control, the admin server and sync build on. Every other domain depends on it.

| Section | Content |
|---|---|
| [Starting point](#starting-point) | What `pak-hooks.sh` does today |
| [Decisions](#decisions) | H1–H10 |
| [Subscribers](#subscribers) | Who can subscribe, and in what order |
| [Events](#events) | The v1 event list |
| [Execution](#execution) | Sync or background, timeouts, veto, transition screen |
| [Pak-emitted events](#pak-emitted-events) | The `<pak>.<event>` namespace |
| [Versioning](#versioning) | The `api` field |
| [Logging](#logging) | One global log, rotated |
| [Changes from today](#changes-from-today) | What breaks, what moves |
| [Open questions](#open-questions) | Not decided yet |

## Starting point

`skeleton/SYSTEM/tg5040/bin/pak-hooks.sh`, called first by `run_hooks.sh` for
every event:

- a Tools pak subscribes by shipping `boot.sh`, `pre-launch.sh`,
  `post-launch.sh`, `pre-sleep.sh` or `post-resume.sh` next to its `launch.sh`;
- all synchronous, in pak-name order, output discarded;
- only a pak-scoped `pre-launch.sh` can veto, and it runs after
  `gametimectl.elf start`, so a vetoing hook must call `gametimectl.elf stop_all`;
- `.hooks/<event>.d/` user scripts run after, in the background unless named
  `*.sync.sh`, exit code ignored.

## Decisions

| # | Question | Decision |
|---|---|---|
| H1 | How a pak declares subscriptions | The manifest lists the events; one `hook.sh <event>` receives them all |
| H2 | Execution mode | Synchronous for `pre-launch`, `post-launch` and `sleep`, behind a transition screen; background for every other event |
| H3 | Timeout | Declared per pak, capped by the system |
| H4 | Veto | `pre-launch` and `sleep` |
| H5 | Who subscribes | Tools paks and system paks |
| H6 | Pak-emitted events | Yes, namespaced `<pak>.<event>` |
| H7 | Order | Numeric priority from the manifest; system paks first |
| H8 | v1 events | Activity, system and Wi-Fi families, plus `pak-installed` ([manifest](manifest.md)); no sync events in the core |
| H9 | Versioning | Required API version in the manifest; incompatible paks are refused |
| H10 | Logs | One global log, rotated |

## Subscribers

| Kind | Location | Can subscribe |
|---|---|---|
| System pak | `.system/<platform>/paks/` | yes |
| Tools pak | `Tools/<platform>/<Name>.pak/` | yes |
| Emus pak | `Emus/<platform>/` | no |
| User script | `.userdata/<platform>/.hooks/<event>.d/` | no — see [open questions](#open-questions) |

A pak subscribes through its `manifest.toml` ([manifest](manifest.md)). A pak
without one gets a synthesized `legacy` manifest built from its `<event>.sh`
scripts, so today's paks keep working. The fields hooks need:

```toml
name = "parental"        # used as the event namespace, see H6
version = "2.0.0"
api = 1                  # H9

[hooks]
entry = "hook.sh"        # receives the event name as $1
events = ["pre-launch", "activity-start", "activity-stop", "wake"]
priority = 10            # H7, lower runs first
timeout = 3              # H3, seconds, for synchronous events only
```

### Order

1. System paks before Tools paks, whatever their priority.
2. Within each group, ascending `priority`; default `50`.
3. Ties broken by pak name.

## Events

v1 ships 14 core events.

| Family | Event | Mode | Veto | Replaces |
|---|---|---|---|---|
| Activity | `pre-launch` | sync | yes | `pre-launch` |
| Activity | `post-launch` | sync | no | `post-launch` |
| Activity | `activity-start`, `activity-stop` | background | no | — |
| System | `boot` | background | no | `boot` |
| System | `shutdown` | background | no | — |
| System | `sleep` | sync | yes | `pre-sleep` |
| System | `wake` | background | no | `post-resume` |
| System | `charge-start`, `charge-stop` | background | no | — |
| System | `battery-low` | background | no | — |
| Network | `wifi-connected`, `wifi-lost` | background | no | — |
| Paks | `pak-installed` | background | no | — |

Sync is an official pak, not part of the core, and is not installed by default.
Its events (`sync.start`, `sync.done`, `sync.content-received`) follow
[H6](#pak-emitted-events) and are documented in [sync](../sync/sync.md).

## Execution

### Synchronous events

`pre-launch`, `post-launch` and `sleep` run one subscriber at a time, in
[order](#order).

- A transition screen covers the phase and names the pak currently running
  (`show2.elf`). A hang then points at the pak that caused it.
- The screen appears only once the phase lasts longer than a threshold, so that
  a fast hook does not flicker.
- Each hook is killed at its timeout: the pak's `timeout`, capped by the system
  ceiling. BusyBox may lack `timeout`, so the watchdog is a shell `kill` or a small
  C helper.

| Value | Proposed |
|---|---|
| Default timeout | 3 s |
| System ceiling | 10 s |
| Screen threshold | 500 ms |

### Background events

Started in subscriber order without waiting for completion. A background hook
still has the system ceiling as its timeout, so it cannot linger forever.

### Veto

- A subscriber to `pre-launch` or `sleep` vetoes by exiting non-zero. The first
  veto stops the phase; later subscribers do not run.
- The OS calls `gametimectl.elf start` only after `pre-launch` passes. A refused
  launch never counts as a session, and paks no longer call `stop_all`.
- A vetoing pak explains itself with `show2.elf`; the OS displays nothing.

### Error isolation

A hook that crashes, times out or prints garbage never stops the launcher.
Outside a veto, its exit code only reaches the [log](#logging).

## Pak-emitted events

A pak emits events in its own namespace only:

```sh
flexui-emit parental.budget-low      # accepted from the parental pak
flexui-emit sleep                     # refused: core namespace
flexui-emit sync.start                # refused from any pak but sync
```

- The namespace is the manifest's `name`.
- Core events have no dot. A name with a dot always belongs to a pak.
- A pak subscribes to another pak's events with the full name:
  `events = ["parental.extra-time-granted"]`.
- Pak events always run in the background and cannot veto.

## Versioning

- `api` in the manifest is the core API version the pak was written for. v1 is
  `1`.
- At discovery, a pak whose `api` is missing or not supported is skipped and the
  reason is logged. It still launches from the menu.
- Hook environment: `FLEXUI_HOOK_API` holds the running version, so a pak can
  adapt within a major version.

## Logging

One global log, `$LOGS_PATH/hooks.txt`, one line per hook run:

```text
2026-11-17T20:31:04 pre-launch parental 42ms exit=0
2026-11-17T20:31:04 pre-launch timer    3001ms timeout
```

- Rotated by size: past the cap, `hooks.txt` becomes `hooks.1.txt` and the
  previous `hooks.1.txt` is deleted. Two files at most, written by appending only,
  so the SD card sees little wear.
- Proposed cap: 256 KB per file.
- A hook's own stdout and stderr stay discarded; a pak that wants a detailed log
  writes its own, under the same rotation rule.

## Changes from today

| Today | v1 |
|---|---|
| `<event>.sh` next to `launch.sh` | `hooks.entry` script, events in the manifest; `<event>.sh` still read for legacy paks |
| `pre-sleep`, `post-resume` | `sleep`, `wake` |
| All pak hooks synchronous | Synchronous only for `pre-launch`, `post-launch`, `sleep` |
| No timeout | Per-pak timeout, 10 s ceiling |
| Pak-name order | Priority, system paks first |
| Vetoing hook calls `gametimectl.elf stop_all` | The OS starts game time after the veto check |
| Output discarded, no trace | Global rotated log |

This supersedes upstream PR LoveRetro/NextUI#821: the manifest-based model can no
longer be offered upstream as is.

## Open questions

| Question | Why it matters |
|---|---|
| Does the manifest call for a FlexUI pak catalogue? | Pak Store paks keep working as legacy, but only a catalogue would carry manifests to users |
| Keep `.hooks/<event>.d/` user scripts? | H5 drops them; existing user hooks (e.g. Shortcuts resume sync, `HOOKS.md`) would stop running |
| Timed-out veto hook: allow or refuse? | Fail-open lets a hung parental pak be bypassed; fail-closed lets any broken pak block every launch |
| Which sleeps can `sleep` veto? | Low-battery and lid-close sleeps should stay unvetoable |
| Toast API for paks | [Sync](../sync/sync.md) and [parental](../parental/enforcement.md) need to show a message from outside the launcher |
| Timeout, ceiling, threshold and log cap values | The figures above are proposals, unmeasured on the device |
