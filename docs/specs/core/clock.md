# Clock

A clock trustworthy enough to enforce time windows and date activity history,
and a clear signal when it is not. How the budget day uses it is in
[parental rules](../parental/rules.md#budget-day).

| Section | Content |
|---|---|
| [Decisions](#decisions) | T1–T5 |
| [How NTP works here](#how-ntp-works-here) | What a sync needs |
| [Trusted time](#trusted-time) | When the clock counts as reliable |
| [Lifecycle](#lifecycle) | Events and actions |
| [Open questions](#open-questions) | Not decided yet |

## Decisions

| # | Question | Decision |
|---|---|---|
| T1 | Time sources | NTP on every `wifi-connected` and `wake` |
| T2 | Untrusted time | Enforce the budget, ignore time windows |
| T3 | Child changes the time in Settings | Ignored: outside the threat model |
| T4 | Time zone | The one set in Settings |
| T5 | Start of the budget day | Set by the admin ([parental rules](../parental/rules.md#budget-day)) |

## How NTP works here

- NTP asks a time server over UDP port 123. The servers are public, on the
  Internet (`pool.ntp.org` and similar), so a sync needs **Internet access**, not
  just an associated Wi-Fi. A home network without Internet gives no time.
- Home routers rarely serve NTP, and the Brick's client does not discover one.
  The OS relies on public servers only.
- The Brick's stock firmware ships an `ntpd` driven by UCI. NextUI toggles it from
  Settings ("Set time and date automatically",
  `workspace/tg5040/platform/platform.c:812`).

A FlexUI system pak, `clock`, runs a one-shot sync on the events of T1,
independently of the Settings toggle: `ntpd -q -n -p <server>`, bounded by a
timeout, in the background.

## Trusted time

| State | Meaning | Parental behaviour |
|---|---|---|
| trusted | An NTP sync succeeded since the last boot | Budget and time windows enforced |
| untrusted | No successful sync since boot | Budget enforced, time windows ignored |

- Trust survives sleep: the clock keeps running while asleep, so `wake` without
  Internet stays trusted.
- Trust is lost only at boot, since the clock may have been reset.
- Changing the time in Settings does not affect trust (T3).
- The state is kept in `/tmp`, so a reboot clears it.
- Local time uses the Settings time zone (T4). An NTP sync sets UTC only; the
  zone is applied on display and on rule evaluation.

Consequence of T2: without Internet, time windows never apply. On a trip with no
Internet access, the budget is the only limit.

## Lifecycle

| Event | Action |
|---|---|
| `boot` | Mark untrusted |
| `wifi-connected` | One-shot NTP sync; trusted on success |
| `wake` | One-shot NTP sync if Wi-Fi is associated; trusted on success |

On success, the pak emits `clock.synced` ([hooks](hooks.md#pak-emitted-events)),
so parental control can re-evaluate time windows at once.

## Open questions

| Question | Why it matters |
|---|---|
| Does the Brick keep time while powered off? | Without a battery-backed RTC, every cold boot starts at a fixed date, and the [budget day](../parental/rules.md#budget-day) rule matters on every boot |
| Server list | The stock `ntpd` servers are unverified; FlexUI may set its own pool |
| Settings toggle "Set time and date automatically" | The FlexUI sync ignores it; hide the toggle, or let it disable FlexUI's sync too |
| Sync timeout | A one-shot sync with no Internet must give up fast; proposed 5 s |
