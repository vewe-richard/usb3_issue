#!/bin/bash
# Installation script for Raspberry Pi CM5 USB-C orientation fix

set -e

echo "Installing Raspberry Pi CM5 USB-C Orientation Fix..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo: sudo ./install.sh"
    exit 1
fi

# Copy udev scripts
echo "Installing udev scripts..."
cp usb-vbus-udev.sh /usr/local/bin/
cp usb-vbus-cleanup.sh /usr/local/bin/
chmod +x /usr/local/bin/usb-vbus-udev.sh
chmod +x /usr/local/bin/usb-vbus-cleanup.sh

# Install udev rule
echo "Installing udev rule..."
cp 99-usb-vbus-fix.rules /etc/udev/rules.d/

# Reload udev rules
echo "Reloading udev rules..."
udevadm control --reload-rules
sync
echo ""
echo "✅ Installation complete!"
echo ""
echo "The fix will automatically trigger when a USB device is detected at 480Mbps."
echo "Test by plugging in a USB device in both orientations."
echo ""
echo "To verify: lsusb -t"
echo "Expected: Device on Bus 005 at 5000M in both orientations"
