# Anki Highlighter Design

## Context
A core capability of a specialized language acquisition video player is frictionlessly turning exposed vocabulary into study material (Anki flashcards). The currently existing Drum Window allows text manipulation, pausing, and vocabulary hover-definitions, but lacks a local database mechanism to capture and visually retain highlighted terms across the media duration. 

## Goals / Non-Goals

**Goals:**
- Provide a database-like mechanism (`.tsv`) to store and retrieve user-created highlights associated with the video.
- Broaden context capturing by using a configurable sliding window (`lls-anki_context_lines`) that prioritizes sentence-boundary isolation (searching for `.`, `!`, `?` around the term) before applying word-count truncation.
- Implement Whole-Word Matching for all highlights to prevent small words from triggering highlights on unrelated larger terms.
- Use a Temporal Fuzzy Window (`lls-anki_local_fuzzy_window`) for local highlights to allow stacking to work across subtitle edges.
- Visually indicate highlights through compounding depth-based shading using a refined 'Rust' palette for maximum legibility in both Drum and Window modes.

**Non-Goals:**
- Character-by-character native text selection. (We will exclusively use existing word-level tokenization).
- Implementing Anki-Connect automation; this is purely an exporter to a structured `.tsv`.

## Decisions

**Decision 1: Storage Layer**
- *Choice*: Map a matching `.tsv` to every media file in its directory.
- *Rationale*: A `.tsv` is perfectly mapped directly to Anki, while reading strings out of it is natively trivial in standard Lua `io`. Unlike JSON, a `.tsv` allows direct user auditing in external spreadsheet editors if needed.

**Decision 2: Subtitle Injection & Shading Calculation**
- *Choice*: Compounding Intensity Array tags over literal sub strings.
- *Rationale*: `mpv.conf` will configure layered BGR colors (`lls-anki_highlight_depth_1` ... ` depth_3`). During OSD formatting, every word's indices are checked against the loaded highlight dictionary. Stacks increase the depth level resulting in dynamically inserted ASS tags `{\\c&H...&}` preceding the word. This is infinitely cleaner than drawing nested ASS opaque boxes behind words.

**Decision 3: Global vs Local Re-Evaluation**
- *Choice*: `global` vs `local` highlight burning.
- *Rationale*: For Local mapping, the system checks whether the current media timestamp intersects the definition's captured `time_pos` within the fuzzy window. If Global, the term is highlighted throughout the entire video.

**Decision 4: Periodic Synchronization**
- *Choice*: Implement a configurable periodic background poll (defaulting to every 5 seconds).
- *Rationale*: Periodic syncing ensures the visual highlights in the player stay up-to-date with external edits to the database without restarting the player. Use atomic swaps to prevent memory corruption.

**Decision 5: TSV Formatting**
- *Choice*: Use literal tab characters instead of the `\t` escape sequence for header strings. Use explicit sentence-boundary detection for context.

## Risks / Trade-offs

- **Risk: Extracted context might lose punctuation semantics at word truncations.** → Mitigation: Prioritize sentence-boundary detection (searching for `.`, `!`, `?` around the term) before resorting to word-limit truncation. Append robust `...` suffixes only if the isolated sentence exceeds `lls-anki_context_max_words`.
- **Risk: Global highlighting can be CPU heavy during active rendering.** → Mitigation: A caching layer or regex compilation step when loading the TSV into memory mapping will keep CPU overhead extremely low on each frame render.
