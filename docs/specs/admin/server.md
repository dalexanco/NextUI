# Admin server

A page and a JSON API served by the console over HTTP, opened from the parent's
phone. This file covers when it runs and how it is built;
[pairing](pairing.md) and [interface](interface.md) cover the rest.

| Section | Content |
|---|---|
| [Decisions](#decisions) | Framing, B1–B6, W1, W7 |
| [What it is for](#what-it-is-for) | History and planning, no live status |
| [Activation rule](#activation-rule) | Menus only |
| [Lifecycle](#lifecycle) | The events that start and stop it |
| [Server](#server) | Binary, port |
| [Consequences](#consequences) | For extra time and the phone |

## Decisions

| # | Question | Decision |
|---|---|---|
| — | Transport | HTTP, served by the console. No PWA, no Bluetooth, no hosted front |
| — | Scope | One console, one page, its own pairing. No multi-console view |
| — | Purpose | Read reports and configure more easily than with the D-pad. No live status, no request from the child |
| B1–B6 | Battery measurement | Dropped. Instead: server on in the menus only, off during any pak or emulator |
| W1 | Server | civetweb (MIT), embedded in a C binary |
| W7 | Port | Configurable, 80 by default |

Rationale for B1–B6: an activity must never pay for the server, in CPU or in
battery. In the menus, the screen dominates power draw and the CPU is idle.

## What it is for

| Does | Does not |
|---|---|
| Read the activity history and stats | Show a live status or the current activity |
| Plan the next sessions: time windows, budgets | Receive requests from the child |
| Push extra time to the device | Depend on a NAS or any other server |

- There is **no request model**. Extra time is granted only by the parent,
  pushed from the web interface, or entered on the device with the PIN.
- The phone and the Brick only need to share the home network; **no NAS is
  assumed**.

## Activation rule

The server runs when **all** of these hold:

- `nextui.elf` is in the foreground (game list, recents, quick menu);
- Wi-Fi is associated;
- the device is awake.

It is stopped in every other case, Tools paks included (Settings, Files,
Parental's own menu).

One exception: Parental.pak's pairing screen runs the server, for `/pair` only
([pairing](pairing.md)).

The server never turns Wi-Fi on or off. Wi-Fi stays under the user's setting.

## Lifecycle

The server is a system pak, `admin`, driven by [hooks](../core/hooks.md).

| Event | Action |
|---|---|
| `boot` | Start, if Wi-Fi is associated |
| `pre-launch` | Stop, before the pak or emulator starts; never vetoes |
| `post-launch` | Start, back in the menus |
| `sleep` | Stop |
| `wake` | Start, if Wi-Fi is associated and the device was in the menus |
| `wifi-connected` | Start, if in the menus |
| `wifi-lost` | Stop |
| `shutdown` | Stop |

- The pak takes a low `priority` value so that, among system paks, it stops first
  on `pre-launch`.
- A stop is `kill` plus a wait for exit, bounded by the pak's `timeout`. It must
  stay well under the transition screen threshold, so launching a game shows no
  delay.
- "In the menus" is tracked by the pak itself: set on `boot` and `post-launch`,
  cleared on `pre-launch`. `sleep` and `wake` leave it unchanged, since waking
  from a game returns to the game.

## Server

- One C binary, `flexui-admin`, with civetweb and the page embedded, shipped in
  the `admin` system pak. No other file to install.
- Port from `parental/rules.toml`, 80 by default.
- Page and API only; no file upload, no shell access.

## Consequences

| Area | Effect |
|---|---|
| Extra time | Pushed by the parent while the device is in the menus; applies at once |
| Phone | History and planning only. "Unreachable" is a normal state, not an error |
| Parent reaches the device | Only while the child is in the menus with Wi-Fi on, on the same network |
| Battery | No cost during an activity; in the menus, the cost of an associated radio, unmeasured |
| Performance | Unchanged during any activity |
