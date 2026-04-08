#!/bin/bash
set -euo pipefail

PKG="pibackup_pkg"
version="1.7.7"
OUTDIR="/home/pi/git/pibackup/bin"

SRC_BIN="/home/pi/git/pibackup/source/pibackup"
ICON="/home/pi/git/pibackup/source/pibackup.png"

echo "🚀 Build pibackup.deb"

# Prüfen ob Binary existiert
if [ ! -f "$SRC_BIN" ]; then
    echo "❌ Binary nicht gefunden: $SRC_BIN"
    exit 1
fi

# Cleanup
rm -rf "$PKG"

# Struktur
mkdir -p "$PKG/DEBIAN"
mkdir -p "$PKG/usr/lib/pibackup"
mkdir -p "$PKG/usr/share/applications"
mkdir -p "$PKG/usr/share/icons/hicolor/256x256/apps"

# Binary
install -Dm755 "$SRC_BIN" \
    "$PKG/usr/lib/pibackup/pibackup"
    
#install -Dm755 /usr/lib/aarch64-linux-gnu/libQt5Pas.so.1 \
#    "$PKG/usr/lib/pibackup/libQt5Pas.so.1"
#install -Dm755 /usr/lib/aarch64-linux-gnu/libQt5Pas.so.1.2.14 \
#    "$PKG/usr/lib/pibackup/libQt5Pas.so.1.2.14"    

# Exclude-Dateien → /etc
install -Dm644 /home/pi/git/pibackup/source/dhcp-cleanup.exclude \
    "$PKG/etc/pibackup/dhcp-cleanup.exclude"

install -Dm644 /home/pi/git/pibackup/source/raspberry.exclude \
    "$PKG/etc/pibackup/raspberry.exclude"

install -Dm644 /home/pi/git/pibackup/source/ssh-cleanup.exclude \
    "$PKG/etc/pibackup/ssh-cleanup.exclude"


cat > "$PKG/etc/pibackup/pibackup.ini" <<EOF
[Drive]


[Destination]


[Exclude]
Last=/etc/pibackup/raspberry.exclude

[Option]
compress=1
DeletePastCompress=0
compresslevel=2
ChangeDeviceID=0
EOF



# Desktop Entry
cat > "$PKG/usr/share/applications/pibackup.desktop" <<EOF
[Desktop Entry]
Name=PiBackup
Comment=Backup and Restore Tool
Exec=sudo /usr/lib/pibackup/pibackup
Icon=pibackup
Terminal=false
Type=Application
Categories=Utility;System;
EOF

# Icon
install -Dm644 "$ICON" \
    "$PKG/usr/share/icons/hicolor/256x256/apps/pibackup.png"

# Control-Datei
cat > "$PKG/DEBIAN/control" <<EOF
Package: pibackup
Version: $version
Section: utils
Priority: optional
Architecture: arm64
Maintainer: RaspberryFpc
Depends: zstd, e2fsprogs, sudo, libqt5pas1
Description: Raspberry Pi Backup Tool
 Fast backup and restore tool with ZSTD compression.
EOF


# 👉 conffiles (wichtig!)
cat > "$PKG/DEBIAN/conffiles" <<EOF
/etc/pibackup/pibackup.ini
/etc/pibackup/dhcp-cleanup.exclude
/etc/pibackup/raspberry.exclude
/etc/pibackup/ssh-cleanup.exclude
EOF
#/etc/pibackup/pibackup.ini


# Paket bauen
dpkg-deb --build --root-owner-group "$PKG" "$OUTDIR/pibackup.deb"

# Cleanup
rm -rf "$PKG"

echo "✔ Fertig: $OUTDIR/pibackup.deb"
