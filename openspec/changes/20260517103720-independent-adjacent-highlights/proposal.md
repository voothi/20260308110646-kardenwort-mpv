## Why

When working with subtitle streams that lack standard punctuation and sentence boundaries (such as bad YouTube auto-subtitles), multiple identical phrase fragments can be added as adjacent highlights from different rows in the TSV file. Due to highlight matching and split-match caching being previously keyed solely by raw `term` text, these identical highlights collided: only one of them would be visually rendered/highlighted in the viewport.

Keying the highlights and split-match cache by a per-entry unique identity key rather than just the raw `term` string ensures that adjacent identical highlight regions behave as distinct independent entities.

## What Changes

- **Unique Entry Key Generation**:
  - Update TSV loader (`load_anki_tsv`) to maintain a unique `row_id` counter and append a unique `__entry_key` field to each loaded highlight data table. The entry key is constructed by concatenating `term`, `context`, standard-formatted `time`, `index`, and the unique `row_id` using a pipe (`|`) delimiter.
  - Update `save_anki_tsv_row` to construct a matching `__entry_key` immediately on newly saved rows using the next row ID to maintain in-memory state consistency.
- **Identity-based Highlight Matching**:
  - Update the main highlighting stack calculator (`calculate_highlight_stack`) to use the unique `__entry_key` instead of the raw `term` text as the key for checking if a highlight has already been matched (`matched_terms`).
  - Update the split-term validation cache (`subs[sub_idx].__split_valid_indices`) to be keyed by `__entry_key` instead of raw `term`, preventing collisions of valid split indices across different highlight rows.

## Capabilities

### New Capabilities

*(None)*

### Modified Capabilities

- `anki-highlighting`: Add requirement and test scenario for independent rendering and non-collision of identical adjacent highlights.

## Impact

- `scripts/kardenwort/main.lua`: The logic for loading TSV highlights, saving rows, calculating highlights, and caching split-match indices is modified to be identity-key-aware.
- Regression Test Suite: A new test suite is created to verify that identical adjacent highlights loaded from the TSV (or added dynamically) are fully and independently rendered in the OSD and state trackers.
