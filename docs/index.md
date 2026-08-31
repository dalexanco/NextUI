# FlexUI documentation

| Document | What it covers |
|---|---|
| [fork-strategy.md](fork-strategy.md) | Why the fork is shaped this way: seams, footprint budget, the five core edits |
| [../.claude/rules/fork-changes.md](../.claude/rules/fork-changes.md) | The rules for changing NextUI's own code |
| [architecture/](architecture/index.md) | How NextUI itself works |

Upstream reference lives in the NextUI repository root: `PAKS.md`, `HOOKS.md`,
`README.md`. This directory does not duplicate them.

## Tooling

| Script | Purpose |
|---|---|
| `scripts/flexui/setup.sh` | One-time local setup: `nextui` remote, `ours` merge driver |
| `scripts/flexui/sync-upstream.sh` | Fetch and merge upstream into `main` |
| `scripts/flexui/footprint.sh` | Measure what the fork costs to maintain |

Agent skill for the same workflow: `.claude/skills/upstream-sync`.
