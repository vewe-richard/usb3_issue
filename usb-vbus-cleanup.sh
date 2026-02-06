#!/bin/bash
# USB VBUS cleanup script - removes lockfile when device successfully connects at 5000M
# This allows USB 3.0 devices to be fixed again if replugged

LOCKDIR="/tmp/usb-vbus-fix"

# Get device info from udev environment
DEVPATH="$1"
VENDOR=""
PRODUCT=""

if [ -n "$DEVPATH" ]; then
    VENDOR=$(cat "$DEVPATH/idVendor" 2>/dev/null)
    PRODUCT=$(cat "$DEVPATH/idProduct" 2>/dev/null)
fi

DEVICE_ID="${VENDOR}-${PRODUCT}"
LOCKFILE="${LOCKDIR}/${DEVICE_ID}.lock"

# Remove lockfile for this device
if [ -f "$LOCKFILE" ]; then
    rm -f "$LOCKFILE"
    logger -t usb-vbus-fix "Device $DEVICE_ID connected at 5000M, lockfile removed"
fi

exit 0
