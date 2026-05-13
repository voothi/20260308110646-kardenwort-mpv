"""
Feature ZID: 20260513121332
Test Creation ZID: 20260513121855
Feature: Search Algorithm Nuances (Functional)

Functional acceptance tests verifying calculate_match_score scoring logic in kardenwort.lua
using IPC diagnostic hooks and a specialized fixture.
"""

import pytest
import json
import time
from tests.ipc.mpv_session import MpvSession
from tests.ipc.mpv_ipc import query_kardenwort_state

@pytest.fixture
def mpv_search():
    """Specialized session for search ranking validation."""
    session = MpvSession(
        video='tests/fixtures/20260502165659-test-fixture/20260502165659-test-fixture.mp4',
        subtitle='tests/fixtures/20260513121332-search-nuances.srt',
        extra_args=['--pause'],
    )
    session.start()
    yield session
    session.stop()

def get_search_results(mpv):
    """Helper to retrieve SEARCH_RESULTS from FSM state."""
    state = query_kardenwort_state(mpv.ipc)
    return state.get("search_results", [])


def set_search_query_and_wait(mpv, query, timeout=2.0):
    """
    Robust query setter for mpv startup races:
    keep sending test hook until SEARCH_QUERY is observed in state snapshot.
    """
    deadline = time.time() + timeout
    while time.time() < deadline:
        mpv.ipc.command(["script-message-to", "kardenwort", "test-set-search-query", query])
        state = query_kardenwort_state(mpv.ipc)
        if state.get("search_query") == query:
            return state.get("search_results", [])
        time.sleep(0.05)
    return []

def test_search_exact_match_priority(mpv_search):
    """Scenario: Exact match must return the highest score and rank first."""
    # Sub 1 is "test"
    results = set_search_query_and_wait(mpv_search, "test")
    assert len(results) > 0
    # Exact match for "test" (sub 1) should be at index 0 in results
    assert results[0]["idx"] == 1
    assert results[0]["text"] == "test"

def test_search_contiguous_substring_bonus(mpv_search):
    """Scenario: Contiguous whole-query substring bonus (+400)."""
    # Sub 2 is "this is a test line"
    # Query "test line" is contiguous here.
    results = set_search_query_and_wait(mpv_search, "test line")
    assert len(results) > 0
    assert results[0]["idx"] == 2
    assert "test line" in results[0]["text"]

def test_search_sequential_order_bonus(mpv_search):
    """Scenario: Sequential order bonus (+300)."""
    # Query: "sequential logic"
    # Sub 7: "sequential test logic" (in order)
    # Sub 8: "logic test sequential" (out of order)
    results = set_search_query_and_wait(mpv_search, "sequential logic")
    
    # Both should match, but sub 7 should be higher
    indices = [r["idx"] for r in results]
    assert 7 in indices
    assert 8 in indices
    
    idx_7_pos = indices.index(7)
    idx_8_pos = indices.index(8)
    assert idx_7_pos < idx_8_pos, f"Sub 7 (order) should rank above Sub 8 (no-order). Results: {indices}"

def test_search_start_of_sentence_bonus(mpv_search):
    """Scenario: Start of sentence bonus (+300)."""
    # Query: "test"
    # Sub 3: "test is first here" (starts with test)
    # Sub 5: "the test of time" (test in middle)
    results = set_search_query_and_wait(mpv_search, "test")
    
    indices = [r["idx"] for r in results]
    # Sub 1 is exact (1st)
    # Sub 3 (start) vs Sub 5 (middle)
    assert 3 in indices
    assert 5 in indices
    
    idx_3_pos = indices.index(3)
    idx_5_pos = indices.index(5)
    assert idx_3_pos < idx_5_pos, f"Sub 3 (start) should rank above Sub 5 (middle). Results: {indices}"

def test_search_compactness_bonus(mpv_search):
    """Scenario: Compactness bonus (Literal vs Fuzzy)."""
    # Query: "test"
    # Sub 4: "a simple testing case" (literal "test" in "testing")
    # Sub 6: "t e s t fuzzy" (fuzzy "t...e...s...t")
    results = set_search_query_and_wait(mpv_search, "test")
    
    indices = [r["idx"] for r in results]
    assert 4 in indices
    assert 6 in indices
    
    idx_4_pos = indices.index(4)
    idx_6_pos = indices.index(6)
    assert idx_4_pos < idx_6_pos, f"Sub 4 (literal) should rank above Sub 6 (loose fuzzy). Results: {indices}"

def test_search_cyrillic_ranking_nuances(mpv_search):
    """Scenario: Ranking nuances with Cyrillic characters."""
    # Query: "проверка"
    # Sub 9: "проверка поиска" (start)
    # Sub 10: "это проверка" (middle)
    results = set_search_query_and_wait(mpv_search, "проверка")
    
    indices = [r["idx"] for r in results]
    assert 9 in indices
    assert 10 in indices
    
    idx_9_pos = indices.index(9)
    idx_10_pos = indices.index(10)
    assert idx_9_pos < idx_10_pos, f"Sub 9 (start) should rank above Sub 10 (middle) for Cyrillic. Results: {indices}"

