# Changelog

All notable changes to the PMKID Capture Tool will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-02-19

### Added
- Initial release of PMKID Capture Tool for WiFi Pineapple Nano
- Core PMKID capture functionality using hcxdumptool
- Automatic monitor mode setup and teardown
- Network scanning capabilities
- Automatic conversion to hashcat format (mode 22000)
- Comprehensive logging system with multiple severity levels
- Color-coded terminal output for better readability
- Configuration file support at /etc/pmkid/config.conf
- Installation script with automatic dependency installation
- Helper scripts for quick operations:
  - pmkid-quick: Quick 5-minute capture
  - pmkid-scan: Scan networks only
  - pmkid-extended: Extended 10-minute capture
  - pmkid-uninstall: Easy uninstallation
- Comprehensive documentation:
  - README.md with full usage instructions
  - EXAMPLES.md with practical examples
  - CHANGELOG.md for version tracking
- Error handling and validation
- Root privilege checking
- Dependency verification
- Interface availability checking
- Graceful cleanup on exit
- Signal handling for proper shutdown
- Verbose mode for debugging
- Custom output directory support
- Configurable capture timeout
- Automatic log rotation support (configured in config.conf)
- Legal disclaimer and usage guidelines
- Security best practices documentation

### Features
- WiFi Pineapple Nano optimized
- Works with wlan1 interface by default
- Compatible with external wireless adapters
- Supports both quick captures and extended sessions
- Preserves raw pcapng files for forensic analysis
- Real-time status updates during capture
- Detailed logging for troubleshooting
- Easy integration with existing workflows

### Security
- Proper permission handling
- Secure file creation
- Safe cleanup procedures
- No hardcoded credentials
- Follows penetration testing best practices

### Documentation
- Complete README with installation and usage
- Extensive examples document
- Inline code comments
- Configuration file comments
- Troubleshooting guide
- Performance tips
- Legal and ethical guidelines

## [Unreleased]

### Planned Features
- Web UI integration for Pineapple Nano
- Multiple interface support (concurrent captures)
- Deauth attack integration for faster captures
- Target filtering by ESSID/BSSID
- Automatic wordlist integration
- Real-time hash cracking integration
- Email/webhook notifications on successful capture
- Database storage for captured hashes
- Statistical analysis of capture success rates
- GPS coordinate logging for location tracking
- Integration with other Pineapple modules
- REST API for remote control
- Mobile app companion
- Scheduled capture jobs
- Improved capture success rate algorithms

### Future Improvements
- Better error messages
- Enhanced logging options
- Performance optimizations
- Battery usage optimization
- Memory usage optimization
- Better WPA3 handling
- Multi-language support
- Plugin system for extensibility

---

[1.0.0]: https://github.com/NaTo1000/iNFINITEAi2025_PiNaCoLlAdA/releases/tag/v1.0.0
