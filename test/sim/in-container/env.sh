#!/bin/sh
# env.sh - the paths and variables a desktop session sees, as set by the
# desktop MinUI.pak/launch.sh. Sourced by the other in-container scripts.

export PLATFORM="desktop"
export SDCARD_PATH="/var/tmp/nextui/sdcard"
export SIM_PATH="/var/tmp/nextui/sim"
export BIOS_PATH="$SDCARD_PATH/Bios"
export ROMS_PATH="$SDCARD_PATH/Roms"
export SAVES_PATH="$SDCARD_PATH/Saves"
export CHEATS_PATH="$SDCARD_PATH/Cheats"
export SYSTEM_PATH="$SDCARD_PATH/.system/$PLATFORM"
export CORES_PATH="$SYSTEM_PATH/cores"
export USERDATA_PATH="$SDCARD_PATH/.userdata/$PLATFORM"
export SHARED_USERDATA_PATH="$SDCARD_PATH/.userdata/shared"
export LOGS_PATH="$USERDATA_PATH/logs"
export HOOKS_PATH="$USERDATA_PATH/.hooks"
export LD_LIBRARY_PATH="$SYSTEM_PATH/lib:${LD_LIBRARY_PATH:-}"
export PATH="$SYSTEM_PATH/bin:$PATH"

export DISPLAY=":99"
export SDL_VIDEODRIVER="x11"
export SDL_AUDIODRIVER="dummy"

export SIM_LOG="/var/tmp/nextui/sim.log"
