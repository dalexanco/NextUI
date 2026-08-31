#!/bin/sh
# setup.sh - one-time local configuration for maintaining the FlexUI fork.
#
# Idempotent: safe to re-run at any time.

set -e
SELF_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SELF_DIR/lib.sh"
cd "$(git rev-parse --show-toplevel)"

UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/LoveRetro/NextUI.git}"

if git remote | grep -qx "$UPSTREAM"; then
	info "remote '$UPSTREAM' already present: $(git remote get-url "$UPSTREAM")"
else
	info "adding remote '$UPSTREAM' -> $UPSTREAM_URL"
	git remote add "$UPSTREAM" "$UPSTREAM_URL"
fi

# git ships the "ours" merge strategy but not the per-file driver of the same
# name; .gitattributes references it, and without this line those files
# conflict on every upstream merge instead of keeping our version.
info "enabling the 'ours' merge driver (see .gitattributes)"
git config merge.ours.driver true

info "fetching $UPSTREAM"
git fetch "$UPSTREAM"

info "done. Next: scripts/flexui/sync-upstream.sh"
