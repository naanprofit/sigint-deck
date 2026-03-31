# Changelog

## [0.2.2] - 2026-03-31

### Fixed
- **GPS Retry Loop**: Fixed infinite fast retry when gpsd is unavailable
  - Added exponential backoff (5s initial, doubling up to 300s max)
  - GPS module now checks config.enabled flag and sleeps forever if disabled
  - Reduced log spam after 4 consecutive failures (switches to debug level)
  - Fast-fail connection test before spawning reader thread

### Added
- **Comprehensive Hardware Documentation** (`docs/PI_REQUIREMENTS.md`)
  - Complete list of supported hardware (WiFi, BLE, GPS, SDR, RayHunter)
  - System package requirements for Raspberry Pi
  - USB device summary and configuration files
  - Quick hardware check commands

- **Pi Setup Scripts**
  - `scripts/pi-gps-setup.sh` - U-blox U7 GPS configuration with udev rules
  - `scripts/pi-full-setup.sh` - Complete system setup including:
    - WiFi tools (aircrack-ng, iw)
    - Bluetooth (bluez)
    - GPS (gpsd)
    - SDR tools (rtl-sdr, rtl_433, kalibrate-rtl, hackrf)
    - RayHunter support (adb)
    - Pi optimizations (GPU memory, swap)
    - Systemd service configuration

- **Docker Image Enhancements**
  - Added SDR tools to runtime images (Pi and Steam Deck):
    - rtl-sdr, rtl_433
    - hackrf (where available)
    - kalibrate-rtl (built from source)
    - adb for RayHunter
    - aircrack-ng for WiFi
  - Added udev rules for SDR devices

### Hardware Support
- **WiFi**: External USB adapters with monitor mode (Alfa AWUS036ACHM, RTL8812AU)
- **Bluetooth/BLE**: Built-in Pi Bluetooth for AirTag/tracker detection
- **GPS**: U-blox U7 via gpsd (VK-172, G-Mouse)
- **RTL-SDR**: ISM band monitoring with rtl_433
- **HackRF One**: Wideband spectrum analysis, drone detection
- **LimeSDR**: Advanced SDR applications
- **RayHunter**: IMSI catcher detection via Android phone + ADB

### Configuration Notes
- GPS can be disabled in config.toml to prevent any connection attempts
- Bluetooth must be unblocked via rfkill on Pi (`sudo rfkill unblock bluetooth`)
- Web server must be explicitly enabled (`[web] enabled = true`)
- WiFi scanner expects external adapter on wlan1 (not built-in wlan0)

### Deployment Notes
- Binary size: ~12MB (ARM64)
- Docker image size: ~340MB (Pi ARM64 with SDR tools)
- Tested on Raspberry Pi Zero 2 W (Debian Bookworm)

## [0.2.1] - Previous Release

### Features
- Multi-platform support (Steam Deck, Raspberry Pi)
- WiFi monitoring with monitor mode
- BLE scanning with AirTag detection
- GPS integration via gpsd
- SDR framework (RTL-SDR, HackRF, LimeSDR)
- RayHunter IMSI catcher detection
- OpenClaw mesh networking
- Meshtastic LoRa integration
- Web UI dashboard
- Alert system (Telegram, Twilio, Email, MQTT)
