## Context

The `extract_anki_context` function in `scripts/kardenwort/main.lua` relies on scanning forward and backward across multiple subtitle lines (`\0` sentinels) to find real sentence terminators (e.g. `.` `!` `?`). When terminators are not found, or when complex abbreviations trick the heuristic (despite allowlists and spacing protections), the sentence boundary logic can split a sentence prematurely. 
To bypass this entirely, users need an alternative mode that extracts context strictly by word count—padding the selection with an exact number of words before and after. This mode ignores all punctuation and abbreviation logic, guaranteeing robust boundaries for extremely difficult texts.

## Goals / Non-Goals

**Goals:**
- Provide a new context extraction mode (`anki_context_mode=word` alongside existing `sentence` or `line` if applicable, or as a fallback).
- Allow configuration of padding words (`anki_context_words_before` and `anki_context_words_after` parameters).
- Cleanly extract exactly X words before and Y words after the selected term, ignoring sentence punctuation.

**Non-Goals:**
- Removing the existing sentence-based extraction logic.
- Building a full NLP tokenizer (we will continue to use the existing space-delimited word logic or simple Lua patterns).

## Decisions

1. **Extraction Mode Flag (`anki_context_mode`)**:
   - We will introduce a new `Options` setting: `anki_context_mode`, defaulting to `sentence` for backward compatibility.
   - When `anki_context_mode="word"`, `extract_anki_context` will completely bypass the forward/backward terminator scan.
   - *Alternative Considered*: Implicitly enabling word-based extraction if `anki_context_words_before` is set > 0. A dedicated mode flag is cleaner and prevents conflicting configurations.

2. **Word Padding Parameters**:
   - `anki_context_words_before` (default: 8)
   - `anki_context_words_after` (default: 8)
   - These define the exact padding size.
   - *Rationale*: Separating "before" and "after" gives the user fine-grained control over context positioning.

3. **Word Counting Logic**:
   - We will use the existing tokenization and `start_idx`/`end_idx` detection from `adaptive-context-truncation`. The system will slice the word array from `start_idx - before` to `end_idx + after`, clamping to the bounds of the joined context.
   - NUL characters (`\0`) within the extracted slice will be replaced by spaces.

## Risks / Trade-offs

- [Risk] Users might find word boundaries abrupt compared to sentence boundaries.
  - Mitigation: Default to `sentence` mode. Users opt-in to `word` mode for problematic decks.
- [Risk] Punctuation inside the padding might look unnatural if cut off mid-sentence.
  - Mitigation: The exact word boundaries will be preserved. It is a known trade-off of bypassing sentence boundaries.

## Migration Plan

1. Add `anki_context_mode`, `anki_context_words_before`, and `anki_context_words_after` to `main.lua` `Options`.
2. Update `mpv.conf` example/defaults to document the new mode.
3. Update `extract_anki_context` to branch early based on `Options.anki_context_mode == "word"`.
4. Run integration tests to ensure backwards compatibility with `sentence` mode.

## Open Questions

- Should word-based extraction remove partial ASS tags, or rely on the existing stripping?
  - (Assumption: Existing stripping happens earlier in the pipeline, so the context block is already plain text).
