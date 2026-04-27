# Spec: Unified Drum Rendering

## Context
Drum Mode lines previously had individual ASS tags, causing background boxes to overlap and bleed padding.

## Requirements
- Concatenate `prev_context`, `active_line`, and `next_context` into a single string.
- Wrap the entire string in a single ASS tag block.
- Ensure that `osd-back-color` (if used) applies to the whole block without internal seams.

### Rendering Logic
1.  **Metadata Generation**: `calculate_osd_line_meta` must be used to pre-calculate the dimensions of every subtitle line to ensure hit-testing accuracy.
2.  **Highlighting Stack**: The `calculate_highlight_stack` and `format_highlighted_word` utilities must be used to ensure that word-level highlighting (Selections, Database hits) looks identical regardless of the overlay type.
3.  **Active Line Consistency**: Seek and navigation operations must always anchor the visual "Active Line" (White) to the current playback position or cursor position, maintaining a stable focal point.

## Verification
- Visually inspect Drum Mode with background boxes enabled to ensure no padding overlaps between lines.
- Confirm that the whole block moves as a single unit.
