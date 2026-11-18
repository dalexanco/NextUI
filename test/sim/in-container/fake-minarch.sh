#!/bin/sh
# fake-minarch.sh - stands in for minarch.elf in the simulator, where no
# libretro core is built. Installed as /opt/sim/bin/minarch.elf, ahead of the
# real one on PATH, so the process is named minarch.elf and answers the same
# external control as the real one (workspace/all/flexui/minarch_control.h):
#
#   SIGUSR1  save and quit
#   SIGUSR2  show the text in /tmp/minarch_notify.txt as a toast, delete it
#   SIGTERM  quit, as when the player leaves from the menu ("sim.sh game stop")
#
# Usage, from an Emus pak's launch.sh: minarch.elf <core.so> <rom>
# shellcheck source=/dev/null
. /opt/sim/env.sh

NOTIFY_PATH="/tmp/minarch_notify.txt"
STATE="/tmp/sim_game"
ROM="${2:-unknown}"
NAME=$(basename "$ROM")

say() { echo "[game] $*" >> "$SIM_LOG"; }

finish() {
	say "$1: $NAME"
	[ -n "${SCREEN_PID:-}" ] && kill "$SCREEN_PID" 2> /dev/null
	rm -f "$STATE"
	exit 0
}

toast() {
	msg=""
	[ -f "$NOTIFY_PATH" ] && msg=$(cat "$NOTIFY_PATH") && rm -f "$NOTIFY_PATH"
	say "toast: $msg"
	[ -n "$msg" ] && xmessage -center -timeout 3 "$msg" > /dev/null 2>&1 &
}

trap 'finish "save-and-quit (SIGUSR1)"' USR1
trap 'finish "quit"' TERM INT
trap 'toast' USR2

echo "$ROM" > "$STATE"
say "start: $NAME (core $(basename "${1:-none}"))"

# Something to see on a screenshot while the "game" runs.
xmessage -center -buttons "" "Playing $NAME (simulated minarch)" > /dev/null 2>&1 &
SCREEN_PID=$!

# sleep in the background and wait on it, so traps run within a second.
while :; do
	sleep 1 &
	wait $!
done
