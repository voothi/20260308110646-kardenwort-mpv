## Why

The current subtitle processing logic in the Anki export system and the ad-hoc "smart joiners" in the Drum Mode display are causing broken punctuation spacing (e.g., `Mal ehrlich ,` and `angeht ?`). This occurs because subtitle tokens are being concatenated with a forced space between them, regardless of punctuation rules. This "distorted" text is then saved to Anki TSV files, which makes cards look unprofessional and also breaks the sentence-boundary detection logic in the context extraction engine. Fixing this ensures that both on-screen and exported text maintain natural, correct subtitle spacing.

## What Changes

- **Unified Smart Joiner**: Implement a robust, central `compose_term_smart` function that handles all common punctuation correctly across languages (German, Russian, English etc.).
- **Raw Context Building**: Refactor `dw_anki_export_selection` to build context strings from the raw subtitle text instead of re-joining tokens.
- **Consistent Truncation**: Update the truncation logic in `extract_anki_context` to use the new smart joiner, maintaining natural spacing even when sentences are shortened.
- **Enhanced Display**: Update `draw_drum` to use the unified smart joiner when `dw_original_spacing` is disabled.

## Capabilities

### New Capabilities
- `smart-joiner-service`: A central logic engine for rebuilding natural strings from word tokens with correct punctuation rules.

### Modified Capabilities
- `anki-export-mapping`: The way context is captured and formatted for Anki TSV export is being updated to prioritize original subtitle formatting.
- `subtitle-rendering`: The display logic for Drum Mode now correctly handles "natural" spacing when the `dw_original_spacing` setting is toggled.

## Impact

- **Affected Code**: `scripts/lls_core.lua` (high impact: joiner logic, export functions, rendering loop).
- **APIs**: No changes to public APIs, internal logic only.
- **Data**: New TSV exports will have clean, natural spacing. Existing TSV files are not retroactively modified.
