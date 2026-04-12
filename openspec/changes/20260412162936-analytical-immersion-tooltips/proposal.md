## Why

Current translation tooltips in the Drum Window do not respect active selection gestures, causing visual overlap and distraction in the **Analytical Immersion** environment. Implementing "Selection-Aware Suppression" ensures the tooltip gracefully steps aside during intensive text study, selection, and copying.

## What Changes

- **Manual Hint Dismissal**: In CLICK mode (manual peeking), clicking the Left Mouse Button (LMB) instantly hides any pinned tooltip.
- **Selection-Aware Suppression**: In HOVER mode (auto-peeking), holding down the LMB (dragging) suppresses all tooltips across all lines.
- **Symmetrical Linger Guard**: Suppression applies to both the start and end focus lines of an interaction. After LMB release, the tooltip stays suppressed for the line where the drag ended (or where the click occurred) until focus moves to a different subtitle line.
- **Interaction Recovery**: Manual activation (RMB) resets the suppression lock, allowing for immediate re-peeking if desired.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `drum-window-tooltip`: Added requirements for selection-aware suppression and manual LMB dismissal.

## Impact

- `lls_core.lua`: Update mouse handler and tooltip tick logic to track suppression state and focus changes.
- `input.conf`: No changes required (leverages existing bindings).
