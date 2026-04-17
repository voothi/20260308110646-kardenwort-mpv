## Context

The current `lls_core.lua` implementation of the Anki highlighter relies on a generous temporal window (10.0s) and an optional context-check that is disabled by default. This leads to "visual noise" where common words are highlighted in sentences unrelated to the card's origin.

## Goals / Non-Goals

**Goals:**
- Implement "Strict Context" as the default behavior for localized highlights.
- Tighten the temporal matching window to prevent bleed-through across distinct dialogue segments.
- Align the `mpv.conf` configuration with these precision-focused defaults.

**Non-Goals:**
- Modifying "Global Highlight" mode (which should remain inclusive).
- Implementing "longest match" deduplication (as requested by user).

## Decisions

- **Enable `anki_context_strict` by default**: Set `Options.anki_context_strict = true` in the core script and `lls-anki_context_strict=yes` in `mpv.conf`. Rationale: Text-only matching on common grammatical particles is insufficient in local mode.
- **Set `anki_local_fuzzy_window` to 3.0s**: This provides enough buffer for subtitle timing variances while effectively cutting off matches from neighboring sentences (which typically have a >3s gap between centers).
- **Update Core Defaults**: Ensure `lls_core.lua` has these as hardcoded defaults so new installations benefit immediately without requiring `mpv.conf` edits.

## Risks / Trade-offs

- **Sensitivity to Context Mismatch**: If a subtitle line is significantly cleaned/modified during export, the neighbor check might fail to find matches in the context sentence. However, the existing implementation's use of lowercase and punctuation stripping (`utf8_to_lower(nw:gsub("[%p%s]", ""))`) provides sufficient fuzzy tolerance.
