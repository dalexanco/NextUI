#!/bin/sh
# sim.sh - drive the FlexUI simulator container from the host.
#
# The desktop platform, built for Linux and run on a 1024x768 virtual screen.
# Keys go in through xdotool, screenshots come out as PNG files, hardware state
# (battery, charging, Wi-Fi) is read from files under /var/tmp/nextui/sim.
#
# Usage: test/sim/sim.sh <command> [args]
#
#   up                  build or update the image, (re)start the container
#   build               copy the repo in, build the desktop platform, install it
#   start | stop        start or stop the launcher loop on the virtual screen
#   shot [file]         screenshot to file (default build-sim/shot.png)
#   key <button>...     press device buttons: up down left right a b x y
#                       start select menu power l1 r1; "wait" pauses 0.5 s
#   set <name> <value>  simulated state: battery 0-100, charging 0|1, wifi 0|1
#   emit <event>        run the hooks of an event (boot, pre-launch, ...)
#   log [n]             last n lines of the simulator log (default 40)
#   exec <cmd>...       run a command in the container, with the device env
#   shell               interactive shell in the container
#   down                remove the container; build cache and SD card are kept
#   reset               remove the container, its build cache and its SD card
#
# Environment: ENGINE (docker or podman, auto-detected), SIM_NAME.
# Single-quoted sh -c scripts expand inside the container, on purpose.
# shellcheck disable=SC2016
set -e

: "${SIM_NAME:=flexui-sim}"
SIM_IMAGE="flexui-sim:latest"
HERE=$(cd "$(dirname "$0")" && pwd)
REPO=$(cd "$HERE/../.." && pwd)
OUT_DIR="$REPO/build-sim"

if [ -z "${ENGINE:-}" ]; then
	if command -v docker > /dev/null 2>&1; then ENGINE=docker
	elif command -v podman > /dev/null 2>&1; then ENGINE=podman
	else echo "sim: neither docker nor podman found" >&2; exit 1
	fi
fi

die() { echo "sim: $*" >&2; exit 1; }

running() {
	[ "$("$ENGINE" inspect -f '{{.State.Running}}' "$SIM_NAME" 2>/dev/null)" = "true" ]
}

need_running() {
	running || die "container '$SIM_NAME' is not running; run: test/sim/sim.sh up"
}

# Runs a command inside the container with the device environment loaded.
in_env() {
	"$ENGINE" exec "$SIM_NAME" sh -c '. /opt/sim/env.sh; exec "$@"' sh "$@"
}

keysym() {
	case "$1" in
		up) echo Up ;; down) echo Down ;; left) echo Left ;; right) echo Right ;;
		a) echo s ;; b) echo a ;; x) echo w ;; y) echo q ;;
		start) echo Return ;; select) echo grave ;; menu) echo space ;;
		power) echo BackSpace ;; l1) echo Tab ;; r1) echo b ;;
		*) return 1 ;;
	esac
}

cmd="${1:-}"
[ -n "$cmd" ] || { sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
shift

case "$cmd" in
up)
	# Cached layers make this quick; it keeps the image in step with the Dockerfile.
	"$ENGINE" build -q -t "$SIM_IMAGE" "$HERE" > /dev/null
	if running && [ "$("$ENGINE" inspect -f '{{.Image}}' "$SIM_NAME")" = "$("$ENGINE" image inspect -f '{{.Id}}' "$SIM_IMAGE")" ]; then
		echo "sim: '$SIM_NAME' already running"
	else
		"$ENGINE" rm -f "$SIM_NAME" > /dev/null 2>&1 || true
		"$ENGINE" run -d --name "$SIM_NAME" \
			-v "$REPO:/src:ro" \
			-v "$SIM_NAME-work:/work" \
			-v "$SIM_NAME-sd:/var/tmp/nextui" \
			-p 8080:80 \
			"$SIM_IMAGE" > /dev/null
		echo "sim: '$SIM_NAME' started; next: test/sim/sim.sh build"
	fi
	;;
rebuild-image)
	"$ENGINE" build --no-cache -t "$SIM_IMAGE" "$HERE"
	;;
build)
	need_running
	"$ENGINE" exec "$SIM_NAME" /opt/sim/build.sh
	;;
start)
	need_running
	"$ENGINE" exec -d "$SIM_NAME" /opt/sim/ui.sh
	sleep 3
	echo "sim: launcher started; see: test/sim/sim.sh shot"
	;;
stop)
	need_running
	"$ENGINE" exec "$SIM_NAME" sh -c 'rm -f /tmp/sim_running; pkill -x nextui.elf; pkill -x Xvfb' || true
	;;
shot)
	need_running
	file="${1:-$OUT_DIR/shot.png}"
	mkdir -p "$(dirname "$file")"
	in_env import -window root /tmp/shot.png
	"$ENGINE" cp "$SIM_NAME:/tmp/shot.png" "$file" > /dev/null
	echo "$file"
	;;
key)
	need_running
	[ $# -gt 0 ] || die "key: name at least one button"
	for b in "$@"; do
		if [ "$b" = "wait" ]; then sleep 0.5; continue; fi
		k=$(keysym "$b") || die "key: unknown button '$b'"
		in_env xdotool key --delay 80 "$k"
		sleep 0.15
	done
	;;
set)
	need_running
	[ $# -eq 2 ] || die "set: usage: set <battery|charging|wifi> <value>"
	case "$1" in battery|charging|wifi) ;; *) die "set: unknown state '$1'" ;; esac
	in_env sh -c 'mkdir -p "$SIM_PATH" && printf "%s\n" "$2" > "$SIM_PATH/$1"' sh "$1" "$2"
	echo "sim: $1=$2"
	;;
emit)
	need_running
	[ $# -eq 1 ] || die "emit: usage: emit <event>"
	in_env sh -c '"$SYSTEM_PATH/bin/run_hooks.sh" "$1.d"; echo "exit=$?"' sh "$1"
	;;
log)
	need_running
	"$ENGINE" exec "$SIM_NAME" tail -n "${1:-40}" /var/tmp/nextui/sim.log
	;;
exec)
	need_running
	in_env "$@"
	;;
shell)
	need_running
	"$ENGINE" exec -it "$SIM_NAME" sh -c '. /opt/sim/env.sh; cd "$SDCARD_PATH"; exec bash'
	;;
down)
	"$ENGINE" rm -f "$SIM_NAME" > /dev/null 2>&1 || true
	echo "sim: '$SIM_NAME' removed; the build cache and the SD card are kept"
	;;
reset)
	"$ENGINE" rm -f "$SIM_NAME" > /dev/null 2>&1 || true
	"$ENGINE" volume rm -f "$SIM_NAME-work" "$SIM_NAME-sd" > /dev/null 2>&1 || true
	echo "sim: '$SIM_NAME', its build cache and its SD card removed"
	;;
*)
	die "unknown command '$cmd'; run without arguments for help"
	;;
esac
