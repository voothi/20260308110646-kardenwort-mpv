## Why

To improve the continuity of language immersion sessions by eliminating the need to manually locate and reload the last video file and its associated subtitle tracks every time MPV is launched. Currently, starting MPV without a file argument results in a blank interface, creating friction for users who consume content in multiple sessions.

## What Changes

- **New Script**: Implementation of `resume_last_file.lua` to manage session persistence.
- **Session Tracking**: Automatic recording of the absolute path of the last played media file.
- **Auto-Resume**: Logic to automatically reload the last file on startup if no media is provided via command-line arguments.
- **Enhanced OSD Feedback**: A clean, vertical OSD layout displaying the resumed filename and a prioritized list of connected sidecar subtitle files.
- **Configurable Parameters**: New user-tunable options for OSD font size, message duration, and track visibility toggles.

## Capabilities

### New Capabilities
- `session-persistence`: Logic to save and restore the last played media path.
- `startup-diagnostic-osd`: A clean OSD notification system that displays the loaded file and prioritized subtitle tracks (Main vs Secondary) upon session restoration.

### Modified Capabilities
- None

## Impact

- **Affected Code**: Addition of `scripts/resume_last_file.lua`.
- **User Experience**: Immediate transition from application launch to content consumption.
- **Configuration**: New configuration keys available at the top of the script for user calibration.
