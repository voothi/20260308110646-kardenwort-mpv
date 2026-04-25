# Spec: Unified Drum Rendering

## Context
Drum Mode lines previously had individual ASS tags, causing background boxes to overlap and bleed padding.

## Requirements
- Concatenate `prev_context`, `active_line`, and `next_context` into a single string.
- Wrap the entire string in a single ASS tag block.
- Ensure that `osd-back-color` (if used) applies to the whole block without internal seams.

## Verification
- Visually inspect Drum Mode with background boxes enabled to ensure no padding overlaps between lines.
- Confirm that the whole block moves as a single unit.
