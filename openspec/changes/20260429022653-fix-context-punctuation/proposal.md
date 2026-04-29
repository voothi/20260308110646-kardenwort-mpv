# Proposal: Fix Context Punctuation and Spacing

## Problem
The Anki export system currently mangles punctuation and spacing in the `SentenceSource` (context) field when truncation occurs. Specifically:
1.  **Stuck Tags**: Bracketed tags like `[UMGEBUNG]` are joined to preceding words without a space (e.g., `Paketsortierung[UMGEBUNG]`) because the joiner incorrectly identifies the closing bracket as punctuation that suppresses leading spaces.
2.  **Missing Punctuation**: Truncated context sentences lose all original punctuation and idiosyncratic spacing because they are reconstructed from a word-only list using a lossy joiner logic.

## Solution
1.  **Strict Joiner Rules**: Update `compose_term_smart` to only suppress spaces before/after tokens that are *exactly* a single punctuation character, preventing bracketed words/tags from triggering the rule.
2.  **Substring-Based Truncation**: Refactor `extract_anki_context` to use substrings of the original source string for the viewport. This natively preserves all punctuation, spaces, and formatting between the words that fall within the truncation limit.

## Rationale
Using substrings is more robust and less complex than trying to perfect a "smart joiner" that mimics the original source. It ensures 100% fidelity to the source subtitle text for the extracted context.
