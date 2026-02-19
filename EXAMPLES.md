# PMKID Capture Tool - Usage Examples

This document provides practical examples for using the PMKID Capture Tool on your WiFi Pineapple Nano.

## Basic Examples

### Example 1: Quick Network Scan
Before capturing, scan to see available networks:

```bash
pmkid-scan
```

Expected output:
```
═══════════════════════════════════════════════════════════
  PMKID Capture Tool - WiFi Pineapple Nano Edition
  Enhanced by iNFINITEAi2025
═══════════════════════════════════════════════════════════

[INFO] Checking dependencies...
[INFO] All dependencies satisfied
[INFO] Setting up monitor mode on wlan1...
[INFO] Monitor mode enabled on wlan1
[INFO] Scanning for nearby networks...
[INFO] Found networks:
BSSID: AA:BB:CC:DD:EE:FF, ESSID: TestNetwork1, Channel: 6
BSSID: 11:22:33:44:55:66, ESSID: TestNetwork2, Channel: 11
```

### Example 2: Quick 5-Minute Capture
The easiest way to capture PMKIDs:

```bash
pmkid-quick
```

This will:
- Set up monitor mode automatically
- Scan for networks
- Capture for 5 minutes
- Convert to hashcat format
- Display results

### Example 3: Extended Capture with Verbose Output
For more detailed information during capture:

```bash
pmkid-extended -v
```

Or manually:
```bash
pmkid-capture -i wlan1 -t 600 -v
```

This captures for 10 minutes with detailed logging.

### Example 4: Target Specific Interface
If you have multiple wireless adapters:

```bash
pmkid-capture -i wlan0 -t 300
```

### Example 5: Custom Output Directory
Save captures to a specific location:

```bash
pmkid-capture -i wlan1 -o /tmp/test_captures -t 300
```

## Advanced Examples

### Example 6: Long-Running Capture
For stubborn networks, run a longer capture:

```bash
pmkid-capture -i wlan1 -t 1800 -v
```

This runs for 30 minutes.

### Example 7: Multiple Sequential Captures
Run multiple captures in sequence:

```bash
for i in {1..3}; do
    echo "Running capture $i of 3..."
    pmkid-quick
    sleep 60  # Wait 60 seconds between captures
done
```

### Example 8: Automated Daily Capture
Create a cron job for automated captures (authorized environments only):

```bash
# Edit crontab
crontab -e

# Add this line to run daily at 2 AM
0 2 * * * /usr/local/bin/pmkid-capture -i wlan1 -t 300 -o /root/daily_captures
```

### Example 9: Check Capture Results
View captured PMKIDs:

```bash
# List all capture files
ls -lh /root/pmkid_captures/

# View hashcat format files
cat /root/pmkid_captures/*.hc22000

# Count captured hashes
cat /root/pmkid_captures/*.hc22000 | wc -l
```

### Example 10: Process Old Captures
Re-process existing pcapng files:

```bash
cd /root/pmkid_captures

# Convert specific file
hcxpcapngtool -o newfile.hc22000 capture_20240219_120000.pcapng

# Batch convert all files
for file in *.pcapng; do
    hcxpcapngtool -o "${file%.pcapng}.hc22000" "$file"
done
```

## Integration Examples

### Example 11: Integration with Web Interface
Create a simple web interface endpoint (requires additional setup):

```bash
#!/bin/bash
# web-endpoint.sh - Simple API endpoint for web UI

case "$1" in
    scan)
        pmkid-scan 2>&1 | tail -20
        ;;
    capture)
        pmkid-quick 2>&1
        ;;
    status)
        ls -lh /root/pmkid_captures/*.hc22000 2>/dev/null | tail -5
        ;;
    *)
        echo "Usage: $0 {scan|capture|status}"
        exit 1
        ;;
esac
```

### Example 12: Export Results
Export captured data for offline analysis:

```bash
#!/bin/bash
# export-captures.sh

DATE=$(date +%Y%m%d)
EXPORT_DIR="/tmp/pmkid_export_$DATE"

mkdir -p "$EXPORT_DIR"

# Copy capture files
cp /root/pmkid_captures/*.hc22000 "$EXPORT_DIR/" 2>/dev/null
cp /root/pmkid_captures/pmkid.log "$EXPORT_DIR/" 2>/dev/null

# Create archive
tar -czf "pmkid_export_$DATE.tar.gz" "$EXPORT_DIR"

echo "Exported to: pmkid_export_$DATE.tar.gz"
```

### Example 13: Monitor Live Capture
Watch the capture progress in real-time:

```bash
# In one terminal, start capture
pmkid-capture -i wlan1 -t 600 -v

# In another terminal, monitor the log
tail -f /root/pmkid_captures/pmkid.log
```

### Example 14: Verify Interface Capabilities
Check if your interface supports required features:

```bash
#!/bin/bash
# check-interface.sh

INTERFACE="wlan1"

echo "Checking interface: $INTERFACE"
echo "================================"

# Check if interface exists
if ip link show $INTERFACE &>/dev/null; then
    echo "✓ Interface exists"
else
    echo "✗ Interface not found"
    exit 1
fi

# Check driver info
echo ""
echo "Driver information:"
ethtool -i $INTERFACE 2>/dev/null | grep driver

# Check supported modes
echo ""
echo "Supported modes:"
iw list | grep -A 10 "Supported interface modes"

# Check if monitor mode is supported
if iw list | grep -q "monitor"; then
    echo "✓ Monitor mode supported"
else
    echo "✗ Monitor mode not supported"
fi
```

## Workflow Examples

### Example 15: Complete Penetration Test Workflow

```bash
#!/bin/bash
# pentest-workflow.sh - Complete PMKID capture workflow

echo "Starting PMKID Capture Workflow"
echo "================================"

# Step 1: Scan for networks
echo "Step 1: Scanning for networks..."
pmkid-scan > scan_results.txt
cat scan_results.txt

# Step 2: Initial capture
echo ""
echo "Step 2: Running initial 5-minute capture..."
pmkid-quick

# Step 3: Check results
echo ""
echo "Step 3: Checking results..."
HASH_COUNT=$(cat /root/pmkid_captures/*.hc22000 2>/dev/null | wc -l)
echo "Captured $HASH_COUNT PMKID hashes"

# Step 4: If no results, try extended capture
if [ $HASH_COUNT -eq 0 ]; then
    echo ""
    echo "Step 4: No hashes found, trying extended capture..."
    pmkid-extended
    HASH_COUNT=$(cat /root/pmkid_captures/*.hc22000 2>/dev/null | wc -l)
    echo "Captured $HASH_COUNT PMKID hashes"
fi

# Step 5: Display results
echo ""
echo "Step 5: Final results"
echo "===================="
ls -lh /root/pmkid_captures/
echo ""
echo "Workflow complete!"
```

### Example 16: Post-Capture Analysis

```bash
#!/bin/bash
# analyze-captures.sh

CAPTURE_DIR="/root/pmkid_captures"

echo "PMKID Capture Analysis"
echo "====================="
echo ""

# Count total captures
PCAPNG_COUNT=$(ls -1 $CAPTURE_DIR/*.pcapng 2>/dev/null | wc -l)
echo "Total capture files: $PCAPNG_COUNT"

# Count total hashes
HASH_COUNT=$(cat $CAPTURE_DIR/*.hc22000 2>/dev/null | wc -l)
echo "Total PMKID hashes: $HASH_COUNT"

# Count unique BSSIDs
UNIQUE_BSSID=$(cat $CAPTURE_DIR/*.hc22000 2>/dev/null | cut -d'*' -f4 | sort -u | wc -l)
echo "Unique networks: $UNIQUE_BSSID"

# Show disk usage
DISK_USAGE=$(du -sh $CAPTURE_DIR 2>/dev/null | cut -f1)
echo "Disk usage: $DISK_USAGE"

# Show recent captures
echo ""
echo "Recent captures:"
ls -lht $CAPTURE_DIR/*.hc22000 2>/dev/null | head -5
```

## Troubleshooting Examples

### Example 17: Diagnose Interface Issues

```bash
#!/bin/bash
# diagnose.sh - Diagnose common issues

echo "PMKID Tool Diagnostics"
echo "====================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "✗ Not running as root (required)"
else
    echo "✓ Running as root"
fi

# Check dependencies
echo ""
echo "Checking dependencies:"
for tool in hcxdumptool hcxpcapngtool airmon-ng iw; do
    if command -v $tool &>/dev/null; then
        echo "  ✓ $tool"
    else
        echo "  ✗ $tool (missing)"
    fi
done

# Check interfaces
echo ""
echo "Available wireless interfaces:"
iw dev | grep Interface | awk '{print "  " $2}'

# Check monitor mode status
echo ""
echo "Monitor mode interfaces:"
iw dev | grep -A 5 "type monitor" || echo "  (none active)"

# Check disk space
echo ""
echo "Disk space in capture directory:"
df -h /root/pmkid_captures 2>/dev/null | tail -1

echo ""
echo "Diagnostics complete!"
```

## Best Practices Examples

### Example 18: Clean Up Old Captures

```bash
#!/bin/bash
# cleanup.sh - Clean up old capture files

CAPTURE_DIR="/root/pmkid_captures"
DAYS_TO_KEEP=7

echo "Cleaning up captures older than $DAYS_TO_KEEP days..."

# Find and remove old files
find $CAPTURE_DIR -name "*.pcapng" -mtime +$DAYS_TO_KEEP -delete
find $CAPTURE_DIR -name "*.hc22000" -mtime +$DAYS_TO_KEEP -delete

echo "Cleanup complete!"
```

### Example 19: Backup Captures

```bash
#!/bin/bash
# backup-captures.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="/root/pmkid_backup_$DATE.tar.gz"

echo "Creating backup: $BACKUP_FILE"

tar -czf "$BACKUP_FILE" /root/pmkid_captures/ 2>/dev/null

if [ -f "$BACKUP_FILE" ]; then
    SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "Backup created successfully: $SIZE"
else
    echo "Backup failed!"
    exit 1
fi
```

---

**Note**: Always use these tools responsibly and only on networks you have explicit authorization to test.
