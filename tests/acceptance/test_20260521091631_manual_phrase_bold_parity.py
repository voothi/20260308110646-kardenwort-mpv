"""
Feature ZID: 20260521091631
Test Creation ZID: 20260521091631
Feature: Manual/Phrase Bold Parity in Highlight Rendering

Regression coverage for format_highlighted_word bold handling:
- manual selection must enforce regular weight (\b0)
- phrase-only highlight must preserve configured highlight bold state
"""


def _lua_source():
    with open("scripts/kardenwort/main.lua", encoding="utf-8") as f:
        return f.read()


def test_manual_selection_enforces_regular_weight_structural():
    src = _lua_source()
    idx = src.find("local function format_highlighted_word")
    assert idx != -1, "format_highlighted_word not found"
    body = src[idx:idx + 1800]

    assert 'local p_b_on = is_manual and "{\\\\b0}" or b_on' in body, (
        "manual selection must enforce regular weight via p_b_on"
    )
    assert 'return string.format("%s%s%s%s{\\\\b%s}", p_b_on, h_tags, word, r_tags, bold_state or "0")' in body, (
        "manual/phrase path must prefix p_b_on and restore bold_state afterwards"
    )


def test_phrase_highlight_keeps_configured_bold_structural():
    src = _lua_source()
    idx = src.find("local function format_highlighted_word")
    assert idx != -1, "format_highlighted_word not found"
    body = src[idx:idx + 1800]

    assert "if is_phrase or is_manual then" in body, "combined phrase/manual branch expected"
    assert 'local p_b_on = is_manual and "{\\\\b0}" or b_on' in body, (
        "phrase-only path must still use b_on (configured highlight bold)"
    )
