"""
Feature ZID: 20260509085806
Test Creation ZID: 20260509091431
Feature: Anki Context Verbatim
"""

import pytest
import time
import json
import os

def wait_for_export(mpv, timeout=2.0):
    start = time.time()
    while time.time() - start < timeout:
        val = mpv.ipc.get_property("user-data/lls/last_export")
        if val and val != "":
            return json.loads(val)
        time.sleep(0.05)
    raise TimeoutError("Timed out waiting for last_export")

@pytest.mark.acceptance
def test_anki_context_verbatim(mpv):
    """Verify standard verbatim context extraction."""
    line = "This is a simple test sentence."
    term = "simple test"
    mpv.ipc.command(["set_property", "user-data/lls/last_export", ""])
    mpv.ipc.command(["script-message-to", "lls_core", "lls-test-extract-anki-context", line, term, "20", "15"])
    res = wait_for_export(mpv)
    assert res['context'] == line

@pytest.mark.acceptance
def test_anki_context_non_contiguous(mpv):
    """Verify context extraction for non-contiguous word selections."""
    line = "The quick brown fox jumps over the lazy dog."
    term = "quick fox dog"
    # 'quick', 'fox', 'dog' should be found even if not contiguous
    mpv.ipc.command(["set_property", "user-data/lls/last_export", ""])
    mpv.ipc.command(["script-message-to", "lls_core", "lls-test-extract-anki-context", line, term, "20", "20"])
    res = wait_for_export(mpv)
    # It should return the full line because it fits in 20 words
    assert res['context'] == line

@pytest.mark.acceptance
def test_anki_context_pivot_selection(mpv):
    """Verify that the occurrence closest to the pivot is selected."""
    # Two instances of 'test'
    line = "First test here. Second test there."
    term = "test"
    
    # Pivot at 6 (near first 'test')
    mpv.ipc.command(["set_property", "user-data/lls/last_export", ""])
    mpv.ipc.command(["script-message-to", "lls_core", "lls-test-extract-anki-context", line, term, "20", "6"])
    res_first = wait_for_export(mpv)
    
    # Pivot at 25 (near second 'test')
    mpv.ipc.command(["set_property", "user-data/lls/last_export", ""])
    mpv.ipc.command(["script-message-to", "lls_core", "lls-test-extract-anki-context", line, term, "20", "25"])
    res_second = wait_for_export(mpv)
    
    # In this case, the 'sentence' extraction logic (2437-2460) will pick the whole line
    # because there are no \0 sentinels. 
    # But internally it selects the match.
    # To test actual 'sentence' boundaries, we need \0 sentinels.
    
    line_sentinel = "First test here.[SENTINEL]Second test there."
    mpv.ipc.command(["set_property", "user-data/lls/last_export", ""])
    mpv.ipc.command(["script-message-to", "lls_core", "lls-test-extract-anki-context", line_sentinel, term, "20", "6"])
    res_sent1 = wait_for_export(mpv)
    
    mpv.ipc.command(["set_property", "user-data/lls/last_export", ""])
    mpv.ipc.command(["script-message-to", "lls_core", "lls-test-extract-anki-context", line_sentinel, term, "20", "25"])
    res_sent2 = wait_for_export(mpv)
    
    assert "First test here" in res_sent1['context']
    assert "Second test there" in res_sent2['context']

@pytest.mark.acceptance
def test_anki_context_truncation(mpv):
    """Verify adaptive truncation when word count exceeds limit."""
    words = ["word" + str(i) for i in range(30)]
    line = " ".join(words)
    term = "word15"
    
    # Limit to 10 words. Should truncate around word15.
    mpv.ipc.command(["set_property", "user-data/lls/last_export", ""])
    mpv.ipc.command(["script-message-to", "lls_core", "lls-test-extract-anki-context", line, term, "10", "75"])
    res = wait_for_export(mpv)
    
    # word15 is roughly in the middle.
    # 10 words centered around word15: word10 to word19 (approx)
    assert "word15" in res['context']
    assert "word0" not in res['context']
    assert "word29" not in res['context']
    assert len(res['context'].split()) <= 11 # 10 plus potential rounding/padding

@pytest.mark.acceptance
def test_anki_context_wide_span(mpv):
    """Verify that wide spans are preserved even if they exceed the limit."""
    words = ["word" + str(i) for i in range(30)]
    line = " ".join(words)
    term = "word5 word25" # Span of 21 words
    
    # Limit to 10 words. 
    # Since span (21) > limit (10), it should crop to the span + pad.
    mpv.ipc.command(["set_property", "user-data/lls/last_export", ""])
    mpv.ipc.command(["script-message-to", "lls_core", "lls-test-extract-anki-context", line, term, "10", "75"])
    res = wait_for_export(mpv)
    
    assert "word5" in res['context']
    assert "word25" in res['context']
    # It should be longer than the limit
    assert len(res['context'].split()) >= 21
