# Proposal: Deep Highlight Synchronization for Tooltips

## Problem Statement
While Drum Mode (Mode C) correctly synchronizes highlights across primary and secondary subtitles, the Drum Window (Mode W) currently limits word-level highlights (Yellow Pointer, Pink Selection) to the primary text. The translation tooltip (E), which displays the secondary track, renders only plain text. This creates a disjointed experience where a user cannot visually verify the translation of a selected word within the tooltip's context.

## Objectives
- Synchronize word-level highlights between the Drum Window text and the translation tooltip.
- Ensure that the Yellow Pointer and Pink Selection sets are visually reflected on the corresponding secondary words in the tooltip.
- Maintain parity with Drum Mode (Mode C) behavior by using shared logical indices for cross-track highlight mapping.

## Proposed Changes
- Refactor `draw_dw_tooltip` to incorporate the global highlight engine (`populate_token_meta`).
- Enable highlight rendering for secondary tokens in the tooltip by passing relevant context (line mapping and timing) to the formatting pipeline.
- Update the tooltip rendering logic to use `format_highlighted_word` for every token, ensuring "surgical" highlighting of punctuation and words.

## Modified Capabilities
- `drum-window`: Extend tooltip rendering to support dynamic highlights.
- `subtitle-rendering`: Ensure the highlight engine is compatible with secondary track rendering in tooltip contexts.
