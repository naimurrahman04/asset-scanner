import os
import subprocess
import csv
import nmap
import time

def nslookup(ip):
    try:
        output = subprocess.check_output(['nslookup', ip], stderr=subprocess.DEVNULL).decode()
        for line in output.splitlines():
            if "name =" in line:
                return line.split('=')[1].strip()
        return "N/A"
    except:
        return "N/A"

def detect_os_and_ports(ip, scanner):
    try:
        scanner.scan(hosts=ip, arguments='-sS -O -p- -T4', timeout=300)
        if ip in scanner.all_hosts():
            osmatch = scanner[ip].get('osmatch')
            if osmatch:
                return osmatch[0]['name']
        return "Unknown"
    except Exception:
        return "Scan Error"

def main():
    input_file = 'targets.txt'
    output_file = 'scan_results.csv'
    scanner = nmap.PortScanner()
    results = []

    if not os.path.exists(input_file):
        print(f"[!] File '{input_file}' not found.")
        return

    with open(input_file, 'r') as f:
        targets = [line.strip() for line in f if line.strip()]

    total_ips = len(targets)
    completed = 0

    print(f"[*] Total IPs to scan: {total_ips}")
    print("[*] Starting scans...\n")

    for ip in targets:
        print(f"[*] Scanning ({completed + 1}/{total_ips}): {ip}")
        asset_name = nslookup(ip)
        detected_os = detect_os_and_ports(ip, scanner)
        results.append({'IP': ip, 'Asset Name': asset_name, 'Detected OS': detected_os})
        completed += 1
        percent = (completed / total_ips) * 100
        print(f"[+] Completed {completed}/{total_ips} ({percent:.2f}%)\n")

    print(f"[*] Writing results to '{output_file}'...\n")
    with open(output_file, 'w', newline='') as csvfile:
        fieldnames = ['IP', 'Asset Name', 'Detected OS']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(results)

    print("[✓] Scan completed successfully.")
    print(f"[✓] Results saved in '{output_file}'.")

if __name__ == '__main__':
    main()
