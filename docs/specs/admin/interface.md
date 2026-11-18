# Admin interface

What the parent sees on the phone: screens, the stats chart, and the JSON API
behind them. Served by the [admin server](server.md), after
[pairing](pairing.md).

| Section | Content |
|---|---|
| [Decisions](#decisions) | W6 |
| [Screens](#screens) | What the v1 page does |
| [Stats screen](#stats-screen) | Battery and activities on one chart |
| [API](#api) | Endpoints |

## Decisions

| # | Question | Decision |
|---|---|---|
| W6 | v1 features | Extra time, activity history, time windows and budgets, exceptional days (pending, see [rules](../parental/rules.md#open-questions)), battery and Wi-Fi history |

## Screens

| Screen | Content |
|---|---|
| Today | Budget used and left, extra time granted today, next time window |
| Extra time | +15, +30, +60 min shortcuts, or an exact value; today only ([rules](../parental/rules.md#budgets)) |
| History | Sessions per day: activity, category, duration |
| Stats | [Battery and activities on one chart](#stats-screen) |
| Rules | Time windows and budgets per profile |
| Calendar | Holiday periods ([rules](../parental/rules.md#time-windows)) |

"Today" reflects the console at the moment the page loads; it is not a live
view, and it does not refresh in the background.

## Stats screen

One time-based chart per day, with a session selector:

```text
100% ┤╲___                     ╱‾‾‾‾  battery %
     │    ╲___      ___╱‾‾‾‾‾‾
  0% ┤        ‾‾‾‾‾‾
     ├─[ game: Zelda ]─[ media: podcast ]──────── activities, by category
     ├──────░░░░░░░────────────────────────────── Wi-Fi online / offline
     ├──────────────────────[ charging ]───────── charge
     └─08:00──────10:00──────12:00──────14:00───
```

- Battery as a line; activities as bands coloured by category; Wi-Fi and charging
  as thin strips; sleep shown as a gap.
- Drawn in hand-written SVG, embedded in the page. No chart library: the page is
  served by the console and must work with no Internet on the phone.
- Data from `parental/stats.log` and `activity.log`
  ([recording](../parental/data.md#recording)).
- Times come from the console's clock, so an
  [untrusted clock](../core/clock.md#trusted-time) is flagged on the chart.

## API

JSON over HTTP, cookie required except on `/pair`.

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/pair?t=` | Swap the token for a cookie |
| `GET` | `/api/today` | Today's budget and windows |
| `POST` | `/api/extra-time` | Grant extra time: appends to `grants.log` |
| `GET` | `/api/history?from=&to=` | Sessions |
| `GET` | `/api/stats?day=` | Battery, Wi-Fi, charge and activity samples for one day |
| `GET` / `PUT` | `/api/rules` | Time windows and budgets |
| `GET` / `PUT` | `/api/calendar` | Holiday periods |

Writes take effect at once. The server writes `rules.toml` and appends to
`grants.log` only; every other file belongs to Parental.pak
([data](../parental/data.md#files)).
