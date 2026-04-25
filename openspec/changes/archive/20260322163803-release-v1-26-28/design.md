# Design: Search Box Visibility Fix (OSD Styling)

## System Architecture
The fix is implemented as a state-aware utility within `lls_core.lua` that intercepts UI state changes.

### Components
1.  **State Manager (`manage_ui_border_override`)**:
    - Saves the current `osd-border-style` to `saved_osd_border_style` upon the first custom UI activation.
    - Sets `osd-border-style` to `outline-and-shadow`.
    - Monitors a "reference count" or boolean logic to determine when to restore the saved style.
2.  **UI Triggers**:
    - **Search HUD**: Triggers the override when the search input is focused.
    - **Drum Window**: Triggers the override when the window is toggled on.

## Implementation Strategy
- **FSM Integration**: Store the `saved_osd_border_style` in the script's central state to ensure persistence across command calls.
- **Robust Restoration**: The restoration logic must be called whenever a UI component is dismissed, but must verify that no other overriding UI is still visible.
- **Visual Baseline**: `outline-and-shadow` is used as the override target because it provides the most legible results on the beige background panels used by the suite.
