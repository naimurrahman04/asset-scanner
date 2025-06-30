#!/bin/bash

INPUT_FILE="targets.txt"
OUTPUT_FILE="scan_results.txt"
TEMP_DIR="./.scan_tmp"
COUNT_FILE=".count.tmp"
CONCURRENT_JOBS=5

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "[!] File '$INPUT_FILE' not found."
    exit 1
fi

# Prepare output and temp
mkdir -p "$TEMP_DIR"
> "$OUTPUT_FILE"
echo 0 > "$COUNT_FILE"

# Load targets
IPS=($(grep -v '^\s*$' "$INPUT_FILE"))
TOTAL=${#IPS[@]}

# Print progress bar
print_progress() {
    local DONE=$(cat "$COUNT_FILE")
    local PERCENT=$((DONE * 100 / TOTAL))
    local FILLED=$((PERCENT / 2))
    local EMPTY=$((50 - FILLED))
    local BAR=$(printf "%0.s#" $(seq 1 $FILLED))
    BAR+=$(printf "%0.s-" $(seq 1 $EMPTY))
    echo -ne "[${BAR}] $DONE/$TOTAL scanned ($PERCENT%%)\r"
}

# Scan function
scan_ip() {
    local IP="$1"
    local TMP_FILE="$TEMP_DIR/$IP.result"
    local HOSTNAME="N/A"
    local OS="Unknown"

    # Try ping
    if ping -c 1 -W 1 "$IP" &>/dev/null; then
        HOSTNAME=$(nslookup "$IP" 2>/dev/null | awk -F'= ' '/name =/ {print $2}' | sed 's/\.$//' | head -n 1)
        [ -z "$HOSTNAME" ] && HOSTNAME="N/A"
        OS=$(nmap -sS -O -p- -T4 "$IP" 2>/dev/null | awk -F': ' '/OS details|OS guesses/ {print $2; exit}')
    else
        # Fallback to -Pn if ping fails
        HOSTNAME=$(nslookup "$IP" 2>/dev/null | awk -F'= ' '/name =/ {print $2}' | sed 's/\.$//' | head -n 1)
        [ -z "$HOSTNAME" ] && HOSTNAME="Unresolved"
        OS=$(nmap -Pn -sS -O -p- -T4 "$IP" 2>/dev/null | awk -F': ' '/OS details|OS guesses/ {print $2; exit}')
    fi

    [ -z "$OS" ] && OS="Unknown"
    OS=$(echo "$OS" | cut -c1-30)

    printf "%-15s %-30s %-30s\n" "$IP" "$HOSTNAME" "$OS" > "$TMP_FILE"

    {
        flock 200
        CUR=$(cat "$COUNT_FILE")
        echo $((CUR + 1)) > "$COUNT_FILE"
    } 200>"$COUNT_FILE.lock"

    print_progress
}

# Export for xargs
export -f scan_ip
export TEMP_DIR COUNT_FILE
export -f print_progress

# Start scan
START_TIME=$(date +%s)
echo "Scan started at: $(date)"
echo "[*] Scanning $TOTAL hosts with up to $CONCURRENT_JOBS concurrent jobs..."
echo

# Output header
printf "IP\t\tAsset_Name\t\t\tOS_Detected\n" > "$OUTPUT_FILE"
echo "===============================================================" >> "$OUTPUT_FILE"

# ✅ Corrected xargs usage
printf "%s\n" "${IPS[@]}" | xargs -P "$CONCURRENT_JOBS" -I {} bash -c 'scan_ip "$@"' _ {}

# Merge results
cat "$TEMP_DIR"/*.result >> "$OUTPUT_FILE"

# Final stats
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

# Cleanup
rm -rf "$TEMP_DIR" "$COUNT_FILE" "$COUNT_FILE.lock"
echo
echo "[✓] All scans completed in $ELAPSED seconds."
echo "[✓] Results saved to '$OUTPUT_FILE'."
