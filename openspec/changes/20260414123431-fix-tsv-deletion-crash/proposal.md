## Why

Deleting or clearing the currently active TSV record file while the script is running causes a silent failure when later attempting to open the Drum Window or access script functionality. The script is incorrectly assuming the file exists and has content, leading to a breakdown of UI initialization (the Drum Window "does not work" and shows "nothing familiar") and potentially causing silent initialization crashes with no clear error messages. This change resolves the fragility by introducing robust file existence checks, fallback creation routines, and error handling for empty/missing TSV files.

## What Changes

- Add robust existence checks for the target TSV file before parsing or opening the Drum Window.
- Automatically recreate the TSV file with appropriate headers if it has been deleted or is missing.
- Ensure the script correctly handles empty TSV files without throwing runtime exceptions.
- Add user-facing error messages (via OSD) when unexpected file state errors occur that cannot be automatically recovered.
- Ensure the Drum Window gracefully degrades or rebuilds its state instead of freezing when TSV file reads fail.

## Capabilities

### New Capabilities

- `tsv-state-recovery`: Graceful handling, recreation, and recovery of deleted or cleared TSV record files during runtime.

### Modified Capabilities

- `drum-window`: The initialization routine must now guarantee resilience against missing or empty TSV files.

## Impact

- `lls_core.lua` or relevant TSV parsing/highlighting scripts will safely default to empty states when file reads fail.
- `kardenwort.lua` (or equivalent main script) will maintain a stable run state even if external file states change externally.
- Drum Window initialization flow.
