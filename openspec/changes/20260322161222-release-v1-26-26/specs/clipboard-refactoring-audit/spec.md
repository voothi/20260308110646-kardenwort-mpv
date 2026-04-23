# Spec: Clipboard Refactoring Audit

## Context
All existing features must be migrated to the new clipboard abstraction.

## Requirements
- Refactor `cmd_dw_copy` (Drum Window) to use `set_clipboard`.
- Refactor `cmd_copy_sub` (Standard Copy Mode) to use `set_clipboard`.
- Refactor `paste_from_clipboard` to use `get_clipboard`.
- Remove any inline `powershell` command strings from these functions.

## Verification
- Test "Copy Word" in the Drum Window and verify the word is in the clipboard.
- Test "Copy Subtitle" and verify the active subtitle is copied.
- Verify that copying text with special characters (quotes, backslashes) does not break the shell command.
