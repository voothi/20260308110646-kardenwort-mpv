# Design: Regression Audit and Synchronization (ZID: 20260505004553)

## Context
A surgical audit of the current version (`04eff08`) against the `v1.58.49` baseline and OpenSpec core requirements revealed several implementation gaps. These gaps affect the stability of the TSV sync engine and the robustness of the subtitle parser.

## Goals / Non-Goals

**Goals:**
- **Stability**: Ensure that errors in a single TSV line do not crash the master heartbeat loop.
- **Spec Compliance**: Adhere strictly to `tsv-state-recovery` regarding dynamic header detection.
- **Parser Robustness**: Harden `load_sub` against malformed whitespace in SRT files.
- **Branding Consistency**: Align internal script metadata with the canonical historicity ledger.

**Non-Goals:**
- Refactoring the entire `load_anki_tsv` logic (only hardening and header logic).
- Changing the `mpv` player core configuration.

## Decisions

### 1. TSV Loop Hardening
Wrap the line-processing gmatch loop in `load_anki_tsv` within a anonymous function passed to `pcall`.
- **Rationale**: satisfy `tsv-state-recovery:REQ-9`.
- **Implementation**: `pcall(function() ... end)` inside the file reading block.

### 2. Dynamic Header Identification
Remove the hardcoded `"WordSource"` and `"Term"` strings from the `is_header` check.
- **Rationale**: The `term_header_name` is already correctly derived from `anki_mapping.ini`. Using it exclusively ensures that the system handles custom field names correctly without hardcoded baggage.

### 3. Whitespace Normalization in SRT
Update `clean_text_srt` to trim leading and trailing whitespace using `gsub("^%s*(.-)%s*$", "%1")`.
- **Rationale**: Prevents "phantom" subtitle blocks where a line containing only spaces is interpreted as subtitle text instead of a block separator.

### 4. Metadata Synchronization
Update the project name in the file header of `lls_core.lua`.
- **Rationale**: Sync with `project-terminology-and-historicity:REQ-96`.

## Risks / Trade-offs
- **Performance**: The overhead of `pcall` inside the TSV loop is negligible given the 10s sync period and typical file size (<1000 lines).
- **Trimming**: Aggressive trimming in `clean_text_srt` might affect subtitles that rely on leading/trailing spaces for formatting (rare in SRT/ASS for this project).
