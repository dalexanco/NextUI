# Platform layer (`PLAT_*`)

## The split

- `workspace/all/` — portable, knows only the abstract API.
- `workspace/<platform>/` — implements it.

The contract is `PLAT_*`, declared entirely in `workspace/all/common/api.h`.

## Three mechanisms, no vtable

### 1. Macro aliasing when nothing is added

```c
#define GFX_clear       PLAT_clearVideo
#define PAD_update      PLAT_updateInput
#define PWR_setCPUSpeed PLAT_setCPUSpeed
```

The caller writes `GFX_clear(screen)`; the preprocessor turns it into
`PLAT_clearVideo(screen)`. Zero cost.

### 2. Weak-symbol fallbacks

```c
#define FALLBACK_IMPLEMENTATION __attribute__((weak))
```

`api.c` provides weak `PLAT_*` bodies. If `platform.c` defines the same symbol
strongly, the linker picks the strong one. A platform implements only what it
changes.

### 3. Direct inclusion of the generic implementations

`workspace/tg5040/platform/platform.c` ends with:

```c
#include "generic_video.c"
#include "generic_wifi.c"
#include "generic_bt.c"
```

The generics are compiled *inside the platform translation unit*, so the platform
can redefine macros before including them. Pragmatic, not modular.

## Required files per platform

| File | Contents |
|---|---|
| `makefile.env` | `OPT`, `CFLAGS`, `LDFLAGS`, `SDL=SDL2` / `GL=GLES` |
| `makefile.copy` | rules copying platform-specific files into `build/` |
| `platform.h` | button codes, screen constants, `extern int is_brick;` |
| `platform.c` | strong `PLAT_*` implementations |

Every makefile under `workspace/all/*` does:

```make
include ../../$(PLATFORM)/platform/makefile.env
```

and compiles `platform.c` into the binary. **Each binary embeds its own copy of
the platform layer.**

That single `include` line, present in every app makefile and existing in only
three copies, is the injection point FlexUI's "prelude" seam uses. See
[../fork-strategy.md](../fork-strategy.md).
