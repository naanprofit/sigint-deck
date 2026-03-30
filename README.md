# SIGINT-Deck

Portable signals intelligence and security monitoring for Steam Deck.

> **LEGAL DISCLAIMER**: This tool is for authorized security research and educational purposes only. Monitoring wireless communications without authorization may be illegal in your jurisdiction. You are solely responsible for ensuring your use complies with all applicable laws.

## Features

- **WiFi Monitoring** (802.11)
  - Device detection and tracking
  - Probe request analysis  
  - Signal strength monitoring (RSSI)
  - Attack detection (deauth, evil twin, KARMA)
  - PCAP capture for forensics

- **Bluetooth/BLE Monitoring**
  - BLE advertisement scanning
  - AirTag/Tile/SmartTag tracker detection with extended data
  - Device type classification (Phone, Wearable, SmartLight, etc.)
  - Lost mode and separated device detection

- **Tracker Intelligence**
  - Detects Find My network devices (Apple AirTags)
  - Extracts status byte, counter, key hints
  - Identifies lost mode and separated-from-owner states

- **AI/LLM Integration** (Optional)
  - Device analysis via local or cloud LLM
  - Support for llama.cpp, Ollama, LMStudio, OpenAI
  - Threat intelligence with 100+ surveillance equipment OUIs

- **GPS Integration**
  - Location tracking with USB GPS
  - Geofencing with alerts

- **Device Learning & Anomaly Detection**
  - Learns baseline of normal devices over time
  - Flags new/unknown devices immediately
  - Detects anomalous behavior patterns
  - Device fingerprinting (survives MAC randomization)
  - Configurable training period (default: 1 hour)

- **Multi-Channel Alerts**
  - Sound alerts with Ninja Mode
  - Telegram, Signal, Email, MQTT
  - Custom webhooks

## Hardware Requirements

> **IMPORTANT**: Steam Deck's internal WiFi does NOT support monitor mode!

| Component | Recommendation | Notes |
|-----------|---------------|-------|
| Steam Deck | LCD or OLED | Main platform |
| USB WiFi | Alfa AWUS036ACHM | Monitor mode required |
| USB GPS | VK-162 u-blox 7 | Optional |
| USB Hub | Powered | Recommended |

## Quick Start

### 1. Enable Developer Mode

```bash
# On Steam Deck, switch to Desktop Mode
# Settings → System → Enable Developer Mode
# Open Konsole and set password:
passwd
```

### 2. Clone and Setup

```bash
git clone https://github.com/naanprofit/sigint-deck.git
cd sigint-deck

# Run setup script
chmod +x steamdeck/setup-steamdeck.sh
./steamdeck/setup-steamdeck.sh
```

### 3. Configure

```bash
cp config.toml.example ~/sigint-deck/config.toml
nano ~/sigint-deck/config.toml
```

Key settings:
- `wifi.interface` - External WiFi adapter (usually `wlan1`)
- `gps.enabled` - Enable if GPS connected
- `alerts.*` - Configure notification channels

### 4. Start

```bash
~/sigint-deck/start-sigint.sh
```

Dashboard: http://localhost:8080

## WiFi Interface Setup

The setup script ensures persistent naming:
- `wlan0` = Internal Steam Deck WiFi (managed)
- `wlan1` = External USB WiFi (monitor mode)

## Web Dashboard

Features:
- Real-time device lists (WiFi + BLE)
- **New Devices** tab - combined view of devices seen in last 60 seconds
- Tracker detection with status badges
- Attack alerts
- GPS location
- Settings management

### Keyboard Shortcuts

| Key | Action |
|-----|--------|
| 1 | WiFi tab |
| 2 | BLE tab |
| 3 | New devices |
| 4 | Alerts |
| 5 | Attacks |
| N | Toggle Ninja Mode |

## PCAP Capture

```bash
# Start capture via API
curl -X POST http://localhost:8080/api/pcap/start

# Check status
curl http://localhost:8080/api/pcap/status

# Stop capture
curl -X POST http://localhost:8080/api/pcap/stop

# List capture files
curl http://localhost:8080/api/pcap/files
```

## Geofencing

```bash
# Set home location
curl -X POST http://localhost:8080/api/geofence/home \
  -H "Content-Type: application/json" \
  -d '{"latitude": 40.7128, "longitude": -74.0060, "radius_m": 100}'

# Check status
curl http://localhost:8080/api/geofence/status
```

## Settings

Settings are saved to `~/sigint-deck/config.toml`:

```bash
# Save settings via API
curl -X POST http://localhost:8080/api/settings \
  -H "Content-Type: application/json" \
  -d @settings.json
```

## Systemd Service

```bash
# Start
systemctl --user start sigint-deck

# Stop  
systemctl --user stop sigint-deck

# Enable on boot
systemctl --user enable sigint-deck
loginctl enable-linger deck

# Logs
journalctl --user -u sigint-deck -f
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/status` | GET | System status |
| `/api/wifi/devices` | GET | WiFi devices |
| `/api/ble/devices` | GET | BLE devices |
| `/api/alerts` | GET | Recent alerts |
| `/api/settings` | GET/POST | Settings |
| `/api/pcap/start` | POST | Start PCAP |
| `/api/pcap/stop` | POST | Stop PCAP |
| `/api/geofence/home` | POST | Set geofence |

## OUI Database

Includes 500+ vendor entries:
- Consumer devices (Apple, Samsung, Intel, etc.)
- IoT/Smart Home (MELK LED strips, Govee, Philips Hue, etc.)
- Threat intel (Harris/Stingray, Hikvision, Dahua, etc.)

## Device Learning

SIGINT-Deck learns your environment over time:

### Training Period
```toml
[learning]
enabled = true
training_hours = 1    # Hours to establish baseline
anomaly_threshold = 0.7
```

### What Happens
1. **During Training**: Collects device data, no anomaly alerts
2. **After Training**: Known devices become baseline, new devices flagged
3. **Location Change**: GPS detects movement > 100m, resets training

### Anomaly Detection
After training, devices are scored for unusual behavior:
- Signal strength deviation
- Unusual time of appearance  
- Behavioral pattern changes

Score > 0.7 triggers alert.

### Device Fingerprinting
Creates behavioral profiles that survive MAC randomization:
- Probe request patterns
- Time-of-day patterns
- Associated networks
- Device classification (Phone, Laptop, IoT, etc.)

## Troubleshooting

### WiFi adapter not in monitor mode
```bash
sudo ip link set wlan1 down
sudo iw wlan1 set type monitor
sudo ip link set wlan1 up
```

### GPS not detecting
```bash
# Check device
lsusb | grep -i u-blox
ls -la /dev/ttyACM*

# Start gpsd
sudo gpsd /dev/ttyACM0 -F /var/run/gpsd.sock
```

### Dashboard shows disconnected
```bash
# Check service
systemctl --user status sigint-deck

# Check API
curl http://localhost:8080/api/status
```

## Legal Notice

This software is for **authorized security research only**.

- Only use on networks/devices you own or have permission to monitor
- Unauthorized interception is illegal in most jurisdictions
- You are solely responsible for legal compliance

## License

MIT License

## Repository

https://github.com/naanprofit/sigint-deck
