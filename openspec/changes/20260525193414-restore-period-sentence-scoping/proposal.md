## Why

The `SentenceSource` column in exported Anki TSV rows currently captures only the **single subtitle line** containing the selected word, not the full grammatical sentence. For properly-punctuated SRTs (e.g. `20260412001656-hoeren-b2-telc-uebungstest.de.srt`), where a sentence routinely spans 2–3 subtitle lines, this produces fragments like `"die verbreitet als Schnee liegen"` instead of the real sentence `"Es kommt zu kräftigen Niederschlägen, die verbreitet als Schnee liegen bleiben."`

This is a regression introduced by archived change `20260429012045-subtitle-line-sentence-boundaries`, which replaced period-based boundary detection with NUL-sentinel (subtitle-line edge) detection to fix false splits on German abbreviations (`ca.`, `z.B.`, `usw.`). The fix solved abbreviations but broke multi-line sentences. We need a hybrid that handles both cleanly.

## What Changes

- **Replace NUL-sentinel sentence scoping with punctuation-anchored scoping** in `extract_anki_context`. Sentence boundaries are determined by the nearest **real** sentence terminator (`.`, `!`, `?`) on either side of the selection, scanning **across** `\0` subtitle-line sentinels.
- **Reuse and extend the existing abbreviation heuristic** (short-lowercase+period, single-uppercase+period) to skip false terminators during the scan. Heuristic remains the primary defence.
- **Add optional configurable abbreviation allowlist** (`anki_abbrev_list`) with sensible German defaults (`z.B., bzw., usw., ca., d.h., u.a., etc., vgl., ggf., bspw.`). Additive on top of the heuristic.
- **No-terminator fallback**: when neither backward nor forward scan finds a real terminator within the joined context block (e.g. YouTube auto-subtitles with no punctuation at all), return the **entire joined context** as the sentence — NOT the single subtitle line. This preserves the YouTube auto-sub use case at full fidelity.
- **Preserve existing word-count truncation**: `anki_context_max_words` still bounds the final exported context after sentence extraction. Span-padding, precision offset mapping, and verbatim substring slicing are unchanged.
- Sentences MAY legitimately span multiple subtitle lines / a whole paragraph when bounded only by real terminators.

## Capabilities

### New Capabilities
<!-- None -->

### Modified Capabilities
- `subtitle-aware-sentence-extraction`: replace the **Subtitle-Boundary Sentence Scoping** requirement with a new **Punctuation-Anchored Sentence Scoping** requirement; keep **NUL Sanitization in Subtitle Loader**, **Abbreviation-Aware Sentence Boundary Detection**, and **Literal Context Extraction** requirements; extend the abbreviation requirement with the optional configurable allowlist.
- `adaptive-context-truncation`: replace the **Sentence Scoping via Subtitle Boundaries** requirement with a period-anchored equivalent and document the no-terminator fallback. Other requirements (Adaptive Word-Count Truncation, Increased Default Context Buffer, Non-Contiguous Term Context Anchor, Precision Offset Mapping, Adaptive Span Padding) remain unchanged.

## Impact

- `scripts/kardenwort/main.lua` — `extract_anki_context` function (line 2809+), specifically the sentence-scoping block at lines 2898-2921. The backward/forward `\0` searches are replaced with terminator-aware scans; `\0` sentinels remain in the joined context only as a hint for the fallback path.
- `scripts/kardenwort/main.lua` — `Options` table: add `anki_abbrev_list` with German defaults. Read by both the new scoping logic and the existing `is_sentence_boundary` check in `dw_anki_export_selection` for consistency.
- No changes to: TSV schema, Anki field mapping (`anki_mapping.ini`), `mpv.conf` option keys (only an additive option), highlighting / drum-window rendering, or any other capability.
- No breaking changes. Existing user configs continue to work; the new option defaults to a useful German abbreviation list.
- Tests: `tests/acceptance/test_20260509085806_anki_context_verbatim.py` and `tests/acceptance/test_20260509102214_spec_depth_pass2.py` may need fixture updates if they assert on the old single-subtitle-line behaviour.
