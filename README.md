# 🚀 pibackup – Raspberry Pi Backup, Restore & Cloning Tool

> Fast, intelligent backup, restore and cloning for Raspberry Pi storage devices.

pibackup is a portable 64-bit Linux application with a simple graphical user interface, designed for Raspberry Pi systems.

It creates compressed backup images, restores existing images, and intelligently clones SD cards, SSDs and HDDs.

Unlike many SD card imaging tools, **pibackup** supports both small SD cards and large storage devices while automatically adapting partition layouts during restore and cloning.

---

# ✨ Features

* 🖥️ Simple graphical user interface (GUI)
* ⚡ Native ARM64 Linux application
* 💾 Backup of the first two Raspberry Pi partitions (`/boot` + `/`)
* 🧠 Intelligent device cloning with automatic partition detection
* 🔄 Restore directly from `.img` and `.img.zst` images
* 📉 Automatic image shrinking
* 🗜️ Fast Zstandard (`.zst`) compression
* 💽 Supports SD cards, SSDs, HDDs and other block devices
* 📏 Adjustable target partition size
* 👀 Live partition preview before restoring
* 🧱 Optional deletion of existing additional partitions
* ⚠️ Existing additional partitions are overwritten only after user confirmation
* 🚫 Configurable exclude list
* 🔐 Optional removal of SSH and DHCP configuration
* 🧹 Unused sectors are overwritten with `0xFF` to improve compression efficiency and remove residual data

---

# ⚙️ Headless Setup Options

For fresh Raspberry Pi installations:

* Enable SSH on first boot
* Set username and password
* Configure Wi-Fi (SSID and PSK)

---

# 📦 Download & Installation

### Recommended

```bash
# Download the latest release, extract it and install.
# Required dependencies (e.g. zstd) are installed automatically.

rm -rf /tmp/pibackup /tmp/pibackup.zip && \
wget -O /tmp/pibackup.zip "https://sourceforge.net/projects/pibackup/files/latest/download" && \
unzip -o /tmp/pibackup.zip -d /tmp/pibackup && \
sudo apt install /tmp/pibackup/*/bin/pibackup.deb
```

---

# ▶️ Run

```bash
sudo /path/to/pibackup
```

or start it from the desktop menu:

```text
Utility → PiBackup
```

---

# ⚙️ Alternative Installation

```bash
sudo apt install ./pibackup.deb
```

---

# 🧰 Requirements

* Linux (ARM64)
* Raspberry Pi OS / Debian Bookworm or newer
* No manual dependency installation required
* All dependencies are handled automatically by the Debian package

---

# 🛠️ Build Information

* Developed with CodeTyphon
* GUI: Qt5
* Target: ARM64 (64-bit)

**Tested on**

* Raspberry Pi 4
* Raspberry Pi 5
* Raspberry Pi OS Trixie (X11)

---

# 🛟 Emergency Recovery

Create a rescue SD card with Linux and **pibackup**.

In case of system failure:

1. Boot the rescue system.
2. Restore your backup image.
3. Continue working within minutes.

---

# 📜 License

MIT License – see **LICENSE**.

---

# ⚠️ Disclaimer

This application writes directly to storage devices.

Always verify that the correct target device is selected before starting a restore or cloning operation.

Incorrect usage may result in data loss.

---

# 👤 Author

**RaspberryFpc**

---

# 🔗 Other Projects

* **raspberry-udp_audio_receiver** – Low-latency audio sender and receiver over UDP
  https://github.com/RaspberryFpc/raspberry-udp_audio_receiver

* **DS18B20-FPC-Pi-GUI** – GUI for DS18B20 temperature sensors
  https://github.com/RaspberryFpc/DS18B20-FPC-Pi-GUI

* **RaspberryPi-BME280-GUI** – GUI and driverfor BME280 environmental sensors
  https://github.com/RaspberryFpc/RaspberryPi-BME280-GUI

* **RaspberryPi-GPIOv2-FPC** – GPIO library for Free Pascal
  https://github.com/RaspberryFpc/RaspberryPi-GPIOv2-FPC


