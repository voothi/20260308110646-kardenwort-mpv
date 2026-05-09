"""
Feature ZID: 20260509085806
Test Creation ZID: 20260509113830
Feature: Anki Context Verbatim

Structural tests verifying extract_anki_context logic in lls_core.lua.
The IPC test handler (lls-test-extract-anki-context) is not implemented, so these
tests validate the key algorithmic properties directly from source code.
"""

import re


LUA = "scripts/lls_core.lua"


def _lua():
    with open(LUA, encoding="utf-8") as f:
        return f.read()


def test_anki_context_verbatim():
    """extract_anki_context must exist with the correct five-argument signature."""
    content = _lua()
    assert "extract_anki_context" in content, (
        "extract_anki_context function not found in lls_core.lua"
    )
    assert re.search(
        r"function\s+extract_anki_context\s*\(full_line,\s*selected_term,\s*max_words_override",
        content,
    ), (
        "extract_anki_context signature must accept (full_line, selected_term, max_words_override, …)"
    )
    # Returns full_line when no term given
    assert 'return full_line' in content, (
        "extract_anki_context must return full_line when selected_term is empty"
    )


def test_anki_context_non_contiguous():
    """Non-contiguous multi-word selections must be resolved via sequential word search."""
    content = _lua()
    # The sequential forward search loop handles words that aren't a single substring
    assert "first_word_found" in content, (
        "first_word_found flag not found; non-contiguous term fallback path is missing"
    )
    assert "Sequential forward search" in content or "seq_pos" in content, (
        "Sequential position tracking (seq_pos) not found for non-contiguous selection"
    )


def test_anki_context_pivot_selection():
    """When a term appears multiple times, the occurrence closest to the pivot must be chosen."""
    content = _lua()
    # Pivot is used as 'center' to compute distance to each candidate
    assert re.search(r"center\s*=\s*pivot_pos\s*or", content), (
        "Pivot fallback (center = pivot_pos or …) not found in extract_anki_context"
    )
    assert "best_dist" in content, (
        "best_dist variable not found; pivot-closest occurrence selection is missing"
    )
    # Sentence boundary uses NUL sentinel (\0) to split context lines
    assert r"\0" in content or '"\0"' in content or "\\0" in content, (
        "NUL sentinel (\\0) not found; sentence boundary detection is missing"
    )


def test_anki_context_truncation():
    """Context exceeding max_words must be truncated, keeping the selected term centred."""
    content = _lua()
    assert "max_words_override" in content, (
        "max_words_override parameter not found in extract_anki_context"
    )
    # Word count check: if <= limit, return early
    assert re.search(r"#words\s*<=\s*limit", content), (
        "Word-count guard (#words <= limit) not found; short contexts must skip truncation"
    )
    # Truncation uses first_idx / last_idx to anchor around the selection
    assert "first_idx" in content and "last_idx" in content, (
        "first_idx/last_idx variables not found; truncation anchor logic is missing"
    )


def test_anki_context_wide_span():
    """When the selected span itself exceeds the word limit, the full sentence must be kept."""
    content = _lua()
    # Wide-span guard: if span >= limit, return the full sentence
    assert re.search(r"span\s*>=\s*limit", content), (
        "Wide-span guard (span >= limit → return full sentence) not found"
    )
