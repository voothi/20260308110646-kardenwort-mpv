## Why

Currently, when a highlighted word belongs to *both* a contiguous term (orange) and a split term (purple), the rendering engine awkwardly collapses them into a single type simply based on stack depth priority. The problem is that the visual nesting logic mixes orange bounds and purple bounds into a unitary count, obscuring whether a word is deeply nested within orange highlights, purple highlights, or an intersection of both types. To accurately convey complex nested relationships and intersections of multiple term types, we must track the depth levels of orange and purple terms independently, and when an intersection occurs, render it with a unique set of colors that visually imply a blending of orange and purple, similar to how eBook readers handle intersecting highlight colors visually.

## What Changes

- Refactor `calculate_highlight_stack` to independently count the nesting depth of contiguous (orange) matches and split (purple) matches for a given word.
- Introduce new "mixed" configuration colors (e.g., `anki_mix_depth_1/2/3`) for rendering words that are present in both an orange highlight and a purple highlight simultaneously.
- Update the highlight formatting logic to correctly select pure orange, pure purple, or the new mixed gradient depending on the independent depth tallies.

## Capabilities

### New Capabilities

### Modified Capabilities
- `anki-highlighting`: Modify the split-term rendering requirement to explicitly handle intersections between split terms and contiguous terms, mandating independent depth tracking and distinct mixed-color rendering.

## Impact

- **Affected code:** Highlight stack calculation and render logic in `lls_core.lua` and default option configurations.
- **Side effects:** Increased loop complexity per word to tally both stacks; requires 3 new configuration items in `mpv.conf`.
