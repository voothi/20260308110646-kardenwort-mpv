## Context

The current highlighting engine is strictly word-based but doesn't handle compounding well. In German, dashes and slashes are frequent in logical compounds. The splitting logic correctly creates separate tokens for these symbols, but the high-recall matcher's neighbor check doesn't "see through" them to verify context. Additionally, the export logic fails to reconstruct these compounds accurately, either stripping separators or adding spaces.

## Goals / Non-Goals

**Goals:**
- Enable high-recall highlighting for hyphenated and slashed compounds by relaxing neighbor strictness to ignore symbol-only tokens.
- Restore visual fidelity of compounds in Anki exports (no extra spaces, no missing dashes).
- Provide full case-insensitive matching support for German (`Ä`, `Ö`, `Ü`, `ß`, `ẞ`).

**Non-Goals:**
- Developing a full UTF-8 normalization library (keep it lightweight and specific to needed languages).
- Changing the word-splitting behavior (tokens remain separate for granular selection).

## Decisions

- **Exhaustive UTF-8 Lowercase Mapping**: Update `utf8_to_lower` and `starts_with_uppercase` to explicitly handle German characters. This is faster and more reliable than locale-dependent Lua `lower()` in varied environments.
- **Neighbor Search Window**: In the strict context check phase of `calculate_highlight_stack`, if an immediate neighbor cleans to an empty string (pure punctuation), the search will expand up to 3 tokens in that direction to find a "real" word neighbor to validate against the context string.
- **Smart Joiner Reuse**: Extract the "Smart Joiner" logic (used in OSD rendering) into a shared helper `compose_term_smart(tokens)`. Use this in `dw_anki_export_selection` and `ctrl_commit_set` to ensure exported terms match the source text's spacing (e.g., `Marken-Discount` instead of `Marken - Discount`).
- **Selective Punctuation Stripping**: In `ctrl_commit_set`, remove the destructive per-token punctuation stripping. Shift punctuation cleaning to the *composed* term level, stripping only leading/trailing punctuation while preserving internal symbols.

## Risks / Trade-offs

- **Fuzzy Match Recall**: Expanding the neighbor check might slightly increase "false positive" highlights if the same word appears nearby with similar symbols, but the 1.5s sub-segment window already mitigates this.
- **Complexity**: Adding a search window to the neighbor check increases the computational cost of highlighting, but since it only triggers on symbol-adjacent tokens, the impact is negligible.
