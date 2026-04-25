# Spec: Real-Time Scaling Updates

## Context
Scaling must respond immediately to window resizing and track changes.

## Requirements
- Use `mp.observe_property("osd-dimensions", ...)` to detect resizes.
- Use `mp.observe_property("track-list", ...)` to detect subtitle track changes.
- Ensure the scaling logic is re-calculated and applied instantly on property change.

## Verification
- Resize the window and verify the font size adjusts smoothly without delay.
- Switch from an `.ass` track to an `.srt` track and verify scaling is applied correctly to the new track.
