#!/bin/bash

INPUT_FILE="targets.txt"
OUTPUT_FILE="scan_results.txt"
TOTAL=$(grep -cve '^\s*$' "$INPUT_FILE")
COUNT=0

if [ ! -f "$INPUT_FILE" ]; then
    echo "[!] File '$INPUT_FILE' not found."
    exit 1
fi

echo "IP Asset_Name Detected_OS" > "$OUTPUT_FILE"
echo "[*] Starting scan on $TOTAL IP(s)..."

while IFS= read -r IP || [ -n "$IP" ]; do
    ((COUNT++))
    echo "[*] ($COUNT/$TOTAL) Scanning: $IP"

    # Get asset name
    HOSTNAME=$(nslookup "$IP" 2>/dev/null | awk -F'= ' '/name =/ {print $2}' | sed 's/\.$//' || echo "N/A")
    [ -z "$HOSTNAME" ] && HOSTNAME="N/A"

    # Run nmap with full TCP port scan + OS detection
    OS=$(nmap -sS -O -p- -T4 "$IP" 2>/dev/null | awk -F': ' '/OS details|OS guesses/ {print $2; exit}')
    [ -z "$OS" ] && OS="Unknown"

    # Append result in space-separated format
    echo "$IP $HOSTNAME $OS" >> "$OUTPUT_FILE"

    # Progress
    PERCENT=$(( COUNT * 100 / TOTAL ))
    echo "[+] Completed $COUNT/$TOTAL ($PERCENT%)"
    echo
done < "$INPUT_FILE"

echo "[✓] Scan completed. Results saved to '$OUTPUT_FILE'."
