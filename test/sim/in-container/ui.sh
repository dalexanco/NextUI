#!/bin/sh
# ui.sh - start the virtual screen and run the launcher loop, as the device
# shell does: nextui.elf, then whatever it wrote to /tmp/next, with the
# pre-launch / post-launch hooks around it. Runs until "sim.sh stop".
# shellcheck source=/dev/null
. /opt/sim/env.sh

pkill -x Xvfb 2>/dev/null
Xvfb "$DISPLAY" -screen 0 1024x768x24 -nolisten tcp > /tmp/xvfb.log 2>&1 &
i=0
while ! xdpyinfo -display "$DISPLAY" > /dev/null 2>&1; do
	i=$((i + 1))
	[ "$i" -gt 50 ] && { echo "Xvfb did not start" >> "$SIM_LOG"; exit 1; }
	sleep 0.1
done

mkdir -p "$ROMS_PATH" "$SAVES_PATH" "$USERDATA_PATH" "$LOGS_PATH" \
	"$HOOKS_PATH" "$SHARED_USERDATA_PATH/.minui" "$SIM_PATH"

"$SYSTEM_PATH/bin/run_hooks.sh" boot.d

# Same parsing as the desktop MinUI.pak/launch.sh, so hooks see the same
# HOOK_* variables as on the device.
parse_hook_cmd() {
	HOOK_CMD="$1"
	HOOK_EMU_PATH=$(echo "$HOOK_CMD" | sed "s/^'\\([^']*\\)'.*/\\1/")
	_remainder=$(echo "$HOOK_CMD" | sed "s/^'[^']*'//")
	if echo "$_remainder" | grep -q "'"; then
		HOOK_TYPE="rom"
		HOOK_ROM_PATH=$(echo "$_remainder" | sed "s/.*'\\([^']*\\)'.*/\\1/")
	else
		HOOK_TYPE="pak"
		HOOK_ROM_PATH=""
	fi
	export HOOK_CMD HOOK_EMU_PATH HOOK_TYPE HOOK_ROM_PATH
}

touch /tmp/sim_running
while [ -f /tmp/sim_running ]; do
	cd "$SYSTEM_PATH/paks/MinUI.pak" || exit 1
	echo "--- nextui.elf" >> "$SIM_LOG"
	nextui.elf >> "$SIM_LOG" 2>&1
	if [ -f /tmp/next ]; then
		CMD=$(cat /tmp/next)
		rm -f /tmp/next
		echo "--- next: $CMD" >> "$SIM_LOG"
		parse_hook_cmd "$CMD"
		if "$SYSTEM_PATH/bin/run_hooks.sh" pre-launch.d; then
			# Paks run under BusyBox ash, the device shell: their launch.sh use
			# ash extensions such as "&>", which Ubuntu's dash reads differently.
			eval "busybox ash $CMD" >> "$SIM_LOG" 2>&1
			"$SYSTEM_PATH/bin/run_hooks.sh" post-launch.d
		else
			echo "--- vetoed" >> "$SIM_LOG"
		fi
	fi
	sleep 0.2
done
