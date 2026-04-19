# Hardening Grounding Precision Design

## Overview

The legacy highlighting engine relied on a single "Pivot Word" index and "fuzzy neighbor matching" to verify subtitle context. This led to "highlight bleed" and failures to bridge large dialogue gaps. The new architecture enforces **Multi-Pivot Grounding**, where every token in a phrase is mapped to its unique logical coordinate.

## Architecture

### 1. Unified Coordinate System (L:W:T)
Every word in a mining record is now tracked using a tri-coordinate:
- `L`: Line Offset relative to the anchor timestamp.
- `W`: Logical Word Index within that segment.
- `T`: Term Position (the index of the word in the mining phrase).

### 2. Multi-Pivot Search Engine
The highlight engine (`calculate_highlight_stack`) has been refactored:
- **Phase 1 (Contiguous)**: If a card contains multiple anchors, it verifies all coordinates immediately. If they match the track, the match is confirmed as Orange (Contiguous).
- **Phase 2 (Split)**: If words are non-contiguous, it uses a recursive algorithm to find the "best fit" tuple that honors the anchor coordinates while maintaining temporal limits.

### 3. Temporal Boundary Safety
Boundary drift (where a timestamp lands exactly between two subtitles) is addressed by injecting a `+0.001s` (1ms) offset to all export times. This ensures the "Center Subtitle" lookup always hits the intended segment.

## Configuration Tokens

All magic numbers are replaced with tokens from the `Options` table:
- `anki_split_search_window`: Range of lines to search for phrases.
- `anki_split_gap_limit`: Maximum silent time (seconds) between phrase parts.
- `anki_neighbor_window`: Padding for fuzzy fallback matching.
- `anki_local_fuzzy_window`: Fallback window for cards without index data.

## Optimization Strategies

- **Valid Set Caching**: Recursive search results are cached per subtitle word to prevent redundant recalculation during playback.
- **Lazy Map Creation**: Coordinate maps (`__pivots`) are generated only when a card enters the visible window.
