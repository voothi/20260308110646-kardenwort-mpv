# Spec: Drum Window Pointer Behavior

## Requirement: Pointer Inactivity
The Drum Window pointer must be inactive (hidden) upon certain triggers to allow uninterrupted full-line copy operations.

### Trigger: Window Toggle
-   **When** the user toggles the Drum Window from `OFF` to `DOCKED` via the `w` key.
-   **Then** `DW_CURSOR_WORD` must be set to `-1`.
-   **Result**: No red highlight on the first word of the active subtitle.

### Trigger: Mouse Scroll
-   **When** the user scrolls the Drum Window using the mouse wheel.
-   **Then** `DW_CURSOR_WORD` must be set to `-1`.
-   **Result**: Any existing word highlight must disappear.

### Trigger: Manual Seek
-   **When** the user seeks between subtitles using the `a` or `d` keys (or Russian equivalents).
-   **Then** `DW_CURSOR_WORD` must be set to `-1`.
-   **Result**: The highlight must disappear after the jump.

## Requirement: Pointer Activation
The pointer must become active and visible upon explicit keyboard navigation intent.

### Trigger: Arrow Key Press
-   **When** `DW_CURSOR_WORD` is `-1` and the user presses any arrow key (`UP`, `DOWN`, `LEFT`, `RIGHT`).
-   **Then** the pointer must become active.
-   **Rule**: 
    - For `UP`/`DOWN`, the pointer should move to the adjacent line and highlight its first word.
    - For `LEFT`/`RIGHT`, the pointer should highlight the first/last word of the current line (already handled by `cmd_dw_word_move` logic).

## Requirement: Copy Priority
-   **When** `DW_CURSOR_WORD` is `-1`.
-   **Then** a copy operation (`Ctrl+c`) must copy the entire subtitle text of the current line (or context, if enabled).
-   **When** `DW_CURSOR_WORD` is `> 0`.
-   **Then** a copy operation must copy only the highlighted word.
