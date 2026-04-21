## Why

The current Drum Window navigation (mode 'w') defaults to selecting the first word of a line when moving vertically with keyboard arrows. This creates a disjointed experience for users accustomed to modern code editors (like VSCode), where the carriage maintains its horizontal position (sticky column) across lines. Additionally, selecting specific substrings or words within long, wrapped lines is currently inefficient.

## What Changes

- **Sticky Column Navigation**: Vertical movement (Up/Down arrows) now preserves the horizontal OSD position. The cursor snaps to the closest word relative to its current horizontal center on the target line, mimicking the VSCode carriage transition.
- **Lazy Position Initialization**: If the cursor is fresh or has been cleared (e.g., by ESC or mouse click), the first vertical move anchors to the current word's center or the middle of the line as a sensible default.
- **Horizontal Persistence**: Horizontal movement (Left/Right arrows) updates the sticky column anchor to the new word's center.
- **Navigation Economy**: Improved word-targeting logic for long subtitles that wrap across multiple visual lines, allowing for faster and more precise interaction.

## Capabilities

### New Capabilities
- `drum-window-sticky-navigation`: Implements a "sticky X" column logic for consistent vertical carriage movement in the Drum Window.

### Modified Capabilities
- `drum-window-highlighting`: Updates the interaction model for keyboard-based word selection and cursor movement.

## Impact

- **`lls_core.lua`**: Significant logic updates to `cmd_dw_line_move` and `cmd_dw_word_move`.
- **FSM State**: Addition of `DW_CURSOR_X` to track the transient sticky horizontal position.
- **User Experience**: Smoother, more predictable keyboard navigation that feels like a professional text editor.
