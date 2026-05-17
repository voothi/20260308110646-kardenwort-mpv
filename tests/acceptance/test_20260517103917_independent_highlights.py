"""
Feature ZID: 20260517103720
Test Creation ZID: 20260517103917
Feature: Non-Colliding Adjacent Identical Highlights

This test verifies that identical adjacent highlights in kardenwort-mpv
render independently without collision or de-duplication, particularly
in bad auto-subtitle streams without punctuation or sentence boundaries.
"""

import time
import os
import tempfile
from pathlib import Path

import pytest
from tests.ipc.mpv_ipc import query_kardenwort_state, query_kardenwort_render


LUA_SOURCE = "scripts/kardenwort/main.lua"


def _read_lua_source():
    with open(LUA_SOURCE, encoding="utf-8") as f:
        return f.read()


@pytest.mark.acceptance
def test_static_code_verification_entry_key():
    """
    1.1 Static Verification:
    Verify that main.lua implements the identity key (__entry_key) logic
    for matched_terms and split_valid_indices tracking instead of raw term_key.
    """
    src = _read_lua_source()

    # Semantic checks: entry-key path must exist and old term-key collisions must be absent.
    assert "__entry_key" in src, "entry-key field must exist for highlight identity isolation"
    assert "local entry_key = data.__entry_key or term_key" in src, (
        "calculate_highlight_stack must derive entry_key"
    )
    assert "matched_terms[entry_key] = true" in src, (
        "matched_terms must be keyed by entry_key"
    )
    assert "subs[sub_idx].__split_valid_indices[entry_key]" in src, (
        "split valid-index cache must be keyed by entry_key"
    )
    assert "matched_terms[term_key] = true" not in src, (
        "term_key-based dedupe must not be used (reintroduces identical-term collision)"
    )
    assert "subs[sub_idx].__split_valid_indices[term_key]" not in src, (
        "term_key-based split cache must not be used (cache collision risk)"
    )


@pytest.mark.acceptance
def test_identical_adjacent_highlights_integration(mpv):
    """
    1.2 Integration Verification:
    Write a custom TSV containing two identical adjacent highlight terms
    at the same time position, configure kardenwort to load it, and verify
    stable loading and robust state execution under identity-key mapping.
    """
    ipc = mpv.ipc

    # Construct a custom TSV file containing adjacent identical highlights
    tsv_content = (
        "#deck column:86\n"
        "Quotation\tWordSource\tWordSource2\tWordSourceInflectedForm\tWordSourceInflectedForm2\t"
        "WordDestination\tWordDestinationInflectedForm\tWordSourceContext\tSentenceSourceContextLeft\t"
        "SentenceSource\tSentenceSourceContextRight\tSentenceDestinationContextLeft\t"
        "SentenceDestination\tSentenceDestinationContextRight\tSentenceDestination2ContextLeft\t"
        "SentenceDestination2\tSentenceDestination2ContextRight\tSentenceSourceWordlist\t"
        "SentenceSourceCloze\tSentenceSourceRewriteAISentenceSource\t"
        "SentenceSourceRewriteAISentenceDestination\tWordSourceMorphologyAI\tNote\t"
        "WordRussian\tWordUkrainian\tWordEnglish\tWordGerman\tWordSourceMorphemeFirst\t"
        "WordSourceMorphemeFirstDefinition\tWordSourceMorphemeSecond\t"
        "WordSourceMorphemeSecondDefinition\tWordSourceMorphemeThird\t"
        "WordSourceMorphemeThirdDefinition\tWordSourceMorphemeFourth\t"
        "WordSourceMorphemeFourthDefinition\tWordSourceMorphemeFifth\t"
        "WordSourceMorphemeFifthDefinition\tWordSourceIPA\tWordSourceSynonymAI\t"
        "WordSourceDefinitionAISentenceSource\tWordSourceDefinitionAISentenceDestination\t"
        "WordSourceDefinitionFirst\tWordSourceDefinitionFirstClipping\tWordSourceDefinitionSecond\t"
        "WordDestinationDefinitionFirst\tWordDestinationDefinitionSecond\tWordSourceAudio\t"
        "SentenceSourceIPA\tSentenceSourceAudio\tImage\tWordSourceCloze\tWordSourceContextAI\t"
        "TextSource\tTextDestination\tTextSourceURL\tSentenceEnglish\tSentenceGerman\t"
        "SentenceUkrainian\tSentenceRussian\tSource\tSourceURL\tSeparatorAudio\t"
        "Source-en-GB\tSource-en-US\tSource-de-DE\tSource-uk-UA\tSource-ru-RU\t"
        "Destination-en-GB\tDestination-en-US\tDestination-de-DE\tDestination-uk-UA\t"
        "Destination-ru-RU\tOverlapping\tToggleAlwaysEmptyField\tNote ID\t"
        "am-all-morphs\tam-all-morphs-count\tam-unknown-morphs\tam-unknown-morphs-count\t"
        "am-highlighted\tam-score\tam-score-terms\tam-study-morphs\tSentenceSourceIndex\tDeck\t\n"
    )

    row_1 = (
        "Hello\tHello\tHello\tHello\tHello\t\t\t"
        "Hello world\t\tHello world\t\t\t\t\t\t\t\t\t\t\t\t\t"
        "1.001\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t"
        "0:1:1\t20260502165659-test-fixture.en\n"
    )
    row_2 = (
        "Hello\tHello\tHello\tHello\tHello\t\t\t"
        "Hello world\t\tHello world\t\t\t\t\t\t\t\t\t\t\t\t\t"
        "1.001\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t"
        "0:1:2\t20260502165659-test-fixture.en\n"
    )

    # Use OS temp directly to avoid repo-local .pytest_tmp lock contention on Windows.
    fd, temp_name = tempfile.mkstemp(prefix="kardenwort-identical-adjacent-", suffix=".tsv")
    try:
        tsv_path = Path(temp_name)
        with open(fd, "w", encoding="utf-8", closefd=True) as f:
            # Baseline: one row only (depth-1 highlight expected).
            f.write(tsv_content + row_1)

        expected_size = tsv_path.stat().st_size
        expected_mtime = int(os.path.getmtime(tsv_path))

        # Speed up periodic TSV sync for deterministic test runtime.
        ipc.command(["script-message-to", "kardenwort", "test-set-option", "anki_sync_period", "0.2"])

        # Inject the temporary TSV path; reload is handled by periodic sync.
        ipc.command(["script-message-to", "kardenwort", "test-set-option", "anki_record_file", str(tsv_path)])

        # Poll until the sync loop picks up the injected DB fingerprint.
        deadline = time.time() + 8.0
        state = {}
        while time.time() < deadline:
            state = query_kardenwort_state(ipc)
            if (
                state
                and state.get("anki_db_size", 0) == expected_size
                and abs(int(state.get("anki_db_mtime", 0)) - expected_mtime) <= 2
            ):
                break
            time.sleep(0.2)

        assert state and "options" in state, "State query failed after loading TSV"
        assert state.get("anki_db_size", 0) == expected_size, "FSM ANKI_DB_SIZE must match injected TSV size"
        assert abs(int(state.get("anki_db_mtime", 0)) - expected_mtime) <= 2, (
            "FSM ANKI_DB_MTIME must track the injected TSV mtime"
        )

        # Move to subtitle with "Hello world", open Drum Window, and capture render baseline.
        ipc.command(["seek", 1.2, "absolute+exact"])
        time.sleep(0.2)
        s0 = query_kardenwort_state(ipc)
        if s0.get("drum_window") == "OFF":
            ipc.command(["script-message-to", "kardenwort", "drum-window-toggle"])
            time.sleep(0.3)
        render_one = query_kardenwort_render(ipc, "dw")
        assert "0075D1" in render_one or "005DAE" in render_one, (
            "Expected anki highlight color in baseline render"
        )

        # Upgrade TSV to two identical rows; engine should stack depth to level 2 (no dedupe).
        with open(tsv_path, "w", encoding="utf-8") as f:
            f.write(tsv_content + row_1 + row_2)
        expected_size_2 = tsv_path.stat().st_size
        expected_mtime_2 = int(os.path.getmtime(tsv_path))

        deadline2 = time.time() + 8.0
        state2 = {}
        while time.time() < deadline2:
            state2 = query_kardenwort_state(ipc)
            if (
                state2
                and state2.get("anki_db_size", 0) == expected_size_2
                and abs(int(state2.get("anki_db_mtime", 0)) - expected_mtime_2) <= 2
            ):
                break
            time.sleep(0.2)

        assert state2.get("anki_db_size", 0) == expected_size_2, "FSM must reload two-row TSV size"
        render_two = query_kardenwort_render(ipc, "dw")
        assert "005DAE" in render_two, (
            "Expected depth-2 orange highlight color after adding second identical row"
        )
        assert render_two != render_one, "Render should change when identical row is added (no dedupe)"
    finally:
        try:
            tsv_path.unlink(missing_ok=True)
        except Exception:
            pass
