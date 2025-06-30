# Asset Scanner - Bash Based Network Recon Tool

A lightweight Bash script to automate asset discovery and operating system fingerprinting using `nslookup` and `nmap`.

---

## 🔍 Features

- Reads a list of target IPs or hostnames from a text file
- Performs:
  - `nslookup` to get asset names
  - Full TCP SYN scan with OS detection using Nmap (`-sS -O -p- -T4`)
- Tracks scan progress with percentage
- Outputs results in **space-separated format**:  
  `IP Asset_Name Detected_OS`
- Saves results to `scan_results.txt`

---

## 📁 Input

Create a file named `targets.txt` in the same directory:

