# Proposal: Fix Pink Selection Regressions and Cleaning

## Problem Statement

The paired selection (Pink) export path in `lls_core.lua` has significantly diverged from the standard contiguous selection (Yellow) path following recent refactors. This has introduced several regressions:
1.  **Missing Term Cleaning**: Paired selections do not undergo the same cleaning process as standard selections (ASS tag removal, bracket stripping, punctuation trimming), leading to polluted `source_word` fields in Anki.
2.  **Synthetic Punctuation**: The Pink path restores a generic period (`.`) regardless of the original subtitle punctuation, and this restoration is easily blocked by metadata word tokens (like `[UMGEBUNG]`) that sit between the word and the period.
3.  **Missing Spacing Logic**: Adjacent words in a paired selection are sometimes joined without a space (e.g., `Paketsortierung[UMGEBUNG]`) because the manual concatenation logic lacks the "smart joiner" capabilities of the standard path.

## What Changes

1.  **Unified Term Cleaning**: Refactor the Pink export flow (`ctrl_commit_set`) to use the same robust cleaning pipeline used by Yellow selection.
2.  **Literal Punctuation Restoration**: Update the terminal punctuation logic to capture and restore the actual punctuation tokens from the subtitle, ensuring `!` and `?` are preserved and not replaced by generic periods.
3.  **Metadata-Aware Lookahead**: Fix the terminal punctuation detection to skip metadata tokens when searching for sentence boundaries.
4.  **Smart Joiner Integration**: Ensure contiguous segments within a paired selection are joined using `compose_term_smart` to maintain proper spacing.

## Capabilities

### Modified Capabilities
- `phrase-trailing-punctuation`: Restore parity for paired highlights to ensure consistent punctuation capture across all selection modes.
- `anki-export-mapping`: Ensure metadata and ASS tag cleaning is consistently applied to the `source_word` field in all export paths.

## Impact

- **Affected Code**: `scripts/lls_core.lua` (specifically `ctrl_commit_set` and associated helper logic).
- **APIs**: No changes to external APIs.
- **Systems**: Anki TSV export quality will be restored to high-fidelity state.
