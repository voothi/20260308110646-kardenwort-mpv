"""
Feature ZID: 20260526170559
Test Creation ZID: 20260526170559
Feature: Context Word Padding

Focused acceptance tests for sentence-scoped context word padding.
"""

LUA = "scripts/kardenwort/main.lua"
TSV_EXPORT = "scripts/kardenwort/tsv_export.lua"


def _lua():
    with open(LUA, encoding="utf-8") as f:
        return f.read()


def _tsv_export():
    with open(TSV_EXPORT, encoding="utf-8") as f:
        return f.read()


def test_padding_options_exist_with_defaults():
    content = _lua()
    assert "anki_context_words_before = 0" in content
    assert "anki_context_words_after = 0" in content


def test_padding_options_are_normalized():
    content = _lua()
    assert "Options.anki_context_words_before = math.max(0, math.floor(tonumber(Options.anki_context_words_before) or 0))" in content
    assert "Options.anki_context_words_after = math.max(0, math.floor(tonumber(Options.anki_context_words_after) or 0))" in content


def test_padding_applies_after_sentence_scoping():
    content = _tsv_export()
    idx = content.find("local function extract_anki_context")
    assert idx != -1
    body = content[idx:idx + 25000]
    assert "padding_active = (pad_before > 0) or (pad_after > 0)" in body
    assert "if padding_allowed then" in body
    assert "final_first_word_idx = math.max(1, first_sent_word_idx - pad_before)" in body
    assert "final_last_word_idx = math.min(#word_tokens, last_sent_word_idx + pad_after)" in body


def test_padding_requires_real_sentence_boundary():
    content = _tsv_export()
    idx = content.find("local function extract_anki_context")
    assert idx != -1
    body = content[idx:idx + 25000]
    assert "local has_real_boundary = false" in body
    assert "has_real_boundary = true" in body
    assert "padding_allowed = padding_active and has_real_boundary" in body


def test_default_sentence_path_is_preserved():
    content = _tsv_export()
    idx = content.find("local function extract_anki_context")
    assert idx != -1
    body = content[idx:idx + 25000]
    assert "if #words <= limit then return sentence end" in body


def test_padding_limit_adjustment_and_wide_span_override():
    content = _tsv_export()
    idx = content.find("local function extract_anki_context")
    assert idx != -1
    body = content[idx:idx + 25000]
    assert "words_needed = span + pad_before + pad_after" in body
    assert "pad_left = math.max(pad_left, pad_before)" in body
    assert "pad_right = math.max(pad_right, pad_after)" in body
