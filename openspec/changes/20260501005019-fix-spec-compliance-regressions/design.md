## Context

The recent removal of "Sentence Punctuation Restoration" (Change `20260430233400`) accidentally stripped away "Phrase Trailing Punctuation Capture" as well. This design restores the capture logic while maintaining the decision to avoid synthetic restoration. It also addresses aggressive bracket stripping in `clean_anki_term` and missing punctuation highlights in the Drum Window.

## Goals / Non-Goals

**Goals:**
- Restore bonded trailing punctuation capture for `RANGE` and `SET` export modes.
- Prevent automatic bracket stripping when brackets are part of an explicit user selection.
- Implement a "semantic bridge" for punctuation highlighting in `calculate_highlight_stack`.

**Non-Goals:**
- Re-introducing synthetic "Sentence Punctuation Restoration" (adding missing periods).
- Modifying the underlying `build_word_list_internal` tokenization.

## Decisions

### 1. Minimal Lookahead for Trailing Punctuation
I will re-implement a targeted lookahead loop in the `RANGE` and `SET` branches of `prepare_export_text`.
- **Logic**: After identifying the last word (`p2_w`), scan subsequent tokens on the same line.
- **Stop Condition**: Stop at the first token where `is_word == true` OR when the line ends.
- **Rationale**: This restores "capture" (including what's there) without "restoration" (adding what's not).

### 2. Selection-Aware Cleaning
Modify `clean_anki_term` to respect the explicit selection boundaries.
- **Logic**: Pass the first and last tokens of the selection to the cleaning service. If the first token starts with an opening bracket and the last ends with a closing one (and they match), bypass the `sub(2, -2)` stripping logic.
- **Alternative considered**: Removing bracket stripping entirely. *Rejected* because "Professional Cleaning" is still desired for MMB clicks (single word) that accidentally catch line-level brackets.

### 3. Punctuation Highlight Bridging
Update `calculate_highlight_stack` to handle non-word tokens.
- **Logic**: If `target_token.is_word` is false, perform a bi-directional global search for the nearest word token. Inherit the highlight state (Orange/Purple stacks) from that neighbor.
- **Rationale**: This prevents "white holes" in highlighted phrases split by punctuation or symbols.

## Risks / Trade-offs

- **[Risk]** Punctuation might inherit "Brick" (mixed) status incorrectly. → **Mitigation**: Use a priority-based inheritance (Purple > Orange) and respect the `logical_idx` distance.
- **[Risk]** Lookahead might include too much whitespace. → **Mitigation**: `prepare_export_text` already uses `build_word_list_internal(text, true)`, so we can filter for `not t.is_word` specifically.
