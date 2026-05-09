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
def test_search_exact_match_priority(mpv):
    """Verify that an exact match has the highest score."""
    mpv.ipc.command(["set_property", "user-data/lls/last_export", ""])
    mpv.ipc.command(["script-message-to", "lls_core", "lls-test-calculate-match-score", "test", "test"])
    res_exact = wait_for_export(mpv)
    
    mpv.ipc.command(["set_property", "user-data/lls/last_export", ""])
    mpv.ipc.command(["script-message-to", "lls_core", "lls-test-calculate-match-score", "testing", "test"])
    res_sub = wait_for_export(mpv)
    
    assert res_exact['score'] == 2000
    assert res_exact['score'] > res_sub['score']

@pytest.mark.acceptance
def test_search_literal_vs_fuzzy(mpv):
    """Verify literal substrings score higher than fuzzy subsequences."""
    mpv.ipc.command(["set_property", "user-data/lls/last_export", ""])
    mpv.ipc.command(["script-message-to", "lls_core", "lls-test-calculate-match-score", "abcde", "abc"])
    res_literal = wait_for_export(mpv)
    
    mpv.ipc.command(["set_property", "user-data/lls/last_export", ""])
    mpv.ipc.command(["script-message-to", "lls_core", "lls-test-calculate-match-score", "axbyc", "abc"])
    res_fuzzy = wait_for_export(mpv)
    
    assert res_literal['score'] > res_fuzzy['score']

@pytest.mark.acceptance
def test_search_compactness_bonus(mpv):
    """Verify that more compact fuzzy matches score higher."""
    mpv.ipc.command(["set_property", "user-data/lls/last_export", ""])
    mpv.ipc.command(["script-message-to", "lls_core", "lls-test-calculate-match-score", "abxc", "abc"])
    res_compact = wait_for_export(mpv)
    
    mpv.ipc.command(["set_property", "user-data/lls/last_export", ""])
    mpv.ipc.command(["script-message-to", "lls_core", "lls-test-calculate-match-score", "axbxxc", "abc"])
    res_loose = wait_for_export(mpv)
    
    assert res_compact['score'] > res_loose['score']

@pytest.mark.acceptance
def test_search_order_bonus(mpv):
    """Verify that sequential matches score higher than out-of-order matches."""
    mpv.ipc.command(["set_property", "user-data/lls/last_export", ""])
    mpv.ipc.command(["script-message-to", "lls_core", "lls-test-calculate-match-score", "a and b", "a b"])
    res_ordered = wait_for_export(mpv)
    
    mpv.ipc.command(["set_property", "user-data/lls/last_export", ""])
    mpv.ipc.command(["script-message-to", "lls_core", "lls-test-calculate-match-score", "b and a", "a b"])
    res_unordered = wait_for_export(mpv)
    
    assert res_ordered['score'] > res_unordered['score']

@pytest.mark.acceptance
def test_search_start_bonus(mpv):
    """Verify that matches at the start of the string get a bonus."""
    mpv.ipc.command(["set_property", "user-data/lls/last_export", ""])
    mpv.ipc.command(["script-message-to", "lls_core", "lls-test-calculate-match-score", "test is here", "test"])
    res_start = wait_for_export(mpv)
    
    mpv.ipc.command(["set_property", "user-data/lls/last_export", ""])
    mpv.ipc.command(["script-message-to", "lls_core", "lls-test-calculate-match-score", "here is test", "test"])
    res_middle = wait_for_export(mpv)
    
    assert res_start['score'] > res_middle['score']

@pytest.mark.acceptance
def test_search_contiguous_bonus(mpv):
    """Verify that contiguous whole query matches get a bonus."""
    mpv.ipc.command(["set_property", "user-data/lls/last_export", ""])
    mpv.ipc.command(["script-message-to", "lls_core", "lls-test-calculate-match-score", "this is the test", "the test"])
    res_contig = wait_for_export(mpv)
    
    mpv.ipc.command(["set_property", "user-data/lls/last_export", ""])
    mpv.ipc.command(["script-message-to", "lls_core", "lls-test-calculate-match-score", "the big test", "the test"])
    res_split = wait_for_export(mpv)
    
    assert res_contig['score'] > res_split['score']
