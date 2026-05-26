## Context

`extract_anki_context` currently anchors the selected term, finds punctuation-aware sentence boundaries across joined subtitle lines, skips configured abbreviations and spaced initialisms, then applies word-count truncation when the resulting sentence is too long. This works well for normal manual subtitles, but some real texts contain organization names and fragments like `Verkehrs-Ausbildungs-Zentrum i. d. Opf. GmbH` where punctuation still looks sentence-like even after abbreviation handling.

The previous word-based proposal in commit `040b6797534953176d6cccc45d8f2f74d9951c1e` solved this by bypassing sentence detection entirely. This change keeps sentence extraction as the primary path and adds optional extensions so users can increase robustness without juggling multiple non-orthogonal modes.

## Goals / Non-Goals

**Goals:**
- Add two word-padding controls: words before the selected span and words after it.
- Keep one primary extraction behavior: current sentence mode.
- Add optional extension parameters that layer on top of the primary behavior.
- Preserve current sentence extraction behavior by default.
- Preserve literal source text between chosen boundaries, including subtitle sentinels normalized to spaces and structural markers such as `##` / `###` when they lie inside the chosen substring.

**Non-Goals:**
- Replacing abbreviation-aware sentence detection.
- Introducing an NLP tokenizer.
- Reworking subtitle-type detection or introducing subtitle-type-specific extraction branches.

## Decisions

1. **Keep sentence as the single main mode**

   Keep sentence extraction as the canonical behavior and compatibility anchor. The change does not add new top-level scope modes.

   Add only two extension options:
   - `anki_context_words_before` (default `0`)
   - `anki_context_words_after` (default `0`)

   These expand sentence-scoped output by a configurable word count on each side.

   Alternative considered: enumerating `sentence`, `sentence-word-padding`, `word-window`, and `auto` in one mode setting. Rejected because the values overlap concerns and increase cognitive load.

2. **Count logical words, preserve literal source substring**

   The implementation should build word spans from the joined context for counting and boundary selection, but return the literal substring from the original joined context between the selected boundary words. Non-word structural markers inside that substring, such as `##` and `###`, are preserved but do not consume before/after word counts.

   Alternative considered: rejoin the selected tokens. That is simpler, but it risks losing exact source punctuation and spacing, which current specs already protect.

3. **Word padding is an extension over sentence output**

   The existing sentence scan decides the base span first. Word padding expands from that base span by `anki_context_words_before` and `anki_context_words_after`.

   If both values are `0`, behavior is identical to current sentence extraction.

4. **Explicit padding influences truncation limits**

   Sentence + padding still allows adaptive truncation for very long results, but the effective limit must be large enough to retain the selected span plus requested extension words when available.

## Risks / Trade-offs

- [Risk] Padding across sentence boundaries may create context that feels less clean than a pure sentence.
  - Mitigation: Padding defaults to `0/0`, so base behavior remains unchanged unless explicitly configured.
- [Risk] Counting logical words while preserving literal substrings can expose edge cases around punctuation-only markers.
  - Mitigation: Reuse the existing word-list/span mapping style and add focused acceptance cases for heading markers and abbreviation-heavy German names.

## Migration Plan

1. Keep sentence extraction as the default and compatibility behavior.
2. Add `anki_context_words_before` and `anki_context_words_after` to `Options`.
3. Factor `extract_anki_context` enough to share selected-span anchoring, word-span indexing, sentence scanning, and literal substring extraction between base behavior and padding extension.
4. Apply optional sentence-output padding after sentence boundaries are found.
5. Update config examples and user-facing documentation.
6. Add focused tests for base behavior and padding extension; do not require a full test run as part of implementation unless requested.

## Open Questions

- Should the before/after counts apply around the selected span or around the detected sentence span when these differ in edge cases?
