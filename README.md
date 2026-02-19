# iFINITEAi2025_PiNeApPlErInGs

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

A complete ground-up rewrite of the WiFi Pineapple PMKID Attack module with AI-autonomous scanning, scalable parallel bots, and advanced configurability.

## Overview

**iFINITEAi2025_PiNeApPlErInGs** is a powerful, POSIX-compliant shell script for automated PMKID capture from WiFi access points. Originally inspired by [xchwarze/wifi-pineapple-community](https://github.com/xchwarze/wifi-pineapple-community), this complete rewrite addresses all limitations of the original script and adds powerful new capabilities:

- ✅ **AI Autonomous Mode**: Automatically scans, selects targets, captures PMKIDs, and retries on failure
- ✅ **Scalable Parallel Bots**: Configurable number of parallel capture workers
- ✅ **POSIX Compliant**: Works on OpenWrt, WiFi Pineapple, and standard Linux systems
- ✅ **Advanced Error Handling**: Fail-fast with `set -e`, proper signal handling, and graceful cleanup
- ✅ **Flexible Configuration**: All parameters configurable via environment variables
- ✅ **Target Filtering**: Whitelist/blacklist support for precise targeting
- ✅ **Comprehensive Logging**: Leveled logging (debug/info/warn/error) with timestamps
- ✅ **Retry Logic**: Configurable retry attempts with delays
- ✅ **Channel Hopping**: Automatic channel hopping for better coverage

## Features

### Core Capabilities
- Capture PMKID hashes from WPA2 access points
- Automatic detection of modern (`hcxpcapngtool`) and legacy (`hcxpcaptool`) tools
- Foreground and background operation modes
- Single-target and multi-target capture
- Hash extraction and reporting

### AI Autonomous Mode
The `auto` command implements a fully autonomous capture system:
1. Periodic scanning for nearby access points
2. Intelligent target selection based on signal strength and encryption
3. Parallel processing with configurable bot count
4. Automatic retry on failure
5. Continuous operation with periodic re-scanning
6. Comprehensive result tracking

### Scalable Bot Architecture
- Launch up to `PMKID_BOT_COUNT` parallel capture workers
- Each bot independently handles capture, retry, and extraction
- Dynamic bot pool management
- Clean PID tracking for all background processes

## Installation

### Prerequisites
- WiFi adapter in monitor mode
- `hcxdumptool` (for packet capture)
- `hcxpcapngtool` or `hcxpcaptool` (for PMKID extraction)
- Standard Unix utilities (`grep`, `sed`, `awk`, etc.)

### Quick Start
```bash
# Clone the repository
git clone https://github.com/NaTo1000/iNFINITEAi2025_PiNaCoLlAdA.git
cd iNFINITEAi2025_PiNaCoLlAdA

# Make the script executable
chmod +x scripts/PMKIDAttack.sh

# Run with default settings
./scripts/PMKIDAttack.sh scan
```

## Usage

### Basic Commands

#### Scan for Access Points
```bash
./scripts/PMKIDAttack.sh scan
```

#### Capture PMKID from Specific AP
```bash
# Foreground (blocks until complete)
./scripts/PMKIDAttack.sh start AA:BB:CC:DD:EE:FF

# Background (returns immediately)
./scripts/PMKIDAttack.sh start-bg AA:BB:CC:DD:EE:FF
```

#### Capture from All Nearby APs
```bash
./scripts/PMKIDAttack.sh start-all
```

#### Extract PMKID Hash
```bash
# From specific AP
./scripts/PMKIDAttack.sh check AA:BB:CC:DD:EE:FF

# From all captures
./scripts/PMKIDAttack.sh check-all
```

#### AI Autonomous Mode
```bash
# Start autonomous capture with default settings
./scripts/PMKIDAttack.sh auto

# Start with custom configuration
PMKID_BOT_COUNT=8 PMKID_TIMEOUT=180 ./scripts/PMKIDAttack.sh auto

# Stop autonomous mode
./scripts/PMKIDAttack.sh auto-stop
```

#### Status and Management
```bash
# Check running captures
./scripts/PMKIDAttack.sh status

# Stop all captures
./scripts/PMKIDAttack.sh stop

# Generate report
./scripts/PMKIDAttack.sh report

# Display configuration
./scripts/PMKIDAttack.sh config

# Clean up all files
./scripts/PMKIDAttack.sh clean
```

### All Available Commands

| Command | Description |
|---------|-------------|
| `start <BSSID>` | Capture PMKID for specific BSSID (foreground) |
| `start-bg <BSSID>` | Capture PMKID for specific BSSID (background) |
| `start-all` | Capture PMKIDs from all nearby APs (foreground) |
| `stop` | Stop all running captures |
| `status` | Check if capture is running |
| `check <BSSID>` | Extract PMKID hash from capture file |
| `check-bg <BSSID>` | Extract PMKID hash (background) |
| `check-all` | Extract all PMKID hashes |
| `check-all-bg` | Extract all hashes (background) |
| `scan` | Discover and list nearby APs |
| `auto` | AI autonomous mode - scan, capture, retry |
| `auto-stop` | Stop autonomous mode |
| `report` | Generate summary report |
| `clean` | Clean up temp files and captures |
| `config` | Display current configuration |

## Configuration

All configuration is done via environment variables. You can set them inline, export them, or use the provided example configuration file.

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PMKID_IFACE` | `wlan1mon` | Wireless interface (must be in monitor mode) |
| `PMKID_TIMEOUT` | `120` | Capture timeout in seconds |
| `PMKID_MAX_RETRIES` | `3` | Maximum retry attempts per target |
| `PMKID_RETRY_DELAY` | `5` | Delay between retries in seconds |
| `PMKID_BOT_COUNT` | `4` | Number of parallel capture bots |
| `PMKID_SCAN_INTERVAL` | `30` | Re-scan interval in seconds (autonomous mode) |
| `PMKID_LOG_LEVEL` | `info` | Logging verbosity: `debug`, `info`, `warn`, `error` |
| `PMKID_OUTPUT_DIR` | `/tmp/pmkid_results` | Output directory for captures and results |
| `PMKID_CHANNEL_HOP` | `1` | Enable/disable channel hopping: `1` or `0` |
| `PMKID_TARGET_MODE` | `all` | Target mode: `all`, `whitelist`, `blacklist` |

### Using Configuration File
```bash
# Copy example configuration
cp scripts/config.example.sh scripts/config.sh

# Edit configuration
nano scripts/config.sh

# Source configuration and run
. scripts/config.sh
./scripts/PMKIDAttack.sh auto
```

### Target Filtering

#### Whitelist Mode
Only capture from specific APs listed in `scripts/targets_whitelist.txt`:
```bash
# Add targets to whitelist
echo "AA:BB:CC:DD:EE:FF" >> scripts/targets_whitelist.txt

# Run in whitelist mode
PMKID_TARGET_MODE=whitelist ./scripts/PMKIDAttack.sh auto
```

#### Blacklist Mode
Capture from all APs except those in `scripts/targets_blacklist.txt`:
```bash
# Add targets to blacklist
echo "00:11:22:33:44:55" >> scripts/targets_blacklist.txt

# Run in blacklist mode
PMKID_TARGET_MODE=blacklist ./scripts/PMKIDAttack.sh auto
```

## Architecture

### POSIX Compliance
- Uses `#!/bin/sh` (not bash)
- No bash-isms like `[[ ]]` or `${var//search/replace}`
- Compatible with busybox ash (used in OpenWrt)
- All variables properly quoted to prevent word splitting

### Error Handling
- `set -e` for fail-fast behavior
- Comprehensive input validation
- Graceful signal handling (SIGINT, SIGTERM)
- Clean shutdown and resource cleanup

### Logging System
- Four log levels: debug, info, warn, error
- Timestamps on all log messages
- Respects `PMKID_LOG_LEVEL` environment variable
- Separate log files for background operations

### Bot System
The autonomous mode uses a pool-based bot system:
1. **Target Discovery**: Periodic scanning discovers available APs
2. **Target Filtering**: Applies whitelist/blacklist rules
3. **Bot Pool**: Maintains up to `PMKID_BOT_COUNT` active workers
4. **Bot Lifecycle**: Each bot captures, retries on failure, extracts hash, and reports
5. **PID Management**: All bots tracked via PID files for clean shutdown
6. **Result Tracking**: All attempts logged to `results.txt`

## File Structure
```
iNFINITEAi2025_PiNaCoLlAdA/
├── scripts/
│   ├── PMKIDAttack.sh          # Main script
│   ├── config.example.sh       # Example configuration
│   ├── targets_whitelist.txt   # Whitelist (optional)
│   └── targets_blacklist.txt   # Blacklist (optional)
├── README.md                   # This file
└── LICENSE                     # Apache 2.0 license
```

### Output Directory Structure
```
/tmp/pmkid_results/             (or $PMKID_OUTPUT_DIR)
├── captures/                   # Raw .pcapng capture files
│   ├── aabbccddeeff.pcapng
│   └── 112233445566.pcapng
├── hashes/                     # Extracted PMKID hashes
│   ├── aabbccddeeff.hash
│   └── 112233445566.hash
├── pids/                       # Process ID files
│   ├── auto_main.pid
│   ├── bot_aabbccddeeff.pid
│   └── capture_112233445566.pid
├── auto.log                    # Autonomous mode log
├── results.txt                 # Capture results summary
└── scan_*.txt                  # Scan results
```

## Examples

### Example 1: Quick Single Target Capture
```bash
# Scan to find targets
./scripts/PMKIDAttack.sh scan

# Capture from specific AP
./scripts/PMKIDAttack.sh start AA:BB:CC:DD:EE:FF

# Extract hash
./scripts/PMKIDAttack.sh check AA:BB:CC:DD:EE:FF
```

### Example 2: Autonomous Mode with Custom Settings
```bash
# Run with 8 parallel bots, 3-minute timeout, debug logging
PMKID_BOT_COUNT=8 \
PMKID_TIMEOUT=180 \
PMKID_LOG_LEVEL=debug \
./scripts/PMKIDAttack.sh auto
```

### Example 3: Whitelist Mode
```bash
# Add targets to whitelist
cat > scripts/targets_whitelist.txt << EOF
AA:BB:CC:DD:EE:FF
11:22:33:44:55:66
EOF

# Run autonomous mode with whitelist
PMKID_TARGET_MODE=whitelist ./scripts/PMKIDAttack.sh auto
```

### Example 4: Generate Report
```bash
# After running captures
./scripts/PMKIDAttack.sh report

# Output:
# ============================================
#   iFINITEAi2025_PiNeApPlErInGs - Report
# ============================================
# 
# Total captures: 15
# Total hashes: 12
# 
# Results summary:
#   Success: 12
#   Failed: 2
#   No PMKID: 1
# 
# Extracted hashes:
#   aa:bb:cc:dd:ee:ff: 2582a8281bf9d4308d6f5731d0e61c61*...
#   ...
```

## Troubleshooting

### Interface Not in Monitor Mode
```bash
# Put interface in monitor mode
ip link set wlan1 down
iw wlan1 set monitor control
ip link set wlan1 up
```

### No PMKIDs Captured
- Ensure target AP uses WPA2 (WPA3 PMKIDs work differently)
- Increase `PMKID_TIMEOUT` for better chances
- Enable `PMKID_CHANNEL_HOP=1` to scan more channels
- Some APs don't respond to PMKID requests

### Missing Dependencies
```bash
# On Debian/Ubuntu
apt-get install hcxdumptool hcxtools

# On Arch
pacman -S hcxdumptool hcxtools

# On OpenWrt
opkg update
opkg install hcxdumptool hcxtools
```

## Security Considerations

⚠️ **For Educational and Authorized Testing Only**

This tool is designed for:
- Penetration testing on networks you own or have explicit permission to test
- Security research and education
- WiFi security auditing

**Never use this tool on networks without authorization.** Unauthorized access to computer networks is illegal.

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes (maintain POSIX compliance)
4. Test on OpenWrt/busybox if possible
5. Submit a pull request

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.

## Credits

- Original inspiration: [xchwarze/wifi-pineapple-community](https://github.com/xchwarze/wifi-pineapple-community)
- Built for WiFi Pineapple and OpenWrt platforms
- Powered by `hcxdumptool` and `hcxtools`

## Changelog

### v1.0.0 (2025)
- Complete rewrite from scratch
- POSIX-compliant implementation
- Added AI autonomous mode
- Scalable parallel bot system
- Advanced configuration options
- Comprehensive error handling
- Target filtering (whitelist/blacklist)
- Leveled logging system
- Retry logic with configurable delays
- Channel hopping support

---

Made with ☕ and ❤️ by the iNFINITEAi2025 team
