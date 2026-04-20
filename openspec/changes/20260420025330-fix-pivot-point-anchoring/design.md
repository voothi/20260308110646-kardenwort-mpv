# Design: Precise Pivot-Point Anchoring

## Context
The Drum Window (Mode W) allows users to export vocabulary terms to Anki. When an export is triggered, the system extracts a context block (usually ±N segments) and searches for the term within it. To resolve ambiguity (e.g., duplicate words in the same segment), the system uses a `pivot_pos` to find the occurrence closest to the user's click point.

Currently, this `pivot_pos` is calculated as the geometric center of the subtitle line. This causes "search drift" where the engine selects the wrong occurrence if it's closer to the line's center than the user's focus point.

## Goals / Non-Goals

**Goals:**
- Implement precise character-offset calculation for the pivot point.
- Ensure the calculation accounts for ASS tags, metadata brackets, and space collapsing EXACTLY as the final context block does.
- Fix both contiguous ranges (MMB) and non-contiguous sets (Ctrl+MMB).

**Non-Goals:**
- Changing the `extract_anki_context` search logic (it works fine if the pivot is correct).
- Refactoring the general Anki export flow.

## Decisions

### 1. Marker-Based Pivot Extraction
Instead of manually calculating byte offsets by summing token lengths (which is error-prone when combined with multiple `gsub` cleanup steps), we will use a **Marker Injection** strategy.

**The Workflow:**
1.  During the `pivot_pos` calculation loop in `dw_anki_export_selection` and `ctrl_commit_set`:
2.  When processing the "focus" line (the one containing the clicked word):
    -   Split the segment into tokens using `build_word_list_internal(text, true)`.
    -   Reconstruct the line text, but replace the target word's characters with a unique, improbable marker string like `___PIVOT_MARKER___`.
    -   Insert this "marked" text into the context construction logic.
3.  After the entire context block has undergone its final cleanup (`gsub` for tags, then metadata, then space collapsing):
    -   Find the byte position of `___PIVOT_MARKER___` in the cleaned string.
    -   The `pivot_pos` is then: `MarkerStart + (#CleanedTargetWord / 2)`.
4.  Remove the marker from the final context string before passing it to Anki.

**Rationale:** This approach is "future-proof" against changes in the cleaning logic (like new tag patterns or different space-collapsing rules), as the marker travels through the same pipeline as the actual text.

### 2. Unified Helper Function
We will encapsulate this logic into a helper to ensure `dw` and `ctrl` exports remain consistent.

## Risks / Trade-offs

- **Risk**: The marker string `___PIVOT_MARKER___` might accidentally overlap with real subtitle text (highly unlikely given it contains triple underscores).
- **Trade-off**: Slightly higher string allocation cost during export. Given exports are infrequent user actions, this is an acceptable trade-off for 100% precision.
