# Spec: Dynamic OSD Border Override

## Context
Standard OSD border styles can conflict with custom UI backgrounds.

## Requirements
- Temporarily change `osd-border-style` to `outline-and-shadow` whenever custom UI is active.
- Save the previous style setting before applying the override.
- Ensure the override applies to all OSD text rendered by mpv while active.

## Verification
- Activate "Black Frame" style (`background-box`) in `mpv.conf`.
- Open the Search HUD.
- Verify that the search text does NOT have a black box behind it, but uses the standard outline/shadow.
