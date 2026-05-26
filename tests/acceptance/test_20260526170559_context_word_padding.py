"""
Feature ZID: 20260526170559
Test Creation ZID: 20260526170559
Feature: Context Word Padding

Focused acceptance tests for sentence-scoped context word padding.
"""

LUA = "scripts/kardenwort/main.lua"


def _lua():
    with open(LUA, encoding="utf-8") as f:
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
    content = _lua()
    idx = content.find("local function extract_anki_context")
    assert idx != -1
    body = content[idx:idx + 25000]
    assert "padding_active = (pad_before > 0) or (pad_after > 0)" in body
    assert "if padding_active then" in body
    assert "final_first_word_idx = math.max(1, first_sent_word_idx - pad_before)" in body
    assert "final_last_word_idx = math.min(#word_tokens, last_sent_word_idx + pad_after)" in body


def test_padding_after_preserves_adjacent_punctuation():
    content = _lua()
    idx = content.find("local function extract_anki_context")
    assert idx != -1
    body = content[idx:idx + 25000]
    assert "while sent_end < #full_line do" in body
    assert "next_char:match" in body
    assert "%.,!?;:" in body


def test_default_sentence_path_is_preserved():
    content = _lua()
    idx = content.find("local function extract_anki_context")
    assert idx != -1
    body = content[idx:idx + 25000]
    assert "if #words <= limit then return sentence end" in body


def test_padding_limit_adjustment_and_wide_span_override():
    content = _lua()
    idx = content.find("local function extract_anki_context")
    assert idx != -1
    body = content[idx:idx + 25000]
    assert "words_needed = span + pad_before + pad_after" in body
    assert "pad_left = math.max(pad_left, pad_before)" in body
    assert "pad_right = math.max(pad_right, pad_after)" in body
