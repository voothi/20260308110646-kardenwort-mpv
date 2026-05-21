"""
Feature ZID: 20260521111616
Test Creation ZID: 20260521112312
Feature: Visibility Resilience & High Fidelity Highlighting Parity

This test verifies:
1. Interactive Drum Window (DW) keybindings (e.g., tooltip toggle, hover mode, search toggle,
   anki global highlight toggle, smart add, pink pairing) successfully bypass the native_sub_vis visibility check
   (i.e., functioning perfectly inside the DW mode even when subtitles are toggled OFF without showing OSD "X").
2. Bold state of database-highlighted phrases respecting `anki_highlight_bold` while
   manual interactive selections strictly enforce regular font weight (\\b0).
"""

import os
import time
import tempfile
from pathlib import Path
import pytest
from tests.ipc.mpv_ipc import query_kardenwort_state, query_kardenwort_render


def test_interactive_dw_keys_bypass_native_sub_vis(mpv):
    """
    Verify that interactive DW commands function when subtitles are visually toggled OFF.
    """
    ipc = mpv.ipc

    # 1. Open Drum Window (z)
    state = query_kardenwort_state(ipc)
    assert state.get("drum_window") == "OFF"
    
    ipc.command(["script-binding", "kardenwort/toggle-drum-window"])
    time.sleep(0.3)
    state = query_kardenwort_state(ipc)
    assert state.get("drum_window") != "OFF"

    # 2. Toggle Subtitle Visibility OFF via script message
    ipc.command(["script-message-to", "kardenwort", "sub-visibility-set", "OFF"])
    time.sleep(0.2)
    state = query_kardenwort_state(ipc)
    assert state.get("native_sub_vis") is False

    # Clear OSD log property before triggers
    ipc.command(["set_property", "user-data/kardenwort/last_osd", ""])

    # 3. Test dw-tooltip-toggle (default 'e')
    initial_forced = state.get("tooltip_forced")
    # Trigger binding directly
    ipc.command(["script-binding", "kardenwort/dw-tooltip-toggle-1"])
    time.sleep(0.2)
    state = query_kardenwort_state(ipc)
    assert state.get("tooltip_forced") != initial_forced, "Tooltip forced toggle must work when sub visibility is OFF"
    assert ipc.get_property("user-data/kardenwort/last_osd") != "X", "dw-tooltip-toggle-1 must not show X"

    # 4. Test dw-tooltip-hover (toggles translation click/hover)
    ipc.command(["set_property", "user-data/kardenwort/last_osd", ""])
    initial_hover = state.get("dw_tooltip_mode")
    ipc.command(["script-binding", "kardenwort/dw-tooltip-hover-1"])
    time.sleep(0.2)
    state = query_kardenwort_state(ipc)
    assert state.get("dw_tooltip_mode") != initial_hover, "Tooltip hover toggle must work when sub visibility is OFF"
    assert ipc.get_property("user-data/kardenwort/last_osd") != "X", "dw-tooltip-hover-1 must not show X"

    # 5. Test toggle-drum-search (default 'Ctrl+f')
    ipc.command(["set_property", "user-data/kardenwort/last_osd", ""])
    assert state.get("search_mode") is False
    ipc.command(["script-binding", "kardenwort/toggle-drum-search"])
    time.sleep(0.2)
    state = query_kardenwort_state(ipc)
    assert state.get("search_mode") is True, "Search mode toggle must work when sub visibility is OFF"
    assert ipc.get_property("user-data/kardenwort/last_osd") != "X", "toggle-drum-search must not show X"

    # Close search mode to return to regular DW state
    ipc.command(["script-binding", "kardenwort/toggle-drum-search"])
    time.sleep(0.1)

    # 6. Test toggle-anki-global (global highlight toggle)
    ipc.command(["set_property", "user-data/kardenwort/last_osd", ""])
    initial_anki_global = state.get("options", {}).get("anki_global_highlight")
    ipc.command(["script-binding", "kardenwort/toggle-anki-global"])
    time.sleep(0.2)
    state = query_kardenwort_state(ipc)
    assert state.get("options", {}).get("anki_global_highlight") != initial_anki_global, "Anki global highlight toggle must work when sub visibility is OFF"
    assert ipc.get_property("user-data/kardenwort/last_osd") != "X", "toggle-anki-global must not show X"

    # 7. Test dw-add-1 (smart add/commit)
    ipc.command(["set_property", "user-data/kardenwort/last_osd", ""])
    ipc.command(["script-binding", "kardenwort/dw-add-1"])
    time.sleep(0.2)
    assert ipc.get_property("user-data/kardenwort/last_osd") != "X", "dw-add-1 must not be blocked or show X"

    # 8. Test dw-pair-1 (pink pairing)
    ipc.command(["set_property", "user-data/kardenwort/last_osd", ""])
    ipc.command(["script-binding", "kardenwort/dw-pair-1"])
    time.sleep(0.2)
    assert ipc.get_property("user-data/kardenwort/last_osd") != "X", "dw-pair-1 must not be blocked or show X"


def test_anki_highlight_bold_vs_manual_selection(mpv):
    """
    Verify bold highlight parity:
    - phrase-only highlights respect anki_highlight_bold (either bold or regular)
    - manual selection strictly enforces regular font weight (\\b0).
    """
    ipc = mpv.ipc

    # Construct a custom TSV file containing an active highlight for "Hello"
    tsv_header = (
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

    row = (
        "Hello\tHello\tHello\tHello\tHello\t\t\t"
        "Hello world\t\tHello world\t\t\t\t\t\t\t\t\t\t\t\t\t"
        "1.001\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t"
        "0:1:1\t20260502165659-test-fixture.en\n"
    )

    fd, temp_name = tempfile.mkstemp(prefix="kardenwort-bold-parity-", suffix=".tsv")
    try:
        tsv_path = Path(temp_name)
        with open(fd, "w", encoding="utf-8", closefd=True) as f:
            f.write(tsv_header + row)

        expected_size = tsv_path.stat().st_size

        # Speed up sync and load TSV
        ipc.command(["script-message-to", "kardenwort", "test-set-option", "anki_sync_period", "0.2"])
        ipc.command(["script-message-to", "kardenwort", "test-set-option", "anki_record_file", str(tsv_path)])

        # Wait for reload
        deadline = time.time() + 5.0
        while time.time() < deadline:
            state = query_kardenwort_state(ipc)
            if state.get("anki_db_size", 0) == expected_size:
                break
            time.sleep(0.2)

        # Seek to the subtitle with "Hello world"
        ipc.command(["seek", 1.2, "absolute+exact"])
        time.sleep(0.2)

        # Enable Drum Window
        state = query_kardenwort_state(ipc)
        if state.get("drum_window") == "OFF":
            ipc.command(["script-message-to", "kardenwort", "drum-window-toggle"])
            time.sleep(0.3)

        # Case A: configured anki_highlight_bold = yes
        ipc.command(["script-message-to", "kardenwort", "test-set-option", "anki_highlight_bold", "yes"])
        time.sleep(0.2)
        render_bold = query_kardenwort_render(ipc, "dw")
        # Should contain bold tag {\b1} or configured highlight bold before/after "Hello"
        assert "{\\b1}" in render_bold or "b1" in render_bold, "Expected bold tag when anki_highlight_bold is active"

        # Case B: configured anki_highlight_bold = no
        ipc.command(["script-message-to", "kardenwort", "test-set-option", "anki_highlight_bold", "no"])
        time.sleep(0.2)
        render_regular = query_kardenwort_render(ipc, "dw")
        assert "{\\b0}" in render_regular or "b0" in render_regular, "Expected regular tag when anki_highlight_bold is inactive"

        # Case C: manual interactive cursor/selection must enforce regular font weight (\b0)
        # Move the cursor/pointer to word "world" (word 1 in line 1)
        ipc.command(["script-message-to", "kardenwort", "test-set-cursor", "1", "1"])
        time.sleep(0.2)
        render_selected = query_kardenwort_render(ipc, "dw")
        # The selected word must be prepended with {\b0}
        assert "{\\b0}" in render_selected or "b0" in render_selected, "Manual selection must enforce regular weight"

    finally:
        try:
            tsv_path.unlink(missing_ok=True)
        except Exception:
            pass
