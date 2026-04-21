## Why

The Drum Window rendering and export engines exhibited several "greedy" behaviors that compromised data precision. Specifically, punctuation marks were incorrectly inheriting intersection colors (Brick) from neighbor words, and the export engine was capturing trailing sentence-ending periods even when they weren't explicitly selected. Overlapping purple selections also lacked visual depth for nesting.

## What Changes

This change implements a "Footprint-based Precision" architecture. Key modifications include:
- **Footprint Shadows**: Re-calculated absolute subtitle timelines are used to detect nesting (showing 3 levels of purple depth) and intersections.
- **Disciplined Punctuation**: Punctuation marks now independently verify their membership in records to prevent "Brick bleed" from neighbor words.
- **Pixel-Perfect Export**: Fractional indexing is used in the export loop to ensure that only physically highlighted tokens (including punctuation) are added to the TSV.
- **Selection Continuity**: A "No-Hole" logic handles multi-line selections by capturing full line tails on non-terminal lines while maintaining precision on the last word.

## Capabilities

### New Capabilities
- `drum-window-high-precision-rendering`: Sub-token stack recalculation for punctuation and 3-tier nesting gradients.

### Modified Capabilities
- `drum-window`: Updated rendering pipeline to use footprint shadows and stack recalculation.
- `drum-window-export`: Shifted to fractional-indexed strict boundary selection.

## Impact

Affects `scripts/lls_core.lua` (Rendering Pass 1/2/3 and `dw_anki_export_selection`). Requires no TSV schema changes as character positions are derived from the exact `WordSource` text.
