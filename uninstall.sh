#!/bin/bash
# Uninstallation script for Raspberry Pi CM5 USB-C orientation fix

set -e

echo "Uninstalling Raspberry Pi CM5 USB-C Orientation Fix..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo: sudo ./uninstall.sh"
    exit 1
fi

# Remove udev scripts
echo "Removing udev scripts..."
rm -f /usr/local/bin/usb-vbus-udev.sh
rm -f /usr/local/bin/usb-vbus-cleanup.sh

# Remove udev rule
echo "Removing udev rule..."
rm -f /etc/udev/rules.d/99-usb-vbus-fix.rules

# Reload udev rules
echo "Reloading udev rules..."
udevadm control --reload-rules

echo ""
echo "✅ Uninstallation complete!"
echo ""
echo "The USB-C orientation fix has been removed."
