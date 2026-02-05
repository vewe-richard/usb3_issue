# Raspberry Pi CM5 USB-C Orientation Detection Fix

Automatic fix for USB-C orientation detection issue on Raspberry Pi CM5, where one cable orientation falls back to USB 2.0 (480Mbps) instead of USB 3.1 SuperSpeed (5Gbps).

## Problem Description

**Hardware:** Raspberry Pi CM5 (Debian 13, kernel 6.12.62+rpt-rpi-2712)

**Issue:** USB-C port only supports USB 3.1 SuperSpeed in one plug orientation; the other orientation falls back to USB 2.0 (480Mbps).

**Root Cause:** GPIO 611 (USB_VBUS_EN) is enabled by the bootloader before the CC (Configuration Channel) logic can properly detect cable orientation and configure the USB 3.0 signal path.

**Observable Behavior:**
- ✅ Working orientation: Device appears on Bus 005 (SuperSpeed 5Gbps)
- ❌ Failing orientation: Device appears on Bus 004 (High-speed 480Mbps)

## Solution

This fix uses a **udev rule** that automatically triggers when a USB device is detected at 480Mbps on Bus 004. The script toggles GPIO 611 (VBUS) with a 500ms delay, allowing proper CC detection and USB 3.0 negotiation.

### How It Works

1. USB device plugged in wrong orientation → detected on Bus 004 at 480Mbps
2. Udev rule triggers the fix script
3. Script disables VBUS (GPIO 611 = 0)
4. Waits 500ms for CC detection to stabilize
5. Re-enables VBUS (GPIO 611 = 1)
6. Device reconnects on Bus 005 at 5000Mbps (USB 3.1 SuperSpeed)

## Installation

### Quick Install

```bash
cd /tmp
git clone https://github.com/YOUR_USERNAME/rpi-cm5-usb-fix.git
cd rpi-cm5-usb-fix
sudo ./install.sh
```

### Manual Install

1. Copy the udev script:
```bash
sudo cp usb-vbus-udev.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/usb-vbus-udev.sh
```

2. Install the udev rule:
```bash
sudo cp 99-usb-vbus-fix.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
```

3. Test by plugging in a USB device in both orientations.

## Verification

Check USB device speed:
```bash
lsusb -t
```

Both cable orientations should show:
```
/:  Bus 005.Port 001: Dev 001, Class=root_hub, Driver=xhci-hcd/1p, 5000M
    |__ Port 001: Dev XXX, If 0, Class=Mass Storage, Driver=uas, 5000M
```

## Uninstallation

```bash
sudo rm /usr/local/bin/usb-vbus-udev.sh
sudo rm /etc/udev/rules.d/99-usb-vbus-fix.rules
sudo udevadm control --reload-rules
```

## Technical Details

- **GPIO**: 611 (USB_VBUS_EN)
- **Delay**: 500ms for CC detection stabilization
- **Trigger**: Udev rule on USB device detection at 480Mbps on Bus 004
- **Effect**: Automatic reconnection at USB 3.1 SuperSpeed (5Gbps)

## Tested Hardware

- Raspberry Pi CM5 (Debian 13, kernel 6.12.62+rpt-rpi-2712)
- Test device: Realtek RTL9210 USB NVMe adapter

## Files

- `usb-vbus-udev.sh` - VBUS toggle script
- `99-usb-vbus-fix.rules` - Udev rule for automatic triggering
- `install.sh` - Automated installation script
- `uninstall.sh` - Automated uninstallation script

## Troubleshooting

### Device still at 480Mbps after plugging in

Check if udev rule triggered:
```bash
journalctl -f
# Then plug in the device and watch for udev events
```

### Manually trigger the fix

```bash
sudo /usr/local/bin/usb-vbus-udev.sh
```

### Check GPIO status

```bash
sudo cat /sys/kernel/debug/gpio | grep -A2 "gpio-611"
```

## License

MIT License - See LICENSE file for details

## Contributing

Issues and pull requests welcome!

## Acknowledgments

- Original issue investigation: Jiang
- Hardware: Raspberry Pi CM5 Distiller system
