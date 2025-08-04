# Changelog

All notable changes to this project are documented in this file.

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
