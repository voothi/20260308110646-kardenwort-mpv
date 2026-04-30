# Proposal: Simplify Specs and Fix Export Fidelity

## Problem
The current OpenSpec documentation contains contradictory requirements regarding punctuation highlighting and tokenization. Specifically, `anki-highlighting` and `unified-drum-rendering` demand "Semantic Punctuation Coloring" and "Atomic Brackets," while `global-semantic-coloring` mandates a "Strict Binding" (Surgical) model where only the word is highlighted. Additionally, the export engine is currently performing "Normalization" (collapsing spaces), which violates the user's requirement for absolute verbatim fidelity.

## Goals
- Finalize the transition to the **Simplified (Surgical) Model** for highlighting and tokenization.
- Remove all contradictory "Semantic Punctuation" requirements from existing specs.
- Restore **Absolute Verbatim Fidelity** to the export engine by removing space normalization.
- Ensure that brackets and other non-word characters are only processed if manually captured by the user.

## What Changes
- **Specifications**: `anki-highlighting`, `unified-drum-rendering`, and `anki-export-mapping` will be updated to remove contradictory requirements (Atomic Brackets, Semantic Punctuation Coloring, and Sentence Restoration references).
- **Export Engine**: `prepare_export_text` and `clean_anki_term` will be modified to remove the `gsub("%s+", " ")` normalization pass, ensuring that multiple spaces and original formatting are preserved.
- **Highlighting Logic**: Highlighting remains strictly word-bound (already partially implemented but needs spec alignment).

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `anki-highlighting`: Remove Requirement 103 (Semantic Punctuation Coloring) and Requirement 114 (Atomic Tokenization) to align with the Surgical Model.
- `unified-drum-rendering`: Update Requirement 13 to clarify that punctuation coloring is NOT performed.
- `anki-export-mapping`: Clarify that "Verbatim Fidelity" (Requirement 112) excludes whitespace normalization.

## Impact
- `scripts/lls_core.lua`: Modifications to `prepare_export_text` and `clean_anki_term`.
- `openspec/specs/`: Updates to multiple specification files to ensure internal consistency.
