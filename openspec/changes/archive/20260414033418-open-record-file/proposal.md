## Why

Currently, users have to manually find and open the record TSV file in the filesystem to review or edit their exports. Providing a quick shortcut ('o') within the Drum Window to open this file in the OS default editor significantly improves the workflow efficiency for language learners.

## What Changes

- Add a new keybinding 'o' (and 'щ' for Russian layout) in the Drum Window.
- Implement a command to open the current record TSV file using the OS default application.
- The command should verify the file existence before attempting to open it and provide OSD feedback.

## Capabilities

### New Capabilities
- `open-record-file`: Provides the ability to quickly open the active TSV record file in an external editor from within the Drum Window.

### Modified Capabilities
- `drum-window`: Updated to include 'o'/'щ' in the managed keybindings when the Drum Window is active.

## Impact

- `scripts/lls_core.lua`: Main logic for keybinding management and file opening command.
- No breaking changes; minimally invasive addition to existing Drum Window logic.
