# Parental rules

What the parent sets and how it is counted: activities, a global budget with
optional category caps, time windows by profile, extra time, the budget day.
Builds on [hooks](../core/hooks.md), [manifest](../core/manifest.md) and
[clock](../core/clock.md). How rules are enforced is in
[enforcement](enforcement.md); where they are stored, in [data](data.md).

| Section | Content |
|---|---|
| [Starting point](#starting-point) | What `Parental.pak` does today |
| [Decisions](#decisions) | P1–P12 and the budget day |
| [Activities](#activities) | What counts, and how it is detected |
| [Budgets](#budgets) | Global, category caps, extra time |
| [Time windows](#time-windows) | Profiles and holidays |
| [Budget day](#budget-day) | When the daily counter resets |
| [Open questions](#open-questions) | Not decided yet |

## Starting point

`workspace/all/parental/parental.c`, 1 136 lines:

- daily budget, 90 min by default, warning 5 min before;
- admin menu locked by a 2–8 button code;
- per-emulator exemptions, 512 at most;
- warning toast, then save-and-quit through minarch's `SIGUSR2` / `SIGUSR1`
  (`workspace/all/flexui/minarch_control.h`), checked every 10 s;
- config in `SHARED_USERDATA_PATH/parental.txt`.

## Decisions

| # | Question | Decision |
|---|---|---|
| P1 | Window profiles | Weekday, weekend, holidays |
| P2 | Holiday activation | Start and end dates entered by the admin |
| P3 | Budgets | One global budget, plus an **optional** cap per category |
| P6 | Extra time | +15, +30, +60 min shortcuts, or an exact value |
| P7 | Scope of a grant | Today only, lost at the end of the budget day |
| P8 | Planning exceptional days | Not a parental control concern: the admin cannot be reached while the child plays |
| P9 | Detecting activities | The OS emits `activity-start` / `activity-stop` around every pak launch |
| P12 | Web PIN | None: the phone is paired instead ([admin pairing](../admin/pairing.md)) |
| T5 | Start of the budget day | Set by the admin |

P4 and P5 are in [enforcement](enforcement.md), P10 and P11 in [data](data.md).

## Activities

- The OS emits `activity-start` before, and `activity-stop` after, every launch:
  ROMs and paks alike (P9). Parental.pak subscribes; no pak has to cooperate.
- An activity's category comes from the [manifest](../core/manifest.md): admin
  override, then the pak's manifest, then the category hints, then `other`. A ROM
  is `game`.
- What counts towards the budget is set per category by the admin. Default:
  `game`, `media`, `education` and `other` count, `tool` does not, so Settings or
  Parental.pak itself never spend the budget.
- The current per-emulator exemptions become category overrides on those
  systems.

## Budgets

| Rule | Behaviour |
|---|---|
| Global budget | Minutes per day, per profile |
| Category cap | Optional, per profile. A category stops at its cap even if the global budget has time left |
| Extra time | Added to today's global budget (P6). Lost at the end of the budget day (P7) |

Extra time is granted from the admin web or on the device with the PIN:
shortcuts +15, +30 and +60 min, or an exact number of minutes.

## Time windows

| Profile | Applies |
|---|---|
| Holidays | On a date inside an admin-entered holiday period (P2) |
| Weekend | Saturday and Sunday, outside holidays |
| Weekday | Every other day |

- Each profile has its allowed hours and its budgets.
- A launch outside the allowed hours is vetoed ([enforcement](enforcement.md)).
  Categories that do not count towards the budget are never vetoed, so Settings
  and Parental.pak stay reachable.
- A window that closes during an activity ends it like an exhausted budget.
- Untrusted clock ([clock](../core/clock.md#trusted-time)): time windows are
  ignored, budgets still apply.

## Budget day

The daily budget resets at the admin-set start of the day (T5), local time.
Proposed default: 00:00.

The clock can be wrong, trusted or not (T3), so the reset follows one rule:

- the counter resets when the current budget day is **later** than the one
  stored in `parental/today.toml` ([data](data.md));
- a clock that moves backwards, such as a reset to 1970 at boot, never resets the
  counter.

A child setting the date forward gets a fresh budget. This is accepted under the
[threat model](../../SPEC.md#threat-model).

## Open questions

| Question | Why it matters |
|---|---|
| Exceptional days | P8 rules them out, while the admin interface (W6) lists a calendar of exceptional days. Drop the calendar, or keep it as one-day holiday periods? |
| Extra time and category caps | Does +15 min lift a reached category cap, or only the global budget? |
