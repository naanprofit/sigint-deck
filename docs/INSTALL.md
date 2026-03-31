# SIGINT-Deck Installation Guide

Complete installation instructions for Raspberry Pi and Steam Deck.

---

## Table of Contents

1. [Quick Install](#quick-install)
2. [Raspberry Pi Installation](#raspberry-pi-installation)
3. [Steam Deck Installation](#steam-deck-installation)
4. [SDR Tools Installation](#sdr-tools-installation)
5. [Post-Installation Setup](#post-installation-setup)
6. [Troubleshooting](#troubleshooting)
7. [Updating](#updating)

---

## Quick Install

### Raspberry Pi (One-liner)
```bash
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/sigint-deck/main/install-pi.sh | bash
```

### Steam Deck (One-liner)
```bash
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/sigint-deck/main/steamdeck/install-steamdeck.sh | bash
```

---

## Raspberry Pi Installation

### Prerequisites

- Raspberry Pi Zero 2 W, Pi 3, Pi 4, or Pi 5
- Raspberry Pi OS Lite (64-bit recommended)
- MicroSD card (16GB+)
- USB WiFi adapter with monitor mode support
- (Optional) USB GPS receiver
- (Optional) RTL-SDR dongle
- (Optional) HackRF One

### Step 1: Prepare the Pi

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y \
    git \
    curl \
    wireless-tools \
    iw \
    aircrack-ng \
    bluez \
    bluetooth \
    gpsd \
    gpsd-clients
```

### Step 2: Install SDR Tools

```bash
# Download and run the SDR installer
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/sigint-deck/main/scripts/install-sdr-pi.sh
chmod +x install-sdr-pi.sh
./install-sdr-pi.sh --all

# This installs:
# - rtl-sdr (rtl_sdr, rtl_fm, rtl_power, rtl_tcp)
# - rtl_433 (ISM band decoder)
# - hackrf (if HackRF detected)
# - kalibrate-rtl (cell tower scanner)
```

### Step 3: Download Binary

**Option A: Download pre-built binary**
```bash
# Download latest ARM64 binary
curl -LO https://github.com/YOUR_USERNAME/sigint-deck/releases/latest/download/sigint-deck-arm64
chmod +x sigint-deck-arm64
sudo mv sigint-deck-arm64 /usr/local/bin/sigint-deck
```

**Option B: Build from source**
```bash
# See BUILD.md for detailed instructions
git clone https://github.com/YOUR_USERNAME/sigint-deck.git
cd sigint-deck
cargo build --release
sudo cp target/release/sigint-deck /usr/local/bin/
```

### Step 4: Install Static Files

```bash
# Create directories
sudo mkdir -p /var/lib/sigint-pi
sudo mkdir -p /usr/share/sigint-deck

# Copy static files
git clone https://github.com/YOUR_USERNAME/sigint-deck.git /tmp/sigint-deck
sudo cp -r /tmp/sigint-deck/static /usr/share/sigint-deck/
sudo cp /tmp/sigint-deck/config.toml.example /var/lib/sigint-pi/config.toml
```

### Step 5: Set Capabilities

```bash
# Allow WiFi capture without root
sudo setcap cap_net_raw,cap_net_admin+eip /usr/local/bin/sigint-deck
```

### Step 6: Setup WiFi Monitor Mode

```bash
# Identify your external WiFi adapter
iw dev

# Assuming wlan1 is your monitor-capable adapter
sudo ip link set wlan1 down
sudo iw wlan1 set type monitor
sudo ip link set wlan1 up

# Verify
iw wlan1 info  # Should show "type monitor"
```

### Step 7: Create Systemd Service

```bash
sudo tee /etc/systemd/system/sigint-pi.service > /dev/null << 'EOF'
[Unit]
Description=SIGINT-Pi Monitoring Service
After=network.target bluetooth.target

[Service]
Type=simple
ExecStart=/usr/local/bin/sigint-deck --config /var/lib/sigint-pi/config.toml
WorkingDirectory=/var/lib/sigint-pi
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable sigint-pi
sudo systemctl start sigint-pi

# Check status
sudo systemctl status sigint-pi
```

### Step 8: Access Web UI

```bash
# Find your Pi's IP
hostname -I

# Access from browser
# http://<pi-ip>:8080
```

---

## Steam Deck Installation

### Prerequisites

- Steam Deck (LCD or OLED)
- USB-C hub (recommended)
- USB WiFi adapter with monitor mode (internal WiFi does NOT support monitor mode)
- (Optional) USB GPS, RTL-SDR, HackRF

### Step 1: Enable Developer Mode

1. Switch to Desktop Mode (hold Power → Desktop Mode)
2. Open Konsole
3. Set a password: `passwd`

### Step 2: Install Dependencies

```bash
# Temporarily disable read-only filesystem
sudo steamos-readonly disable

# Install packages
sudo pacman -S --needed base-devel rust wireless_tools bluez

# Re-enable read-only (optional)
sudo steamos-readonly enable
```

### Step 3: Install SDR Tools

```bash
# Download installer
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/sigint-deck/main/scripts/install-sdr.sh
chmod +x install-sdr.sh
./install-sdr.sh --all

# Add to PATH (tools install to ~/bin)
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH="$HOME/bin/lib:$LD_LIBRARY_PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Step 4: Download/Build Binary

**Option A: Download pre-built**
```bash
curl -LO https://github.com/YOUR_USERNAME/sigint-deck/releases/latest/download/sigint-deck-x86_64
chmod +x sigint-deck-x86_64
mv sigint-deck-x86_64 ~/bin/sigint-deck
```

**Option B: Build natively**
```bash
git clone https://github.com/YOUR_USERNAME/sigint-deck.git
cd sigint-deck
cargo build --release
cp target/release/sigint-deck ~/bin/
```

### Step 5: Install Static Files

```bash
mkdir -p ~/sigint-deck
cp -r static ~/sigint-deck/
cp config.toml.example ~/sigint-deck/config.toml
```

### Step 6: Set Capabilities

```bash
sudo setcap cap_net_raw,cap_net_admin+eip ~/bin/sigint-deck
```

### Step 7: Setup Monitor Mode

```bash
# List interfaces
iw dev

# Set wlan1 to monitor mode (assuming external adapter)
sudo ip link set wlan1 down
sudo iw wlan1 set type monitor
sudo ip link set wlan1 up

# Optional: Channel hopping
sudo ~/sigint-deck/scripts/channel-hop.sh wlan1 &
```

### Step 8: Create User Service

```bash
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/sigint-deck.service << 'EOF'
[Unit]
Description=SIGINT-Deck
After=network.target

[Service]
Type=simple
ExecStart=%h/bin/sigint-deck --config %h/sigint-deck/config.toml
WorkingDirectory=%h/sigint-deck
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF

# Enable lingering (service runs without login)
loginctl enable-linger $USER

# Enable and start
systemctl --user daemon-reload
systemctl --user enable sigint-deck
systemctl --user start sigint-deck
```

### Step 9: Access Web UI

```bash
# Access from Deck's browser
# http://localhost:8080

# Or from another device on same network
hostname -I  # Get Deck's IP
# http://<deck-ip>:8080
```

---

## SDR Tools Installation

### Required Tools by Feature

| Feature | Required Tools |
|---------|---------------|
| RF Device Monitor | rtl_433 |
| Spectrum Analyzer | rtl_power or hackrf_sweep |
| Cell Tower Scanner | kalibrate-rtl (kal) |
| Drone Detection (RF) | hackrf_sweep |
| Drone Detection (EMI) | rtl_power with direct sampling |
| Radio Reception | rtl_fm |
| TSCM Sweeps | rtl_power + hackrf_sweep |

### Pi Installation

```bash
./scripts/install-sdr-pi.sh --all
```

### Steam Deck Installation

```bash
./scripts/install-sdr.sh --all
```

### Verify Installation

```bash
# RTL-SDR
rtl_test -t

# rtl_433
rtl_433 -G  # List supported devices

# HackRF
hackrf_info

# Kalibrate
kal -h
```

---

## Post-Installation Setup

### 1. Configure WiFi Interface

Edit config.toml:
```toml
[wifi]
interface = "wlan1"  # Your monitor-mode capable interface
channel_hop = true
hop_interval_ms = 500
```

### 2. Configure GPS (Optional)

```bash
# Start gpsd
sudo systemctl enable gpsd
sudo systemctl start gpsd

# Edit config.toml
[gps]
enabled = true
device = "/dev/ttyUSB0"  # Or /dev/ttyACM0
```

### 3. Configure Alerts (Optional)

```toml
[alerts]
sound_enabled = true
ninja_mode = false

[alerts.telegram]
enabled = true
bot_token = "YOUR_BOT_TOKEN"
chat_id = "YOUR_CHAT_ID"
```

### 4. Blacklist DVB-T Drivers

```bash
# These interfere with RTL-SDR
echo "blacklist dvb_usb_rtl28xxu" | sudo tee /etc/modprobe.d/blacklist-rtlsdr.conf
echo "blacklist rtl2832" | sudo tee -a /etc/modprobe.d/blacklist-rtlsdr.conf
```

### 5. Setup udev Rules

```bash
# RTL-SDR
echo 'SUBSYSTEM=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="2838", MODE:="0666"' | sudo tee /etc/udev/rules.d/rtl-sdr.rules

# HackRF
echo 'SUBSYSTEM=="usb", ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="6089", MODE:="0666"' | sudo tee /etc/udev/rules.d/53-hackrf.rules

sudo udevadm control --reload-rules
sudo udevadm trigger
```

---

## Troubleshooting

### WiFi Capture Not Working

```bash
# Check interface is in monitor mode
iw wlan1 info

# If not, set it:
sudo ip link set wlan1 down
sudo iw wlan1 set type monitor
sudo ip link set wlan1 up

# Check capabilities on binary
getcap /usr/local/bin/sigint-deck
# Should show: cap_net_admin,cap_net_raw=eip

# If not:
sudo setcap cap_net_raw,cap_net_admin+eip /usr/local/bin/sigint-deck
```

### rtl_433 Not Found

```bash
# Pi: Run installer
./scripts/install-sdr-pi.sh --rtl433

# Deck: Check PATH
echo $PATH  # Should include ~/bin
which rtl_433
```

### Kalibrate Not Working

```bash
# Install from source
cd /tmp
git clone https://github.com/steve-m/kalibrate-rtl.git
cd kalibrate-rtl
./bootstrap && ./configure && make
sudo make install
```

### Service Won't Start

```bash
# Check logs
sudo journalctl -u sigint-pi -f     # Pi
journalctl --user -u sigint-deck -f  # Deck

# Check config
sigint-deck --config /path/to/config.toml --check
```

### SDR Device Not Detected

```bash
# Check USB
lsusb | grep -i rtl    # RTL-SDR
lsusb | grep -i 1d50   # HackRF

# Unplug and replug device
# Check udev rules are loaded
sudo udevadm control --reload-rules
```

---

## Updating

### Update Binary

```bash
# Download latest
curl -LO https://github.com/YOUR_USERNAME/sigint-deck/releases/latest/download/sigint-deck-arm64

# Replace and set caps
sudo mv sigint-deck-arm64 /usr/local/bin/sigint-deck
sudo chmod +x /usr/local/bin/sigint-deck
sudo setcap cap_net_raw,cap_net_admin+eip /usr/local/bin/sigint-deck

# Restart service
sudo systemctl restart sigint-pi  # Pi
systemctl --user restart sigint-deck  # Deck
```

### Update Static Files

```bash
cd /tmp
git clone https://github.com/YOUR_USERNAME/sigint-deck.git
sudo cp -r sigint-deck/static/* /usr/share/sigint-deck/static/
```

### Update from Source

```bash
cd ~/sigint-deck
git pull
cargo build --release
sudo cp target/release/sigint-deck /usr/local/bin/
sudo setcap cap_net_raw,cap_net_admin+eip /usr/local/bin/sigint-deck
sudo systemctl restart sigint-pi
```
