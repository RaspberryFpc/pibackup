# Introduction

## How the image is created

1. A 1:1 copy is created from the beginning of the device up to the end of the second partition.  
   The resulting `.img` file contains the MBR, `/boot`, and `/root`.  
   In other words, the complete operating system is stored in this file.  
   Any additional partitions are **not** included in the backup.

2. The `/root` partition is mounted and becomes accessible like a normal filesystem.

3. Unwanted files are removed.

4. The partition is unmounted.

5. The generated partition (image file) is then shrunk:  
   - Unused sectors are overwritten with `0xFF`  
   - This removes leftover data and improves compression efficiency  
   - Both the filesystem size and the image file size are adjusted accordingly

6. Optional compression can be applied.

---

## Restoring the image

### Under Windows

If the image and the target device contain **only `/boot` and `/root`**, the image can be written back using a standard imaging tool without issues.  
The system will boot immediately, but the `/root` partition will be smaller and must be expanded after the first boot (e.g. using `raspi-config`).

If the image was created from the same target device, it can be restored **without data loss on additional partitions**, provided that these partitions have not been moved or resized since the backup.

⚠️ In this case, **do not use `raspi-config` to expand the filesystem**, as it will grow the `/root` partition to the end of the device and overwrite any additional partitions.

Instead, use a partitioning tool that supports ext4 (e.g. DiskGenius or AOMEI Partition Assistant – untested).

---

### Under Linux

Using **pibackup** for restoring is recommended.

1. The MBR is taken from the image and merged with the partition table entries of any additional partitions on the target device.  
   This ensures that existing partitions remain untouched, even if they were moved or resized after the backup was created.

2. The corrected MBR and the image data are written to the target device.

3. Selected options such as:
   - size of the new `/root` partition  
   - passwords  
   - device ID  

   are applied during the restore process.

---

### Note

Extracted passwords are displayed in encoded form.  
If you want to change them, you can simply enter them in plain text.




# pibackup Exclude File Syntax

Exclude files can be used to remove unnecessary files and directories from the backup image before compression.

Default example file:

```text
/etc/pibackup/raspberry.exclude
```

## Syntax

Each line uses the following format:

```text
command = /path
```

Lines starting with `#` are comments.

The placeholder:

```text
§user
```

is automatically replaced with the current username.

---

## Available Commands

### RF = Remove File

Removes a single file.

Example:

```text
rf = /home/§user/.bash_history
```

---

### RD = Remove Directory

Removes an empty directory.

Example:

```text
rd = /home/§user/emptyfolder
```

---

### RT = Remove Tree

Removes a directory and everything inside it.

Example:

```text
rt = /var/lib/snapd
```

---

### RFID = Remove Files In Directory

Removes all files in a directory but keeps subdirectories.

Example:

```text
rfid = /var/backups/*
```

---

### RAID = Remove All In Directory

Removes everything inside a directory, but keeps the directory itself.

Example:

```text
raid = /home/§user/Downloads
```

---

### RAIT = Remove All In Tree

Removes all files and directories inside a directory, including subdirectories, but keeps the top-level directory.

Example:

```text
rait = /tmp
```

---

## Example Exclude Entries

```text
# Temporary directories
rait = /tmp
rait = /var/tmp
rait = /var/cache/apt/archives

# Logs
rait = /var/log

# Browser cache
rait = /home/§user/.cache/mozilla
rait = /home/§user/.cache/chromium

# Downloads folder contents
raid = /home/§user/Downloads

# Snap
rt = /var/lib/snapd
rt = /home/§user/snap
```

---

## Notes

* Commands are case-insensitive.
* Spaces around `=` are optional.
* Invalid or missing paths are ignored.
* Be careful when using `rt`, because it removes complete directory trees.
* `raid` and `rait` are safer if you want to keep the main directory structure.
* Comment out optional entries with `#` if you do not want them to be used.
* The exclude file is processed before shrinking and compression start.

---

# Compression Guide

pibackup uses Zstandard (zstd) with long mode always enabled.

## Compression Levels

### Level 1–3

* Very fast
* Larger backup files
* Good for frequent backups

### Level 4–6

* Best balance between speed and compression
* Recommended for most users
* Suggested default range

### Level 7–10

* Better compression ratio
* Noticeably slower
* Useful if storage space is important

### Level 11–19

* Maximum compression ratio
* Very slow
* Usually only useful for archive backups

## Long Mode (--long)

Long mode is always enabled.

It improves compression by searching further back in the data stream.
This is especially useful for Raspberry Pi images because they often contain many repeated patterns.

Important:

* Lower compression levels with long mode can sometimes achieve similar results faster than higher levels without it.
* Very high compression levels often provide only small additional savings.
* Level 4–6 is usually the best compromise.

## Recommended Levels by Device

### Raspberry Pi 3

* Level 3–5

### Raspberry Pi 4

* Level 4–7

### Raspberry Pi 5

* Level 5–10
