# Pak manifest

One `manifest.toml` per pak: the contract of the public API. It names the pak,
the API version it targets, its activity category and its hook subscriptions.
Builds on [hooks](hooks.md); every pak in the other domains uses it.

| Section | Content |
|---|---|
| [Decisions](#decisions) | M1–M8 |
| [File](#file) | Name, location, an example |
| [Fields](#fields) | The v1 schema |
| [Categories](#categories) | The closed list, plus `other` |
| [Legacy paks](#legacy-paks) | A synthesized manifest for paks without one |
| [Emus paks](#emus-paks) | No manifest, implicit `game` |
| [Admin overrides](#admin-overrides) | Kept in parental storage |
| [Discovery and validation](#discovery-and-validation) | At boot and on `pak-installed` |
| [Open questions](#open-questions) | Not decided yet |

## Decisions

| # | Question | Decision |
|---|---|---|
| M1 | Format | TOML |
| M2 | Name and location | `manifest.toml` at the root of the `.pak` |
| M3 | Mandatory? | No. A pak without one gets a synthesized manifest flagged `legacy` |
| M4 | v1 fields | `name`, `version`, `api`, `category`, `[hooks]`, `description`, `author`, `homepage` |
| M5 | Categories | Closed list plus `other`; the OS ships category hints for known paks |
| M6 | Emus paks | No manifest; implicit `game` |
| M7 | Admin overrides | In parental storage |
| M8 | Validation | At boot, errors logged, faulty pak skipped; rerun on a `pak-installed` event |

## File

`Tools/<platform>/<Name>.pak/manifest.toml`, or
`.system/<platform>/paks/<Name>.pak/manifest.toml` for a system pak.

```toml
name = "parental"
version = "2.0.0"
api = 1
category = "tool"
description = "Daily play time budget and time windows"
author = "FlexUI"
homepage = "https://github.com/dalexanco/NextUI"

[hooks]
entry = "hook.sh"
events = ["pre-launch", "activity-start", "activity-stop", "wake"]
priority = 10
timeout = 3
```

Parsed with tomlc17 (MIT), already used by nextui-samba-sync.

## Fields

| Field | Type | Required | Rule |
|---|---|---|---|
| `name` | string | yes | `[a-z0-9-]`, 1–32 characters, unique across paks. Also the event namespace (H6) |
| `version` | string | yes | Free form; `MAJOR.MINOR.PATCH` advised |
| `api` | integer | yes | Core API version targeted; unsupported → pak skipped (H9) |
| `category` | string | no | One of [the categories](#categories); default `other` |
| `description` | string | no | One line, shown in a future catalogue |
| `author` | string | no | |
| `homepage` | string | no | URL |
| `hooks.entry` | string | if `[hooks]` | Path relative to the pak, executable |
| `hooks.events` | string array | if `[hooks]` | Core events, or `<pak>.<event>` |
| `hooks.priority` | integer | no | 0–99, default 50, lower runs first |
| `hooks.timeout` | integer | no | Seconds for synchronous events; default 3, capped at 10 |

- No `mode` key: H2 fixes the mode per event.
- No `sync` section: synced folders are declared in the sync pak's own config
  ([sync](../sync/sync.md#links-and-policies)).
- No `permissions` section.
- Unknown keys are ignored with a warning, so a pak written for a later minor
  version still loads.

## Categories

| Category | For |
|---|---|
| `game` | Anything played: emulators, native games |
| `media` | Podcasts, music, video, audiobooks |
| `education` | Learning apps |
| `tool` | Settings, file manager, system utilities |
| `other` | Anything else, and any unknown value |

Parental budgets count by category, so the list is closed: a parent never meets
a category they did not expect.

### Category hints

The OS ships a table assigning a category to well-known paks that have no
manifest, keyed by pak directory name:

```text
# .system/<platform>/res/category-hints.txt
Battery       tool
Bootlogo      tool
Clock         tool
Files         tool
Game Tracker  tool
```

A hint applies only to a legacy pak. A real manifest and an
[admin override](#admin-overrides) both win over it.

## Legacy paks

A pak without `manifest.toml` is loaded through a manifest the OS builds for it,
so the rest of the system reads manifests only and has a single code path.

| Field | Synthesized value |
|---|---|
| `name` | Directory name, lower-cased, spaces to `-` (`Game Tracker.pak` → `game-tracker`) |
| `version` | `0` |
| `api` | `1` |
| `category` | From the [hints](#category-hints), else `other` |
| `legacy` | `true` — set only by the OS; a real manifest cannot set it |
| `hooks.entry` | none: each event calls its own `<event>.sh` |
| `hooks.events` | One per `boot.sh`, `pre-launch.sh`, `post-launch.sh`, `pre-sleep.sh`, `post-resume.sh` present |
| `hooks.priority` | 50 |

Legacy event names map to the v1 ones: `pre-sleep` → `sleep`, `post-resume` →
`wake`. A legacy `pre-sleep.sh` does **not** get the veto that `sleep` allows;
only `pre-launch.sh` keeps its current veto.

## Emus paks

No manifest is read under `Emus/`. Every ROM launch is category `game`. An admin
can reclassify by system or by ROM through [overrides](#admin-overrides), for
example an emulator holding educational games.

## Admin overrides

Overrides live in `parental/rules.toml` ([parental data](../parental/data.md)),
outside synced folders. An admin can override, per pak or per Emus system:

- `category`;
- whether the pak's hooks run at all.

Precedence, highest first: admin override, `manifest.toml`, category hint,
default.

## Discovery and validation

`flexui-manifest`, a small C tool on tomlc17, scans all paks and writes a flat
cache under `/tmp` that `pak-hooks.sh` and the launcher read. Shell never parses
TOML.

It runs:

- at boot;
- on `pak-installed`, a core event emitted when the content of `Tools/`
  changes — today, after any Tools pak exits (the hook cache rebuild in
  `pak-hooks.sh`).

| Problem | Effect |
|---|---|
| TOML syntax error | Pak skipped from hooks, still launchable |
| Missing `name`, `version` or `api` | Skipped |
| Unsupported `api` | Skipped |
| Invalid or duplicate `name` | Skipped; for a duplicate, the system pak wins, then the first in path order |
| `hooks.entry` missing or not executable | Skipped |
| Unknown event in `hooks.events` | That event ignored, warning |
| Unknown `category` | `other`, warning |
| Unknown key | Ignored, warning |

Each skip or warning goes to the hooks log (H10) with the pak path and the
reason.

## Open questions

| Question | Why it matters |
|---|---|
| `pak-removed` alongside `pak-installed`? | Lets parental and sync forget a deleted pak |
| Detecting a change in `Tools/` | A Tools pak exit catches the Pak Store and Files; a card edited on a PC is only seen at the next boot |
| Initial content of the category hints | Which third-party paks matter: podcast, video and music players |
