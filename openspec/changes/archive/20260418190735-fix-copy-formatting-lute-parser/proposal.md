## Why

The transition to the scanner-based "Lute" parser improved highlighting stability but introduced a regression in text reconstruction. Currently, copying text from the Drum Window selection (Ctrl+C) or exporting to Anki loses internal punctuation (e.g., commas) and original spacing, resulting in "sanitized" text that doesn't match the source media.

## What Changes

- **Preserve Original Formatting**: Update the Drum Window copy logic to use the full token stream (including non-word tokens like commas and spaces) when reconstructing selected phrases.
- **Improved Anki Grounding**: Sync the Anki export term composition to preserve punctuation, ensuring the context extractor can find exact verbatim matches in the source text.
- **Robust Range Extraction**: Implement a logical-index aware range extractor that identifies all tokens between the selected start and end points on a per-line basis.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `high-recall-highlighting`: Selection and copy operations must now preserve the exact character sequence (including punctuation and spacing) of the source subtitle segment between the chosen anchors.

## Impact

- **Affected Code**: `scripts/lls_core.lua` (specifically `cmd_dw_copy` and `dw_anki_export_selection`).
- **Systems**: Clipboard management and Anki export pipeline.
