# pibackup – Raspberry Pi Backup & Restore Tool

**pibackup** is a portable **64-bit backup and restore tool** with a simple **graphical user interface (GUI)**,  
specially designed for **Raspberry Pi and Linux systems**.  

It can **create, shrink, compress (Zstandard)** and **restore** images of SD cards, SSDs and HDDs.  
Backups are safe, flexible, and can be restored directly from `.img` or `.img.zst` files.  

👉 Unlike typical SD card tools, **pibackup works with large storage devices** (SSD/HDD) as well as smaller SD cards.

---

## Version
**v1.5.2**

---

## Main Features
- Simple graphical user interface (GUI)  
- No installation required – runs directly  
- 64-bit Linux application  
- Automatic backup of the first two partitions (typically `/boot` and `/root`)  
- Configurable exclude file to remove unnecessary data  
- Optional removal of SSH and DHCP configurations  
- Image shrinking to optimize storage  
- Efficient compression with **Zstandard (.zst)**  
- Option to save backups on other partitions of the same drive  
- `.img` and `.img.zst` backups supported (restore without manual decompression)  
- Supports SD cards, SSDs, HDDs, and other block devices  
- Empty sectors filled with `0xFF` → better compression & prevents residual recovery  

---

## Restore Features
- Restore directly from `.img` or `.img.zst`  
- Target device selection via drop-down list  
- Adjustable partition size via slider  
- Partition preview in grid view (updates dynamically)  
- Existing partitions remain intact by default  
- Optional selective partition deletion  
- Filesystem auto-resized to fit partition (manual override possible)  

---

## Graphical Interface
- Clear, intuitive GUI  
- Device selection via drop-down list  
- Partition preview in grid view  
- Progress indicators for backup & restore  
- Clear status and error messages  

---

## Exclude File
The exclude file lets you remove unnecessary or temporary files from the backup image.  

**Format:**
- Each line = path (absolute from root of partition)  
- Comments and empty lines are ignored  
- Use `raspberry.exclude` as a starting point  

---

## Usage

### Start Script
```bash
/path/to/pibackup/start_pibackup.sh
```

Options to start:
- From terminal  
- By double-clicking the script (must be executable)  
- Via `.desktop` launcher  

---

### Desktop Launcher Example
`PiBackup.desktop`:
```ini
[Desktop Entry]
Name=PiBackup
Comment=Start the PiBackup tool
Exec=/home/pi/PiBackup/start_pibackup.sh
Icon=utilities-terminal
Terminal=true
Type=Application
Categories=Utility;
```

---

## Output
- Full `.img` backup file  
- Compressed `.img.zst` backup file (if enabled)  
- Uncompressed `.img` is kept if compression is disabled or fails  

---

## Requirements
- No installation required  
- **zstd** must be installed (`sudo apt install zstd`)  
- Root privileges required (`sudo`)  

---

## Build Information
- Developed with [CodeTyphon](https://www.pilotlogic.com/)  
- GUI: Qt5 widgetset  
- Target: 64-bit ARM Linux  

### Build from Source
- Open CodeTyphon IDE  
- Set widgetset to Qt5  
- Compile as 64-bit ARM Linux application  

---

## License
MIT License – see [LICENSE](LICENSE).  

⚠️ **Disclaimer**:  
This tool directly operates on storage devices and filesystems.  
Improper use may result in **data loss**. Use at your own risk.  

---

## Author
**RaspberryFpc**

---

## Feedback & Issues
Please open an issue on [GitHub](https://github.com/RaspberryFpc/pibackup).

---

## 📥 Download and Use
- Clone via Git:  
  ```bash
  git clone https://github.com/RaspberryFpc/pibackup.git
  ```  
- Or download as ZIP (⚠️ set execute permissions afterwards):  
  ```bash
  chmod +x pibackup/start_pibackup.sh
  chmod +x pibackup/pibackup
  ```  

Precompiled binaries are in the `bin/` folder.  

---

💡 **Note on Live Backups:**  
Live backups work reliably but for maximum consistency a fresh boot or inactive system backup is recommended.  
