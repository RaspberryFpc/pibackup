
#!/bin/bash
set -euo pipefail

# Fehler abfangen, damit das Terminal offen bleibt
trap 'echo; echo "❌ Build abgebrochen!"; read -rp "Enter drücken zum Schließen..."' ERR

# Verzeichnisse
BASE="/home/pi/git/pibackup"
PKG="$BASE/pibackup_pkg"
OUTDIR="$BASE/bin"

SRC_BIN="$BASE/source/pibackup"
ICON="$BASE/source/pibackup.png"

# Version abfragen
read -rp "Bitte Version eingeben (z.B. 2.1.0): " version

if [ -z "$version" ]; then
    echo "❌ Keine Version eingegeben!"
    read -rp "Enter drücken zum Schließen..."
    exit 1
fi

echo
echo "🚀 Build pibackup.deb"
echo "Version: v$version"
echo

# Prüfen ob Binary existiert
if [ ! -f "$SRC_BIN" ]; then
    echo "❌ Binary nicht gefunden:"
    echo "$SRC_BIN"
    read -rp "Enter drücken zum Schließen..."
    exit 1
fi

# Ausgabe-Verzeichnis sicherstellen
mkdir -p "$OUTDIR"

# Version für den Updater schreiben
echo "v$version" > "$OUTDIR/version.txt"

# Altes Build-Verzeichnis löschen
rm -rf "$PKG"

# Altes Paket löschen
rm -f "$OUTDIR/pibackup.deb"

# Paketstruktur
mkdir -p "$PKG/DEBIAN"
mkdir -p "$PKG/usr/lib/pibackup"
mkdir -p "$PKG/usr/share/applications"
mkdir -p "$PKG/usr/share/icons/hicolor/256x256/apps"
mkdir -p "$PKG/usr/share/doc/pibackup/help"
mkdir -p "$PKG/etc/pibackup"

# --------------------------------------------------
# Binary
# --------------------------------------------------

install -Dm755 "$SRC_BIN" \
    "$PKG/usr/lib/pibackup/pibackup"

# --------------------------------------------------
# Exclude-Dateien
# --------------------------------------------------

install -Dm644 "$BASE/source/dhcp-cleanup.exclude" \
    "$PKG/etc/pibackup/dhcp-cleanup.exclude"

install -Dm644 "$BASE/source/raspberry.exclude" \
    "$PKG/etc/pibackup/raspberry.exclude"

install -Dm644 "$BASE/source/ssh-cleanup.exclude" \
    "$PKG/etc/pibackup/ssh-cleanup.exclude"

# --------------------------------------------------
# Dokumentation
# --------------------------------------------------

install -Dm644 "$BASE/docs/intro.html" \
    "$PKG/usr/share/doc/pibackup/help/intro.html"

install -Dm644 "$BASE/README.md" \
    "$PKG/usr/share/doc/pibackup/README.md"

install -Dm644 "$BASE/CHANGELOG.md" \
    "$PKG/usr/share/doc/pibackup/CHANGELOG.md"

install -Dm644 "$BASE/LICENSE" \
    "$PKG/usr/share/doc/pibackup/LICENSE"

# --------------------------------------------------
# Konfigurationsdatei
# --------------------------------------------------

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

# --------------------------------------------------
# Desktop Entry
# --------------------------------------------------

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

# --------------------------------------------------
# Icon
# --------------------------------------------------

install -Dm644 "$ICON" \
    "$PKG/usr/share/icons/hicolor/256x256/apps/pibackup.png"

# --------------------------------------------------
# Debian Control-Datei
# --------------------------------------------------

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

# --------------------------------------------------
# Conffiles
# --------------------------------------------------

cat > "$PKG/DEBIAN/conffiles" <<EOF
/etc/pibackup/pibackup.ini
/etc/pibackup/dhcp-cleanup.exclude
/etc/pibackup/raspberry.exclude
/etc/pibackup/ssh-cleanup.exclude
EOF

# --------------------------------------------------
# Debian-Paket erstellen
# --------------------------------------------------

echo "📦 Erstelle Debian-Paket..."

dpkg-deb --build --root-owner-group \
    "$PKG" \
    "$OUTDIR/pibackup.deb"

# --------------------------------------------------
# Ergebnis prüfen
# --------------------------------------------------

if [ ! -f "$OUTDIR/pibackup.deb" ]; then
    echo "❌ Debian-Paket wurde nicht erzeugt!"
    read -rp "Enter drücken zum Schließen..."
    exit 1
fi

echo
echo "========================================"
echo "✅ Build erfolgreich abgeschlossen!"
echo "========================================"
echo
echo "Version: v$version"
echo
echo "Paket erstellt:"
echo "$OUTDIR/pibackup.deb"
echo
echo "Version-Datei:"
echo "$OUTDIR/version.txt"
echo
ls -lh "$OUTDIR/pibackup.deb" "$OUTDIR/version.txt"
echo
read -rp "Enter drücken zum Schließen..."

