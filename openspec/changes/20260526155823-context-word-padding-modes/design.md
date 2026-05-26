## Context

`extract_anki_context` currently anchors the selected term, finds punctuation-aware sentence boundaries across joined subtitle lines, skips configured abbreviations and spaced initialisms, then applies word-count truncation when the resulting sentence is too long. This works well for normal manual subtitles, but some real texts contain organization names and fragments like `Verkehrs-Ausbildungs-Zentrum i. d. Opf. GmbH` where punctuation still looks sentence-like even after abbreviation handling.

The previous word-based proposal in commit `040b6797534953176d6cccc45d8f2f74d9951c1e` solved this by bypassing sentence detection entirely. This change keeps that option, but treats it as one mode in a small extraction policy so manual subtitles can retain sentence boundaries while optionally receiving exact word padding around the selected fragment.

## Goals / Non-Goals

**Goals:**
- Add two word-padding controls: words before the selected span and words after it.
- Add one mode setting that decides whether those controls are disabled, used to expand a sentence-scoped result, or used as the primary word-window extractor.
- Preserve current sentence extraction behavior by default.
- Keep auto-subtitle and manual-subtitle behavior explicit enough that future implementation does not collapse them into one accidental heuristic.
- Preserve literal source text between chosen boundaries, including subtitle sentinels normalized to spaces and structural markers such as `##` / `###` when they lie inside the chosen substring.

**Non-Goals:**
- Replacing abbreviation-aware sentence detection.
- Introducing an NLP tokenizer.
- Reworking subtitle-type detection beyond the minimum needed to select an automatic context mode.

## Decisions

1. **Use one mode option for the third control**

   Add `anki_context_scope_mode` with these values:
   - `sentence`: existing punctuation-aware sentence behavior. This is the backward-compatible default.
   - `sentence-word-padding`: first compute sentence boundaries exactly as today, then expand the chosen substring by `anki_context_words_before` and `anki_context_words_after` logical words.
   - `word-window`: bypass sentence terminator scanning and return the selected span plus the configured before/after word window.
   - `auto`: choose `word-window` for subtitles identified as auto-generated or sentence-unreliable, otherwise choose `sentence`.

   Alternative considered: add a boolean `anki_context_word_padding_enabled`. That would cover on/off but would not express pure word-window behavior or auto/manual policy clearly.

2. **Count logical words, preserve literal source substring**

   The implementation should build word spans from the joined context for counting and boundary selection, but return the literal substring from the original joined context between the selected boundary words. Non-word structural markers inside that substring, such as `##` and `###`, are preserved but do not consume before/after word counts.

   Alternative considered: rejoin the selected tokens. That is simpler, but it risks losing exact source punctuation and spacing, which current specs already protect.

3. **Sentence-word padding expands after sentence scoping**

   In `sentence-word-padding`, the existing sentence scan still decides the base sentence. The word-padding layer then expands outward from that base sentence boundary, not merely from the selected term, so the current sentence extraction remains the primary semantic unit. If a false abbreviation split makes the base sentence too short, the padding can pull in the nearby words needed to make the context usable.

   Alternative considered: always pad around the selected term even in sentence mode. That would make the feature closer to auto-subtitle behavior, but it would weaken the distinction between sentence-based manual subtitles and raw word windows.

4. **Explicit padding influences truncation limits**

   `word-window` mode is already bounded by the configured before/after counts and should skip adaptive truncation. `sentence-word-padding` still allows adaptive truncation for very long results, but the effective limit must be large enough to retain the selected span plus the configured word padding whenever those words exist in the source.

## Risks / Trade-offs

- [Risk] `auto` mode may misclassify subtitle type if reliable metadata is unavailable.
  - Mitigation: Keep `sentence`, `sentence-word-padding`, and `word-window` as explicit user-selectable modes; `auto` can fall back to `sentence` when uncertain.
- [Risk] Padding across sentence boundaries may create context that feels less clean than a pure sentence.
  - Mitigation: Make the behavior opt-in via `sentence-word-padding`; default `sentence` remains unchanged.
- [Risk] Counting logical words while preserving literal substrings can expose edge cases around punctuation-only markers.
  - Mitigation: Reuse the existing word-list/span mapping style and add focused acceptance cases for heading markers and abbreviation-heavy German names.

## Migration Plan

1. Add `anki_context_scope_mode`, `anki_context_words_before`, and `anki_context_words_after` to `Options`.
2. Factor `extract_anki_context` enough to share selected-span anchoring, word-span indexing, sentence scanning, and literal substring extraction across modes.
3. Implement `sentence`, `sentence-word-padding`, `word-window`, and `auto` dispatch.
4. Update config examples and user-facing documentation.
5. Add focused tests for each mode; do not require a full test run as part of implementation unless requested.

## Open Questions

- What signal should implementation use to classify auto-generated subtitles for `auto` mode: track metadata, user option, punctuation density heuristic, or a combination?
- Should `auto` default to the current behavior (`sentence`) until auto-subtitle detection is proven, or should it become available only as an explicit opt-in mode?
