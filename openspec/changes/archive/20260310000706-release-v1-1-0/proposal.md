## Why

This change formalizes the enhancements introduced in Release v1.1.0 to the Context Copy system. These improvements were necessitated by failures when processing complex `.ass` files with interleaved dual-language tracks and word-by-word karaoke styling.

## What Changes

- Implementation of a deep backward search (up to 10 entries) during subtitle array loading to accurately merge identical raw text lines separated by interleaved translations.
- Implementation of language-aware context fetching that uses character detection (e.g., Cyrillic) to filter out irrelevant tracks during context assembly.
- Refinement of the `get_context_text` logic to ensure the `context_copy_lines` quota is met with true conversational context rather than fragments or translations.

## Capabilities

### New Capabilities
- `context-copy-enhancements`: Improved logic for reassembling sentences from karaoke fragments and filtering interleaved subtitle tracks based on language characteristics.

### Modified Capabilities
- None.

## Impact

- **Reliability**: Context Copy (`Ctrl+X`) now correctly identifies sentence boundaries in complex files.
- **Accuracy**: Exported context contains only relevant language tracks, improving the quality of study materials.
