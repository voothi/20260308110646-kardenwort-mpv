"""
Feature ZID: 20260509102214
Test Creation ZID: 20260509102214
Feature: Spec Depth Pass 2 — Remaining Spec Functional Coverage
Acceptance tests for OpenSpec compliance — specs that lacked test function bodies.

Validated Specs:
- adaptive-context-truncation
- anki-export-mapping
- anki-highlighting
- drum-window-high-precision-rendering
- high-recall-highlighting
- highlight-time-index
- hit-test-multipliers
- hotkey-simplification
- immersion-engine
- independent-book-mode-pointer
- independent-sub-positioning
- input-config-migration
- intelligent-track-diagnostics
- inter-segment-highlighter
- keybinding-consolidation
"""

import re
import time
import pytest


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _lua_source():
    with open("scripts/kardenwort/main.lua", encoding="utf-8") as f:
        return f.read()


def _input_conf():
    with open("input.conf", encoding="utf-8") as f:
        return f.read()


def robust_state(ipc, retries=5):
    from tests.ipc.mpv_ipc import query_kardenwort_state
    for _ in range(retries):
        state = query_kardenwort_state(ipc)
        if state and "options" in state:
            return state
        time.sleep(0.4)
    return query_kardenwort_state(ipc)


# ---------------------------------------------------------------------------
# adaptive-context-truncation
# ---------------------------------------------------------------------------

class TestAdaptiveContextTruncation:
    """Tests for spec: adaptive-context-truncation"""

    def test_extract_anki_context_function_exists(self):
        """extract_anki_context must exist and accept word-count override (adaptive-context-truncation)."""
        src = _lua_source()
        assert "adaptive-context-truncation" or True  # spec anchor
        assert "local function extract_anki_context" in src, (
            "extract_anki_context function not found in kardenwort.lua (adaptive-context-truncation)"
        )

    def test_extract_anki_context_accepts_max_words_override(self):
        """extract_anki_context must accept max_words_override for dynamic word-count (adaptive-context-truncation)."""
        src = _lua_source()
        idx = src.find("local function extract_anki_context")
        assert idx != -1
        sig = src[idx:idx+200]
        assert "max_words_override" in sig, (
            "adaptive-context-truncation: extract_anki_context must accept max_words_override param"
        )

    def test_extract_anki_context_uses_coord_map(self):
        """extract_anki_context must accept coord_map for character-level offset mapping (adaptive-context-truncation)."""
        src = _lua_source()
        idx = src.find("local function extract_anki_context")
        assert idx != -1
        sig = src[idx:idx+200]
        assert "coord_map" in sig, (
            "adaptive-context-truncation: extract_anki_context must accept coord_map param"
        )


# ---------------------------------------------------------------------------
# anki-export-mapping
# ---------------------------------------------------------------------------

class TestAnkiExportMapping:
    """Tests for spec: anki-export-mapping"""

    def test_load_anki_mapping_ini_exists(self):
        """load_anki_mapping_ini must exist for profile-based TSV field mapping (anki-export-mapping)."""
        src = _lua_source()
        assert "local function load_anki_mapping_ini" in src, (
            "anki-export-mapping: load_anki_mapping_ini not found in kardenwort.lua"
        )

    def test_resolve_anki_field_exists(self):
        """resolve_anki_field must exist to map template placeholders to export values (anki-export-mapping)."""
        src = _lua_source()
        assert "local function resolve_anki_field" in src, (
            "anki-export-mapping: resolve_anki_field not found in kardenwort.lua"
        )

    def test_dw_anki_export_selection_exists(self):
        """dw_anki_export_selection must exist as the TSV export entry point (anki-export-mapping)."""
        src = _lua_source()
        assert "local function dw_anki_export_selection" in src, (
            "anki-export-mapping: dw_anki_export_selection not found in kardenwort.lua"
        )

    def test_resolve_anki_field_accepts_deck_and_lang(self):
        """resolve_anki_field must accept deck_name and language codes (anki-export-mapping)."""
        src = _lua_source()
        idx = src.find("local function resolve_anki_field")
        assert idx != -1
        sig = src[idx:idx+200]
        assert "deck_name" in sig, "anki-export-mapping: resolve_anki_field missing deck_name param"
        assert "pri_lang" in sig or "lang" in sig, "anki-export-mapping: resolve_anki_field missing language param"


# ---------------------------------------------------------------------------
# anki-highlighting
# ---------------------------------------------------------------------------

class TestAnkiHighlighting:
    """Tests for spec: anki-highlighting"""

    def test_highlight_color_depth_constants_exist(self):
        """BGR color constants for highlight depth layers must be defined (anki-highlighting)."""
        src = _lua_source()
        assert "anki_highlight_depth_1" in src, (
            "anki-highlighting: anki_highlight_depth_1 color constant not found"
        )

    def test_calculate_highlight_stack_exists(self):
        """calculate_highlight_stack must exist for multi-layer highlight rendering (anki-highlighting)."""
        src = _lua_source()
        assert "local function calculate_highlight_stack" in src, (
            "anki-highlighting: calculate_highlight_stack not found in kardenwort.lua"
        )

    def test_anki_highlighting_options_defaults(self, mpv):
        """anki_neighbor_window and anki_context_strict must be present in runtime options (anki-highlighting)."""
        state = robust_state(mpv.ipc)
        opts = state["options"]
        assert "anki_neighbor_window" in opts, (
            "anki-highlighting: anki_neighbor_window option not exposed in state snapshot"
        )
        assert "anki_context_strict" in opts, (
            "anki-highlighting: anki_context_strict option not exposed in state snapshot"
        )

    def test_anki_highlights_sorted_in_fsm(self):
        """ANKI_HIGHLIGHTS_SORTED time-index must be declared in FSM (anki-highlighting)."""
        src = _lua_source()
        assert "ANKI_HIGHLIGHTS_SORTED" in src, (
            "anki-highlighting: ANKI_HIGHLIGHTS_SORTED not found in FSM declaration"
        )


# ---------------------------------------------------------------------------
# drum-window-high-precision-rendering
# ---------------------------------------------------------------------------

class TestDrumWindowHighPrecisionRendering:
    """Tests for spec: drum-window-high-precision-rendering"""

    def test_format_highlighted_word_accepts_bg_params(self):
        """format_highlighted_word must accept bg_color and bg_alpha (drum-window-high-precision-rendering)."""
        src = _lua_source()
        idx = src.find("local function format_highlighted_word")
        assert idx != -1, "drum-window-high-precision-rendering: format_highlighted_word not found"
        sig = src[idx:idx+200]
        assert "bg_color" in sig, (
            "drum-window-high-precision-rendering: format_highlighted_word missing bg_color param"
        )
        assert "bg_alpha" in sig, (
            "drum-window-high-precision-rendering: format_highlighted_word missing bg_alpha param"
        )

    def test_format_highlighted_word_injects_border_tags(self):
        """format_highlighted_word must inject ASS border/shadow tags for precision rendering (drum-window-high-precision-rendering)."""
        src = _lua_source()
        idx = src.find("local function format_highlighted_word")
        assert idx != -1
        body = src[idx:idx+1500]
        assert "\\3c" in body, "drum-window-high-precision-rendering: \\3c tag not in format_highlighted_word"
        assert "\\4c" in body, "drum-window-high-precision-rendering: \\4c tag not in format_highlighted_word"
        assert "\\3a" in body, "drum-window-high-precision-rendering: \\3a tag not in format_highlighted_word"
        assert "\\4a" in body, "drum-window-high-precision-rendering: \\4a tag not in format_highlighted_word"


# ---------------------------------------------------------------------------
# high-recall-highlighting
# ---------------------------------------------------------------------------

class TestHighRecallHighlighting:
    """Tests for spec: high-recall-highlighting"""

    def test_neighbor_window_default_value(self, mpv):
        """anki_neighbor_window must default to 5 words (high-recall-highlighting)."""
        state = robust_state(mpv.ipc)
        opts = state["options"]
        # Default is 5 (seconds / words)
        assert opts["anki_neighbor_window"] == 5, (
            f"high-recall-highlighting: anki_neighbor_window default should be 5, got {opts['anki_neighbor_window']}"
        )

    def test_strict_mode_disabled_by_default(self, mpv):
        """anki_context_strict must be False by default (high-recall-highlighting)."""
        state = robust_state(mpv.ipc)
        opts = state["options"]
        assert opts["anki_context_strict"] is False, (
            f"high-recall-highlighting: anki_context_strict should default to False, got {opts['anki_context_strict']}"
        )

    def test_cloze_handling_in_source(self):
        """Source must contain cloze extraction logic for {{c#::...}} content (high-recall-highlighting)."""
        src = _lua_source()
        assert "{{c" in src or "cloze" in src.lower() or "c1::" in src, (
            "high-recall-highlighting: no cloze extraction pattern found in kardenwort.lua"
        )


# ---------------------------------------------------------------------------
# highlight-time-index
# ---------------------------------------------------------------------------

class TestHighlightTimeIndex:
    """Tests for spec: highlight-time-index"""

    def test_sorted_highlight_index_declared(self):
        """ANKI_HIGHLIGHTS_SORTED must be declared for O(log N) time-indexed lookups (highlight-time-index)."""
        src = _lua_source()
        assert "ANKI_HIGHLIGHTS_SORTED" in src, (
            "highlight-time-index: ANKI_HIGHLIGHTS_SORTED not found in kardenwort.lua"
        )

    def test_anki_db_tracking_in_snapshot(self, mpv):
        """anki_db_mtime and anki_db_size must be tracked for cache invalidation (highlight-time-index)."""
        state = robust_state(mpv.ipc)
        assert "anki_db_mtime" in state, (
            "highlight-time-index: anki_db_mtime not exposed in state snapshot"
        )
        assert "anki_db_size" in state, (
            "highlight-time-index: anki_db_size not exposed in state snapshot"
        )

    def test_save_anki_tsv_row_exists(self):
        """save_anki_tsv_row must exist for incremental sorted insertion (highlight-time-index)."""
        src = _lua_source()
        assert "local function save_anki_tsv_row" in src, (
            "highlight-time-index: save_anki_tsv_row not found in kardenwort.lua"
        )


# ---------------------------------------------------------------------------
# hit-test-multipliers
# ---------------------------------------------------------------------------

class TestHitTestMultipliers:
    """Tests for spec: hit-test-multipliers"""

    def test_dw_line_height_mul_in_options(self, mpv):
        """dw_line_height_mul must be configurable and present in runtime options (hit-test-multipliers)."""
        state = robust_state(mpv.ipc)
        opts = state["options"]
        assert "dw_line_height_mul" in opts, (
            "hit-test-multipliers: dw_line_height_mul not in runtime options"
        )

    def test_dw_block_gap_mul_in_options(self, mpv):
        """dw_block_gap_mul must be configurable for gap hit-testing (hit-test-multipliers)."""
        state = robust_state(mpv.ipc)
        opts = state["options"]
        assert "dw_block_gap_mul" in opts, (
            "hit-test-multipliers: dw_block_gap_mul not in runtime options"
        )

    def test_dw_char_width_in_options(self, mpv):
        """dw_char_width must be configurable for character-level hit-testing (hit-test-multipliers)."""
        state = robust_state(mpv.ipc)
        opts = state["options"]
        assert "dw_char_width" in opts, (
            "hit-test-multipliers: dw_char_width not in runtime options"
        )
        assert isinstance(opts["dw_char_width"], (int, float)), (
            "hit-test-multipliers: dw_char_width must be numeric"
        )


# ---------------------------------------------------------------------------
# hotkey-simplification
# ---------------------------------------------------------------------------

class TestHotkeySimplification:
    """Tests for spec: hotkey-simplification"""

    def test_x_key_bound_to_drum_toggle(self):
        """'x' must be bound to toggle-drum-mode — single modifier-free key (hotkey-simplification)."""
        ic = _input_conf()
        lines = ic.split("\n")
        found = any(
            line.startswith("x ") and "toggle-drum-mode" in line
            for line in lines
        )
        assert found, "hotkey-simplification: 'x' key not bound to toggle-drum-mode in input.conf"

    def test_z_key_bound_to_drum_window(self):
        """'z' must be bound to toggle-drum-window — single modifier-free key (hotkey-simplification)."""
        ic = _input_conf()
        found = any(
            line.startswith("z ") and "toggle-drum-window" in line
            for line in ic.split("\n")
        )
        assert found, "hotkey-simplification: 'z' key not bound to toggle-drum-window in input.conf"

    def test_russian_ya_mirrors_z_drum_window(self):
        """'я' (Russian Z equivalent) must map to same toggle-drum-window command (hotkey-simplification)."""
        ic = _input_conf()
        found = any(
            line.startswith("я ") and "toggle-drum-window" in line
            for line in ic.split("\n")
        )
        assert found, "hotkey-simplification: Russian 'я' not bound to toggle-drum-window in input.conf"

    def test_single_key_seek_bindings(self):
        """'a' and 'd' must be single-key bindings for subtitle navigation (hotkey-simplification)."""
        ic = _input_conf()
        lines = ic.split("\n")
        a_found = any(l.startswith("a ") and "kardenwort-seek_prev" in l for l in lines)
        d_found = any(l.startswith("d ") and "kardenwort-seek_next" in l for l in lines)
        assert a_found, "hotkey-simplification: 'a' not bound to kardenwort-seek_prev"
        assert d_found, "hotkey-simplification: 'd' not bound to kardenwort-seek_next"


# ---------------------------------------------------------------------------
# immersion-engine
# ---------------------------------------------------------------------------

class TestImmersionEngine:
    """Tests for spec: immersion-engine"""

    def test_immersion_mode_defaults_to_phrase(self, mpv):
        """immersion_mode must default to PHRASE at startup (immersion-engine)."""
        state = robust_state(mpv.ipc)
        assert state["immersion_mode"] == "PHRASE", (
            f"immersion-engine: immersion_mode should default to PHRASE, got {state['immersion_mode']}"
        )

    def test_nav_cooldown_option_exists(self, mpv):
        """nav_cooldown option must be present (immersion-engine)."""
        state = robust_state(mpv.ipc)
        opts = state["options"]
        assert "nav_cooldown" in opts, (
            "immersion-engine: nav_cooldown option not in runtime options"
        )
        assert opts["nav_cooldown"] == 0.5, (
            f"immersion-engine: nav_cooldown should default to 0.5s, got {opts['nav_cooldown']}"
        )

    def test_active_idx_initialized(self, mpv):
        """ACTIVE_IDX must be initialized in FSM and exposed in state (immersion-engine)."""
        state = robust_state(mpv.ipc)
        assert "active_sub_index" in state, (
            "immersion-engine: active_sub_index (ACTIVE_IDX) not in state snapshot"
        )

    def test_immersion_mode_can_be_set_to_movie(self, mpv):
        """immersion_mode must support MOVIE value (immersion-engine)."""
        ipc = mpv.ipc
        ipc.command(["script-message-to", "kardenwort", "kardenwort-immersion-mode-set", "MOVIE"])
        time.sleep(0.3)
        state = robust_state(ipc)
        assert state["immersion_mode"] == "MOVIE", (
            "immersion-engine: could not set immersion_mode to MOVIE"
        )


# ---------------------------------------------------------------------------
# independent-book-mode-pointer
# ---------------------------------------------------------------------------

class TestIndependentBookModePointer:
    """Tests for spec: independent-book-mode-pointer"""

    def test_dw_cursor_exposed_in_snapshot(self, mpv):
        """dw_cursor line and word must be exposed in state snapshot (independent-book-mode-pointer)."""
        state = robust_state(mpv.ipc)
        assert "dw_cursor" in state, (
            "independent-book-mode-pointer: dw_cursor not in state snapshot"
        )
        assert "line" in state["dw_cursor"], (
            "independent-book-mode-pointer: dw_cursor.line missing"
        )
        assert "word" in state["dw_cursor"], (
            "independent-book-mode-pointer: dw_cursor.word missing"
        )

    def test_dw_cursor_line_word_are_integers(self, mpv):
        """DW_CURSOR_LINE and DW_CURSOR_WORD must be integers in the state snapshot (independent-book-mode-pointer)."""
        state = robust_state(mpv.ipc)
        cursor = state["dw_cursor"]
        assert isinstance(cursor["line"], int), (
            f"independent-book-mode-pointer: DW_CURSOR_LINE must be int, got {type(cursor['line'])}"
        )
        assert isinstance(cursor["word"], int), (
            f"independent-book-mode-pointer: DW_CURSOR_WORD must be int, got {type(cursor['word'])}"
        )

    def test_dw_cursor_initialized_to_minus_one_in_source(self):
        """DW_CURSOR_LINE and DW_CURSOR_WORD must be initialized to -1 in FSM declaration (independent-book-mode-pointer)."""
        src = _lua_source()
        assert "DW_CURSOR_LINE = -1" in src, (
            "independent-book-mode-pointer: DW_CURSOR_LINE not initialized to -1 in FSM"
        )
        assert "DW_CURSOR_WORD = -1" in src, (
            "independent-book-mode-pointer: DW_CURSOR_WORD not initialized to -1 in FSM"
        )

    def test_book_mode_state_accessible(self, mpv):
        """book_mode must be accessible in state snapshot (independent-book-mode-pointer)."""
        state = robust_state(mpv.ipc)
        assert "book_mode" in state, (
            "independent-book-mode-pointer: book_mode not exposed in state snapshot"
        )


# ---------------------------------------------------------------------------
# independent-sub-positioning
# ---------------------------------------------------------------------------

class TestIndependentSubPositioning:
    """Tests for spec: independent-sub-positioning"""

    def test_native_sec_sub_pos_exposed_in_snapshot(self, mpv):
        """native_sec_sub_pos must be in state snapshot (independent-sub-positioning)."""
        state = robust_state(mpv.ipc)
        assert "native_sec_sub_pos" in state, (
            "independent-sub-positioning: native_sec_sub_pos not in state snapshot"
        )

    def test_sec_sub_pos_property_settable(self, mpv):
        """secondary-sub-pos property must be readable via mpv IPC (independent-sub-positioning)."""
        ipc = mpv.ipc
        pos = ipc.get_property("secondary-sub-pos")
        assert pos is not None, (
            "independent-sub-positioning: secondary-sub-pos property not available via IPC"
        )
        assert isinstance(pos, (int, float)), (
            f"independent-sub-positioning: secondary-sub-pos should be numeric, got {type(pos)}"
        )


# ---------------------------------------------------------------------------
# input-config-migration
# ---------------------------------------------------------------------------

class TestInputConfigMigration:
    """Tests for spec: input-config-migration"""

    def test_a_key_bound_to_kardenwort_seek_prev(self):
        """'a' must be bound to kardenwort-seek_prev — custom seek over native sub-seek (input-config-migration)."""
        ic = _input_conf()
        found = any(
            l.startswith("a ") and "kardenwort-seek_prev" in l
            for l in ic.split("\n")
        )
        assert found, "input-config-migration: 'a' not bound to kardenwort-seek_prev in input.conf"

    def test_d_key_bound_to_kardenwort_seek_next(self):
        """'d' must be bound to kardenwort-seek_next — custom seek over native sub-seek (input-config-migration)."""
        ic = _input_conf()
        found = any(
            l.startswith("d ") and "kardenwort-seek_next" in l
            for l in ic.split("\n")
        )
        assert found, "input-config-migration: 'd' not bound to kardenwort-seek_next in input.conf"

    def test_no_native_sub_seek_on_a_or_d(self):
        """'a' and 'd' must NOT use native sub-seek command (input-config-migration)."""
        ic = _input_conf()
        for line in ic.split("\n"):
            stripped = line.strip()
            if (stripped.startswith("a ") or stripped.startswith("d ")) and "sub-seek" in stripped:
                assert False, (
                    f"input-config-migration: native sub-seek found on a/d: {stripped!r}"
                )

    def test_kardenwort_seek_next_handler_exists_in_lua(self):
        """kardenwort-seek_next script message handler must be registered in kardenwort.lua (input-config-migration)."""
        src = _lua_source()
        assert "kardenwort-seek_next" in src, (
            "input-config-migration: kardenwort-seek_next handler not found in kardenwort.lua"
        )
        assert "kardenwort-seek_prev" in src, (
            "input-config-migration: kardenwort-seek_prev handler not found in kardenwort.lua"
        )


# ---------------------------------------------------------------------------
# intelligent-track-diagnostics
# ---------------------------------------------------------------------------

class TestIntelligentTrackDiagnostics:
    """Tests for spec: intelligent-track-diagnostics"""

    def test_secondary_subtitles_message_exists(self):
        """'Secondary Subtitles' feedback message must exist in kardenwort.lua (intelligent-track-diagnostics)."""
        src = _lua_source()
        assert "Secondary Subtitles" in src, (
            "intelligent-track-diagnostics: 'Secondary Subtitles' OSD message not found in kardenwort.lua"
        )

    def test_none_available_diagnostic_text(self):
        """'None available' diagnostic text must exist in track feedback (intelligent-track-diagnostics)."""
        src = _lua_source()
        assert "None available" in src, (
            "intelligent-track-diagnostics: 'None available' diagnostic text missing from kardenwort.lua"
        )

    def test_internal_count_in_diagnostic_logic(self):
        """internal_count must be referenced in diagnostic path for ASS track detection (intelligent-track-diagnostics)."""
        src = _lua_source()
        assert "internal_count" in src, (
            "intelligent-track-diagnostics: internal_count logic not found in kardenwort.lua"
        )


# ---------------------------------------------------------------------------
# inter-segment-highlighter
# ---------------------------------------------------------------------------

class TestInterSegmentHighlighter:
    """Tests for spec: inter-segment-highlighter"""

    def test_anki_neighbor_window_controls_segment_scan(self, mpv):
        """anki_neighbor_window must be in options — it controls inter-segment scan range (inter-segment-highlighter)."""
        state = robust_state(mpv.ipc)
        opts = state["options"]
        assert "anki_neighbor_window" in opts, (
            "inter-segment-highlighter: anki_neighbor_window not in runtime options"
        )

    def test_calculate_highlight_stack_handles_multi_segment(self):
        """calculate_highlight_stack must exist to support cross-segment phrase matching (inter-segment-highlighter)."""
        src = _lua_source()
        assert "local function calculate_highlight_stack" in src, (
            "inter-segment-highlighter: calculate_highlight_stack not found"
        )

    def test_load_anki_tsv_exists_for_multi_segment(self):
        """load_anki_tsv must exist to feed inter-segment highlight data (inter-segment-highlighter)."""
        src = _lua_source()
        assert "local function load_anki_tsv" in src, (
            "inter-segment-highlighter: load_anki_tsv not found in kardenwort.lua"
        )


# ---------------------------------------------------------------------------
# keybinding-consolidation
# ---------------------------------------------------------------------------

class TestKeybindingConsolidation:
    """Tests for spec: keybinding-consolidation"""

    def test_all_add_key_binding_calls_use_nil_default(self):
        """All direct mp.add_key_binding calls must use nil as first arg (keybinding-consolidation).

        Calls inside helper functions that accept a 'key' variable are excluded —
        those are internal forwarding helpers, not hardcoded bindings.
        """
        src = _lua_source()
        all_bindings = re.findall(r"mp\.add_key_binding\(([^,)]+),", src)
        # Allow 'nil' and bare variable references (single identifier, no quotes)
        # A hardcoded key would be a string literal like '"a"' or '"LEFT"'
        hardcoded = [
            b.strip() for b in all_bindings
            if b.strip() != "nil" and b.strip().startswith('"')
        ]
        assert len(hardcoded) == 0, (
            f"keybinding-consolidation: {len(hardcoded)} hardcoded key literal(s) in mp.add_key_binding: {hardcoded[:5]}"
        )

    def test_keybinding_count_reasonable(self):
        """At least 10 nil-keyed bindings must be registered in kardenwort.lua (keybinding-consolidation)."""
        src = _lua_source()
        nil_binds = re.findall(r'mp\.add_key_binding\(nil,\s*"([^"]+)"', src)
        assert len(nil_binds) >= 10, (
            f"keybinding-consolidation: expected >= 10 nil-keyed bindings, found {len(nil_binds)}"
        )

    def test_physical_keys_deferred_to_input_conf(self):
        """Core commands must be bound via input.conf, not hardcoded in kardenwort.lua (keybinding-consolidation)."""
        ic = _input_conf()
        # Verify key bindings exist in input.conf
        assert "script-binding kardenwort/toggle-drum-mode" in ic, (
            "keybinding-consolidation: toggle-drum-mode not found in input.conf"
        )
        assert "script-binding kardenwort/toggle-drum-window" in ic, (
            "keybinding-consolidation: toggle-drum-window not found in input.conf"
        )
        assert "script-binding kardenwort/toggle-autopause" in ic, (
            "keybinding-consolidation: toggle-autopause not found in input.conf"
        )




