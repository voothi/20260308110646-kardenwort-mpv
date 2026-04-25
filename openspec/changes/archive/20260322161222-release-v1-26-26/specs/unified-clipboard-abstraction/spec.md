# Spec: Unified Clipboard Abstraction

## Context
Centralizing clipboard logic prevents code duplication and shell escaping bugs.

## Requirements
- Create `get_clipboard()`: Returns the clipboard content as a string.
- Create `set_clipboard(text)`: Copies the provided string to the clipboard.
- Both functions must handle shell command execution and return codes.
- `set_clipboard` must properly escape quotes to prevent shell interpretation errors.

## Verification
- Call `set_clipboard("Test String")` and verify the clipboard content via a text editor.
- Call `get_clipboard()` after copying text manually and verify the script receives the correct string.
