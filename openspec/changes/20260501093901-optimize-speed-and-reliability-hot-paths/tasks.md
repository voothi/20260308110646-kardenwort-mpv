## 1. Token & Metadata Preparation

- [x] 1.1 Update `build_word_list_internal` to pre-calculate `token.lower_clean` (normalized lowercase) for all word tokens.
- [x] 1.2 Refactor `calculate_highlight_stack` and related search helpers to use `token.lower_clean` instead of calling `utf8_to_lower` repeatedly.
- [x] 1.3 Implement "Level 3" (Database) highlight memoization on word tokens within `populate_token_meta` to skip redundant binary searches.

## 2. Hierarchical Layout Caching

- [x] 2.1 Refactor `dw_build_layout` to store wrapped visual lines (`vlines`) and calculated heights on individual subtitle objects.
- [x] 2.2 Implement a centralized `flush_rendering_caches()` helper to invalidate all token and subtitle-level caches.
- [x] 2.3 Ensure `flush_rendering_caches()` is called during TSV reloads, track changes, and option updates.

## 3. Result Cache Reliability Fixes

- [x] 3.1 Update `DRUM_DRAW_CACHE` to include a track identifier (Primary vs Secondary) to prevent content mirroring in dual-track mode.
- [x] 3.2 Update both `DRUM_DRAW_CACHE` and `DW_DRAW_CACHE` to include `#FSM.ANKI_HIGHLIGHTS` in their invalidation keys.
- [x] 3.3 Refactor Draw Caches to store and restore the `hit_zones` geometry table, enabling caching even during interactive playback.

## 4. Verification & Profiling

- [ ] 4.1 Verify that primary and secondary tracks in Drum Mode maintain separate cached content.
- [ ] 4.2 Verify that adding an Anki record triggers immediate visual updates in the Drum Window.
- [ ] 4.3 Profile scrolling performance in the Drum Window to confirm sub-level layout cache effectiveness.
