# Changelog
All notable changes to this project are documented in this file.

## [1.7.7] – 2026-04-08

### ✨ Improvements

*Removed checkbox to optionally ignore the MBR signature, no need anymore


## [1.7.7] – 2026-04-08

### Bugfix

* In some cases MBR signature not read properly.Changed MBR reading from low level reading with fpopen to filestream.


## [1.7.6] – 2026-04-08

### Bugfix

* Invalid MBR signature could cause a crash
* Added a checkbox to optionally ignore the MBR signature (the image is checked with e2fsck after creation anyway)
* Improved error messages


## [1.7.5] – 2026-04-07
### Bugfix
- Corrected download instructions in README
- Added missing dependency for Qt5
 
## [1.7.0] – 2026-03-27
### ✨ Improvements
- Installation now via `sudo apt install ./pibackup.deb` from the `/bin` directory  
- No startup script needed anymore.
- Corrected display of transfer speed and written bytes during recover operation with compressed images.
- Updated doc files.

## [1.6.2] – 2025-12-17
### Added
- Info for usersetup

## [1.6.1] – 2025-12-17
### Bugfix
- Fixed issues where unmounting failed due to mount points left behind from earlier runs.

## [1.6.0] – 2025-12-16
### Added
### options useful for setting up a fresh Raspberry Pi OS and headless systems.
- Enable SSH on first boot
- Set or change username and/or password
- Configure Wi-Fi – set or change SSID and password (PSK)

## [1.5.6] – 2025-11-13
### Improved
- Fixed progress bar behavior during resizing
- Perform thread check on shutdown instead of using static timeout

## [1.5.5] – 2025-09-07
### Changed  
- The main function selection buttons have been moved to the top of the form.  
- The progress bar now updates during resize operations.  
- All functions for executing external programs have been moved into a separate unit.  

## [1.5.4] – 2025-09-02
### Improved
- More reliable resource handling and shutdown of background processes.  
- Code simplified: less duplication, clearer execution flow.  

### Added
- External programs (`resize2fs`, `e2fsck`, etc.) are now executed in a separate thread:  
- GUI remains responsive during long-running operations.  
- Progress and cancellation are handled more consistently.  


## [1.5.3] – 2025-08-30
### Improved 
- restore functions

## [1.5.2] – 2025-08-29
### Improved 
- now only a single call to resize2fs is needed.
- Before calling resize2fs, a sync is now executed.

## [1.5.1] – 2025-08-28
### Added
- Added check for free disk space at target before creating image.

### Fixed
- Bugfix: Wrong exclude file was used when removing DHCP.

## [1.5.0] – 2025-08-22
### Improved
- Improved large parts of code

### Added
- Added progressbar

## [1.4.1] – 2025-08-04
### Fixed
- Bugfix: Overwriting of empty blocks after shrinking was incomplete under certain conditions.
- Fixed issue where `raspberry.exclude` caused `dpkg` to fail due to removal of essential package info directories.

### Improved
- More details are now shown in the log display during operations.
- Log output can now be saved to a file via the GUI.
- Improved saving and restoring of user settings between runs.

## [1.4.0] – 2025-07-30
### Added  and removed on 2025-08-01
  - Empty sectors are now overwritten with **0xFF** after shrinking with `resize2fs`:
  - Improves compression of image files
  - Ensures no residual data remains for security reasons

## [1.3.0] – 2025-07-23
### Added
- New `start_pibackup.sh` script:
  - Starts `pibackup` with `sudo` in the background
  - Automatically closes the launching terminal window
- Recommended `.desktop` usage with clean startup behavior
---
## [v1.2.0] – 2025-07-22
- Improved error handling using exceptions.
- Improved partition display in the grid.
---
## [v1.1.1] – 2025-07-20
- Fixed GUI issue in restore process: corrected misplaced input field.
---
## [v1.1.0] – 2025-07-20
- Added option to automatically delete the uncompressed image file after successful compression (checkbox in GUI).
---

## [v1.0.2] – 2025-07-18
- Solved problem when selecting image file for restore.
---

## [v1.0.1] – 2025-07-17
- Improved partition layout preview during restore.
- Minor updates to progress display and status messages.
- UI: Small layout and text improvements.
- Small bugfixes in backup and restore functionality.
---

## [v1.0.0] – 2025-07-15
- Initial public release.
