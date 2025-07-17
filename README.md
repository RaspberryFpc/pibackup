# pibackup

**pibackup** is a portable 64-bit backup and restore tool with a graphical user interface (GUI), specially designed for Raspberry Pi and similar Linux systems.  
It backs up the first two partitions of any storage device (e.g., SD cards, SSDs, HDDs) and supports flexible restoration.

After saving, the tool removes defined files and folders from the image, shrinks it, and efficiently compresses it using **Zstandard (.zst)**.

## Main Features

- **Simple graphical user interface (GUI)**
- No installation required – runs directly
- 64-bit application for Linux
- Automatically backs up the first two partitions (typically `/boot` and `/root`) of the selected device
- Flexible removal of unwanted files and folders via a freely configurable **exclude file**
- Optional removal of SSH and DHCP configurations from the backup
- Shrinks the image after creation to optimize storage usage
- Efficient compression using **zstd**
- Allows saving to other partitions on the same drive
- The uncompressed `.img` backup file is **not deleted** and remains available
- Compressed backups can be created directly as `.img.zst` and used for restoration
- Supports SD cards, SSDs, HDDs, and other block devices

## Restore Features

- Direct restore from **`.img`** or **`.img.zst`** files – no manual decompression needed
- Target device selection via a **drop-down list**
- Target partition size adjustable via a **scrollbar**:
  - Range between the minimum image size and the maximum available storage
- Preview of the planned target partition layout:
  - Displayed in a **grid** showing how the drive will look after restoration
  - Shows partition tables, sizes, types, etc.
  - The grid updates dynamically when adjusting the target size
- Existing partitions remain intact
- Optional deletion of **selected** partitions before restore
- Backup is written directly to the chosen partition without overwriting others (except when deletion is enabled)
- Automatically adjusts the filesystem to fit the size of the partition.

## Graphical Interface

- Clear, self-explanatory GUI
- Select device via drop-down list
- Partition preview via grid display
- Progress indication during backup and restore
- Clear status and error messages

## Exclude File

The **exclude file** is a configurable text file containing a list of files and folders to remove from the image before backup.  
This allows the backup to be cleaned of unnecessary or temporary data to save storage space and reduce image size.

### Exclude File Format

- Each line contains a path (absolute from the root filesystem of the partition) to exclude.
- Wildcards (e.g., `*`) are **not recommended**. Instead, use existing commands to delete multiple files or directories.
- Comments or empty lines are ignored.
- For examples, refer to the existing exclude files.
- For initial usage, use the raspberry.exclude file.
```

## Usage

1. Start the application in a terminal with root privileges:

```bash
sudo /path/to/pibackup/pibackup
```

2. In the GUI:

- Select the device to back up
- Choose target partition and storage location
- Optionally specify an exclude file
- Start the backup process

The tool creates:

- A full **.img** file
- An additional **.img.zst** compressed backup

Both files remain available.

Restore works directly from both file types.

## Requirements

- No installation required
- `zstd` must be installed (`sudo apt install zstd`)
- Root privileges required (start via `sudo`)

## Build Information

* The application was developed using **CodeTyphon** ([https://www.pilotlogic.com/](https://www.pilotlogic.com/)).
* **Qt5** widgetset was used for the GUI.
* Compilation target: **64-bit ARM Linux**.

### Building from source

```bash
# Use CodeTyphon IDE
# Set widgetset to Qt5  - may need recompiling CodeTyphon IDE
# Compile as 64-bit ARM Linux application
```

## License

MIT License – see [LICENSE](LICENSE)

This software is licensed under the MIT License. Additionally, please note: This program performs direct operations on storage devices and filesystems. Improper use may result in data loss. Use entirely at your own risk. The author assumes no responsibility for any damages or data loss – this also applies to damages caused by software bugs or implementation errors.

Diese Software steht unter der MIT-Lizenz. Zusätzlich wird darauf hingewiesen: Dieses Programm arbeitet direkt auf Speichergeräten und Dateisystemen. Unsachgemäße Verwendung kann zu Datenverlust führen. Die Nutzung erfolgt vollständig auf eigenes Risiko. Der Autor übernimmt keine Haftung für Schäden oder Datenverluste – dies gilt auch für Schäden, die durch Programmierfehler oder Implementierungsfehler verursacht werden.


## Author

- PiFpcHub

## Feedback

Issues?  
Please open a GitHub issue.

---

**Note:** This project is currently under development. Features and functionality may change.
