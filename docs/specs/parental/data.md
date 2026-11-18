# Parental data

The `parental/` folder: rules, today's counters, activity history, battery and
Wi-Fi samples, paired phones. Who writes each file, so that Parental.pak and the
[admin server](../admin/server.md) never write the same one.

| Section | Content |
|---|---|
| [Decisions](#decisions) | P10, P11 |
| [Files](#files) | Content and writer of each file |
| [Formats](#formats) | `rules.toml`, `activity.log` |
| [Recording](#recording) | Battery and Wi-Fi samples behind the stats |
| [Retention](#retention) | 30 days, pruned once a day |
| [Open questions](#open-questions) | Not decided yet |

## Decisions

| # | Question | Decision |
|---|---|---|
| P10 | History | Per session, 30 days |
| P11 | Storage | A `parental/` folder: `rules.toml` plus an append-only activity log |

## Files

`SHARED_USERDATA_PATH/parental/`, outside every synced folder:

| File | Content | Written by |
|---|---|---|
| `rules.toml` | Profiles, windows, budgets, caps, holidays, day start, category overrides ([manifest](../core/manifest.md#admin-overrides)) | Admin server, Parental.pak menu |
| `grants.log` | Extra time granted, one line per grant | Admin server, Parental.pak menu (append) |
| `today.toml` | Budget day, minutes used per category, extra time applied | Parental.pak only, at most once a minute |
| `activity.log` | One line per session | Parental.pak, on `activity-stop` |
| `stats.log` | Battery, Wi-Fi, charge and sleep samples | Parental.pak, see [recording](#recording) |
| `phones.toml` | Paired phones ([pairing](../admin/pairing.md)) | Parental.pak pairing screen |

Parental.pak folds `grants.log` into `today.toml`, so the admin server never
touches the counters.

## Formats

```toml
# rules.toml
day_start = "04:00"
counted = ["game", "media", "education", "other"]

[profiles.weekday]
windows = [["16:30", "19:00"]]
budget = 60
caps = { game = 45 }

[profiles.weekend]
windows = [["09:00", "12:00"], ["14:00", "19:00"]]
budget = 120

[[holidays]]
from = "2026-12-19"
to = "2027-01-04"
```

```text
# activity.log: start, end, minutes, category, pak or ROM, clock trust
2026-11-18T16:42 2026-11-18T17:20 38 game "Zelda - Minish Cap" trusted
```

## Recording

The [stats screen](../admin/interface.md#stats-screen) needs data recorded while
the admin server is off, during activities. Parental.pak records it: it already
subscribes to the activity events and owns `parental/`.

| Data | Source | Frequency |
|---|---|---|
| Battery % | `/sys/class/power_supply/` | Every 60 s while awake, plus on each event below |
| Activity start / stop | `activity-start`, `activity-stop` | Per event |
| Wi-Fi online / offline | `wifi-connected`, `wifi-lost` | Per event |
| Charging | `charge-start`, `charge-stop` | Per event |
| Sleep / wake | `sleep`, `wake` | Per event |

- Samples are buffered in `/tmp` and appended to `stats.log` on `activity-stop`,
  `sleep` and `shutdown`. This keeps SD card writes rare.
- A 60 s battery sample is about 10 bytes; a full day is under 15 KB.

## Retention

- `activity.log` and `stats.log` are pruned to 30 days at each budget day
  rollover: rewritten to a temporary file, then renamed. One rewrite a day.
- `parental.txt` is converted on first start, then removed.

## Open questions

| Question | Why it matters |
|---|---|
| Battery sampling while asleep | The chart shows sleep as a gap; a sample on `wake` gives the drain overnight |
