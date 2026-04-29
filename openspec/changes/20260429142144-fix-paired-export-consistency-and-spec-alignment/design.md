# Design: Export Consistency and Specification Alignment

## Context
The Anki mining system in `lls_core.lua` currently handles contiguous and non-contiguous selections through different code paths (`dw_anki_export_selection` and `ctrl_commit_set`). While both aim to produce high-quality Anki cards, the contiguous path has undergone more recent stabilization regarding punctuation cleaning. Specifically, it includes logic to restore a terminal period to exported phrases that resemble sentences. This design aims to unify that behavior and align the project's core specifications with the reality of the context extraction engine.

## Goals / Non-Goals

**Goals:**
- **Punctuation Parity**: Ensure that paired (Pink) selections receive the same terminal punctuation cleaning as standard Yellow selections.
- **Specification Integrity**: Update the `anki-highlighting` spec to reflect the move from punctuation-scanning to subtitle-boundary-scanning for sentence context.

**Non-Goals:**
- Changing the fundamental tokenizer or `compose_term_smart` joiner.
- Modifying the Anki mapping profile structure.

## Decisions

### 1. Specification Pivot: Subtitle Boundaries as Sentence Anchors
The `anki-highlighting` specification currently implies a character-based scan for `.`, `!`, or `?` to determine sentence boundaries. 
- **Decision**: Formally redefine the sentence boundary as the **literal edge of the subtitle segment**. 
- **Rationale**: This approach (already implemented in `extract_anki_context`) effectively uses the translator's manual segmentation as a guard against abbreviation false-positives (e.g., `z.B.`, `ca.`), which are notoriously difficult to handle with simple regex in German.

### 2. Functional Parity for Paired Selections
- **Decision**: Port the "Restore Terminal Period" logic into `ctrl_commit_set`.
- **Logic Details**: 
    - Check if the final `term` starts with an uppercase letter (`starts_with_uppercase`).
    - Check if the `term` contains internal spaces (indicating a phrase/sentence rather than a single word).
    - Check if the *raw source text* of the last token in the selection was followed by terminal punctuation.
    - Append `.` if the term does not already end with punctuation.

## Risks / Trade-offs
- **Redundant Punctuation**: There is a slight risk of double-punctuation if the selection logic incorrectly identifies a token boundary. This is mitigated by reusing the existing `not term:match("[.!?]$")` check from the Yellow export path.
