#!/bin/bash
#
# Utility script for PMKID Capture Tool
# Provides additional helper functions
#

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CAPTURE_DIR="/root/pmkid_captures"

show_banner() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  PMKID Capture Tool - Utilities${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Show statistics
show_stats() {
    echo -e "${GREEN}Capture Statistics${NC}"
    echo "===================="
    echo ""
    
    if [ ! -d "$CAPTURE_DIR" ]; then
        echo "Capture directory not found"
        return 1
    fi
    
    # Count files
    local pcapng_count=$(ls -1 "$CAPTURE_DIR"/*.pcapng 2>/dev/null | wc -l)
    
    # Count hashes with validation
    local hash_count=0
    if ls "$CAPTURE_DIR"/*.hc22000 2>/dev/null | grep -q .; then
        hash_count=$(find "$CAPTURE_DIR" -name "*.hc22000" -type f -exec cat {} \; 2>/dev/null | grep -v '^$' | wc -l)
    fi
    
    # Count unique BSSIDs with validation
    local unique_bssid=0
    if [ $hash_count -gt 0 ]; then
        unique_bssid=$(find "$CAPTURE_DIR" -name "*.hc22000" -type f -exec cat {} \; 2>/dev/null | grep -v '^$' | cut -d'*' -f4 | sort -u | wc -l)
    fi
    
    echo "Total capture files: $pcapng_count"
    echo "Total PMKID hashes: $hash_count"
    echo "Unique networks: $unique_bssid"
    
    # Disk usage
    local disk_usage=$(du -sh "$CAPTURE_DIR" 2>/dev/null | cut -f1)
    echo "Disk usage: $disk_usage"
    
    # Most recent capture
    local latest=$(ls -t "$CAPTURE_DIR"/*.pcapng 2>/dev/null | head -1)
    if [ -n "$latest" ]; then
        echo ""
        echo "Latest capture:"
        ls -lh "$latest"
    fi
    
    echo ""
}

# List recent captures
list_captures() {
    local count=${1:-10}
    
    echo -e "${GREEN}Recent Captures (last $count)${NC}"
    echo "=============================="
    echo ""
    
    if [ ! -d "$CAPTURE_DIR" ]; then
        echo "Capture directory not found"
        return 1
    fi
    
    ls -lht "$CAPTURE_DIR"/*.hc22000 2>/dev/null | head -n "$count"
    echo ""
}

# Show captured hashes
show_hashes() {
    local file=$1
    
    if [ -z "$file" ]; then
        # Show all hashes
        echo -e "${GREEN}All Captured PMKIDs${NC}"
        echo "===================="
        echo ""
        
        if [ ! -d "$CAPTURE_DIR" ]; then
            echo "Capture directory not found"
            return 1
        fi
        
        for hashfile in "$CAPTURE_DIR"/*.hc22000; do
            if [ -f "$hashfile" ]; then
                echo "File: $(basename $hashfile)"
                echo "----------------------------------------"
                cat "$hashfile"
                echo ""
            fi
        done
    else
        # Show specific file
        if [ -f "$file" ]; then
            cat "$file"
        else
            echo "File not found: $file"
            return 1
        fi
    fi
}

# Clean old captures
clean_old() {
    local days=${1:-7}
    
    echo -e "${YELLOW}Cleaning captures older than $days days...${NC}"
    
    if [ ! -d "$CAPTURE_DIR" ]; then
        echo "Capture directory not found"
        return 1
    fi
    
    # Find and list old files
    local old_files=$(find "$CAPTURE_DIR" -name "*.pcapng" -mtime +$days)
    local old_hashes=$(find "$CAPTURE_DIR" -name "*.hc22000" -mtime +$days)
    
    if [ -z "$old_files" ] && [ -z "$old_hashes" ]; then
        echo "No old files to clean"
        return 0
    fi
    
    echo "Files to be removed:"
    find "$CAPTURE_DIR" -name "*.pcapng" -mtime +$days -ls
    find "$CAPTURE_DIR" -name "*.hc22000" -mtime +$days -ls
    
    read -p "Proceed with deletion? (y/N): " confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        find "$CAPTURE_DIR" -name "*.pcapng" -mtime +$days -delete
        find "$CAPTURE_DIR" -name "*.hc22000" -mtime +$days -delete
        echo -e "${GREEN}Cleanup complete${NC}"
    else
        echo "Cleanup cancelled"
    fi
}

# Backup captures
backup_captures() {
    local backup_file=${1:-/root/pmkid_backup_$(date +%Y%m%d_%H%M%S).tar.gz}
    
    echo -e "${GREEN}Creating backup: $backup_file${NC}"
    
    if [ ! -d "$CAPTURE_DIR" ]; then
        echo "Capture directory not found"
        return 1
    fi
    
    tar -czf "$backup_file" "$CAPTURE_DIR" 2>/dev/null
    
    if [ -f "$backup_file" ]; then
        local size=$(du -h "$backup_file" | cut -f1)
        echo -e "${GREEN}Backup created successfully: $size${NC}"
        echo "Location: $backup_file"
    else
        echo -e "${RED}Backup failed${NC}"
        return 1
    fi
}

# Export hashes only
export_hashes() {
    local output_file=${1:-/root/pmkid_hashes_$(date +%Y%m%d_%H%M%S).txt}
    
    echo -e "${GREEN}Exporting all hashes to: $output_file${NC}"
    
    if [ ! -d "$CAPTURE_DIR" ]; then
        echo "Capture directory not found"
        return 1
    fi
    
    cat "$CAPTURE_DIR"/*.hc22000 2>/dev/null > "$output_file"
    
    if [ -f "$output_file" ]; then
        local count=$(wc -l < "$output_file")
        echo -e "${GREEN}Exported $count hashes${NC}"
    else
        echo -e "${RED}Export failed${NC}"
        return 1
    fi
}

# Check interface status
check_interface() {
    local interface=${1:-wlan1}
    
    echo -e "${GREEN}Interface Status: $interface${NC}"
    echo "================================"
    echo ""
    
    if ! ip link show "$interface" &>/dev/null; then
        echo -e "${RED}Interface not found${NC}"
        return 1
    fi
    
    # Show interface info
    echo "Link status:"
    ip link show "$interface"
    echo ""
    
    # Show mode
    echo "Mode:"
    iw dev "$interface" info 2>/dev/null | grep type
    echo ""
    
    # Show channel
    echo "Channel:"
    iw dev "$interface" info 2>/dev/null | grep channel
    echo ""
}

# View logs
view_logs() {
    local lines=${1:-50}
    
    local log_file="$CAPTURE_DIR/pmkid.log"
    
    if [ ! -f "$log_file" ]; then
        echo "Log file not found: $log_file"
        return 1
    fi
    
    echo -e "${GREEN}Recent Log Entries (last $lines lines)${NC}"
    echo "======================================="
    echo ""
    
    tail -n "$lines" "$log_file"
}

# Analyze success rate
analyze_success() {
    echo -e "${GREEN}Capture Success Analysis${NC}"
    echo "========================="
    echo ""
    
    if [ ! -d "$CAPTURE_DIR" ]; then
        echo "Capture directory not found"
        return 1
    fi
    
    local total_captures=$(ls -1 "$CAPTURE_DIR"/*.pcapng 2>/dev/null | wc -l)
    local successful_captures=$(ls -1 "$CAPTURE_DIR"/*.hc22000 2>/dev/null | wc -l)
    
    if [ $total_captures -eq 0 ]; then
        echo "No captures found"
        return 0
    fi
    
    local success_rate=$((successful_captures * 100 / total_captures))
    
    echo "Total captures: $total_captures"
    echo "Successful captures: $successful_captures"
    echo "Success rate: ${success_rate}%"
    echo ""
    
    if [ $success_rate -lt 30 ]; then
        echo -e "${RED}Low success rate. Consider:${NC}"
        echo "  - Increasing capture duration"
        echo "  - Moving closer to target networks"
        echo "  - Trying different times of day"
        echo "  - Checking interface quality"
    elif [ $success_rate -lt 70 ]; then
        echo -e "${YELLOW}Moderate success rate. Room for improvement.${NC}"
    else
        echo -e "${GREEN}Good success rate!${NC}"
    fi
}

# Usage information
usage() {
    show_banner
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  stats              Show capture statistics"
    echo "  list [N]           List N recent captures (default: 10)"
    echo "  hashes [FILE]      Show captured hashes"
    echo "  clean [DAYS]       Clean captures older than DAYS (default: 7)"
    echo "  backup [FILE]      Create backup archive"
    echo "  export [FILE]      Export all hashes to file"
    echo "  interface [NAME]   Check interface status"
    echo "  logs [N]           View last N log lines (default: 50)"
    echo "  analyze            Analyze capture success rate"
    echo ""
    echo "Examples:"
    echo "  $0 stats"
    echo "  $0 list 20"
    echo "  $0 clean 14"
    echo "  $0 backup /tmp/backup.tar.gz"
    echo "  $0 interface wlan1"
    echo ""
}

# Main execution
case "$1" in
    stats)
        show_banner
        show_stats
        ;;
    list)
        show_banner
        list_captures "$2"
        ;;
    hashes)
        show_banner
        show_hashes "$2"
        ;;
    clean)
        show_banner
        clean_old "$2"
        ;;
    backup)
        show_banner
        backup_captures "$2"
        ;;
    export)
        show_banner
        export_hashes "$2"
        ;;
    interface)
        show_banner
        check_interface "$2"
        ;;
    logs)
        show_banner
        view_logs "$2"
        ;;
    analyze)
        show_banner
        analyze_success
        ;;
    *)
        usage
        exit 1
        ;;
esac
