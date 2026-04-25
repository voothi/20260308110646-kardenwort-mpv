# Spec: Style Restoration Verification

## Context
The user's original OSD style must be perfectly restored after using custom UI features.

## Requirements
- After all custom UI components are closed, the `osd-border-style` property must exactly match its value from before the override.
- Standard OSD messages (e.g., volume, seek) must immediately use the restored style.

## Verification
- Change volume after closing the Search HUD.
- Verify that the volume OSD bar/text uses the "Black Frame" style if that was the original user setting.
