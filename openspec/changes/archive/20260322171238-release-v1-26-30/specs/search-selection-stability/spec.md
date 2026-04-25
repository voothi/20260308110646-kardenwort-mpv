# Spec: Search Selection Stability

## Context
Word-based selection is a core productivity feature for the search interface.

## Requirements
- Ensure `Ctrl+Shift+Left/Right` correctly expands the selection in the search input field.
- Ensure `Shift+Left/Right` correctly selects individual characters.
- Selection must not cause script hangs or UI elements to disappear.

## Verification
- Enter Search Mode.
- Type "Hello World".
- Move cursor to the end.
- Press `Ctrl+Shift+Left`.
- Verify "World" is highlighted.
- Press `w` to open Drum Window and verify the script is still responsive.
