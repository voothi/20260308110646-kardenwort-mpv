# Proposal: Fix Export Regressions and Unify Cleaning Pipeline

## Problem Statement

The export logic in `lls_core.lua` currently suffers from two distinct regressions affecting data quality in Anki:

1.  **Pink Selection (Paired) Degradation**: Paired selections have diverged from the standard path, losing essential cleaning (ASS tag and bracket stripping) and reverting to generic periods instead of literal terminal punctuation. Metadata tokens at the end of a line currently block punctuation detection.
2.  **Yellow Selection (Contiguous) Over-inclusion**: The standard selection path is currently over-inclusive when capturing trailing punctuation. It fails to verify if a selection actually ends at the subtitle boundary, resulting in "dangling" characters (like spaces and opening parentheses `(`) from the *next* word being pulled into the export.

## What Changes

1.  **Unified Term Cleaning**: Refactor both export flows to use a shared `clean_anki_term` helper for consistent tag and bracket removal.
2.  **Literal Punctuation Restoration**: Implement a metadata-aware lookahead for Pink selections to capture literal punctuation (`!`, `?`, `...`) while skipping intervening metadata.
3.  **End-of-Line Guard for Yellow Selection**: Update `dw_anki_export_selection` to ensure trailing tokens are only captured if `p2_w` is the final word of the subtitle segment.
4.  **Smart Joiner Integration**: Transition Pink exports to use `compose_term_smart` for consistent token spacing.

## Capabilities

### Modified Capabilities
- `phrase-trailing-punctuation`: Restore parity for paired highlights and implement strict "End of Line" guards for all selection modes.
- `anki-export-mapping`: Ensure metadata and ASS tag cleaning is consistently applied to the `source_word` field.

## Impact

- **Affected Code**: `scripts/lls_core.lua` (specifically `ctrl_commit_set`, `dw_anki_export_selection`).
- **Systems**: Anki TSV export quality will be restored to a clean, high-fidelity state without dangling or synthetic characters.
