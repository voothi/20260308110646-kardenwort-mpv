## Why

Recent refactoring (Change `20260430233400`) introduced regressions where mandatory terminal punctuation is stripped from Anki exports, and high-precision rendering rules for punctuation highlighting are being bypassed. This change restores compliance with core specifications to ensure high-fidelity mining data and visual consistency.

## What Changes

- **Restore Trailing Punctuation**: Re-implement lookahead logic in `prepare_export_text` to capture bonded terminal punctuation at the end of selection ranges.
- **Selective Bracket Preservation**: Modify `clean_anki_term` and `compose_term_smart` to preserve outer brackets if they were explicitly included in the user's selection.
- **Semantic Punctuation Highlighting**: Remove the non-word early-exit in `calculate_highlight_stack` and implement the whitespace-blind global search for punctuation highlighting.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `anki-export-mapping`: Clarify that explicit user selection overrides automatic bracket stripping for "professional" cleaning.
- `phrase-trailing-punctuation`: Re-establish the requirement for capturing terminal punctuation bonded to the last word of a selection.
- `tsv-export-formatting`: Restore literal preservation of terminal punctuation in TSV mining records.
- `drum-window-high-precision-rendering`: Restore the requirement for independent, stream-based punctuation highlighting to prevent "white holes" in colored phrases.

## Impact

- `scripts/lls_core.lua`: Significant logic updates to `prepare_export_text`, `clean_anki_term`, `compose_term_smart`, and `calculate_highlight_stack`.
- **Anki Export System**: Restored fidelity of exported terms and context.
- **Drum Window UI**: Restored color-accurate punctuation rendering across line and subtitle boundaries.
