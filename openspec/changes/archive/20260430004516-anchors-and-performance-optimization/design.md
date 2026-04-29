## Context

The current rendering and highlight matching system is functional but exhibits performance degradation when the Anki highlight database grows (linear search overhead). Additionally, "precision anchoring" is required to ensure that split-phrase selections (anchors) maintain absolute fidelity down to the character level, especially for non-contiguous fragments.

## Goals / Non-Goals

**Goals:**
- **O(1) Highlight Lookup**: Transition from $O(N)$ scanning to a word-mapped index.
- **Rendering Caching**: Implement multi-level caching for OSD and Layout metadata to reduce CPU cycles during playback and mouse interaction.
- **Character-Level Precision**: Enhance the anchoring system to support sub-word character offsets for exported phrases.

**Non-Goals:**
- Rewriting the core tokenizer (maintain current `build_word_list_internal`).
- Modifying the Anki TSV format (preserve backwards compatibility).

## Decisions

- **Indexing Strategy**: Build a `FSM.ANKI_WORD_MAP` during TSV load. Each key is a lowercased word, and the value is an array of highlight data objects.
- **Caching Tiers**:
    - **Layout Cache**: Stored on the `sub` object itself to preserve wrapped token metadata across redraws at the same font size.
    - **Draw Cache**: A global `DRUM_DRAW_CACHE` keyed by track (pri/sec) and state (center index, font size, DB version) to skip rendering logic entirely.
- **Anchoring Update**: Extend the `item_index` coordinate string (e.g., `Line:Word:Character`) to support optional character-offset suffix for pinpoint phrase boundaries.
- **Redundancy Reduction**: Pass calculated `active_idx` from the master loop directly into rendering functions to avoid repeated binary searches.

## Risks / Trade-offs

- **Memory Overhead**: Caching layout metadata on every subtitle object increases memory consumption. This is mitigated by the fact that mpv subtitle tracks are typically small (thousands of lines, not millions).
- **Cache Invalidation**: Stale caches could lead to rendering glitches. This is managed by including `FSM.ANKI_DB_MTIME` in cache keys to force-refresh when the database changes.
