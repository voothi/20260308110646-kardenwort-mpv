## Context

`extract_anki_context` currently anchors the selected term, finds punctuation-aware sentence boundaries across joined subtitle lines, skips configured abbreviations and spaced initialisms, then applies word-count truncation when the resulting sentence is too long. This works well for normal manual subtitles, but some real texts contain organization names and fragments like `Verkehrs-Ausbildungs-Zentrum i. d. Opf. GmbH` where punctuation still looks sentence-like even after abbreviation handling.

The previous word-based proposal in commit `040b6797534953176d6cccc45d8f2f74d9951c1e` solved this by bypassing sentence detection entirely. This change keeps sentence extraction as the primary path and adds optional extensions so users can increase robustness without juggling multiple non-orthogonal modes.

## Goals / Non-Goals

**Goals:**
- Add two word-padding controls: words before the selected span and words after it.
- Keep one primary extraction behavior: current sentence mode.
- Add optional extension toggles that layer on top of the primary behavior.
- Preserve current sentence extraction behavior by default.
- Keep auto-subtitle fallback explicit and optional.
- Preserve literal source text between chosen boundaries, including subtitle sentinels normalized to spaces and structural markers such as `##` / `###` when they lie inside the chosen substring.

**Non-Goals:**
- Replacing abbreviation-aware sentence detection.
- Introducing an NLP tokenizer.
- Reworking subtitle-type detection beyond the minimum needed to select an automatic context mode.

## Decisions

1. **Keep sentence as the single main mode**

   Keep `anki_context_scope_mode=sentence` as the canonical behavior and compatibility anchor. The change does not add new top-level scope modes.

   Add extension options instead:
   - `anki_context_words_before` and `anki_context_words_after` (default `0`): expand sentence-scoped output by a configurable word count on each side.
   - `anki_context_auto_word_window` (default `false`): optional fallback for detected auto/unreliable subtitles that uses word-window extraction around the selected span.

   Alternative considered: enumerating `sentence`, `sentence-word-padding`, `word-window`, and `auto` in one mode setting. Rejected because the values overlap concerns and increase cognitive load.

2. **Count logical words, preserve literal source substring**

   The implementation should build word spans from the joined context for counting and boundary selection, but return the literal substring from the original joined context between the selected boundary words. Non-word structural markers inside that substring, such as `##` and `###`, are preserved but do not consume before/after word counts.

   Alternative considered: rejoin the selected tokens. That is simpler, but it risks losing exact source punctuation and spacing, which current specs already protect.

3. **Word padding is an extension over sentence output**

   The existing sentence scan decides the base span first. Word padding expands from that base span by `anki_context_words_before` and `anki_context_words_after`.

   If both values are `0`, behavior is identical to current sentence extraction.

4. **Auto-subtitle fallback is isolated behind one toggle**

   `anki_context_auto_word_window=false` keeps sentence extraction for all subtitle types.

   `anki_context_auto_word_window=true` allows a fallback to word-window extraction only when subtitles are identified as auto-generated or sentence-unreliable.

5. **Explicit padding influences truncation limits**

   Sentence + padding still allows adaptive truncation for very long results, but the effective limit must be large enough to retain the selected span plus requested extension words when available.

   Auto word-window fallback is already bounded by before/after word counts and should skip adaptive truncation.

## Risks / Trade-offs

- [Risk] Auto-subtitle detection may misclassify subtitle type.
  - Mitigation: Auto fallback is opt-in via `anki_context_auto_word_window`; default stays sentence-only.
- [Risk] Padding across sentence boundaries may create context that feels less clean than a pure sentence.
  - Mitigation: Padding defaults to `0/0`, so base behavior remains unchanged unless explicitly configured.
- [Risk] Counting logical words while preserving literal substrings can expose edge cases around punctuation-only markers.
  - Mitigation: Reuse the existing word-list/span mapping style and add focused acceptance cases for heading markers and abbreviation-heavy German names.

## Migration Plan

1. Keep `anki_context_scope_mode=sentence` as the default and compatibility mode.
2. Add `anki_context_words_before`, `anki_context_words_after`, and `anki_context_auto_word_window` to `Options`.
3. Factor `extract_anki_context` enough to share selected-span anchoring, word-span indexing, sentence scanning, and literal substring extraction between base behavior and extensions.
4. Apply optional sentence-output padding and optional auto-subtitle fallback.
5. Update config examples and user-facing documentation.
6. Add focused tests for base behavior and extensions; do not require a full test run as part of implementation unless requested.

## Open Questions

- What signal should implementation use to classify auto-generated subtitles for `anki_context_auto_word_window`: track metadata, punctuation density heuristic, or a combined strategy?
- Should the fallback be all-or-nothing per track or evaluated per extracted context block?
