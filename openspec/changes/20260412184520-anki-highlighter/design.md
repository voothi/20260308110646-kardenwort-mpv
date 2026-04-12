# Anki Highlighter Design

**Project:** Anki Vocabulary Highlighter for kardenwort-mpv
**Date:** 2026-04-12

**Goals:**
- Provide a database-like mechanism (`.tsv`) to store and retrieve user-created highlights associated with the video.
- Broaden context capturing by using a configurable sliding window (`lls-anki_context_lines`) that prioritizes sentence-boundary isolation (searching for `.`, `!`, `?` around the term) before applying word-count truncation.
- Implement Whole-Word Matching for all highlights to prevent small words from triggering highlights on unrelated larger terms.
- Use a Temporal Fuzzy Window (`lls-anki_local_fuzzy_window`) for local highlights to allow stacking to work across subtitle edges.
- Visually indicate highlights through compounding depth-based shading using a refined 'Rust' palette for maximum legibility in both Drum and Window modes.

**Non-Goals:**
- Character-by-character native text selection. (We will exclusively use existing word-level tokenization).
- Visual UI for editing TSV entries from within mpv. (Manual TSV editing or external spreadsheet tools are the intended workflow).

## Architecture

1. **Storage Layer**: 
    - A per-video TSV file (`<video_filename>.tsv`) in the video directory.
    - Periodic background synchronization (timer-based) ensures the player reflects external edits to the database without needing a restart.
2. **Highlight Engine**:
    - Highlights are stored as a map of `term` -> `{context, time}`.
    - Rendering uses word-by-word tokenization in the Drum and Window OSDs, injecting ASS `{\1c&H...&}` tags based on how many database entries match the current word (Stacking).
3. **Mining Logic**:
    - Triggered via `MBTN_MID` (Middle Mouse Button) in Drum Window mode.
    - Aggregates the current selection (or word under cursor) and uses a sliding window of subtitle tracks to generate the context field.

## Risks / Trade-offs

- **Risk: Extracted context might lose punctuation semantics at word truncations.** → Mitigation: Prioritize sentence-boundary detection (searching for `.`, `!`, `?` around the term) before resorting to word-limit truncation. Append robust `...` suffixes only if the isolated sentence exceeds `lls-anki_context_max_words`.
- **Risk: Global highlighting can be CPU heavy during active rendering.** → Mitigation: A caching layer or regex compilation step when loading the TSV into memory mapping will keep CPU overhead extremely low on each frame render, avoiding `O(N*M)` nested loops where possible, but since subtitle blocks are very small, the overhead should be negligible even globally.
