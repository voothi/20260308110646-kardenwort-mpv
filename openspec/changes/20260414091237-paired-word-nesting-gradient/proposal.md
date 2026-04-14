## Why

Non-contiguous saved terms (paired words, highlighted in purple) currently do not visually communicate their nesting depth or overlapping status in the same way contiguous saved words do. Contiguous words use a gradient/opacity approach based on their nesting level to ensure overlapping phrases are visually distinct. Applying this same visual logic to paired/split words will unify the visual language of the application and help users better understand complex, overlapping grammatical structures in sentences.

## What Changes

- Update the highlighting logic for non-contiguous paired words (split terms) to calculate their nesting level alongside regular contiguous terms.
- Apply the same alpha/gradient calculations to paired word highlights, adjusting their background opacity based on nesting level so that overlapping terms are visually distinct.
- Ensure that the rendering of purple paired highlights matches the gradient/opacity behavior (e.g., from lighter to darker or varying alpha) seen in the orange contiguous highlights.

## Capabilities

### New Capabilities

### Modified Capabilities
- `inter-segment-highlighter`: Update rendering requirements to include nesting-based gradients for split/paired terms, matching the behavior of contiguous terms.

## Impact

- **Affected code:** TSV parsing and highlighting logic in `lls_core.lua` or similar files handling the Drum Window's rendering of saved terms.
- **Affected features:** Drum Window visual highlighting.
