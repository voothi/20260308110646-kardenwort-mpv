## Why

Sentence-aware Anki context extraction is now much better at handling punctuation, abbreviation allowlists, and spaced German initialisms, but real subtitles can still contain fragments where signatures alone are not enough, such as `Verkehrs-Ausbildungs-Zentrum i. d. Opf. GmbH`. A configurable word-padding layer lets users preserve sentence-boundary behavior while adding a controlled number of words before and after the selected fragment, avoiding both premature abbreviation splits and overly long subtitle-line context.

## What Changes

- Add a context word-padding mechanism with separate before/after settings, for example `anki_context_words_before` and `anki_context_words_after`.
- Add an explicit mode/toggle setting that controls when word padding is applied, so users can choose no padding, sentence-plus-word-padding, pure word-window behavior, or automatic behavior based on subtitle type.
- Preserve the current sentence-boundary machinery for manual subtitles by default, including configurable sentence terminators, abbreviation allowlists, and spaced-initialism exceptions.
- Define auto-subtitle behavior separately so unpunctuated or unreliable auto subtitles can continue to use word-window context without depending on sentence detection.
- Ensure the final exported `SentenceSource` remains bounded, readable, and anchored to the selected term even when punctuation or subtitle segmentation is unreliable.

## Capabilities

### New Capabilities
- `context-word-padding-modes`: Defines configurable before/after word padding and the mode selection policy that decides whether padding augments sentence extraction or replaces it with a word window.

### Modified Capabilities
- `adaptive-context-truncation`: Clarifies how explicit word padding interacts with the existing maximum-word and wide-selection truncation rules.
- `subtitle-aware-sentence-extraction`: Clarifies that manual-subtitle sentence extraction can be expanded by word padding while retaining abbreviation-aware sentence boundaries.

## Impact

- **`scripts/kardenwort/main.lua`**: New options, mode dispatch, and extraction flow changes around `extract_anki_context`.
- **`mpv.conf` / documentation**: New commented examples for mode selection and before/after word padding.
- **Tests**: Focused acceptance coverage for manual sentence-plus-padding, auto word-window behavior, disabled padding, and abbreviation-heavy German organization names.
