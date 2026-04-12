## Why

The current highlighter and capture engine incorrectly include trailing punctuation (periods, commas, question marks) in the color tags and exported Anki cards. This creates a messy visual experience and pollutes the vocabulary database with non-word characters.

## What Changes

- **Punctuation Normalization**: Implementation of a surgical `gsub`-based stripping logic for both on-screen rendering and clipboard export.
- **UTF-8 Safety**: Use of Lua's `%p` class to ensure that German Umlaute (`ä`, `ö`, `ü`) are never accidentally stripped, while all ASCII punctuation is correctly isolated.
- **Clean Interface**: Highlights will now only color the word body, leaving trailing punctuation in the base subtitle color.

## Capabilities

### New Capabilities
- `clean-punctuation-normalization`: Logic for surgical isolation of word bodies from trailing/leading punctuation during rendering and export.

## Impact

- `lls_core.lua`: Refactoring of `format_sub`, `draw_dw`, and `cmd_dw_copy` logic.
