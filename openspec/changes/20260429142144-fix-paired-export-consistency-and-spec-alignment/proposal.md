# Proposal: Fix Paired Export Consistency and Spec Alignment

## Problem
The recent refactoring of the Anki export pipeline has introduced a discrepancy between the implementation and the original specifications. Specifically:
1. **Spec-Implementation Mismatch**: `extract_anki_context` now uses subtitle-line boundaries (`\0`) to define the sentence viewport, which is superior for German abbreviation handling but contradicts the punctuation-based rules in `anki-highlighting/spec.md`.
2. **Feature Disparity**: The "Restore Terminal Period" logic—which ensures that exported sentence-like phrases include a trailing period—is active for standard contiguous (Yellow) selections but missing for non-contiguous (Pink) paired selections.

## Rationale
To maintain high-fidelity Anki exports and architectural integrity, the documentation must reflect the current "subtitle-as-boundary" logic. Additionally, the user experience must be consistent; a paired selection that semantically forms a sentence should receive the same automated punctuation cleaning as a standard drag-selection.

## What Changes
- **Specification Alignment**: Update `openspec/specs/anki-highlighting/spec.md` to formalize the use of subtitle segments as the authoritative boundary for "sentence" context extraction.
- **Implementation Port**: Extract the period-restoration logic from `dw_anki_export_selection` and implement it within `ctrl_commit_set` to ensure Pink highlights are semantically cleaned before export.

## Capabilities

### Modified Capabilities
- `anki-highlighting`: Redefining sentence boundary detection to utilize subtitle segment edges instead of punctuation scanning.
- `anki-export-mapping`: Standardizing terminal punctuation restoration for both contiguous and non-contiguous selections.

## Impact
- **Code**: `scripts/lls_core.lua` (`ctrl_commit_set` function).
- **Documentation**: `openspec/specs/anki-highlighting/spec.md`.
- **Exports**: Improved consistency for non-contiguous Anki cards.
