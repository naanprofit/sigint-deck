#!/bin/bash
# SIGINT-Pi SDR Tools Installer
# Installs RTL-SDR, rtl_433, HackRF, kalibrate-rtl for Raspberry Pi OS
#
# Usage: ./install-sdr-pi.sh [--all|--rtlsdr|--rtl433|--hackrf|--kalibrate]

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════╗"
echo "║       SIGINT-Pi SDR Tools Installer           ║"
echo "║  RTL-SDR | rtl_433 | HackRF | kalibrate-rtl   ║"
echo "╚═══════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if running on Pi
if [[ ! -f /proc/device-tree/model ]] || ! grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
    echo -e "${YELLOW}Warning: This script is designed for Raspberry Pi${NC}"
    echo "Continuing anyway..."
fi

# Parse arguments
INSTALL_RTLSDR=false
INSTALL_RTL433=false
INSTALL_HACKRF=false
INSTALL_KALIBRATE=false
INSTALL_ALL=false

if [ $# -eq 0 ]; then
    INSTALL_ALL=true
fi

for arg in "$@"; do
    case $arg in
        --all) INSTALL_ALL=true ;;
        --rtlsdr) INSTALL_RTLSDR=true ;;
        --rtl433) INSTALL_RTL433=true ;;
        --hackrf) INSTALL_HACKRF=true ;;
        --kalibrate) INSTALL_KALIBRATE=true ;;
        --help|-h)
            echo "Usage: $0 [--all|--rtlsdr|--rtl433|--hackrf|--kalibrate]"
            echo ""
            echo "Options:"
            echo "  --all        Install all SDR tools (default)"
            echo "  --rtlsdr     Install RTL-SDR base tools"
            echo "  --rtl433     Install rtl_433 (ISM band decoder)"
            echo "  --hackrf     Install HackRF tools"
            echo "  --kalibrate  Install kalibrate-rtl (cell tower scanner)"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $arg${NC}"
            exit 1
            ;;
    esac
done

if $INSTALL_ALL; then
    INSTALL_RTLSDR=true
    INSTALL_RTL433=true
    INSTALL_HACKRF=true
    INSTALL_KALIBRATE=true
fi

# Update package lists
echo -e "${BLUE}Updating package lists...${NC}"
sudo apt-get update

# Install common dependencies
echo -e "${BLUE}Installing common dependencies...${NC}"
sudo apt-get install -y build-essential cmake git pkg-config libusb-1.0-0-dev

# ============================================
# RTL-SDR Base Tools
# ============================================
if $INSTALL_RTLSDR; then
    echo -e "\n${GREEN}[1/4] Installing RTL-SDR...${NC}"
    
    # Try apt first (faster)
    if sudo apt-get install -y rtl-sdr librtlsdr-dev 2>/dev/null; then
        echo -e "${GREEN}✓ RTL-SDR installed via apt${NC}"
    else
        # Build from source
        echo "Building RTL-SDR from source..."
        cd /tmp
        rm -rf rtl-sdr
        git clone https://github.com/osmocom/rtl-sdr.git
        cd rtl-sdr
        mkdir build && cd build
        cmake ../ -DINSTALL_UDEV_RULES=ON
        make -j$(nproc)
        sudo make install
        sudo ldconfig
        echo -e "${GREEN}✓ RTL-SDR built from source${NC}"
    fi
    
    # Blacklist DVB-T drivers (interfere with SDR)
    if ! grep -q "blacklist dvb_usb_rtl28xxu" /etc/modprobe.d/blacklist-rtlsdr.conf 2>/dev/null; then
        echo -e "${BLUE}Blacklisting DVB-T kernel drivers...${NC}"
        echo "blacklist dvb_usb_rtl28xxu" | sudo tee /etc/modprobe.d/blacklist-rtlsdr.conf
        echo "blacklist rtl2832" | sudo tee -a /etc/modprobe.d/blacklist-rtlsdr.conf
        echo "blacklist rtl2830" | sudo tee -a /etc/modprobe.d/blacklist-rtlsdr.conf
    fi
    
    echo "  Tools: rtl_sdr, rtl_fm, rtl_power, rtl_tcp, rtl_test"
fi

# ============================================
# rtl_433 - ISM Band Decoder
# ============================================
if $INSTALL_RTL433; then
    echo -e "\n${GREEN}[2/4] Installing rtl_433...${NC}"
    
    # Try apt first
    if sudo apt-get install -y rtl-433 2>/dev/null; then
        echo -e "${GREEN}✓ rtl_433 installed via apt${NC}"
    else
        # Build from source
        echo "Building rtl_433 from source..."
        cd /tmp
        rm -rf rtl_433
        git clone https://github.com/merbanan/rtl_433.git
        cd rtl_433
        mkdir build && cd build
        cmake ..
        make -j$(nproc)
        sudo make install
        echo -e "${GREEN}✓ rtl_433 built from source${NC}"
    fi
    
    echo "  Decodes: weather stations, tire pressure monitors, door sensors, etc."
    echo "  Frequencies: 315 MHz, 433 MHz, 868 MHz, 915 MHz"
fi

# ============================================
# HackRF Tools
# ============================================
if $INSTALL_HACKRF; then
    echo -e "\n${GREEN}[3/4] Installing HackRF...${NC}"
    
    # Try apt first
    if sudo apt-get install -y hackrf libhackrf-dev 2>/dev/null; then
        echo -e "${GREEN}✓ HackRF installed via apt${NC}"
    else
        # Build from source
        echo "Building HackRF from source..."
        cd /tmp
        rm -rf hackrf
        git clone https://github.com/greatscottgadgets/hackrf.git
        cd hackrf/host
        mkdir build && cd build
        cmake ..
        make -j$(nproc)
        sudo make install
        sudo ldconfig
        echo -e "${GREEN}✓ HackRF built from source${NC}"
    fi
    
    echo "  Tools: hackrf_info, hackrf_transfer, hackrf_sweep"
    echo "  Frequency range: 1 MHz - 6 GHz"
fi

# ============================================
# kalibrate-rtl - Cell Tower Scanner
# ============================================
if $INSTALL_KALIBRATE; then
    echo -e "\n${GREEN}[4/4] Installing kalibrate-rtl...${NC}"
    
    # Must build from source (not in apt)
    echo "Building kalibrate-rtl from source..."
    cd /tmp
    rm -rf kalibrate-rtl
    git clone https://github.com/steve-m/kalibrate-rtl.git
    cd kalibrate-rtl
    ./bootstrap
    ./configure
    make -j$(nproc)
    sudo make install
    echo -e "${GREEN}✓ kalibrate-rtl installed${NC}"
    
    echo "  Tool: kal"
    echo "  Usage: kal -s GSM850  (scan GSM 850 band)"
    echo "         kal -s GSM900  (scan GSM 900 band)"
fi

# ============================================
# udev rules for non-root access
# ============================================
echo -e "\n${BLUE}Setting up udev rules...${NC}"

# RTL-SDR udev rules
if [ ! -f /etc/udev/rules.d/rtl-sdr.rules ]; then
    cat << 'EOF' | sudo tee /etc/udev/rules.d/rtl-sdr.rules
# RTL-SDR
SUBSYSTEM=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="2832", MODE:="0666"
SUBSYSTEM=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="2838", MODE:="0666"
EOF
fi

# HackRF udev rules
if [ ! -f /etc/udev/rules.d/53-hackrf.rules ]; then
    cat << 'EOF' | sudo tee /etc/udev/rules.d/53-hackrf.rules
# HackRF
SUBSYSTEM=="usb", ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="6089", MODE:="0666"
SUBSYSTEM=="usb", ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="604b", MODE:="0666"
EOF
fi

sudo udevadm control --reload-rules
sudo udevadm trigger

# ============================================
# Verify Installation
# ============================================
echo -e "\n${GREEN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        SDR Installation Complete!              ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
echo ""
echo "Installed tools:"

if command -v rtl_test &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} rtl_sdr, rtl_fm, rtl_power, rtl_tcp, rtl_test"
fi

if command -v rtl_433 &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} rtl_433"
fi

if command -v hackrf_info &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} hackrf_info, hackrf_transfer, hackrf_sweep"
fi

if command -v kal &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} kal (kalibrate-rtl)"
fi

echo ""
echo -e "${YELLOW}IMPORTANT: Unplug and replug your SDR devices for udev rules to take effect${NC}"
echo ""
echo -e "${BLUE}Test your SDR hardware:${NC}"
echo "  rtl_test -t              # RTL-SDR"
echo "  rtl_433 -G               # rtl_433 (list supported devices)"
echo "  hackrf_info              # HackRF"
echo "  kal -s GSM850            # Cell tower scan"
echo ""
echo -e "${BLUE}Quick start commands:${NC}"
echo "  rtl_433 -f 433920000     # Monitor 433.92 MHz ISM band"
echo "  rtl_fm -f 162.55M -M fm  # Listen to NOAA weather"
echo "  hackrf_sweep -f 2400:2500 -w 500000  # Scan 2.4 GHz"
echo ""
