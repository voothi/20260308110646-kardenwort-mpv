"""
Feature ZID: 20260526170559
Test Creation ZID: 20260526170559
Feature: Context Word Padding Modes

Structural acceptance tests verifying the context word-padding mechanism layers correctly on top of punctuation-anchored sentence extraction.
"""

import re

LUA = "scripts/kardenwort/main.lua"


def _lua():
    with open(LUA, encoding="utf-8") as f:
        return f.read()


def test_context_word_padding_options_exist():
    """anki_context_words_before and anki_context_words_after options must be defined in Options with default 0."""
    content = _lua()
    assert "anki_context_words_before = 0" in content, (
        "anki_context_words_before not defined in Options with default 0"
    )
    assert "anki_context_words_after = 0" in content, (
        "anki_context_words_after not defined in Options with default 0"
    )


def test_context_word_padding_normalization():
    """Word padding options must be normalized to non-negative integers inside validate_config."""
    content = _lua()
    idx = content.find("function validate_config()")
    assert idx != -1
    body = content[idx:idx + 1500]
    assert "Options.anki_context_words_before = math.max(0," in body, (
        "anki_context_words_before not normalized to non-negative integer in validate_config"
    )
    assert "Options.anki_context_words_after = math.max(0," in body, (
        "anki_context_words_after not normalized to non-negative integer in validate_config"
    )


def test_extract_anki_context_word_indexing():
    """extract_anki_context must index word tokens over the joined context using start_byte and end_byte."""
    content = _lua()
    idx = content.find("local function extract_anki_context")
    assert idx != -1
    body = content[idx:idx + 25000]
    
    assert "build_word_list_internal(full_line_spaced, true)" in body, (
        "extract_anki_context must tokenize full_line using build_word_list_internal keeping spaces"
    )
    assert "start_byte = curr_byte" in body, (
        "start_byte tracking for token indexing is missing"
    )
    assert "end_byte = curr_byte + #text - 1" in body, (
        "end_byte tracking for token indexing is missing"
    )
    assert "if t.is_word then" in body, (
        "is_word check to filter word tokens is missing"
    )


def test_extract_anki_context_applies_padding_after_sentence_scoping():
    """Word padding must be applied strictly after sentence-scoping indices are found."""
    content = _lua()
    idx = content.find("local function extract_anki_context")
    assert idx != -1
    body = content[idx:idx + 25000]
    
    # Locate the scan and then the padding apply
    scan_idx = body.find("=== Sentence Scoping ===")
    assert scan_idx != -1
    
    pad_idx = body.find("Apply optional before/after word padding after sentence scoping")
    assert pad_idx != -1
    assert pad_idx > scan_idx, (
        "Padding must be applied after the sentence boundary scans"
    )
    
    assert "final_first_word_idx - pad_before" in body, (
        "pad_before must expand the sentence-scoped start index"
    )
    assert "final_last_word_idx + pad_after" in body, (
        "pad_after must expand the sentence-scoped end index"
    )


def test_extract_anki_context_preserves_non_word_structural_markers():
    """Non-word structural markers like ## and ### must be preserved in literal substring without consuming padding counts."""
    content = _lua()
    idx = content.find("local function extract_anki_context")
    assert idx != -1
    body = content[idx:idx + 25000]
    
    # We only count words (t.is_word), but pull exact substring by mapping back to original bytes in full_line
    assert "word_tokens[final_first_word_idx].start_byte" in body, (
        "Substring boundaries must map back to word token start bytes"
    )
    assert "word_tokens[final_last_word_idx].end_byte" in body, (
        "Substring boundaries must map back to word token end bytes"
    )
    assert "full_line:sub(f_byte, l_byte)" in body, (
        "extract_anki_context must extract the literal substring from full_line using the mapped bytes"
    )


def test_extract_anki_context_nul_sentinels_internal():
    """Subtitle NUL sentinels must remain internal to extraction and be replaced with spaces only in final context return."""
    content = _lua()
    idx = content.find("local function extract_anki_context")
    assert idx != -1
    body = content[idx:idx + 25000]
    
    # The scan uses full_line which still contains NUL. Only the returned values gsub("%z", " ")
    assert 'raw_sub:gsub("%z", " ")' in body, (
        "NUL sentinels must only be replaced with spaces on output"
    )


def test_extract_anki_context_dynamic_truncation_limit():
    """Effective truncation limit must be raised dynamically to preserve selection and requested padding."""
    content = _lua()
    idx = content.find("local function extract_anki_context")
    assert idx != -1
    body = content[idx:idx + 25000]
    
    assert "sel_span = last_sel_word_idx - first_sel_word_idx + 1" in body, (
        "Selection span in words must be computed to evaluate required limits"
    )
    assert "limit = words_needed" in body, (
        "Effective limit must be raised if the required words exceed it"
    )


def test_extract_anki_context_wide_selection_explicit_padding():
    """Wide selection with explicit padding must override standard pad, pad by configured values, and clamp to joined context boundaries."""
    content = _lua()
    idx = content.find("local function extract_anki_context")
    assert idx != -1
    body = content[idx:idx + 25000]
    
    assert "is_explicit_padding_active" in body, (
        "Wide selection handling must check if explicit padding is active"
    )
    assert "math.max(1, first_sel_word_idx - actual_pad_before)" in body, (
        "Wide selection with explicit padding must clamp to joined context boundary (1)"
    )
    assert "math.min(#word_tokens, last_sel_word_idx + actual_pad_after)" in body, (
        "Wide selection with explicit padding must clamp to joined context boundary (#word_tokens)"
    )
    assert "math.max(first_sent_word_idx" in body, (
        "Standard wide selection without explicit padding must clamp to sentence boundaries"
    )
