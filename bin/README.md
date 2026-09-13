# 🚀 pibackup -- Raspberry Pi Backup,Restore & Clone Tool

Pibackup is a 64-bit backup,restore and clone tool with a simple
graphical user interface,  
designed for Raspberry Pi and Linux systems.
It can create, shrink, compress (Zstandard) and restore images of SD
cards, SSDs and HDDs.  
Backups are safe, flexible, and can be restored directly from .img or
.img.zst files.
 Unlike typical SD card tools, pibackup works with large storagedevices (SSD/HDD) as well as smaller SD cards.
 The new cloning feature automatically checks whether changes to the partition layout are required and prompts you to confirm any necessary adjustments.

## ✨ Features

🖥️ Simple graphical user interface (GUI)\
⚡ 64-bit Linux application (ARM64)\
💾 Backup of first two partitions (/boot + /root)\
🚫 Configurable exclude file\
🔐 Optional removal of SSH & DHCP configs\
📉 Automatic image shrinking\
🗜️ Compression with Zstandard (.zst)\
💽 Supports SD, SSD, HDD and other block devices\
🧠 Empty sectors filled with 0xFF (better compression)

## 🔄 Restore Features

📂 Restore from .img or .img.zst\
🎯 Device selection via dropdown list\
📏 Adjustable partition size\
👀 Live partition preview\
🧱 Optional partition deletion\
📐 Filesystem auto-resize\

## ⚙️ Headless Setup Options

 For fresh Raspberry Pi setups:
- enable SSH on first boot\
- Set username & password\
- Configure WiFi (SSID + PSK)\
---
## 📦 Download and Installation
📥 Install (Recommended)
``` bash
# Download latest release, unzip, and install
# Automatically installs all dependencies (e.g. zstd)
rm -rf /tmp/pibackup /tmp/pibackup.zip && wget -O /tmp/pibackup.zip "https://sourceforge.net/projects/pibackup/files/latest/download" && unzip -o /tmp/pibackup.zip -d /tmp/pibackup && sudo apt install -y "$(find /tmp/pibackup -type f -name 'pibackup.deb' -print -quit)"
```

## ▶️ Start
``` bash
sudo /path/to/pibackup
```
Or via menu:
``` text
Utility → PiBackup
```
---
## ⚙️ Alternative Installation (Fallback)
``` bash
sudo dpkg -i pibackup.deb
sudo apt -f install
```
## 🧰 Requirements  

Linux (ARM64)  
No manual dependency installation required  
All dependencies are handled via .deb

---
## 🛠️ Build Information  

Developed with CodeTyphon\
Gui:Qt5\
Target: 64-bit ARM (arm64)\ 
Tested on:\  
Raspberry Pi 4\  
Raspberry Pi 5\  
Debian Bookworm / Trixie (X11) 

---
## 📜 License

MIT License -- see LICENSE


## ⚠️ Disclaimer:

This tool works directly on storage devices.\  
Incorrect usage may result in data loss.

---
## 👤 Author
RaspberryFpc

---
## 🛟 Emergency Recovery

💡 Create a rescue SD card with Linux + pibackup.\
In case of system failure:\
Boot rescue system\
Restore your backup image\
Get your system back instantly\

---
## 🔗 Other Projects

- [raspberry-udp_audio_receiver](https://github.com/RaspberryFpc/raspberry-udp_audio_receiver) -- Low latency audio sender and receiver over UDP  
- [DS18B20-FPC-Pi-GUI](https://github.com/RaspberryFpc/DS18B20-FPC-Pi-GUI) -- Temperature sensor GUI  
- [RaspberryPi-BME280-GUI](https://github.com/RaspberryFpc/RaspberryPi-BME280-GUI) -- Sensor access GUI  
- [RaspberryPi-GPIOv2-FPC](https://github.com/RaspberryFpc/RaspberryPi-GPIOv2-FPC) -- GPIO control unit  

