#!/bin/sh
# sync-upstream.sh - merge upstream NextUI into the fork.
#
# FlexUI is a plain fork: one long-lived main that merges nextui/main. A merge
# resolves each conflict once, against the merge base, instead of replaying it
# at every sync.
#
# Usage: scripts/flexui/sync-upstream.sh

set -e
SELF_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SELF_DIR/lib.sh"
cd "$(git rev-parse --show-toplevel)"

require_upstream_remote
require_clean_tree

info "fetching $UPSTREAM"
git fetch "$UPSTREAM"

BASE="$UPSTREAM/$UPSTREAM_BRANCH"
AHEAD=$(git rev-list --count "HEAD..$BASE")
info "$BASE is at $(git rev-parse --short "$BASE"), $AHEAD commits we do not have"

if [ "$AHEAD" -eq 0 ]; then
	info "already up to date"
	exit 0
fi

# Which upstream commits landed in the files the fork actually changes. If
# nothing here moved, the merge cannot conflict.
CONTACT=$(sh "$SELF_DIR/footprint.sh" --files 2>/dev/null || true)
if [ -n "$CONTACT" ]; then
	info "upstream activity in files the fork changes:"
	# shellcheck disable=SC2086
	git --no-pager log --oneline "HEAD..$BASE" -- $CONTACT | sed 's/^/    /'
fi

info "merging $BASE"
git merge --no-edit "$BASE" || die "conflict merging $BASE

Resolve it, then:
    git add <files> && git commit

Files the fork owns (README.md, the install logos) should never appear here --
.gitattributes keeps our version automatically. If one does, run
scripts/flexui/setup.sh: the 'ours' merge driver is missing from git config."

cat <<'MSG'

A clean merge proves nothing. Build before trusting this sync:
    make PLATFORM=tg5040 build
MSG
