#!/bin/bash
# Update kernel with A/B slot awareness.
# Default: write the inactive slot only (keeps the running slot intact).
#   --switch   : after writing, switch the boot slot to the updated one
#   --both     : write both A and B slots (recovery / manual)
#   --dry-run  : print what would be done, do not write
set -e

usage() {
    cat <<EOF
Usage: $0 <firmware_dir> [--switch|--both|--dry-run]

  <firmware_dir> must contain boot_signed.bin.

Examples:
  $0 /root                         # write inactive slot, stay on current
  $0 /root --switch                # write inactive slot and switch to it
  $0 /root --both                  # write both slots (no switch)
  $0 /root --dry-run               # show target only
EOF
}

if [ $# -lt 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
    exit 1
fi

FIRMWARE_DIR=$1
MODE=${2:-inactive}

case "$MODE" in
    --switch)  MODE=switch ;;
    --both)    MODE=both ;;
    --dry-run) MODE=dryrun ;;
    inactive)  MODE=inactive ;;
    *) echo "Unknown option: $MODE"; usage; exit 1 ;;
esac

SRC="$FIRMWARE_DIR/boot_signed.bin"
if [ ! -f "$SRC" ]; then
    echo "Error: $SRC not found"
    exit 1
fi

SLOT=$(fw_printenv -n bootsystem 2>/dev/null || echo A)
if [ "$SLOT" = "A" ]; then
    TARGET=/dev/mmcblk0p15
    OTHER=B
else
    TARGET=/dev/mmcblk0p14
    OTHER=A
fi

echo "current slot: $SLOT"
echo "inactive slot target: $TARGET (slot $OTHER)"

write_one() {
    echo "writing $1 -> $2"
    if [ "$MODE" = "dryrun" ]; then
        echo "  (dry-run) dd if=$1 of=$2 bs=1M conv=fsync"
    else
        dd if="$1" of="$2" bs=1M conv=fsync
    fi
}

case "$MODE" in
    both)
        write_one "$SRC" /dev/mmcblk0p14
        write_one "$SRC" /dev/mmcblk0p15
        ;;
    *)
        write_one "$SRC" "$TARGET"
        ;;
esac

if [ "$MODE" != "dryrun" ]; then
    sync
fi

if [ "$MODE" = "switch" ]; then
    echo "switching boot slot to $OTHER and rebooting is required"
    if [ "$SLOT" = "A" ]; then
        /etc/init.d/S99checkboot systemB
    else
        /etc/init.d/S99checkboot systemA
    fi
    echo "reboot to test the updated slot"
elif [ "$MODE" = "inactive" ]; then
    echo "done. current slot $SLOT is unchanged."
    echo "to test the updated slot, run: $0 $FIRMWARE_DIR --switch"
fi
