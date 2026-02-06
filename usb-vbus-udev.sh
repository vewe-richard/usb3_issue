#!/bin/bash
# USB VBUS timing fix - triggered by udev on USB device detection
# Fixes USB-C orientation detection by toggling VBUS
# Uses lockfile to prevent repeated triggers on same device

VBUS_GPIO=611
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

# Create lock directory if it doesn't exist
mkdir -p "$LOCKDIR"

logger -t usb-vbus-fix "Device $DEVICE_ID detected at 480M"

# Check if we already processed this device
# Lockfile is removed by cleanup script when USB 3.0 device connects at 5000M
# For USB 2.0 devices, lockfile stays to prevent reconnection loops
if [ -f "$LOCKFILE" ]; then
    logger -t usb-vbus-fix "Device $DEVICE_ID already processed, skipping"
    exit 0
fi

# Create lockfile for this device
touch "$LOCKFILE"
logger -t usb-vbus-fix "Triggering VBUS fix for $DEVICE_ID"

# Trigger the VBUS fix
# This will help USB 3.0 devices that are falling back to 480M
# USB 2.0 devices will reconnect at 480M (no harm, but won't trigger again due to lockfile)

# Use sysfs GPIO control
GPIO_PATH="/sys/class/gpio/gpio${VBUS_GPIO}"

# Otherwise use sysfs approach
if [ ! -d "$GPIO_PATH" ]; then
    echo $VBUS_GPIO > /sys/class/gpio/export 2>/dev/null
    sleep 0.1
fi

echo out > ${GPIO_PATH}/direction 2>/dev/null
echo 0 > ${GPIO_PATH}/value 2>/dev/null
sleep 0.3
echo 1 > ${GPIO_PATH}/value 2>/dev/null

exit 0
