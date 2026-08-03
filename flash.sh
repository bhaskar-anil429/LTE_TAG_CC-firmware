#!/usr/bin/env bash
# One-command factory flash. Auto-detects a USB-serial port on macOS/Linux, then
# erases the chip and writes the merged factory image.
#
# Usage:
#   ./flash.sh            # auto-detect port
#   ./flash.sh /dev/cu.usbserial-0001
#
# Requires: python3 -m pip install esptool

set -eu
IMG="$(cd "$(dirname "$0")" && pwd)/factory_v1.19.bin"

if [[ ! -f "$IMG" ]]; then
    echo "ERROR: $IMG not found. Copy factory_v1.19.bin next to this script."
    exit 1
fi

if [[ $# -ge 1 ]]; then
    PORT="$1"
else
    # macOS: /dev/cu.usbserial-*   Linux: /dev/ttyUSB*  /dev/ttyACM*
    PORT=$(ls /dev/cu.usbserial-* /dev/ttyUSB* /dev/ttyACM* 2>/dev/null | head -1 || true)
    if [[ -z "$PORT" ]]; then
        echo "ERROR: no USB-serial port found. Pass one as an argument, e.g. ./flash.sh /dev/cu.usbserial-0001"
        exit 1
    fi
fi

echo "Port:  $PORT"
echo "Image: $IMG"
echo ""

python3 -m esptool --chip esp32 -p "$PORT" -b 921600 erase_flash
echo ""
python3 -m esptool --chip esp32 -p "$PORT" -b 921600 \
    --before default_reset --after hard_reset \
    write_flash --flash_mode dio --flash_freq 40m --flash_size 16MB \
    0x0 "$IMG"

echo ""
echo "===================================================="
echo "  DONE. Device rebooting into V1.19 factory image."
echo "===================================================="
