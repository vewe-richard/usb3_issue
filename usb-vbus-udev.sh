#!/bin/bash
# USB VBUS timing fix - triggered by udev on USB device detection
# Fixes USB-C orientation detection by toggling VBUS

VBUS_GPIO=611

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
