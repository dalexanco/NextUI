# Fork strategy

## The premise

A fork's cost is not the number of features it carries. It is the number of
**hunks it leaves in files upstream keeps editing**.

So FlexUI does not carry features as patches. It carries a small number of
structural changes — **core edits** — each of which opens an extension point,
and builds everything else on top of those without touching upstream code at all.

| Section | Covers |
|---|---|
| [Conflict hotspots](#conflict-hotspots) | Where the pain comes from, measured |
| [Upstream footprint](#upstream-footprint) | The single metric |
| [The core edits](#the-core-edits) | Five seams, A through E |
| [Integration model](#integration-model) | Why `main` is regenerated, not merged |
| [Roadmap](#roadmap) | Suggested order |
| [Open questions](#open-questions) | Licence, how public the fork should be |

## Conflict hotspots

| Zone | Size | Upstream churn | Why it hurts |
|---|---|---|---|
| `workspace/all/nextui/nextui.c` | ~3 400 lines, one file | high | everything launcher-related lands here |
| `workspace/all/common/api.c` | ~4 750 lines | high | same for UI, power, GFX |
| `workspace/all/settings/settings.cpp` | large | medium | the menu tree is hardcoded |
| `workspace/makefile` (`cd ./all/X && make` list) | list | low but append-only | adding an app = adjacent-line conflict every time |
| `makefile`, `system:` target (`cp` list) | list | medium | same |
| `skeleton/SYSTEM/{tg5040,tg5050,desktop}/` | tripled | medium | every fork script written and rebased 3× |

Two prototypes make the point better than any argument:

- **pak hooks** (`06171af6`): 9 hunks in the C code — 3 in `api.c`, 6 in
  `nextui.c` — with the logic in a new file (`pak-hooks.sh`). The C side is
  free to rebase forever.
- **i18n** (upstream PR 735): **3 050 lines across 35 files**, rewriting every
  string literal in `settings.cpp` (410 lines), `ma_config.c` (209), `nextui.c`
  (51). Every upstream sync touching any menu produces a conflict.

The second approach makes a fork unmaintainable. That observation drives
everything below.

## Upstream footprint

One metric: **how many hunks a change leaves in files upstream owns.**

Budget: **≤ 3 hunks per core edit, 0 for anything built on top of one.**

```sh
scripts/flexui/footprint.sh
```

A core edit never implements a feature. It opens a **seam** — a hook point, a
dispatch table, a registry, a compiler-flag injection — and all the substance
lives in new files upstream will never touch. A change that exceeds its budget
means the seam is in the wrong place; find another one rather than accept the
diff.

## The core edits

| # | Seam | Footprint | Unlocks | Status |
|---|---|---|---|---|
| A | Lifecycle hooks | **46 hunks, measured** | parental, tracker, gift code, any reactive pak | done |
| — | Fork identity: name, logo, docs, tooling | 7 hunks | not a seam; what makes the fork a fork | done |
| B | Fork prelude (`makefile.env` injection) | 3 files × 3 lines | i18n, any cross-cutting logic | planned |
| C | App/pak auto-discovery | 2 hunks | a native pak costs 0 upstream edits | planned |
| D | `skeleton/SYSTEM/common/` overlay | 3 hunks | divides shell-script cost by 3 | planned |
| E | Config/menu option registry | 2 hunks | fork options without touching menus | planned |

### A — lifecycle hooks

Measured footprint, from `scripts/flexui/footprint.sh`:

| Files | Hunks | |
|---|---|---|
| `api.c`, `nextui.c` | 9 | the seam itself |
| `skeleton/SYSTEM/{tg5040,tg5050,desktop}/**` | 25 | **the same three edits, tripled** |
| `HOOKS.md` | 12 | documentation |
| **total** | **46** | |

The C seam is within budget. Everything above it is the triplication tax, which
is 54% of the cost of this change and would be cut by roughly two thirds by
seam D. This is the concrete argument for doing D first.

Tools paks self-register by dropping a `boot.sh`, `pre-launch.sh`,
`post-launch.sh`, `pre-sleep.sh` or `post-resume.sh` next to their own
`launch.sh`; `pak-hooks.sh` scans and runs them. Presence of the file *is* the
registration — no arming step, and removing the pak removes its hooks.

Remaining work: let paks shipped in `SYSTEM/` register too, so a native pak can
hook without living on the visible part of the SD card.

### B — the fork prelude

Every app makefile does `include ../../$(PLATFORM)/platform/makefile.env` and then
`$(CC) $(SOURCE) -o $(PRODUCT) $(CFLAGS) $(LDFLAGS)`. `makefile.env` is therefore
**the single injection point for the whole tree**, C and C++ alike, and exists in
three copies.

```make
CFLAGS  += -I../all/flexui -include flexui_prelude.h
LDFLAGS += ../all/flexui/build/$(PLATFORM)/libflexui.a
```

For i18n, the prelude redefines the two places text actually passes through:

```c
#define TTF_RenderUTF8_Blended(f,s,c)  FLEX_ttf_render(f, I18N_t(s), c)
#define TTF_SizeUTF8(f,s,w,h)          TTF_SizeUTF8(f, I18N_t(s), w, h)
```

There are **93 SDL_ttf call sites outside `api.c`** (29 in `ma_menu.c`, ~43 in
`settings/`). Covering them by macro costs 9 lines instead of 3 050, with zero
edits in any `.c` or `.cpp`. Translations are English-key → string, loaded from
`/.system/res/lang/*.txt`.

Limits to accept up front:

- strings built with `sprintf` pass through untranslated (mostly numbers);
- `-flto` is on for tg5040 — preprocessor macros resolve long before LTO, but
  verify;
- the lookup sits on the render path, so hash + memo cache are mandatory
  (`ma_menu` redraws per frame);
- `font1.ttf` already covers CJK.

If upstream merges PR 735, FlexUI deletes seam B.

### C — app auto-discovery

Replace the two hardcoded lists with a convention: any `workspace/all/*/`
directory containing a `pak.mk` gets built, and that `pak.mk` declares its own
copy destination. The lists become loops. Two hunks paid once; after that,
adding a pak touches zero upstream files.

Corollary: fork code lives under `workspace/all/flexui/` and `skeleton/FLEXUI/`
— paths upstream will never have, hence structurally conflict-free.

### D — de-triplicate `skeleton/SYSTEM/`

Seam A had to write `pak-hooks.sh` three times, identically. Add a pass in
`makefile.copy` overlaying `skeleton/SYSTEM/common/` onto each platform before
the platform-specific files.

### E — option registry

A `FLEX_registerSetting(...)` called during config load, plus one insertion point
in the Settings menu construction. Language selection, parental settings and
future options then come from fork-owned files.

## Integration model

Three models were considered:

| | Model | Upside | Downside |
|---|---|---|---|
| A | Topic branches rebased onto upstream, `main` regenerated | each change stays a clean, upstreamable patch | a stack to maintain, tooling to debug, conflicts replayed at every sync |
| B | Long-lived `main` merging upstream | each conflict resolved once, against the merge base | the fork's diff is one blob; extracting a change takes work |
| C | Out-of-tree overlay (submodule + patch series) | maximum cleanliness | painful ergonomics |

**FlexUI uses B.** One long-lived `main`, `git merge nextui/main` at every sync.

A was built first and dropped. Its one real advantage — handing upstream a single
isolated change — is reachable from B with a `git cherry-pick`, as long as each
fork change stays in one atomic `flexui:` commit. Its costs were not: a stack of
branches to keep aligned, ~250 lines of shell to maintain, and every conflict
replayed at every sync rather than resolved once (`rerere` caches resolutions,
but its cache is local and uncommitted, so CI never benefits).

Files the fork **owns outright** — `README.md`, the install logos — are marked
`merge=ours` in `.gitattributes`, so upstream edits to them are discarded
without a conflict. Use that only for fork identity; see
[the rule](../.claude/rules/fork-changes.md).

**Success criterion: a change merged upstream is deleted here.**

### Sync frequency is the real variable

Syncing weekly against 5 upstream commits is trivial. Syncing every six months
against 400 never is. A nightly CI job attempting the merge reports a
breakage against 3 commits of context instead of 300.

## Roadmap

1. **D** and **C** first: pure refactors, no feature attached, easy to get
   accepted upstream, and they lower the cost of everything else.
2. **A**: allow registration from `SYSTEM/` for native paks, not only `Tools/`.
3. **B**: prelude + macro-based i18n.
4. **E**: option registry, then migrate Parental / Music Player / Gift Code to
   native paks via C.

## Open questions

- **Licence.** `ae652648` moved NextUI to PolyForm Noncommercial 1.0.0. Forking
  is allowed; commercial use is not.
- **Public and upstreamable, or private?** Everything here assumes the seams are
  meant to go upstream. For a purely private fork, model B alone would cost less
  effort.
