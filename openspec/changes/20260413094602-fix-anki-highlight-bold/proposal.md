## Why

Anki highlight bolding (`anki_highlight_bold=yes`) stopped working in the new Drum Window renderer (`draw_dw`). This regression was likely introduced when the rendering logic was unified, as the bolding tags present in the older `draw_drum` function were not ported to the Drum Window implementation. Restoring this functionality is necessary for users who prefer higher contrast visual feedback for saved vocabulary.

## What Changes

- Restore support for `anki_highlight_bold` in the `draw_dw` (Drum Window) renderer.
- Ensure consistency between the classic `draw_drum` and the new `draw_dw` renderers regarding highlight styling.
- Unify word highlighting logic (surgical punctuation isolation and bolding) into a central helper function to prevent future regressions.

## Capabilities

### New Capabilities
- none

### Modified Capabilities
- high-recall-highlighting: Update the rendering requirements to explicitly include bolding if `anki_highlight_bold` is enabled, ensuring consistent implementation across all active viewports.

## Impact

- `scripts/lls_core.lua`: Modification to `draw_dw` and potential refactoring of word-formatting logic.
- Performance: Negligible (shared code paths).
- Configuration: No changes needed to `mpv.conf`; existing `lls-anki_highlight_bold=yes` will start working again.
