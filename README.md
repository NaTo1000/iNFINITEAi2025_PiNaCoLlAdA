# PMKID Capture Tool for WiFi Pineapple Nano
## Enhanced by iNFINITEAi2025

A comprehensive, well-rounded PMKID capture tool specifically designed for the WiFi Pineapple Nano. This tool captures PMKID hashes from WPA/WPA2 networks for authorized security testing and penetration testing purposes.

## ⚠️ Legal Disclaimer

**This tool is for authorized security testing only!**

Use of this tool against networks without explicit written permission is illegal and unethical. The developers assume no liability for misuse. Always:
- Obtain proper authorization before testing
- Comply with all applicable laws and regulations
- Use only in controlled environments
- Respect privacy and data protection laws

## 🚀 Features

- **Automated PMKID Capture**: Captures PMKID hashes from WPA/WPA2 networks
- **Monitor Mode Management**: Automatic setup and teardown of monitor mode
- **Network Scanning**: Scan and list available networks before capture
- **Hashcat Integration**: Automatic conversion to hashcat-compatible format (mode 22000)
- **Comprehensive Logging**: Detailed logs with timestamps and severity levels
- **Error Handling**: Robust error checking and graceful failure handling
- **Configurable Settings**: Easy-to-use configuration file
- **Multiple Capture Modes**: Quick, scan-only, and extended capture options
- **WiFi Pineapple Optimized**: Specifically designed for Pineapple Nano hardware
- **Color-Coded Output**: Easy-to-read terminal output with color coding

## 📋 Requirements

### Hardware
- WiFi Pineapple Nano
- External wireless adapter (if using dual-band capture)

### Software Dependencies
- `hcxtools` - PMKID capture and conversion utilities
- `hcxdumptool` - Packet capture tool
- `aircrack-ng` - Wireless security tools
- `iw` - Wireless configuration utility

## 📦 Installation

### Quick Install

1. Clone or download this repository to your WiFi Pineapple Nano:
```bash
git clone https://github.com/NaTo1000/iNFINITEAi2025_PiNaCoLlAdA.git
cd iNFINITEAi2025_PiNaCoLlAdA
```

2. Run the installation script:
```bash
chmod +x install.sh
./install.sh
```

The installer will:
- Install required dependencies via opkg
- Copy scripts to `/usr/local/bin`
- Create configuration directory at `/etc/pmkid`
- Set up data directory at `/root/pmkid_captures`
- Install helper scripts for quick access

### Manual Install

If you prefer manual installation:

```bash
# Install dependencies
opkg update
opkg install hcxtools hcxdumptool aircrack-ng

# Copy main script
cp pmkid_capture.sh /usr/local/bin/pmkid-capture
chmod +x /usr/local/bin/pmkid-capture

# Create directories
mkdir -p /etc/pmkid
mkdir -p /root/pmkid_captures

# Copy configuration
cp config.conf /etc/pmkid/config.conf
```

## 🎯 Usage

### Quick Start

The easiest way to get started:
```bash
pmkid-quick
```

This runs a 5-minute capture with default settings.

### Available Commands

After installation, you have access to several commands:

| Command | Description |
|---------|-------------|
| `pmkid-capture` | Main tool with full options |
| `pmkid-quick` | Quick 5-minute capture |
| `pmkid-scan` | Scan networks only (no capture) |
| `pmkid-extended` | Extended 10-minute capture |
| `pmkid-uninstall` | Remove the tool |

### Main Tool Options

```bash
pmkid-capture [OPTIONS]

Options:
  -i INTERFACE    Wireless interface to use (default: wlan1)
  -o OUTPUT_DIR   Output directory for captures
  -t TIMEOUT      Capture timeout in seconds (default: 300)
  -s              Scan mode only (no capture)
  -v              Verbose output
  -h              Show help message
```

### Usage Examples

**Scan for networks:**
```bash
pmkid-capture -s
# or
pmkid-scan
```

**Capture PMKIDs with custom timeout:**
```bash
pmkid-capture -i wlan1 -t 600 -v
```

**Quick capture with verbose output:**
```bash
pmkid-capture -v
```

**Capture to custom directory:**
```bash
pmkid-capture -i wlan1 -o /root/my_captures -t 300
```

For more examples, see [EXAMPLES.md](EXAMPLES.md).

## 📁 File Structure

```
/usr/local/bin/
├── pmkid-capture      # Main capture tool
├── pmkid-quick        # Quick capture shortcut
├── pmkid-scan         # Network scan shortcut
├── pmkid-extended     # Extended capture shortcut
└── pmkid-uninstall    # Uninstall script

/etc/pmkid/
├── config.conf        # Configuration file
└── README.txt         # Quick reference

/root/pmkid_captures/
├── capture_*.pcapng   # Raw capture files
├── capture_*.hc22000  # Hashcat format hashes
└── pmkid.log          # Application logs
```

## ⚙️ Configuration

Edit `/etc/pmkid/config.conf` to customize settings:

```bash
# Default wireless interface
INTERFACE=wlan1

# Output directory
OUTPUT_DIR=/root/pmkid_captures

# Default timeout (seconds)
TIMEOUT=300

# Verbose logging (0=off, 1=on)
VERBOSE=0

# Target specific BSSID (optional)
TARGET_BSSID=

# Target channel (0=all)
TARGET_CHANNEL=0
```

## 🔍 Understanding Output

### Capture Files

The tool creates two types of files:

1. **Raw Capture (*.pcapng)**
   - Contains all captured packets
   - Can be analyzed with Wireshark
   - Preserved for forensic analysis

2. **Hashcat Format (*.hc22000)**
   - PMKID hashes ready for cracking
   - Compatible with hashcat mode 22000
   - One hash per line format

### Log Files

Logs are stored in `$OUTPUT_DIR/pmkid.log` with:
- Timestamps
- Severity levels (INFO, WARN, ERROR, DEBUG)
- Detailed operation information

Example log entry:
```
[2024-02-19 12:30:45] [INFO] Starting PMKID capture for 300s...
[2024-02-19 12:35:46] [INFO] Capture complete: capture_20240219_123045.pcapng (1024576 bytes)
[2024-02-19 12:35:47] [INFO] Extracted 3 PMKID hash(es)
```

## 🔓 Using Captured Hashes

Once you have captured PMKID hashes, you can crack them with hashcat:

```bash
# Basic dictionary attack
hashcat -m 22000 capture_*.hc22000 wordlist.txt

# With rules
hashcat -m 22000 capture_*.hc22000 wordlist.txt -r rules/best64.rule

# Brute force (8-12 characters)
hashcat -m 22000 capture_*.hc22000 -a 3 ?a?a?a?a?a?a?a?a
```

## 🛠️ Troubleshooting

### Interface Not Found

If you get "Interface not found" error:
```bash
# List available interfaces
iw dev

# Use the correct interface name
pmkid-capture -i wlan0
```

### No PMKIDs Captured

If no PMKIDs are captured:
- Ensure networks are using WPA/WPA2 (not WPA3)
- Try increasing capture timeout: `-t 600`
- Target specific channel: edit config.conf
- Check if interface is in monitor mode: `iw dev`

### Dependencies Missing

If tools are missing:
```bash
opkg update
opkg install hcxtools hcxdumptool aircrack-ng
```

### Permission Denied

Always run as root:
```bash
sudo pmkid-capture
```

## 🔐 Security Best Practices

1. **Authorization**: Always obtain written permission before testing
2. **Scope**: Stay within authorized testing boundaries
3. **Data Handling**: Securely store and dispose of captured data
4. **Logging**: Keep detailed logs of all testing activities
5. **Reporting**: Document findings responsibly
6. **Legal Compliance**: Follow all applicable laws and regulations

## 📊 Performance Tips

- **Channel Selection**: Target specific channels for better performance
- **Capture Duration**: 5-10 minutes usually sufficient for most networks
- **Multiple Sessions**: Run multiple shorter captures rather than one long capture
- **Interface Quality**: Use high-quality wireless adapters
- **Proximity**: Closer to target AP improves capture success rate

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your improvements
4. Test thoroughly on WiFi Pineapple Nano
5. Submit a pull request

## 📝 Version History

### v1.0.0 - Initial Release
- Core PMKID capture functionality
- WiFi Pineapple Nano integration
- Automatic hashcat conversion
- Comprehensive logging
- Configuration file support
- Helper scripts for common operations
- Detailed documentation

## 👤 Author

Enhanced by iNFINITEAi2025 for the WiFi Pineapple Nano community

## 📄 License

This project is licensed under the terms included in the LICENSE file.

## 🙏 Acknowledgments

- WiFi Pineapple Nano team
- hcxtools developers
- aircrack-ng team
- Security research community

## ⚖️ Responsible Disclosure

If you discover security vulnerabilities:
1. Do not disclose publicly
2. Contact the maintainers privately
3. Allow time for patches before disclosure
4. Follow responsible disclosure guidelines

---

**Remember**: With great power comes great responsibility. Use this tool ethically and legally.
