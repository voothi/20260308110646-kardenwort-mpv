"""
Feature ZID: 20260525193414
Test Creation ZID: 20260525194543
Feature: Restore Period-Based Sentence Scoping

Structural tests verifying that extract_anki_context uses punctuation-anchored
sentence boundary detection instead of subtitle-line NUL-sentinel scoping.
Regression fix for: 20260429012045-subtitle-line-sentence-boundaries

Specs:
- openspec/specs/subtitle-aware-sentence-extraction
- openspec/specs/adaptive-context-truncation
"""

import re


LUA = "scripts/kardenwort/main.lua"


def _lua():
    with open(LUA, encoding="utf-8") as f:
        return f.read()


def _scoping_block(content):
    """Extract the sentence scoping block from extract_anki_context."""
    start = content.find("=== Backward scan: find nearest real sentence terminator")
    if start == -1:
        return ""
    # Grab a generous window around both scans
    return content[start:start + 3000]


# ---------------------------------------------------------------------------
# Task 4.1 — full-sentence capture for multi-line SRT
# ---------------------------------------------------------------------------

def test_backward_scan_uses_terminator_chars():
    """Backward scan must search for real sentence terminators, not NUL sentinels.

    Spec: Punctuation-Anchored Sentence Scoping — backward scan stops at real [.!?]
    Scenario: Sentence spanning multiple subtitle lines
    """
    content = _lua()
    block = _scoping_block(content)
    assert block, "Sentence scoping block not found in extract_anki_context"
    # Must call is_terminator_char (or equivalent) instead of looking for \0
    assert "is_terminator_char" in block, (
        "is_terminator_char not called in backward scan; NUL-sentinel scoping regression"
    )
    # Must not use the old reversed-string NUL find pattern
    assert 'pre:reverse():find("\\0"' not in block, (
        "Old NUL-sentinel backward scan (pre:reverse():find) still present; not replaced"
    )


def test_forward_scan_uses_terminator_chars():
    """Forward scan must search for real sentence terminators, not NUL sentinels.

    Spec: Punctuation-Anchored Sentence Scoping — forward scan stops at real [.!?]
    Scenario: Forward scan includes the terminating punctuation
    """
    content = _lua()
    block = _scoping_block(content)
    assert block, "Sentence scoping block not found in extract_anki_context"
    assert "f_term_pos" in block, (
        "f_term_pos variable not found; forward terminator scan is missing"
    )
    # Must include the terminator in sent_end (inclusive)
    assert "sent_end = f_term_pos" in block, (
        "sent_end must equal f_term_pos to include the terminator character"
    )
    # Must not use the old post:find("\0") pattern
    assert 'post:find("\\0"' not in content or "post:find" not in block, (
        "Old NUL-sentinel forward scan (post:find) still present in scoping block"
    )


# ---------------------------------------------------------------------------
# Task 4.2 — non-contiguous span starts at correct sentence boundary
# ---------------------------------------------------------------------------

def test_backward_boundary_excludes_prior_sentence():
    """Sentence start must be placed AFTER the backward terminator, not at the NUL.

    Spec: Punctuation-Anchored Sentence Scoping
    Scenario: Backward scan stops at the nearest real terminator
    For 'Autofahrer ... rechnen', result must NOT start with 'bleiben.'
    The sent_start is set to b_term_pos + 1 (right after the period).
    """
    content = _lua()
    block = _scoping_block(content)
    assert "b_term_pos + 1" in block or "b_term_pos+1" in block, (
        "sent_start must be set to b_term_pos + 1 to exclude the boundary terminator from the result"
    )


def test_no_terminator_fallback_uses_full_block():
    """When no terminator is found, the full joined context block must be returned.

    Spec: No-Terminator Fallback to Full Joined Context
    Scenario: Unpunctuated auto-subtitle block
    """
    content = _lua()
    block = _scoping_block(content)
    # Fallback: sent_start = 1, sent_end = #full_line
    assert "sent_start = 1" in block, (
        "No-terminator fallback must set sent_start = 1 to use the full block"
    )
    assert "sent_end = #full_line" in block, (
        "No-terminator fallback must set sent_end = #full_line to use the full block"
    )
    # Must NOT fall back to a single NUL-bounded subtitle line
    assert 'b_idx = pre:reverse():find("\\0"' not in block, (
        "Old NUL-sentinel fallback still present; should fall back to full block, not single subtitle line"
    )


# ---------------------------------------------------------------------------
# Task 4.3 — abbreviation skip in the scoping scan
# ---------------------------------------------------------------------------

def test_abbreviation_skip_in_scoping_block():
    """The scoping scan must skip periods that belong to abbreviations.

    Spec: Abbreviation-Aware Sentence Boundary Detection
    Scenario: Heuristic catches short German abbreviation (ca., usw., d.h.)
    """
    content = _lua()
    block = _scoping_block(content)
    assert "is_abbrev" in block, (
        "is_abbrev not called inside sentence scoping block; abbreviation skip is missing"
    )
    assert "token_ending_at" in block, (
        "token_ending_at not called inside sentence scoping block; preceding-token extraction is missing"
    )


def test_is_abbrev_function_exists_and_uses_list():
    """is_abbrev must consult both the heuristic and anki_abbrev_list.

    Spec: Abbreviation-Aware Sentence Boundary Detection
    Spec: Configurable Abbreviation Allowlist
    """
    content = _lua()
    assert "local function is_abbrev" in content, (
        "is_abbrev function not found in main.lua"
    )
    assert "anki_abbrev_list" in content, (
        "anki_abbrev_list option not referenced in is_abbrev"
    )
    assert "anki_abbrev_smart" in content, (
        "anki_abbrev_smart option not referenced; heuristic toggle is missing"
    )


def test_token_ending_at_helper_exists():
    """token_ending_at helper must be defined for preceding-token extraction.

    Spec: Abbreviation-Aware Sentence Boundary Detection
    """
    content = _lua()
    assert "local function token_ending_at" in content, (
        "token_ending_at helper function not found in main.lua"
    )


# ---------------------------------------------------------------------------
# Task 4.4 — no-terminator fallback structural check
# ---------------------------------------------------------------------------

def test_no_terminator_fallback_trace_message():
    """Diagnostic trace must distinguish terminator-found from fallback paths.

    Spec: No-Terminator Fallback to Full Joined Context
    """
    content = _lua()
    assert "fallback to block" in content, (
        "Diagnostic trace for no-terminator fallback ('fallback to block') not found"
    )


# ---------------------------------------------------------------------------
# Task 4.5 — configurable sentence terminators option
# ---------------------------------------------------------------------------

def test_anki_sentence_terminators_option_defined():
    """anki_sentence_terminators must be declared in Options with default '.!?'.

    Spec: Configurable Sentence Terminators
    Scenario: Default terminators
    """
    content = _lua()
    assert 'anki_sentence_terminators' in content, (
        "anki_sentence_terminators option not found in main.lua"
    )
    assert '".!?"' in content or "'.!?'" in content, (
        "Default value .!? not found for anki_sentence_terminators"
    )


def test_is_terminator_char_helper_exists():
    """is_terminator_char must be defined and consult anki_sentence_terminators.

    Spec: Configurable Sentence Terminators
    Scenario: User adds terminator characters
    """
    content = _lua()
    assert "local function is_terminator_char" in content, (
        "is_terminator_char helper function not found in main.lua"
    )
    assert "anki_sentence_terminators" in content[content.find("local function is_terminator_char"):
                                                   content.find("local function is_terminator_char") + 300], (
        "is_terminator_char must reference anki_sentence_terminators option"
    )


# ---------------------------------------------------------------------------
# Task 4.5b — anki_abbrev_list extended defaults
# ---------------------------------------------------------------------------

def test_anki_abbrev_list_includes_german_defaults():
    """anki_abbrev_list default must include common German abbreviations.

    Spec: Configurable Abbreviation Allowlist
    Scenario: Default value covers common German abbreviations
    """
    content = _lua()
    idx = content.find("anki_abbrev_list")
    assert idx != -1, "anki_abbrev_list not found in Options"
    line = content[idx:idx+200]
    for abbrev in ["d.h.", "vgl.", "ggf.", "bspw."]:
        assert abbrev in line, (
            f"German abbreviation '{abbrev}' not in anki_abbrev_list default value"
        )


# ---------------------------------------------------------------------------
# Edge case 20260526113537 — uppercase look-ahead suppresses lowercase
# abbreviation heuristic so 4-letter common words ("work.", "view.") do not
# false-positive as abbreviations when the next sentence clearly begins.
# ---------------------------------------------------------------------------

def test_is_abbrev_accepts_lookahead_argument():
    """is_abbrev must accept a second lookahead argument so callers can disambiguate
    a real sentence end ("work. Microsoft") from a mid-sentence abbreviation ("ca. 3 km")."""
    content = _lua()
    assert re.search(r"local function is_abbrev\(w,\s*lookahead\)", content), (
        "is_abbrev must accept an optional lookahead character argument"
    )


def test_is_abbrev_suppresses_lowercase_heuristic_on_uppercase_lookahead():
    """The 1-4 lowercase letter heuristic must be suppressed when the look-ahead
    character is uppercase — otherwise common English/German words such as
    "work.", "view.", "many.", "this." misfire as abbreviations."""
    content = _lua()
    idx = content.find("local function is_abbrev(w, lookahead)")
    assert idx != -1, "Patched is_abbrev signature not found"
    body = content[idx:idx + 1200]
    assert "heuristic_suppressed" in body, (
        "is_abbrev must compute heuristic_suppressed based on the lookahead"
    )
    # The suppression must apply specifically to the `^%l+%.$` heuristic,
    # not the uppercase-initial patterns.
    assert re.search(
        r"not heuristic_suppressed and w:match\(\"\^%l\+%\.\$\"\)",
        body,
    ), (
        "Lowercase-letter heuristic must be gated by 'not heuristic_suppressed'; "
        "uppercase-letter patterns must remain active"
    )


def test_extract_anki_context_passes_lookahead_to_is_abbrev():
    """Both the backward and forward scans must compute the next visible
    character past the candidate period and pass it to is_abbrev."""
    content = _lua()
    # Helper that walks past whitespace/\0 to the next visible character
    assert "local function lookahead_after" in content, (
        "lookahead_after helper not defined inside extract_anki_context"
    )
    block = _scoping_block(content)
    # Both scans must consult is_abbrev with the lookahead character.
    matches = re.findall(
        r"is_abbrev\(token_ending_at\(full_line,\s*\w+\),\s*lookahead_after\(full_line,\s*\w+\)\)",
        block,
    )
    assert len(matches) >= 2, (
        f"Both backward and forward scans must call is_abbrev with lookahead_after; "
        f"found only {len(matches)} occurrences"
    )
