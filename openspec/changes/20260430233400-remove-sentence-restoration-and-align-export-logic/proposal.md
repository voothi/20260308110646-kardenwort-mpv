# Proposal: Remove Sentence Restoration and Align Export Logic

## Problem
The current export engine implementation of "Sentence Punctuation Restoration" (Requirement 114) introduces significant complexity, including lookahead logic and capitalization checks, which often conflict with the core principle of **Verbatim String Fidelity** (Requirement 152). Additionally, a parity gap exists between selection modes, and the "Adaptive Gap Detection" for cross-line adjacency is currently implemented as a simple line-boundary trigger, contradicting the spec.

## Goal
Simplify the export pipeline and ensure strict verbatim fidelity by removing the "smart" sentence restoration logic. Simultaneously, align the implementation of gap detection with the specification to provide a consistent cross-line experience without unnecessary ellipses.

## What Changes
1.  **Requirement Removal**: Eliminate Requirement 114 ("Automatic Sentence Punctuation Recovery") from the `sentence-punctuation-normalization` specification.
2.  **Code Cleanup**: Remove `starts_with_uppercase` and the restoration multi-pass logic from `prepare_export_text`.
3.  **Gap Detection Alignment**: Refine the `has_gap` logic in `prepare_export_text` (SET mode) to correctly identify adjacent tokens across consecutive lines, avoiding ellipses when the last word of Line N is followed by the first word of Line N+1.
4.  **Spec Alignment**: Remove Requirement 153 ("Terminal Punctuation Parity") from `anki-export-mapping` as it is rendered obsolete by the removal of the restoration service.

## Capabilities

### Modified Capabilities
- `sentence-punctuation-normalization`: Remove Requirement 114 (Sentence Punctuation Recovery).
- `smart-joiner-service`: Refine "Adaptive Gap Detection" implementation to support cross-line adjacency.
- `anki-export-mapping`: Remove Requirement 153 (Terminal Punctuation Parity).

## Impact
- **LLS Core**: Simplification of `prepare_export_text` and removal of `starts_with_uppercase` helper.
- **Anki Export**: TSV outputs will now strictly reflect the user's selection, including punctuation only if specifically captured in the range or set.
- **User UX**: More predictable export behavior; users must include punctuation in their selection if they want it preserved in the vocab term.
