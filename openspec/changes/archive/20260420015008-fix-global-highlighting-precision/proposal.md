# Proposal: Global Highlighting Precision Fix

## Problem
The "Anki Global Highlight" mode is currently plagued by two distinct regressions that make it appear "limited" or non-functional:
1. **Split-Phrase Grounding Leak**: Multi-word split terms (identified by `...`) fail to highlight in Global Mode when playback is away from the original record's timestamp. This is because the search logic is incorrectly grounded to `data.time` (the record absolute time) rather than the current playback context.
2. **Brittle Neighbor Verification**: Single words (like "die") use a literal string `find` for neighborhood verification. This sensitivity causes highlights to fail on minor punctuation or formatting differences between the Anki context and the subtitle segment (e.g., "die." vs "die").

## Goal
Restore high-recall, precision highlighting for both contiguous and split terms in Global Mode, ensuring that matches are correctly verified by their surrounding context in a robust, punctuation-agnostic manner.

## What Changes
1. **Un-ground Global Split Matching**: Refactor the Phase 3 split detection loop to operate relative to the currently rendered subtitle segment, effectively ignoring the `data.time` anchor of the original record for segment discovery. 
2. **Implement Word-Based Intersection for Context Verification**: Replace the literal segment searches with a robust word-tokenized check. Verification will succeed if a meaningful subset of neighboring words in the movie matches words in the saved context, regardless of punctuation or ASS tags.

## Capabilities

### Modified Capabilities
- `window-highlighting-spec`: Update requirements for Global Mode neighborhood verification to be word-based rather than literal string-based. Fix temporal grounding constraints for Global Split Matching.

## Impact
- `lls_core.lua`: Significant refactoring of `calculate_highlight_stack` (Phases 2 and 3).
- Highlighting performance: Transitioning to word-based intersection for single words should remain performant due to the small ±3 segment window.
- Accuracy: Eliminates "limited" highlight coverage for multi-word phrases and common words in Global Mode.
