#!/bin/sh
# footprint.sh - measure what the fork costs to maintain.
#
# The maintenance debt is the number of hunks the fork leaves in files upstream
# owns. New files cost nothing on a merge; hunks in nextui.c do. Files the fork
# owns outright are excluded: the merge driver keeps them, so they never
# conflict.
#
# Usage: scripts/flexui/footprint.sh            per-file report
#        scripts/flexui/footprint.sh --files    just the touched upstream files

set -e
SELF_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SELF_DIR/lib.sh"
cd "$(git rev-parse --show-toplevel)"

require_upstream_remote
BASE="$UPSTREAM/$UPSTREAM_BRANCH"
git rev-parse --verify --quiet "$BASE" >/dev/null || die "$BASE not fetched"

is_fork_owned() {
	for owned in $FORK_OWNED; do
		[ "$1" = "$owned" ] && return 0
	done
	return 1
}

# Upstream files the fork modifies, excluding the ones it owns outright.
touched_upstream_files() {
	git diff --name-only --diff-filter=M "$BASE" HEAD | while IFS= read -r f; do
		is_fork_owned "$f" || echo "$f"
	done
}

if [ "$1" = "--files" ]; then
	touched_upstream_files
	exit 0
fi

printf '%7s  %s\n' "HUNKS" "UPSTREAM FILE"
total=0
files=0
for f in $(touched_upstream_files); do
	h=$(git diff -U0 "$BASE" HEAD -- "$f" | grep -c '^@@' || true)
	total=$((total + h))
	files=$((files + 1))
	printf '%7s  %s\n' "$h" "$f"
done

echo
echo "$total hunks across $files upstream files"
echo "budget: <= 3 hunks per change that opens a seam, 0 for anything built on one"
echo "(files the fork owns outright are excluded: $FORK_OWNED)"
