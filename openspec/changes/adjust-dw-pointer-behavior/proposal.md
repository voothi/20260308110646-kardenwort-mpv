# Proposal: Adjust Drum Window Pointer Behavior

## Summary
Change the initialization and scrolling logic of the Drum Window pointer so that no word is highlighted by default. The pointer should only appear once the user interacts with the arrow keys.

## Problem
Currently, when the Drum Window (triggered by `w`) is opened, it automatically highlights the first word of the active subtitle in red. Similarly, when scrolling through subtitles or seeking (`a`/`d`), the pointer often resets or stays on the first word. 

This behavior hinders the user's ability to copy the entire subtitle or its context using `Ctrl+c`, as the copy logic prioritizes the currently highlighted word. Users who want to copy the whole line must first "de-select" the word or avoid moving the pointer, but since it starts selected, it requires extra steps.

## Proposed Solution
1.  **Delayed Pointer Activation**: When the Drum Window is opened, `DW_CURSOR_WORD` should be initialized to `-1` (inactive), so no word is highlighted.
2.  **Scroll/Seek Deactivation**: When the user scrolls with the mouse wheel or uses the `a`/`d` keys to seek, the pointer should be set to `-1`.
3.  **Arrow Key Activation**: Pressing any of the four arrow keys (`UP`, `DOWN`, `LEFT`, `RIGHT`) should activate the pointer and highlight the first word of the current/target line if it was previously inactive.
4.  **Mouse Selection**: Clicking a word with the mouse should still highlight it as usual, overriding the inactive state.

## Benefits
-   **Easier Copying**: Users can copy the full subtitle immediately after opening the window or scrolling without word-level highlights interfering.
-   **Intuitive Interaction**: The pointer only "wakes up" when the user explicitly uses keyboard navigation keys.
-   **Consistency**: Reduces visual noise when just browsing subtitles in the Drum Window.

## Verification Plan
-   Open Drum Window: Verify no word is highlighted.
-   Press `Ctrl+c`: Verify the full subtitle (or context, if enabled) is copied.
-   Press `DOWN`: Verify the pointer appears on the next line's first word.
-   Scroll with Mouse Wheel: Verify the highlight disappears.
-   Press `LEFT`: Verify the pointer appears on the current line's word.
