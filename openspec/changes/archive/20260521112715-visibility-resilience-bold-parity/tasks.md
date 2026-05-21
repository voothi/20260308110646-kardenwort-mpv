## 1. DW Visibility Resilience

- [x] 1.1 Update subtitle visibility checks in `scripts/kardenwort/main.lua` to check if `FSM.DRUM_WINDOW` is OFF when checking native subtitle visibility.
- [x] 1.2 Verify that tooltip toggle, pairing, smart-add, and search keybindings execute without displaying "X" inside the Drum Window when subtitles are OFF.

## 2. Dynamic Phrase Bold Highlighting

- [x] 2.1 Refactor the highlighting logic in `scripts/kardenwort/main.lua` to conditionally add bold styling (`{\b1}` or `{\b0}`) to database phrase highlights based on `anki_highlight_bold` configuration.
- [x] 2.2 Enforce standard font weight (`{\b0}`) on manual interactive selections in all modes to avoid interference.

## 3. Cache-Backed Context Copying and Fallback

- [x] 3.1 Enhance `append()` helper in `get_copy_context_text()` to support direct subtitle table lookup and fallback to `FSM.DW_TOOLTIP_SEC_SUBS` cache.
- [x] 3.2 Update `cmd_cycle_copy_mode()` to check for translation cache presence when secondary subtitle tracks are visually disabled.
- [x] 3.3 Ensure translation copying fallback in Mode B extracts lines successfully using cache data.

## 4. Verification and Acceptance Testing

- [x] 4.1 Write integration tests in `tests/acceptance/test_20260521111616_visibility_resilience.py` to check visibility resilience inside DW and bold highlighting parity behavior.
- [x] 4.2 Add Mode B copy fallback tests in `tests/acceptance/test_20260427003254_copy_sub_fallback.py` to cover preloaded translation cache.
- [x] 4.3 Execute full acceptance test suite and confirm 100% passing results.
