## Why

Recent changes moved the system to a token-driven architecture. During this transition, several regressions were introduced into `lls_core.lua`. These regressions break cross-subtitle neighbor matching, change highlight coloring definitions erroneously, and disable subtitle merging in a way that may cause visual artifacts. Fixing these is critical for maintaining high subtitle processing quality and visual consistency.

## What Changes

- Fix the cross-segment neighbor lookup in `get_relative_word_text` by correctly adjusting target indices when switching between subtitle segments.
- Restore the original highlight color logic: contiguous phrases should remain Orange (Contiguous), while Purple (Split) is strictly reserved for non-contiguous scattered words.
- Restore subtitle merging for ASS tracks (safe merging that respects export accuracy).
- Standardize selection and export logic to fully utilize the new token-based architecture instead of raw string manipulation.
- Optimize the `calculate_highlight_stack` performance by reducing redundant token iterations.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `subtitle-rendering`: Fix regression in high-precision highlighting and neighbor matching across segments. Update color logic for long contiguous phrases.

## Impact

- `scripts/lls_core.lua`: Significant logic adjustments in highlighting and token processing.
- Drum Window (Mode W): Direct visual impact on word highlighting and selection colors.
- Anki Export: Higher reliability in context and term extraction.
