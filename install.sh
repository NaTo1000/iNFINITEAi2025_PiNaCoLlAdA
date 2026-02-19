#!/bin/bash
#
# Installation script for PMKID Capture Tool
# WiFi Pineapple Nano Edition
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/pmkid"
DATA_DIR="/root/pmkid_captures"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  PMKID Capture Tool - Installation${NC}"
echo -e "${BLUE}  WiFi Pineapple Nano Edition${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR]${NC} Please run as root"
    exit 1
fi

# Update package list
echo -e "${GREEN}[INFO]${NC} Updating package list..."
opkg update

# Install dependencies
echo -e "${GREEN}[INFO]${NC} Installing dependencies..."

# Check and install required packages
PACKAGES="hcxtools hcxdumptool aircrack-ng"

for package in $PACKAGES; do
    if ! opkg list-installed | grep -q "^$package "; then
        echo -e "${YELLOW}[INFO]${NC} Installing $package..."
        opkg install $package || echo -e "${YELLOW}[WARN]${NC} Failed to install $package, may need manual installation"
    else
        echo -e "${GREEN}[OK]${NC} $package already installed"
    fi
done

# Create directories
echo -e "${GREEN}[INFO]${NC} Creating directories..."
mkdir -p "$CONFIG_DIR"
mkdir -p "$DATA_DIR"
mkdir -p "$INSTALL_DIR"

# Copy main script
echo -e "${GREEN}[INFO]${NC} Installing PMKID capture script..."
cp pmkid_capture.sh "$INSTALL_DIR/pmkid-capture"
chmod +x "$INSTALL_DIR/pmkid-capture"

# Create default configuration
echo -e "${GREEN}[INFO]${NC} Creating default configuration..."
cat > "$CONFIG_DIR/config.conf" << 'EOF'
# PMKID Capture Tool Configuration
# WiFi Pineapple Nano Edition

# Default wireless interface
INTERFACE=wlan1

# Output directory for captures
OUTPUT_DIR=/root/pmkid_captures

# Default capture timeout (seconds)
TIMEOUT=300

# Verbose logging (0 = off, 1 = on)
VERBOSE=0

# Auto-start on boot (0 = off, 1 = on)
AUTO_START=0
EOF

# Create helper scripts
echo -e "${GREEN}[INFO]${NC} Creating helper scripts..."

# Quick capture script
cat > "$INSTALL_DIR/pmkid-quick" << 'EOF'
#!/bin/bash
# Quick PMKID capture with default settings
pmkid-capture -i wlan1 -t 300 -v
EOF
chmod +x "$INSTALL_DIR/pmkid-quick"

# Scan only script
cat > "$INSTALL_DIR/pmkid-scan" << 'EOF'
#!/bin/bash
# Scan for nearby networks
pmkid-capture -i wlan1 -s
EOF
chmod +x "$INSTALL_DIR/pmkid-scan"

# Extended capture script
cat > "$INSTALL_DIR/pmkid-extended" << 'EOF'
#!/bin/bash
# Extended PMKID capture (10 minutes)
pmkid-capture -i wlan1 -t 600 -v
EOF
chmod +x "$INSTALL_DIR/pmkid-extended"

# Create uninstall script
cat > "$INSTALL_DIR/pmkid-uninstall" << 'EOF'
#!/bin/bash
echo "Uninstalling PMKID Capture Tool..."
rm -f /usr/local/bin/pmkid-capture
rm -f /usr/local/bin/pmkid-quick
rm -f /usr/local/bin/pmkid-scan
rm -f /usr/local/bin/pmkid-extended
rm -f /usr/local/bin/pmkid-uninstall
echo "PMKID Capture Tool uninstalled"
echo "Note: Configuration and capture data preserved in /etc/pmkid and /root/pmkid_captures"
EOF
chmod +x "$INSTALL_DIR/pmkid-uninstall"

# Create README in config directory
cat > "$CONFIG_DIR/README.txt" << 'EOF'
PMKID Capture Tool - WiFi Pineapple Nano Edition
================================================

Configuration file: /etc/pmkid/config.conf
Capture data directory: /root/pmkid_captures

Available commands:
  pmkid-capture      - Main capture tool with options
  pmkid-quick        - Quick 5-minute capture
  pmkid-scan         - Scan for networks only
  pmkid-extended     - Extended 10-minute capture
  pmkid-uninstall    - Uninstall the tool

Usage examples:
  pmkid-capture -i wlan1 -t 600 -v
  pmkid-quick
  pmkid-scan

For detailed help: pmkid-capture -h
EOF

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Installation Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Available commands:${NC}"
echo "  pmkid-capture      - Main capture tool"
echo "  pmkid-quick        - Quick capture (5 min)"
echo "  pmkid-scan         - Scan networks only"
echo "  pmkid-extended     - Extended capture (10 min)"
echo ""
echo -e "${BLUE}Quick start:${NC}"
echo "  pmkid-quick"
echo ""
echo -e "${BLUE}Configuration:${NC}"
echo "  Edit: $CONFIG_DIR/config.conf"
echo "  Logs: $DATA_DIR/pmkid.log"
echo ""
echo -e "${YELLOW}Note:${NC} This tool is for authorized security testing only!"
echo ""
