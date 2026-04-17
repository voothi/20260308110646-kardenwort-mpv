## Why

German compound terms (e.g., `Marken-Discount`, `Amazon-Verteilzentrum`) are currently degraded in two ways:
1. **Highlighting Failure**: The strict neighbor check fails when a word is adjacent to a dash or slash, as symbols aren't recognized as valid context neighbors.
2. **Export Data Loss**: TSV exports (both single and multi-select) either strip dashes entirely or inject extra spaces, breaking the connection between the exported word and the original text.

Additionally, incomplete UTF-8 support for German characters (`ÄÖÜßẞ`) prevents reliable matching and case-insensitive normalization for German media.

## What Changes

- **Robust Neighbor Checking**: The highlighter's context neighbor check will now "skip" over purely punctuational tokens (dashes, slashes, brackets) to find the nearest real word neighbor.
- **Smart Export Joiner**: Implementation of a smart joiner for TSV export that mirrors the OSD's logic, joining tokens without spaces if they are adjacent to a compound separator (`-`, `/`).
- **German Language Support**: Expansion of the `utf8_to_lower` and `starts_with_uppercase` helpers to include German umlauts and the sharp S (`ß`, `ẞ`).
- **Punctuation Preservation**: Multi-select exports will no longer strip internal punctuation from individual tokens, preserving hyphenated compounds in the final Anki card.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `high-recall-highlighting`: Update strict neighbor check to be symbol-agnostic.
- `anki-highlighting`: Add German UTF-8 support for normalization and matching.
- `ctrl-multiselect`: Preserve internal punctuation during term composition.
- `mmb-drag-export`: Implement smart joiner for TSV term composition.

## Impact

- `lls_core.lua`: Highlighting logic, export logic, and UTF-8 utility functions.
- Anki TSV format: Composited terms will now accurately reflect the source text's hyphenation.
