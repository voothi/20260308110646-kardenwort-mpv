# Spec: State-Aware UI Management

## Context
Multiple UI components might need the style override simultaneously.

## Requirements
- Maintain a state-aware logic that tracks if *any* custom UI is currently open.
- Only restore the user's original style when the *last* custom UI component is closed.
- Store the `saved_osd_border_style` in a way that is persistent across multiple UI toggle events.

## Verification
- Open the Drum Window.
- Open the Search HUD.
- Close the Search HUD.
- Verify the override still applies (because Drum Window is open).
- Close the Drum Window.
- Verify the original style is restored.
