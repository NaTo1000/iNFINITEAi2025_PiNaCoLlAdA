#!/bin/sh
# iFINITEAi2025_PiNeApPlErInGs Configuration Example
# Source this file before running: . ./config.example.sh

# Wireless interface (must be in monitor mode)
export PMKID_IFACE="wlan1mon"

# Capture timeout in seconds (how long to capture before giving up)
export PMKID_TIMEOUT=120

# Maximum retry attempts per target AP
export PMKID_MAX_RETRIES=3

# Delay between retry attempts in seconds
export PMKID_RETRY_DELAY=5

# Number of parallel capture bots in autonomous mode
export PMKID_BOT_COUNT=4

# How often to re-scan for new targets in seconds (autonomous mode)
export PMKID_SCAN_INTERVAL=30

# Logging verbosity: debug, info, warn, error
export PMKID_LOG_LEVEL="info"

# Output directory for all captures, hashes, logs, and results
export PMKID_OUTPUT_DIR="/tmp/pmkid_results"

# Enable channel hopping: 1 (enabled) or 0 (disabled)
export PMKID_CHANNEL_HOP=1

# Target filtering mode: all, whitelist, blacklist
# - all: capture from all detected APs
# - whitelist: only capture from APs in targets_whitelist.txt
# - blacklist: capture from all APs except those in targets_blacklist.txt
export PMKID_TARGET_MODE="all"
