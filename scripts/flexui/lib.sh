#!/bin/sh
# lib.sh - shared helpers for the FlexUI maintenance scripts.
#
# Sourced, never executed. POSIX sh only: these scripts run on the maintainer's
# machine, which is macOS (BSD userland, bash 3.2) as often as Linux.

# Remote pointing at upstream LoveRetro/NextUI. Override with UPSTREAM=<remote>.
UPSTREAM="${UPSTREAM:-nextui}"
UPSTREAM_BRANCH="${UPSTREAM_BRANCH:-main}"

# Files the fork owns outright: replaced wholesale, and kept on every upstream
# merge by the "ours" merge driver declared in .gitattributes. They cost no
# maintenance, so footprint.sh does not count them.
FORK_OWNED="README.md workspace/tg5040/install/logo.png workspace/tg5050/install/logo.png"

die() {
	echo "error: $*" >&2
	exit 1
}

info() { echo "==> $*"; }
warn() { echo "warning: $*" >&2; }

repo_root() {
	git rev-parse --show-toplevel 2>/dev/null || die "not inside a git repository"
}

require_clean_tree() {
	if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
		die "working tree has uncommitted changes; commit or stash them first"
	fi
}

require_upstream_remote() {
	if ! git remote | grep -qx "$UPSTREAM"; then
		die "no remote named '$UPSTREAM'; run scripts/flexui/setup.sh"
	fi
}
