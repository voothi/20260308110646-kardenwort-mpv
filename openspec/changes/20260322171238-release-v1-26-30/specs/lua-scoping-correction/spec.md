# Spec: Lua Scoping Correction

## Context
Lua requires local functions to be defined before use if they are at the same lexical level.

## Requirements
- Move the definition of `is_word_char` so it occurs before the definition of `get_word_boundary`.
- Ensure no other utility functions suffer from similar forward-reference issues.

## Verification
- Start mpv and enter Search Mode.
- Type text and perform word navigation/selection.
- Verify that no "attempt to call a nil value" errors appear in the log.
