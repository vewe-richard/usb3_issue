#!/bin/bash
# USB VBUS timing fix - triggered by udev on USB device detection
# Fixes USB-C orientation detection by toggling VBUS
# Uses lockfile to prevent repeated triggers on same device

VBUS_GPIO=611
LOCKFILE="/tmp/usb-vbus-fix.lock"
LOCK_TIMEOUT=5  # seconds

# Get device info from udev environment
DEVPATH="$1"
VENDOR=""
PRODUCT=""
SERIAL=""

if [ -n "$DEVPATH" ]; then
    VENDOR=$(cat "$DEVPATH/idVendor" 2>/dev/null)
    PRODUCT=$(cat "$DEVPATH/idProduct" 2>/dev/null)
    SERIAL=$(cat "$DEVPATH/serial" 2>/dev/null)
fi

DEVICE_ID="${VENDOR}:${PRODUCT}:${SERIAL}"

# Check if we recently processed this device
if [ -f "$LOCKFILE" ]; then
    LOCK_AGE=$(($(date +%s) - $(stat -c %Y "$LOCKFILE" 2>/dev/null || echo 0)))
    LOCKED_DEVICE=$(cat "$LOCKFILE" 2>/dev/null)

    # If same device and lock is recent, skip
    if [ "$LOCKED_DEVICE" = "$DEVICE_ID" ] && [ "$LOCK_AGE" -lt "$LOCK_TIMEOUT" ]; then
        exit 0
    fi
fi

# Create lockfile for this device
echo "$DEVICE_ID" > "$LOCKFILE"

# Trigger the VBUS fix
# This will help USB 3.0 devices that are falling back to 480M
# USB 2.0 devices will reconnect at 480M (no harm, but won't trigger again due to lockfile)

# Use sysfs GPIO control
GPIO_PATH="/sys/class/gpio/gpio${VBUS_GPIO}"

# If GPIO is controlled by kernel module, skip
if [ -d "$GPIO_PATH" ] && grep -q "usb_vbus_en" /sys/kernel/debug/gpio 2>/dev/null; then
    # GPIO owned by module, use module approach
    rmmod usb_vbus_fix 2>/dev/null
    sleep 0.1
    insmod /lib/modules/$(uname -r)/kernel/drivers/usb/usb_vbus_fix.ko 2>/dev/null
    exit 0
fi

# Otherwise use sysfs approach
if [ ! -d "$GPIO_PATH" ]; then
    echo $VBUS_GPIO > /sys/class/gpio/export 2>/dev/null
    sleep 0.1
fi

echo out > ${GPIO_PATH}/direction 2>/dev/null
echo 0 > ${GPIO_PATH}/value 2>/dev/null
sleep 0.5
echo 1 > ${GPIO_PATH}/value 2>/dev/null

exit 0
