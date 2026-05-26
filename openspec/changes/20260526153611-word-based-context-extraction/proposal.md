## Why

The current context extraction mechanism relies heavily on accurate sentence boundary detection (punctuation and abbreviations) or subtitle line boundaries. However, highly complex, unstandardized, or domain-specific abbreviations (e.g., "Verkehrs-Ausbildungs-Zentrum i. d. Opf. GmbH") can still trigger false splits. In these edge cases, sentence scoping produces incomplete context, while falling back to raw subtitle lines may produce excessively wordy or unreadable context. Providing a purely word-count-based context extraction mechanism (e.g., exactly X words before and Y words after the selection) bypasses punctuation logic entirely, guaranteeing consistent, predictable context sizes for problematic texts.

## What Changes

- Introduce a new context extraction mode that captures a fixed number of words before and after the selected term.
- Add new configuration options for word-based context padding: `anki_context_words_before` and `anki_context_words_after` (or a single `anki_context_pad_words` parameter).
- Add a toggle option (e.g., `anki_context_mode=word`) to select this new third mode (alongside the existing sentence and line modes).
- Ensure the word-based extraction accurately counts logical tokens and ignores ASS tags or subtitle formatting.

## Capabilities

### New Capabilities
- `word-based-context-extraction`: The system SHALL support extracting context by padding the selection with a precise, configurable number of preceding and succeeding words, bypassing punctuation-based sentence boundaries.

### Modified Capabilities
- `adaptive-context-truncation`: Integrating the new word-based padding mode as an alternative to sentence truncation.

## Impact

- **`scripts/kardenwort/main.lua`**: Modifications to `extract_anki_context` and `Options` schema.
- **`mpv.conf`**: New configuration keys for users.
- **Tests**: New acceptance tests for word-based padding boundaries.
