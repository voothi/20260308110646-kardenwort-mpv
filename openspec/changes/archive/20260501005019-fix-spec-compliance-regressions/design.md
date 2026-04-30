## Context

The design philosophy is shifting from "Smart" capture/cleaning to "Strictly Verbatim" selection. This simplification removes all hidden lookahead logic and automatic text filtering, ensuring that the exported Anki cards and UI highlights strictly match the user's manual selection.

## Goals / Non-Goals

**Goals:**
- Eliminate all lookahead capture in `prepare_export_text`.
- Disable automatic bracket/parenthesis stripping in `clean_anki_term`.
- Simplify `calculate_highlight_stack` by removing punctuation bridging.

**Non-Goals:**
- Supporting any form of automatic "professional" cleaning that modifies the user's selected character stream.

## Decisions

### 1. Pure Verbatim Selection
I will revert all lookahead logic in `prepare_export_text`.
- **Logic**: Use the existing `in_range` logic without the `reached_p2_limit` lookahead.
- **Rationale**: If a user wants a period, they must select it. This ensures absolute predictability.

### 2. Bypass Cleaning
I will simplify `clean_anki_term` to its most basic form.
- **Logic**: Remove the balanced-bracket stripping logic entirely.
- **Rationale**: Selection intent is sovereign. Brackets are treated as any other character.

### 3. Word-Only Highlighting
I will revert `calculate_highlight_stack` to its original word-only state.
- **Logic**: Early-exit for any token where `is_word` is false.
- **Rationale**: Reduces complexity and focus the user's attention on word-level acquisition.

## Risks / Trade-offs

- **[Trade-off]** Users must be more precise with their mouse/keyboard selection to include punctuation. → **Benefit**: Higher predictability and lower code complexity.
- **[Trade-off]** Brackets will no longer be colored in parenthetical phrases. → **Benefit**: Clearer distinction between word tokens and logistical punctuation.
