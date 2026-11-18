# Parental enforcement

How [rules](rules.md) act on the device: a launch refused, a warning before
the end, an activity stopped, and the events Parental.pak emits on the way.

| Section | Content |
|---|---|
| [Decisions](#decisions) | P4, P5 |
| [Contexts](#contexts) | Every situation Parental.pak reacts to |
| [Warning and stop](#warning-and-stop) | Channels, save-and-quit |
| [Events emitted](#events-emitted) | `parental.*` |
| [Open questions](#open-questions) | Not decided yet |

## Decisions

| # | Question | Decision |
|---|---|---|
| P4 | Budget exhausted | Warning, then save-and-quit |
| P5 | Warning channels | Toast, LED, vibration |

## Contexts

| Context | Hook | Action |
|---|---|---|
| Launch of a counted activity, budget left, inside a window | `pre-launch` | Allow; start counting on `activity-start` |
| Launch with no budget left | `pre-launch` | Veto; `show2.elf` says why |
| Launch outside a time window, clock trusted | `pre-launch` | Veto; `show2.elf` says why |
| Launch outside a time window, clock untrusted | `pre-launch` | Allow: windows are ignored |
| Launch of an uncounted category (`tool`) | `pre-launch` | Always allow |
| Budget or window ends in N min, during an activity | Watcher | Warning, `parental.budget-low` |
| Budget or window ends, during an activity | Watcher | Stop, `parental.budget-exhausted` or `parental.window-closed` |
| Activity ends | `activity-stop` | Stop counting, write the session |
| Extra time granted | `grants.log` | Budget extended; a running warning is cancelled |

The watcher is Parental.pak's background process, checking every 10 s during an
activity, as today.

## Warning and stop

1. Warning, by default 5 min before the end, on every channel available (P5).
2. At the end: save-and-quit through minarch for a game; a plain stop for a pak.

| Channel | Source |
|---|---|
| Toast | Exists |
| LED | Branch `feat/parental-led-warning` |
| Vibration | `PLAT_setRumble` (`workspace/tg5040/platform/platform.c:293`) |

## Events emitted

Under the `parental.` namespace ([hooks](../core/hooks.md#pak-emitted-events)):

| Event | When |
|---|---|
| `parental.budget-low` | At the warning |
| `parental.budget-exhausted` | At the end of the budget |
| `parental.window-closed` | When a time window ends |
| `parental.extra-time-granted` | When extra time is granted, from the web or the device |

## Open questions

| Question | Why it matters |
|---|---|
| Stopping a non-game pak | Paks have no save-and-quit; a plain kill may lose their state |
| Timed-out `pre-launch` hook | Fail-open or fail-closed ([hooks](../core/hooks.md#open-questions)) decides whether a hung Parental.pak can be bypassed |
