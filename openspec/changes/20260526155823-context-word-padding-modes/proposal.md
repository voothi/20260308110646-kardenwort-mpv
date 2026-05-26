## Why

Sentence-aware Anki context extraction is now much better at handling punctuation, abbreviation allowlists, and spaced German initialisms, but real subtitles can still contain fragments where signatures alone are not enough, such as `Verkehrs-Ausbildungs-Zentrum i. d. Opf. GmbH`. A configurable word-padding layer lets users preserve sentence-boundary behavior while adding a controlled number of words before and after the selected fragment, avoiding both premature abbreviation splits and overly long subtitle-line context.

## What Changes

- Add a context word-padding mechanism with separate before/after settings, for example `anki_context_words_before` and `anki_context_words_after`.
- Keep current sentence extraction as the single primary behavior (`anki_context_scope_mode=sentence`).
- Add `anki_context_words_before` and `anki_context_words_after` as word-padding extensions over sentence output.
- Add `anki_context_auto_word_window` as an optional auto-subtitle fallback that uses word-window extraction only when auto subtitles are detected.
- Ensure the final exported `SentenceSource` remains bounded, readable, and anchored to the selected term even when punctuation or subtitle segmentation is unreliable.

## Capabilities

### New Capabilities
- `context-word-padding-extensions`: Defines optional extensions layered onto sentence-based context extraction: before/after word padding and optional auto-subtitle word-window fallback.

### Modified Capabilities
- `adaptive-context-truncation`: Clarifies how explicit word padding interacts with the existing maximum-word and wide-selection truncation rules.
- `subtitle-aware-sentence-extraction`: Clarifies that manual-subtitle sentence extraction can be expanded by word padding while retaining abbreviation-aware sentence boundaries.

## Impact

- **`scripts/kardenwort/main.lua`**: New options and extension flow around `extract_anki_context`, with sentence mode remaining primary.
- **`mpv.conf` / documentation**: New commented examples for sentence + padding and optional auto-subtitle fallback.
- **Tests**: Focused acceptance coverage for baseline sentence behavior, sentence padding, optional auto fallback, and abbreviation-heavy German organization names.
