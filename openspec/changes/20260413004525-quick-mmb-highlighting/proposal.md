# Proposal - Quick MMB Highlighting (20260413004525)

## Problem

In the Drum Window (`w` mode), users currently have to perform a two-step process to highlight and export phrases to Anki:
1. Drag the Left Mouse Button (LMB) to select a phrase (highlighted in red).
2. Click the Middle Mouse Button (MMB) on the selection to save/highlight it in green.

This is inefficient for users who frequently export phrases. They would prefer to perform the selection and the export in a single mouse gesture using the MMB.

## Goals

- Enable "Hold-to-Select, Release-to-Export" behavior for the Middle Mouse Button (MMB) in Drum Window mode.
- Maintain existing MMB functionality (the "SCM" or standard export behavior).
- Ensure consistency with existing LMB drag-to-select mechanics.

## What Changes

- **MMB Behavior Update**: The Middle Mouse Button handler in the Drum Window will be upgraded from a simple click handler to a tracking handler (down/move/up).
  - **Down**: Initiate selection (setting Anchor and Cursor) and enable mouse-tracking (similar to LMB).
  - **Move**: Update selection (Cursor) and handle auto-scroll if dragging at window boundaries.
  - **Up**: Finalize selection and automatically trigger the Anki export/highlight logic for the selected range.
- **Independence**: This new behavior will coexist with the standard LMB selection logic, allowing users to still use LMB for non-exporting selections (e.g., for seeking or copying).

## Capabilities

### New Capabilities
- `mmb-drag-export`: Allows initiating a selection by holding MMB and automatically exporting it upon release. This combines visual selection and data export into one action.

### Modified Capabilities
- `high-recall-highlighting`: The export trigger for the high-recall engine is now accessible via a drag-and-release gesture on MMB, in addition to the existing single-click-on-selection method.

## Impact

- `lls_core.lua`: Significant update to `cmd_dw_export_anki` and potential refactoring of the mouse selection logic to share code between `cmd_dw_mouse_select` (LMB) and the updated MMB handler.
- UI: Immediate visual feedback (red highlight during drag, green highlight upon release) for a single interaction.
