## Why

The Anki word highlighting system currently exhibits "visual noise" where words from other sentences are highlighted in the current view even when "Global Highlight" is OFF. This happens because the default 10-second temporal window is too broad and context-strictness is disabled, allowing words like "die" to bleed through from previous or upcoming dialogue. Additionally, overlapping card selections (word vs. phrase) from the same sentence cause confusing color stacking.

## What Changes

- **Default Sensitivity**: Update the default configuration to enable strict context matching (`anki_context_strict=yes`) and reduce the local temporal window (`anki_local_fuzzy_window=3.0`).
- **Linguistic Context Binding**: The highlighter will now require that neighbors of a word in the subtitle also appear in the original card's context sentence before applying a highlight in Local mode.
- **Improved Focus**: These changes will ensure that "Local Mode" behaves as expected—only showing the specific words that were marked in the exact sentence they were created from.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `anki-highlighting`: Refine the temporal and contextual matching requirements for localized (non-global) highlights.

## Impact

- **Affected Code**: `scripts/lls_core.lua` (default Options and `calculate_highlight_stack` logic).
- **Configuration**: `mpv.conf` default values for `lls-anki_context_strict` and `lls-anki_local_fuzzy_window`.
- **User Experience**: Drastic reduction in "phantom" highlights in Local Mode.
