#!/bin/sh
# build.sh - copy the mounted repository to /work, build the desktop platform,
# and install the result on the simulated SD card. User data, ROMs and saves on
# the card survive a rebuild; .system is replaced.
set -e
# shellcheck source=/dev/null
. /opt/sim/env.sh

# Git-ignored paths are neither copied nor deleted: build outputs and the
# dependencies the makefiles clone (libretro-common, rcheevos...) survive.
rsync -a --delete --exclude '.git/' --filter=':- .gitignore' /src/ /work/

cd /work
make setup PLATFORM=desktop
make common PLATFORM=desktop

mkdir -p "$SDCARD_PATH" "$SIM_PATH"
rsync -a build/BASE/ "$SDCARD_PATH/"
rsync -a build/EXTRAS/ "$SDCARD_PATH/"
mkdir -p "$SDCARD_PATH/.system"
rsync -a --delete build/SYSTEM/ "$SDCARD_PATH/.system/"

echo "installed on $SDCARD_PATH"
