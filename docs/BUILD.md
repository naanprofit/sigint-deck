# Building SIGINT-Deck/SIGINT-Pi from Source

This guide covers building the application from source for all supported platforms.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Building for Raspberry Pi](#building-for-raspberry-pi)
3. [Building for Steam Deck](#building-for-steam-deck)
4. [Cross-Compilation](#cross-compilation)
5. [Docker Builds](#docker-builds)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Tools

| Tool | Version | Purpose |
|------|---------|---------|
| Rust | 1.70+ | Compiler |
| Cargo | 1.70+ | Package manager |
| Git | 2.x | Source control |
| GCC/Clang | Latest | C compiler (for dependencies) |
| pkg-config | Latest | Library detection |
| OpenSSL | 1.1+ | TLS support |

### Required Libraries

**Debian/Ubuntu/Raspberry Pi OS:**
```bash
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    pkg-config \
    libssl-dev \
    libasound2-dev \
    libdbus-1-dev \
    libudev-dev \
    libsqlite3-dev \
    bluetooth \
    libbluetooth-dev
```

**Arch Linux/Steam Deck:**
```bash
sudo pacman -S --needed \
    base-devel \
    openssl \
    alsa-lib \
    dbus \
    sqlite \
    bluez \
    bluez-libs
```

**macOS:**
```bash
brew install openssl pkg-config sqlite
```

### Installing Rust

```bash
# Install Rust via rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Add to PATH (or restart shell)
source $HOME/.cargo/env

# Verify installation
rustc --version
cargo --version
```

---

## Building for Raspberry Pi

### Native Build (On the Pi)

Building natively on a Raspberry Pi Zero 2 W is **very slow** (2-4 hours). Recommended only if cross-compilation isn't available.

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/sigint-deck.git
cd sigint-deck

# Install Rust (if not installed)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# Build release binary
cargo build --release

# Binary location
ls -la target/release/sigint-deck
```

**Optimization for Pi Zero 2 W:**
```bash
# Use fewer parallel jobs to avoid OOM
cargo build --release -j 1

# Or set in .cargo/config.toml
[build]
jobs = 1
```

### Cross-Compilation from Linux/Mac (Recommended)

Much faster - builds in 5-10 minutes instead of hours.

**Setup cross-compilation toolchain:**
```bash
# Add ARM64 target
rustup target add aarch64-unknown-linux-gnu

# Install cross-compiler (Ubuntu/Debian)
sudo apt-get install gcc-aarch64-linux-gnu

# Or use cross (Docker-based, works on any system)
cargo install cross
```

**Build with cross:**
```bash
# Using cross (easiest, uses Docker)
cross build --release --target aarch64-unknown-linux-gnu

# Binary location
ls -la target/aarch64-unknown-linux-gnu/release/sigint-deck
```

**Build with native cross-compiler:**
```bash
# Set linker in .cargo/config.toml or environment
export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-linux-gnu-gcc

# Build
cargo build --release --target aarch64-unknown-linux-gnu
```

### Deploy to Pi

```bash
# Copy binary to Pi
scp target/aarch64-unknown-linux-gnu/release/sigint-deck user@<pi-ip>:/home/user/

# Copy static files
scp -r static/ user@<pi-ip>:/home/user/sigint-deck/

# SSH to Pi and set capabilities
ssh user@<pi-ip>
sudo setcap cap_net_raw,cap_net_admin+eip /home/user/sigint-deck
```

---

## Building for Steam Deck

### Native Build (On the Deck)

Steam Deck can build natively - it's fast enough (3-5 minutes).

**Enable Developer Mode:**
1. Switch to Desktop Mode
2. Open Konsole
3. Set a password: `passwd`

**Install build tools:**
```bash
# Disable read-only filesystem temporarily
sudo steamos-readonly disable

# Install development packages
sudo pacman -S --needed base-devel rust

# Re-enable read-only (optional, will reset on update anyway)
sudo steamos-readonly enable
```

**Build:**
```bash
cd ~/sigint-deck
cargo build --release

# Binary location
ls -la target/release/sigint-deck
```

### Deploy on Deck

```bash
# Set capabilities for WiFi capture
sudo setcap cap_net_raw,cap_net_admin+eip target/release/sigint-deck

# Copy to persistent location
mkdir -p ~/bin
cp target/release/sigint-deck ~/bin/
cp -r static/ ~/sigint-deck/

# Create systemd user service
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/sigint-deck.service << 'EOF'
[Unit]
Description=SIGINT-Deck
After=network.target

[Service]
Type=simple
ExecStart=/home/deck/bin/sigint-deck --config /home/deck/sigint-deck/config.toml
WorkingDirectory=/home/deck/sigint-deck
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF

# Enable and start
systemctl --user daemon-reload
systemctl --user enable sigint-deck
systemctl --user start sigint-deck
```

---

## Cross-Compilation

### Using Docker (Recommended)

Docker provides consistent build environments across platforms.

**ARM64 (Raspberry Pi):**
```bash
# Build using provided Dockerfile
docker build -f docker/Dockerfile.pi -t sigint-pi-builder .

# Extract binary
docker create --name extract sigint-pi-builder
docker cp extract:/app/target/release/sigint-deck ./sigint-deck-arm64
docker rm extract

# Verify
file sigint-deck-arm64
# Should show: ELF 64-bit LSB executable, ARM aarch64
```

**x86_64 (Steam Deck):**
```bash
# Build using provided Dockerfile
docker build -f docker/Dockerfile.steamdeck -t sigint-deck-builder .

# Extract binary
docker create --name extract sigint-deck-builder
docker cp extract:/app/target/release/sigint-deck ./sigint-deck-x86_64
docker rm extract
```

### Using `cross` Tool

The `cross` tool uses Docker automatically:

```bash
# Install cross
cargo install cross

# Build for ARM64
cross build --release --target aarch64-unknown-linux-gnu

# Build for x86_64 (musl - static linking)
cross build --release --target x86_64-unknown-linux-musl
```

### Manual Cross-Compilation Setup

**For ARM64 from Ubuntu/Debian:**
```bash
# Install toolchain
sudo apt-get install gcc-aarch64-linux-gnu

# Add target
rustup target add aarch64-unknown-linux-gnu

# Create .cargo/config.toml
cat > .cargo/config.toml << 'EOF'
[target.aarch64-unknown-linux-gnu]
linker = "aarch64-linux-gnu-gcc"
EOF

# Build
cargo build --release --target aarch64-unknown-linux-gnu
```

---

## Docker Builds

### Dockerfile.pi (ARM64)

```dockerfile
FROM rust:1.75-bookworm

# Install ARM64 cross-compilation tools
RUN apt-get update && apt-get install -y \
    gcc-aarch64-linux-gnu \
    libc6-dev-arm64-cross \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Add ARM64 target
RUN rustup target add aarch64-unknown-linux-gnu

# Set cross-compilation environment
ENV CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-linux-gnu-gcc
ENV PKG_CONFIG_ALLOW_CROSS=1

WORKDIR /app
COPY . .

RUN cargo build --release --target aarch64-unknown-linux-gnu
```

### Dockerfile.steamdeck (x86_64)

```dockerfile
FROM rust:1.75-bookworm

RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    libasound2-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

RUN cargo build --release
```

### Build Commands

```bash
# ARM64 (Pi)
docker build -f docker/Dockerfile.pi -t sigint-pi .
ID=$(docker create sigint-pi)
docker cp $ID:/app/target/aarch64-unknown-linux-gnu/release/sigint-deck ./sigint-deck-arm64
docker rm $ID

# x86_64 (Deck)
docker build -f docker/Dockerfile.steamdeck -t sigint-deck .
ID=$(docker create sigint-deck)
docker cp $ID:/app/target/release/sigint-deck ./sigint-deck-x86_64
docker rm $ID
```

---

## Build Configuration

### Cargo.toml Optimization

For smaller/faster binaries:

```toml
[profile.release]
opt-level = 3
lto = true
codegen-units = 1
panic = "abort"
strip = true
```

### Feature Flags

```bash
# Build with specific features
cargo build --release --features "bluetooth,gps,sdr"

# Build minimal (no optional features)
cargo build --release --no-default-features
```

---

## Troubleshooting

### Common Build Errors

**Error: `openssl-sys` build failed**
```bash
# Install OpenSSL development files
sudo apt-get install libssl-dev pkg-config

# Or use vendored OpenSSL
cargo build --release --features openssl/vendored
```

**Error: `libasound` not found**
```bash
# Install ALSA development files
sudo apt-get install libasound2-dev
```

**Error: `bluetooth` crate build failed**
```bash
# Install Bluetooth development files
sudo apt-get install libbluetooth-dev bluetooth
```

**Error: Out of memory on Pi Zero**
```bash
# Reduce parallel jobs
cargo build --release -j 1

# Or increase swap
sudo dphys-swapfile swapoff
sudo sed -i 's/CONF_SWAPSIZE=.*/CONF_SWAPSIZE=2048/' /etc/dphys-swapfile
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```

**Error: Cross-compilation linker not found**
```bash
# Verify linker is installed
which aarch64-linux-gnu-gcc

# Install if missing
sudo apt-get install gcc-aarch64-linux-gnu
```

### Verifying the Build

```bash
# Check binary architecture
file target/release/sigint-deck

# Check dependencies
ldd target/release/sigint-deck

# Check size
ls -lh target/release/sigint-deck

# Test run (on target platform)
./sigint-deck --version
./sigint-deck --help
```

---

## Build Artifacts

After successful build:

| File | Location | Size (approx) |
|------|----------|---------------|
| Binary (ARM64) | `target/aarch64-unknown-linux-gnu/release/sigint-deck` | 12-15 MB |
| Binary (x86_64) | `target/release/sigint-deck` | 15-20 MB |
| Static files | `static/` | 500 KB |
| Config example | `config.toml.example` | 2 KB |

---

## Next Steps

After building:

1. See [INSTALL.md](INSTALL.md) for installation instructions
2. See [PI_QUICKSTART.md](PI_QUICKSTART.md) for Raspberry Pi setup
3. See [../steamdeck/README-STEAMDECK.md](../steamdeck/README-STEAMDECK.md) for Steam Deck setup
