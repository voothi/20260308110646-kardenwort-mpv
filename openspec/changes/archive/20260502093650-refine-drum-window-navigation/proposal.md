## Why

Vertical navigation in the Drum Window (Mode W) and OSD (Mode C) currently treats all logical tokens equally, including punctuation and symbols. This often causes the yellow navigation pointer to land on non-word characters during vertical transitions (UP/DOWN), leading to a "disappearing pointer" experience that disrupts reading and lookup flow.

## What Changes

- **Word-Only Vertical Transitions**: The vertical navigation logic (`cmd_dw_line_move`) will be updated to exclusively target tokens marked as words (`is_word == true`).
- **Punctuation-Inclusive Horizontal Navigation**: Horizontal movement (`cmd_dw_word_move`) and mouse interaction will remain character-inclusive to preserve the ability to surgically select punctuation and symbols (e.g., brackets, hyphens).
- **Line Skipping**: Vertical navigation will now skip over lines that contain no valid word tokens, ensuring the pointer always remains visible on meaningful content.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `drum-window-navigation`: Vertical navigation transitions are refined to exclusively target word tokens and skip symbolic lines, while preserving character-level precision for horizontal and mouse interactions.

## Impact

- `scripts/lls_core.lua`: Modification of `cmd_dw_line_move` and `dw_closest_word_at_x`.
- Navigation experience: Faster, more reliable word-targeting during vertical jumps.
