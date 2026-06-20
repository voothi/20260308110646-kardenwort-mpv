"""
Feature ZID: 20260526170559
Test Creation ZID: 20260526170559
Feature: Context Word Padding

Focused acceptance tests for sentence-scoped context word padding.
"""

LUA = "scripts/kardenwort/main.lua"
TSV_EXPORT = "scripts/kardenwort/tsv_export.lua"


import re


LUA = "scripts/kardenwort/main.lua"
TSV_EXPORT = "scripts/kardenwort/tsv_export.lua"


def assert_contains(haystack, needle, msg=None):
    def norm(s):
        return re.sub(r"[\s\n\r\t\"']+", "", s)
    assert norm(needle) in norm(haystack), msg or f"Expected {repr(needle)} to be in text, but not found."


def _lua():
    import os
    contents = []
    base_dir = "scripts/kardenwort"
    for filename in sorted(os.listdir(base_dir)):
        if filename.endswith(".lua"):
            with open(os.path.join(base_dir, filename), encoding="utf-8") as f:
                contents.append(f.read())
    return "\n".join(contents)


def _tsv_export():
    with open(TSV_EXPORT, encoding="utf-8") as f:
        return f.read()


def test_padding_options_exist_with_defaults():
    content = _lua()
    assert_contains(content, "anki_context_words_before = 0")
    assert_contains(content, "anki_context_words_after = 0")


def test_padding_options_are_normalized():
    content = _lua()
    assert (
        norm_check("Options.anki_context_words_before = math.max(0, math.floor(tonumber(Options.anki_context_words_before) or 0))", content) or
        norm_check("opts.anki_context_words_before = math.max(0, math.floor(tonumber(opts.anki_context_words_before) or 0))", content)
    )
    assert (
        norm_check("Options.anki_context_words_after = math.max(0, math.floor(tonumber(Options.anki_context_words_after) or 0))", content) or
        norm_check("opts.anki_context_words_after = math.max(0, math.floor(tonumber(opts.anki_context_words_after) or 0))", content)
    )


def norm_check(needle, haystack):
    def norm(s):
        return re.sub(r"[\s\n\r\t\"']+", "", s)
    return norm(needle) in norm(haystack)


def test_padding_applies_after_sentence_scoping():
    content = _tsv_export()
    idx = content.find("local function extract_anki_context")
    assert idx != -1
    body = content[idx:idx + 25000]
    assert_contains(body, "padding_active = (pad_before > 0) or (pad_after > 0)")
    assert_contains(body, "if padding_allowed then")
    assert_contains(body, "final_first_word_idx = math.max(1, first_sent_word_idx - pad_before)")
    assert_contains(body, "final_last_word_idx = math.min(#word_tokens, last_sent_word_idx + pad_after)")


def test_padding_requires_real_sentence_boundary():
    content = _tsv_export()
    idx = content.find("local function extract_anki_context")
    assert idx != -1
    body = content[idx:idx + 25000]
    assert_contains(body, "local has_real_boundary = false")
    assert_contains(body, "has_real_boundary = true")
    assert_contains(body, "padding_allowed = padding_active and has_real_boundary")


def test_default_sentence_path_is_preserved():
    content = _tsv_export()
    idx = content.find("local function extract_anki_context")
    assert idx != -1
    body = content[idx:idx + 25000]
    assert_contains(body, "if #words <= limit then return sentence end")


def test_padding_limit_adjustment_and_wide_span_override():
    content = _tsv_export()
    idx = content.find("local function extract_anki_context")
    assert idx != -1
    body = content[idx:idx + 25000]
    assert_contains(body, "words_needed = span + pad_before + pad_after")
    assert_contains(body, "pad_left = math.max(pad_left, pad_before)")
    assert_contains(body, "pad_right = math.max(pad_right, pad_after)")

