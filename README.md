# Asset Scanner - NSLookup + Nmap OS Detection Tool

This Python-based tool reads a list of IP addresses or hostnames from a `.txt` file, performs:
- 🔍 `nslookup` to resolve asset names
- 🔎 Full TCP port scan using `nmap -sS -O -p- -T4` to detect OS
- 📄 Exports the result as a CSV: `IP`, `Asset Name`, `Detected OS`
- ✅ Shows progress (completed, total, percentage)

---

## 📦 Requirements

- Python 3.x
- [Nmap](https://nmap.org/download.html) installed and accessible in `PATH`
- Python modules:
  ```bash
  pip install python-nmap
