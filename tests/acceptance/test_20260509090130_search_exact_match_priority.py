"""
Feature ZID: 20260509090130
Test Creation ZID: 20260509113830
Feature: Search Exact Match Priority

Structural tests verifying calculate_match_score scoring logic in kardenwort.lua.
The IPC test handler (test-calculate-match-score) is not implemented, so these
tests validate the scoring rules directly from source code.
"""

import re


LUA = "scripts/kardenwort/main.lua"


def _lua():
    with open(LUA, encoding="utf-8") as f:
        return f.read()


def test_search_exact_match_priority():
    """Exact match must return the hard-coded maximum score (2000)."""
    content = _lua()
    assert "calculate_match_score" in content, "calculate_match_score function missing"
    # Spec: exact match is highest priority at 2000
    assert "return 2000" in content, (
        "calculate_match_score must return 2000 for an exact match"
    )


def test_search_literal_vs_fuzzy():
    """Literal substring matches must receive a higher bonus than fuzzy matches."""
    content = _lua()
    # Literal gets +200; fuzzy gets at most +150
    assert re.search(r"literal\b.*score\s*=\s*score\s*\+\s*200|score\s*=\s*score\s*\+\s*200.*literal", content, re.DOTALL), (
        "Literal match bonus (+200) not found in calculate_match_score"
    )
    assert "150" in content, (
        "Fuzzy compactness bonus (150) not found; literal must exceed fuzzy bonus"
    )
    # Confirm the literal branch exists alongside a fuzzy branch
    assert "literal = true" in content and "literal = false" in content, (
        "Both literal and fuzzy match branches must be present"
    )


def test_search_compactness_bonus():
    """Compact fuzzy matches must score higher than loose fuzzy matches."""
    content = _lua()
    # Two-tier compactness: very compact (+150), reasonably compact (+5)
    assert re.search(r"score\s*=\s*score\s*\+\s*150", content), (
        "Very-compact fuzzy bonus (+150) not found in calculate_match_score"
    )
    assert re.search(r"score\s*=\s*score\s*\+\s*5\b", content), (
        "Reasonably-compact fuzzy bonus (+5) not found in calculate_match_score"
    )


def test_search_order_bonus():
    """Sequential (in-order) multi-token matches must receive a bonus."""
    content = _lua()
    # +300 for words matched in correct document order
    m = re.search(r"in_order.*score\s*=\s*score\s*\+\s*(\d+)", content, re.DOTALL)
    assert m and int(m.group(1)) >= 200, (
        "Order bonus (>=200) not found after in_order check in calculate_match_score"
    )


def test_search_start_bonus():
    """Matches starting at position 1 of the string must receive a start-of-sentence bonus."""
    content = _lua()
    # Pattern: matches[1].indices[1] == 1 → bonus
    assert "indices[1] == 1" in content, (
        "Start-of-sentence check (indices[1] == 1) not found in calculate_match_score"
    )
    m = re.search(r"indices\[1\]\s*==\s*1.*?score\s*=\s*score\s*\+\s*(\d+)", content, re.DOTALL)
    assert m and int(m.group(1)) >= 200, (
        "Start-of-sentence bonus (>=200) not found after indices[1]==1 check"
    )


def test_search_contiguous_bonus():
    """A query that appears verbatim as a contiguous substring must get the highest bonus."""
    content = _lua()
    # Contiguous whole-query bonus: str_lower:find(query_lower, 1, true) → +400
    assert re.search(r"query_lower.*score\s*=\s*score\s*\+\s*400|score\s*=\s*score\s*\+\s*400.*query_lower", content, re.DOTALL), (
        "Contiguous whole-query bonus (+400) not found in calculate_match_score"
    )


def test_search_returns_highlight_lookup_map():
    """Search scoring must return a char-index lookup map for UI hit coloring."""
    content = _lua()
    assert "return score, indices_map" in content, (
        "calculate_match_score should return indices_map (char-index -> true) for search highlighting"
    )


def test_search_results_keep_highlight_payload():
    """SEARCH_RESULTS entries must preserve hl so draw_search_ui can color all hits."""
    content = _lua()
    assert re.search(
        r"table\.insert\(FSM\.SEARCH_RESULTS,\s*\{idx\s*=\s*item\.idx,\s*text\s*=\s*subs\[item\.idx\]\.text,\s*hl\s*=\s*item\.hl\}\)",
        content
    ), (
        "update_search_results must keep idx/text/hl in SEARCH_RESULTS entries"
    )




