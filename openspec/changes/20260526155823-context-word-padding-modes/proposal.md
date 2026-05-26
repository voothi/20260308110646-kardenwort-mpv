## Why

Sentence-aware Anki context extraction is now much better at handling punctuation, abbreviation allowlists, and spaced German initialisms, but real subtitles can still contain fragments where signatures alone are not enough, such as `Verkehrs-Ausbildungs-Zentrum i. d. Opf. GmbH`. A configurable word-padding layer lets users preserve sentence-boundary behavior while adding a controlled number of words before and after the selected fragment, avoiding both premature abbreviation splits and overly long subtitle-line context.

## What Changes

- Add a context word-padding mechanism with separate before/after settings, for example `anki_context_words_before` and `anki_context_words_after`.
- Keep current sentence extraction as the single primary behavior.
- Apply `anki_context_words_before` and `anki_context_words_after` as optional word-padding extensions over sentence output.
- Ensure the final exported `SentenceSource` remains bounded, readable, and anchored to the selected term even when punctuation or subtitle segmentation is unreliable.

## Capabilities

### New Capabilities
- `context-word-padding`: Defines before/after word padding layered onto sentence-based context extraction.

### Modified Capabilities
- `adaptive-context-truncation`: Clarifies how explicit word padding interacts with the existing maximum-word and wide-selection truncation rules.
- `subtitle-aware-sentence-extraction`: Clarifies that manual-subtitle sentence extraction can be expanded by word padding while retaining abbreviation-aware sentence boundaries.

## Impact

- **`scripts/kardenwort/main.lua`**: New options and extension flow around `extract_anki_context`, with sentence mode remaining primary.
- **`mpv.conf` / documentation**: New commented examples for sentence + padding.
- **Tests**: Focused acceptance coverage for baseline sentence behavior, sentence padding, and abbreviation-heavy German organization names.
