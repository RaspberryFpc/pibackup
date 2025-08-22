# pibackup
**Version:** v1.5.0  

**pibackup** is a portable 64-bit **live backup tool** with a graphical user interface (GUI), specially designed for Raspberry Pi and similar Linux systems. It supports **live backups** of running systems, but can also create images from inactive drives. Restores are **safe and flexible**, offering various options.  

Unlike typical SD card tools, it is optimized for large storage devices such as SSDs and HDDs, while still working seamlessly with smaller devices. It creates backups of the first two partitions of any storage device and provides selective restoration. After creating a backup, **pibackup** can automatically remove specified files and folders from the image, shrink it, and compress it efficiently using **Zstandard (.zst)** to save space.  

---

## Main Features
- **Simple graphical user interface (GUI)**
- No installation required – runs directly
- 64-bit application for Linux
- Automatically backs up the first two partitions (typically `/boot` and `/root`) of the selected device
- Flexible exclusion of files and folders via a configurable **exclude file**
- Optional removal of SSH and DHCP configurations from the backup
- Image shrinking after creation to optimize storage usage
- Efficient compression using **zstd**
- Backups can be saved to other partitions on the same drive
- The uncompressed `.img` backup file remains available if compression is disabled or fails
- Compressed backups (`.img.zst`) can be created directly and used for restoration
- Supports SD cards, SSDs, HDDs, and other block devices
- Empty sectors are filled with `0xFF` to improve compression and prevent recovery of residual data  

---

## Restore Features
- Direct restore from **`.img`** or **`.img.zst`** files – no manual decompression required
- Target device selection via a **drop-down list**
- Adjustable target partition size via a **slider**
- Partition size can range between the minimum image size and the maximum available storage
- Live preview of the planned target layout:
  - Displayed in a **grid view** showing partitions, sizes, and types
  - The preview updates dynamically when adjusting the target size
- Existing partitions remain intact by default
- Selective deletion of partitions before restore (optional)
- Backup is written only to the chosen partition unless deletion is enabled
- Filesystem automatically resized to fit the partition by default
- Alternatively, manual partition size adjustment is possible  

---

## Graphical Interface
- Clear, intuitive GUI
- Device selection via drop-down list
- Partition preview in grid view
- Progress indicators during backup and restore
- Clear status and error messages  

## Exclude File

The **exclude file** is a configurable text file containing a list of files and folders to remove from the image. This allows the backup to be cleaned of unnecessary or temporary data to save storage space and reduce image size.

### Exclude File Format

- Each line contains a path (absolute from the root filesystem of the partition) to exclude.
- Wildcards (e.g., `*`) are **not recommended**. Instead, use existing commands to delete multiple files or directories.
- Comments or empty lines are ignored.
- For examples, refer to the existing exclude files.
- For initial usage, use the raspberry.exclude file.

## Usage

Start the application using the provided launch script:

    /path/to/pibackup/start_pibackup.sh

This script:

- Launches `pibackup` with `sudo` and required environment variables
- Runs the application in the background
- Closes the terminal window automatically after launching

You can start it:
- From a terminal, by typing:

      /path/to/pibackup/start_pibackup.sh

- By double-clicking the script in a file manager (make sure it is executable)
- Or via a `.desktop` launcher

## Desktop Launcher
To launch PiBackup from the desktop or applications menu, you can create a `.desktop` file:

#### Example: `PiBackup.desktop`

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

#### Instructions:

1. Save this content as a file named `PiBackup.desktop` in your home folder or on the desktop:

    `/home/pi/Desktop/PiBackup.desktop`

2. Make the file executable:

    ```bash
    chmod +x /home/pi/Desktop/PiBackup.desktop
    ```

3. Optional: If you want to use a custom icon, replace the `Icon=` line with:

    ```ini
    Icon=/home/pi/PiBackup/icon.png
    ```

4. You can also copy the file to `~/.local/share/applications/` to make it appear in the main applications menu.

This launcher uses the `start_pibackup.sh` script, which starts the backup application with the necessary privileges and closes the terminal automatically.

Tip: Make sure both files are executable:
 ```bash
    chmod +x start_pibackup.sh
    chmod +x pibackup
```
> ⚠️ **Note:**  
> Adjust the `Exec=` and `Icon=` paths if your project is located in a different directory.  
> For example, replace `/home/pi/PiBackup/` with your actual installation path.

## In the GUI:

- Select the device to back up
- Choose target partition and storage location
- Optionally specify an exclude file
- Start the backup process

The tool creates:

- A full **.img** file
- An additional **.img.zst** compressed backup

If you wish, both files remain available. The uncompressed .img file is not deleted if the checkbox is unchecked or compression is unsuccessful.

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
# Set widgetset to Qt5  - may needs recompiling CodeTyphon IDE
# Compile as 64-bit ARM Linux application
```

## License

MIT License – see [LICENSE](LICENSE)

This software is licensed under the MIT License. Additionally, please note: This program performs direct operations on storage devices and filesystems. Improper use may result in data loss. Use entirely at your own risk. The author assumes no responsibility for any damages or data loss – this also applies to damages caused by software bugs or implementation errors.

Diese Software steht unter der MIT-Lizenz. Zusätzlich wird darauf hingewiesen: Dieses Programm arbeitet direkt auf Speichergeräten und Dateisystemen. Unsachgemäße Verwendung kann zu Datenverlust führen. Die Nutzung erfolgt vollständig auf eigenes Risiko. Der Autor übernimmt keine Haftung für Schäden oder Datenverluste – dies gilt auch für Schäden, die durch Programmierfehler oder Implementierungsfehler verursacht werden.

## Author

- RaspberryFpc

## Feedback

Issues?  
Please open a GitHub issue.

---

## 📥 Download and Use

Just download the full repository using the **Code → Download ZIP** button, or clone it via Git.

- **Source code** is located in the [`source/`](source/) folder.
- **Ready-to-use binaries** are located in the [`bin/`](bin/) folder.

- Download the full repository using Code → Download ZIP or clone it via Git.
- Important: If you download the repository as a ZIP archive, the executable permissions of the files in the bin/ folder will be lost (this is a limitation of ZIP files). After unpacking, manually make the binary executable:

```bash
chmod +x /path/to/pibackup/pibackup
```

No separate releases are needed.  

> 💡 **Note on Live Backups:**  
> Live backups have been successfully tested and work without problems. They are optional; you can also create backups from inactive drives.  
> However, it is recommended to stop all running programs or perform the backup on a freshly booted system to avoid potential consistency issues.

