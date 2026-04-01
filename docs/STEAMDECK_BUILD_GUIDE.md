# Building SIGINT-Deck on Steam Deck from Scratch

This guide covers installing Rust and all build dependencies on a Steam Deck running SteamOS 3.x, and compiling sigint-deck from source.

## SteamOS Filesystem Overview

SteamOS uses an **immutable (read-only) root filesystem**. This means:

- `/usr`, `/lib`, `/bin` are read-only by default
- System packages installed with `pacman` are **wiped on every SteamOS update**
- Your home directory (`/home/deck`) is writable and persists across updates
- You must run `sudo steamos-readonly disable` before installing system packages

**Strategy**: Install Rust and cargo to `~/.cargo` (survives updates). Install system libraries to `/usr` (must re-run after SteamOS updates). Build artifacts and binaries go to `~/sigint-deck/`.

---

## Step 1: Set a sudo Password

If you haven't already, set a password for the `deck` user:

```bash
passwd
```

## Step 2: Disable Read-Only Filesystem

```bash
sudo steamos-readonly disable
```

You'll need to re-enable this when done:
```bash
sudo steamos-readonly enable
```

## Step 3: Initialize the Pacman Keyring

SteamOS ships with pacman but the keyring may not be initialized:

```bash
sudo pacman-key --init
sudo pacman-key --populate archlinux
sudo pacman-key --populate holo
```

If you get GPG errors during package install, run:
```bash
sudo pacman-key --refresh-keys
```

## Step 4: Install Build Dependencies

```bash
sudo pacman -Sy --needed \
    base-devel \
    openssl \
    pkg-config \
    sqlite \
    bluez \
    bluez-utils \
    wireless_tools \
    iw \
    python \
    curl \
    git \
    usbutils
```

These provide the C compilers, linkers, and development headers that Rust crates need to compile native code (OpenSSL, SQLite, Bluetooth, etc.).

**Note**: `base-devel` includes `gcc`, `make`, `binutils`, `fakeroot`, and other essential build tools.

## Step 5: Install Rust

Rust installs entirely into `~/.cargo/` and `~/.rustup/`, which are on the writable home partition. This **survives SteamOS updates**.

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
```

Load it into your current shell:
```bash
source ~/.cargo/env
```

Add it permanently to your shell profile:
```bash
echo 'source ~/.cargo/env' >> ~/.bash_profile
```

Verify:
```bash
rustc --version    # Should show 1.75+ (1.94+ recommended)
cargo --version
```

## Step 6: Install SDR Tools

### RTL-SDR (from pacman)
```bash
sudo pacman -Sy --needed rtl-sdr
```

### rtl_433 (ISM band decoder)

If not available via pacman, build from source:
```bash
sudo pacman -Sy --needed cmake
cd /tmp
git clone https://github.com/merbanan/rtl_433.git
cd rtl_433 && mkdir build && cd build
cmake .. && make -j4
cp src/rtl_433 ~/bin/
cd ~ && rm -rf /tmp/rtl_433
```

### HackRF
```bash
sudo pacman -Sy --needed hackrf
```

### Kalibrate-RTL (cell tower scanner)

Build from source (not in pacman):
```bash
cd /tmp
git clone https://github.com/steve-m/kalibrate-rtl.git
cd kalibrate-rtl
./bootstrap && ./configure && make -j4
cp src/kal ~/bin/
cd ~ && rm -rf /tmp/kalibrate-rtl
```

**Note**: kalibrate-rtl requires `autoconf`, `automake`, `libtool`, and `fftw` (all part of `base-devel` or installable via pacman).

### Add ~/bin to PATH
```bash
mkdir -p ~/bin
echo 'export PATH="$HOME/bin:$HOME/.local/bin:$PATH"' >> ~/.bash_profile
source ~/.bash_profile
```

## Step 7: Configure SDR Device Access

### Blacklist the DVB-T kernel driver
The default `dvb_usb_rtl28xxu` driver claims RTL-SDR devices. Blacklist it:

```bash
echo "blacklist dvb_usb_rtl28xxu" | sudo tee /etc/modprobe.d/blacklist-rtlsdr.conf
echo "blacklist rtl2832" | sudo tee -a /etc/modprobe.d/blacklist-rtlsdr.conf
```

### Add udev rules
```bash
sudo tee /etc/udev/rules.d/20-rtlsdr.rules > /dev/null << 'EOF'
SUBSYSTEM=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="2838", MODE="0666"
SUBSYSTEM=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="2832", MODE="0666"
SUBSYSTEM=="usb", ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="6089", MODE="0666"
EOF
sudo udevadm control --reload-rules
sudo udevadm trigger
```

### Add user to SDR groups
```bash
# SteamOS uses 'rtlsdr' group for RTL-SDR devices
sudo usermod -aG rtlsdr deck 2>/dev/null
sudo usermod -aG plugdev deck 2>/dev/null
sudo usermod -aG dialout deck 2>/dev/null
```

**You must log out and back in (or reboot) for group changes to take effect.**

## Step 8: Re-Enable Read-Only Filesystem

```bash
sudo steamos-readonly enable
```

## Step 9: Clone and Build SIGINT-Deck

```bash
git clone https://github.com/naanprofit/sigint-deck.git ~/sigint-deck
cd ~/sigint-deck
cargo build --release
```

Build time: ~3-5 minutes on the Steam Deck's Zen 2 APU.

The binary will be at `target/release/sigint-deck`. Copy it to the install directory:

```bash
cp target/release/sigint-deck ~/sigint-deck/sigint-deck
```

### Set network capabilities

Without this, WiFi monitor mode won't work:

```bash
sudo setcap cap_net_raw,cap_net_admin+eip ~/sigint-deck/sigint-deck
```

## Step 10: Run

```bash
cd ~/sigint-deck
SIGINT_ACCEPT_DISCLAIMER=1 ./sigint-deck
```

Web UI: `http://<deck-ip>:8085`

### Run as a systemd user service

```bash
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/sigint-deck.service << EOF
[Unit]
Description=SIGINT-Deck Security Monitor
After=network.target

[Service]
Type=simple
WorkingDirectory=/home/deck/sigint-deck
Environment=SIGINT_ACCEPT_DISCLAIMER=1
Environment=RUST_LOG=info
Environment=PATH=/home/deck/.cargo/bin:/home/deck/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=/home/deck/sigint-deck/sigint-deck
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable sigint-deck
systemctl --user start sigint-deck
loginctl enable-linger deck    # Start services at boot without login
```

---

## Surviving SteamOS Updates

When SteamOS updates, the read-only partition is re-imaged. This means:

**Persists (in /home/deck):**
- Rust toolchain (~/.cargo, ~/.rustup)
- sigint-deck binary and config (~~/sigint-deck)
- Python venv (~/sigint-deck/venv)
- Systemd user services (~/.config/systemd/user/)
- ~/bin tools built from source
- Shell profile changes (~/.bash_profile)

**Lost (must re-run):**
- System packages from pacman (base-devel, openssl, rtl-sdr, hackrf, etc.)
- Udev rules (/etc/udev/rules.d/)
- Modprobe blacklists (/etc/modprobe.d/)
- Group membership changes

**After a SteamOS update, run:**
```bash
sudo steamos-readonly disable
sudo pacman -Sy --needed base-devel openssl pkg-config sqlite bluez wireless_tools iw rtl-sdr hackrf
echo "blacklist dvb_usb_rtl28xxu" | sudo tee /etc/modprobe.d/blacklist-rtlsdr.conf
echo "blacklist rtl2832" | sudo tee -a /etc/modprobe.d/blacklist-rtlsdr.conf
sudo tee /etc/udev/rules.d/20-rtlsdr.rules > /dev/null << 'EOF'
SUBSYSTEM=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="2838", MODE="0666"
SUBSYSTEM=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="2832", MODE="0666"
SUBSYSTEM=="usb", ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="6089", MODE="0666"
EOF
sudo udevadm control --reload-rules
sudo usermod -aG rtlsdr,plugdev,dialout deck
sudo setcap cap_net_raw,cap_net_admin+eip ~/sigint-deck/sigint-deck
sudo steamos-readonly enable
```

Or simply re-run the install script which does all of this:
```bash
cd ~/sigint-deck && bash scripts/install-deck.sh
```

---

## Troubleshooting

### "error: linker cc not found"
```bash
sudo steamos-readonly disable
sudo pacman -Sy base-devel
sudo steamos-readonly enable
```

### "failed to run custom build command for openssl-sys"
```bash
sudo steamos-readonly disable
sudo pacman -Sy openssl pkg-config
sudo steamos-readonly enable
```

### "rtl_sdr: command not found" or "rtl_power: usb_open error -3"
```bash
# Add user to rtlsdr group
sudo usermod -aG rtlsdr deck
# Log out and back in, then verify:
groups | grep rtlsdr
```

### RTL-SDR "PLL not locked" warnings
This is normal on some devices. The scan data is still valid. The software accepts scan results even when rtl_power exits with code 1 due to PLL warnings.

### "Permission denied" on WiFi monitor mode
```bash
sudo setcap cap_net_raw,cap_net_admin+eip ~/sigint-deck/sigint-deck
```

### Binary crashes after SteamOS update
The binary itself is fine (it's in /home), but the shared libraries it links against may have changed. Rebuild:
```bash
sudo steamos-readonly disable
sudo pacman -Sy --needed base-devel openssl sqlite
sudo steamos-readonly enable
cd ~/sigint-deck && cargo build --release && cp target/release/sigint-deck ./
sudo setcap cap_net_raw,cap_net_admin+eip ~/sigint-deck/sigint-deck
```

### Pacman "invalid or corrupted package (PGP signature)"
```bash
sudo pacman-key --init
sudo pacman-key --populate archlinux holo
sudo pacman -Sy
```
