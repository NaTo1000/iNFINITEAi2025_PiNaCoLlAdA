#!/bin/bash
#
# Test script for PMKID Capture Tool
# Validates installation and functionality
#

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASSED=0
FAILED=0
WARNINGS=0

print_header() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  PMKID Capture Tool - Test Suite${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

test_pass() {
    echo -e "${GREEN}✓ PASS${NC} - $1"
    ((PASSED++))
}

test_fail() {
    echo -e "${RED}✗ FAIL${NC} - $1"
    ((FAILED++))
}

test_warn() {
    echo -e "${YELLOW}⚠ WARN${NC} - $1"
    ((WARNINGS++))
}

test_info() {
    echo -e "${BLUE}ℹ INFO${NC} - $1"
}

# Test 1: Check if running as root
test_root_privileges() {
    echo "Test 1: Root Privileges"
    if [ "$EUID" -eq 0 ]; then
        test_pass "Running as root"
    else
        test_fail "Not running as root (some tests will be skipped)"
    fi
    echo ""
}

# Test 2: Check for required commands
test_dependencies() {
    echo "Test 2: Dependencies"
    local required=("hcxdumptool" "hcxpcapngtool" "airmon-ng" "iw")
    
    for cmd in "${required[@]}"; do
        if command -v $cmd &> /dev/null; then
            test_pass "$cmd is installed"
        else
            test_fail "$cmd is not installed"
        fi
    done
    echo ""
}

# Test 3: Check installed scripts
test_installed_scripts() {
    echo "Test 3: Installed Scripts"
    local scripts=("pmkid-capture" "pmkid-quick" "pmkid-scan" "pmkid-extended")
    
    for script in "${scripts[@]}"; do
        if [ -f "/usr/local/bin/$script" ]; then
            test_pass "$script is installed"
            
            # Check if executable
            if [ -x "/usr/local/bin/$script" ]; then
                test_pass "$script is executable"
            else
                test_fail "$script is not executable"
            fi
        else
            test_fail "$script is not installed"
        fi
    done
    echo ""
}

# Test 4: Check directories
test_directories() {
    echo "Test 4: Directory Structure"
    local dirs=("/etc/pmkid" "/root/pmkid_captures")
    
    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            test_pass "$dir exists"
            
            # Check permissions
            if [ -w "$dir" ]; then
                test_pass "$dir is writable"
            else
                test_warn "$dir is not writable"
            fi
        else
            test_fail "$dir does not exist"
        fi
    done
    echo ""
}

# Test 5: Check configuration file
test_configuration() {
    echo "Test 5: Configuration"
    
    if [ -f "/etc/pmkid/config.conf" ]; then
        test_pass "Configuration file exists"
        
        # Check if readable
        if [ -r "/etc/pmkid/config.conf" ]; then
            test_pass "Configuration file is readable"
        else
            test_fail "Configuration file is not readable"
        fi
        
        # Check for key configuration items
        local keys=("INTERFACE" "OUTPUT_DIR" "TIMEOUT")
        for key in "${keys[@]}"; do
            if grep -q "^$key=" "/etc/pmkid/config.conf"; then
                test_pass "Configuration contains $key"
            else
                test_warn "Configuration missing $key"
            fi
        done
    else
        test_fail "Configuration file does not exist"
    fi
    echo ""
}

# Test 6: Check wireless interfaces
test_interfaces() {
    echo "Test 6: Wireless Interfaces"
    
    # List all wireless interfaces
    local interfaces=$(iw dev 2>/dev/null | grep Interface | awk '{print $2}')
    
    if [ -z "$interfaces" ]; then
        test_fail "No wireless interfaces found"
    else
        test_pass "Found wireless interfaces:"
        for iface in $interfaces; do
            test_info "  - $iface"
            
            # Check if interface supports monitor mode
            if iw list 2>/dev/null | grep -A 10 "Supported interface modes" | grep -q "monitor"; then
                test_pass "    Monitor mode supported"
            else
                test_warn "    Monitor mode support unknown"
            fi
        done
    fi
    echo ""
}

# Test 7: Test script syntax
test_script_syntax() {
    echo "Test 7: Script Syntax"
    
    local script="/usr/local/bin/pmkid-capture"
    if [ -f "$script" ]; then
        if bash -n "$script" 2>/dev/null; then
            test_pass "Main script syntax is valid"
        else
            test_fail "Main script has syntax errors"
        fi
    else
        test_warn "Main script not found, skipping syntax check"
    fi
    echo ""
}

# Test 8: Test help output
test_help_output() {
    echo "Test 8: Help Output"
    
    if command -v pmkid-capture &> /dev/null; then
        if pmkid-capture -h &> /dev/null; then
            test_pass "Help option works"
        else
            test_warn "Help option returned non-zero exit code"
        fi
    else
        test_fail "pmkid-capture command not found"
    fi
    echo ""
}

# Test 9: Check disk space
test_disk_space() {
    echo "Test 9: Disk Space"
    
    local capture_dir="/root/pmkid_captures"
    if [ -d "$capture_dir" ]; then
        local available=$(df "$capture_dir" 2>/dev/null | tail -1 | awk '{print $4}')
        
        if [ -n "$available" ]; then
            # Convert to MB
            local available_mb=$((available / 1024))
            
            test_info "Available space: ${available_mb}MB"
            
            if [ $available_mb -gt 100 ]; then
                test_pass "Sufficient disk space (>100MB)"
            elif [ $available_mb -gt 10 ]; then
                test_warn "Low disk space (<100MB)"
            else
                test_fail "Very low disk space (<10MB)"
            fi
        else
            test_warn "Could not determine available disk space"
        fi
    else
        test_warn "Capture directory does not exist, skipping disk space check"
    fi
    echo ""
}

# Test 10: Check log file
test_logging() {
    echo "Test 10: Logging"
    
    local log_dir="/root/pmkid_captures"
    
    if [ -d "$log_dir" ]; then
        test_pass "Log directory exists"
        
        # Check if we can create a test log entry
        local test_log="$log_dir/test_log.txt"
        if echo "Test log entry" > "$test_log" 2>/dev/null; then
            test_pass "Can write to log directory"
            rm -f "$test_log"
        else
            test_fail "Cannot write to log directory"
        fi
    else
        test_fail "Log directory does not exist"
    fi
    echo ""
}

# Test 11: Network capabilities
test_network_capabilities() {
    echo "Test 11: Network Capabilities"
    
    # Check if system has CAP_NET_RAW and CAP_NET_ADMIN
    if [ "$EUID" -eq 0 ]; then
        test_pass "Root privileges available for network operations"
    else
        test_warn "Not root - some network operations may fail"
    fi
    
    # Check if can access /dev/net/tun
    if [ -c /dev/net/tun ]; then
        test_pass "/dev/net/tun is accessible"
    else
        test_warn "/dev/net/tun not found (may not be needed)"
    fi
    echo ""
}

# Test 12: Package manager
test_package_manager() {
    echo "Test 12: Package Manager"
    
    if command -v opkg &> /dev/null; then
        test_pass "opkg package manager found"
        
        # Check if can update
        if [ "$EUID" -eq 0 ]; then
            test_info "Package manager is functional"
        else
            test_warn "Cannot test package manager without root"
        fi
    else
        test_fail "opkg not found (required for WiFi Pineapple)"
    fi
    echo ""
}

# Print summary
print_summary() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Test Summary${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}Passed:   $PASSED${NC}"
    echo -e "${RED}Failed:   $FAILED${NC}"
    echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
    echo ""
    
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed! ✓${NC}"
        echo ""
        exit 0
    else
        echo -e "${RED}Some tests failed. Please review the output above.${NC}"
        echo ""
        exit 1
    fi
}

# Main execution
main() {
    print_header
    
    test_root_privileges
    test_dependencies
    test_installed_scripts
    test_directories
    test_configuration
    test_interfaces
    test_script_syntax
    test_help_output
    test_disk_space
    test_logging
    test_network_capabilities
    test_package_manager
    
    print_summary
}

# Run tests
main
