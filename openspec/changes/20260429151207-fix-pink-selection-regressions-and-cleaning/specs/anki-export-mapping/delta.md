## ADDED Requirements

### Requirement: Unified Paired Export Cleaning
The paired selection export path (Pink selection) SHALL apply the same metadata and ASS tag cleaning logic as the standard selection path (Yellow selection) for the `source_word` field.

### Requirement: Literal Punctuation Restoration for Paired Highlights
The export system SHALL restore the actual terminal punctuation (e.g., `!`, `?`, `...`) for paired highlights if the selection ends at a sentence boundary. The detection logic SHALL skip metadata tokens (bracketed text) when searching for the terminal punctuation.

### Requirement: Strict Selection Boundaries (End-of-Line Guard)
Standard selection (Yellow) export SHALL NOT capture trailing punctuation or spaces if the selection does not include the final word of the subtitle segment. Opening punctuation characters (e.g., `(`, `[` ) from subsequent words SHALL ALWAYS be excluded from the exported term.

### Requirement: Spacing Consistency
All export paths SHALL use grammar-aware token joining (equivalent to `compose_term_smart`) to ensure consistent spacing around metadata and punctuation tokens.
