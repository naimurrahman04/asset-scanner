#!/bin/bash

INPUT_FILE="targets.txt"
OUTPUT_FILE="scan_results.txt"
TEMP_DIR="./.scan_tmp"
CONCURRENT_JOBS=5

if [ ! -f "$INPUT_FILE" ]; then
    echo "[!] File '$INPUT_FILE' not found."
    exit 1
fi

mkdir -p "$TEMP_DIR"
> "$OUTPUT_FILE"

IPS=($(grep -v '^\s*$' "$INPUT_FILE"))
TOTAL=${#IPS[@]}
COUNT_FILE=".count.tmp"
echo 0 > "$COUNT_FILE"

print_progress() {
    local DONE=$(cat "$COUNT_FILE")
    local PERCENT=$((DONE * 100 / TOTAL))
    local FILLED=$((PERCENT / 2))
    local EMPTY=$((50 - FILLED))
    local BAR=$(printf "%0.s#" $(seq 1 $FILLED))
    BAR+=$(printf "%0.s-" $(seq 1 $EMPTY))
    echo -ne "[${BAR}] $DONE/$TOTAL scanned ($PERCENT%%)\r"
}

scan_ip() {
    local IP="$1"
    local TMP_FILE="$TEMP_DIR/$IP.result"

    HOSTNAME=$(nslookup "$IP" 2>/dev/null | awk -F'= ' '/name =/ {print $2}' | sed 's/\.$//' | head -n 1)
    [ -z "$HOSTNAME" ] && HOSTNAME="N/A"

    OS=$(nmap -Pn -sS -O -p- -T4 "$IP" 2>/dev/null | awk -F': ' '/OS details|OS guesses/ {print $2; exit}')
    [ -z "$OS" ] && OS="Unknown"
    OS=$(echo "$OS" | cut -c1-30)

    printf "%-15s %-30s %-30s\n" "$IP" "$HOSTNAME" "$OS" > "$TMP_FILE"

    flock "$COUNT_FILE" bash -c 'echo $(( $(cat '"$COUNT_FILE"') + 1 )) > '"$COUNT_FILE"
    print_progress
}

export -f scan_ip
export TEMP_DIR
export COUNT_FILE
export -f print_progress

START_TIME=$(date +%s)
echo "Scan started at: $(date)"
echo "[*] Scanning $TOTAL hosts with up to $CONCURRENT_JOBS concurrent jobs..."

printf "IP\t\tAsset_Name\t\t\tOS_Detected\n" > "$OUTPUT_FILE"
echo "===============================================================" >> "$OUTPUT_FILE"

printf "%s\n" "${IPS[@]}" | xargs -n 1 -P "$CONCURRENT_JOBS" -I {} bash -c 'scan_ip "$@"' _ {}

cat "$TEMP_DIR"/*.result >> "$OUTPUT_FILE"
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

# Cleanup
rm -rf "$TEMP_DIR" "$COUNT_FILE"
echo
echo -e "\n[✓] Scans completed in $ELAPSED seconds."
echo "[✓] Results saved to '$OUTPUT_FILE'."
