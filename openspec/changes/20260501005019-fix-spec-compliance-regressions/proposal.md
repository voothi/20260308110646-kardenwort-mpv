## Why

The previous attempt to restore compliance with "smart" capture and cleaning logic resulted in unnecessary complexity. The philosophy is shifting to a **Strictly Verbatim** model where the system only processes tokens explicitly captured by the user's manual selection range. Complex mechanics for trailing punctuation lookahead and automatic bracket stripping are being removed to simplify the pipeline and ensure predictability.

## What Changes

- **Simplify Export Pipeline**: Remove lookahead capture logic from `prepare_export_text`. Only tokens within the manual selection range will be exported.
- **Remove Automatic Cleaning**: Disable automatic balanced-bracket stripping in `clean_anki_term`. If a user selects brackets, they are included; if not, they aren't.
- **Simplify Highlight Logic**: (Non-goal/Optional) Revert complex punctuation bridging if it complicates the core stack.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `anki-export-mapping`: REMOVE automatic bracket stripping. Requirements SHALL focus on strict verbatim selection.
- `phrase-trailing-punctuation`: REMOVE bonded capture requirement. Trailing punctuation is only included if explicitly selected.
- `tsv-export-formatting`: REMOVE trailing token lookahead.
- `drum-window-high-precision-rendering`: (Optional) Revert to word-only highlighting if global stream-based rendering is too complex for the current architecture.

## Impact

- `scripts/lls_core.lua`: Simplification of `prepare_export_text`, `clean_anki_term`, and `calculate_highlight_stack`.
- **System Logic**: Reduced maintenance overhead and higher predictability for advanced users.
