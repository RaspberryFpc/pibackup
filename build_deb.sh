#!/bin/bash
set -euo pipefail

# Fehler abfangen, damit das Terminal offen bleibt
trap 'echo; echo "❌ Build abgebrochen!"; read -rp "Enter drücken zum Schließen..."' ERR

# Version abfragen
read -rp "Bitte Version eingeben (z.B. 2.1.0): " version

if [ -z "$version" ]; then
    echo "❌ Keine Version eingegeben!"
    read -rp "Enter drücken zum Schließen..."
    exit 1
fi

PKG="pibackup_pkg"

OUTDIR="/home/pi/git/pibackup/bin"

echo "v$version" > "$OUTDIR/version.txt"


SRC_BIN="/home/pi/git/pibackup/source/pibackup"
ICON="/home/pi/git/pibackup/source/pibackup.png"

echo "🚀 Build pibackup.deb"

# Prüfen ob Binary existiert
if [ ! -f "$SRC_BIN" ]; then
    echo "❌ Binary nicht gefunden: $SRC_BIN"
    read -rp "Enter drücken zum Schließen..."
    exit 1
fi

# Cleanup
rm -rf "$PKG"

# Struktur
mkdir -p "$PKG/DEBIAN"
mkdir -p "$PKG/usr/lib/pibackup"
mkdir -p "$PKG/usr/share/applications"
mkdir -p "$PKG/usr/share/icons/hicolor/256x256/apps"
mkdir -p "$PKG/usr/share/doc/pibackup"
mkdir -p "$PKG/usr/share/doc/pibackup/help"

# Binary
install -Dm755 "$SRC_BIN" \
    "$PKG/usr/lib/pibackup/pibackup"

# Exclude-Dateien → /etc
install -Dm644 /home/pi/git/pibackup/source/dhcp-cleanup.exclude \
    "$PKG/etc/pibackup/dhcp-cleanup.exclude"

install -Dm644 /home/pi/git/pibackup/source/raspberry.exclude \
    "$PKG/etc/pibackup/raspberry.exclude"

install -Dm644 /home/pi/git/pibackup/source/ssh-cleanup.exclude \
    "$PKG/etc/pibackup/ssh-cleanup.exclude"

install -Dm644 /home/pi/git/pibackup/docs/intro.html \
    "$PKG/usr/share/doc/pibackup/help/intro.html"

install -Dm644 /home/pi/git/pibackup/README.md \
    "$PKG/usr/share/doc/pibackup/README.md"

install -Dm644 /home/pi/git/pibackup/CHANGELOG.md \
    "$PKG/usr/share/doc/pibackup/CHANGELOG.md"

install -Dm644 /home/pi/git/pibackup/LICENSE \
    "$PKG/usr/share/doc/pibackup/LICENSE"


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


# conffiles
cat > "$PKG/DEBIAN/conffiles" <<EOF
/etc/pibackup/pibackup.ini
/etc/pibackup/dhcp-cleanup.exclude
/etc/pibackup/raspberry.exclude
/etc/pibackup/ssh-cleanup.exclude
EOF


# Debian-Paket erstellen
#dpkg-deb --build "$PKG"
dpkg-deb --build --root-owner-group "$PKG"

echo
echo "========================================"
echo "✅ Build erfolgreich abgeschlossen!"
echo "Version: v$version"
echo "========================================"
echo
echo "Paket erstellt:"
echo "$PKG.deb"
echo
read -rp "Enter drücken zum Schließen..."