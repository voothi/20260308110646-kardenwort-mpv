## 1. Configuration

- [ ] 1.1 Add `anki_context_mode` (default `"sentence"`) to `Options` in `main.lua`
- [ ] 1.2 Add `anki_context_words_before` (default `8`) and `anki_context_words_after` (default `8`) to `Options` in `main.lua`
- [ ] 1.3 Update `mpv.conf` with commented-out examples and descriptions of the new options

## 2. Core Implementation

- [ ] 2.1 Update `extract_anki_context` to branch based on `Options.anki_context_mode`
- [ ] 2.2 Implement word-based extraction logic: slice the word array from `start_idx - anki_context_words_before` to `end_idx + anki_context_words_after`
- [ ] 2.3 Clamp the sliced bounds to `1` and `#words`
- [ ] 2.4 Join the padded word slice, replacing internal `\0` characters with single spaces
- [ ] 2.5 Ensure the word mode entirely skips the forward/backward terminator search and the adaptive word-count truncation

## 3. Testing

- [ ] 3.1 Create acceptance test verifying word-based extraction mode
- [ ] 3.2 Add test case for padding hitting the start/end boundaries of the context block
