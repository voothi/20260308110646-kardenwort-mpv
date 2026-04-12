## Why

Current translation tooltips in the Drum Window do not respect active selection gestures, causing visual overlap and distraction when a user is trying to select, copy, or analyze text. Implementing "Selection-Aware Suppression" ensures the tooltip gracefully steps aside during intensive text interaction.

## What Changes

- **Manual Hint Dismissal**: In CLICK mode (manual peeking), clicking the Left Mouse Button (LMB) instantly hides any pinned tooltip.
- **Selection Suppression**: In HOVER mode (auto-peeking), holding down the LMB (e.g., for dragging) suppresses all tooltips across all lines.
- **Sticky Linger Guard**: After LMB release, the tooltip stays suppressed for the current focused line until the user moves the mouse focus to a different subtitle line.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `drum-window-tooltip`: Added requirements for selection-aware suppression and manual LMB dismissal.

## Impact

- `lls_core.lua`: Update mouse handler and tooltip tick logic to track suppression state and focus changes.
- `input.conf`: No changes required (leverages existing bindings).
